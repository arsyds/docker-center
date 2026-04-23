# ClickHouse Dual-Write

Technical reference for the real-time transaction log sync from the payment middleware to ClickHouse.

---

## Context

The FE transaction log reads from ClickHouse (CH). Previously CH was populated via **ClickPipes/PeerDB** — a WAL-based CDC pipeline from PostgreSQL (PG). Measured behaviour:

| Load profile | Sync lag |
|---|---|
| Normal | ~60s (fixed PeerDB poll interval) |
| High volume (>1M rows/day) | Up to 4h (PeerDB catch-up bound by throughput) |

PeerDB's pull interval is controlled by ClickHouse Cloud, not configurable from the application side. The lag was the root cause of FE showing stale transaction data.

---

## Solution

Replace CDC with **direct writes from the middleware to ClickHouse** on every transaction state change. ClickHouse is no longer dependent on WAL polling; the middleware is the single producer.

- Writes to PG remain synchronous (source of truth)
- Writes to CH fire in a goroutine — never block the merchant response
- A retry queue with exponential backoff handles transient CH failures
- Back-office reconciliation (separate codebase) covers sustained outages

---

## Architecture

```
Merchant request
      ↓
Payment middleware
      ↓
PostgreSQL INSERT/UPDATE        (synchronous, source of truth)
      ↓
ClickHouse INSERT               (async via Writer goroutine)
```

### Write points

Every transaction state change triggers one CH `INSERT`. The middleware writes the full row, not a delta.

| Event | Source | CH Write |
|---|---|---|
| QR generated | `internal/fiberapp/handler/qr_middleware.go` | `InsertTransaction` |
| Transfer success (RTOL) | `internal/fiberapp/handler/transfer_middleware.go` | `InsertTransaction` |
| Transfer success (BIFAST) | `internal/fiberapp/handler/transfer_middleware.go` | `InsertTransaction` |
| Account inquiry success | `internal/fiberapp/handler/account_inquiry_middleware.go` | `InsertTransaction` |
| QR payment status → SUCCESS | `internal/grpcserver/handler.go` | `InsertTransaction` (full row re-fetched from PG after update) |
| QR payment status → FAILED | `internal/grpcserver/handler.go` | `InsertTransaction` (full row re-fetched) |
| Merchant callback sent | `internal/grpcserver/handler.go` | `InsertTransaction` (full row re-fetched) |

For status changes in `grpcserver`, the PG update returns a partial record — the full row is fetched via `GetByReference` before the CH write so every column lands in CH.

---

## ClickHouse Table Design

### Engine

```sql
ENGINE = ReplacingMergeTree(updated_at)
PARTITION BY toYYYYMM(transaction_date)
ORDER BY (merchant_id, transaction_date, reference, merchant_reference, id)
```

- `updated_at` is the version column — on merge, the highest value wins per `ORDER BY` key
- Transactions are never deleted, so no delete-marker column is used
- Every state change is a new `INSERT`. **No `ALTER TABLE UPDATE`** mutations are used
- `ORDER BY` includes `reference` and `merchant_reference` for direct transaction lookup; `id` is kept last to guarantee row uniqueness for RMT dedup

Full DDL: `migrations/clickhouse/001_create_transactions_table.sql`

### Nullability policy

Per ClickHouse Cloud guideline, the table avoids `Nullable(T)` columns. Every column that may be absent in PG is declared non-nullable with a `DEFAULT` sentinel:

| PG type | CH type | Default sentinel |
|---|---|---|
| `*string` | `String` | `''` |
| `*float64` | `Float64` | `-1` |
| `*uuid.UUID` | `UUID` | `toUUID('00000000-0000-0000-0000-000000000000')` |
| `*time.Time` | `DateTime64(3, 'UTC')` | `toDateTime64(0, 3, 'UTC')` |

The middleware Insert dereferences nil pointers from the entity into these zero values before sending to CH (`derefString`, `derefFloat64`, `derefUUID`, `derefTime` helpers in `transaction_repository.go`).

### Why append-only instead of mutations

`ALTER TABLE UPDATE` in ClickHouse is:
- **Asynchronous** — FE reads stale rows until the mutation completes
- **Expensive** — rewrites entire data parts on disk
- **Sequential** — mutations queue one-at-a-time per table, causing backlog under load

This would reintroduce the same lag pattern as CDC. Append-only `INSERT` with `ReplacingMergeTree` is the native pattern.

### How ReplacingMergeTree Works

Every `INSERT` appends a new row. A single transaction going through its lifecycle leaves multiple rows on disk:

```
id     updated_at  status    callback
TRX-1  10:00:00    PENDING   null
TRX-1  10:00:45    SUCCESS   null
TRX-1  10:01:10    SUCCESS   "200 OK"
```

A background merge periodically reclaims duplicates by the `ORDER BY` key, keeping only the row with the highest `updated_at`. Merge timing is non-deterministic (can be seconds or minutes).

Because merges are not instant, **every read query must use `FINAL`** — this forces deduplication at query time in memory, regardless of merge state.

---

## Querying ClickHouse

### `FINAL` is mandatory

```sql
SELECT * FROM transactions FINAL
WHERE merchant_id = '...'
SETTINGS do_not_merge_across_partitions_select_final = 1
```

The `do_not_merge_across_partitions_select_final = 1` setting leverages the monthly partitioning for significantly faster `FINAL` scans on bounded windows.

Without `FINAL`, pre-merge duplicate rows of the same transaction can appear in results.

### Recommended: a view

To enforce `FINAL` consistently without relying on every caller:

```sql
CREATE VIEW transactions_current AS
SELECT * FROM transactions FINAL
SETTINGS do_not_merge_across_partitions_select_final = 1;
```

