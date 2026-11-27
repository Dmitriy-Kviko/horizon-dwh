{{ config(indexes=[{'columns': ['hk_card_client_id'], 'unique': true}]) }}

{% set batch %}
select distinct {{ hk(['h1.hk_card_id', 'h2.hk_client_id']) }} as hk_card_client_id,
       h1.hk_card_id, h2.hk_client_id, s.batch_date, s.loaded_at, s.record_source
from {{ ref('stg_cards') }} s
join {{ ref('hub_card') }} h1 on h1.card_id = s.card_id
join {{ ref('hub_customer') }} h2 on h2.client_id = s.client_id
{% endset %}
{{ append_new(batch, ['hk_card_client_id']) }}
