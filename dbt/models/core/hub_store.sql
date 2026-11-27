{{ config(indexes=[{'columns': ['hk_store_id'], 'unique': true}]) }}

{% set batch %}
with keys as (
select store_id as store_id, batch_date, loaded_at, record_source
from {{ ref('stg_sales') }}
union all
select store_id as store_id, batch_date, loaded_at, record_source
from {{ ref('stg_loyalty_transactions') }}
union all
select store_id as store_id, batch_date, loaded_at, record_source
from {{ ref('stg_employees') }}
),
first_seen as (
    select distinct on (store_id) *
    from keys
    where store_id is not null
    order by store_id, batch_date, loaded_at, record_source
)
select {{ hk(['store_id']) }} as hk_store_id, *
from first_seen
{% endset %}
{{ append_new(batch, ['hk_store_id']) }}