Read clients (back-office, FE) target `transactions_current`.

---

## Writer & Retry Behaviour

`internal/clickhouse/writer.go` wraps the repository with a non-blocking dispatcher.

```
middleware handler
      ↓
Writer.InsertTransaction(tx)   ← synchronous, returns immediately
      ↓
goroutine: tx snapshot → CH INSERT
      ↓ on failure
retry queue (in-memory, cap 1000)
      ↓
exponential backoff worker
```

### Retry schedule

| Attempt | Delay before retry |
|---|---|
| 1 | 1s |
| 2 | 2s |
| 3 | 4s |
| 4 | 8s |
| 5 | 16s |

### Failure paths

| Condition | Log level | Message |
|---|---|---|
| Single attempt fails | `WARN` | `clickhouse write failed, queuing for retry` |
| 5 retries exhausted | `ERROR` | `clickhouse write permanently failed after max retries — manual reconciliation required` |
| Retry queue full (1001st op) | `ERROR` | `clickhouse retry queue full, dropping operation — manual reconciliation required` |

Both `ERROR` cases require action from the back-office reconciliation process (next section).

### Server-side async insert

The CH connection uses:

```go
Settings: clickhouse.Settings{
    "async_insert":          1,
    "wait_for_async_insert": 1,
}
```

This lets the ClickHouse server **buffer single-row INSERTs into batches internally** without any application-side batching logic. It mitigates part-pressure under high insert volume. `wait_for_async_insert=1` makes the Writer wait for the flush confirmation, so a successful return means the data is visible to queries.

---

## Data Parity & Reconciliation

PG is the source of truth; CH is the read replica for FE/analytics.

### When parity can break

1. Sustained CH outage → 5-retry budget exhausted → rows dropped
2. App crash while retries are in-flight → in-memory queue lost
3. Retry queue overflow during extended outage

All three emit `ERROR`-level logs (see table above).

### Reconciliation (implemented in the back-office codebase)

The back-office service runs a periodic reconcile that:

1. Reads `max(updated_at)` from both PG and CH
2. If CH is behind, pulls the missing window from PG (`updated_at BETWEEN chMax AND pgMax`)
3. Bulk-inserts the rows into CH

Re-inserting is safe — `ReplacingMergeTree` keeps the highest `updated_at` per row, and the middleware writes the full 58-column row set, so no partial-overwrite risk when the reconcile writes the same columns.

Three entry points:

| Entry | Trigger |
|---|---|
| Boot | On back-office service start |
| Ticker | `24h` interval (configurable) |
| Manual HTTP | `POST /api/v1/operational/sync/clickhouse` (admin-only, empty body) |

### Known trade-off

The `max(updated_at)` heuristic **does not catch individual rows dropped mid-stream** (where `chMax == pgMax` because later rows succeeded). These cases surface via the `ERROR` logs above and are resolved with a direct manual re-sync.

---

## Configuration

```yaml
# config.yaml
clickhouse:
  hosts:
    - <host>:<port>
  database: <database>
  user: <user>
  password: <password>
  secure: false
  dial_timeout: 10        # seconds
  max_open_conns: 10
  max_idle_conns: 5
  conn_max_lifetime: 60   # minutes
```

---

## Startup Integration

Added to `main.go`:

```go
ch, err := clickhouse.NewClickHouse(config, logger)
if err != nil { /* fatal */ }
defer ch.Close()
ch.Writer.Start(ctx)    // boots retry worker goroutine
```

The Writer is passed into both the Fiber HTTP app and the gRPC server so every handler that writes a transaction can dual-write.

---

## Files Added

| File | Purpose |
|---|---|
| `internal/clickhouse/clickhouse.go` | Connection setup, exposes `Repository` + `Writer` |
| `internal/clickhouse/writer.go` | Non-blocking dispatcher with retry queue |
| `internal/clickhouse/repository/repository.go` | Repository container |
| `internal/clickhouse/repository/transaction_repository.go` | `Insert` implementation (59 columns) |
| `migrations/clickhouse/001_create_transactions_table.sql` | Table DDL |

## Files Modified

| File | Change |
|---|---|
| `config/config.go` | Added `ClickHouse` config struct |
| `config.yaml` | Added `clickhouse` block |
| `main.go` | Initialise CH, start Writer, inject into app |
| `internal/fiberapp/fiberapp.go` | Accept + pass `*clickhouse.Writer` |
| `internal/fiberapp/handler/handler.go` | Added `chWriter` field |
| `internal/fiberapp/handler/qr_middleware.go` | Dual-write on QR insert |
| `internal/fiberapp/handler/transfer_middleware.go` | Dual-write on RTOL + BIFAST |
| `internal/fiberapp/handler/account_inquiry_middleware.go` | Dual-write on inquiry |
| `internal/grpcserver/server.go` | Accept + pass `*clickhouse.Writer` |
| `internal/grpcserver/handler.go` | Dual-write on status + callback updates |

---

## Operational Notes

### Monitoring signals

Watch these `ERROR` log messages — both indicate a parity gap that reconciliation must close:

- `clickhouse write permanently failed after max retries`
- `clickhouse retry queue full, dropping operation`

### Rollout

No PG schema change. CH DDL must be applied before deploying the middleware; the middleware will fail to INSERT otherwise.

The dual-write is additive: disabling it requires removing the `h.chWriter.InsertTransaction(...)` call sites. The existing CDC pipeline can remain in place during rollout as a fallback safety net, then be retired once parity is verified.

### Back-office contract

Back-office clients of the CH `transactions` table must:

1. Use `FINAL` on every read (or a view that wraps `FINAL`)
2. Implement the reconcile function covering boot / ticker / manual entry points
3. Match the full 58-column write set on reconcile re-insert to avoid partial-overwrite