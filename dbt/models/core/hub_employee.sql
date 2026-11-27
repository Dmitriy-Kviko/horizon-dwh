{{ config(indexes=[{'columns': ['hk_employee_id'], 'unique': true}]) }}

{% set batch %}
with keys as (
select employee_id as employee_id, batch_date, loaded_at, record_source
from {{ ref('stg_employees') }}
),
first_seen as (
    select distinct on (employee_id) *
    from keys
    where employee_id is not null
    order by employee_id, batch_date, loaded_at, record_source
)
select {{ hk(['employee_id']) }} as hk_employee_id, *
from first_seen
{% endset %}
{{ append_new(batch, ['hk_employee_id']) }}
