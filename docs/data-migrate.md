# data-migrate — PostgreSQL Migration Repository

`data-migrate` is the **shared schema repository** for the SemarPay payment gateway platform. All PostgreSQL DDL changes for `eagle-ops`, `payment-middleware`, and `api-adapter` live here as versioned migration files.

---

## Overview

| Item | Value |
|------|-------|
| Migration tool | `golang-migrate/migrate` v4 |
| Database target | PostgreSQL 15 |
| Migration files | 82 pairs (164 files) as of migration `000082` |
| File format | `{seq}_{description}.sql.up.sql` / `.down.sql` |
| Applied by | `postgres-migrate` Docker container (on `docker-compose up`) |

> `mobile-banking` maintains its **own** migration directory (`db/migrate/`) and is **not** managed here.

---

## Directory Layout

```
data-migrate/
├── README.md
├── clickhouse/              # Reserved for ClickHouse DDL (managed by docker-center/migrations/clickhouse/)
├── 000001_create_user_profiles_table.sql.up.sql
├── 000001_create_user_profiles_table.sql.down.sql
├── ...
└── 000082_alter_transactions_add_payername_payerphonenumber.sql.up.sql
```

---

## Key Tables by Domain

### User & Auth

| Table | Managed Since | Purpose |
|-------|---------------|---------|
| `user_profiles` | 000001 | Back-office user accounts |
| `user_credentials` | 000002 | Hashed passwords, credential status |

### Merchants & Stores

| Table | Managed Since | Purpose |
|-------|---------------|---------|
| `merchants` | 000006 | Merchant master records |
| `merchant_api_credentials` | 000007 | Client key, public key for SNAP auth |
| `stores` | 000008 | Sub-units of a merchant |
| `merchant_banks` | 000009 | Merchant bank accounts for settlement |
| `merchant_channels` | 000011 | Merchant's active payment channels |
| `merchant_fees` | 000031 | Fee rules per merchant-channel |
| `merchant_categories` | 000027 | MCC categories |
| `merchant_settlement_configurations` | 000059 | Settlement schedule per merchant |
| `merchant_balance_mutations` | 000070 | Ledger mutations for settlement |
| `merchant_disbursement_limit_rules` | 000074 | Disbursement amount limits |
| `disbursement_amount_limit_table` | 000080 | Current disbursement usage |

### Payments & Transactions

| Table | Managed Since | Purpose |
|-------|---------------|---------|
| `transactions` | 000019 | Every payment event (QR, RTOL, BIFAST, intrabank) |
| `store_transaction_limit_rules` | 000030 | Per-store daily/weekly/monthly caps |
| `store_qris_nmids` | 000021 | QRIS NMID assignments per store |
| `qris_acquirers` | 000020 | Acquirer registry for QRIS |
| `settlement_processes` | 000071 | Settlement batch records |

### Providers & Channels

| Table | Managed Since | Purpose |
|-------|---------------|---------|
| `providers` | 000014 | Payment provider definitions |
| `provider_api_credentials` | 000015 | RSA keys, HMAC secrets per provider channel |
| `provider_channels` | 000016 | Provider channel config, endpoint URL, status |
| `provider_fees` | 000018 | MDR/fee per provider channel |
| `provider_response_codes` | 000017 | Provider response code mapping |
| `provider_disbursement_traffic_balances` | 000075 | Weighted load balancer config |

### Master Data & Reference

| Table | Managed Since | Purpose |
|-------|---------------|---------|
| `master_channels` | 000012 | Channel definitions (QRIS, RTOL, BIFAST, intrabank) |
| `channel_groups` | 000013 | Groupings of channels |
| `bank_infos` | 000010 | Bank directory (code, name, SWIFT) |
| `holiday_dates` | 000064 | Settlement holiday calendar |

---

## Running Migrations

### Automatic (docker-compose)

Migrations run automatically when you bring up the `postgres-migrate` container:

```bash
cd docker-center
docker-compose up postgres-migrate
```

The container applies all pending migrations and exits.

### Manual (CLI)

Install the `migrate` CLI:

```bash
brew install golang-migrate
# or
go install -tags 'postgres' github.com/golang-migrate/migrate/v4/cmd/migrate@latest
```

Apply all pending migrations:

```bash
migrate \
  -path data-migrate/ \
  -database "postgres://postgres_user:postgres_pass@localhost:5432/psql_local?sslmode=disable" \
  up
```

Roll back one migration:

```bash
migrate \
  -path data-migrate/ \
  -database "postgres://postgres_user:postgres_pass@localhost:5432/psql_local?sslmode=disable" \
  down 1
```

Check current version:

```bash
migrate \
  -path data-migrate/ \
  -database "postgres://postgres_user:postgres_pass@localhost:5432/psql_local?sslmode=disable" \
  version
```

Force a specific version (use only if migration state is dirty):

```bash
migrate \
  -path data-migrate/ \
  -database "postgres://postgres_user:postgres_pass@localhost:5432/psql_local?sslmode=disable" \
  force 82
```

---

## Adding a New Migration

1. Determine the next sequence number (current highest + 1).

2. Create both files in `data-migrate/`:

```
000083_<verb>_<what>.sql.up.sql
000083_<verb>_<what>.sql.down.sql
```

3. Write the forward change in `.up.sql` and the rollback in `.down.sql`. If rollback is destructive (data loss), leave `.down.sql` empty and add a comment.

4. Test locally:

```bash
# Apply
migrate -path data-migrate/ -database "..." up 1

# Verify with psql
psql postgres://postgres_user:postgres_pass@localhost:5432/psql_local -c '\d <tablename>'

# Roll back
migrate -path data-migrate/ -database "..." down 1
```

5. Include the migration file in the same PR as the code that depends on it. Deploy migrations **before** deploying the service.

---

## Schema Conventions

All tables follow these conventions:

| Convention | Detail |
|-----------|--------|
| Primary key | `id UUID DEFAULT gen_random_uuid()` |
| Timestamps | `created_at TIMESTAMPTZ`, `updated_at TIMESTAMPTZ` (timezone-aware) |
| Soft deletes | `deleted_at TIMESTAMPTZ`, `deleted_by UUID` (nullable) |
| Audit trail | `created_by UUID`, `updated_by UUID` |
| Status columns | `VARCHAR` with CHECK constraint (not ENUM — easier schema evolution) |

---

## Migration State Management

The `migrate` tool tracks applied migrations in the `schema_migrations` table:

```sql
SELECT * FROM schema_migrations;
-- version | dirty
-- 82      | false
```

If `dirty = true`, a previous migration failed mid-run. Fix the underlying issue, then:

```bash
# After manually fixing the partial state in the DB:
migrate -path data-migrate/ -database "..." force <version-that-failed>
```

---

## ClickHouse Migrations

ClickHouse DDL lives in `docker-center/migrations/clickhouse/` (not in this repository). It is applied by the `clickhouse-migrate` container. See [overview.md](./overview.md) for the table list.
