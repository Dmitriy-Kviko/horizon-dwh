select x.loyalty_transaction_id
from {{ ref('stg_loyalty_transactions') }} x
left join {{ ref('hub_card') }} h using (card_id)
where h.card_id is null
