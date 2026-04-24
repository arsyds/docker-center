# payment-middleware

## Overview

**payment-middleware** is the core payment-processing engine of the SemarPay platform. It exposes a REST API (SNAP-compliant) for merchants to initiate payments, and a gRPC server for receiving transaction status notifications from **api-adapter**. It orchestrates the full transaction lifecycle: authentication → validation → enrichment → provider routing → state management → merchant callback.

---

## Directory Structure

```
payment-middleware/
├── config/                    # YAML config loader
├── constant/                  # App-wide constants
├── dto/                       # Request/response DTOs (28+ files)
├── entity/                    # Domain entities (Transaction, Merchant, Store…)
├── internal/
│   ├── clickhouse/            # ClickHouse dual-write
│   │   └── writer.go          # Async batch writer
│   ├── fiberapp/              # HTTP REST server (Fiber v2)
│   │   └── handler/           # Handler + middleware per endpoint
│   ├── grpcserver/            # gRPC server (NotifyQrisTransaction)
│   ├── grpcclient/            # gRPC client pool → api-adapter
│   ├── kafka/                 # Async Kafka producer
│   ├── postgres/
│   │   └── repository/        # PostgreSQL repositories
│   └── redis/
│       └── repository/        # Redis cluster cache (22 repositories)
├── migrations/                # ClickHouse schema (SQL)
├── service/                   # Business logic
│   ├── auth_service.go
│   ├── qr_service.go
│   ├── transfer_service.go
│   └── account_inquiry_service.go
├── util/                      # balancer_util, random generator
└── main.go
```

---

## Service Architecture

```
                 ┌─────────────────────────────────────────┐
  Merchant ─────►│     payment-middleware                   │
  (HTTP REST)    │  Fiber :8000   gRPC :50051               │
                 └──────┬──────────────────┬───────────────┘
                        │                  │
          ┌─────────────▼────┐   ┌─────────▼─────────────────┐
          │   PostgreSQL     │   │    Redis Cluster            │
          │  (transactions,  │   │  (credentials, channels,   │
          │   settlements,   │   │   limits, idempotency,     │
          │   mutations)     │   │   session tokens)          │
          └──────────────────┘   └────────────────────────────┘
                        │
          ┌─────────────▼────────────────────────────┐
          │             api-adapter                   │
          │   gRPC client  (dynamic endpoint pool)    │
          └──────────────────────────────────────────┘
                        │
          ┌─────────────▼────┐   ┌────────────────────────┐
          │   ClickHouse     │   │       Kafka             │
          │ (transaction_rmt │   │ (merchant-api-log)      │
          │  dual-write)     │   │                         │
          └──────────────────┘   └────────────────────────┘
                        │
          ┌─────────────▼────────────────────────────┐
          │     Merchant Callback (HTTP POST)         │
          │   GET /v1.0/access-token/b2b              │
          │   POST /v1.0/qr/qr-mpm-notify             │
          └──────────────────────────────────────────┘
```

---

## Inbound API

### REST — Fiber HTTP (Port 8000)

All endpoints follow SNAP (Standard Nasional API Pembayaran) protocol.

#### Authentication

| Method | Path | Description | Required Headers |
|--------|------|-------------|-----------------|
| POST | `/v1.0/access-token/b2b` | Issue merchant JWT (900s TTL) | X-CLIENT-KEY, X-SIGNATURE, X-TIMESTAMP |

#### QR Code (QRIS MPM)

| Method | Path | Description |
|--------|------|-------------|
| POST | `/v1.0/qr/qr-mpm-generate` | Generate QRIS QR code |
| POST | `/v1.0/qr/qr-mpm-query` | Query QRIS payment status |

#### Interbank Transfers

| Method | Path | Description |
|--------|------|-------------|
| POST | `/v1.0/transfer-interbank/rtol` | RTOL (Real-Time Online) transfer |
| POST | `/v1.0/transfer-interbank/bifast` | BI-FAST transfer |
| POST | `/v1.0/transfer-intrabank` | Intrabank transfer |

#### Account Inquiry

| Method | Path | Description |
|--------|------|-------------|
| POST | `/v1.0/account-inquiry-external` | External account lookup (RTOL) |
| POST | `/v1.0/account-inquiry-internal` | Internal account lookup (intrabank) |

