# Troubleshooting Guide

Common failure modes, their root causes, and resolution steps for the SemarPay platform.

---

## Infrastructure

### Redis cluster won't form

**Symptom:** `redis-cluster-init` container exits with "ERR This instance has cluster support disabled" or nodes not joining.

**Cause:** Old `nodes.conf` from a previous run confuses the cluster state.

**Fix:**
```bash
docker-compose down -v          # wipe all volumes
docker-compose up redis-node-1 redis-node-2 redis-node-3
sleep 5
docker-compose up redis-cluster-init
```

---

### Redis: "MOVED" error in application

**Symptom:** `MOVED 3847 127.0.0.1:6380` logged by any service.

**Cause:** The application client is not in cluster mode. Redis is redirecting the key to the correct shard but the client doesn't follow the redirect.

**Fix:** Verify the service config uses `cluster.hosts` (the array form), not a single `host`/`port` key. All services that hit the payment-gateway Redis must use the cluster client.

---

### PostgreSQL: "schema_migrations" is dirty

**Symptom:** `migrate` CLI or `postgres-migrate` container exits with `Dirty database version N. Fix and force version`.

**Cause:** A previous migration run crashed mid-statement, leaving the database in a partial state.

**Fix:**
```bash
# 1. Inspect what actually applied:
psql postgres://postgres_user:postgres_pass@localhost:5432/psql_local \
  -c "SELECT * FROM schema_migrations;"

# 2. Manually fix the partial SQL if needed (drop table, revert column, etc.)

# 3. Force the version to the last clean one:
migrate -path data-migrate/ \
  -database "postgres://postgres_user:postgres_pass@localhost:5432/psql_local?sslmode=disable" \
  force <last-clean-version>

# 4. Re-run up:
migrate -path data-migrate/ \
  -database "..." up
```

---

### ClickHouse: HTTP 403 or "Authentication failed"

**Symptom:** `authentication failed` in ClickHouse logs or service startup failure.

**Cause:** Username/password mismatch, or `secure: true` on a local port-9000 (non-TLS) connection.

**Fix:**
- Local: `secure: false`, port `9000` (TCP native) or `8123` (HTTP).
- Remote ClickHouse Cloud: `secure: true`, port `8443`.
- Verify credentials match `CLICKHOUSE_USER` / `CLICKHOUSE_PASSWORD` in docker-compose.

---

### Kafka: Consumer group never receives messages

**Symptom:** `kafka-ui` shows topics with messages but consumer group lag grows without being consumed.

**Cause (common):** Consumer is configured for a different broker address. Kafka's internal `ADVERTISED_LISTENERS` differ between inter-container (`kafka-N:29092`) and host-facing (`localhost:9092/9094/9095`).

**Fix:** Services running inside Docker containers should use `kafka-1:29092,kafka-2:29092,kafka-3:29092`. Services running on the host machine (e.g., `go run main.go`) should use `localhost:9092,localhost:9094,localhost:9095`.

---

## eagle-ops

### Startup: "super admin init failed" / service crashes at startup

**Cause:** No `super.admin_email` or `super.admin_password` in config, or PostgreSQL migrations have not been run.

**Fix:** Ensure migrations are applied before starting eagle-ops. Check config has the `super:` section filled in.

---

### OTP email not delivered

**Symptom:** Login flow sends OTP but email never arrives.

**Cause:** SMTP config points to wrong host/port, or haraka container is not running.

**Fix:**
1. Check Mailpit at `http://localhost:8025` — if email is there, it arrived but SMTP relay from haraka works; the issue is downstream.
2. If not in Mailpit: verify eagle-ops SMTP config points to `localhost:1025` (mailpit direct) or `localhost:2525` (haraka → mailpit). Haraka requires `auth_method: CRAMMD5`, user `mailu`, password `mailu`.
3. Check mail template path: templates are loaded relative to working directory. If running from a different directory, adjust or use absolute paths.

---

### OTP verify returns 429 Too Many Requests

**Cause:** OTP max-attempt counter in Redis is not being cleared after correct entry, or you hit 5 wrong attempts.

**Fix:** Flush the rate-limit key manually:

```bash
redis-cli -c -h localhost -p 6379 -a redis_cluster_pass \
  DEL "user_otp_attempts:<email>"
```

Wait 15 minutes, or flush the lockout key as well.

---

### Master channel sync shows stale data after config update

**Cause:** The 30-second sync ticker has not fired since the update.

**Fix:** Trigger manual sync:
```bash
curl -X POST http://localhost:<eagle-ops-port>/api/v1/operational/sync/clickhouse
```
Or wait up to 30 seconds. For channel config specifically, force-sync via provider-channel PUT endpoint which writes to Redis immediately.

---

### ClickHouse reconciliation: "missing rows detected"

**Symptom:** `eagle-ops` logs `clickhouse reconciliation found N gap rows`.

