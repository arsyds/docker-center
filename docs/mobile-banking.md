# mobile-banking

## Overview

**mobile-banking** is a standalone digital banking backend. It is a separate project from the payment gateway platform and has no integration with eagle-ops, payment-middleware, api-adapter, or provider-mock.

It serves two client types:
- **Mobile app customers** — onboarding, KYC, authentication, banking operations (transfers, balance, history, account opening)
- **Web admin users** — customer registration management, content, pricing, transaction reporting, dashboard analytics

The service integrates with a **core banking system** (HTTP REST + gRPC), an **ISO8583 IBFT adapter** for national inter-bank transfers, an **eKYC provider (VIDA)** for identity verification, and **SMS OTP (Dart Media)** for OTP delivery.

---

## Directory Structure

```
mobile-banking/
├── main.go
├── config/
│   └── config.go                      # Environment-variable config
├── internal/
│   ├── fiberapp/
│   │   ├── fiberapp.go                # Fiber HTTP app bootstrap
│   │   ├── handler/                   # Route handlers (20+ files)
│   │   └── middleware/                # Auth, payload decryption, rate limit
│   ├── grpc/
│   │   ├── grpc.go                    # gRPC server bootstrap
│   │   ├── handler/                   # IBFTTransferInquiry, IBFTTransferReversal
│   │   └── proto/inbound/             # .proto definitions
│   ├── postgres/
│   │   └── repository/                # PostgreSQL repositories (26 files)
│   ├── redis/
│   │   ├── redis.go
│   │   └── cache/                     # Cache models (8+ types)
│   └── worker/                        # WorkerPool (async jobs)
├── service/                           # Business logic (17 services)
├── entity/                            # Domain entities
├── dto/                               # Request/response DTOs (30+ files)
├── vendors/
│   ├── core_banking_client.go         # HTTP REST client (core banking)
│   ├── ekyc-client.go                 # VIDA eKYC HTTP client
│   ├── sms-otp-client.go              # Dart Media SMS client
│   ├── mail_client.go                 # SMTP email client
│   ├── obs.go                         # Huawei OBS storage
│   ├── corebanking/                   # Core banking gRPC client
│   └── iso8583adapter/                # ISO8583 IBFT gRPC client
├── db/migrate/                        # 72 PostgreSQL migrations
├── apperrors/
├── constant/
└── util/
```

---

## Service Architecture

```
  Mobile App ──────────────────────────────────────────────►┐
  (RSA+AES-GCM encrypted payload, JWT RS256)                 │
                                                             │
  Web Admin ───────────────────────────────────────────────►│
  (HMAC-SHA256 signed, JWT)                                  │
                                                             ▼
                    ┌────────────────────────────────────────────┐
                    │             mobile-banking                  │
                    │   Fiber HTTP  :9000 (mobile + web)         │
                    │   gRPC        :50052 (IBFT inbound)         │
                    └──────────────────┬─────────────────────────┘
                                       │
        ┌──────────────────────────────┼──────────────────────────────┐
        │                              │                              │
┌───────▼────────┐   ┌─────────────────▼─────┐   ┌──────────────────▼──┐
│  PostgreSQL    │   │       Redis            │   │  External Services  │
│  (26 repos)    │   │  (sessions, tokens,    │   │                     │
│                │   │   OTP, device)         │   │  Core Banking (HTTP)│
│  user_profiles │   │                        │   │  Core Banking (gRPC)│
│  transactions  │   └────────────────────────┘   │  ISO8583 Adapter    │
│  bank_accounts │                                │  eKYC (VIDA)        │
│  onboardings   │                                │  SMS OTP            │
│  ...           │                                │  SMTP / OBS         │
└────────────────┘                                └─────────────────────┘
        ▲
        │  Inbound gRPC
┌───────┴───────────────┐
│  Other Banks (IBFT)   │
│  via ISO8583 network  │
└───────────────────────┘
```

---

## Inbound API

### REST — Fiber HTTP (Port 9000)

#### Mobile Routes — `/api/v1/m/*`
Middleware: `DecryptPayloadMiddleware` (RSA+AES-GCM) + `LanguageMiddleware`

##### Authentication (`/m/authenticate`)

