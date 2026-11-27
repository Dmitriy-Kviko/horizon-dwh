{{ config(indexes=[{'columns': ['hk_employee_id', 'batch_date'], 'unique': true}]) }}

{% set batch %}
select h.hk_employee_id, s.batch_date, s.loaded_at, s.record_source,
       s.full_name as full_name,
       s.position as position,
       s.hire_date as hire_date,
       s.termination_date as termination_date
from {{ ref('hub_employee') }} h
join {{ ref('stg_employees') }} s on s.employee_id = h.employee_id
{% endset %}
{{ historize(batch, 'hk_employee_id', ['b.full_name', 'b.position', 'b.hire_date', 'b.termination_date']) }}
