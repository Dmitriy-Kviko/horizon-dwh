with raw as (
    {{ raw_batch('sales', 'sales') }}
)
select (payload->>'transaction_id')::uuid::text as transaction_id,
       nullif(btrim(payload->>'product_id'), '') as product_id,
       nullif(btrim(payload->>'store_id'), '') as store_id,
       (payload->>'amount')::numeric(10,2) as sales_amount,
       coalesce(payload->>'quantity', payload->>'oquantity')::numeric(10,3) as quantity,
       (payload->>'datetime')::timestamp as sold_at,
       nullif(payload->>'payment_method','') as payment_method,
       row_no as line_no, batch_date, loaded_at, record_source
from raw
