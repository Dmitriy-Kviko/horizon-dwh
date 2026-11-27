select c.full_date as "Дата", sum(f.sum_sales) as "Выручка, ₽"
from marts.fct_sales_daily f
join marts.dim_calendar c using (date_key)
group by c.full_date
order by c.full_date;