**Cause:** payment-middleware's async ClickHouse writer exhausted retries during a ClickHouse outage, or the app crashed while retries were in-flight.

**Fix:** The reconciliation job handles this automatically — it fetches missing rows from PostgreSQL and re-inserts them into ClickHouse. You can trigger it manually:

```bash
curl -X POST http://localhost:<eagle-ops-port>/api/v1/operational/sync/clickhouse
```

---

## payment-middleware

### Merchant request returns 401 "Invalid Signature"

**Cause (most common):** Timestamp drift between client and server. payment-middleware enforces a ±30-second window.

**Fix:**
1. Verify client NTP is synchronized.
2. Confirm signature algorithm matches the endpoint:
   - `/v1.0/access-token/b2b` → RSA-SHA256 over `clientKey|timestamp`
   - Payload endpoints → HMAC-SHA512 over `METHOD|PATH|bearerToken|bodySHA256|timestamp`
3. Confirm the correct merchant public key is stored in Redis: `merchant_api_credentials:{clientKey}`.

---

### Merchant request returns 404 "Merchant not found" or 503

**Cause:** Redis cache miss for `merchant:{id}`, `merchant_api_credentials:{clientKey}`, or `master_channel:{code}`.

**Fix:**
1. Verify eagle-ops has written the merchant to Redis. Check:
```bash
redis-cli -c -h localhost -p 6379 -a redis_cluster_pass \
  GET "merchant_api_credentials:<clientKey>"
```
2. If empty, trigger merchant cache sync from eagle-ops:
```bash
curl -X POST http://localhost:<eagle-ops-port>/api/v1/operational/merchants/<id>/sync-cache
```

---

### Idempotency collision: 409 Conflict on valid request

**Cause:** `X-EXTERNAL-ID` has been reused. Idempotency keys are stored in Redis indefinitely (no TTL on merchant transaction references, though `api_idempotency` has 5 min TTL).

**Fix:** Use a globally unique `X-EXTERNAL-ID` per request. In testing, rotate IDs each run. If a test created a collision, flush the key:
```bash
redis-cli -c -h localhost -p 6379 -a redis_cluster_pass \
  DEL "api_idempotency:<merchantId>:<externalId>"
```

---

### QR payment notification never reaches merchant

**Symptom:** Transaction shows SUCCESS in DB but merchant callback URL was never called.

**Cause:** The callback goroutine fails silently after exhausting retries (`retry_callback_count` from `merchant_channels`).

**Fix:**
1. Search logs for `"merchant callback failed"` with the transaction reference.
2. Verify the merchant callback URL is reachable from payment-middleware's network.
3. Verify the merchant's callback URL is responding with a valid token on `POST /v1.0/access-token/b2b`.
4. Check `merchant_channels.retry_callback_count` and `retry_callback_interval` — defaults are configurable per merchant.

---

### ClickHouse dual-write "permanently failed after max retries"

**Symptom:** `ERROR` log: `clickhouse write permanently failed after max retries — manual reconciliation required`.

**Cause:** ClickHouse was unreachable for > 31 seconds during the 5-attempt retry window.

**Fix:**
1. Verify ClickHouse is reachable: `curl http://localhost:8123/ping`
2. Trigger manual reconciliation from eagle-ops: `POST /api/v1/operational/sync/clickhouse`
3. For sustained outages, reconciliation will catch all missed rows on next run.

---

### gRPC connection to api-adapter fails at startup

**Symptom:** `failed to create gRPC connection to api-adapter` in logs.

**Cause:** api-adapter is not yet running, or the `payment_middleware.host`/`port` in api-adapter's config doesn't point back to payment-middleware.

**Fix:**
- Start api-adapter first (or simultaneously). gRPC clients in payment-middleware use lazy connections — they reconnect automatically.
- Verify api-adapter config: `payment_middleware.host` = payment-middleware host, `port` = 50051.

---

## api-adapter

### Provisioning fails: "no provider_channels found"

**Cause:** PostgreSQL has no rows in `providers`/`provider_channels` tables, or migrations haven't run.

**Fix:**
1. Apply migrations: `docker-compose up postgres-migrate`
2. Use eagle-ops to create a provider and provider channel via its API.
3. After creating, api-adapter's provisioning loop will sync them to Redis on next cycle (immediate on startup).

---

### Nobu Bank API: RSA signature verification fails

**Symptom:** Nobu Bank returns 401 on token request.

**Cause:** Private key stored in `provider_api_credentials` is incorrect or in wrong format. The key must be RSA in PEM format.

**Fix:**
1. Check `provider_api_credentials.private_key` in PostgreSQL — it should start with `-----BEGIN RSA PRIVATE KEY-----` or `-----BEGIN PRIVATE KEY-----`.
2. Verify the public key registered with Nobu Bank matches the private key.
3. In local dev: verify `provider-mock` doesn't validate signatures (it accepts all tokens).

