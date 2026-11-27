select c.card_id
from {{ ref('stg_cards') }} c
left join {{ ref('hub_customer') }} h using (client_id)
where h.client_id is null
