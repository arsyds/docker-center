# api-adapter

## Overview

**api-adapter** (deployed as `api-adapter-nobu`) is the provider integration layer for the SemarPay platform. It translates internal gRPC calls from **payment-middleware** into signed HTTP requests to the **Nobu Bank API**, and relays provider callbacks back to payment-middleware via gRPC. It also handles credential provisioning (DB → Redis sync), periodic balance inquiry, and BIFAST pending transaction polling.

The adapter is **stateless at runtime** — all configuration is served from Redis (provisioned from PostgreSQL on startup).

---

## Directory Structure

```
api-adapter/
├── cmd/
│   └── main.go                        # Bootstrap & lifecycle supervisor
├── config/
│   └── config.go                      # YAML config loader
├── constant/
│   └── constant.go                    # Service codes, channel codes
├── entity/
│   └── entity.go                      # Core data models
├── apperrors/
├── utility/
├── internal/
│   ├── domain/
│   │   ├── transaction/               # QRIS, RTOL, BIFAST, Intrabank logic
│   │   ├── provisioning/              # DB → Redis credential sync
│   │   ├── inquiry/                   # Periodic balance inquiry
│   │   ├── bifast_transaction/        # BIFAST pending status checker
│   │   └── callback/                  # Provider callback receiver
│   ├── handler/
│   │   ├── rest/server/               # Fiber HTTP :8080 (auth + callback)
│   │   └── grpc/server/               # gRPC server :7979 (transactions)
│   ├── integration/provider/
│   │   ├── nobu.go                    # NobuService — HTTP client
│   │   ├── http_client.go             # Request signing, retries
│   │   ├── dto.go                     # Nobu request/response types
│   │   └── util.go                    # RSA / HMAC crypto helpers
│   ├── messaging/kafka/               # Async Kafka producer
│   ├── repository/
│   │   ├── postgres/                  # pgx connection + queries
│   │   └── redis/                     # Redis cluster + key operations
│   └── transaction-grpc/
│       └── grpcclient/                # payment-middleware gRPC client
├── api-adapter-nobu-config.yaml
└── wiki/                              # Architecture documentation
```

---

## Service Architecture

```
                  ┌───────────────────────────────────────────┐
                  │              api-adapter-nobu              │
                  │    gRPC :7979 (inbound from pay-mw)        │
                  │    REST :8080 (callback from Nobu Bank)     │
                  └──────┬────────────────────┬───────────────┘
                         │                    │
           ┌─────────────▼──┐      ┌──────────▼──────────────────┐
           │ PostgreSQL     │      │       Redis Cluster          │
           │ (read-only     │      │  (credentials, tokens,       │
           │  provisioning) │      │   channel configs, replay)   │
           └────────────────┘      └──────────────────────────────┘
                         │
           ┌─────────────▼──────────────────────────────────┐
           │              Nobu Bank HTTP API                  │
           │  Auth / QR / RTOL / BIFAST / Intrabank          │
           └────────────────────────────────────────────────-┘
                         │
           ┌─────────────▼──────────────────────────────────┐
           │           payment-middleware gRPC               │
           │    NotifyQrisTransaction (callback relay)       │
           └────────────────────────────────────────────────┘
                         │
           ┌─────────────▼──────────────────────────────────┐
           │                   Kafka                          │
           │  provider-api-log / provisioning-log /          │
           │  bifast-transaction-status-log /                │
           │  balance-inquiry-log                            │
           └────────────────────────────────────────────────┘
```

---

## Inbound API

### gRPC Server (Port 7979)

Implements `transaction.TransactionServiceServer` from `github.com/sma-payment-gateway/grpc-proto`.

| RPC Method | Caller | Purpose |
|-----------|--------|---------|
| `CreateQrisTransaction` | payment-middleware | Generate QRIS MPM code via Nobu |
| `QueryQrisTransaction` | payment-middleware | Query QRIS payment status from Nobu |
| `RTOLAccountInquiry` | payment-middleware | Account lookup via RTOL |
| `RTOLTransaction` | payment-middleware | Execute RTOL interbank transfer |
| `BIFASTAccountInquiry` | payment-middleware | Account lookup via BIFAST |
| `BIFASTTransaction` | payment-middleware | Execute BIFAST transfer |
| `IntrabankAccountInquiry` | payment-middleware | Internal account lookup |
| `IntraBankTransfer` | payment-middleware | Execute intrabank transfer |

