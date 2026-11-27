{{ config(indexes=[{'columns': ['hk_card_id', 'batch_date'], 'unique': true}]) }}

{% set batch %}
select h.hk_card_id, s.batch_date, s.loaded_at, s.record_source,
       s.card_number as card_number,
       s.issue_date as issue_date,
       s.status as status
from {{ ref('hub_card') }} h
join {{ ref('stg_cards') }} s on s.card_id = h.card_id
{% endset %}
{{ historize(batch, 'hk_card_id', ['b.card_number', 'b.issue_date', 'b.status']) }}
