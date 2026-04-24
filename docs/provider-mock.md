# provider-mock

## Overview

**provider-mock** is a lightweight, stateless mock service that simulates the **Nobu Bank payment provider API**. It is used exclusively in development and testing environments to allow **api-adapter** to exercise its full integration flow without connecting to the real Nobu Bank endpoints.

The service has no database, no Kafka integration, no Redis, and makes no outbound calls. All responses are generated in-memory with hardcoded or timestamp-derived values.

---

## Directory Structure

```
provider-mock/
├── main.go
├── config/
│   └── config.go              # YAML config loader (port only)
├── constant/
│   └── constant.go            # Service codes
├── dto/
│   ├── auth_dto.go
│   ├── error_dto.go
│   ├── inquiry_dto.go
│   ├── qr_dto.go
│   └── transfer_dto.go
├── internal/
│   └── fiberapp/
│       ├── fiberapp.go
│       └── handler/
│           ├── handler.go          # Route setup + 404 fallback
│           ├── auth_handler.go
│           ├── inquiry_handler.go
│           ├── qr_handler.go
│           └── transfer_handler.go
├── service/
│   ├── service.go
│   ├── auth_service.go
│   ├── inquiry_service.go
│   ├── qr_service.go
│   └── transfer_service.go
├── config.yaml                # Production config template
└── config.local.yaml          # Local dev config (port: 4000)
```

---

## Service Architecture

```
              ┌──────────────────────────────────┐
              │           provider-mock           │
              │       Fiber HTTP  :4000           │
              │  (stateless — no DB, no cache)    │
              └──────────────┬───────────────────┘
                             │
                     Inbound only
                             │
              ┌──────────────▼───────────────────┐
              │           api-adapter             │
              │  (calls provider-mock instead of  │
              │   real Nobu Bank in dev/test env) │
              └──────────────────────────────────┘
```

---

## Inbound API

All endpoints are **POST** with JSON body. Base paths mirror the real Nobu Bank API.

### Authentication

| Method | Path | Service Code | Description |
|--------|------|-------------|-------------|
| POST | `/v2.0/access-token/b2b` | 73 | Issue mock Bearer token (900s) |

**Response:**
```json
{
  "responseCode": "2007300",
  "responseMessage": "Request has been processed successfully",
  "accessToken": "<mock-jwt>",
  "tokenType": "Bearer",
  "expiresIn": "900"
}
```

### Account Inquiry

| Method | Path | Protocol | Service Code |
|--------|------|----------|-------------|
| POST | `/v1.0/account-inquiry-external` | RTOL | 16 |
| POST | `/v1.1/account-inquiry-external` | BI-FAST | 16 |

**RTOL response fields:** `beneficiaryAccountNo`, `beneficiaryAccountName`, `beneficiaryBankCode`, `currency`

**BI-FAST additional fields:** `beneficiaryAccountType` (CACC), `beneficiaryCityCode`, `residenceStatus`, `beneficiaryType`

### QR Code (QRIS MPM)

| Method | Path | Service Code | Description |
|--------|------|-------------|-------------|
| POST | `/v1.2/qr/qr-mpm-generate` | 47 | Generate mock QRIS QR code |
| POST | `/v1.2/qr/qr-mpm-query` | 51 | Query mock QRIS payment status |

**Generate response:** Returns a realistic QRIS string and hardcoded merchant name `"SOLUSI MULTI ARTHA UAT TESTING"`.

**Query response:** Always returns SUCCESS status, payer name `"GOPAY"`, and nett amount.

### Fund Transfers

| Method | Path | Protocol | Service Code |
|--------|------|----------|-------------|
| POST | `/v1.0/transfer-interbank` | RTOL | 18 |
| POST | `/v1.3/transfer-interbank` | BI-FAST | 18 |
| POST | `/v1.1/transfer/status` | BI-FAST status | 36 |

**Transfer responses:** Echo back request fields with confirmation. BI-FAST always returns final status `"00"` (Success).

### Fallback

All unmatched routes return:
```json
{
  "responseCode": "4010000",
  "responseMessage": "Unauthorized [Invalid Path]"
}
```

---

## Outbound API Calls

**None.** provider-mock is a terminal service — it does not call any other service.

---

## Kafka

**None.** No Kafka producer or consumer.

---

## Database I/O

**None.** Fully stateless. All responses are generated in-memory.

| Store | Usage |
|-------|-------|
| PostgreSQL | Not used |
| Redis | Not used |
| ClickHouse | Not used |

---

## Response Code Format

All responses use a standardized code format:

```
"200" + SERVICE_CODE + "00"
```

| Service Code | Operation |
|-------------|-----------|
| 73 | Access token |
| 47 | QR generate |
| 51 | QR query |
| 16 | Account inquiry |
| 18 | Transfer interbank |
| 36 | Transaction status inquiry |

Example: QRIS generate success → `"2004700"`

---

## Mock Data

| Field | Mock Value |
|-------|-----------|
| QR content | Real-format QRIS string (Indonesian standard) |
| Merchant name | `"SOLUSI MULTI ARTHA UAT TESTING"` |
| Payer name | `"GOPAY"` |
| Account type | `"CACC"` (Current Account) |
| Account status | `"01"` (Active) |
| Currency | `"IDR"` |
| Timestamps | `time.Now()` (Unix nano / milli) |
| BI-FAST final status | `"00"` (Success) |
| RTOL transfer status | Echo of request fields |

---

## How api-adapter Uses This Service

In local / development environments, the `endpoint_url` stored in Redis for a provider channel is pointed at `provider-mock` instead of the real Nobu Bank host. No code changes are needed in api-adapter — the swap is purely configuration.

```
Real environment:
  provider_channels.endpoint_url = https://api.nobubank.com

Dev/test environment:
  provider_channels.endpoint_url = http://provider-mock:4000
```

This allows end-to-end integration testing of the full flow:

```
payment-middleware → api-adapter → provider-mock
                  ← (mock QR / transfer response)
```

---

## Configuration

```yaml
# config.local.yaml
app_name: payment-middleware   # template artifact — actual service is provider-mock
app_version: 1.0.0
environment: development
fiber:
  port: 4000
```

The production config (`config.yaml`) uses `_FIBERPORT_` as a placeholder replaced at CI/CD build time.

---

## Deployment

- **Container port:** 8080 (Dockerfile EXPOSE)
- **Local port:** 4000 (config.local.yaml)
- **Registry:** Huawei SWR (`ap-southeast-4` region)
- **Namespace:** `konnco-eagle`
- **Image name:** `provider-mock-api`
- **Deploy method:** Docker Compose on remote host
- **Framework:** Fiber v3 (Go)
- **Dependencies:** Only Fiber, yaml, uuid, slog — no external DB or messaging dependencies
