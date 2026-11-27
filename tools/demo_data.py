"""Создаёт учебные файлы и заполняет отдельную базу лояльности."""
import csv
import json
import os
from contextlib import closing
from datetime import date, timedelta
from pathlib import Path
from uuid import NAMESPACE_URL, uuid5

import psycopg2

ROOT = Path(__file__).resolve().parents[1]
FIRST_DAY = date(2026, 11, 9)
DAYS = 8
STORES = ("S01", "S02", "S03")
PRODUCTS = tuple(f"SKU-{n:02}" for n in range(1, 13))


def make_demo():
    folder = Path(os.environ.get("HORIZON_DATA_DIR", ROOT / "demo-data"))
    (folder / "hr").mkdir(parents=True, exist_ok=True)
    with closing(psycopg2.connect(os.environ["LOYALTY_DSN"])) as conn, conn, conn.cursor() as cur:
        if conn.info.dbname == "horizon":
            raise ValueError("Для демо нужна отдельная база программы лояльности")
        cur.execute((ROOT / "sql/loyalty_demo.sql").read_text())
        for offset in range(DAYS):
            day = FIRST_DAY + timedelta(days=offset)
            rows = []
            count = [16, 19, 18, 25, 22, 29, 26, 31][offset]
            for n in range(count):
                check = str(uuid5(NAMESPACE_URL, f"horizon/demo/{day}/{n}"))
                store = STORES[n % len(STORES)]
                stamp = f"{day} {8 + n % 12:02}:15:00"
                product = PRODUCTS[(n + offset) % 12]
                other = PRODUCTS[(n * 5 + offset + 1) % 12]
                if offset == 0 and n == 0:
                    # Повтор SKU в чеке и второй товар. Полная сумма чека 450.
                    lines = [(PRODUCTS[0], 100, "1.000"), (PRODUCTS[0], 50, "0.500"),
                             (PRODUCTS[1], 300, "1.000")]
                else:
                    lines = [(product, (110 + (n % 12)*23) * (1 + n % 3), "1.000"),
                             (other, 85 + 11*(n % 8), "1.000")]
                rows.extend((check, sku, f"{amount:.2f}", qty, store, stamp)
                            for sku, amount, qty in lines)
                if n == 0:
                    register(cur, offset, day, stamp)
                elif n % 4 == 0:
                    cur.execute("""insert into public.transactions values (%s,%s,%s,%s,%s,%s)
                                   on conflict do nothing""",
                                (1000+offset*100+n, 10+offset, 30 if n % 8 == 0 else -10,
                                 stamp, store, check))
            with (folder / f"sales_{day:%Y%m%d}.csv").open("w", encoding="utf-8", newline="") as f:
                out = csv.writer(f)
                out.writerow(("transaction_id","product_id","amount","quantity","store_id","datetime"))
                out.writerows(rows)
            employees = []
            if offset == 0:
                employees = [
                    dict(employee_id=n, full_name=f"Учебный сотрудник {n}", position="Кассир",
                         store_id=store, hire_date=str(day), termination_date=None)
                    for n, store in enumerate(STORES,1)
                ]
            if offset == DAYS-1:
                employees = [dict(employee_id=1, full_name="Учебный сотрудник 1",
                                  position="Кассир",store_id=STORES[0],
                                  hire_date=str(FIRST_DAY),termination_date=str(day))]
            (folder / "hr" / f"{day}.json").write_text(json.dumps(employees,ensure_ascii=False),encoding="utf-8")
        (folder / "hr.json").write_text("[]\n",encoding="utf-8")


def register(cur, offset, day, stamp):
    client = offset + 1
    card = offset + 10
    cur.execute("""insert into public.clients values (%s,%s,null,null,null,%s)
                   on conflict do nothing""", (client,f"Учебный клиент {client}",day))
    cur.execute("""insert into public.cards values (%s,%s,%s,%s,%s)
                   on conflict do nothing""",
                (card,client,f"DEMO-{card}",day,("active","blocked","expired")[offset%3]))
    cur.execute("""insert into public.transactions values (%s,%s,30,%s,null,null)
                   on conflict do nothing""", (1000+offset*100,card,stamp))


if __name__ == "__main__":
    make_demo()
