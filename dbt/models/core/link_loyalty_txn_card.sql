{{ config(indexes=[{'columns': ['hk_loyalty_card_id'], 'unique': true}]) }}

{% set batch %}
select distinct {{ hk(['h1.hk_loyalty_txn_id', 'h2.hk_card_id']) }} as hk_loyalty_card_id,
       h1.hk_loyalty_txn_id, h2.hk_card_id, s.batch_date, s.loaded_at, s.record_source
from {{ ref('stg_loyalty_transactions') }} s
join {{ ref('hub_loyalty_transaction') }} h1 on h1.loyalty_transaction_id = s.loyalty_transaction_id
join {{ ref('hub_card') }} h2 on h2.card_id = s.card_id
{% endset %}
{{ append_new(batch, ['hk_loyalty_card_id']) }}
