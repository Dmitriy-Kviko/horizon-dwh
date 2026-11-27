{{ config(indexes=[{'columns': ['hk_sale_id'], 'unique': true}]) }}

{% set batch %}
select distinct {{ hk(['h1.hk_transaction_id', 'h2.hk_product_id', 's.line_no']) }} as hk_sale_id,
       h1.hk_transaction_id, h2.hk_product_id, s.line_no, s.batch_date, s.loaded_at, s.record_source
from {{ ref('stg_sales') }} s
join {{ ref('hub_transaction') }} h1 on h1.transaction_id = s.transaction_id
join {{ ref('hub_product') }} h2 on h2.product_id = s.product_id
{% endset %}
{{ append_new(batch, ['hk_sale_id']) }}
