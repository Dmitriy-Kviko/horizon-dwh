select p.product_id as "Товар (SKU)", sum(f.sum_sales) as "Выручка, ₽"
from marts.fct_sales_daily f
join marts.dim_product p using (product_key)
group by p.product_id
order by sum(f.sum_sales) desc, p.product_id
limit 10;
