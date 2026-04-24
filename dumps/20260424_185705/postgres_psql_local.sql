--
-- PostgreSQL database dump
--

\restrict ce8CckPszSii2OOLobsYBrhD4Laoyk5JOrOcYiGoCLIy5SlcOZufOBZZEIiDoqN

-- Dumped from database version 15.17
-- Dumped by pg_dump version 15.17

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: bank_infos; Type: TABLE; Schema: public; Owner: postgres_user
--

CREATE TABLE public.bank_infos (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    created_by uuid,
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_by uuid,
    deleted_at timestamp with time zone,
    deleted_by uuid,
    bank_name character varying(300) NOT NULL,
    bank_code character varying(10) NOT NULL,
    swift_code character varying(30)
);


ALTER TABLE public.bank_infos OWNER TO postgres_user;

--
-- Name: channel_groups; Type: TABLE; Schema: public; Owner: postgres_user
--

CREATE TABLE public.channel_groups (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    created_by uuid,
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_by uuid,
    deleted_at timestamp with time zone,
    deleted_by uuid,
    channel_group_name character varying(255) NOT NULL
);


ALTER TABLE public.channel_groups OWNER TO postgres_user;

--
-- Name: disbursement_limit_amounts; Type: TABLE; Schema: public; Owner: postgres_user
--

CREATE TABLE public.disbursement_limit_amounts (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    created_by uuid,
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_by uuid,
    deleted_at timestamp with time zone,
    deleted_by uuid,
    provider_channel_id uuid NOT NULL,
    min_amount numeric(16,2) DEFAULT 0.00,
    max_amount numeric(16,2) DEFAULT 0.00
);


ALTER TABLE public.disbursement_limit_amounts OWNER TO postgres_user;

--
-- Name: holiday_dates; Type: TABLE; Schema: public; Owner: postgres_user
--

CREATE TABLE public.holiday_dates (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    created_by uuid,
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_by uuid,
    deleted_at timestamp with time zone,
    deleted_by uuid,
    holiday_date date,
    description text
);


ALTER TABLE public.holiday_dates OWNER TO postgres_user;

--
-- Name: master_channels; Type: TABLE; Schema: public; Owner: postgres_user
--

CREATE TABLE public.master_channels (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    created_by uuid,
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_by uuid,
    deleted_at timestamp with time zone,
    deleted_by uuid,
    channel_group_id uuid NOT NULL,
    channel_name character varying(300) NOT NULL,
    channel_code character varying(300) NOT NULL,
    transaction_type character varying(300) NOT NULL,
    description text,
    endpoint_url character varying(300),
    service_code character varying(10)
);


ALTER TABLE public.master_channels OWNER TO postgres_user;

--
-- Name: merchant_api_credentials; Type: TABLE; Schema: public; Owner: postgres_user
--

CREATE TABLE public.merchant_api_credentials (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    created_by uuid,
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_by uuid,
    deleted_at timestamp with time zone,
    deleted_by uuid,
    merchant_id uuid NOT NULL,
    secret_key character varying(300) NOT NULL,
    public_key text NOT NULL,
    client_key character varying(100) NOT NULL
);


ALTER TABLE public.merchant_api_credentials OWNER TO postgres_user;

--
-- Name: merchant_balance_mutations; Type: TABLE; Schema: public; Owner: postgres_user
--

CREATE TABLE public.merchant_balance_mutations (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    created_by uuid,
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_by uuid,
    deleted_at timestamp with time zone,
    deleted_by uuid,
    merchant_id uuid NOT NULL,
    mutation_date date DEFAULT CURRENT_DATE NOT NULL,
    mutation_datetime timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    mutation_amount numeric(16,2) DEFAULT 0.0 NOT NULL,
    previous_balance numeric(16,2) DEFAULT 0.0 NOT NULL,
    current_balance numeric(16,2) DEFAULT 0.0 NOT NULL,
    transaction_type character varying(100),
    reference_id character varying(255),
    note text,
    mutation_type character varying(255)
);


ALTER TABLE public.merchant_balance_mutations OWNER TO postgres_user;

--
-- Name: merchant_banks; Type: TABLE; Schema: public; Owner: postgres_user
--

CREATE TABLE public.merchant_banks (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    created_by uuid,
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_by uuid,
    deleted_at timestamp with time zone,
    deleted_by uuid,
    merchant_id uuid NOT NULL,
    bank_info_id uuid NOT NULL,
    account_name character varying(500) NOT NULL,
    account_number character varying(100) NOT NULL,
    is_default boolean DEFAULT false NOT NULL
);


ALTER TABLE public.merchant_banks OWNER TO postgres_user;

--
-- Name: merchant_categories; Type: TABLE; Schema: public; Owner: postgres_user
--

CREATE TABLE public.merchant_categories (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    created_by uuid,
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_by uuid,
    deleted_at timestamp with time zone,
    deleted_by uuid,
    merchant_category_name character varying(300) NOT NULL,
    merchant_category_description character varying(500),
    merchant_category_code character varying(100)
);


ALTER TABLE public.merchant_categories OWNER TO postgres_user;

--
-- Name: merchant_channels; Type: TABLE; Schema: public; Owner: postgres_user
--

CREATE TABLE public.merchant_channels (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    created_by uuid,
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_by uuid,
    deleted_at timestamp with time zone,
    deleted_by uuid,
    merchant_id uuid NOT NULL,
    master_channel_id uuid NOT NULL,
    transaction_type character varying(255) NOT NULL,
    merchant_callback_url character varying(255),
    retry_callback_count integer DEFAULT 5,
    retry_callback_interval integer DEFAULT 3,
    callback_client_key character varying(100),
    callback_secret_key character varying(300),
    callback_partner_id character varying(100),
    callback_private_key text,
    callback_public_key text
);


ALTER TABLE public.merchant_channels OWNER TO postgres_user;

--
-- Name: merchant_disbursement_limit_rules; Type: TABLE; Schema: public; Owner: postgres_user
--

CREATE TABLE public.merchant_disbursement_limit_rules (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    created_by uuid,
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_by uuid,
    deleted_at timestamp with time zone,
    deleted_by uuid,
    merchant_id uuid NOT NULL,
    limit_amount numeric(16,2) DEFAULT 0.00,
    limit_cycle character varying(30) NOT NULL
);


ALTER TABLE public.merchant_disbursement_limit_rules OWNER TO postgres_user;

--
-- Name: merchant_fees; Type: TABLE; Schema: public; Owner: postgres_user
--

CREATE TABLE public.merchant_fees (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    created_by uuid,
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_by uuid,
    deleted_at timestamp with time zone,
    deleted_by uuid,
    merchant_id uuid NOT NULL,
    merchant_channel_id uuid NOT NULL,
    fee_type character varying(30) NOT NULL,
    fee_fixed numeric(10,2) NOT NULL,
    fee_percentage numeric(5,2) NOT NULL,
    fee_status character varying(50) DEFAULT 'INACTIVE'::character varying NOT NULL,
    begin_active_date timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    end_active_date timestamp with time zone
);


ALTER TABLE public.merchant_fees OWNER TO postgres_user;

--
-- Name: merchant_settlement_configurations; Type: TABLE; Schema: public; Owner: postgres_user
--

CREATE TABLE public.merchant_settlement_configurations (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    created_by uuid,
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_by uuid,
    deleted_at timestamp with time zone,
    deleted_by uuid,
    merchant_id uuid NOT NULL,
    settlement_type character varying(5) NOT NULL,
    settlement_day integer DEFAULT 0 NOT NULL,
    settlement_times character varying(8)[] DEFAULT '{}'::character varying[] NOT NULL,
    status character varying(50) DEFAULT 'ACTIVE'::character varying NOT NULL
);


ALTER TABLE public.merchant_settlement_configurations OWNER TO postgres_user;

--
-- Name: merchant_settlement_histories; Type: TABLE; Schema: public; Owner: postgres_user
--

CREATE TABLE public.merchant_settlement_histories (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    created_by uuid,
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_by uuid,
    deleted_at timestamp with time zone,
    deleted_by uuid,
    merchant_id uuid NOT NULL,
    settlement_datetime timestamp with time zone NOT NULL,
    settlement_type character varying(5) NOT NULL,
    is_current_settlement boolean DEFAULT false NOT NULL,
    merchant_settlement_config_id uuid NOT NULL
);


ALTER TABLE public.merchant_settlement_histories OWNER TO postgres_user;

--
-- Name: merchants; Type: TABLE; Schema: public; Owner: postgres_user
--

CREATE TABLE public.merchants (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    created_by uuid,
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_by uuid,
    deleted_at timestamp with time zone,
    deleted_by uuid,
    merchant_name character varying(500) NOT NULL,
    email character varying(300) NOT NULL,
    phone character varying(50) NOT NULL,
    status character varying(50) DEFAULT 'INACTIVE'::character varying NOT NULL,
    merchant_category_id uuid,
    owner character varying(300),
    merchant_code character varying(15),
    settled_balance numeric(16,2) DEFAULT 0.0
);


ALTER TABLE public.merchants OWNER TO postgres_user;

--
-- Name: provider_api_credentials; Type: TABLE; Schema: public; Owner: postgres_user
--

CREATE TABLE public.provider_api_credentials (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    created_by uuid,
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_by uuid,
    deleted_at timestamp with time zone,
    deleted_by uuid,
    provider_id uuid NOT NULL,
    is_snap boolean DEFAULT true NOT NULL,
    client_key character varying(500),
    client_secret character varying(500),
    public_key text,
    private_key text,
    additional_info jsonb,
    provider_channel_id uuid,
    service_code character varying(3),
    callback_public_key text,
    callback_client_key character varying(255),
    callback_secret_key character varying(255)
);


ALTER TABLE public.provider_api_credentials OWNER TO postgres_user;

--
-- Name: provider_channels; Type: TABLE; Schema: public; Owner: postgres_user
--

CREATE TABLE public.provider_channels (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    created_by uuid,
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_by uuid,
    deleted_at timestamp with time zone,
    deleted_by uuid,
    provider_id uuid NOT NULL,
    transaction_type character varying(255) NOT NULL,
    master_channel_id uuid NOT NULL,
    status character varying(50) DEFAULT 'INACTIVE'::character varying NOT NULL,
    adapter_status character varying(50) DEFAULT 'INACTIVE'::character varying NOT NULL,
    endpoint_url character varying(500),
    provider_reference_length integer DEFAULT 12 NOT NULL
);


ALTER TABLE public.provider_channels OWNER TO postgres_user;

--
-- Name: provider_channels_auth_histories; Type: TABLE; Schema: public; Owner: postgres_user
--

CREATE TABLE public.provider_channels_auth_histories (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    created_by uuid,
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_by uuid,
    deleted_at timestamp with time zone,
    deleted_by uuid,
    provider_channel_id uuid NOT NULL,
    response_code character varying(30) NOT NULL,
    response_message character varying(500),
    response_status character varying(30)
);


ALTER TABLE public.provider_channels_auth_histories OWNER TO postgres_user;

--
-- Name: provider_disbursement_traffic_balances; Type: TABLE; Schema: public; Owner: postgres_user
--

CREATE TABLE public.provider_disbursement_traffic_balances (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    created_by uuid,
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_by uuid,
    deleted_at timestamp with time zone,
    deleted_by uuid,
    provider_channel_id uuid NOT NULL,
    channel_code character varying(50) NOT NULL,
    weight integer DEFAULT 0 NOT NULL
);


ALTER TABLE public.provider_disbursement_traffic_balances OWNER TO postgres_user;

--
-- Name: provider_fees; Type: TABLE; Schema: public; Owner: postgres_user
--

CREATE TABLE public.provider_fees (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    created_by uuid,
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_by uuid,
    deleted_at timestamp with time zone,
    deleted_by uuid,
    provider_channel_id uuid NOT NULL,
    provider_id uuid,
    fee_type character varying(255) NOT NULL,
    fee_fixed numeric(10,2) DEFAULT 0.00 NOT NULL,
    fee_percentage numeric(10,2) DEFAULT 0.00 NOT NULL,
    fee_status character varying(255) DEFAULT 'INACTIVE'::character varying NOT NULL,
    begin_active_date timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    end_active_date timestamp with time zone
);


ALTER TABLE public.provider_fees OWNER TO postgres_user;

--
-- Name: provider_response_codes; Type: TABLE; Schema: public; Owner: postgres_user
--

CREATE TABLE public.provider_response_codes (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    created_by uuid,
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_by uuid,
    deleted_at timestamp with time zone,
    deleted_by uuid,
    provider_id uuid NOT NULL,
    response_code character varying(300) NOT NULL,
    messages character varying(500)
);


ALTER TABLE public.provider_response_codes OWNER TO postgres_user;

--
-- Name: providers; Type: TABLE; Schema: public; Owner: postgres_user
--

CREATE TABLE public.providers (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    created_by uuid,
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_by uuid,
    deleted_at timestamp with time zone,
    deleted_by uuid,
    name character varying(300) NOT NULL,
    adapter_name character varying(300) NOT NULL,
    status character varying(100) DEFAULT 'INACTIVE'::character varying NOT NULL,
    adapter_deployment_service character varying(255),
    api_timeout integer DEFAULT 0 NOT NULL,
    api_retry integer DEFAULT 0 NOT NULL,
    deposit_balance numeric(16,2) DEFAULT 0.00 NOT NULL
);


ALTER TABLE public.providers OWNER TO postgres_user;

--
-- Name: qris_acquirers; Type: TABLE; Schema: public; Owner: postgres_user
--

CREATE TABLE public.qris_acquirers (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    created_by uuid,
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_by uuid,
    deleted_at timestamp with time zone,
    deleted_by uuid,
    provider_channel_id uuid NOT NULL,
    acquirer_name character varying(255) NOT NULL
);


ALTER TABLE public.qris_acquirers OWNER TO postgres_user;

--
-- Name: schema_migrations; Type: TABLE; Schema: public; Owner: postgres_user
--

CREATE TABLE public.schema_migrations (
    version bigint NOT NULL,
    dirty boolean NOT NULL
);


ALTER TABLE public.schema_migrations OWNER TO postgres_user;

--
-- Name: settlement_processes; Type: TABLE; Schema: public; Owner: postgres_user
--

CREATE TABLE public.settlement_processes (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    created_by uuid,
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_by uuid,
    deleted_at timestamp with time zone,
    deleted_by uuid,
    merchant_id uuid NOT NULL,
    settlement_type character varying(5) NOT NULL,
    settlement_day integer NOT NULL,
    begin_settlement_datetime timestamp with time zone NOT NULL,
    end_settlement_datetime timestamp with time zone NOT NULL,
    settlement_datetime timestamp with time zone NOT NULL,
    settlement_amount numeric(16,2) DEFAULT 0.0 NOT NULL,
    settlement_batch_id character varying(255),
    store_id uuid,
    store_name character varying(300)
);


ALTER TABLE public.settlement_processes OWNER TO postgres_user;

--
-- Name: store_qris_nmids; Type: TABLE; Schema: public; Owner: postgres_user
--

CREATE TABLE public.store_qris_nmids (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    created_by uuid,
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_by uuid,
    deleted_at timestamp with time zone,
    deleted_by uuid,
    merchant_id uuid NOT NULL,
    store_id uuid NOT NULL,
    nmid character varying(255) NOT NULL,
    qris_acquirer_id uuid NOT NULL
);


ALTER TABLE public.store_qris_nmids OWNER TO postgres_user;

--
-- Name: store_transaction_limit_rules; Type: TABLE; Schema: public; Owner: postgres_user
--

CREATE TABLE public.store_transaction_limit_rules (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    created_by uuid,
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_by uuid,
    deleted_at timestamp with time zone,
    deleted_by uuid,
    store_id uuid NOT NULL,
    limit_amount numeric(16,2) DEFAULT 0 NOT NULL,
    limit_cycle character varying(30) DEFAULT 'DAILY'::character varying NOT NULL
);


ALTER TABLE public.store_transaction_limit_rules OWNER TO postgres_user;

--
-- Name: stores; Type: TABLE; Schema: public; Owner: postgres_user
--

CREATE TABLE public.stores (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    created_by uuid,
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_by uuid,
    deleted_at timestamp with time zone,
    deleted_by uuid,
    merchant_id uuid NOT NULL,
    store_name character varying(500) NOT NULL,
    address text,
    status character varying(100) DEFAULT 'INACTIVE'::character varying NOT NULL,
    pending_balance numeric(16,2) DEFAULT 0.0
);


ALTER TABLE public.stores OWNER TO postgres_user;

--
-- Name: transactions; Type: TABLE; Schema: public; Owner: postgres_user
--

CREATE TABLE public.transactions (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    created_by uuid,
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_by uuid,
    deleted_at timestamp with time zone,
    deleted_by uuid,
    merchant_id uuid NOT NULL,
    store_id uuid NOT NULL,
    transaction_timestamp timestamp with time zone NOT NULL,
    status_changed_timestamp timestamp with time zone,
    transaction_date date NOT NULL,
    transaction_type character varying(20) NOT NULL,
    transaction_status character varying(20) NOT NULL,
    previous_transaction_status character varying(20),
    transaction_expired_time timestamp with time zone,
    transaction_valid_time bigint DEFAULT 0 NOT NULL,
    transaction_paid_at timestamp with time zone,
    channel character varying(30),
    channel_group character varying(30),
    amount numeric(15,2),
    fee numeric(10,2),
    provider_fee numeric(10,2),
    fee_type character varying(25),
    fee_id uuid,
    provider_id uuid,
    provider_channel_id uuid,
    provider_fee_id uuid,
    provider_snap boolean DEFAULT false NOT NULL,
    provider_response_code character varying(10),
    provider_response_message character varying(300),
    provider_reference character varying(100),
    provider_status_changed_timestamp timestamp with time zone,
    provider_previous_response_code character varying(10),
    provider_previous_response_message character varying(300),
    reference character varying(100),
    merchant_reference character varying(100),
    merchant_callback_url character varying(500),
    merchant_callback_response_code character varying(10),
    merchant_callback_response_message character varying(300),
    merchant_callback_sent_timestamp timestamp with time zone,
    revenue numeric(10,2),
    bank_code character varying(10),
    bank_account_id uuid,
    additional_info jsonb,
    acquirer character varying(100),
    settled_at timestamp with time zone,
    is_settled boolean DEFAULT false NOT NULL,
    response_code character varying(10),
    response_message character varying(300),
    previous_response_code character varying(10),
    previous_response_message character varying(300),
    currency character varying(5),
    retrieval_reference_number character varying(255),
    merchant_fixed_fee numeric(16,2),
    merchant_percentage_fee numeric(16,2),
    mpan character varying(255),
    merchant_amount numeric(16,2) DEFAULT 0.0,
    settlement_status character varying(30) DEFAULT 'PENDING'::character varying NOT NULL,
    settlement_batch_id character varying(255),
    payer_name character varying(500),
    payer_phone_number character varying(40)
);


