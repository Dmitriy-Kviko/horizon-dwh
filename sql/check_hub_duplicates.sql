-- Пустой результат означает, что дубли хэш-ключей отсутствуют.
SELECT 'hub_product' AS hub, hk_product_id AS hash_key, COUNT(*) AS copies
FROM core.hub_product GROUP BY hk_product_id HAVING COUNT(*) > 1
UNION ALL
SELECT 'hub_store' AS hub, hk_store_id AS hash_key, COUNT(*) AS copies
FROM core.hub_store GROUP BY hk_store_id HAVING COUNT(*) > 1
UNION ALL
SELECT 'hub_client' AS hub, hk_client_id AS hash_key, COUNT(*) AS copies
FROM core.hub_client GROUP BY hk_client_id HAVING COUNT(*) > 1
UNION ALL
SELECT 'hub_card' AS hub, hk_card_id AS hash_key, COUNT(*) AS copies
FROM core.hub_card GROUP BY hk_card_id HAVING COUNT(*) > 1
UNION ALL
SELECT 'hub_employee' AS hub, hk_employee_id AS hash_key, COUNT(*) AS copies
FROM core.hub_employee GROUP BY hk_employee_id HAVING COUNT(*) > 1
UNION ALL
SELECT 'hub_transaction' AS hub, hk_transaction_id AS hash_key, COUNT(*) AS copies
FROM core.hub_transaction GROUP BY hk_transaction_id HAVING COUNT(*) > 1
UNION ALL
SELECT 'hub_loyalty_transaction' AS hub, hk_loyalty_txn_id AS hash_key, COUNT(*) AS copies
FROM core.hub_loyalty_transaction GROUP BY hk_loyalty_txn_id HAVING COUNT(*) > 1;
