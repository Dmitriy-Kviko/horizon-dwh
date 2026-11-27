{{ config(indexes=[{'columns': ['hk_loyalty_store_id'], 'unique': true}]) }}

{% set batch %}
select distinct {{ hk(['h1.hk_loyalty_txn_id', 'h2.hk_store_id']) }} as hk_loyalty_store_id,
       h1.hk_loyalty_txn_id, h2.hk_store_id, s.batch_date, s.loaded_at, s.record_source
from {{ ref('stg_loyalty_transactions') }} s
join {{ ref('hub_loyalty_transaction') }} h1 on h1.loyalty_transaction_id = s.loyalty_transaction_id
join {{ ref('hub_store') }} h2 on h2.store_id = s.store_id
{% endset %}
{{ append_new(batch, ['hk_loyalty_store_id']) }}
