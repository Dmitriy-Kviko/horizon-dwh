{{ config(indexes=[{'columns': ['hk_loyalty_txn_id'], 'unique': true}]) }}

{% set batch %}
with keys as (
select loyalty_transaction_id as loyalty_transaction_id, batch_date, loaded_at, record_source
from {{ ref('stg_loyalty_transactions') }}
),
first_seen as (
    select distinct on (loyalty_transaction_id) *
    from keys
    where loyalty_transaction_id is not null
    order by loyalty_transaction_id, batch_date, loaded_at, record_source
)
select {{ hk(['loyalty_transaction_id']) }} as hk_loyalty_txn_id, *
from first_seen
{% endset %}
{{ append_new(batch, ['hk_loyalty_txn_id']) }}