ALTER TABLE public.transactions OWNER TO postgres_user;

--
-- Name: user_credentials; Type: TABLE; Schema: public; Owner: postgres_user
--

CREATE TABLE public.user_credentials (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    created_by uuid,
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_by uuid,
    deleted_at timestamp with time zone,
    deleted_by uuid,
    username character varying(300) NOT NULL,
    password character varying(300) NOT NULL,
    role character varying(300) NOT NULL,
    is_enabled boolean DEFAULT true NOT NULL,
    profile_id uuid NOT NULL,
    merchant_id uuid
);


ALTER TABLE public.user_credentials OWNER TO postgres_user;

--
-- Name: user_profiles; Type: TABLE; Schema: public; Owner: postgres_user
--

CREATE TABLE public.user_profiles (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    created_by uuid,
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_by uuid,
    deleted_at timestamp with time zone,
    deleted_by uuid,
    profile_name character varying(300),
    email character varying(200),
    phone character varying(50),
    merchant_id uuid
);


ALTER TABLE public.user_profiles OWNER TO postgres_user;

--
-- Data for Name: bank_infos; Type: TABLE DATA; Schema: public; Owner: postgres_user
--

COPY public.bank_infos (id, created_at, created_by, updated_at, updated_by, deleted_at, deleted_by, bank_name, bank_code, swift_code) FROM stdin;
db5404b6-a542-4c56-90b9-d8bf875c3146	2026-01-15 08:49:15.879715+00	\N	2026-01-15 08:49:15.879715+00	\N	\N	\N	BANK OF TOKYO MITSUBISHI UFJ, LTD.	042	BOTKIDJX
\.


--
-- Data for Name: channel_groups; Type: TABLE DATA; Schema: public; Owner: postgres_user
--

COPY public.channel_groups (id, created_at, created_by, updated_at, updated_by, deleted_at, deleted_by, channel_group_name) FROM stdin;
47d31ac9-bfb1-4119-9339-56f6d70fb6cf	2026-04-23 08:25:43.756499+00	5f7e8b2f-c678-45eb-990a-5155ffef61f9	2026-04-23 08:25:43.756499+00	5f7e8b2f-c678-45eb-990a-5155ffef61f9	\N	\N	QRIS
\.


--
-- Data for Name: disbursement_limit_amounts; Type: TABLE DATA; Schema: public; Owner: postgres_user
--

COPY public.disbursement_limit_amounts (id, created_at, created_by, updated_at, updated_by, deleted_at, deleted_by, provider_channel_id, min_amount, max_amount) FROM stdin;
\.


--
-- Data for Name: holiday_dates; Type: TABLE DATA; Schema: public; Owner: postgres_user
--

COPY public.holiday_dates (id, created_at, created_by, updated_at, updated_by, deleted_at, deleted_by, holiday_date, description) FROM stdin;
\.


--
-- Data for Name: master_channels; Type: TABLE DATA; Schema: public; Owner: postgres_user
--

COPY public.master_channels (id, created_at, created_by, updated_at, updated_by, deleted_at, deleted_by, channel_group_id, channel_name, channel_code, transaction_type, description, endpoint_url, service_code) FROM stdin;
05cfdb2b-622d-462b-9939-e3b0a4e6cd88	2026-04-23 08:27:03.65566+00	5f7e8b2f-c678-45eb-990a-5155ffef61f9	2026-04-23 08:27:03.65566+00	5f7e8b2f-c678-45eb-990a-5155ffef61f9	\N	\N	47d31ac9-bfb1-4119-9339-56f6d70fb6cf	Qris	QRIS	CASH_IN	Qris Transaction	/qr/qr-mpm-generate	123
733a3c63-69a6-41a0-bc2a-9a0afced8f84	2026-04-24 03:18:06.944453+00	\N	2026-04-24 03:18:06.944453+00	\N	\N	\N	47d31ac9-bfb1-4119-9339-56f6d70fb6cf	RTOL Inquiry	RTOL	INQUIRY	Real Time Online Account Inquiry	/account-inquiry-external	16
b62bd1ab-fdfb-4e9b-9ae4-acd0a476665f	2026-04-24 03:18:06.944453+00	\N	2026-04-24 03:18:06.944453+00	\N	\N	\N	47d31ac9-bfb1-4119-9339-56f6d70fb6cf	RTOL Transfer	RTOL	CASH_OUT	Real Time Online Transfer	/transfer-interbank/rtol	18
10041899-439b-4b97-a123-6a4793de6bd5	2026-04-24 03:18:06.944453+00	\N	2026-04-24 03:18:06.944453+00	\N	\N	\N	47d31ac9-bfb1-4119-9339-56f6d70fb6cf	BIFAST Inquiry	BIFAST	INQUIRY	BI-FAST Account Inquiry	/account-inquiry-external	16
b16eba77-bd9c-44d1-ad56-65e2a38bc09b	2026-04-24 03:18:06.944453+00	\N	2026-04-24 03:18:06.944453+00	\N	\N	\N	47d31ac9-bfb1-4119-9339-56f6d70fb6cf	BIFAST Transfer	BIFAST	CASH_OUT	BI-FAST Transfer	/transfer-interbank/bifast	18
c32d2c1c-ad6b-40c8-9221-d248c6da26e2	2026-04-24 03:18:06.944453+00	\N	2026-04-24 03:18:06.944453+00	\N	\N	\N	47d31ac9-bfb1-4119-9339-56f6d70fb6cf	BIFAST Status Check	BIFAST	CHECK_STATUS	BI-FAST Transaction Status	/transfer/status	36
6bb11428-f6d1-4c78-a4c9-7f94a5852c4e	2026-04-24 03:18:06.944453+00	\N	2026-04-24 03:18:06.944453+00	\N	\N	\N	47d31ac9-bfb1-4119-9339-56f6d70fb6cf	Intrabank Transfer	INTRABANK	CASH_OUT	Intrabank Transfer	/transfer-intrabank	29
58dbe3b0-5a54-4183-b103-b9c20a1d35df	2026-04-24 03:18:06.944453+00	\N	2026-04-24 03:18:06.944453+00	\N	\N	\N	47d31ac9-bfb1-4119-9339-56f6d70fb6cf	Intrabank Inquiry	INTRABANK	INQUIRY	Intrabank Account Inquiry	/account-inquiry-internal	37
\.


--
-- Data for Name: merchant_api_credentials; Type: TABLE DATA; Schema: public; Owner: postgres_user
--

COPY public.merchant_api_credentials (id, created_at, created_by, updated_at, updated_by, deleted_at, deleted_by, merchant_id, secret_key, public_key, client_key) FROM stdin;
b1db04ea-066d-4634-8625-ea7fb9da2e02	2026-04-23 08:30:48.487585+00	5f7e8b2f-c678-45eb-990a-5155ffef61f9	2026-04-23 09:44:19.943637+00	5f7e8b2f-c678-45eb-990a-5155ffef61f9	\N	\N	7848b9ca-b4b4-426f-bf87-d2d109b4361a	019db9b9-e0e3-7566-b60f-2617b534e7f1	-----BEGIN PUBLIC KEY-----\nMIIBITANBgkqhkiG9w0BAQEFAAOCAQ4AMIIBCQKCAQBqG/bc72XcHw6AWvlPtcLxpK8fy6QtTRYL1b72Rk/c1WEbkGrOmu7RnmvPWhB5mPli/G08oJxOtkvdJkFaBsC2dlh7qZRNNbG094OYgOgd80bnRfRQp8A/twDo9MTjgpdz6aq83kTXyIln9zMEboSFJ5h/as6O2qYPmnjPV76RiTmPseD3CmvtYJmKLAqoWlk5PD9f3NYxbgAYuqCDmrkAp1aalZhIMlmwBbkyrYFvbv+zCseBXcqCu49p22bJ/Wqhhd2VIkWtx1iA8dO+3rMsycGOb/AdP+EnMvV0nsIpdjDzNLXp+haQSbZAj9Qs0T7Fyw3/Et9VdBcydiY8a1BXAgMBAAE=\n-----END PUBLIC KEY-----	019db976-90de-7659-9339-1ca3e184de80
\.


--
-- Data for Name: merchant_balance_mutations; Type: TABLE DATA; Schema: public; Owner: postgres_user
--

COPY public.merchant_balance_mutations (id, created_at, created_by, updated_at, updated_by, deleted_at, deleted_by, merchant_id, mutation_date, mutation_datetime, mutation_amount, previous_balance, current_balance, transaction_type, reference_id, note, mutation_type) FROM stdin;
\.


--
-- Data for Name: merchant_banks; Type: TABLE DATA; Schema: public; Owner: postgres_user
--

COPY public.merchant_banks (id, created_at, created_by, updated_at, updated_by, deleted_at, deleted_by, merchant_id, bank_info_id, account_name, account_number, is_default) FROM stdin;
4ab1dfa9-fab3-4fec-a94e-a5262850bfa5	2026-04-23 08:30:48.487585+00	\N	2026-04-23 08:30:48.487585+00	\N	\N	\N	7848b9ca-b4b4-426f-bf87-d2d109b4361a	db5404b6-a542-4c56-90b9-d8bf875c3146	Dororo	11122233444	t
\.


--
-- Data for Name: merchant_categories; Type: TABLE DATA; Schema: public; Owner: postgres_user
--

COPY public.merchant_categories (id, created_at, created_by, updated_at, updated_by, deleted_at, deleted_by, merchant_category_name, merchant_category_description, merchant_category_code) FROM stdin;
7262ff8b-8d95-47da-8a0e-d14e25a90ce5	2025-12-02 06:25:48.19506+00	\N	2025-12-02 06:25:48.19506+00	\N	\N	\N	Layanan Pendidikan	Kategori lembaga pendidikan. MDR 0.6%	EDU
\.


--
-- Data for Name: merchant_channels; Type: TABLE DATA; Schema: public; Owner: postgres_user
--

COPY public.merchant_channels (id, created_at, created_by, updated_at, updated_by, deleted_at, deleted_by, merchant_id, master_channel_id, transaction_type, merchant_callback_url, retry_callback_count, retry_callback_interval, callback_client_key, callback_secret_key, callback_partner_id, callback_private_key, callback_public_key) FROM stdin;
e2899f6f-4175-4e5f-9466-f308d46f1fee	2026-04-23 08:34:06.504246+00	5f7e8b2f-c678-45eb-990a-5155ffef61f9	2026-04-23 08:42:41.625227+00	5f7e8b2f-c678-45eb-990a-5155ffef61f9	\N	\N	7848b9ca-b4b4-426f-bf87-d2d109b4361a	05cfdb2b-622d-462b-9939-e3b0a4e6cd88	CASH_IN	http://merchant-client:12345/v1.0/qr/qr-mpm-notify	51	51	12341234	123123	019db97690de765993391ca3e184de80	-----BEGIN PRIVATE KEY-----\nMIIEowIBAAKCAQBqG/bc72XcHw6AWvlPtcLxpK8fy6QtTRYL1b72Rk/c1WEbkGrOmu7RnmvPWhB5mPli/G08oJxOtkvdJkFaBsC2dlh7qZRNNbG094OYgOgd80bnRfRQp8A/twDo9MTjgpdz6aq83kTXyIln9zMEboSFJ5h/as6O2qYPmnjPV76RiTmPseD3CmvtYJmKLAqoWlk5PD9f3NYxbgAYuqCDmrkAp1aalZhIMlmwBbkyrYFvbv+zCseBXcqCu49p22bJ/Wqhhd2VIkWtx1iA8dO+3rMsycGOb/AdP+EnMvV0nsIpdjDzNLXp+haQSbZAj9Qs0T7Fyw3/Et9VdBcydiY8a1BXAgMBAAECggEAXXtpj9fxu245DmgXwVv29YELME3uxGJni+GyLbJgZcQvm2MuVfs1b8PMY4+LeDWHcOfHLWSqkMYWLC2p4bCVU6sL5VbPav5lI3P0ogTfepN74gFFb1F7FCccTCBo3a+N0vcIDwEbUahBNjEY50yev9jUh10Hwd9r8c87pCA/qmM9JTCOO/pjQWg/ca8Lti0xN5VAeNQ5iSLOp0rMW3NCOEaimh4PAaB4seZ6ZTHhcazyfl/+eAV+xS2QRAd+E6cSrcE7E8O4DTYqSqkusO4BrLg5DGBepeLKM2h6f3Qk4PPtEIhGv1750FjbBjLOOPrzjdFBCaOWfoWZHKv/eRkR4QKBgQDImJODfr/nJgf8qNZ18tkVzYQ2tz97uraMi5m6yE4dJF8g4lPzWDArhHN2ntK3SqCMRZvpqTFx5nWiD1DCVE63qeCIUBM6xSqnRtXhYRZSOj6S1tdCrT58zIUql4wnNRoEz1vU9MUNsVOlyg2RCjG5Ud0/ky9SBgG6fw2NOsBW6QKBgQCHapFaujghbTDmVMnx3fbHsiuUN568MCDu1C2x6HR6rgiUortSNC0pD4/mZBegsIOyJrzxQ7YXtIZRTX1OFXIWV+eNjqFMJxMmApviE3N35MgT30XXHUOSIxEejD3DPEFdjq/+RFfe0JDnr1DSwa1FzCiM+Wnnsp8+LVxA1uxlPwKBgQDIayEfhVkpEmdyeiJkEDHzRbYukOIdtgxD2grLguwA0+Ez0s272UWvhRNz1fWEakyEOdwwFfqv6WlodNLkhiVr/Y+3wgGke3BFV1HEcCNEHqt8PKkwFjXTrOf0CRxf4/9OBPukhrYHG0AO6hSp8DyEAxYCOgVSd2vssJqSm7umWQKBgHIgJUqigOXjAYBNWzkFiZM5nLK4wYX2xfqiRbSXpXszKzYhg9++64Scgfl4x9T8jrFZJonrOA74bO8ecImbV2BvS04pM9VbZS72qeu52unjnZ/p3xFxr139QdNN/EuLf8dalwajEK9PdaBdR6+n3OFjM5XEKjZEeyLK1eIrgGW/AoGBAJQXYLl9kjVs0w+MzyH/NQD7ylV5gtnecqIARM4yKlS/2t//+xUAe6NxmZzJ08mmLrByPGr04vGtPlHVXWHppJ5Cn5O24/wH2VONiYMVrc6tAx5b600pnViOMaukPU4BMREVKYyWWf4yb6cYYg+wka3lWmw180NxWJiiUyXo7nES\n-----END PRIVATE KEY-----	-----BEGIN PUBLIC KEY-----\nMIIBITANBgkqhkiG9w0BAQEFAAOCAQ4AMIIBCQKCAQBqG/bc72XcHw6AWvlPtcLxpK8fy6QtTRYL1b72Rk/c1WEbkGrOmu7RnmvPWhB5mPli/G08oJxOtkvdJkFaBsC2dlh7qZRNNbG094OYgOgd80bnRfRQp8A/twDo9MTjgpdz6aq83kTXyIln9zMEboSFJ5h/as6O2qYPmnjPV76RiTmPseD3CmvtYJmKLAqoWlk5PD9f3NYxbgAYuqCDmrkAp1aalZhIMlmwBbkyrYFvbv+zCseBXcqCu49p22bJ/Wqhhd2VIkWtx1iA8dO+3rMsycGOb/AdP+EnMvV0nsIpdjDzNLXp+haQSbZAj9Qs0T7Fyw3/Et9VdBcydiY8a1BXAgMBAAE=\n-----END PUBLIC KEY-----
\.


--
-- Data for Name: merchant_disbursement_limit_rules; Type: TABLE DATA; Schema: public; Owner: postgres_user
--

COPY public.merchant_disbursement_limit_rules (id, created_at, created_by, updated_at, updated_by, deleted_at, deleted_by, merchant_id, limit_amount, limit_cycle) FROM stdin;
4bde5c1a-26ea-4402-b42f-ba3d8b1cbde9	2026-04-23 08:34:18.253535+00	5f7e8b2f-c678-45eb-990a-5155ffef61f9	2026-04-23 08:34:18.253535+00	5f7e8b2f-c678-45eb-990a-5155ffef61f9	\N	\N	7848b9ca-b4b4-426f-bf87-d2d109b4361a	10000000.00	DAILY
b934639a-46ed-4f35-81e9-4a32a5b43cdf	2026-04-23 08:34:18.253535+00	5f7e8b2f-c678-45eb-990a-5155ffef61f9	2026-04-23 08:34:18.253535+00	5f7e8b2f-c678-45eb-990a-5155ffef61f9	\N	\N	7848b9ca-b4b4-426f-bf87-d2d109b4361a	200000000.00	MONTHLY
\.


--
-- Data for Name: merchant_fees; Type: TABLE DATA; Schema: public; Owner: postgres_user
--

COPY public.merchant_fees (id, created_at, created_by, updated_at, updated_by, deleted_at, deleted_by, merchant_id, merchant_channel_id, fee_type, fee_fixed, fee_percentage, fee_status, begin_active_date, end_active_date) FROM stdin;
f9f74dc8-d928-4106-9d06-aeec965a6019	2026-04-23 08:34:06.504246+00	5f7e8b2f-c678-45eb-990a-5155ffef61f9	2026-04-23 08:34:06.504246+00	5f7e8b2f-c678-45eb-990a-5155ffef61f9	\N	\N	7848b9ca-b4b4-426f-bf87-d2d109b4361a	e2899f6f-4175-4e5f-9466-f308d46f1fee	FIXED	25000.00	0.00	ACTIVE	2026-04-23 08:34:06.504246+00	\N
\.


