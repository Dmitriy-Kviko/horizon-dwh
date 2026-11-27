CREATE SCHEMA IF NOT EXISTS staging;

CREATE TABLE IF NOT EXISTS staging.raw_records (
    batch_date date NOT NULL,
    entity text NOT NULL,
    row_no integer NOT NULL CHECK (row_no > 0),
    payload jsonb NOT NULL,
    PRIMARY KEY (entity, batch_date, row_no)
);

CREATE TABLE IF NOT EXISTS staging.load_batches (
    batch_date date NOT NULL,
    source_system text NOT NULL,
    source_ref text NOT NULL,
    row_count integer NOT NULL CHECK (row_count >= 0),
    loaded_at timestamptz NOT NULL DEFAULT now(),
    PRIMARY KEY (source_system, batch_date)
);
