with raw as (
    {{ raw_batch('loyalty_transactions', 'loyalty') }}
)
select (payload->>'loyalty_transaction_id')::integer as loyalty_transaction_id,
       (payload->>'card_id')::integer as card_id, (payload->>'points')::integer as points,
       (payload->>'transaction_date')::timestamp as transaction_date,
       nullif(btrim(payload->>'store_id'),'') as store_id,
       nullif(btrim(payload->>'source_transaction_id'),'')::uuid::text as source_transaction_id,
       batch_date, loaded_at, record_source
from raw