--
-- Data for Name: merchant_settlement_configurations; Type: TABLE DATA; Schema: public; Owner: postgres_user
--

COPY public.merchant_settlement_configurations (id, created_at, created_by, updated_at, updated_by, deleted_at, deleted_by, merchant_id, settlement_type, settlement_day, settlement_times, status) FROM stdin;
\.


--
-- Data for Name: merchant_settlement_histories; Type: TABLE DATA; Schema: public; Owner: postgres_user
--

COPY public.merchant_settlement_histories (id, created_at, created_by, updated_at, updated_by, deleted_at, deleted_by, merchant_id, settlement_datetime, settlement_type, is_current_settlement, merchant_settlement_config_id) FROM stdin;
\.


--
-- Data for Name: merchants; Type: TABLE DATA; Schema: public; Owner: postgres_user
--

COPY public.merchants (id, created_at, created_by, updated_at, updated_by, deleted_at, deleted_by, merchant_name, email, phone, status, merchant_category_id, owner, merchant_code, settled_balance) FROM stdin;
7848b9ca-b4b4-426f-bf87-d2d109b4361a	2026-04-23 08:30:48.487585+00	\N	2026-04-23 08:30:48.487585+00	\N	\N	\N	Bimbel Dororo	dororo@example.com	+628123123123	ACTIVE	7262ff8b-8d95-47da-8a0e-d14e25a90ce5	Dororo	iPRiYUdyz9Ry	0.00
\.


--
-- Data for Name: provider_api_credentials; Type: TABLE DATA; Schema: public; Owner: postgres_user
--

