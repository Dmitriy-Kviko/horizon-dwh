"""Ежедневная загрузка в PostgreSQL и публикация проверенной витрины."""
import csv
import json
import logging
import os
import subprocess
from contextlib import closing
from pathlib import Path
from urllib import parse, request

import pendulum
import psycopg2
from airflow.decorators import dag, task
from airflow.operators.python import get_current_context
from airflow.utils.task_group import TaskGroup
from psycopg2.extras import Json, execute_values

ROOT = Path(__file__).resolve().parents[1]
ZONE = "Europe/Samara"
LOG = logging.getLogger(__name__)

# Суточные интервалы исходных локальных дат, с полуоткрытой верхней границей.
LOYALTY_QUERIES = {
    "clients": """select * from public.clients
                   where registration_date = %(day)s::date order by client_id""",
    "cards": """select * from public.cards
                 where issue_date = %(day)s::date order by card_id""",
    "loyalty_transactions": """select * from public.transactions
        where transaction_date >= %(day)s::date
          and transaction_date < %(day)s::date + 1
        order by loyalty_transaction_id""",
}
CSV_COLUMNS = {"transaction_id", "product_id", "amount", "store_id", "datetime"}
HR_COLUMNS = {"employee_id", "full_name", "position", "store_id", "termination_date"}


def dwh():
    return psycopg2.connect(os.environ["DWH_DSN"])


def load_sql(name):
    return (ROOT / "sql" / name).read_text(encoding="utf-8")


def require_fields(row, fields, source):
    if not isinstance(row, dict) or fields - row.keys():
        raise ValueError(f"Неверная структура записи: {source}")


def read_sales(day, data):
    path = data / f"sales_{day.replace('-', '')}.csv"
    if not path.is_file():
        LOG.warning("Нет файла продаж %s. Витрина за %s не публикуется.", path.name, day)
        return None
    with path.open(encoding="utf-8-sig", newline="") as stream:
        reader = csv.DictReader(stream)
        fields = set(reader.fieldnames or [])
        if CSV_COLUMNS - fields or len(fields & {"quantity", "oquantity"}) != 1:
            raise ValueError(f"Некорректный заголовок {path.name}")
        rows = list(reader)
    if any(None in row or None in row.values() for row in rows):
        raise ValueError(f"Число полей строки отличается от заголовка {path.name}")
    return path.name, {"sales": rows}


def read_loyalty(day):
    with closing(psycopg2.connect(os.environ["LOYALTY_DSN"])) as conn:
        conn.set_session(readonly=True, isolation_level="REPEATABLE READ")
        with conn, conn.cursor() as cur:
            rows = {}
            for entity, query in LOYALTY_QUERIES.items():
                cur.execute(query, {"day": day})
                columns = [column.name for column in cur.description]
                rows[entity] = [dict(zip(columns, record)) for record in cur.fetchall()]
    return "loyalty_db", rows


def read_hr(day, data):
    url = os.environ.get("HR_API_URL")
    dated_path = data / "hr" / f"{day}.json"
    if url:
        # Договорённость для реального API: параметр date, ответ — суточная дельта.
        parts = parse.urlsplit(url)
        query = parse.parse_qsl(parts.query) + [("date", day)]
        endpoint = parts._replace(query=parse.urlencode(query)).geturl()
        token = os.environ.get("HR_API_TOKEN")
        headers = {"Authorization": f"Bearer {token}"} if token else {}
        with request.urlopen(request.Request(endpoint, headers=headers), timeout=30) as response:
            records = json.load(response)
        source = "hr_api"
        delta = True
    else:
        path = dated_path if dated_path.is_file() else data / "hr.json"
        records = json.loads(path.read_text(encoding="utf-8"))
        source = path.relative_to(data).as_posix()
        delta = path == dated_path
    if not isinstance(records, list):
        raise ValueError("HR должен вернуть массив сотрудников")
    for row in records:
        require_fields(row, HR_COLUMNS, source)
        if not ({"hire_date", "ohire_date"} & row.keys()):
            raise ValueError("Отсутствует дата найма")
    if not delta:
        records = [row for row in records if day in (
            row.get("hire_date", row.get("ohire_date")), row["termination_date"]
        )]
    return source, {"employees": records}