#### Middleware Chain (per endpoint)

```
Log → Channel → Headers → Payload → Enrichment → Idempotency → Handler
```

| Stage | Purpose |
|-------|---------|
| Log | Capture raw request headers and body |
| Channel | Load master channel from Redis, attach transaction reference |
| Headers | Validate Content-Type, extract X-EXTERNAL-ID, X-TIMESTAMP |
| Payload | Parse and validate request body schema |
| Enrichment | Load merchant / channel / provider / fee config; resolve adapter endpoint; calculate fees |
| Idempotency | Check Redis for duplicate request (X-EXTERNAL-ID deduplication) |
| Handler | Execute business logic, call api-adapter gRPC |

### gRPC Server (Port 50051)

| RPC Method | Caller | Purpose |
|-----------|--------|---------|
| `NotifyQrisTransaction` | api-adapter | Receive QRIS payment completion from provider |

---

## Outbound API Calls

### gRPC → api-adapter (dynamic endpoint per provider)

The adapter endpoint URL is resolved per-request during the Enrichment middleware stage from Redis (`provider_channel:{id}` cache).

| RPC Method | Trigger | Data Sent |
|-----------|---------|-----------|
| `CreateQrisTransaction` | QR generate | ProviderChannelId, AdapterName, TransactionReference, Channel, Amount, Currency, ValidityPeriod |
| `QueryQrisTransaction` | QR query | ProviderChannelId, AdapterName, TransactionReference, AccountNo |
| `RTOLTransaction` | RTOL transfer | Amount, BeneficiaryAccountNo, BeneficiaryBankCode, CustomerReference, Remark |
| `BIFASTTransaction` | BI-FAST transfer | Amount, BeneficiaryAccountNo, BeneficiaryBankCode, CustomerReference |
| `IntraBankTransfer` | Intrabank transfer | Amount, BeneficiaryAccountNo, BeneficiaryAccountName |
| `RTOLAccountInquiry` | External inquiry | BeneficiaryBankCode, BeneficiaryAccountNo |
| `IntrabankAccountInquiry` | Internal inquiry | BeneficiaryAccountNo |

Traffic balancing across multiple adapter endpoints uses a weight-based balancer loaded from `provider_disbursement_traffic_balances` in PostgreSQL.

### HTTP → Merchant Callback (async, after provider notification)

| Step | Method | Path | Auth |
|------|--------|------|------|
| 1. Get token | POST | `{merchantCallbackUrl}/v1.0/access-token/b2b` | HMAC-SHA512 signature |
| 2. Send result | POST | `{merchantCallbackUrl}/v1.0/qr/qr-mpm-notify` | Bearer token + X-SIGNATURE |

- Retry: up to 5 attempts with exponential backoff
- Interval: configurable (default 3 seconds)
- Signature: HMAC-SHA512 with merchant callback secret key

---

## Kafka

| Direction | Topic | Message | When |
|-----------|-------|---------|------|
| Produce | `merchant-api-log` | `MerchantApiLogMessage` | After every API response |

- Compression: Snappy
- Ack: WaitForLocal
- Partitioning: by transaction reference (key)

---

## Database I/O

### PostgreSQL

| Table | Operations | When |
|-------|-----------|------|
| `transactions` | INSERT | QR generate, transfer execute — initial PENDING record |
| `transactions` | UPDATE status, provider_response | On notification from api-adapter |
| `transactions` | UPDATE callback fields | After merchant callback sent |
| `transactions` | SELECT | QR query, transfer status |
| `merchants` | SELECT | Enrichment middleware fallback |
| `stores` | SELECT | Enrichment middleware fallback |
| `merchant_banks` | SELECT | Transfer enrichment |
| `bank_infos` | SELECT | Transfer enrichment |
| `merchant_balance_mutations` | INSERT | After settlement updates |
| `provider_disbursement_traffic_balances` | SELECT | Balancer weight loading |

### Redis Cluster (22 cache repositories)

All entries are stored as JSON. Most have no TTL (invalidated explicitly).