COPY public.provider_api_credentials (id, created_at, created_by, updated_at, updated_by, deleted_at, deleted_by, provider_id, is_snap, client_key, client_secret, public_key, private_key, additional_info, provider_channel_id, service_code, callback_public_key, callback_client_key, callback_secret_key) FROM stdin;
f9505946-dbf4-42b3-986f-a5dd372277d5	2026-04-23 08:29:05.919224+00	5f7e8b2f-c678-45eb-990a-5155ffef61f9	2026-04-23 08:29:05.919224+00	5f7e8b2f-c678-45eb-990a-5155ffef61f9	\N	\N	04c26b41-1e0b-49a6-aa25-4a2c62a1e11e	t	based	based	based	-----BEGIN RSA PRIVATE KEY-----\nMIIEowIBAAKCAQEA0i9/ISWa0AD8tU6Y6cI8EqOc1zOSwiXNEnJ1rSNbyHGRmRau\nhni/3YdR93YrV6RgCz6cEBWKHxmIEt0+ENCcnGR8+zg5LS37sYKJggpKyO1T43DH\nkOU64IKPjDA1pbM1YMWJ5S1EdlaIZQbXdET5OUCL7Z5h71e4X0o2EO2/PlGMyjvw\nkkx7tDC8F3Ure4vNOHHMW7epYhLd309o5V55CFxULHbMv0lc3hyNXgg6HG7i2pgR\nGUXfJUJtrtnI6K2wJjULd9iDf/A2XydRtm7R3IaHd/7L0NtRHXJWUjWGNukoQBQK\ng1F2bKxepHf1jMNf15EOYSSHIcwJmqTcZpg21wIDAQABAoIBAGwoPMcVzsBSgbfa\nph1D8h21S7QBufdl9E0V0TAzDbvrlPyuC0jvQewBAlDQ4iTLVRD0OuKb8uNmA/uR\nFasZbj2cCCROHj39d5M0lQXxveH/HjffhRIuo0l8ZdnBxRlrSoBtpjPkQ2KRzMYP\n6zbNd2HasSapZcP/48RFL+UuMkciSREzWb4DuEWjRjeNzOJstJqlIgy9aLBWP/Xq\n2ny8DOSuw7tnbdlmzy8k/uVZgiOs2iv+aunICu1/bw4RZfBsiEaEwsvNCpSCR38P\nOClJh2TA9Tz/cO5+RS4rKxQtLJH/ujOGVFypYxZErEsxGSfSqCWnQLyFF8M2VoGi\nYpsL8YECgYEA6CD1g1tvmpVTnAfSwkSPBkr/ZDz/LwdLZHCncumxtywzPQ1lD4Sg\nEKqt5JQ+VB/K15ZJl8HxeujOhMBfbiecBgO5Sz41eq64okqXGJ1FC5CFJfQG2zDn\nur/eGhJ2RSx1jIEu2uHyTR0Tp+cAKyXxKRE3mB+yihkVhfcP8TFaAEcCgYEA58zb\n04AuW/5wNc+JHUW7eJ+UgBfsVDv/fnDpe80L77wRdsB9y60ZRrCu1WfcfDBzHQX+\nr3LRLsiYfpXAIZhU+f/kCqx5qRE/n/kQLvPshmS4GN6hcsA0S7ooGWVdx49p83ks\n2KUQGFcJnlvWMKk6mygBS/XLWRC+VcoToGFAbPECgYEAxWHZQlQKx0h4qvGgDh7b\n+z7kgai4WJX8TrDYQgdjXV1RSHXOXG6q6OEpMne3tDLAeadKdqesnZW+nfUycGlv\n61FZSxjfwq01RJLmfkCkyFugTJB/D/063npt8n+GX/WZEtt6Kxb7wQSbhScQ5p/B\nu+ju/ATf/TutKJfXz4DmhdsCgYBPW7Zi2X6Fpj16Xrv9lpMRP+kSVZ5mVEgrXLLC\n3LdacxOziUFICtIdfn3MuAsnRVsTs6q3HGL7VlfG9rPZjJKDKJVFBjl8pVgYB6f/\nuyjd9fuFICs74wvEZU43K5oIqVPHtFOjNBenjZzQZ3aUIEvdNLwE6nic3HudWVqQ\nzNrGsQKBgCzXjJK0iWeSvkL2MlArDaKOnGCckE9vvxrSRG/U7XOM7ft+CNkSO0gR\nD5nPrVZsLWL5H+oNZ7m/FkfUGmJJv8LydSAJGwcwiy4oEtw8fdoHjG1LHIe+REg2\nYOWdGBlDItRMp9GeZJatiFI8VNivH+Y3Yvo+fdEZWo228NzFsuvA\n-----END RSA PRIVATE KEY-----\n	{"partnerId": "mock-partner-id", "senderJob": "1", "merchantId": "mock-merchant-id-nobu", "senderName": "Mock Sender", "senderAddress": "Jl. Mock No. 1", "senderCountry": "ID", "senderCityCode": "3201", "sourceAccountNo": "1234567890", "senderDateOfBirth": "1990-01-01", "sourceAccountName": "Mock Source Account", "senderIdentityType": "1", "senderPlaceOfBirth": "Jakarta", "senderProvinceCode": "32", "sourceAccountBankId": "503", "sourceAccountBankNo": "503001", "senderIdentityNumber": "1234567890123456"}	80f1867f-ec69-4b35-ac84-b29ef4537134	123	-----BEGIN PUBLIC KEY-----\nMIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAwjREt4ub4AQtzm9o3YhU\n1PF3umUqxuqfTym9KFwftYvUP1G0eXOkAoIi8uaN4PlfYer6bz2NYlA2ZlKGHQwj\n2ya1mBZdMkxAYuLjli2yxEJqEZjXvAX5ttSXgmBi6I8gZziMIGeo1z2pcX+sn5Qx\nHl9PIoMGzdTeUMfPU+NXkqcjEkNbq4ek1qUHRqjz9ATR8ZsCMcXpPHQa7YgMH+1o\ncDMt2YNXf3avLkVL5vftDoDu6sJ0lH0GJ6hudeG/oH1RDfLzH9RvzutK7uCvcng9\njilTAGQEK9P6k4S9vHlcGPwN1q/bLgcbdF/mQhdXrrd9KZB1x3+IzbAXEAKf7kg6\n2QIDAQAB\n-----END PUBLIC KEY-----\n	019db975-003e-73eb-9844-6e40a485e20e	019db975-003e-73ef-841b-99872852a223
a2eed949-2e0d-481f-aa06-60c194c58af7	2026-04-24 03:18:21.864717+00	\N	2026-04-24 03:18:21.864717+00	\N	\N	\N	04c26b41-1e0b-49a6-aa25-4a2c62a1e11e	t	mock-client-key	mock-client-secret	mock-public-key	-----BEGIN RSA PRIVATE KEY-----\nMIIEowIBAAKCAQEA0i9/ISWa0AD8tU6Y6cI8EqOc1zOSwiXNEnJ1rSNbyHGRmRau\nhni/3YdR93YrV6RgCz6cEBWKHxmIEt0+ENCcnGR8+zg5LS37sYKJggpKyO1T43DH\nkOU64IKPjDA1pbM1YMWJ5S1EdlaIZQbXdET5OUCL7Z5h71e4X0o2EO2/PlGMyjvw\nkkx7tDC8F3Ure4vNOHHMW7epYhLd309o5V55CFxULHbMv0lc3hyNXgg6HG7i2pgR\nGUXfJUJtrtnI6K2wJjULd9iDf/A2XydRtm7R3IaHd/7L0NtRHXJWUjWGNukoQBQK\ng1F2bKxepHf1jMNf15EOYSSHIcwJmqTcZpg21wIDAQABAoIBAGwoPMcVzsBSgbfa\nph1D8h21S7QBufdl9E0V0TAzDbvrlPyuC0jvQewBAlDQ4iTLVRD0OuKb8uNmA/uR\nFasZbj2cCCROHj39d5M0lQXxveH/HjffhRIuo0l8ZdnBxRlrSoBtpjPkQ2KRzMYP\n6zbNd2HasSapZcP/48RFL+UuMkciSREzWb4DuEWjRjeNzOJstJqlIgy9aLBWP/Xq\n2ny8DOSuw7tnbdlmzy8k/uVZgiOs2iv+aunICu1/bw4RZfBsiEaEwsvNCpSCR38P\nOClJh2TA9Tz/cO5+RS4rKxQtLJH/ujOGVFypYxZErEsxGSfSqCWnQLyFF8M2VoGi\nYpsL8YECgYEA6CD1g1tvmpVTnAfSwkSPBkr/ZDz/LwdLZHCncumxtywzPQ1lD4Sg\nEKqt5JQ+VB/K15ZJl8HxeujOhMBfbiecBgO5Sz41eq64okqXGJ1FC5CFJfQG2zDn\nur/eGhJ2RSx1jIEu2uHyTR0Tp+cAKyXxKRE3mB+yihkVhfcP8TFaAEcCgYEA58zb\n04AuW/5wNc+JHUW7eJ+UgBfsVDv/fnDpe80L77wRdsB9y60ZRrCu1WfcfDBzHQX+\nr3LRLsiYfpXAIZhU+f/kCqx5qRE/n/kQLvPshmS4GN6hcsA0S7ooGWVdx49p83ks\n2KUQGFcJnlvWMKk6mygBS/XLWRC+VcoToGFAbPECgYEAxWHZQlQKx0h4qvGgDh7b\n+z7kgai4WJX8TrDYQgdjXV1RSHXOXG6q6OEpMne3tDLAeadKdqesnZW+nfUycGlv\n61FZSxjfwq01RJLmfkCkyFugTJB/D/063npt8n+GX/WZEtt6Kxb7wQSbhScQ5p/B\nu+ju/ATf/TutKJfXz4DmhdsCgYBPW7Zi2X6Fpj16Xrv9lpMRP+kSVZ5mVEgrXLLC\n3LdacxOziUFICtIdfn3MuAsnRVsTs6q3HGL7VlfG9rPZjJKDKJVFBjl8pVgYB6f/\nuyjd9fuFICs74wvEZU43K5oIqVPHtFOjNBenjZzQZ3aUIEvdNLwE6nic3HudWVqQ\nzNrGsQKBgCzXjJK0iWeSvkL2MlArDaKOnGCckE9vvxrSRG/U7XOM7ft+CNkSO0gR\nD5nPrVZsLWL5H+oNZ7m/FkfUGmJJv8LydSAJGwcwiy4oEtw8fdoHjG1LHIe+REg2\nYOWdGBlDItRMp9GeZJatiFI8VNivH+Y3Yvo+fdEZWo228NzFsuvA\n-----END RSA PRIVATE KEY-----\n	{"partnerId": "mock-partner-id", "senderJob": "1", "merchantId": "mock-merchant-id-nobu", "senderName": "Mock Sender", "senderAddress": "Jl. Mock No. 1", "senderCountry": "ID", "senderCityCode": "3201", "sourceAccountNo": "1234567890", "senderDateOfBirth": "1990-01-01", "sourceAccountName": "Mock Source Account", "senderIdentityType": "1", "senderPlaceOfBirth": "Jakarta", "senderProvinceCode": "32", "sourceAccountBankId": "503", "sourceAccountBankNo": "503001", "senderIdentityNumber": "1234567890123456"}	7e14d6b1-67dd-42c3-b01d-1f1395953575	73	\N	7a07cbc6-664f-401e-941d-084717a04d67	854a4681-c06d-4789-bca5-37791b97a8c2
551a2842-da2d-474c-bbc5-2abaca3f70d5	2026-04-24 03:18:21.864717+00	\N	2026-04-24 03:18:21.864717+00	\N	\N	\N	04c26b41-1e0b-49a6-aa25-4a2c62a1e11e	t	mock-client-key	mock-client-secret	mock-public-key	-----BEGIN RSA PRIVATE KEY-----\nMIIEowIBAAKCAQEA0i9/ISWa0AD8tU6Y6cI8EqOc1zOSwiXNEnJ1rSNbyHGRmRau\nhni/3YdR93YrV6RgCz6cEBWKHxmIEt0+ENCcnGR8+zg5LS37sYKJggpKyO1T43DH\nkOU64IKPjDA1pbM1YMWJ5S1EdlaIZQbXdET5OUCL7Z5h71e4X0o2EO2/PlGMyjvw\nkkx7tDC8F3Ure4vNOHHMW7epYhLd309o5V55CFxULHbMv0lc3hyNXgg6HG7i2pgR\nGUXfJUJtrtnI6K2wJjULd9iDf/A2XydRtm7R3IaHd/7L0NtRHXJWUjWGNukoQBQK\ng1F2bKxepHf1jMNf15EOYSSHIcwJmqTcZpg21wIDAQABAoIBAGwoPMcVzsBSgbfa\nph1D8h21S7QBufdl9E0V0TAzDbvrlPyuC0jvQewBAlDQ4iTLVRD0OuKb8uNmA/uR\nFasZbj2cCCROHj39d5M0lQXxveH/HjffhRIuo0l8ZdnBxRlrSoBtpjPkQ2KRzMYP\n6zbNd2HasSapZcP/48RFL+UuMkciSREzWb4DuEWjRjeNzOJstJqlIgy9aLBWP/Xq\n2ny8DOSuw7tnbdlmzy8k/uVZgiOs2iv+aunICu1/bw4RZfBsiEaEwsvNCpSCR38P\nOClJh2TA9Tz/cO5+RS4rKxQtLJH/ujOGVFypYxZErEsxGSfSqCWnQLyFF8M2VoGi\nYpsL8YECgYEA6CD1g1tvmpVTnAfSwkSPBkr/ZDz/LwdLZHCncumxtywzPQ1lD4Sg\nEKqt5JQ+VB/K15ZJl8HxeujOhMBfbiecBgO5Sz41eq64okqXGJ1FC5CFJfQG2zDn\nur/eGhJ2RSx1jIEu2uHyTR0Tp+cAKyXxKRE3mB+yihkVhfcP8TFaAEcCgYEA58zb\n04AuW/5wNc+JHUW7eJ+UgBfsVDv/fnDpe80L77wRdsB9y60ZRrCu1WfcfDBzHQX+\nr3LRLsiYfpXAIZhU+f/kCqx5qRE/n/kQLvPshmS4GN6hcsA0S7ooGWVdx49p83ks\n2KUQGFcJnlvWMKk6mygBS/XLWRC+VcoToGFAbPECgYEAxWHZQlQKx0h4qvGgDh7b\n+z7kgai4WJX8TrDYQgdjXV1RSHXOXG6q6OEpMne3tDLAeadKdqesnZW+nfUycGlv\n61FZSxjfwq01RJLmfkCkyFugTJB/D/063npt8n+GX/WZEtt6Kxb7wQSbhScQ5p/B\nu+ju/ATf/TutKJfXz4DmhdsCgYBPW7Zi2X6Fpj16Xrv9lpMRP+kSVZ5mVEgrXLLC\n3LdacxOziUFICtIdfn3MuAsnRVsTs6q3HGL7VlfG9rPZjJKDKJVFBjl8pVgYB6f/\nuyjd9fuFICs74wvEZU43K5oIqVPHtFOjNBenjZzQZ3aUIEvdNLwE6nic3HudWVqQ\nzNrGsQKBgCzXjJK0iWeSvkL2MlArDaKOnGCckE9vvxrSRG/U7XOM7ft+CNkSO0gR\nD5nPrVZsLWL5H+oNZ7m/FkfUGmJJv8LydSAJGwcwiy4oEtw8fdoHjG1LHIe+REg2\nYOWdGBlDItRMp9GeZJatiFI8VNivH+Y3Yvo+fdEZWo228NzFsuvA\n-----END RSA PRIVATE KEY-----\n	{"partnerId": "mock-partner-id", "senderJob": "1", "merchantId": "mock-merchant-id-nobu", "senderName": "Mock Sender", "senderAddress": "Jl. Mock No. 1", "senderCountry": "ID", "senderCityCode": "3201", "sourceAccountNo": "1234567890", "senderDateOfBirth": "1990-01-01", "sourceAccountName": "Mock Source Account", "senderIdentityType": "1", "senderPlaceOfBirth": "Jakarta", "senderProvinceCode": "32", "sourceAccountBankId": "503", "sourceAccountBankNo": "503001", "senderIdentityNumber": "1234567890123456"}	34d60118-3be0-4cb7-bf3a-e5dafe1fd156	73	\N	6c502ae7-372b-442a-9576-49ad1ba28410	f95fa91d-ecba-4c7a-8607-dd61a6169f6c
632c310d-ba97-4d8a-b254-5673dc3ef1c0	2026-04-24 03:18:21.864717+00	\N	2026-04-24 03:18:21.864717+00	\N	\N	\N	04c26b41-1e0b-49a6-aa25-4a2c62a1e11e	t	mock-client-key	mock-client-secret	mock-public-key	-----BEGIN RSA PRIVATE KEY-----\nMIIEowIBAAKCAQEA0i9/ISWa0AD8tU6Y6cI8EqOc1zOSwiXNEnJ1rSNbyHGRmRau\nhni/3YdR93YrV6RgCz6cEBWKHxmIEt0+ENCcnGR8+zg5LS37sYKJggpKyO1T43DH\nkOU64IKPjDA1pbM1YMWJ5S1EdlaIZQbXdET5OUCL7Z5h71e4X0o2EO2/PlGMyjvw\nkkx7tDC8F3Ure4vNOHHMW7epYhLd309o5V55CFxULHbMv0lc3hyNXgg6HG7i2pgR\nGUXfJUJtrtnI6K2wJjULd9iDf/A2XydRtm7R3IaHd/7L0NtRHXJWUjWGNukoQBQK\ng1F2bKxepHf1jMNf15EOYSSHIcwJmqTcZpg21wIDAQABAoIBAGwoPMcVzsBSgbfa\nph1D8h21S7QBufdl9E0V0TAzDbvrlPyuC0jvQewBAlDQ4iTLVRD0OuKb8uNmA/uR\nFasZbj2cCCROHj39d5M0lQXxveH/HjffhRIuo0l8ZdnBxRlrSoBtpjPkQ2KRzMYP\n6zbNd2HasSapZcP/48RFL+UuMkciSREzWb4DuEWjRjeNzOJstJqlIgy9aLBWP/Xq\n2ny8DOSuw7tnbdlmzy8k/uVZgiOs2iv+aunICu1/bw4RZfBsiEaEwsvNCpSCR38P\nOClJh2TA9Tz/cO5+RS4rKxQtLJH/ujOGVFypYxZErEsxGSfSqCWnQLyFF8M2VoGi\nYpsL8YECgYEA6CD1g1tvmpVTnAfSwkSPBkr/ZDz/LwdLZHCncumxtywzPQ1lD4Sg\nEKqt5JQ+VB/K15ZJl8HxeujOhMBfbiecBgO5Sz41eq64okqXGJ1FC5CFJfQG2zDn\nur/eGhJ2RSx1jIEu2uHyTR0Tp+cAKyXxKRE3mB+yihkVhfcP8TFaAEcCgYEA58zb\n04AuW/5wNc+JHUW7eJ+UgBfsVDv/fnDpe80L77wRdsB9y60ZRrCu1WfcfDBzHQX+\nr3LRLsiYfpXAIZhU+f/kCqx5qRE/n/kQLvPshmS4GN6hcsA0S7ooGWVdx49p83ks\n2KUQGFcJnlvWMKk6mygBS/XLWRC+VcoToGFAbPECgYEAxWHZQlQKx0h4qvGgDh7b\n+z7kgai4WJX8TrDYQgdjXV1RSHXOXG6q6OEpMne3tDLAeadKdqesnZW+nfUycGlv\n61FZSxjfwq01RJLmfkCkyFugTJB/D/063npt8n+GX/WZEtt6Kxb7wQSbhScQ5p/B\nu+ju/ATf/TutKJfXz4DmhdsCgYBPW7Zi2X6Fpj16Xrv9lpMRP+kSVZ5mVEgrXLLC\n3LdacxOziUFICtIdfn3MuAsnRVsTs6q3HGL7VlfG9rPZjJKDKJVFBjl8pVgYB6f/\nuyjd9fuFICs74wvEZU43K5oIqVPHtFOjNBenjZzQZ3aUIEvdNLwE6nic3HudWVqQ\nzNrGsQKBgCzXjJK0iWeSvkL2MlArDaKOnGCckE9vvxrSRG/U7XOM7ft+CNkSO0gR\nD5nPrVZsLWL5H+oNZ7m/FkfUGmJJv8LydSAJGwcwiy4oEtw8fdoHjG1LHIe+REg2\nYOWdGBlDItRMp9GeZJatiFI8VNivH+Y3Yvo+fdEZWo228NzFsuvA\n-----END RSA PRIVATE KEY-----\n	{"partnerId": "mock-partner-id", "senderJob": "1", "merchantId": "mock-merchant-id-nobu", "senderName": "Mock Sender", "senderAddress": "Jl. Mock No. 1", "senderCountry": "ID", "senderCityCode": "3201", "sourceAccountNo": "1234567890", "senderDateOfBirth": "1990-01-01", "sourceAccountName": "Mock Source Account", "senderIdentityType": "1", "senderPlaceOfBirth": "Jakarta", "senderProvinceCode": "32", "sourceAccountBankId": "503", "sourceAccountBankNo": "503001", "senderIdentityNumber": "1234567890123456"}	a4bf5cd1-23a5-4941-a5d1-8130d0d4f0ba	73	\N	a51c9f25-bf48-4e21-b7da-cd5e1ce26ee5	21b6f0d8-7cc5-4caf-8f43-725e9d44937f
a4186828-7c63-49f7-9041-b15934f2f778	2026-04-24 03:18:21.864717+00	\N	2026-04-24 03:18:21.864717+00	\N	\N	\N	04c26b41-1e0b-49a6-aa25-4a2c62a1e11e	t	mock-client-key	mock-client-secret	mock-public-key	-----BEGIN RSA PRIVATE KEY-----\nMIIEowIBAAKCAQEA0i9/ISWa0AD8tU6Y6cI8EqOc1zOSwiXNEnJ1rSNbyHGRmRau\nhni/3YdR93YrV6RgCz6cEBWKHxmIEt0+ENCcnGR8+zg5LS37sYKJggpKyO1T43DH\nkOU64IKPjDA1pbM1YMWJ5S1EdlaIZQbXdET5OUCL7Z5h71e4X0o2EO2/PlGMyjvw\nkkx7tDC8F3Ure4vNOHHMW7epYhLd309o5V55CFxULHbMv0lc3hyNXgg6HG7i2pgR\nGUXfJUJtrtnI6K2wJjULd9iDf/A2XydRtm7R3IaHd/7L0NtRHXJWUjWGNukoQBQK\ng1F2bKxepHf1jMNf15EOYSSHIcwJmqTcZpg21wIDAQABAoIBAGwoPMcVzsBSgbfa\nph1D8h21S7QBufdl9E0V0TAzDbvrlPyuC0jvQewBAlDQ4iTLVRD0OuKb8uNmA/uR\nFasZbj2cCCROHj39d5M0lQXxveH/HjffhRIuo0l8ZdnBxRlrSoBtpjPkQ2KRzMYP\n6zbNd2HasSapZcP/48RFL+UuMkciSREzWb4DuEWjRjeNzOJstJqlIgy9aLBWP/Xq\n2ny8DOSuw7tnbdlmzy8k/uVZgiOs2iv+aunICu1/bw4RZfBsiEaEwsvNCpSCR38P\nOClJh2TA9Tz/cO5+RS4rKxQtLJH/ujOGVFypYxZErEsxGSfSqCWnQLyFF8M2VoGi\nYpsL8YECgYEA6CD1g1tvmpVTnAfSwkSPBkr/ZDz/LwdLZHCncumxtywzPQ1lD4Sg\nEKqt5JQ+VB/K15ZJl8HxeujOhMBfbiecBgO5Sz41eq64okqXGJ1FC5CFJfQG2zDn\nur/eGhJ2RSx1jIEu2uHyTR0Tp+cAKyXxKRE3mB+yihkVhfcP8TFaAEcCgYEA58zb\n04AuW/5wNc+JHUW7eJ+UgBfsVDv/fnDpe80L77wRdsB9y60ZRrCu1WfcfDBzHQX+\nr3LRLsiYfpXAIZhU+f/kCqx5qRE/n/kQLvPshmS4GN6hcsA0S7ooGWVdx49p83ks\n2KUQGFcJnlvWMKk6mygBS/XLWRC+VcoToGFAbPECgYEAxWHZQlQKx0h4qvGgDh7b\n+z7kgai4WJX8TrDYQgdjXV1RSHXOXG6q6OEpMne3tDLAeadKdqesnZW+nfUycGlv\n61FZSxjfwq01RJLmfkCkyFugTJB/D/063npt8n+GX/WZEtt6Kxb7wQSbhScQ5p/B\nu+ju/ATf/TutKJfXz4DmhdsCgYBPW7Zi2X6Fpj16Xrv9lpMRP+kSVZ5mVEgrXLLC\n3LdacxOziUFICtIdfn3MuAsnRVsTs6q3HGL7VlfG9rPZjJKDKJVFBjl8pVgYB6f/\nuyjd9fuFICs74wvEZU43K5oIqVPHtFOjNBenjZzQZ3aUIEvdNLwE6nic3HudWVqQ\nzNrGsQKBgCzXjJK0iWeSvkL2MlArDaKOnGCckE9vvxrSRG/U7XOM7ft+CNkSO0gR\nD5nPrVZsLWL5H+oNZ7m/FkfUGmJJv8LydSAJGwcwiy4oEtw8fdoHjG1LHIe+REg2\nYOWdGBlDItRMp9GeZJatiFI8VNivH+Y3Yvo+fdEZWo228NzFsuvA\n-----END RSA PRIVATE KEY-----\n	{"partnerId": "mock-partner-id", "senderJob": "1", "merchantId": "mock-merchant-id-nobu", "senderName": "Mock Sender", "senderAddress": "Jl. Mock No. 1", "senderCountry": "ID", "senderCityCode": "3201", "sourceAccountNo": "1234567890", "senderDateOfBirth": "1990-01-01", "sourceAccountName": "Mock Source Account", "senderIdentityType": "1", "senderPlaceOfBirth": "Jakarta", "senderProvinceCode": "32", "sourceAccountBankId": "503", "sourceAccountBankNo": "503001", "senderIdentityNumber": "1234567890123456"}	cc018e73-18c7-4f7c-8f52-0149149a59c9	73	\N	1c179412-86ea-415a-827a-82e062f04157	14dbf846-e4a0-4be3-8921-2b26e341be3b
b78f9e63-6348-4f5c-8a7d-daf86a7d2a16	2026-04-24 03:18:21.864717+00	\N	2026-04-24 03:18:21.864717+00	\N	\N	\N	04c26b41-1e0b-49a6-aa25-4a2c62a1e11e	t	mock-client-key	mock-client-secret	mock-public-key	-----BEGIN RSA PRIVATE KEY-----\nMIIEowIBAAKCAQEA0i9/ISWa0AD8tU6Y6cI8EqOc1zOSwiXNEnJ1rSNbyHGRmRau\nhni/3YdR93YrV6RgCz6cEBWKHxmIEt0+ENCcnGR8+zg5LS37sYKJggpKyO1T43DH\nkOU64IKPjDA1pbM1YMWJ5S1EdlaIZQbXdET5OUCL7Z5h71e4X0o2EO2/PlGMyjvw\nkkx7tDC8F3Ure4vNOHHMW7epYhLd309o5V55CFxULHbMv0lc3hyNXgg6HG7i2pgR\nGUXfJUJtrtnI6K2wJjULd9iDf/A2XydRtm7R3IaHd/7L0NtRHXJWUjWGNukoQBQK\ng1F2bKxepHf1jMNf15EOYSSHIcwJmqTcZpg21wIDAQABAoIBAGwoPMcVzsBSgbfa\nph1D8h21S7QBufdl9E0V0TAzDbvrlPyuC0jvQewBAlDQ4iTLVRD0OuKb8uNmA/uR\nFasZbj2cCCROHj39d5M0lQXxveH/HjffhRIuo0l8ZdnBxRlrSoBtpjPkQ2KRzMYP\n6zbNd2HasSapZcP/48RFL+UuMkciSREzWb4DuEWjRjeNzOJstJqlIgy9aLBWP/Xq\n2ny8DOSuw7tnbdlmzy8k/uVZgiOs2iv+aunICu1/bw4RZfBsiEaEwsvNCpSCR38P\nOClJh2TA9Tz/cO5+RS4rKxQtLJH/ujOGVFypYxZErEsxGSfSqCWnQLyFF8M2VoGi\nYpsL8YECgYEA6CD1g1tvmpVTnAfSwkSPBkr/ZDz/LwdLZHCncumxtywzPQ1lD4Sg\nEKqt5JQ+VB/K15ZJl8HxeujOhMBfbiecBgO5Sz41eq64okqXGJ1FC5CFJfQG2zDn\nur/eGhJ2RSx1jIEu2uHyTR0Tp+cAKyXxKRE3mB+yihkVhfcP8TFaAEcCgYEA58zb\n04AuW/5wNc+JHUW7eJ+UgBfsVDv/fnDpe80L77wRdsB9y60ZRrCu1WfcfDBzHQX+\nr3LRLsiYfpXAIZhU+f/kCqx5qRE/n/kQLvPshmS4GN6hcsA0S7ooGWVdx49p83ks\n2KUQGFcJnlvWMKk6mygBS/XLWRC+VcoToGFAbPECgYEAxWHZQlQKx0h4qvGgDh7b\n+z7kgai4WJX8TrDYQgdjXV1RSHXOXG6q6OEpMne3tDLAeadKdqesnZW+nfUycGlv\n61FZSxjfwq01RJLmfkCkyFugTJB/D/063npt8n+GX/WZEtt6Kxb7wQSbhScQ5p/B\nu+ju/ATf/TutKJfXz4DmhdsCgYBPW7Zi2X6Fpj16Xrv9lpMRP+kSVZ5mVEgrXLLC\n3LdacxOziUFICtIdfn3MuAsnRVsTs6q3HGL7VlfG9rPZjJKDKJVFBjl8pVgYB6f/\nuyjd9fuFICs74wvEZU43K5oIqVPHtFOjNBenjZzQZ3aUIEvdNLwE6nic3HudWVqQ\nzNrGsQKBgCzXjJK0iWeSvkL2MlArDaKOnGCckE9vvxrSRG/U7XOM7ft+CNkSO0gR\nD5nPrVZsLWL5H+oNZ7m/FkfUGmJJv8LydSAJGwcwiy4oEtw8fdoHjG1LHIe+REg2\nYOWdGBlDItRMp9GeZJatiFI8VNivH+Y3Yvo+fdEZWo228NzFsuvA\n-----END RSA PRIVATE KEY-----\n	{"partnerId": "mock-partner-id", "senderJob": "1", "merchantId": "mock-merchant-id-nobu", "senderName": "Mock Sender", "senderAddress": "Jl. Mock No. 1", "senderCountry": "ID", "senderCityCode": "3201", "sourceAccountNo": "1234567890", "senderDateOfBirth": "1990-01-01", "sourceAccountName": "Mock Source Account", "senderIdentityType": "1", "senderPlaceOfBirth": "Jakarta", "senderProvinceCode": "32", "sourceAccountBankId": "503", "sourceAccountBankNo": "503001", "senderIdentityNumber": "1234567890123456"}	3f7ab460-765c-4d11-b2cb-aa2c2e151297	73	\N	115374c7-f03e-4222-b985-10373e1f8852	f16bba18-97dd-432a-b221-fb09646efaff
bd7f2ab8-9883-4f77-88f1-64f57d587c6b	2026-04-24 03:18:21.864717+00	\N	2026-04-24 03:18:21.864717+00	\N	\N	\N	04c26b41-1e0b-49a6-aa25-4a2c62a1e11e	t	mock-client-key	mock-client-secret	mock-public-key	-----BEGIN RSA PRIVATE KEY-----\nMIIEowIBAAKCAQEA0i9/ISWa0AD8tU6Y6cI8EqOc1zOSwiXNEnJ1rSNbyHGRmRau\nhni/3YdR93YrV6RgCz6cEBWKHxmIEt0+ENCcnGR8+zg5LS37sYKJggpKyO1T43DH\nkOU64IKPjDA1pbM1YMWJ5S1EdlaIZQbXdET5OUCL7Z5h71e4X0o2EO2/PlGMyjvw\nkkx7tDC8F3Ure4vNOHHMW7epYhLd309o5V55CFxULHbMv0lc3hyNXgg6HG7i2pgR\nGUXfJUJtrtnI6K2wJjULd9iDf/A2XydRtm7R3IaHd/7L0NtRHXJWUjWGNukoQBQK\ng1F2bKxepHf1jMNf15EOYSSHIcwJmqTcZpg21wIDAQABAoIBAGwoPMcVzsBSgbfa\nph1D8h21S7QBufdl9E0V0TAzDbvrlPyuC0jvQewBAlDQ4iTLVRD0OuKb8uNmA/uR\nFasZbj2cCCROHj39d5M0lQXxveH/HjffhRIuo0l8ZdnBxRlrSoBtpjPkQ2KRzMYP\n6zbNd2HasSapZcP/48RFL+UuMkciSREzWb4DuEWjRjeNzOJstJqlIgy9aLBWP/Xq\n2ny8DOSuw7tnbdlmzy8k/uVZgiOs2iv+aunICu1/bw4RZfBsiEaEwsvNCpSCR38P\nOClJh2TA9Tz/cO5+RS4rKxQtLJH/ujOGVFypYxZErEsxGSfSqCWnQLyFF8M2VoGi\nYpsL8YECgYEA6CD1g1tvmpVTnAfSwkSPBkr/ZDz/LwdLZHCncumxtywzPQ1lD4Sg\nEKqt5JQ+VB/K15ZJl8HxeujOhMBfbiecBgO5Sz41eq64okqXGJ1FC5CFJfQG2zDn\nur/eGhJ2RSx1jIEu2uHyTR0Tp+cAKyXxKRE3mB+yihkVhfcP8TFaAEcCgYEA58zb\n04AuW/5wNc+JHUW7eJ+UgBfsVDv/fnDpe80L77wRdsB9y60ZRrCu1WfcfDBzHQX+\nr3LRLsiYfpXAIZhU+f/kCqx5qRE/n/kQLvPshmS4GN6hcsA0S7ooGWVdx49p83ks\n2KUQGFcJnlvWMKk6mygBS/XLWRC+VcoToGFAbPECgYEAxWHZQlQKx0h4qvGgDh7b\n+z7kgai4WJX8TrDYQgdjXV1RSHXOXG6q6OEpMne3tDLAeadKdqesnZW+nfUycGlv\n61FZSxjfwq01RJLmfkCkyFugTJB/D/063npt8n+GX/WZEtt6Kxb7wQSbhScQ5p/B\nu+ju/ATf/TutKJfXz4DmhdsCgYBPW7Zi2X6Fpj16Xrv9lpMRP+kSVZ5mVEgrXLLC\n3LdacxOziUFICtIdfn3MuAsnRVsTs6q3HGL7VlfG9rPZjJKDKJVFBjl8pVgYB6f/\nuyjd9fuFICs74wvEZU43K5oIqVPHtFOjNBenjZzQZ3aUIEvdNLwE6nic3HudWVqQ\nzNrGsQKBgCzXjJK0iWeSvkL2MlArDaKOnGCckE9vvxrSRG/U7XOM7ft+CNkSO0gR\nD5nPrVZsLWL5H+oNZ7m/FkfUGmJJv8LydSAJGwcwiy4oEtw8fdoHjG1LHIe+REg2\nYOWdGBlDItRMp9GeZJatiFI8VNivH+Y3Yvo+fdEZWo228NzFsuvA\n-----END RSA PRIVATE KEY-----\n	{"partnerId": "mock-partner-id", "senderJob": "1", "merchantId": "mock-merchant-id-nobu", "senderName": "Mock Sender", "senderAddress": "Jl. Mock No. 1", "senderCountry": "ID", "senderCityCode": "3201", "sourceAccountNo": "1234567890", "senderDateOfBirth": "1990-01-01", "sourceAccountName": "Mock Source Account", "senderIdentityType": "1", "senderPlaceOfBirth": "Jakarta", "senderProvinceCode": "32", "sourceAccountBankId": "503", "sourceAccountBankNo": "503001", "senderIdentityNumber": "1234567890123456"}	783eb297-f42e-44aa-9f08-488922dcb108	73	\N	a35ba5b0-3c4a-4f4f-b6d3-9d8c93e559ff	ac0efbe5-c736-42e9-84ae-cd4b83a59dfb
26fdfbcb-32e7-46d6-80fd-bfd6d51cf8b3	2026-04-24 03:18:21.864717+00	\N	2026-04-24 03:18:21.864717+00	\N	\N	\N	04c26b41-1e0b-49a6-aa25-4a2c62a1e11e	t	mock-client-key	mock-client-secret	mock-public-key	-----BEGIN RSA PRIVATE KEY-----\nMIIEowIBAAKCAQEA0i9/ISWa0AD8tU6Y6cI8EqOc1zOSwiXNEnJ1rSNbyHGRmRau\nhni/3YdR93YrV6RgCz6cEBWKHxmIEt0+ENCcnGR8+zg5LS37sYKJggpKyO1T43DH\nkOU64IKPjDA1pbM1YMWJ5S1EdlaIZQbXdET5OUCL7Z5h71e4X0o2EO2/PlGMyjvw\nkkx7tDC8F3Ure4vNOHHMW7epYhLd309o5V55CFxULHbMv0lc3hyNXgg6HG7i2pgR\nGUXfJUJtrtnI6K2wJjULd9iDf/A2XydRtm7R3IaHd/7L0NtRHXJWUjWGNukoQBQK\ng1F2bKxepHf1jMNf15EOYSSHIcwJmqTcZpg21wIDAQABAoIBAGwoPMcVzsBSgbfa\nph1D8h21S7QBufdl9E0V0TAzDbvrlPyuC0jvQewBAlDQ4iTLVRD0OuKb8uNmA/uR\nFasZbj2cCCROHj39d5M0lQXxveH/HjffhRIuo0l8ZdnBxRlrSoBtpjPkQ2KRzMYP\n6zbNd2HasSapZcP/48RFL+UuMkciSREzWb4DuEWjRjeNzOJstJqlIgy9aLBWP/Xq\n2ny8DOSuw7tnbdlmzy8k/uVZgiOs2iv+aunICu1/bw4RZfBsiEaEwsvNCpSCR38P\nOClJh2TA9Tz/cO5+RS4rKxQtLJH/ujOGVFypYxZErEsxGSfSqCWnQLyFF8M2VoGi\nYpsL8YECgYEA6CD1g1tvmpVTnAfSwkSPBkr/ZDz/LwdLZHCncumxtywzPQ1lD4Sg\nEKqt5JQ+VB/K15ZJl8HxeujOhMBfbiecBgO5Sz41eq64okqXGJ1FC5CFJfQG2zDn\nur/eGhJ2RSx1jIEu2uHyTR0Tp+cAKyXxKRE3mB+yihkVhfcP8TFaAEcCgYEA58zb\n04AuW/5wNc+JHUW7eJ+UgBfsVDv/fnDpe80L77wRdsB9y60ZRrCu1WfcfDBzHQX+\nr3LRLsiYfpXAIZhU+f/kCqx5qRE/n/kQLvPshmS4GN6hcsA0S7ooGWVdx49p83ks\n2KUQGFcJnlvWMKk6mygBS/XLWRC+VcoToGFAbPECgYEAxWHZQlQKx0h4qvGgDh7b\n+z7kgai4WJX8TrDYQgdjXV1RSHXOXG6q6OEpMne3tDLAeadKdqesnZW+nfUycGlv\n61FZSxjfwq01RJLmfkCkyFugTJB/D/063npt8n+GX/WZEtt6Kxb7wQSbhScQ5p/B\nu+ju/ATf/TutKJfXz4DmhdsCgYBPW7Zi2X6Fpj16Xrv9lpMRP+kSVZ5mVEgrXLLC\n3LdacxOziUFICtIdfn3MuAsnRVsTs6q3HGL7VlfG9rPZjJKDKJVFBjl8pVgYB6f/\nuyjd9fuFICs74wvEZU43K5oIqVPHtFOjNBenjZzQZ3aUIEvdNLwE6nic3HudWVqQ\nzNrGsQKBgCzXjJK0iWeSvkL2MlArDaKOnGCckE9vvxrSRG/U7XOM7ft+CNkSO0gR\nD5nPrVZsLWL5H+oNZ7m/FkfUGmJJv8LydSAJGwcwiy4oEtw8fdoHjG1LHIe+REg2\nYOWdGBlDItRMp9GeZJatiFI8VNivH+Y3Yvo+fdEZWo228NzFsuvA\n-----END RSA PRIVATE KEY-----\n	{"partnerId": "mock-partner-id", "senderJob": "1", "merchantId": "mock-merchant-id-nobu", "senderName": "Mock Sender", "senderAddress": "Jl. Mock No. 1", "senderCountry": "ID", "senderCityCode": "3201", "sourceAccountNo": "1234567890", "senderDateOfBirth": "1990-01-01", "sourceAccountName": "Mock Source Account", "senderIdentityType": "1", "senderPlaceOfBirth": "Jakarta", "senderProvinceCode": "32", "sourceAccountBankId": "503", "sourceAccountBankNo": "503001", "senderIdentityNumber": "1234567890123456"}	d9958658-7d0a-48c8-9572-324d2d0d6e0e	73	\N	7eaea934-78f4-47dd-ac35-e256ee62f999	c1de4b16-5000-4962-b913-035289804c6b
\.


