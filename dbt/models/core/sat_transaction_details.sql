{{ config(alias='sat_transaction', indexes=[{'columns': ['hk_transaction_id', 'batch_date'], 'unique': true}]) }}

{% set batch %}
select h.hk_transaction_id, s.batch_date, s.loaded_at, s.record_source,
       min(s.sold_at) as sold_at,
       sum(s.sales_amount)::numeric(14,2) as total_amount,
       max(s.payment_method) as payment_method
from {{ ref('hub_transaction') }} h
join {{ ref('stg_sales') }} s on s.transaction_id = h.transaction_id
group by h.hk_transaction_id, s.batch_date, s.loaded_at, s.record_source
{% endset %}
{{ historize(batch, 'hk_transaction_id', ['b.sold_at', 'b.total_amount', 'b.payment_method']) }}
