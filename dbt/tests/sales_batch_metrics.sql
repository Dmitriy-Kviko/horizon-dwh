-- Независимый расчёт из Staging: сумма чека считается оконной функцией.
with lines as (
    select sold_at::date as full_date, store_id, product_id, transaction_id,
           sales_amount, sum(sales_amount) over (partition by transaction_id) as receipt_amount
    from {{ ref('stg_sales') }}
),
per_product_receipt as (
    select full_date, store_id, product_id, transaction_id,
           sum(sales_amount) as product_amount, max(receipt_amount) as receipt_amount
    from lines group by full_date, store_id, product_id, transaction_id
),
expected as (
    select full_date, store_id, product_id, sum(product_amount) as sum_sales,
           count(*) as num_transactions, round(avg(receipt_amount),2) as avg_transaction_amount
    from per_product_receipt group by full_date, store_id, product_id
),
actual as (
    select d.full_date, s.store_id, p.product_id,
           f.sum_sales, f.num_transactions, f.avg_transaction_amount
    from {{ ref('int_sales_daily_batch') }} f
    join {{ ref('dim_calendar') }} d using (date_key)
    join {{ ref('dim_store') }} s using (store_key)
    join {{ ref('dim_product') }} p using (product_key)
)
select coalesce(e.full_date,a.full_date) as full_date,
       coalesce(e.store_id,a.store_id) as store_id, coalesce(e.product_id,a.product_id) as product_id
from expected e full join actual a using (full_date,store_id,product_id)
where (e.sum_sales,e.num_transactions,e.avg_transaction_amount)
      is distinct from (a.sum_sales,a.num_transactions,a.avg_transaction_amount)