| Method | Path | Description |
|--------|------|-------------|
| POST | `/authenticate` | Login with username/password → trigger OTP |
| POST | `/authenticate/otp` | Verify OTP → issue JWT |
| POST | `/refresh-token` | Refresh access token |
| POST | `/logout` | Invalidate session |
| POST | `/forgot-password` | Request reset (trigger OTP) |
| POST | `/forgot-password/otp` | Send OTP |
| POST | `/forgot-password/verify` | Verify OTP |
| POST | `/reset-password` | Set new password |

##### Onboarding (`/m/onboardings`)

| Method | Path | Description |
|--------|------|-------------|
| GET | `/tncs` | Get Terms & Conditions |
| POST | `/status` | Get onboarding progress |
| POST | `/step1` – `/step7` | Sequential onboarding steps (eKYC, data entry, document upload) |

##### Banking (`/m/banking`) — JWT required

| Method | Path | Description |
|--------|------|-------------|
| GET | `/accounts` | List customer accounts |
| GET | `/accounts/:id` | Balance inquiry |
| GET | `/transfer/accounts` | List saved transfer accounts |
| POST | `/transfer/accounts/intrabank` | Intrabank account inquiry |
| POST | `/transfer/accounts/interbank` | Interbank account inquiry |
| POST/DELETE | `/transfer/accounts/:id/pin` | Pin / unpin transfer account |
| PUT | `/transfer/accounts/:id` | Update saved account |
| DELETE | `/transfer/accounts/:id` | Delete saved account |
| POST | `/transfer/validate/intrabank` | Validate intrabank transfer (pre-confirm) |
| POST | `/transfer/validate/interbank` | Validate interbank transfer (pre-confirm) |
| POST | `/transfer/intrabank` | Execute intrabank transfer |
| POST | `/transfer/interbank` | Execute interbank transfer (IBFT) |
| GET | `/mutations` | Transaction history |
| POST | `/mutations/export` | Export mutations |
| GET | `/activities` | Activity log |
| GET | `/activities/:id` | Activity detail |
| GET | `/transfer/pricing/interbank` | Interbank fee pricing |

##### Customer Activation (`/m/activations`)

Multiple endpoints for activating a customer account post-onboarding.

##### Account Opening (`/m/account-opening`) — JWT required

| Method | Path | Description |
|--------|------|-------------|
| GET | `/products` | List available banking products |
| GET | `/products/:id/tnc` | Get product T&C |
| POST | `/step1` – `/step5` | Account opening workflow |

##### User Management (`/m/user-management`) — JWT required

| Method | Path | Description |
|--------|------|-------------|
| GET | `/profile-info` | Get profile |
| — | (credential management) | Change PIN, change password |

##### Master Data (`/m/master-management`)

| Method | Path | Description |
|--------|------|-------------|
| GET | `/bank-codes` | List bank codes |

---

#### Web Admin Routes — `/api/v1/w/*`
Middleware: `WebApiMiddleware` (HMAC-SHA256 `X-Sig` header validation)

| Resource | Methods | Purpose |
|----------|---------|---------|
| `/w/authenticate` | POST | Admin login |
| `/w/users` | GET | Admin user profile |
| `/w/content` | CRUD | Content management |
| `/w/banking-config` | CRUD | Banking configuration |
| `/w/transactions` | GET | Transaction reporting |
| `/w/registration-nasabah` | GET, GET /export, GET /:type/:id | Customer registration management |
| `/w/pricing-configuration` | CRUD | Interbank transfer pricing |
| `/w/master-management` | CRUD | Master data (bank codes, etc.) |
| `/w/dashboard` | GET | Analytics dashboard |

---

### gRPC Server (Port 50052) — Inbound IBFT

Receives inbound inter-bank requests from other banks via the national IBFT network.

| RPC Method | Caller | Purpose |
|-----------|--------|---------|
| `IBFTTransferInquiry` | ISO8583 adapter / IBFT network | Receive inquiry for inbound transfer |
| `IBFTTransferReversal` | ISO8583 adapter / IBFT network | Reverse a previous inbound transfer |

---

## Outbound API Calls

### HTTP REST

| Service | Env Var | Purpose |
|---------|---------|---------|
| Core Banking | `CORE_BANKING_BASE_URL` | Account inquiry, balance inquiry, in-house transfer, transaction history, product inquiry, create account |
| eKYC (VIDA) | `VENDOR_EKYC_BASE_URL` | Customer identity verification (KYC) |
| SMS OTP (Dart Media) | `VENDOR_SMS_OTP_URL` | Deliver OTP to customer phone |

