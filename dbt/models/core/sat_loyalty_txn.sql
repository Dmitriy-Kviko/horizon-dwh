{{ config(indexes=[{'columns': ['hk_loyalty_txn_id', 'batch_date'], 'unique': true}]) }}

{% set batch %}
select h.hk_loyalty_txn_id, s.batch_date, s.loaded_at, s.record_source,
       s.points as points,
       s.transaction_date as transaction_date,
       case when s.points > 0 then 'accrual' when s.points < 0 then 'redemption' end as operation_type
from {{ ref('hub_loyalty_transaction') }} h
join {{ ref('stg_loyalty_transactions') }} s on s.loyalty_transaction_id = h.loyalty_transaction_id
{% endset %}
{{ historize(batch, 'hk_loyalty_txn_id', ['b.points', 'b.transaction_date', 'b.operation_type']) }}
