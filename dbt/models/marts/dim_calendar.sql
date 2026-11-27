{{ config(indexes=[{'columns': ['date_key'], 'unique': true}]) }}

{% set batch %}
with day as (
    select {{ batch_date() }} as full_date
)
select to_char(full_date, 'YYYYMMDD')::integer as date_key,
       full_date,
       extract(isodow from full_date)::smallint as day_of_week,
       (array['Понедельник','Вторник','Среда','Четверг','Пятница','Суббота','Воскресенье'])
           [extract(isodow from full_date)::int]::varchar(11) as day_name,
       extract(month from full_date)::smallint as month,
       (array['Январь','Февраль','Март','Апрель','Май','Июнь',
              'Июль','Август','Сентябрь','Октябрь','Ноябрь','Декабрь'])
           [extract(month from full_date)::int]::varchar(10) as month_name,
       extract(quarter from full_date)::smallint as quarter,
       extract(year from full_date)::smallint as year,
       case when extract(month from full_date)=1 and extract(day from full_date) between 1 and 8
                  or to_char(full_date, 'MM-DD') in ('02-23','03-08','05-01','05-09','06-12','11-04')
            then true end as is_holiday
from day
{% endset %}
{{ append_new(batch, ['date_key']) }}
