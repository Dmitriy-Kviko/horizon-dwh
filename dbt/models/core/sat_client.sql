{{ config(indexes=[{'columns': ['hk_client_id', 'batch_date'], 'unique': true}]) }}

{% set batch %}
select h.hk_client_id, s.batch_date, s.loaded_at, s.record_source,
       s.full_name as full_name,
       s.birth_date as birth_date,
       s.phone as phone,
       s.email as email,
       s.registration_date as registration_date
from {{ ref('hub_customer') }} h
join {{ ref('stg_clients') }} s on s.client_id = h.client_id
{% endset %}
{{ historize(batch, 'hk_client_id', ['b.full_name', 'b.birth_date', 'b.phone', 'b.email', 'b.registration_date']) }}
