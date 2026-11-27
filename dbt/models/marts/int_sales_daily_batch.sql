{{ config(materialized='view') }}

with receipt_product as (
    -- Одна строка на чек и SKU. Повторные позиции SKU суммируются,
    -- а полная сумма этого чека попадёт в среднее только один раз.
    select l.hk_transaction_id, l.hk_product_id, sum(s.amount) as product_amount
    from {{ ref('link_sale') }} l
    join {{ ref('sat_sale') }} s using (hk_sale_id, batch_date)
    where l.batch_date = {{ batch_date() }}
    group by l.hk_transaction_id, l.hk_product_id
),
enriched as (
    select c.date_key, ds.store_key, dp.product_key,
           p.product_amount, t.total_amount
    from receipt_product p
    join {{ ref('sat_transaction_details') }} t using (hk_transaction_id)
    join {{ ref('link_transaction') }} x using (hk_transaction_id)
    join {{ ref('hub_store') }} hs using (hk_store_id)
    join {{ ref('hub_product') }} hp using (hk_product_id)
    join {{ ref('dim_calendar') }} c on c.full_date = t.sold_at::date
    join {{ ref('dim_store') }} ds on ds.store_id = hs.store_id
    join {{ ref('dim_product') }} dp on dp.product_id = hp.product_id
    where t.batch_date = {{ batch_date() }} and x.batch_date = {{ batch_date() }}
)
select date_key, store_key, product_key,
       sum(product_amount)::numeric(12,2) as sum_sales,
       count(*)::integer as num_transactions,
       round(avg(total_amount), 2)::numeric(10,2) as avg_transaction_amount
from enriched
group by date_key, store_key, product_key