| Key Pattern | Contents | Read By | Written By |
|-------------|----------|---------|------------|
| `merchant_active_token:{clientKey}` | JWT token + expiry | Auth handler | Auth handler |
| `merchant_api_credentials:{clientKey}` | Client key, secret, public key | Auth middleware | eagle-ops |
| `merchant_channel:{id}` | Channel config, callback URL | Enrichment | eagle-ops |
| `merchant_channel_fee:{id}` | Fee type, fixed, percentage | Enrichment | eagle-ops |
| `merchant:{id}` | Merchant status, code | Enrichment | eagle-ops |
| `master_channel:{code}` | Channel definition | Enrichment | eagle-ops (30s sync) |
| `merchant_transaction_reference:{ref}` | Idempotency guard | Idempotency middleware | Enrichment |
| `provider_transaction_reference:{ref}` | Provider-side reference map | Notification handler | QR generate handler |
| `provider_channel_credentials:{id}` | Provider API credentials | api-adapter provisioning | api-adapter |
| `provider_inquiry_channel:{adapterName}` | Inquiry channel config | Transfer handlers | api-adapter |
| `merchant_bank_account:{id}` | Bank account details | Transfer enrichment | eagle-ops |
| `merchant_store:{storeId}` | Store → merchant mapping | Enrichment | eagle-ops |
| `store_limit_amount_rule:{storeId}` | Limit rules (daily/weekly/monthly) | Limit middleware | eagle-ops |
| `store_limit_balance:{storeId}:{cycle}` | Current spend | Limit check | Transaction complete |
| `merchant_disbursement_limit_rule:{id}` | Disbursement limits | Disbursement enrichment | eagle-ops |
| `merchant_disbursement_limit_balance:{id}` | Current disbursement total | Disbursement check | After transfer |
| `api_idempotency:{externalId}` | Duplicate request guard (TTL: 5 min) | Idempotency middleware | Idempotency middleware |
| `bank_info:{code}` | Bank name, SWIFT | Transfer enrichment | eagle-ops |
| `store_qris_provider:{storeId}` | QRIS provider assignment | QR enrichment | eagle-ops |

### ClickHouse (dual-write)

| Table | Operations | When |
|-------|-----------|------|
| `transaction_rmt` | INSERT | On every transaction state change (PENDING, SUCCESS, FAILED) |

- Async batch writer with retry queue
- ReplacingMergeTree — deduplication by `updated_at` version
- Partitioned by month (`toYYYYMM(transaction_date)`)
- Queries must use `FINAL` for correct read

---

## Full Transaction Flow

### QR Generate

```
Merchant → POST /v1.0/qr/qr-mpm-generate
  1. Log middleware captures raw request
  2. Channel middleware: load master_channel from Redis, generate reference
  3. Headers middleware: validate Content-Type, extract X-EXTERNAL-ID
  4. Payload middleware: parse & validate body
  5. Enrichment middleware:
       - Load merchant_api_credentials from Redis (verify clientKey)
       - Load merchant from Redis
       - Load store from Redis
       - Load merchant_channel from Redis (check callback URL, fee)
       - Resolve provider_channel → adapter endpoint
       - Calculate fee (FIXED / PERCENTAGE / MIXED)
  6. Idempotency middleware: check Redis for duplicate X-EXTERNAL-ID
  7. QrHandler:
       a. gRPC CreateQrisTransaction → api-adapter
       b. INSERT transaction (PENDING) → PostgreSQL
       c. INSERT transaction_rmt → ClickHouse (async)
       d. Cache provider reference → Redis
  8. Return QR content to merchant
```

### QR Payment (Provider Notification)

```
Provider → api-adapter → gRPC NotifyQrisTransaction → payment-middleware
  1. Update transaction status (SUCCESS/FAILED) → PostgreSQL
  2. Update store_limit_balance → Redis (decrement on FAILED)
  3. INSERT transaction_rmt (final state) → ClickHouse (async)
  4. HTTP POST merchant callback:
       a. GET /v1.0/access-token/b2b (merchant) → store token in Redis
       b. POST /v1.0/qr/qr-mpm-notify (merchant) with result
  5. Produce merchant-api-log → Kafka
```

---

## Configuration

```yaml
postgresql:
  host / port / user / password / database
  max_connections: 100

redis:
  cluster:
    hosts: [node1, node2, node3]
    password: ...

kafka:
  bootstrap_servers: [broker1, broker2, broker3]

clickhouse:
  hosts: [...]
  database / user / password
  secure: false

fiber:
  port: 8000

grpc:
  port: 50051
```