--
-- Data for Name: provider_channels; Type: TABLE DATA; Schema: public; Owner: postgres_user
--

COPY public.provider_channels (id, created_at, created_by, updated_at, updated_by, deleted_at, deleted_by, provider_id, transaction_type, master_channel_id, status, adapter_status, endpoint_url, provider_reference_length) FROM stdin;
80f1867f-ec69-4b35-ac84-b29ef4537134	2026-04-23 08:29:05.919224+00	5f7e8b2f-c678-45eb-990a-5155ffef61f9	2026-04-23 08:29:05.919224+00	5f7e8b2f-c678-45eb-990a-5155ffef61f9	\N	\N	04c26b41-1e0b-49a6-aa25-4a2c62a1e11e	CASH_IN	05cfdb2b-622d-462b-9939-e3b0a4e6cd88	ACTIVE	ACTIVE	http://localhost:4000	12
7e14d6b1-67dd-42c3-b01d-1f1395953575	2026-04-24 03:18:21.864717+00	\N	2026-04-24 03:18:21.864717+00	\N	\N	\N	04c26b41-1e0b-49a6-aa25-4a2c62a1e11e	CASH_OUT	b62bd1ab-fdfb-4e9b-9ae4-acd0a476665f	ACTIVE	ACTIVE	http://localhost:4000	12
34d60118-3be0-4cb7-bf3a-e5dafe1fd156	2026-04-24 03:18:21.864717+00	\N	2026-04-24 03:18:21.864717+00	\N	\N	\N	04c26b41-1e0b-49a6-aa25-4a2c62a1e11e	INQUIRY	733a3c63-69a6-41a0-bc2a-9a0afced8f84	ACTIVE	ACTIVE	http://localhost:4000	12
a4bf5cd1-23a5-4941-a5d1-8130d0d4f0ba	2026-04-24 03:18:21.864717+00	\N	2026-04-24 03:18:21.864717+00	\N	\N	\N	04c26b41-1e0b-49a6-aa25-4a2c62a1e11e	CASH_OUT	b16eba77-bd9c-44d1-ad56-65e2a38bc09b	ACTIVE	ACTIVE	http://localhost:4000	12
cc018e73-18c7-4f7c-8f52-0149149a59c9	2026-04-24 03:18:21.864717+00	\N	2026-04-24 03:18:21.864717+00	\N	\N	\N	04c26b41-1e0b-49a6-aa25-4a2c62a1e11e	INQUIRY	10041899-439b-4b97-a123-6a4793de6bd5	ACTIVE	ACTIVE	http://localhost:4000	12
3f7ab460-765c-4d11-b2cb-aa2c2e151297	2026-04-24 03:18:21.864717+00	\N	2026-04-24 03:18:21.864717+00	\N	\N	\N	04c26b41-1e0b-49a6-aa25-4a2c62a1e11e	CHECK_STATUS	c32d2c1c-ad6b-40c8-9221-d248c6da26e2	ACTIVE	ACTIVE	http://localhost:4000	12
783eb297-f42e-44aa-9f08-488922dcb108	2026-04-24 03:18:21.864717+00	\N	2026-04-24 03:18:21.864717+00	\N	\N	\N	04c26b41-1e0b-49a6-aa25-4a2c62a1e11e	CASH_OUT	6bb11428-f6d1-4c78-a4c9-7f94a5852c4e	ACTIVE	ACTIVE	http://localhost:4000	12
d9958658-7d0a-48c8-9572-324d2d0d6e0e	2026-04-24 03:18:21.864717+00	\N	2026-04-24 03:18:21.864717+00	\N	\N	\N	04c26b41-1e0b-49a6-aa25-4a2c62a1e11e	INQUIRY	58dbe3b0-5a54-4183-b103-b9c20a1d35df	ACTIVE	ACTIVE	http://localhost:4000	12
\.


--
-- Data for Name: provider_channels_auth_histories; Type: TABLE DATA; Schema: public; Owner: postgres_user
--

COPY public.provider_channels_auth_histories (id, created_at, created_by, updated_at, updated_by, deleted_at, deleted_by, provider_channel_id, response_code, response_message, response_status) FROM stdin;
\.


--
-- Data for Name: provider_disbursement_traffic_balances; Type: TABLE DATA; Schema: public; Owner: postgres_user
--

COPY public.provider_disbursement_traffic_balances (id, created_at, created_by, updated_at, updated_by, deleted_at, deleted_by, provider_channel_id, channel_code, weight) FROM stdin;
\.


--
-- Data for Name: provider_fees; Type: TABLE DATA; Schema: public; Owner: postgres_user
--

COPY public.provider_fees (id, created_at, created_by, updated_at, updated_by, deleted_at, deleted_by, provider_channel_id, provider_id, fee_type, fee_fixed, fee_percentage, fee_status, begin_active_date, end_active_date) FROM stdin;
6614d998-7c1c-4587-8031-b104c49a2de0	2026-04-23 08:29:05.919224+00	5f7e8b2f-c678-45eb-990a-5155ffef61f9	2026-04-23 08:29:05.919224+00	5f7e8b2f-c678-45eb-990a-5155ffef61f9	\N	\N	80f1867f-ec69-4b35-ac84-b29ef4537134	04c26b41-1e0b-49a6-aa25-4a2c62a1e11e	FIXED	20000.00	0.00	INACTIVE	2026-04-23 08:29:05.919224+00	\N
\.


--
-- Data for Name: provider_response_codes; Type: TABLE DATA; Schema: public; Owner: postgres_user
--

COPY public.provider_response_codes (id, created_at, created_by, updated_at, updated_by, deleted_at, deleted_by, provider_id, response_code, messages) FROM stdin;
\.


--
-- Data for Name: providers; Type: TABLE DATA; Schema: public; Owner: postgres_user
--

COPY public.providers (id, created_at, created_by, updated_at, updated_by, deleted_at, deleted_by, name, adapter_name, status, adapter_deployment_service, api_timeout, api_retry, deposit_balance) FROM stdin;
04c26b41-1e0b-49a6-aa25-4a2c62a1e11e	2026-04-23 08:27:13.967861+00	5f7e8b2f-c678-45eb-990a-5155ffef61f9	2026-04-23 08:27:13.967861+00	5f7e8b2f-c678-45eb-990a-5155ffef61f9	\N	\N	Nobunaga	api-adapter-nobu	ACTIVE	localhost:7979	200	5	100000000.00
\.


--
-- Data for Name: qris_acquirers; Type: TABLE DATA; Schema: public; Owner: postgres_user
--

COPY public.qris_acquirers (id, created_at, created_by, updated_at, updated_by, deleted_at, deleted_by, provider_channel_id, acquirer_name) FROM stdin;
93484ef9-de32-4988-b37d-13f23f47faa9	2026-04-23 08:29:05.919224+00	5f7e8b2f-c678-45eb-990a-5155ffef61f9	2026-04-23 08:29:05.919224+00	5f7e8b2f-c678-45eb-990a-5155ffef61f9	\N	\N	80f1867f-ec69-4b35-ac84-b29ef4537134	Nobunaga
\.


--
-- Data for Name: schema_migrations; Type: TABLE DATA; Schema: public; Owner: postgres_user
--

COPY public.schema_migrations (version, dirty) FROM stdin;
82	f
\.


--
-- Data for Name: settlement_processes; Type: TABLE DATA; Schema: public; Owner: postgres_user
--

COPY public.settlement_processes (id, created_at, created_by, updated_at, updated_by, deleted_at, deleted_by, merchant_id, settlement_type, settlement_day, begin_settlement_datetime, end_settlement_datetime, settlement_datetime, settlement_amount, settlement_batch_id, store_id, store_name) FROM stdin;
\.


--
-- Data for Name: store_qris_nmids; Type: TABLE DATA; Schema: public; Owner: postgres_user
--

COPY public.store_qris_nmids (id, created_at, created_by, updated_at, updated_by, deleted_at, deleted_by, merchant_id, store_id, nmid, qris_acquirer_id) FROM stdin;
4fd0fdf3-0064-45eb-8963-395478a80b0a	2026-04-23 08:30:48.601641+00	5f7e8b2f-c678-45eb-990a-5155ffef61f9	2026-04-23 08:30:48.601641+00	5f7e8b2f-c678-45eb-990a-5155ffef61f9	\N	\N	7848b9ca-b4b4-426f-bf87-d2d109b4361a	cc1bdbec-342f-490c-b637-1d258c9ee1ef	1234	93484ef9-de32-4988-b37d-13f23f47faa9
3090b041-c899-48fc-9062-7471cc94d23e	2026-04-23 08:35:04.70529+00	5f7e8b2f-c678-45eb-990a-5155ffef61f9	2026-04-23 08:35:04.70529+00	5f7e8b2f-c678-45eb-990a-5155ffef61f9	\N	\N	7848b9ca-b4b4-426f-bf87-d2d109b4361a	cc1bdbec-342f-490c-b637-1d258c9ee1ef	1000	93484ef9-de32-4988-b37d-13f23f47faa9
\.


--
-- Data for Name: store_transaction_limit_rules; Type: TABLE DATA; Schema: public; Owner: postgres_user
--

COPY public.store_transaction_limit_rules (id, created_at, created_by, updated_at, updated_by, deleted_at, deleted_by, store_id, limit_amount, limit_cycle) FROM stdin;
03d6cb0d-f1fe-4958-9ca1-28bac90f48c3	2026-04-23 08:30:48.487585+00	5f7e8b2f-c678-45eb-990a-5155ffef61f9	2026-04-23 08:30:48.487585+00	5f7e8b2f-c678-45eb-990a-5155ffef61f9	\N	\N	cc1bdbec-342f-490c-b637-1d258c9ee1ef	10000000.00	DAILY
7dd1a5e6-2b7f-4452-9b8e-b04dd398b50e	2026-04-23 08:30:48.487585+00	5f7e8b2f-c678-45eb-990a-5155ffef61f9	2026-04-23 08:30:48.487585+00	5f7e8b2f-c678-45eb-990a-5155ffef61f9	\N	\N	cc1bdbec-342f-490c-b637-1d258c9ee1ef	100000000.00	MONTHLY
\.


--
-- Data for Name: stores; Type: TABLE DATA; Schema: public; Owner: postgres_user
--

COPY public.stores (id, created_at, created_by, updated_at, updated_by, deleted_at, deleted_by, merchant_id, store_name, address, status, pending_balance) FROM stdin;
cc1bdbec-342f-490c-b637-1d258c9ee1ef	2026-04-23 08:30:48.487585+00	5f7e8b2f-c678-45eb-990a-5155ffef61f9	2026-04-24 04:27:56.856969+00	5f7e8b2f-c678-45eb-990a-5155ffef61f9	\N	\N	7848b9ca-b4b4-426f-bf87-d2d109b4361a	Bimbel Dora		ACTIVE	105000.00
\.


--
-- Data for Name: transactions; Type: TABLE DATA; Schema: public; Owner: postgres_user
--

