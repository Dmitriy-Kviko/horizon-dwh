{{ config(indexes=[{'columns': ['hk_product_id'], 'unique': true}]) }}

{% set batch %}
with keys as (
select product_id as product_id, batch_date, loaded_at, record_source
from {{ ref('stg_sales') }}
),
first_seen as (
    select distinct on (product_id) *
    from keys
    where product_id is not null
    order by product_id, batch_date, loaded_at, record_source
)
select {{ hk(['product_id']) }} as hk_product_id, *
from first_seen
{% endset %}
{{ append_new(batch, ['hk_product_id']) }}
