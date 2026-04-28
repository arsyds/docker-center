# SemarPay Platform — Engineer Onboarding Guide

This guide gets you from zero to a running local environment. Estimated time: **45–60 minutes** on first run.

---

## Prerequisites

| Tool | Version | Purpose |
|------|---------|---------|
| Go | ≥ 1.22 | All services are written in Go |
| Docker / OrbStack | Latest | Local infrastructure (Postgres, Redis, Kafka, ClickHouse) |
| `air` | Latest | Hot-reload for Go services (bundled in `docker-center/air/`) |
| `migrate` CLI | v4 | Running PostgreSQL migrations manually |
| `protoc` + Go gRPC plugins | Latest | Only if editing `.proto` files |

```bash
# Install air (hot-reload)
go install github.com/air-verse/air@latest

# Install migrate CLI
brew install golang-migrate
```

---

## Repositories

All services live as sibling directories under a single parent:

```
~/Project/
├── docker-center/        # Infrastructure + this docs dir
├── data-migrate/         # Shared PostgreSQL migrations (all services)
├── eagle-ops/            # Back-office operations API
├── payment-middleware/   # Core payment engine
├── api-adapter/          # Nobu Bank integration layer
├── provider-mock/        # Mock Nobu Bank (dev/test only)
└── mobile-banking/       # Digital banking app (separate project)
```

Clone each repo into the same parent directory. The `docker-compose.yml` in `docker-center/` mounts `../data-migrate` as its migrations volume, so sibling placement is required.

---

## Step 1 — Start Infrastructure

```bash
cd docker-center
chmod +x setup-local.sh
./setup-local.sh
```

This script:
1. Starts PostgreSQL, Kafka (3 brokers), Redis (3-node cluster), and ClickHouse
2. Waits for PostgreSQL health check
3. Initialises the Redis cluster (`CLUSTER CREATE` across the 3 nodes)

Verify everything is up:

```bash
docker-compose ps
# All containers should show "healthy" or "running"
```

After `setup-local.sh` completes, run migrations and optional services:

```bash
# Apply PostgreSQL migrations (runs automatically via postgres-migrate container)
docker-compose up postgres-migrate

# Apply ClickHouse schema
docker-compose up clickhouse-migrate

# Start Kafka UI and email capture (optional but useful)
docker-compose up kafka-ui mailpit haraka

# Start provider-mock (required if running api-adapter in dev mode)
docker-compose up provider-mock   # or run it locally — see below
```

### Local credentials (infrastructure)

| Service | Host | Port | User | Password | Database |
|---------|------|------|------|----------|----------|
| PostgreSQL | localhost | 5432 | `postgres_user` | `postgres_pass` | `psql_local` |
| Redis node 1 | localhost | 6379 | — | `redis_cluster_pass` | — |
| Redis node 2 | localhost | 6380 | — | `redis_cluster_pass` | — |
| Redis node 3 | localhost | 6381 | — | `redis_cluster_pass` | — |
| ClickHouse (TCP) | localhost | 9000 | `clickhouse_user` | `clickhouse_pass` | `clickhouse_local` |
| ClickHouse (HTTP) | localhost | 8123 | `clickhouse_user` | `clickhouse_pass` | `clickhouse_local` |
| Kafka broker 1 | localhost | 9092 | — | — | — |
| Kafka broker 2 | localhost | 9094 | — | — | — |
| Kafka broker 3 | localhost | 9095 | — | — | — |
| Kafka UI | localhost | 8090 | — | — | — |
| Mailpit UI | localhost | 8025 | — | — | — |
| Mailpit SMTP | localhost | 1025 | — | — | — |
| Haraka SMTP | localhost | 2525 | `mailu` | `mailu` | — |

---

## Step 2 — Configure Each Service

Every service reads from a `config.local.yaml` file at its root. Copy from the production template and fill in local values.

### eagle-ops

```bash
cd eagle-ops
cp eagle-ops-config.yaml eagle-ops-config.local.yaml
```

Key values to update in `eagle-ops-config.local.yaml`:

```yaml
postgresql:
  host: localhost
  port: 5432
  user: postgres_user
  password: postgres_pass
  database: psql_local

redis:
  cluster:
    hosts:
      - localhost:6379
      - localhost:6380
      - localhost:6381
    password: redis_cluster_pass

clickhouse:
  host: localhost
  port: 9000
  username: clickhouse_user
  password: clickhouse_pass
  database: clickhouse_local
  secure: false        # IMPORTANT: false for local TCP; true for remote ClickHouse Cloud

fiber:
  port: 3000

smtp:
  host: localhost
  port: 1025           # mailpit
  auth_method: NONE
  sender: noreply@semarpay.local

jwt:
  secret_key: <any-256-bit-hex-string>
  refresh_token_hash: <any-hex-string>
```

### payment-middleware