COPY public.transactions (id, created_at, created_by, updated_at, updated_by, deleted_at, deleted_by, merchant_id, store_id, transaction_timestamp, status_changed_timestamp, transaction_date, transaction_type, transaction_status, previous_transaction_status, transaction_expired_time, transaction_valid_time, transaction_paid_at, channel, channel_group, amount, fee, provider_fee, fee_type, fee_id, provider_id, provider_channel_id, provider_fee_id, provider_snap, provider_response_code, provider_response_message, provider_reference, provider_status_changed_timestamp, provider_previous_response_code, provider_previous_response_message, reference, merchant_reference, merchant_callback_url, merchant_callback_response_code, merchant_callback_response_message, merchant_callback_sent_timestamp, revenue, bank_code, bank_account_id, additional_info, acquirer, settled_at, is_settled, response_code, response_message, previous_response_code, previous_response_message, currency, retrieval_reference_number, merchant_fixed_fee, merchant_percentage_fee, mpan, merchant_amount, settlement_status, settlement_batch_id, payer_name, payer_phone_number) FROM stdin;
dd07e35a-df6f-4aa6-9c86-4901a70d424d	2026-04-23 09:43:26.849139+00	\N	2026-04-23 09:43:26.849139+00	\N	\N	\N	7848b9ca-b4b4-426f-bf87-d2d109b4361a	00000000-0000-0000-0000-000000000000	2026-04-23 09:43:26.746709+00	\N	2026-04-23	CASH_IN	FAILED	\N	2026-04-23 09:58:26.753773+00	900	\N	QRIS	QRIS	10000.00	0.00	\N		00000000-0000-0000-0000-000000000000	00000000-0000-0000-0000-000000000000	00000000-0000-0000-0000-000000000000	\N	t			\N	\N	\N	\N	17769374067462SDGVHB53IK6	20201029000000000000001		\N	\N	\N	\N	\N	\N	{"channel": "mobile", "deviceId": "device001"}		\N	f	40412308	Invalid Merchant	\N	\N	IDR	\N	0.00	0.00	\N	0.00	FAILED	\N	\N	\N
a356fa05-0c9c-4e25-a9e0-4c08b95e96fe	2026-04-23 09:45:05.935142+00	\N	2026-04-23 09:45:05.935142+00	\N	\N	\N	7848b9ca-b4b4-426f-bf87-d2d109b4361a	00000000-0000-0000-0000-000000000000	2026-04-23 09:45:05.894876+00	\N	2026-04-23	CASH_IN	FAILED	\N	2026-04-23 10:00:05.899125+00	900	\N	QRIS	QRIS	10000.00	0.00	\N		00000000-0000-0000-0000-000000000000	00000000-0000-0000-0000-000000000000	00000000-0000-0000-0000-000000000000	\N	t			\N	\N	\N	\N	1776937505894OvsXMEsNJCsY	20201029000000000000001		\N	\N	\N	\N	\N	\N	{"channel": "mobile", "deviceId": "device001"}		\N	f	40412308	Invalid Merchant	\N	\N	IDR	\N	0.00	0.00	\N	0.00	FAILED	\N	\N	\N
007ae04a-fce7-41ee-9f5a-0e396b185834	2026-04-23 09:45:06.680536+00	\N	2026-04-23 09:45:06.680536+00	\N	\N	\N	7848b9ca-b4b4-426f-bf87-d2d109b4361a	00000000-0000-0000-0000-000000000000	2026-04-23 09:45:06.670475+00	\N	2026-04-23	CASH_IN	FAILED	\N	2026-04-23 10:00:06.673802+00	900	\N	QRIS	QRIS	10000.00	0.00	\N		00000000-0000-0000-0000-000000000000	00000000-0000-0000-0000-000000000000	00000000-0000-0000-0000-000000000000	\N	t			\N	\N	\N	\N	1776937506670mjXLuTtaASyr	20201029000000000000001		\N	\N	\N	\N	\N	\N	{"channel": "mobile", "deviceId": "device001"}		\N	f	40412308	Invalid Merchant	\N	\N	IDR	\N	0.00	0.00	\N	0.00	FAILED	\N	\N	\N
04874619-e4c3-47d8-b870-6479acf9efe9	2026-04-23 09:45:07.160835+00	\N	2026-04-23 09:45:07.160835+00	\N	\N	\N	7848b9ca-b4b4-426f-bf87-d2d109b4361a	00000000-0000-0000-0000-000000000000	2026-04-23 09:45:07.153161+00	\N	2026-04-23	CASH_IN	FAILED	\N	2026-04-23 10:00:07.154597+00	900	\N	QRIS	QRIS	10000.00	0.00	\N		00000000-0000-0000-0000-000000000000	00000000-0000-0000-0000-000000000000	00000000-0000-0000-0000-000000000000	\N	t			\N	\N	\N	\N	1776937507153MqqY43FCDOyO	20201029000000000000001		\N	\N	\N	\N	\N	\N	{"channel": "mobile", "deviceId": "device001"}		\N	f	40412308	Invalid Merchant	\N	\N	IDR	\N	0.00	0.00	\N	0.00	FAILED	\N	\N	\N
6b6c70a0-dac8-4163-9373-4058d525b972	2026-04-23 09:45:45.940285+00	\N	2026-04-23 09:45:45.940285+00	\N	\N	\N	7848b9ca-b4b4-426f-bf87-d2d109b4361a	cc1bdbec-342f-490c-b637-1d258c9ee1ef	2026-04-23 09:45:45.879335+00	\N	2026-04-23	CASH_IN	FAILED	\N	2026-04-23 10:00:45.907019+00	900	\N	QRIS	QRIS	10000.00	25000.00	\N	FIXED	f9f74dc8-d928-4106-9d06-aeec965a6019	04c26b41-1e0b-49a6-aa25-4a2c62a1e11e	80f1867f-ec69-4b35-ac84-b29ef4537134	\N	t			\N	\N	\N	\N	1776937545879MXjrGncl11fr	20201029000000000000001	http://merchant-client:12345/v1.0/qr/qr-mpm-notify	\N	\N	\N	\N	\N	\N	{"channel": "mobile", "deviceId": "device001"}	Nobunaga	\N	f	40912301	Duplicate partnerReferenceNo	\N	\N	IDR	\N	25000.00	0.00	\N	-15000.00	FAILED	\N	\N	\N
d94da691-6a08-460c-be7e-d9ceebbfaf1d	2026-04-23 09:45:48.644652+00	\N	2026-04-23 09:45:48.644652+00	\N	\N	\N	7848b9ca-b4b4-426f-bf87-d2d109b4361a	cc1bdbec-342f-490c-b637-1d258c9ee1ef	2026-04-23 09:45:48.565072+00	\N	2026-04-23	CASH_IN	FAILED	\N	2026-04-23 10:00:48.624071+00	900	\N	QRIS	QRIS	10000.00	25000.00	\N	FIXED	f9f74dc8-d928-4106-9d06-aeec965a6019	04c26b41-1e0b-49a6-aa25-4a2c62a1e11e	80f1867f-ec69-4b35-ac84-b29ef4537134	\N	t			\N	\N	\N	\N	1776937548565SMO9NUHDPMA0	20201029000000000000002	http://merchant-client:12345/v1.0/qr/qr-mpm-notify	\N	\N	\N	\N	\N	\N	{"channel": "mobile", "deviceId": "device001"}	Nobunaga	\N	f	50312300	Service Unavailable	\N	\N	IDR	\N	25000.00	0.00	\N	-15000.00	FAILED	\N	\N	\N
52530e41-6a6e-4c7c-9bd1-279fb8393fce	2026-04-23 09:47:04.635206+00	\N	2026-04-23 09:47:04.635206+00	\N	\N	\N	7848b9ca-b4b4-426f-bf87-d2d109b4361a	cc1bdbec-342f-490c-b637-1d258c9ee1ef	2026-04-23 09:47:04.582224+00	\N	2026-04-23	CASH_IN	FAILED	\N	2026-04-23 10:02:04.611718+00	900	\N	QRIS	QRIS	10000.00	25000.00	\N	FIXED	f9f74dc8-d928-4106-9d06-aeec965a6019	04c26b41-1e0b-49a6-aa25-4a2c62a1e11e	80f1867f-ec69-4b35-ac84-b29ef4537134	\N	t			\N	\N	\N	\N	1776937624581yPYF961itt9K	20201029000000000000003	http://merchant-client:12345/v1.0/qr/qr-mpm-notify	\N	\N	\N	\N	\N	\N	{"channel": "mobile", "deviceId": "device001"}	Nobunaga	\N	f	50312300	Service Unavailable	\N	\N	IDR	\N	25000.00	0.00	\N	-15000.00	FAILED	\N	\N	\N
a9c1a905-a7a6-498c-b7df-6f93da830eb8	2026-04-23 09:47:41.379747+00	\N	2026-04-23 09:47:41.379747+00	\N	\N	\N	7848b9ca-b4b4-426f-bf87-d2d109b4361a	cc1bdbec-342f-490c-b637-1d258c9ee1ef	2026-04-23 09:47:41.276888+00	\N	2026-04-23	CASH_IN	FAILED	\N	2026-04-23 10:02:41.323991+00	900	\N	QRIS	QRIS	10000.00	25000.00	\N	FIXED	f9f74dc8-d928-4106-9d06-aeec965a6019	04c26b41-1e0b-49a6-aa25-4a2c62a1e11e	80f1867f-ec69-4b35-ac84-b29ef4537134	\N	t			\N	\N	\N	\N	1776937661276NoxgpDDuBPh5	20201029000000000000004	http://merchant-client:12345/v1.0/qr/qr-mpm-notify	\N	\N	\N	\N	\N	\N	{"channel": "mobile", "deviceId": "device001"}	Nobunaga	\N	f	50312300	Service Unavailable	\N	\N	IDR	\N	25000.00	0.00	\N	-15000.00	FAILED	\N	\N	\N
a0308e22-6520-4e00-92db-7ccb678bb0e8	2026-04-23 10:33:27.597079+00	\N	2026-04-23 10:33:27.597079+00	\N	\N	\N	00000000-0000-0000-0000-000000000000	00000000-0000-0000-0000-000000000000	2026-04-23 10:33:27.50877+00	\N	2026-04-23	CASH_IN	FAILED	\N	2026-04-23 10:33:27.542235+00	0	\N	QRIS	QRIS	0.00	0.00	\N		00000000-0000-0000-0000-000000000000	00000000-0000-0000-0000-000000000000	00000000-0000-0000-0000-000000000000	\N	t			\N	\N	\N	\N	1776940407507eJazUpCUB4v3			\N	\N	\N	\N	\N	\N	{"channel": "", "deviceId": ""}		\N	f	40112300	Unauthorized	\N	\N		\N	0.00	0.00	\N	0.00	FAILED	\N	\N	\N
c06725de-410f-445d-a18a-d63cf72e7035	2026-04-23 10:38:14.698364+00	\N	2026-04-23 10:38:14.698364+00	\N	\N	\N	7848b9ca-b4b4-426f-bf87-d2d109b4361a	cc1bdbec-342f-490c-b637-1d258c9ee1ef	2026-04-23 10:38:14.624073+00	\N	2026-04-23	CASH_IN	FAILED	\N	2026-04-23 10:53:14.648112+00	900	\N	QRIS	QRIS	10000.00	25000.00	\N	FIXED	f9f74dc8-d928-4106-9d06-aeec965a6019	04c26b41-1e0b-49a6-aa25-4a2c62a1e11e	80f1867f-ec69-4b35-ac84-b29ef4537134	\N	t			\N	\N	\N	\N	1776940694623IpkFfbX6YQ6d	20201029000000000000005	http://merchant-client:12345/v1.0/qr/qr-mpm-notify	\N	\N	\N	\N	\N	\N	{"channel": "mobile", "deviceId": "device001"}	Nobunaga	\N	f	50312300	Service Unavailable	\N	\N	IDR	\N	25000.00	0.00	\N	-15000.00	FAILED	\N	\N	\N
a99f3d48-9360-4e3d-87cc-25c3c5578c7e	2026-04-23 10:39:20.156067+00	\N	2026-04-23 10:39:20.156067+00	\N	\N	\N	7848b9ca-b4b4-426f-bf87-d2d109b4361a	cc1bdbec-342f-490c-b637-1d258c9ee1ef	2026-04-23 10:39:20.054877+00	\N	2026-04-23	CASH_IN	FAILED	\N	2026-04-23 10:54:20.128546+00	900	\N	QRIS	QRIS	10000.00	25000.00	\N	FIXED	f9f74dc8-d928-4106-9d06-aeec965a6019	04c26b41-1e0b-49a6-aa25-4a2c62a1e11e	80f1867f-ec69-4b35-ac84-b29ef4537134	\N	t			\N	\N	\N	\N	17769407600526FUUCype3nLA	20201029000000000000006	http://merchant-client:12345/v1.0/qr/qr-mpm-notify	\N	\N	\N	\N	\N	\N	{"channel": "mobile", "deviceId": "device001"}	Nobunaga	\N	f	50312300	Service Unavailable	\N	\N	IDR	\N	25000.00	0.00	\N	-15000.00	FAILED	\N	\N	\N
ef8bce8c-c84e-450e-bb07-22e0d56ce948	2026-04-24 03:13:17.782152+00	\N	2026-04-24 03:13:17.782152+00	\N	\N	\N	7848b9ca-b4b4-426f-bf87-d2d109b4361a	cc1bdbec-342f-490c-b637-1d258c9ee1ef	2026-04-24 03:13:17.263614+00	\N	2026-04-24	CASH_IN	FAILED	\N	2026-04-24 03:28:17.568788+00	900	\N	QRIS	QRIS	10000.00	25000.00	\N	FIXED	f9f74dc8-d928-4106-9d06-aeec965a6019	04c26b41-1e0b-49a6-aa25-4a2c62a1e11e	80f1867f-ec69-4b35-ac84-b29ef4537134	\N	t			\N	\N	\N	\N	1777000397263jEhzL6kvF0yj	20201029000000000000001	http://merchant-client:12345/v1.0/qr/qr-mpm-notify	\N	\N	\N	\N	\N	\N	{"channel": "mobile", "deviceId": "device001"}	Nobunaga	\N	f	50312300	Service Unavailable	\N	\N	IDR	\N	25000.00	0.00	\N	-15000.00	FAILED	\N	\N	\N
4fafca16-385c-4fc1-8b6e-aa761402300a	2026-04-24 03:14:47.549614+00	\N	2026-04-24 03:14:47.549614+00	\N	\N	\N	7848b9ca-b4b4-426f-bf87-d2d109b4361a	cc1bdbec-342f-490c-b637-1d258c9ee1ef	2026-04-24 03:14:47.461474+00	\N	2026-04-24	CASH_IN	FAILED	\N	2026-04-24 03:29:47.490388+00	900	\N	QRIS	QRIS	10000.00	25000.00	\N	FIXED	f9f74dc8-d928-4106-9d06-aeec965a6019	04c26b41-1e0b-49a6-aa25-4a2c62a1e11e	80f1867f-ec69-4b35-ac84-b29ef4537134	\N	t			\N	\N	\N	\N	1777000487460wetylHr6MUOV	20201029000000000000002	http://merchant-client:12345/v1.0/qr/qr-mpm-notify	\N	\N	\N	\N	\N	\N	{"channel": "mobile", "deviceId": "device001"}	Nobunaga	\N	f	50312300	Service Unavailable	\N	\N	IDR	\N	25000.00	0.00	\N	-15000.00	FAILED	\N	\N	\N
91f551a7-d296-4a03-91b4-ec3e71dd3844	2026-04-24 03:19:40.777192+00	\N	2026-04-24 03:19:40.777192+00	\N	\N	\N	7848b9ca-b4b4-426f-bf87-d2d109b4361a	cc1bdbec-342f-490c-b637-1d258c9ee1ef	2026-04-24 03:19:40.669857+00	\N	2026-04-24	CASH_IN	FAILED	\N	2026-04-24 03:34:40.756895+00	900	\N	QRIS	QRIS	10000.00	25000.00	\N	FIXED	f9f74dc8-d928-4106-9d06-aeec965a6019	04c26b41-1e0b-49a6-aa25-4a2c62a1e11e	80f1867f-ec69-4b35-ac84-b29ef4537134	\N	t			\N	\N	\N	\N	1777000780669EGdwinpFB6Mz	20201029000000000000003	http://merchant-client:12345/v1.0/qr/qr-mpm-notify	\N	\N	\N	\N	\N	\N	{"channel": "mobile", "deviceId": "device001"}	Nobunaga	\N	f	50312300	Service Unavailable	\N	\N	IDR	\N	25000.00	0.00	\N	-15000.00	FAILED	\N	\N	\N
9171c9e2-31f3-463b-966c-128a1ab7d18c	2026-04-24 03:25:39.053468+00	\N	2026-04-24 03:25:39.053468+00	\N	\N	\N	00000000-0000-0000-0000-000000000000	00000000-0000-0000-0000-000000000000	2026-04-24 03:25:39.009087+00	\N	2026-04-24		FAILED	\N	2026-04-24 03:25:39.011624+00	0	\N			0.00	0.00	\N		00000000-0000-0000-0000-000000000000	00000000-0000-0000-0000-000000000000	00000000-0000-0000-0000-000000000000	\N	t			\N	\N	\N	\N	1777001139008wEcqCNbCMhza			\N	\N	\N	\N	\N	\N	{"channel": "", "deviceId": ""}		\N	f	4050000	Requested Function Is Not Supported	\N	\N		\N	0.00	0.00	\N	0.00	FAILED	\N	\N	\N
4c376fe0-8f2c-4e46-a579-98cc845c354c	2026-04-24 03:41:07.467144+00	\N	2026-04-24 03:41:07.467144+00	\N	\N	\N	7848b9ca-b4b4-426f-bf87-d2d109b4361a	cc1bdbec-342f-490c-b637-1d258c9ee1ef	2026-04-24 03:41:07.315145+00	\N	2026-04-24	CASH_IN	FAILED	\N	2026-04-24 03:56:07.439034+00	900	\N	QRIS	QRIS	10000.00	25000.00	\N	FIXED	f9f74dc8-d928-4106-9d06-aeec965a6019	04c26b41-1e0b-49a6-aa25-4a2c62a1e11e	80f1867f-ec69-4b35-ac84-b29ef4537134	\N	t			\N	\N	\N	\N	1777002067314mxGA16M1L8Sb	20201029000000000000003	http://merchant-client:12345/v1.0/qr/qr-mpm-notify	\N	\N	\N	\N	\N	\N	{"channel": "mobile", "deviceId": "device001"}	Nobunaga	\N	f	50312300	Service Unavailable	\N	\N	IDR	\N	25000.00	0.00	\N	-15000.00	FAILED	\N	\N	\N
b1e1c9c2-f1d2-44f8-a571-4a12e88b27bc	2026-04-24 03:44:56.905324+00	\N	2026-04-24 03:44:56.905324+00	\N	\N	\N	7848b9ca-b4b4-426f-bf87-d2d109b4361a	cc1bdbec-342f-490c-b637-1d258c9ee1ef	2026-04-24 03:44:56.796867+00	\N	2026-04-24	CASH_IN	PENDING	\N	2026-04-24 03:59:56.851613+00	900	\N	QRIS	QRIS	10000.00	25000.00	\N	FIXED	f9f74dc8-d928-4106-9d06-aeec965a6019	04c26b41-1e0b-49a6-aa25-4a2c62a1e11e	80f1867f-ec69-4b35-ac84-b29ef4537134	\N	t	2004700	Request has been processed successfully	\N	\N	\N	\N	1777002296796ykd3Fp4fKoWW	20201029000000000000005	http://merchant-client:12345/v1.0/qr/qr-mpm-notify	\N	\N	\N	\N	\N	\N	{"channel": "mobile", "deviceId": "device001"}	Nobunaga	\N	f	2004700	Request has been processed successfully	\N	\N	IDR	\N	25000.00	0.00	\N	-15000.00	PENDING	\N	\N	\N
6fc564b3-f51c-4216-af42-d0410e7fc0e6	2026-04-24 03:56:13.002928+00	\N	2026-04-24 03:56:13.002928+00	\N	\N	\N	7848b9ca-b4b4-426f-bf87-d2d109b4361a	cc1bdbec-342f-490c-b637-1d258c9ee1ef	2026-04-24 03:56:12.877768+00	\N	2026-04-24	CASH_IN	FAILED	\N	2026-04-24 04:11:12.961252+00	900	\N	QRIS	QRIS	10000.00	25000.00	\N	FIXED	f9f74dc8-d928-4106-9d06-aeec965a6019	04c26b41-1e0b-49a6-aa25-4a2c62a1e11e	80f1867f-ec69-4b35-ac84-b29ef4537134	\N	t			\N	\N	\N	\N	1777002972864XJfhYjTyVcPT	20201029000000000000005	http://merchant-client:12345/v1.0/qr/qr-mpm-notify	\N	\N	\N	\N	\N	\N	{"channel": "mobile", "deviceId": "device001"}	Nobunaga	\N	f	40912301	Duplicate partnerReferenceNo	\N	\N	IDR	\N	25000.00	0.00	\N	-15000.00	FAILED	\N	\N	\N
de648ed3-158f-4bd1-8e87-a010cacdcdff	2026-04-24 03:56:15.738542+00	\N	2026-04-24 04:05:30.67305+00	\N	\N	\N	7848b9ca-b4b4-426f-bf87-d2d109b4361a	cc1bdbec-342f-490c-b637-1d258c9ee1ef	2026-04-24 03:56:15.623728+00	2026-04-24 04:05:30.569937+00	2026-04-24	CASH_IN	SUCCESS	PENDING	2026-04-24 04:11:15.716782+00	900	2026-04-24 04:05:30.569937+00	QRIS	QRIS	10000.00	25000.00	\N	FIXED	f9f74dc8-d928-4106-9d06-aeec965a6019	04c26b41-1e0b-49a6-aa25-4a2c62a1e11e	80f1867f-ec69-4b35-ac84-b29ef4537134	\N	t	2004700	Request has been processed successfully	\N	\N	\N	\N	17770029756230p56CyBFr0Fs	20201029000000000000006	http://merchant-client:12345/v1.0/qr/qr-mpm-notify	INIT_ERROR	x509: failed to parse private key (use ParsePKCS1PrivateKey instead for this key format)	2026-04-24 04:05:30.67305+00	\N	\N	\N	{"channel": "mobile", "deviceId": "device001"}	Nobunaga	\N	f	2004700	Request has been processed successfully	\N	\N	IDR	4d56b23d-3862-4f30-b544-c275fd350a31	25000.00	0.00	\N	-15000.00	PENDING	\N	GOPAY	08123456789
eec2a109-1f55-4837-9ce9-646e2785daa6	2026-04-24 04:09:06.469742+00	\N	2026-04-24 04:09:06.469742+00	\N	\N	\N	00000000-0000-0000-0000-000000000000	00000000-0000-0000-0000-000000000000	2026-04-24 04:09:06.423214+00	\N	2026-04-24	CASH_IN	FAILED	\N	2026-04-24 04:09:06.434664+00	0	\N	QRIS	QRIS	0.00	0.00	\N		00000000-0000-0000-0000-000000000000	00000000-0000-0000-0000-000000000000	00000000-0000-0000-0000-000000000000	\N	t			\N	\N	\N	\N	17770037464198V43la8kv4OB			\N	\N	\N	\N	\N	\N	{"channel": "", "deviceId": ""}		\N	f	40112300	Unauthorized	\N	\N		\N	0.00	0.00	\N	0.00	FAILED	\N	\N	\N
00faa75c-e3fd-4834-a622-fde058b6f336	2026-04-24 04:09:09.821693+00	\N	2026-04-24 04:09:28.327118+00	\N	\N	\N	7848b9ca-b4b4-426f-bf87-d2d109b4361a	cc1bdbec-342f-490c-b637-1d258c9ee1ef	2026-04-24 04:09:09.719688+00	2026-04-24 04:09:28.303616+00	2026-04-24	CASH_IN	SUCCESS	PENDING	2026-04-24 04:24:09.806391+00	900	2026-04-24 04:09:28.303616+00	QRIS	QRIS	10000.00	25000.00	\N	FIXED	f9f74dc8-d928-4106-9d06-aeec965a6019	04c26b41-1e0b-49a6-aa25-4a2c62a1e11e	80f1867f-ec69-4b35-ac84-b29ef4537134	\N	t	2004700	Request has been processed successfully	\N	\N	\N	\N	1777003749719gRMYOSuXLyz7	20201029000000000000007	http://merchant-client:12345/v1.0/qr/qr-mpm-notify	INIT_ERROR	x509: failed to parse private key (use ParsePKCS1PrivateKey instead for this key format)	2026-04-24 04:09:28.327118+00	\N	\N	\N	{"channel": "mobile", "deviceId": "device001"}	Nobunaga	\N	f	2004700	Request has been processed successfully	\N	\N	IDR		25000.00	0.00	\N	-15000.00	PENDING	\N		
eb7d2365-5861-4699-b55c-e272829939f4	2026-04-24 04:14:29.556581+00	\N	2026-04-24 04:14:44.861406+00	\N	\N	\N	7848b9ca-b4b4-426f-bf87-d2d109b4361a	cc1bdbec-342f-490c-b637-1d258c9ee1ef	2026-04-24 04:14:29.433689+00	2026-04-24 04:14:44.833534+00	2026-04-24	CASH_IN	FAILED	PENDING	2026-04-24 04:29:29.519863+00	900	\N	QRIS	QRIS	10000.00	25000.00	\N	FIXED	f9f74dc8-d928-4106-9d06-aeec965a6019	04c26b41-1e0b-49a6-aa25-4a2c62a1e11e	80f1867f-ec69-4b35-ac84-b29ef4537134	\N	t	2004700	Request has been processed successfully	\N	\N	\N	\N	1777004069432QZgccZ8HtRLS	20201029000000000000008	http://merchant-client:12345/v1.0/qr/qr-mpm-notify	INIT_ERROR	x509: failed to parse private key (use ParsePKCS1PrivateKey instead for this key format)	2026-04-24 04:14:44.861406+00	\N	\N	\N	{"channel": "mobile", "deviceId": "device001"}	Nobunaga	\N	f	2004700	Request has been processed successfully	\N	\N	IDR		25000.00	0.00	\N	-15000.00	FAILED	\N		
fe1672a0-1937-4410-8d16-b39b4e6b6b1d	2026-04-24 04:14:47.421768+00	\N	2026-04-24 04:14:47.421768+00	\N	\N	\N	7848b9ca-b4b4-426f-bf87-d2d109b4361a	cc1bdbec-342f-490c-b637-1d258c9ee1ef	2026-04-24 04:14:47.38628+00	\N	2026-04-24	CASH_IN	FAILED	\N	2026-04-24 04:29:47.398049+00	900	\N	QRIS	QRIS	10000.00	25000.00	\N	FIXED	f9f74dc8-d928-4106-9d06-aeec965a6019	04c26b41-1e0b-49a6-aa25-4a2c62a1e11e	80f1867f-ec69-4b35-ac84-b29ef4537134	\N	t			\N	\N	\N	\N	1777004087386lqZxJeVKtzQk	20201029000000000000008	http://merchant-client:12345/v1.0/qr/qr-mpm-notify	\N	\N	\N	\N	\N	\N	{"channel": "mobile", "deviceId": "device001"}	Nobunaga	\N	f	40912301	Duplicate partnerReferenceNo	\N	\N	IDR	\N	25000.00	0.00	\N	-15000.00	FAILED	\N	\N	\N
9541eb25-6358-471a-895b-70421244584b	2026-04-24 04:14:50.414566+00	\N	2026-04-24 04:15:03.523573+00	\N	\N	\N	7848b9ca-b4b4-426f-bf87-d2d109b4361a	cc1bdbec-342f-490c-b637-1d258c9ee1ef	2026-04-24 04:14:50.375757+00	2026-04-24 04:15:03.507172+00	2026-04-24	CASH_IN	FAILED	PENDING	2026-04-24 04:29:50.39781+00	900	\N	QRIS	QRIS	10000.00	25000.00	\N	FIXED	f9f74dc8-d928-4106-9d06-aeec965a6019	04c26b41-1e0b-49a6-aa25-4a2c62a1e11e	80f1867f-ec69-4b35-ac84-b29ef4537134	\N	t	2004700	Request has been processed successfully	\N	\N	\N	\N	1777004090375bCa85BhzSPwS	20201029000000000000009	http://merchant-client:12345/v1.0/qr/qr-mpm-notify	INIT_ERROR	x509: failed to parse private key (use ParsePKCS1PrivateKey instead for this key format)	2026-04-24 04:15:03.523573+00	\N	\N	\N	{"channel": "mobile", "deviceId": "device001"}	Nobunaga	\N	f	2004700	Request has been processed successfully	\N	\N	IDR		25000.00	0.00	\N	-15000.00	FAILED	\N		
72111892-3292-4845-93cf-4993c477b016	2026-04-24 04:25:14.917329+00	\N	2026-04-24 04:25:14.917329+00	\N	\N	\N	00000000-0000-0000-0000-000000000000	00000000-0000-0000-0000-000000000000	2026-04-24 04:25:14.713025+00	\N	2026-04-24	CASH_IN	FAILED	\N	2026-04-24 04:25:14.734138+00	0	\N	QRIS	QRIS	0.00	0.00	\N		00000000-0000-0000-0000-000000000000	00000000-0000-0000-0000-000000000000	00000000-0000-0000-0000-000000000000	\N	t			\N	\N	\N	\N	17770047147124NJziX8gJdF4			\N	\N	\N	\N	\N	\N	{"channel": "", "deviceId": ""}		\N	f	40112300	Unauthorized	\N	\N		\N	0.00	0.00	\N	0.00	FAILED	\N	\N	\N
80d7d923-5c0a-4fd8-adca-d5c5619e407c	2026-04-24 04:25:17.900826+00	\N	2026-04-24 04:25:29.058486+00	\N	\N	\N	7848b9ca-b4b4-426f-bf87-d2d109b4361a	cc1bdbec-342f-490c-b637-1d258c9ee1ef	2026-04-24 04:25:17.752178+00	2026-04-24 04:25:29.018542+00	2026-04-24	CASH_IN	SUCCESS	PENDING	2026-04-24 04:40:17.871094+00	900	2026-04-24 04:25:29.018542+00	QRIS	QRIS	10000.00	25000.00	\N	FIXED	f9f74dc8-d928-4106-9d06-aeec965a6019	04c26b41-1e0b-49a6-aa25-4a2c62a1e11e	80f1867f-ec69-4b35-ac84-b29ef4537134	\N	t	2004700	Request has been processed successfully	\N	\N	\N	\N	1777004717751ApdkXjqRY20D	20201029000000000000010	http://merchant-client:12345/v1.0/qr/qr-mpm-notify	INIT_ERROR	x509: failed to parse private key (use ParsePKCS1PrivateKey instead for this key format)	2026-04-24 04:25:29.058486+00	\N	\N	\N	{"channel": "mobile", "deviceId": "device001"}	Nobunaga	\N	f	2004700	Request has been processed successfully	\N	\N	IDR		25000.00	0.00	\N	-15000.00	PENDING	\N		
bbfcada3-f4e8-4034-9881-c18a51503d6d	2026-04-24 04:27:11.195173+00	\N	2026-04-24 04:27:17.479251+00	\N	\N	\N	7848b9ca-b4b4-426f-bf87-d2d109b4361a	cc1bdbec-342f-490c-b637-1d258c9ee1ef	2026-04-24 04:27:11.053389+00	2026-04-24 04:27:17.443436+00	2026-04-24	CASH_IN	SUCCESS	PENDING	2026-04-24 04:42:11.134151+00	900	2026-04-24 04:27:17.443436+00	QRIS	QRIS	100000.00	25000.00	\N	FIXED	f9f74dc8-d928-4106-9d06-aeec965a6019	04c26b41-1e0b-49a6-aa25-4a2c62a1e11e	80f1867f-ec69-4b35-ac84-b29ef4537134	\N	t	2004700	Request has been processed successfully	\N	\N	\N	\N	1777004831052ADu8hTESVTYO	20201029000000000000011	http://merchant-client:12345/v1.0/qr/qr-mpm-notify	INIT_ERROR	x509: failed to parse private key (use ParsePKCS1PrivateKey instead for this key format)	2026-04-24 04:27:17.479251+00	\N	\N	\N	{"channel": "mobile", "deviceId": "device001"}	Nobunaga	\N	f	2004700	Request has been processed successfully	\N	\N	IDR		25000.00	0.00	\N	75000.00	PENDING	\N		
2a4c3da9-e0cb-403c-99e6-2fa491656a08	2026-04-24 04:27:46.460596+00	\N	2026-04-24 04:27:56.877062+00	\N	\N	\N	7848b9ca-b4b4-426f-bf87-d2d109b4361a	cc1bdbec-342f-490c-b637-1d258c9ee1ef	2026-04-24 04:27:46.395083+00	2026-04-24 04:27:56.856969+00	2026-04-24	CASH_IN	SUCCESS	PENDING	2026-04-24 04:42:46.436857+00	900	2026-04-24 04:27:56.856969+00	QRIS	QRIS	100000.00	25000.00	\N	FIXED	f9f74dc8-d928-4106-9d06-aeec965a6019	04c26b41-1e0b-49a6-aa25-4a2c62a1e11e	80f1867f-ec69-4b35-ac84-b29ef4537134	\N	t	2004700	Request has been processed successfully	\N	\N	\N	\N	17770048663940Zwrt8bV5J8q	20201029000000000000012	http://merchant-client:12345/v1.0/qr/qr-mpm-notify	INIT_ERROR	x509: failed to parse private key (use ParsePKCS1PrivateKey instead for this key format)	2026-04-24 04:27:56.877062+00	\N	\N	\N	{"channel": "mobile", "deviceId": "device001"}	Nobunaga	\N	f	2004700	Request has been processed successfully	\N	\N	IDR		25000.00	0.00	\N	75000.00	PENDING	\N		
\.


