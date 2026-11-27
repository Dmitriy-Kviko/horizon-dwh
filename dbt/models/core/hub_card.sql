{{ config(indexes=[{'columns': ['hk_card_id'], 'unique': true}]) }}

{% set batch %}
with keys as (
select card_id as card_id, batch_date, loaded_at, record_source
from {{ ref('stg_cards') }}
),
first_seen as (
    select distinct on (card_id) *
    from keys
    where card_id is not null
    order by card_id, batch_date, loaded_at, record_source
)
select {{ hk(['card_id']) }} as hk_card_id, *
from first_seen
{% endset %}
{{ append_new(batch, ['hk_card_id']) }}