All methods include a recovery interceptor for panic handling.

### REST Server (Port 8080) — Fiber

| Method | Path | Caller | Purpose |
|--------|------|--------|---------|
| POST | `/v2.0/access-token/b2b` | Nobu Bank | Issue auth token (RSA-PSS signature) |
| POST | `/v1.0/qr/qr-mpm-notify` | Nobu Bank | Receive QRIS payment notification |

**Middleware on callback endpoint:**
- CORS (`https://apidevportal.aspi-indonesia.or.id`)
- Replay protection: `replay:{X-EXTERNAL-ID}:{clientIP}` cached in Redis (5 min TTL)
- Timestamp freshness: ±5 minutes
- JWT authentication + HMAC-SHA512 signature verification
- Request body validation

---

## Outbound API Calls

### HTTP → Nobu Bank API

All requests include a Bearer token (auto-refreshed, cached in Redis), and are signed with RSA-PSS or HMAC-SHA256 depending on the endpoint.

| Operation | Method | Path | Signature |
|-----------|--------|------|-----------|
| Get access token | POST | `/v2.0/access-token/b2b/` | RSA-PSS SHA256 |
| Generate QRIS | POST | `/v1.2/qr/qr-mpm-generate/` | HMAC-SHA256 |
| Query QRIS | POST | `/v1.2/qr/qr-mpm-query/` | HMAC-SHA256 |
| RTOL account inquiry | POST | `/v1.0/account-inquiry-external/` | HMAC-SHA256 |
| RTOL transfer | POST | `/v1.0/transfer-interbank/` | HMAC-SHA256 |
| Balance inquiry | POST | `/v1.0/balance-inquiry/` | HMAC-SHA256 |
| BIFAST account inquiry | POST | `/v1.1/account-inquiry-external/` | HMAC-SHA256 |
| BIFAST transfer | POST | `/v1.3/transfer-interbank/` | HMAC-SHA256 |
| BIFAST status check | POST | `/v1.1/transfer/status/` | HMAC-SHA256 |
| Intrabank account inquiry | POST | `/v1.0/account-inquiry-internal/` | HMAC-SHA256 |
| Intrabank transfer | POST | `/v1.0/transfer-intrabank/` | HMAC-SHA256 |

- Endpoint URL resolved from Redis (`provider_channels:{id}`)
- Custom CA certificate: `nobubank.com.pem` bundled in image
- Retry with exponential backoff

### gRPC → payment-middleware

| RPC Method | Trigger | Purpose |
|-----------|---------|---------|
| `NotifyQrisTransaction` | POST /v1.0/qr/qr-mpm-notify (from Nobu) | Relay QRIS payment result to payment-middleware |
| `BIFASTTransactionStatus` | Background (every 3 min) | Check pending BIFAST status |

---

## Kafka

| Direction | Topic | Message | Trigger |
|-----------|-------|---------|---------|
| Produce | `provider-api-log` | `ProviderApiLog{Request, Response}` | Every Nobu Bank API call |
| Produce | `provisioning-log` | `AdapterProvisioningLog` | Every credential sync cycle |
| Produce | `bifast-transaction-status-log` | `BifastPendingTransactionLog` | BIFAST status check result |
| Produce | `balance-inquiry-log` | `InquiryLog` | Periodic balance check |

- Compression: Snappy
- Ack: WaitForLocal
- No consumer — audit/logging only

---

## Database I/O

### PostgreSQL — Read-only (provisioning only)

| Table | Operations | Purpose |
|-------|-----------|---------|
| `providers` | SELECT | Load provider by adapter_name |
| `provider_channels` | SELECT | Load channels for provider |
| `master_channels` | SELECT (JOIN) | Resolve channel code + transaction type |
| `provider_api_credentials` | SELECT (JOIN) | Load client key, secret, RSA keys |
| `provider_fees` | SELECT | Load fee config per channel |

All reads happen in the **Provisioning background service** on startup and periodically. No writes occur to PostgreSQL at runtime.

### Redis Cluster — Primary runtime store

