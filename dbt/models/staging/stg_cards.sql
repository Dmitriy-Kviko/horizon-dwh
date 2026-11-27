with raw as (
    {{ raw_batch('cards', 'loyalty') }}
)
select (payload->>'card_id')::integer as card_id, (payload->>'client_id')::integer as client_id,
       payload->>'card_number' as card_number, (payload->>'issue_date')::date as issue_date,
       payload->>'status' as status, batch_date, loaded_at, record_source
from raw
