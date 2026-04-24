# eagle-ops

## Overview

**eagle-ops** is the back-office operations management service for the SemarPay payment gateway platform. It is the **source-of-truth for all configuration data** — merchants, providers, channels, stores, fees, and settlements — and exposes a REST API consumed by internal operational dashboards and merchant-facing portals.

It does **not** make outbound calls to other microservices. All other services pull their configuration from the shared PostgreSQL database or Redis cache that eagle-ops writes to.

---

## Directory Structure

```
eagle-ops/
├── config/                    # YAML config loader
├── apperrors/                 # Typed error definitions
├── constant/                  # App-wide constants
├── docs/                      # Swagger/API docs
├── dto/                       # Request/response DTOs (21 files)
├── entity/                    # DB entity models (29 files)
├── internal/
│   ├── clickhouse/
│   │   └── repository/        # Read-only analytics queries
│   ├── fiberapp/
│   │   ├── handler/           # Route handlers (21 handlers)
│   │   ├── middleware/        # JWT, RBAC, rate limiting
│   │   └── validator/         # Request validators
│   ├── postgres/
│   │   └── repository/        # CRUD repositories (46 files)
│   ├── redis/
│   │   ├── repository/        # Cache repositories
│   │   └── executor/          # Redis operation helpers
│   └── worker/                # Async worker pool
├── mail_templates/            # Email templates
├── messages/                  # Message string definitions
├── service/                   # Business logic (20+ services)
├── util/                      # Shared utilities
├── vendors/                   # OBS / SMTP clients
├── main.go
└── eagle-ops-config.yaml
```

---

## Service Architecture

```
                        ┌──────────────────────────────────┐
                        │            eagle-ops             │
                        │         (Fiber HTTP API)         │
                        │          Port: configurable      │
                        └──────┬────────────┬─────────────┘
                               │            │
                    ┌──────────▼──┐   ┌─────▼──────────┐
                    │ PostgreSQL  │   │ Redis Cluster   │
                    │  (write)    │   │   (cache sync)  │
                    └─────────────┘   └────────────────-┘
                               │
                    ┌──────────▼──┐
                    │ ClickHouse  │
                    │ (read-only) │
                    └─────────────┘

           ┌──────────────────────────────────────────┐
           │              Workers (async)              │
           │   SMTP mailer │ OBS file upload │ exports │
           └──────────────────────────────────────────┘
```

---

## Inbound API

Base path: `/api/v1`

### Auth (`/auth`)

| Method | Path | Description | Auth |
|--------|------|-------------|------|
| POST | `/auth/login` | User login (triggers OTP) | — |
| POST | `/auth/login/verify` | Verify OTP | — |
| POST | `/auth/refresh-token` | Refresh access token | — |
| POST | `/auth/logout` | Logout | JWT |
| GET  | `/auth/profile` | Get own profile | JWT |
| POST | `/auth/forgot-password/verify` | Verify reset OTP | — |
| POST | `/auth/activate-user/verify` | Verify activation OTP | — |
| POST | `/auth/activate-user` | Set initial password | — |

### Master Data (`/master`)

| Method | Path | Description | Roles |
|--------|------|-------------|-------|
| GET | `/master/banks` | List banks | — |
| GET | `/master/merchant-categories` | List merchant categories | — |
| GET/POST | `/master/channels` | List / create channels | SUPERADMIN |
| GET/PUT | `/master/channels/:id` | Get / update channel | SUPERADMIN |
| GET/POST | `/master/channel-groups` | List / create channel groups | SUPERADMIN |
| GET/PUT | `/master/channel-groups/:id` | Get / update channel group | SUPERADMIN |
| GET/POST/PUT/DELETE | `/master/holiday-dates` | Holiday date CRUD | SUPERADMIN |

### Operational (`/operational`) — JWT required

| Resource | Methods | Path Pattern |
|----------|---------|--------------|
| Users | CRUD, reset-password | `/operational/users[/:id]` |
| Merchant Users | CRUD, resend-activation | `/operational/merchant-users[/:id]` |
| Merchants | CRUD, sync-cache | `/operational/merchants[/:id]` |
| Merchant Fees | List, create | `/operational/merchants/:id/fees` |
| Merchant Callbacks | Get, update | `/operational/merchants/:id/callbacks[/:channelId]` |
| Merchant Settlements | List, create | `/operational/merchants/:id/settlements` |
| Disbursement Limits | Get, create | `/operational/merchants/:id/limit-disbursement` |
| Providers | CRUD | `/operational/providers[/:id]` |
| Provider Channels | CRUD, MDR | `/operational/provider-channels[/:id]` |
| Stores | CRUD, provider channels | `/operational/stores[/:storeId]` |
| Merchant API Keys | Generate, get | `/operational/merchants/:id/api-key` |
| Transactions | List, get, audit trail | `/operational/transactions[/:id]` |
| Settlements | List, export, stats | `/operational/settlements[/:id]` |
| Balances | List, stats, mutations | `/operational/balances[/:id]` |
| Disbursements | List, get | `/operational/disbursements[/:id]` |
| Dashboard | Statistics, settlement | `/operational/dashboard/...` |
| Sync | ClickHouse reconcile | `/operational/sync/clickhouse` |

### Merchant Portal (`/merchant`) — JWT + merchant context required

| Resource | Methods | Path Pattern |
|----------|---------|--------------|
| Stores | List, get | `/merchant/stores[/:storeId]` |
| Users | CRUD, reset-password | `/merchant/users[/:id]` |
| Fees | List | `/merchant/fees` |
| Transactions | List, export, audit | `/merchant/transactions[/:id]` |
| Settlements | List, stats | `/merchant/settlements[/:batchId]` |
| Balances | Stats, mutations, summaries | `/merchant/balances/...` |
| Dashboard | Statistics | `/merchant/dashboard/...` |