@dag(
    dag_id="horizon_elt",
    schedule="@daily",
    start_date=pendulum.datetime(2026, 11, 1, tz=ZONE),
    catchup=False,
    max_active_runs=1,
    default_args={"retries": 1, "retry_delay": pendulum.duration(minutes=5)},
    tags=["dwh", "horizon"],
)
def horizon_elt():
    @task
    def init_batch():
        context = get_current_context()
        dag_run = context["dag_run"]
        requested = dag_run.conf.get("batch_date")
        if requested is not None:
            from datetime import date
            day = date.fromisoformat(requested).isoformat()
        else:
            day = context["data_interval_end"].in_timezone(ZONE).subtract(days=1).to_date_string()
        with closing(dwh()) as conn, conn, conn.cursor() as cur:
            cur.execute(load_sql("staging.sql"))
        LOG.info("Бизнес-дата: %s", day)
        return day

    @task(task_id="extract")
    def extract(day, source):
        with closing(dwh()) as conn, conn.cursor() as cur:
            cur.execute("""select 1 from staging.load_batches
                           where batch_date=%s and source_system=%s""", (day, source))
            if cur.fetchone():
                LOG.info("Пакет %s за %s уже загружен", source, day)
                return {"loaded": True}
        data = Path(os.environ.get("HORIZON_DATA_DIR", ROOT / "demo-data"))
        if source == "sales":
            result = read_sales(day, data)
        elif source == "loyalty":
            result = read_loyalty(day)
        else:
            result = read_hr(day, data)

        if result is None:
            return {"missing": True}
        source_ref, entities = result
        work = Path(os.environ.get("HORIZON_WORK_DIR", ROOT / "work")) / day
        work.mkdir(parents=True, exist_ok=True)
        path = work / f"{source}.json"
        temp = path.with_suffix(".tmp")
        with open(temp, "w", encoding="utf-8", opener=private_file) as out:
            json.dump({"source_ref": source_ref, "entities": entities}, out, ensure_ascii=False,
                      default=str)
        temp.replace(path)
        return {"path": str(path)}

    @task(task_id="load")
    def load(day, source, extracted):
        if "missing" in extracted:
            return False
        if "loaded" in extracted:
            return True
        path = Path(extracted["path"])
        with closing(dwh()) as conn, conn, conn.cursor() as cur:
            cur.execute("""select 1 from staging.load_batches
                           where batch_date=%s and source_system=%s""", (day, source))
            if cur.fetchone():
                LOG.info("Пропуск повторной загрузки %s за %s", source, day)
                return True
            with path.open(encoding="utf-8") as stream:
                batch = json.load(stream)
            rows = [
                (day, entity, number, Json(payload))
                for entity, records in batch["entities"].items()
                for number, payload in enumerate(records, start=1)
            ]
            if rows:
                execute_values(cur, "insert into staging.raw_records values %s", rows)
            cur.execute("""insert into staging.load_batches
                           (batch_date, source_system, source_ref, row_count)
                           values (%s, %s, %s, %s)""",
                        (day, source, batch["source_ref"], len(rows)))
        # Оставляем промежуточный файл до повторных попыток, при штатном коммите удаляем.
        path.unlink(missing_ok=True)
        LOG.info("%s: загружено %s строк за %s", source, len(rows), day)
        return True

    @task
    def transform(day):
        project = ROOT / "dbt"
        # Сначала проверяем Staging, Core и расчёт за сутки. Затем публикуем факт.
        base = ["dbt", "--no-use-colors"]
        flags = ["--project-dir", str(project), "--profiles-dir", str(project),
                 "--vars", json.dumps({"batch_date": day})]
        subprocess.run(base + ["build"] + flags + ["--exclude", "fct_sales_daily"], check=True)
        subprocess.run(base + ["build"] + flags + ["--select", "fct_sales_daily"], check=True)

    @task
    def reconcile(day, sales_loaded):
        if not sales_loaded:
            LOG.warning("Сверка продаж за %s пропущена. Суточный файл отсутствует.", day)
            return
        with closing(dwh()) as conn, conn.cursor() as cur:
            cur.execute(load_sql("reconcile_sales.sql"), {"batch_date": day})
            raw, mart, difference = cur.fetchone()
        LOG.info("Сверка %s: raw=%s mart=%s difference=%s", day, raw, mart, difference)
        if difference != 0:
            raise ValueError(f"Разница сумм за {day}: {difference}")

    day = init_batch()
    loaded = {}
    for source in ("sales", "loyalty", "hr"):
        with TaskGroup(source):
            loaded[source] = load(day, source, extract(day, source))
    transformed = transform(day)
    for branch in loaded.values():
        branch >> transformed
    transformed >> reconcile(day, loaded["sales"])


def private_file(path, flags):
    return os.open(path, flags, 0o600)


pipeline = horizon_elt()
