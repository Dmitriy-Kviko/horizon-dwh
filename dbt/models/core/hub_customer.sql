{{ config(alias='hub_client', indexes=[{'columns': ['hk_client_id'], 'unique': true}]) }}

{% set batch %}
with keys as (
select client_id as client_id, batch_date, loaded_at, record_source
from {{ ref('stg_clients') }}
),
first_seen as (
    select distinct on (client_id) *
    from keys
    where client_id is not null
    order by client_id, batch_date, loaded_at, record_source
)
select {{ hk(['client_id']) }} as hk_client_id, *
from first_seen
{% endset %}
{{ append_new(batch, ['hk_client_id']) }}
