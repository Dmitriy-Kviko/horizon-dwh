CREATE TABLE IF NOT EXISTS public.clients (
    client_id integer PRIMARY KEY, full_name varchar(255), birth_date date,
    phone varchar(20), email varchar(255), registration_date date NOT NULL
);
CREATE TABLE IF NOT EXISTS public.cards (
    card_id integer PRIMARY KEY, client_id integer NOT NULL REFERENCES public.clients,
    card_number varchar(50), issue_date date NOT NULL, status varchar(20) NOT NULL
);
CREATE TABLE IF NOT EXISTS public.transactions (
    loyalty_transaction_id integer PRIMARY KEY,
    card_id integer NOT NULL REFERENCES public.cards,
    points integer NOT NULL, transaction_date timestamp NOT NULL,
    store_id text, source_transaction_id text
);
