{{ config(indexes=[{'columns': ['hk_product_id', 'batch_date'], 'unique': true}]) }}

{% set batch %}
select h.hk_product_id, h.batch_date, h.loaded_at, h.record_source,
       null::numeric(10,2) as purchase_price,
       null::text as status
from {{ ref('hub_product') }} h
where h.batch_date = {{ batch_date() }}
{% endset %}
{{ historize(batch, 'hk_product_id', ['b.purchase_price', 'b.status']) }}
