"""Снимок итоговых фактов и явная сверка. Запускать до и после повтора."""
import argparse
import hashlib
import json
import os
from contextlib import closing
from datetime import date
from pathlib import Path

import psycopg2

ROOT = Path(__file__).resolve().parents[1]


def verify(day, allow_missing):
    date_key = int(day.replace("-", ""))
    with closing(psycopg2.connect(os.environ["DWH_DSN"])) as conn, conn.cursor() as cur:
        cur.execute("""select row_count from staging.load_batches
                       where source_system='sales' and batch_date=%s""", (day,))
        batch = cur.fetchone()
        if batch is None and not allow_missing:
            raise ValueError(f"Нет пакета продаж за {day}")
        cur.execute((ROOT / "sql/reconcile_sales.sql").read_text(), {"batch_date": day})
        raw, mart, difference = cur.fetchone()
        cur.execute("""select date_key, store_key, product_key, sum_sales, num_transactions,
                              avg_transaction_amount
                       from marts.fct_sales_daily
                       where date_key=%s order by 1,2,3""", (date_key,))
        daily = cur.fetchall()
        cur.execute("""select date_key, store_key, product_key, sum_sales, num_transactions,
                              avg_transaction_amount
                       from marts.fct_sales_daily order by 1,2,3""")
        all_fact = cur.fetchall()
        cur.execute((ROOT / "sql/check_hub_duplicates.sql").read_text())
        duplicates = cur.fetchall()
    if difference != 0 or duplicates or (batch is None and daily):
        raise ValueError(f"Контроль не пройден за {day}: сумма {difference}, дубли хабов {duplicates}")
    return {"date": day, "raw_rows": batch[0] if batch else None,
            "raw_amount": str(raw), "mart_amount": str(mart), "difference": str(difference),
            "daily_fact_rows": len(daily), "all_fact_rows": len(all_fact),
            "all_fact_sha256": hashlib.sha256(json.dumps(all_fact, default=str).encode()).hexdigest(),
            "duplicate_hub_keys": len(duplicates)}


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("date", type=lambda s: date.fromisoformat(s).isoformat())
    parser.add_argument("--allow-missing", action="store_true")
    args = parser.parse_args()
    print(json.dumps(verify(args.date, args.allow_missing), ensure_ascii=False, indent=2))
