with raw as (
    select coalesce(sum((payload->>'amount')::numeric),0) as amount
    from {{ source('raw','raw_records') }}
    where entity = 'sales' and batch_date = {{ batch_date() }}
),
candidate as (
    select coalesce(sum(sum_sales),0) as amount
    from {{ ref('int_sales_daily_batch') }}
)
select raw.amount as raw_amount, candidate.amount as candidate_amount
from raw cross join candidate
where raw.amount <> candidate.amount
