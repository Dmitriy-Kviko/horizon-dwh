-- Сверка за бизнес-дату. В psql см. команду запуска в README.
WITH raw AS (
    SELECT COALESCE(SUM((payload->>'amount')::numeric), 0) AS amount
    FROM staging.raw_records
    WHERE entity = 'sales' AND batch_date = %(batch_date)s::date
), mart AS (
    SELECT COALESCE(SUM(sum_sales), 0) AS amount
    FROM marts.fct_sales_daily
    WHERE date_key = TO_CHAR(%(batch_date)s::date, 'YYYYMMDD')::integer
)
SELECT raw.amount AS raw_amount, mart.amount AS mart_amount,
       raw.amount - mart.amount AS difference
FROM raw CROSS JOIN mart;