--
-- Data for Name: user_credentials; Type: TABLE DATA; Schema: public; Owner: postgres_user
--

COPY public.user_credentials (id, created_at, created_by, updated_at, updated_by, deleted_at, deleted_by, username, password, role, is_enabled, profile_id, merchant_id) FROM stdin;
5f7e8b2f-c678-45eb-990a-5155ffef61f9	2026-04-23 08:23:36.661203+00	\N	2026-04-23 08:23:36.661203+00	\N	\N	\N	super@example.com	$2a$10$l7SjOjbYE0XpjHXTFTXxwexem/B1VnxsjCdnCOeVG4ONdXEUSBrGO	SUPERADMIN	t	bf5b4c75-9aa0-4ec5-bf94-210e15e36340	\N
e9c4567f-7726-437d-b712-9c9cc8452b00	2026-04-23 08:30:48.487585+00	\N	2026-04-23 08:30:48.487585+00	\N	\N	\N	dororo@example.com		BUSINESS_OWNER	f	3cac3057-8458-4d5c-9908-654e18eebfbc	7848b9ca-b4b4-426f-bf87-d2d109b4361a
\.


--
-- Data for Name: user_profiles; Type: TABLE DATA; Schema: public; Owner: postgres_user
--

COPY public.user_profiles (id, created_at, created_by, updated_at, updated_by, deleted_at, deleted_by, profile_name, email, phone, merchant_id) FROM stdin;
bf5b4c75-9aa0-4ec5-bf94-210e15e36340	2026-04-23 08:23:36.738465+00	\N	2026-04-23 08:23:36.738465+00	\N	\N	\N	Super Admin	super@example.com	\N	\N
3cac3057-8458-4d5c-9908-654e18eebfbc	2026-04-23 08:30:48.487585+00	\N	2026-04-23 08:30:48.487585+00	\N	\N	\N	Dororo	dororo@example.com	\N	7848b9ca-b4b4-426f-bf87-d2d109b4361a
\.


--
-- Name: bank_infos bank_infos_pk; Type: CONSTRAINT; Schema: public; Owner: postgres_user
--

ALTER TABLE ONLY public.bank_infos
    ADD CONSTRAINT bank_infos_pk PRIMARY KEY (id);


--
-- Name: channel_groups channel_groups_pk; Type: CONSTRAINT; Schema: public; Owner: postgres_user
--

ALTER TABLE ONLY public.channel_groups
    ADD CONSTRAINT channel_groups_pk PRIMARY KEY (id);


--
-- Name: disbursement_limit_amounts disbursement_limit_amounts_pk; Type: CONSTRAINT; Schema: public; Owner: postgres_user
--

