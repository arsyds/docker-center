#!/usr/bin/env bash
#
# Seed local ClickHouse from local PostgreSQL — a "poor-man's CDC" for tables
# that aren't covered by the dual-write pipeline (everything except `transactions`).
#
# Behavior
# - For every table in `public.*` in PG (minus the skip list):
#   - If no matching CH table exists: CREATE it via `CREATE TABLE ... AS SELECT *
#     FROM postgresql(...)`, picking ReplacingMergeTree(updated_at)/MergeTree based
#     on whether `id` and `updated_at` columns exist.
#   - If a CH table already exists: leave its DDL alone, INSERT the intersection
#     of PG/CH columns. Re-runs are safe — ReplacingMergeTree dedups by id on
#     merge or via FINAL.
# - Reports row counts (PG, CH raw, CH FINAL) per table at the end.
#
# Limits
# - One-shot pull — not real-time. Re-run after manual data changes in PG.
# - DELETEs aren't propagated (we don't read tombstones).
# - PG NULLs land as NULLs in newly-created CH tables (Nullable types). For
#   pre-existing CH tables that use non-Nullable + DEFAULT sentinels (e.g.
#   `transactions`), a PG NULL in such a column will fail the INSERT — flagged
#   in the output as "(insert failed)" so you can fix per-table.
#
# Usage
#   ./scripts/seed-clickhouse-from-pg.sh
#
# Env overrides (all optional):
#   PG_CONTAINER, PG_USER, PG_PASS, PG_DB
#   CH_CONTAINER, CH_USER, CH_PASS, CH_DB
#   PG_HOST_FROM_CH    hostname:port that CH uses to reach PG (Docker network)

set -euo pipefail

PG_CONTAINER="${PG_CONTAINER:-local-postgres}"
PG_USER="${PG_USER:-postgres_user}"
PG_PASS="${PG_PASS:-postgres_pass}"
PG_DB="${PG_DB:-psql_local}"

CH_CONTAINER="${CH_CONTAINER:-local-clickhouse}"
CH_USER="${CH_USER:-clickhouse_user}"
CH_PASS="${CH_PASS:-clickhouse_pass}"
CH_DB="${CH_DB:-clickhouse_local}"

PG_HOST_FROM_CH="${PG_HOST_FROM_CH:-local-postgres:5432}"

# PG-only metadata. (Kafka / *_mv tables aren't in PG so they self-skip.)
SKIP=("schema_migrations")

pg_q() {
  docker exec -i "${PG_CONTAINER}" psql -U "${PG_USER}" -d "${PG_DB}" -At -c "$1"
}

ch_q() {
  docker exec -i "${CH_CONTAINER}" clickhouse-client \
    --user "${CH_USER}" --password "${CH_PASS}" -d "${CH_DB}" --query "$1"
}

is_skipped() {
  local t="$1"
  local s
  for s in "${SKIP[@]}"; do
    [[ "$s" == "$t" ]] && return 0
  done
  return 1
}

# Intersection of column names between PG and CH for a given table, comma-separated.
common_cols() {
  local tbl="$1"
  local pg_cols ch_cols
  pg_cols=$(pg_q "select column_name from information_schema.columns where table_schema='public' and table_name='${tbl}' order by ordinal_position")
  ch_cols=$(ch_q "select name from system.columns where database='${CH_DB}' and table='${tbl}'")
  comm -12 <(echo "$pg_cols" | sort) <(echo "$ch_cols" | sort) | paste -sd, -
}

if ! docker ps --format '{{.Names}}' | grep -qx "${PG_CONTAINER}"; then
  echo "!! container '${PG_CONTAINER}' not running"; exit 1
fi
if ! docker ps --format '{{.Names}}' | grep -qx "${CH_CONTAINER}"; then
  echo "!! container '${CH_CONTAINER}' not running"; exit 1
fi

TABLES=$(pg_q "select tablename from pg_tables where schemaname='public' order by 1")

printf '%-45s %10s %10s %10s  %s\n' "table" "pg_rows" "ch_rows" "ch_final" "action"
printf -- '----------------------------------------------------------------------------------------\n'

for tbl in $TABLES; do
  if is_skipped "$tbl"; then
    printf '%-45s %10s\n' "$tbl" "(skipped)"
    continue
  fi

  has_id=$(pg_q "select 1 from information_schema.columns where table_schema='public' and table_name='${tbl}' and column_name='id' limit 1")
  has_updated_at=$(pg_q "select 1 from information_schema.columns where table_schema='public' and table_name='${tbl}' and column_name='updated_at' limit 1")
  ch_exists=$(ch_q "exists table ${CH_DB}.${tbl}")

  pg_fn="postgresql('${PG_HOST_FROM_CH}', '${PG_DB}', '${tbl}', '${PG_USER}', '${PG_PASS}')"

  action=""
  if [[ "$ch_exists" != "1" ]]; then
    if [[ -n "$has_id" && -n "$has_updated_at" ]]; then
      ENGINE="ReplacingMergeTree(updated_at) ORDER BY id"
    elif [[ -n "$has_id" ]]; then
      ENGINE="MergeTree() ORDER BY id"
    else
      ENGINE="MergeTree() ORDER BY tuple()"
    fi
    if ch_q "CREATE TABLE ${CH_DB}.${tbl} ENGINE = ${ENGINE} AS SELECT * FROM ${pg_fn}" >/dev/null 2>&1; then
      action="created+seeded"
    else
      printf '%-45s %10s  %s\n' "$tbl" "-" "(create failed)"
      continue
    fi
  else
    cols=$(common_cols "$tbl")
    if [[ -z "$cols" ]]; then
      printf '%-45s %10s  %s\n' "$tbl" "-" "(no overlapping columns)"
      continue
    fi
    if ch_q "INSERT INTO ${CH_DB}.${tbl} (${cols}) SELECT ${cols} FROM ${pg_fn}" >/dev/null 2>&1; then
      action="inserted"
    else
      printf '%-45s %10s  %s\n' "$tbl" "-" "(insert failed — schema mismatch on cols: ${cols})"
      continue
    fi
  fi

  pg_count=$(pg_q "select count(*) from ${tbl}")
  ch_count=$(ch_q "select count(*) from ${CH_DB}.${tbl}")
  # FINAL only works on MergeTree family — Log/Memory/etc. error out.
  ch_engine=$(ch_q "select engine from system.tables where database='${CH_DB}' and name='${tbl}'")
  if [[ -n "$has_id" && "$ch_engine" == *MergeTree* ]]; then
    ch_final=$(ch_q "select count(*) from ${CH_DB}.${tbl} final" 2>/dev/null || echo "-")
  else
    ch_final="-"
  fi
  printf '%-45s %10s %10s %10s  %s\n' "$tbl" "$pg_count" "$ch_count" "$ch_final" "$action"
done

echo "done"
