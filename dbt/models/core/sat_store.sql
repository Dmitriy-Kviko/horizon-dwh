{{ config(indexes=[{'columns': ['hk_store_id', 'batch_date'], 'unique': true}]) }}

{% set batch %}
select h.hk_store_id, h.batch_date, h.loaded_at, h.record_source,
       null::varchar(255) as address,
       null::varchar(100) as region,
       null::varchar(20) as phone,
       null::text as store_type
from {{ ref('hub_store') }} h
where h.batch_date = {{ batch_date() }}
{% endset %}
{{ historize(batch, 'hk_store_id', ['b.address', 'b.region', 'b.phone', 'b.store_type']) }}
