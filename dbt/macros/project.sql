{% macro generate_schema_name(custom_schema_name, node) %}
  {{ (custom_schema_name or target.schema) | trim }}
{% endmacro %}

{% macro batch_date() %}
  '{{ var("batch_date", "2000-01-01") }}'::date
{% endmacro %}

{% macro hk(fields) %}
  md5(jsonb_build_array({{ fields | join(', ') }})::text)
{% endmacro %}

{% macro raw_batch(entity, source_system) %}
select r.payload, r.row_no, r.batch_date, b.loaded_at, b.source_system as record_source
from {{ source('raw', 'raw_records') }} r
join {{ source('raw', 'load_batches') }} b using (batch_date)
where r.entity = '{{ entity }}'
  and b.source_system = '{{ source_system }}'
  and r.batch_date = {{ batch_date() }}
{% endmacro %}

{% macro append_new(query, keys) %}
with batch as (
    {{ query }}
)
select b.*
from batch b
{% if is_incremental() %}
where not exists (
    select 1 from {{ this }} t
    where {% for k in keys %} t.{{ k }} = b.{{ k }} {% if not loop.last %} and {% endif %}{% endfor %}
)
{% endif %}
{% endmacro %}

{% macro historize(query, parent_key, attributes) %}
with batch as (
    {{ query }}
),
hashed as (
    select b.*, {{ hk(attributes) }} as hashdiff
    from batch b
)
select b.*
from hashed b
{% if is_incremental() %}
-- Одна версия на пакет. Пишем новую версию только при изменении атрибутов.
left join lateral (
    select t.hashdiff
    from {{ this }} t
    where t.{{ parent_key }} = b.{{ parent_key }} and t.batch_date < b.batch_date
    order by t.batch_date desc
    limit 1
) previous on true
where previous.hashdiff is distinct from b.hashdiff
  and not exists (
    select 1 from {{ this }} t
    where t.{{ parent_key }} = b.{{ parent_key }} and t.batch_date = b.batch_date
  )
{% endif %}
{% endmacro %}

{% macro new_dimension(query, business_key, sk) %}
with attrs as (
    {{ query }}
),
new_members as (
    select a.*
    from attrs a
    {% if is_incremental() %}
    where not exists (select 1 from {{ this }} d where d.{{ business_key }} = a.{{ business_key }})
    {% endif %}
)
-- Ключи уже опубликованных элементов сохраняются. DAG сериализует запуски.
select (
    {% if is_incremental() %}(select coalesce(max({{ sk }}), 0) from {{ this }}) +{% endif %}
    row_number() over (order by {{ business_key }})
)::integer as {{ sk }}, *
from new_members
{% endmacro %}
