with raw as (
    {{ raw_batch('employees', 'hr') }}
)
select (payload->>'employee_id')::integer as employee_id,
       payload->>'full_name' as full_name, payload->>'position' as position,
       nullif(btrim(payload->>'store_id'),'') as store_id,
       coalesce(payload->>'hire_date', payload->>'ohire_date')::date as hire_date,
       (payload->>'termination_date')::date as termination_date,
       batch_date, loaded_at, record_source
from raw