```bash
cd payment-middleware
cp payment-middleware-config.yaml config.local.yaml
```

Key values:

```yaml
postgresql:
  host: localhost
  port: 5432
  user: postgres_user
  password: postgres_pass
  database: psql_local

redis:
  cluster:
    hosts: [localhost:6379, localhost:6380, localhost:6381]
    password: redis_cluster_pass

kafka:
  bootstrap_servers: [localhost:9092, localhost:9094, localhost:9095]

clickhouse:
  hosts: [localhost:9000]
  database: clickhouse_local
  user: clickhouse_user
  password: clickhouse_pass
  secure: false

fiber:
  port: 8000

grpc:
  port: 50051
```

### api-adapter

```bash
cd api-adapter
cp api-adapter-nobu-config.yaml api-adapter-nobu-config.local.yaml
```

Key values:

```yaml
redis:
  cluster:
    hosts: [localhost:6379, localhost:6380, localhost:6381]
    password: redis_cluster_pass

postgresql:
  host: localhost
  port: 5432
  user: postgres_user
  password: postgres_pass
  database: psql_local

grpc:
  host: 0.0.0.0
  port: 7979

fiber:
  port: 8080

kafka:
  brokers: [localhost:9092, localhost:9094, localhost:9095]

payment_middleware:
  host: localhost
  port: 50051
```

> **Dev tip:** Point the `provider_channels.endpoint_url` in your PostgreSQL seed data at `http://localhost:4000` to route api-adapter through provider-mock instead of the real Nobu Bank.

### provider-mock

```bash
cd provider-mock
# config.local.yaml already set to port 4000 — no changes needed
```

### mobile-banking

mobile-banking uses environment variables instead of a YAML config. Create a `.env` file at the repo root:

```bash
DB=postgres://postgres_user:postgres_pass@localhost:5432/psql_local
REDIS_CONN=localhost:6379
REDIS_PASSWORD=redis_cluster_pass

PRIVATE_KEY_PATH=./keys/private.pem   # RSA private key for mobile payload decryption

ACCESS_TOKEN_TTL=15m
REFRESH_TOKEN_TTL=72h
WEB_API_KEY=<any-secret-string>
REFRESH_TOKEN_HASH=<any-hex-string>

# Leave these pointing to stubs for local dev if you don't have the real endpoints:
CORE_BANKING_BASE_URL=http://localhost:9999
CORE_BANKING_PROVIDER_ADDRESS=localhost:9998
ISO_ADAPTER_GRPC_ADDR=localhost:9997
ISO_ADAPTER_TLS_ENABLED=false

# SMTP → mailpit
SMTP_HOST=localhost
SMTP_PORT=1025
SMTP_AUTH_METHOD=NONE

GRPC_PORT=50052
```

---

## Step 3 — Run Services Locally

Each service uses `air` for hot-reload. Start from each service's root:

```bash
# Terminal 1
cd eagle-ops && air

# Terminal 2
cd payment-middleware && air

# Terminal 3
cd api-adapter && air

# Terminal 4 (only needed if api-adapter points to mock)
cd provider-mock && air

# Terminal 5 (standalone project)
cd mobile-banking && air
```

Alternatively, run without hot-reload:

```bash
go run main.go                    # most services
go run cmd/main.go                # api-adapter
```

---

## Step 4 — Verify the Stack

```bash
# PostgreSQL
psql postgres://postgres_user:postgres_pass@localhost:5432/psql_local -c '\dt'

# Redis cluster
redis-cli -c -h localhost -p 6379 -a redis_cluster_pass ping

# ClickHouse
curl -s "http://localhost:8123/ping"   # should return "Ok."

# Kafka (list topics)
docker exec kafka-1 kafka-topics --bootstrap-server localhost:9092 --list

# eagle-ops health (adapt port to your config)
curl http://localhost:3000/api/v1/master/banks

# payment-middleware health
curl -X POST http://localhost:8000/v1.0/access-token/b2b \
  -H "Content-Type: application/json" \
  -H "X-CLIENT-KEY: <key>" \
  -H "X-TIMESTAMP: $(date -u +%Y-%m-%dT%H:%M:%SZ)" \
  -H "X-SIGNATURE: <sig>" \
  -d '{}'
```

---

## Development Workflow

### Adding a new REST endpoint (payment-gateway services)

All four payment-gateway services follow the same layered pattern:

```
dto/ → entity/ → internal/postgres/repository/ → service/ → internal/fiberapp/handler/
```

1. Define request/response structs in `dto/`
2. Add or extend entity in `entity/`
3. Add repository method in `internal/postgres/repository/`
4. Add business logic in `service/`
5. Add handler in `internal/fiberapp/handler/`
6. Register route in the fiber app setup file

### Adding a PostgreSQL migration

All schema changes go in `data-migrate/`. Naming convention:

