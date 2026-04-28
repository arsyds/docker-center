# SemarPay Platform — Architecture Overview

## Documentation Index

| Document | Audience | Purpose |
|----------|---------|---------|
| **[Onboarding Guide](./onboarding.md)** | All | Local setup, dev workflow, mental models |
| **[Troubleshooting](./troubleshooting.md)** | All | Common failures and resolution steps |
| **[Data Migrations](./data-migrate.md)** | Backend | Schema management, migration conventions |
| [eagle-ops](./eagle-ops.md) | Backend | Back-office configuration service |
| [payment-middleware](./payment-middleware.md) | Backend | Core payment processing engine |
| [api-adapter](./api-adapter.md) | Backend | Nobu Bank integration layer |
| [provider-mock](./provider-mock.md) | Backend | Dev/test mock for Nobu Bank |
| [mobile-banking](./mobile-banking.md) | Backend | Standalone digital banking service |
| [ClickHouse Dual-Write](../clickhouse-dual-write.md) | Tech Lead | Analytics write strategy and reconciliation |

---

## Services

| Service | Role | Port(s) | Protocol |
|---------|------|---------|----------|
| `eagle-ops` | Back-office operations & configuration management | HTTP (configurable) | REST |
| `payment-middleware` | Payment processing engine (merchant-facing) | HTTP :8000, gRPC :50051 | REST + gRPC |
| `api-adapter` | Provider integration adapter (Nobu Bank) | gRPC :7979, HTTP :8080 | gRPC + REST |
| `provider-mock` | Mock Nobu Bank API (dev/test only) | HTTP :4000 | REST |

> **Note:** `mobile-banking` is a separate project with its own scope and is not part of the payment gateway platform. See [mobile-banking.md](./mobile-banking.md) for its standalone documentation.

---

## System-Wide Architecture

```
┌──────────────────────────────────────────────────────────────┐
│                      EXTERNAL ACTORS                          │
│                                                               │
│     Merchants (SNAP REST)         Payment Providers           │
└──────────────┬───────────────────────────────────────────────┘
               │
               ▼
┌─────────────────┐
│  payment-       │
│  middleware     │──────── gRPC ────────────────────────────────►┐
│  REST :8000     │                                               │
│  gRPC :50051    │◄─────── gRPC (QRIS callback relay) ──────────┐│
└─────────────────┘                                              ││
                                                                 ▼│
                                                    ┌─────────────────┐
                                                    │   api-adapter   │──► Nobu Bank API
                                                    │ gRPC :7979      │◄── Nobu Bank Callback
                                                    │ REST :8080      │
                                                    └─────────────────┘

               ▼
┌─────────────────┐
│  payment-       │──────────────► Merchant Callback (HTTP POST)
│  middleware     │
└─────────────────┘


┌─────────────────────────────────────────────────────────────┐
│                  SHARED INFRASTRUCTURE                       │
│                                                              │
│  ┌──────────────┐   ┌────────────────┐   ┌───────────────┐  │
│  │  PostgreSQL  │   │  Redis Cluster │   │   ClickHouse  │  │
│  │  :5432       │   │  :6379-6381    │   │   :9000       │  │
│  └──────────────┘   └────────────────┘   └───────────────┘  │
│                                                              │
│  ┌──────────────┐   ┌────────────────┐   ┌───────────────┐  │
│  │    Kafka     │   │    Mailpit     │   │    Haraka     │  │
│  │ :9092-9095   │   │ SMTP :1025     │   │ SMTP :2525    │  │
│  └──────────────┘   └────────────────┘   └───────────────┘  │
│                                                              │
│  ┌──────────────┐                                            │
│  │ provider-    │  (dev/test only — replaces Nobu Bank)      │
│  │ mock :4000   │                                            │
│  └──────────────┘                                            │
└─────────────────────────────────────────────────────────────┘
```

---

## Intra-Service Communication Map

```
eagle-ops ──────────────────────────────────────────────────────────────────►
  writes PostgreSQL (providers, channels, merchants, fees, stores, credentials)
  writes Redis (merchant cache, channel cache, credential cache)
  reads  ClickHouse (analytics, reconciliation)

payment-middleware ──────────────────────────────────────────────────────────►
  reads  Redis (credentials, channels, limits — written by eagle-ops)
  writes PostgreSQL (transactions, balance mutations)
  writes ClickHouse (transaction_rmt dual-write)
  calls  gRPC api-adapter (CreateQrisTransaction, RTOLTransaction, …)
  calls  HTTP merchant (callback notification)
  writes Kafka (merchant-api-log)

api-adapter ─────────────────────────────────────────────────────────────────►
  reads  PostgreSQL (provisioning: providers, channels, credentials, fees)
  writes Redis (provider tokens, channel configs, credentials, fees)
  calls  HTTP Nobu Bank (QR, RTOL, BIFAST, Intrabank, Auth)
  calls  gRPC payment-middleware (NotifyQrisTransaction)
  writes Kafka (provider-api-log, provisioning-log, bifast-status-log, inquiry-log)
  receives HTTP Nobu Bank callback (/v1.0/qr/qr-mpm-notify)

provider-mock ───────────────────────────────────────────────────────────────►
  no outbound calls
  receives HTTP from api-adapter (dev/test only)
```

---

## Data Flow: Merchant QR Payment (End-to-End)

