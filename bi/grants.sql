-- Выполняется в horizon владельцем витрин после создания роли horizon_bi.
GRANT CONNECT ON DATABASE horizon TO horizon_bi;
GRANT USAGE ON SCHEMA marts TO horizon_bi;
GRANT SELECT ON marts.fct_sales_daily, marts.dim_calendar, marts.dim_product, marts.dim_store TO horizon_bi;
