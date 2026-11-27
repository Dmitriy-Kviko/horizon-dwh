{{ config(indexes=[{'columns': ['hk_loyalty_source_id'], 'unique': true}]) }}

{% set batch %}
select distinct {{ hk(['h1.hk_loyalty_txn_id', 'h2.hk_transaction_id']) }} as hk_loyalty_source_id,
       h1.hk_loyalty_txn_id, h2.hk_transaction_id, s.batch_date, s.loaded_at, s.record_source
from {{ ref('stg_loyalty_transactions') }} s
join {{ ref('hub_loyalty_transaction') }} h1 on h1.loyalty_transaction_id = s.loyalty_transaction_id
join {{ ref('hub_transaction') }} h2 on h2.transaction_id = s.source_transaction_id
{% endset %}
{{ append_new(batch, ['hk_loyalty_source_id']) }}