```
1.  Merchant          POST /v1.0/access-token/b2b → payment-middleware
                      ← JWT (900s)

2.  Merchant          POST /v1.0/qr/qr-mpm-generate → payment-middleware
      Middleware chain: Log → Channel → Headers → Payload → Enrichment → Idempotency

3.  payment-middleware gRPC CreateQrisTransaction → api-adapter
      api-adapter: load credentials from Redis
      api-adapter: refresh Bearer token (Redis cache or Nobu Bank auth)
      api-adapter: POST /v1.2/qr/qr-mpm-generate/ → Nobu Bank
      api-adapter: produce provider-api-log → Kafka
      api-adapter: ← QR content

4.  payment-middleware INSERT transaction (PENDING) → PostgreSQL
5.  payment-middleware INSERT transaction_rmt → ClickHouse (async)
6.  payment-middleware ← QR content to Merchant

--- Customer scans QR and pays ---

7.  Nobu Bank          POST /v1.0/qr/qr-mpm-notify → api-adapter (REST :8080)
      Replay check → Timestamp check → JWT+HMAC validate

8.  api-adapter        gRPC NotifyQrisTransaction → payment-middleware

9.  payment-middleware UPDATE transaction (SUCCESS/FAILED) → PostgreSQL
10. payment-middleware UPDATE Redis (store_limit_balance, reference cleanup)
11. payment-middleware INSERT transaction_rmt (final state) → ClickHouse (async)
12. payment-middleware POST /v1.0/access-token/b2b → Merchant (get callback token)
13. payment-middleware POST /v1.0/qr/qr-mpm-notify → Merchant (send result)
14. payment-middleware produce merchant-api-log → Kafka
```

---

## Database Ownership by Service

### PostgreSQL

| Table Group | Primary Writer | Primary Reader(s) |
|-------------|---------------|-------------------|
| `merchants`, `stores`, `merchant_*` | eagle-ops | payment-middleware (via Redis cache) |
| `providers`, `provider_channels`, `provider_api_credentials`, `provider_fees` | eagle-ops | api-adapter (provisioning), payment-middleware |
| `master_channels`, `channel_groups` | eagle-ops | payment-middleware, api-adapter |
| `bank_infos` | eagle-ops | payment-middleware |
| `transactions` | payment-middleware | eagle-ops (analytics), payment-middleware |
| `merchant_balance_mutations` | payment-middleware | eagle-ops (balance views) |
| `settlement_processes`, `merchant_settlement_*` | payment-middleware | eagle-ops (settlement reports) |
| `provider_disbursement_traffic_balances` | eagle-ops | api-adapter (balancer), payment-middleware |
| `user_profiles`, `user_credentials` | eagle-ops | eagle-ops (ops users) |

### Redis Cluster

| Key Namespace | Written By | Read By |
|---------------|-----------|---------|
| `merchant_*` | eagle-ops | payment-middleware |
| `master_channel_*` | eagle-ops (30s sync) | payment-middleware |
| `provider_channel_*`, `provider_adapter_*` | api-adapter (provisioning) | api-adapter, payment-middleware |
| `provider_channel_tokens_*` | api-adapter | api-adapter |
| `merchant_active_token_*` | payment-middleware | payment-middleware |
| `api_idempotency_*` | payment-middleware | payment-middleware |
| `store_limit_*` | eagle-ops, payment-middleware | payment-middleware |
| `bifast_pending_trx_*` | api-adapter | api-adapter (background poller) |
| `replay_*` | api-adapter | api-adapter (replay protection) |

### ClickHouse

| Table | Writer | Reader |
|-------|--------|--------|
| `transaction_rmt` | payment-middleware (dual-write) | eagle-ops (analytics, reconciliation) |
| `provider_api_log` | api-adapter → Kafka → ClickHouse consumer (external) | eagle-ops |
| `merchant_api_log` | payment-middleware → Kafka → ClickHouse consumer (external) | eagle-ops |

### Kafka Topics

| Topic | Producer | Purpose |
|-------|---------|---------|
| `merchant-api-log` | payment-middleware | Merchant API call audit |
| `provider-api-log` | api-adapter | Nobu Bank API call audit |
| `provisioning-log` | api-adapter | Credential sync events |
| `bifast-transaction-status-log` | api-adapter | BIFAST pending status updates |
| `balance-inquiry-log` | api-adapter | Periodic balance check results |

---

## Infrastructure (docker-compose.yml)

| Service | Image | Port(s) | Purpose |
|---------|-------|---------|---------|
| `postgres` | postgres:15-alpine | 5432 | Primary relational DB |
| `postgres-migrate` | migrate/migrate:4 | — | Runs `/data-migrate` migrations on startup |
| `redis-node-1/2/3` | redis:7-alpine | 6379-6381 | 3-node Redis cluster |
| `redis-cluster-init` | redis:7-alpine | — | Initialises Redis cluster |
| `kafka-1/2/3` | cp-kafka:7.5.0 | 9092, 9094, 9095 | KRaft Kafka cluster (3 brokers) |
| `kafka-ui` | kafbat/kafka-ui | 8090 | Kafka web UI |
| `mailpit` | axllent/mailpit | 8025 (UI), 1025 (SMTP) | Email capture (dev) |
| `haraka` | custom | 2525 | SMTP relay → mailpit (CRAM-MD5 auth) |
| `clickhouse` | clickhouse-server:24.8 | 8123 (HTTP), 9000 (TCP) | Analytics DB |