---

### BIFAST transaction stuck in PENDING

**Symptom:** BIFAST transaction in PostgreSQL has status PENDING after provider responded 200.

**Cause:** Normal — BIFAST transactions can return PENDING asynchronously. The background poller checks every 3 minutes.

**Fix:** Wait 3 minutes for the BIFAST pending processor to pick it up. If still stuck after 10 minutes:
1. Check Redis for the pending key: `redis-cli -c ... GET "bifast_pending_trx:<partnerReferenceNo>"`
2. Check api-adapter logs for BIFAST status check errors.
3. Manually check status with Nobu Bank if the key is missing from Redis (processor may have already consumed it).

---

### Replay attack detected on valid callback

**Symptom:** Nobu Bank callback returns 400 `replay attack detected` despite it being a new notification.

**Cause:** Redis replay key `replay:{externalId}:{clientIP}` is still alive (5-min TTL). This can happen if Nobu Bank retries the same notification within 5 minutes with the same `X-EXTERNAL-ID`.

**Fix:** This is intentional replay protection. Nobu Bank retries should use new `X-EXTERNAL-ID` values. If the upstream generates duplicate IDs, coordinate with the provider.

In local testing, flush the replay key:
```bash
redis-cli -c -h localhost -p 6379 -a redis_cluster_pass \
  DEL "replay:<externalId>:<clientIP>"
```

---

### api-adapter crashes immediately after start

**Symptom:** Container exits with `context deadline exceeded` or `connection refused`.

**Cause:** Missing or unreachable dependencies (Redis, PostgreSQL, Kafka, or payment-middleware gRPC).

**Fix:**
1. `docker-compose ps` — verify all infrastructure containers are healthy.
2. Check config: `redis.cluster.hosts`, `postgresql.host`, `kafka.brokers`, `payment_middleware.host`.
3. Provisioning service will retry on failure, but gRPC and Fiber servers will kill the process if they can't bind.

---

## mobile-banking

### Mobile payload decryption fails (400 Bad Request)

**Symptom:** All mobile requests return 400 with decryption error.

**Cause:** `PRIVATE_KEY_PATH` env var points to wrong file, or RSA key pair mismatch between client and server.

**Fix:**
1. Verify `PRIVATE_KEY_PATH` points to an existing RSA private key (PEM format).
2. Ensure the mobile client's public key matches the server's private key.
3. On first startup, the server auto-generates keys at `./keys/private.pem` and `./keys/public.pem` if not found.

---

### Core banking calls time out or fail

**Cause:** `CORE_BANKING_BASE_URL` or `CORE_BANKING_PROVIDER_ADDRESS` is unreachable. In local dev without real core banking, all banking operations (balance, transfer, mutation) will fail.

**Fix:**
- For local dev: stub the core banking responses or run a mock core banking service.
- Errors from core banking initialization are logged but don't crash startup — the service runs but banking endpoints will return errors.

---

### mobile-banking migrations diverge from payment-gateway

**Cause:** mobile-banking maintains its own migrations in `db/migrate/` (72 files) separate from `data-migrate/` (82 files). They target different schemas.

**Fix:** Never mix the two migration directories. Run mobile-banking migrations only against the mobile-banking database, and `data-migrate/` only against the payment gateway database.

---

## General Debugging Techniques

### Trace a transaction end-to-end

1. Find the `X-EXTERNAL-ID` or transaction reference from the merchant.
2. Search payment-middleware logs:
   ```bash
   docker logs <payment-middleware-container> | grep "<reference>"
   ```
3. Check PostgreSQL:
   ```bash
   psql postgres://... -c "SELECT status, updated_at FROM transactions WHERE reference = '<ref>';"
   ```
4. Check ClickHouse (use FINAL):
   ```bash
   curl "http://localhost:8123/" --data-binary \
     "SELECT status, updated_at FROM clickhouse_local.transactions FINAL WHERE reference = '<ref>'"
   ```
5. Check Kafka (via kafka-ui at `localhost:8090`) — search `merchant-api-log` and `provider-api-log` topics.

---

### Inspect Redis keys

```bash
# Connect to cluster
redis-cli -c -h localhost -p 6379 -a redis_cluster_pass

# Scan for keys (use SCAN not KEYS in production)
SCAN 0 MATCH "merchant:*" COUNT 100

# Get a specific key
GET "merchant_api_credentials:<clientKey>"

# Check TTL
TTL "api_idempotency:<id>"
```

---

### Reset the entire local environment

```bash
cd docker-center
docker-compose down -v
./setup-local.sh
docker-compose up postgres-migrate clickhouse-migrate
```

This wipes all data and starts fresh. Re-seed necessary data via eagle-ops API or directly in PostgreSQL.
