select hk_transaction_id
from {{ ref('sat_transaction_details') }}
group by hk_transaction_id
having count(*) > 1