#### Core Banking HTTP endpoints called

| Operation | Path | Trigger |
|-----------|------|---------|
| Get access token | `/v2.0/access-token/b2b` | Before each authenticated call |
| Account inquiry | `/account-inquiry` | Account lookup |
| Balance inquiry | `/balance-inquiry` | `/m/banking/accounts/:id` |
| In-house transfer | `/in-house-transfer` | `/m/banking/transfer/intrabank` |
| Transaction history | `/transaction-history` | `/m/banking/mutations` |
| Create saving account | `/create-account-saving` | Account opening |
| Create deposit account | `/create-account-deposit` | Account opening |
| Product inquiry saving | `/product-inquiry-saving` | List products (account opening) |
| Product inquiry deposit | `/product-inquiry-deposit` | List products (account opening) |

#### eKYC (VIDA)

| Step | Endpoint | Trigger |
|------|----------|---------|
| Get OAuth2 token | `VENDOR_EKYC_AUTH_URL` → `/auth/.../token` | Before KYC calls |
| KYC check | `VENDOR_EKYC_BASE_URL` → `/v3/services/kyc` | Onboarding identity verification step |

### gRPC Outbound

| Service | Env Var | RPC Methods | Trigger |
|---------|---------|-------------|---------|
| Core Banking Provider | `CORE_BANKING_PROVIDER_ADDRESS` | CustomerInquiry, CustomerAccountsInquiry, AccountInquiry, BalanceInquiry, InHouseTransfer, TransactionHistory, SavingProductInquiry, DepositProductInquiry, CreateSavingAccount, CreateDepositAccount | Banking operations (gRPC path) |
| ISO8583 Adapter (IBFT) | `ISO_ADAPTER_GRPC_ADDR` | `Inquiry` (account lookup), `Transaction` (IBFT transfer) | Interbank transfers via national network |

---

## Kafka

**No Kafka integration.** Async tasks (export generation, email delivery) are processed by an internal `WorkerPool` (goroutine pool).

---

## Database I/O

### PostgreSQL (26 repositories, 72 migrations)

#### User & Auth

| Table | Operations | Service |
|-------|-----------|---------|
| `user_profiles` | INSERT, SELECT, UPDATE | UserManagementService, OnboardingService |
| `user_credentials` | INSERT, SELECT, UPDATE | AuthManagementService |
| `user_devices` | INSERT, SELECT, UPDATE, DELETE | Device binding |
| `roles` | SELECT | RBAC |
| `login_activities` | INSERT, SELECT | AuthManagementService |

#### Onboarding & Activation

| Table | Operations | Service |
|-------|-----------|---------|
| `onboardings` | INSERT, SELECT, UPDATE | OnboardingService |
| `customer_activations` | INSERT, SELECT, UPDATE | CustomerActivationService |
| `admin_onboardings` | INSERT, SELECT, UPDATE | RegistrationNasabahService |

#### Banking

| Table | Operations | Service |
|-------|-----------|---------|
| `bank_accounts` | INSERT, SELECT, UPDATE | BankingService |
| `banking_products` | SELECT | AccountOpeningService |
| `banking_product_tncs` | SELECT | AccountOpeningService |
| `tncs` | SELECT | OnboardingService |
| `account_opening` | INSERT, SELECT, UPDATE | AccountOpeningService |
| `account_transactions` | INSERT, SELECT | TransactionService, BankingService |
| `favorite_account_transactions` | INSERT, SELECT, UPDATE, DELETE | BankingService (saved accounts) |
| `bank_codes` | SELECT | MasterManagementService |
| `currency_codes` | SELECT | BankingService |
| `transfer_bank_fees` | SELECT | PricingConfigurationService |
| `transfer_bank_operationals` | SELECT | BankingService |

#### Security & Fraud

| Table | Operations | Service |
|-------|-----------|---------|
| `fds_transaction_alerts` | INSERT, SELECT | FdsService |

#### Logging

| Table | Operations | Notes |
|-------|-----------|-------|
| `vendors.api_logs` | INSERT, SELECT | HTTP vendor call audit trail |
| `vendors.iso8583_logs` | INSERT, SELECT | ISO8583 adapter call logs |

### Redis (standalone, not cluster)

