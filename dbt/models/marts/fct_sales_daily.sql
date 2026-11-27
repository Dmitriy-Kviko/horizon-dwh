{{ config(indexes=[{'columns': ['date_key', 'store_key', 'product_key'], 'unique': true}]) }}

{% set batch %}
select * from {{ ref('int_sales_daily_batch') }}
{% endset %}
{{ append_new(batch, ['date_key','store_key','product_key']) }}
