{{ config(indexes=[{'columns': ['store_key'], 'unique': true}]) }}

{% set batch %}
select h.store_id, s.address, s.region,
       s.batch_date as valid_from, null::date as valid_to, true as is_current
from {{ ref('hub_store') }} h
join {{ ref('sat_store') }} s
  on s.hk_store_id = h.hk_store_id and s.batch_date = h.batch_date
{% endset %}
{{ new_dimension(batch, 'store_id', 'store_key') }}