| Key Pattern | TTL | Contents |
|-------------|-----|----------|
| `mobile_access_token:{userId}` | `ACCESS_TOKEN_TTL` | JWT access token |
| `mobile_refresh_token:{userId}` | `REFRESH_TOKEN_TTL` | Refresh token |
| `web_access_token:{adminId}` | `ACCESS_TOKEN_TTL` | Web admin JWT |
| `web_refresh_token:{adminId}` | `REFRESH_TOKEN_TTL` | Web admin refresh |
| `mobile_forgot_password:{phone}` | Short | Reset code |
| `mobile_forgot_password_otp:{phone}` | Short | OTP for reset |
| `user_credential:{username}` | Session TTL | Cached credentials |
| `administrator:{id}` | Session TTL | Admin session data |
| `device_binding:{deviceId}` | — | Device binding state |
| `fds:{userId}` | — | Fraud detection signals |

---

## Authentication & Security

| Layer | Mechanism |
|-------|-----------|
| Mobile API | Payload encryption (RSA+AES-GCM), JWT RS256, device binding |
| Web Admin API | HMAC-SHA256 signature (`X-Sig` header), JWT |
| Core Banking HTTP | OAuth2 client credentials |
| Core Banking gRPC | Internal network (port-based) |
| ISO8583 Adapter | Optional TLS (`ISO_ADAPTER_TLS_ENABLED`) |
| eKYC (VIDA) | OAuth2 client credentials |
| SMS OTP | Username / password |
| Rate limiting | Auth, forgot-password, and transfer endpoints |

---

## Service Layer

| Service | Responsibilities |
|---------|----------------|
| `AuthManagementService` | Login, OTP, token issuance/refresh, logout |
| `OnboardingService` | 7-step mobile onboarding workflow |
| `CustomerActivationService` | Post-onboarding account activation |
| `UserManagementService` | Profile management, password change |
| `BankingService` | Accounts, balance, transfers, mutations, saved accounts |
| `TransactionService` | Transaction record management |
| `Iso8583Service` | IBFT inter-bank transfers via ISO8583 adapter |
| `InboundService` | Inbound IBFT requests from other banks |
| `AccountOpeningService` | New account opening workflow |
| `RegistrationNasabahService` | Admin: customer registration management |
| `MasterManagementService` | Bank codes, currencies |
| `PricingConfigurationService` | Transfer fee pricing |
| `DashboardManagementService` | Admin analytics |
| `FdsService` | Fraud detection signals |
| `ContentService` | Content management (web admin) |
| `MailService` | Email notifications (SMTP) |

---

## Configuration

```bash
# Database
DB=postgres://user:pass@host:5432/dbname

# JWT
REFRESH_TOKEN_HASH=...
ACCESS_TOKEN_TTL=15m
REFRESH_TOKEN_TTL=72h
WEB_API_KEY=...            # HMAC key for web API signature validation
PRIVATE_KEY_PATH=...       # RSA private key for mobile payload decryption

# Core Banking
CORE_BANKING_BASE_URL=http://...
CORE_BANKING_CLIENT_ID=...
CORE_BANKING_CLIENT_SECRET=...
CORE_BANKING_PROVIDER_ADDRESS=host:port

# ISO8583 Adapter (IBFT)
ISO_ADAPTER_GRPC_ADDR=host:port
ISO_ADAPTER_TLS_ENABLED=false
ISO_ADAPTER_TLS_CERT=...

# eKYC (VIDA)
VENDOR_EKYC_AUTH_URL=https://sso.vida.id/...
VENDOR_EKYC_BASE_URL=https://services.vida.id/main
VENDOR_EKYC_CLIENT_ID=...
VENDOR_EKYC_CLIENT_SECRET=...

# SMS OTP (Dart Media)
VENDOR_SMS_OTP_URL=https://rutesms-id.com/...
VENDOR_SMS_OTP_UID=...
VENDOR_SMS_OTP_PWD=...
VENDOR_SMS_OTP_SC=...

# Redis
REDIS_CONN=host:port
REDIS_PASSWORD=...

# Object Storage (Huawei OBS)
OBS_BUCKET_NAME=...
OBS_ENDPOINT=...
OBS_ACCESS_KEY=...
OBS_SECRET_KEY=...

# SMTP
SMTP_HOST=... SMTP_PORT=...
SMTP_USERNAME=... SMTP_PASSWORD=...
SMTP_SENDER=... SMTP_AUTH_METHOD=...

# Service ports
GRPC_PORT=50052        # gRPC inbound IBFT server
```
