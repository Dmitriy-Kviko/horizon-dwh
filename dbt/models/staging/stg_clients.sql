with raw as (
    {{ raw_batch('clients', 'loyalty') }}
)
select (payload->>'client_id')::integer as client_id,
       payload->>'full_name' as full_name, (payload->>'birth_date')::date as birth_date,
       payload->>'phone' as phone, payload->>'email' as email,
       (payload->>'registration_date')::date as registration_date,
       batch_date, loaded_at, record_source
from raw
