with totals as (
    select case entity
               when 'sales' then 'sales'
               when 'employees' then 'hr'
               else 'loyalty'
           end as source_system, count(*) as row_count
    from {{ source('raw','raw_records') }}
    where batch_date = {{ batch_date() }}
    group by 1
)
select b.source_system, b.row_count, coalesce(r.row_count,0) as actual
from {{ source('raw','load_batches') }} b
left join totals r using (source_system)
where b.batch_date = {{ batch_date() }} and b.row_count <> coalesce(r.row_count,0)
