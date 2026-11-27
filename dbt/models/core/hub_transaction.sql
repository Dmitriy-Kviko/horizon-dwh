{{ config(indexes=[{'columns': ['hk_transaction_id'], 'unique': true}]) }}

{% set batch %}
with keys as (
select transaction_id as transaction_id, batch_date, loaded_at, record_source
from {{ ref('stg_sales') }}
union all
select source_transaction_id as transaction_id, batch_date, loaded_at, record_source
from {{ ref('stg_loyalty_transactions') }}
),
first_seen as (
    select distinct on (transaction_id) *
    from keys
    where transaction_id is not null
    order by transaction_id, batch_date, loaded_at, record_source
)
select {{ hk(['transaction_id']) }} as hk_transaction_id, *
from first_seen
{% endset %}
{{ append_new(batch, ['hk_transaction_id']) }}
