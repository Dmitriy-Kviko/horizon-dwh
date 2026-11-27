{{ config(indexes=[{'columns': ['hk_product_id', 'batch_date'], 'unique': true}]) }}

{% set batch %}
select h.hk_product_id, h.batch_date, h.loaded_at, h.record_source,
       null::varchar(255) as product_name,
       null::varchar(100) as category,
       null::varchar(100) as brand
from {{ ref('hub_product') }} h
where h.batch_date = {{ batch_date() }}
{% endset %}
{{ historize(batch, 'hk_product_id', ['b.product_name', 'b.category', 'b.brand']) }}
