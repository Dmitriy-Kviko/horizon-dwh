{{ config(indexes=[{'columns': ['hk_sale_id', 'batch_date'], 'unique': true}]) }}

{% set batch %}
select l.hk_sale_id, s.batch_date, s.loaded_at, s.record_source,
       s.sales_amount as amount, s.quantity
from {{ ref('stg_sales') }} s
join {{ ref('hub_transaction') }} t using (transaction_id)
join {{ ref('link_sale') }} l
  on l.hk_transaction_id = t.hk_transaction_id
 and l.batch_date = s.batch_date and l.line_no = s.line_no
{% endset %}
{{ historize(batch, 'hk_sale_id', ['b.amount','b.quantity']) }}