ALTER TABLE ONLY public.disbursement_limit_amounts
    ADD CONSTRAINT disbursement_limit_amounts_pk PRIMARY KEY (id);


--
-- Name: holiday_dates holiday_calendar_pk; Type: CONSTRAINT; Schema: public; Owner: postgres_user
--

ALTER TABLE ONLY public.holiday_dates
    ADD CONSTRAINT holiday_calendar_pk PRIMARY KEY (id);


--
-- Name: master_channels master_channels_pk; Type: CONSTRAINT; Schema: public; Owner: postgres_user
--

ALTER TABLE ONLY public.master_channels
    ADD CONSTRAINT master_channels_pk PRIMARY KEY (id);


--
-- Name: merchant_api_credentials merchant_api_credentials_pk; Type: CONSTRAINT; Schema: public; Owner: postgres_user
--

ALTER TABLE ONLY public.merchant_api_credentials
    ADD CONSTRAINT merchant_api_credentials_pk PRIMARY KEY (id);


--
-- Name: merchant_balance_mutations merchant_balance_mutations_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres_user
--

ALTER TABLE ONLY public.merchant_balance_mutations
    ADD CONSTRAINT merchant_balance_mutations_pkey PRIMARY KEY (id);


--
-- Name: merchant_categories merchant_categories_pk; Type: CONSTRAINT; Schema: public; Owner: postgres_user
--

ALTER TABLE ONLY public.merchant_categories
    ADD CONSTRAINT merchant_categories_pk PRIMARY KEY (id);


--
-- Name: merchant_channels merchant_channels_pk; Type: CONSTRAINT; Schema: public; Owner: postgres_user
--

ALTER TABLE ONLY public.merchant_channels
    ADD CONSTRAINT merchant_channels_pk PRIMARY KEY (id);


--
-- Name: merchant_fees merchant_fees_pk; Type: CONSTRAINT; Schema: public; Owner: postgres_user
--

ALTER TABLE ONLY public.merchant_fees
    ADD CONSTRAINT merchant_fees_pk PRIMARY KEY (id);


--
-- Name: merchant_settlement_configurations merchant_settlement_configurations_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres_user
--

ALTER TABLE ONLY public.merchant_settlement_configurations
    ADD CONSTRAINT merchant_settlement_configurations_pkey PRIMARY KEY (id);


--
-- Name: merchant_settlement_histories merchant_settlement_histories_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres_user
--

ALTER TABLE ONLY public.merchant_settlement_histories
    ADD CONSTRAINT merchant_settlement_histories_pkey PRIMARY KEY (id);


--
-- Name: merchant_banks merchants_banks_pk; Type: CONSTRAINT; Schema: public; Owner: postgres_user
--

ALTER TABLE ONLY public.merchant_banks
    ADD CONSTRAINT merchants_banks_pk PRIMARY KEY (id);


--
-- Name: merchants merchants_pk; Type: CONSTRAINT; Schema: public; Owner: postgres_user
--

ALTER TABLE ONLY public.merchants
    ADD CONSTRAINT merchants_pk PRIMARY KEY (id);


--
-- Name: provider_api_credentials provider_api_credential_pk; Type: CONSTRAINT; Schema: public; Owner: postgres_user
--

ALTER TABLE ONLY public.provider_api_credentials
    ADD CONSTRAINT provider_api_credential_pk PRIMARY KEY (id);


--
-- Name: provider_channels_auth_histories provider_channels_auth_histories_pk; Type: CONSTRAINT; Schema: public; Owner: postgres_user
--

ALTER TABLE ONLY public.provider_channels_auth_histories
    ADD CONSTRAINT provider_channels_auth_histories_pk PRIMARY KEY (id);


--
-- Name: provider_channels provider_channels_pk; Type: CONSTRAINT; Schema: public; Owner: postgres_user
--

ALTER TABLE ONLY public.provider_channels
    ADD CONSTRAINT provider_channels_pk PRIMARY KEY (id);


--
-- Name: provider_disbursement_traffic_balances provider_disbursement_traffic_balances_pk; Type: CONSTRAINT; Schema: public; Owner: postgres_user
--

ALTER TABLE ONLY public.provider_disbursement_traffic_balances
    ADD CONSTRAINT provider_disbursement_traffic_balances_pk PRIMARY KEY (id);


--
-- Name: provider_fees provider_fees_pk; Type: CONSTRAINT; Schema: public; Owner: postgres_user
--

ALTER TABLE ONLY public.provider_fees
    ADD CONSTRAINT provider_fees_pk PRIMARY KEY (id);


--
-- Name: provider_response_codes provider_response_codes_pk; Type: CONSTRAINT; Schema: public; Owner: postgres_user
--

ALTER TABLE ONLY public.provider_response_codes
    ADD CONSTRAINT provider_response_codes_pk PRIMARY KEY (id);


--
-- Name: providers providers_pk; Type: CONSTRAINT; Schema: public; Owner: postgres_user
--

ALTER TABLE ONLY public.providers
    ADD CONSTRAINT providers_pk PRIMARY KEY (id);


--
-- Name: qris_acquirers qris_acquirers_pk; Type: CONSTRAINT; Schema: public; Owner: postgres_user
--

ALTER TABLE ONLY public.qris_acquirers
    ADD CONSTRAINT qris_acquirers_pk PRIMARY KEY (id);


--
-- Name: schema_migrations schema_migrations_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres_user
--

ALTER TABLE ONLY public.schema_migrations
    ADD CONSTRAINT schema_migrations_pkey PRIMARY KEY (version);


--
-- Name: settlement_processes settlement_processes_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres_user
--

ALTER TABLE ONLY public.settlement_processes
    ADD CONSTRAINT settlement_processes_pkey PRIMARY KEY (id);


--
-- Name: store_qris_nmids store_qris_nmids_pk; Type: CONSTRAINT; Schema: public; Owner: postgres_user
--

ALTER TABLE ONLY public.store_qris_nmids
    ADD CONSTRAINT store_qris_nmids_pk PRIMARY KEY (id);


--
-- Name: store_transaction_limit_rules store_transaction_limit_rules_pk; Type: CONSTRAINT; Schema: public; Owner: postgres_user
--

ALTER TABLE ONLY public.store_transaction_limit_rules
    ADD CONSTRAINT store_transaction_limit_rules_pk PRIMARY KEY (id);


--
-- Name: stores stores_pk; Type: CONSTRAINT; Schema: public; Owner: postgres_user
--

ALTER TABLE ONLY public.stores
    ADD CONSTRAINT stores_pk PRIMARY KEY (id);


--
-- Name: transactions transactions_pk; Type: CONSTRAINT; Schema: public; Owner: postgres_user
--

ALTER TABLE ONLY public.transactions
    ADD CONSTRAINT transactions_pk PRIMARY KEY (id);


--
-- Name: user_credentials user_credentials_pk; Type: CONSTRAINT; Schema: public; Owner: postgres_user
--

ALTER TABLE ONLY public.user_credentials
    ADD CONSTRAINT user_credentials_pk PRIMARY KEY (id);


--
-- Name: user_profiles user_profiles_pk; Type: CONSTRAINT; Schema: public; Owner: postgres_user
--

ALTER TABLE ONLY public.user_profiles
    ADD CONSTRAINT user_profiles_pk PRIMARY KEY (id);


--
-- Name: disbursement_limit_amounts_provider_channel_id_idx; Type: INDEX; Schema: public; Owner: postgres_user
--

CREATE INDEX disbursement_limit_amounts_provider_channel_id_idx ON public.disbursement_limit_amounts USING btree (provider_channel_id);


--
-- Name: master_channels_channel_group_id_idx; Type: INDEX; Schema: public; Owner: postgres_user
--

CREATE INDEX master_channels_channel_group_id_idx ON public.master_channels USING btree (channel_group_id);


--
-- Name: merchant_api_credentials_merchant_id_idx; Type: INDEX; Schema: public; Owner: postgres_user
--

CREATE INDEX merchant_api_credentials_merchant_id_idx ON public.merchant_api_credentials USING btree (merchant_id);


--
-- Name: merchant_balance_mut_merchant_id_idx; Type: INDEX; Schema: public; Owner: postgres_user
--

CREATE INDEX merchant_balance_mut_merchant_id_idx ON public.merchant_balance_mutations USING btree (merchant_id);


--
-- Name: merchant_balance_mut_reference_id_idx; Type: INDEX; Schema: public; Owner: postgres_user
--

CREATE INDEX merchant_balance_mut_reference_id_idx ON public.merchant_balance_mutations USING btree (reference_id);


--
-- Name: merchant_categories_category_code_idx; Type: INDEX; Schema: public; Owner: postgres_user
--

CREATE INDEX merchant_categories_category_code_idx ON public.merchant_categories USING btree (merchant_category_code);


--
-- Name: merchant_categories_category_name_idx; Type: INDEX; Schema: public; Owner: postgres_user
--

CREATE INDEX merchant_categories_category_name_idx ON public.merchant_categories USING btree (merchant_category_name);


--
-- Name: merchant_channels_master_channel_id_idx; Type: INDEX; Schema: public; Owner: postgres_user
--

CREATE INDEX merchant_channels_master_channel_id_idx ON public.merchant_channels USING btree (master_channel_id);


--
-- Name: merchant_channels_merchant_id_idx; Type: INDEX; Schema: public; Owner: postgres_user
--

CREATE INDEX merchant_channels_merchant_id_idx ON public.merchant_channels USING btree (merchant_id);


--
-- Name: merchant_disbursement_limit_rules_merchant_id_idx; Type: INDEX; Schema: public; Owner: postgres_user
--

CREATE INDEX merchant_disbursement_limit_rules_merchant_id_idx ON public.merchant_disbursement_limit_rules USING btree (merchant_id);


--
-- Name: merchant_fees_merchant_channel_id_fee_type_idx; Type: INDEX; Schema: public; Owner: postgres_user
--

CREATE INDEX merchant_fees_merchant_channel_id_fee_type_idx ON public.merchant_fees USING btree (merchant_channel_id, fee_type);


--
-- Name: merchant_fees_merchant_channel_id_idx; Type: INDEX; Schema: public; Owner: postgres_user
--

CREATE INDEX merchant_fees_merchant_channel_id_idx ON public.merchant_fees USING btree (merchant_channel_id);


--
-- Name: merchant_fees_merchant_id_idx; Type: INDEX; Schema: public; Owner: postgres_user
--

CREATE INDEX merchant_fees_merchant_id_idx ON public.merchant_fees USING btree (merchant_id);


--
-- Name: merchant_settlement_configs_merchant_id_idx; Type: INDEX; Schema: public; Owner: postgres_user
--

CREATE INDEX merchant_settlement_configs_merchant_id_idx ON public.merchant_settlement_configurations USING btree (merchant_id);


--
-- Name: merchant_settlement_hist_merchant_id_idx; Type: INDEX; Schema: public; Owner: postgres_user
--

CREATE INDEX merchant_settlement_hist_merchant_id_idx ON public.merchant_settlement_histories USING btree (merchant_id);


--
-- Name: merchant_settlement_histories_merchant_sttlement_config_id_idx; Type: INDEX; Schema: public; Owner: postgres_user
--

CREATE INDEX merchant_settlement_histories_merchant_sttlement_config_id_idx ON public.merchant_settlement_histories USING btree (merchant_settlement_config_id);


--
-- Name: merchants_banks_merchant_id_idx; Type: INDEX; Schema: public; Owner: postgres_user
--

CREATE INDEX merchants_banks_merchant_id_idx ON public.merchant_banks USING btree (merchant_id);


--
-- Name: merchants_email_idx; Type: INDEX; Schema: public; Owner: postgres_user
--

CREATE INDEX merchants_email_idx ON public.merchants USING btree (email);


--
-- Name: merchants_merchant_code_idx; Type: INDEX; Schema: public; Owner: postgres_user
--

CREATE INDEX merchants_merchant_code_idx ON public.merchants USING btree (merchant_code);


--
-- Name: merchants_phone_idx; Type: INDEX; Schema: public; Owner: postgres_user
--

CREATE INDEX merchants_phone_idx ON public.merchants USING btree (phone);


--
-- Name: prov_disb_traffic_balances_provider_chan_id_idx; Type: INDEX; Schema: public; Owner: postgres_user
--

CREATE UNIQUE INDEX prov_disb_traffic_balances_provider_chan_id_idx ON public.provider_disbursement_traffic_balances USING btree (provider_channel_id);


--
-- Name: provider_api_credentials_provider_id_idx; Type: INDEX; Schema: public; Owner: postgres_user
--

CREATE INDEX provider_api_credentials_provider_id_idx ON public.provider_api_credentials USING btree (provider_id);


--
-- Name: provider_chan_auth_hists_provider_channel_id_idx; Type: INDEX; Schema: public; Owner: postgres_user
--

CREATE INDEX provider_chan_auth_hists_provider_channel_id_idx ON public.provider_channels_auth_histories USING btree (provider_channel_id);


--
-- Name: provider_channels_master_channel_id_idx; Type: INDEX; Schema: public; Owner: postgres_user
--

CREATE INDEX provider_channels_master_channel_id_idx ON public.provider_channels USING btree (master_channel_id);


--
-- Name: provider_channels_provider_id_idx; Type: INDEX; Schema: public; Owner: postgres_user
--

CREATE INDEX provider_channels_provider_id_idx ON public.provider_channels USING btree (provider_id);


--
-- Name: provider_fees_provider_channel_id_idx; Type: INDEX; Schema: public; Owner: postgres_user
--

CREATE INDEX provider_fees_provider_channel_id_idx ON public.provider_fees USING btree (provider_channel_id);


--
-- Name: provider_fees_provider_id_idx; Type: INDEX; Schema: public; Owner: postgres_user
--

CREATE INDEX provider_fees_provider_id_idx ON public.provider_fees USING btree (provider_id);


--
-- Name: provider_response_codes_provider_id_idx; Type: INDEX; Schema: public; Owner: postgres_user
--

CREATE INDEX provider_response_codes_provider_id_idx ON public.provider_response_codes USING btree (provider_id);


--
-- Name: providers_adapter_name_idx; Type: INDEX; Schema: public; Owner: postgres_user
--

CREATE INDEX providers_adapter_name_idx ON public.providers USING btree (adapter_name);


--
-- Name: qris_acquirers_provier_channel_id_idx; Type: INDEX; Schema: public; Owner: postgres_user
--

CREATE INDEX qris_acquirers_provier_channel_id_idx ON public.qris_acquirers USING btree (provider_channel_id);


--
-- Name: settlement_processes_merchant_id_idx; Type: INDEX; Schema: public; Owner: postgres_user
--

CREATE INDEX settlement_processes_merchant_id_idx ON public.settlement_processes USING btree (merchant_id);


--
-- Name: store_qris_nmids_merchant_id_idx; Type: INDEX; Schema: public; Owner: postgres_user
--

CREATE INDEX store_qris_nmids_merchant_id_idx ON public.store_qris_nmids USING btree (merchant_id);


--
-- Name: store_qris_nmids_nmid_idx; Type: INDEX; Schema: public; Owner: postgres_user
--

CREATE INDEX store_qris_nmids_nmid_idx ON public.store_qris_nmids USING btree (nmid);


--
-- Name: store_qris_nmids_qris_acquirer_id_idx; Type: INDEX; Schema: public; Owner: postgres_user
--

CREATE INDEX store_qris_nmids_qris_acquirer_id_idx ON public.store_qris_nmids USING btree (qris_acquirer_id);


--
-- Name: store_qris_nmids_store_id_idx; Type: INDEX; Schema: public; Owner: postgres_user
--

CREATE INDEX store_qris_nmids_store_id_idx ON public.store_qris_nmids USING btree (store_id);


--
-- Name: store_trx_lim_rule_store_id_idx; Type: INDEX; Schema: public; Owner: postgres_user
--

CREATE INDEX store_trx_lim_rule_store_id_idx ON public.store_transaction_limit_rules USING btree (store_id);


--
-- Name: stores_merchant_id_idx; Type: INDEX; Schema: public; Owner: postgres_user
--

CREATE INDEX stores_merchant_id_idx ON public.stores USING btree (merchant_id);


--
-- Name: stores_store_name_idx; Type: INDEX; Schema: public; Owner: postgres_user
--

CREATE INDEX stores_store_name_idx ON public.stores USING btree (store_name);


--
-- Name: transactions_settlement_idx; Type: INDEX; Schema: public; Owner: postgres_user
--

CREATE INDEX transactions_settlement_idx ON public.transactions USING btree (transaction_timestamp, merchant_id, store_id, transaction_status, transaction_type, is_settled);


--
-- Name: transactions_update_transactions_status_idx; Type: INDEX; Schema: public; Owner: postgres_user
--

CREATE INDEX transactions_update_transactions_status_idx ON public.transactions USING btree (transaction_date, provider_reference, transaction_status);


--
-- Name: user_credentials_merchant_id_idx; Type: INDEX; Schema: public; Owner: postgres_user
--

CREATE INDEX user_credentials_merchant_id_idx ON public.user_credentials USING btree (merchant_id);


--
-- Name: user_credentials_profile_id_idx; Type: INDEX; Schema: public; Owner: postgres_user
--

CREATE UNIQUE INDEX user_credentials_profile_id_idx ON public.user_credentials USING btree (profile_id);


--
-- Name: user_credentials_username_idx; Type: INDEX; Schema: public; Owner: postgres_user
--

CREATE UNIQUE INDEX user_credentials_username_idx ON public.user_credentials USING btree (username);


--
-- Name: user_profiles_email_idx; Type: INDEX; Schema: public; Owner: postgres_user
--

CREATE INDEX user_profiles_email_idx ON public.user_profiles USING btree (email);


--
-- Name: user_profiles_merchant_id_idx; Type: INDEX; Schema: public; Owner: postgres_user
--

CREATE INDEX user_profiles_merchant_id_idx ON public.user_profiles USING btree (merchant_id);


--
-- Name: user_profiles_phone_idx; Type: INDEX; Schema: public; Owner: postgres_user
--

CREATE INDEX user_profiles_phone_idx ON public.user_profiles USING btree (phone);


--
-- PostgreSQL database dump complete
--

\unrestrict ce8CckPszSii2OOLobsYBrhD4Laoyk5JOrOcYiGoCLIy5SlcOZufOBZZEIiDoqN

