-- Каждому глобальному UUID чека соответствует один магазин и момент продажи.
select transaction_id
from {{ ref('stg_sales') }}
group by transaction_id
having count(distinct store_id) <> 1
    or count(distinct sold_at) <> 1
    or count(distinct payment_method) > 1
    or min(sold_at::date) <> {{ batch_date() }}