---

## Outbound API Calls

**None.** eagle-ops is a closed, write-only operations service. It does not call any other microservice via HTTP or gRPC.

### External vendor integrations only:

| Vendor | Protocol | Purpose |
|--------|----------|---------|
| SMTP (Haraka / Mailpit) | SMTP | User activation, password reset, OTP emails |
| Huawei Cloud OBS | HTTP | Export file uploads |

---

## Database I/O

### PostgreSQL — Write operations (source of truth)

| Table | Operations | Service Layer |
|-------|-----------|---------------|
| `user_profiles` | INSERT, UPDATE, DELETE | UserManagementService |
| `user_credentials` | INSERT, UPDATE, DELETE | UserManagementService, AuthManagementService |
| `merchants` | INSERT, UPDATE | MerchantService |
| `merchant_categories` | INSERT, UPDATE | MasterManagementService |
| `merchant_api_credentials` | INSERT, UPDATE | MerchantService |
| `merchant_channels` | INSERT, UPDATE | MerchantService |
| `merchant_banks` | INSERT, UPDATE | MerchantService |
| `merchant_settlement_configurations` | INSERT, UPDATE | SettlementManagementService |
| `merchant_disbursement_limit_rules` | INSERT, UPDATE | DisbursementManagementService |
| `merchant_fees` | INSERT, UPDATE | MerchantService |
| `stores` | INSERT, UPDATE | StoreManagementService |
| `store_qris_nmids` | INSERT, UPDATE | StoreManagementService |
| `store_transaction_limit_rules` | INSERT, UPDATE | StoreManagementService |
| `providers` | INSERT, UPDATE | ProviderManagementService |
| `provider_channels` | INSERT, UPDATE | ProviderChannelManagementService |
| `provider_fees` | INSERT, UPDATE | ProviderChannelManagementService |
| `provider_api_credentials` | INSERT, UPDATE | ProviderChannelManagementService |
| `provider_response_codes` | INSERT, UPDATE | ProviderManagementService |
| `provider_disbursement_traffic_balances` | INSERT, UPDATE | ProviderChannelManagementService |
| `master_channels` | INSERT, UPDATE | MasterManagementService |
| `channel_groups` | INSERT, UPDATE | MasterManagementService |
| `bank_infos` | INSERT, UPDATE | BankManagementService |
| `holiday_dates` | INSERT, UPDATE, DELETE | MasterManagementService |
| `qris_acquirers` | INSERT, UPDATE | ProviderChannelManagementService |
| `settlement_processes` | SELECT | SettlementManagementService |
| `merchant_balance_mutations` | SELECT | BalanceManagementService |
| `transactions` | SELECT | TransactionManagementService |
| `disbursement_limit_amounts` | INSERT, UPDATE | DisbursementManagementService |

### Redis Cluster — Cache sync (written by eagle-ops, read by payment-middleware)

| Key Pattern | Contents | Trigger |
|-------------|----------|---------|
| `merchant:{id}` | Merchant master data | POST /operational/merchants, sync-cache |
| `merchant_api_credentials:{clientKey}` | API credentials | POST /operational/merchants/:id/api-key |
| `provider_channel:{id}` | Provider channel config | PUT /operational/provider-channels/:id |
| `merchant_channel:{id}` | Merchant-channel config | Merchant sync |
| `merchant_disbursement_limit:{id}` | Disbursement limits | POST limit-disbursement |
| `bank_info:{code}` | Bank reference data | BankManagementService |
| `master_channel:{code}` | Channel definitions | Sync interval (30s) |

### ClickHouse — Read-only analytics

| Table | Operations | Used By |
|-------|-----------|---------|
| `transaction_rmt` | SELECT (FINAL) | TransactionManagementService, DashboardManagementService |
| `provider_api_log` | SELECT | Operational reporting |
| `merchant_balance_mutation` | SELECT | BalanceManagementService |

---

## Authentication & Authorization

- **Token type:** JWT (RS256)
- **Access token TTL:** 15 minutes
- **Refresh token TTL:** 72 hours
- **OTP max attempts:** 5, lockout 15 minutes
- **Login max attempts:** 5 within 2 minutes (Redis rate limiter)
- **Session storage:** Redis

### Role Hierarchy

```
SUPERADMIN
  └── ADMIN
        ├── FINANCE
        ├── ACCOUNT_MANAGER
        ├── TECHNICAL_SUPPORT
        ├── CUSTOMER_SERVICE
        └── DEVELOPMENT_TEAM

BUSINESS_OWNER (merchant)
  └── STAFF (merchant)
```

---

## Background Services

| Service | Interval | Purpose |
|---------|----------|---------|
| Master channel sync | 30 seconds | Refreshes Redis channel cache from PostgreSQL |
| ClickHouse reconciliation | 24 hours | Reconciles transaction data between PostgreSQL and ClickHouse |
| Worker pool | On demand | Async export generation, email delivery |

---

## Configuration

```yaml
postgresql:
  host / port / user / password / database
  max_connections: 100
  min_connections: 10

redis:
  cluster:
    hosts: [node1, node2, node3]
    password: ...

clickhouse:
  host / port / username / password / database
  secure: true

fiber:
  port: <HTTP port>
  api_key: <internal API key>

smtp:
  host / port / auth_method / username / password / sender

obs:
  bucket_name / endpoint / access_key / secret_key

jwt:
  secret_key / refresh_token_hash
  access_token_ttl: 15m
  refresh_token_ttl: 72h

sync:
  master_channel: 30s
  clickhouse_reconciliation: 24h
```
