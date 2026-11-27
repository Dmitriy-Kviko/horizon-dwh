{{ config(indexes=[{'columns': ['hk_employee_store_id'], 'unique': true}]) }}

{% set batch %}
select distinct {{ hk(['h1.hk_employee_id', 'h2.hk_store_id']) }} as hk_employee_store_id,
       h1.hk_employee_id, h2.hk_store_id, s.batch_date, s.loaded_at, s.record_source
from {{ ref('stg_employees') }} s
join {{ ref('hub_employee') }} h1 on h1.employee_id = s.employee_id
join {{ ref('hub_store') }} h2 on h2.store_id = s.store_id
{% endset %}
{{ append_new(batch, ['hk_employee_store_id']) }}