| Key Pattern | TTL | Contents | Set By | Read By |
|-------------|-----|----------|--------|---------|
| `provider_adapters:{adapterName}` | none | `ProviderAdapter` JSON | Provisioning | gRPC handler enrichment |
| `provider_inquiry_channels:{adapterName}` | none | Inquiry channel config | Provisioning | Transfer handlers |
| `provider_channel_tokens:{providerChannelId}` | none | Bearer token + expiry | Auth handler | All Nobu API calls |
| `provider_channels:{providerChannelId}` | none | Channel config + endpoint URL | Provisioning | Transaction handlers |
| `provider_channel_credentials:{providerChannelId}` | none | RSA keys, HMAC secret | Provisioning | Request signing |
| `provider_callback_credentials:{clientKey}` | none | Callback auth config | Provisioning | Callback middleware |
| `provider_fee:{providerChannelId}` | none | Fee rules array | Provisioning | payment-middleware enrichment |
| `bifast_pending_trx:{partnerReferenceNo}` | none | BIFAST pending status request | BIFAST handler | BIFAST background poller |
| `replay:{externalId}:{clientIP}` | 5 min | Empty (existence check) | Callback middleware | Replay protection |

---

## Background Services

| Service | Interval | Purpose |
|---------|----------|---------|
| **Provisioning** | On-demand loop | Syncs PostgreSQL → Redis: providers, channels, credentials, fees |
| **Balance Inquiry** | Configurable | Periodic balance check via Nobu Bank API |
| **BIFAST Pending Processor** | 3 minutes | Polls all pending BIFAST entries in Redis, checks status with Nobu |
| **Kafka SuccessLog / ErrorLog** | Real-time | Logs Kafka produce results |

### Shutdown Order

```
1. Stop gRPC + Fiber servers (no new requests)
2. Cancel background service contexts
3. Close Kafka producer (flush pending messages)
4. Wait for goroutines (10s timeout)
5. Close DB connections (deferred)
```

---

## Full Transaction Flow

### gRPC QRIS Generate

```
payment-middleware → gRPC CreateQrisTransaction
  1. Load credentials from Redis (provider_channel_credentials)
  2. Check/refresh Bearer token from Redis (provider_channel_tokens)
     → If expired: POST /v2.0/access-token/b2b to Nobu, cache result
  3. POST /v1.2/qr/qr-mpm-generate/ to Nobu Bank (HMAC-SHA256 signed)
  4. Produce provider-api-log to Kafka (async)
  5. Return QR content to payment-middleware
```

### QRIS Callback (Provider → Adapter → Middleware)

```
Nobu Bank → POST /v1.0/qr/qr-mpm-notify (Fiber :8080)
  1. Replay protection check (Redis)
  2. Timestamp freshness check (±5 min)
  3. JWT + HMAC signature validation
  4. gRPC NotifyQrisTransaction → payment-middleware
  5. Return 200 OK to Nobu Bank
```

### Provisioning Cycle

```
Background service (on startup + loop):
  1. SELECT providers, provider_channels, master_channels, credentials, fees from PostgreSQL
  2. SET all Redis keys (provider_adapters, credentials, fees, channels)
  3. Produce provisioning-log to Kafka
  4. On error: DEL Redis keys, rollback
```

---

## Authentication & Security

| Layer | Mechanism |
|-------|-----------|
| Nobu Bank API calls | RSA-PSS SHA256 (token) + HMAC-SHA256 (transactions) |
| Inbound REST callbacks | JWT HS256 + RSA signature + replay detection + timestamp |
| gRPC inbound | No auth (internal network assumed) |
| Redis | Password-protected cluster |
| PostgreSQL | Username/password |
| Kafka | No SASL (internal broker) |
| TLS | Custom Nobu Bank CA cert bundled in Docker image |

---

## Configuration

```yaml
app_name: api-adapter-nobu
deployment_service: adapter-nobu-svc

redis:
  cluster:
    hosts: [node1, node2, node3]
    password: ...

postgresql:
  host / port / user / password / database
  max_connections: 100

grpc:
  host: 0.0.0.0
  port: 7979

fiber:
  port: 8080

kafka:
  brokers: [broker1, broker2, broker3]

payment_middleware:
  host: <host>
  port: <port>
```
