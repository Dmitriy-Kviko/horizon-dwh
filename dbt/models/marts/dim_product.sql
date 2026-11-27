{{ config(indexes=[{'columns': ['product_key'], 'unique': true}]) }}

{% set batch %}
select h.product_id, s.product_name, s.category, s.brand,
       s.batch_date as valid_from, null::date as valid_to, true as is_current
from {{ ref('hub_product') }} h
join {{ ref('sat_product_static') }} s
  on s.hk_product_id = h.hk_product_id and s.batch_date = h.batch_date
{% endset %}
{{ new_dimension(batch, 'product_id', 'product_key') }}