```
000083_<verb>_<what>.sql.up.sql
000083_<verb>_<what>.sql.down.sql
```

Apply locally:

```bash
docker-compose -f docker-center/docker-compose.yml run --rm postgres-migrate up
```

Or with the CLI directly:

```bash
migrate -path data-migrate/ \
  -database "postgres://postgres_user:postgres_pass@localhost:5432/psql_local?sslmode=disable" up
```

Roll back one step:

```bash
migrate -path data-migrate/ \
  -database "postgres://postgres_user:postgres_pass@localhost:5432/psql_local?sslmode=disable" down 1
```

### Adding a ClickHouse migration

ClickHouse DDL lives in `docker-center/migrations/clickhouse/`. Apply with:

```bash
docker-compose run --rm clickhouse-migrate
```

For local one-off changes, use the HTTP interface:

```bash
curl "http://localhost:8123/" --data-binary "CREATE TABLE ... ENGINE = ..."
```

### Editing gRPC proto definitions

Proto files live in the shared `github.com/sma-payment-gateway/grpc-proto` module. After updating:

```bash
protoc --go_out=. --go-grpc_out=. path/to/service.proto
```

Both `payment-middleware` and `api-adapter` import the generated types — update both services when proto changes.

---

## Mental Models for New Engineers

### Redis is the hot-path — PostgreSQL is the source of truth

payment-middleware and api-adapter read almost everything from Redis at request time. PostgreSQL is only consulted as a fallback or during the provisioning cycle. If a Redis key is stale or missing, the live request will fail. **eagle-ops writes to Redis after every configuration change.**

### Cache invalidation is explicit, not TTL-based

Most Redis keys have **no TTL**. They are invalidated and rewritten by eagle-ops on every PUT/POST. The exception: idempotency keys (`api_idempotency:*`) expire after 5 minutes, and replay keys (`replay:*`) after 5 minutes.

### ClickHouse is append-only — always use `FINAL`

The `transactions` table uses `ReplacingMergeTree`. Every state change appends a new row. Background merges deduplicate by `updated_at`. Until a merge runs, multiple rows for the same transaction exist. **Every SELECT query must include `FINAL`** or use the `transactions_current` view.

### api-adapter is stateless at runtime

All credentials and channel config are loaded from Redis on startup (provisioned from PostgreSQL). No database is hit during a transaction. If Redis is empty or stale, api-adapter cannot process any request. **Provisioning must complete before accepting traffic.**

### The middleware chain is the gatekeeper

payment-middleware processes every merchant request through 7 middleware stages before the handler runs. A failure at any stage (missing Redis key, invalid signature, idempotency collision) returns an error before any database write occurs.

---

## Audience-Specific Guidance

### Junior Engineers

- Start with `eagle-ops` — it has the most straightforward CRUD pattern and no gRPC.
- Read `dto/` and `service/` files side by side for any feature — they map 1:1.
- Never skip running `postgres-migrate` after pulling changes; unmigrated schema changes cause runtime panics.
- Add log statements freely — services use structured `slog` logging.

### Senior Engineers / Tech Leads

- See [Architecture Overview](./overview.md) for the full cross-service data flow.
- See [ClickHouse Dual-Write](../clickhouse-dual-write.md) for the append-only write strategy and reconciliation contract.
- Redis cluster (3-node, no replica) is a **single point of failure** for the hot path. Plan capacity and failover accordingly.
- The gRPC proto module is a shared dependency — coordinate version bumps across payment-middleware and api-adapter.
- Master channel sync in eagle-ops runs every 30 seconds — changes to channel config are not immediately reflected in payment-middleware.

### Contractors

| Service | Your Scope | Integration Boundary |
|---------|-----------|---------------------|
| `eagle-ops` | Back-office CRUD and configuration management | Writes PostgreSQL and Redis; no inbound calls from other services |
| `payment-middleware` | Merchant-facing payment processing | Reads Redis (written by eagle-ops); calls api-adapter gRPC; receives gRPC from api-adapter |
| `api-adapter` | Nobu Bank HTTP integration and QRIS callback | Reads Redis (self-provisioned from PostgreSQL); calls Nobu Bank HTTP; receives gRPC from payment-middleware |
| `provider-mock` | Dev/test stub | No integration — replace Nobu Bank endpoint URL in config only |
| `mobile-banking` | Digital banking app | Entirely separate — no shared DB or cache with payment gateway services |

**Do not** write to Redis keys owned by another service. Redis key ownership is documented in [overview.md](./overview.md#redis-cluster).

---

## Stopping and Cleaning Up

```bash
# Stop all containers (keep volumes)
docker-compose -f docker-center/docker-compose.yml down

# Stop and wipe all data
docker-compose -f docker-center/docker-compose.yml down -v
```

> **Warning:** `-v` deletes all PostgreSQL, Redis, Kafka, and ClickHouse data. Only use it when you want a completely fresh environment.
