{{ config(alias='link_transaction_store', indexes=[{'columns': ['hk_txn_store_id'], 'unique': true}]) }}

{% set batch %}
select distinct {{ hk(['h1.hk_transaction_id', 'h2.hk_store_id']) }} as hk_txn_store_id,
       h1.hk_transaction_id, h2.hk_store_id, s.batch_date, s.loaded_at, s.record_source
from {{ ref('stg_sales') }} s
join {{ ref('hub_transaction') }} h1 on h1.transaction_id = s.transaction_id
join {{ ref('hub_store') }} h2 on h2.store_id = s.store_id
{% endset %}
{{ append_new(batch, ['hk_txn_store_id']) }}
