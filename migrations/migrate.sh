#!/usr/bin/env bash
#
# Apply all ClickHouse migrations to the local database in the correct order.
#
# Runs migrations via `docker exec` against a ClickHouse container.
#
# Order rules:
#   1. Master tables before their paired Kafka engine tables
#   2. Master + Kafka tables before their materialized views (MV references both)
#
# Usage:
#   ./migrate.sh                                                # use env defaults
#   CH_CONTAINER=clickhouse ./migrate.sh                        # override container name
#
# Environment variables (all optional):
#   CH_CONTAINER   container name or id (default: clickhouse)
#   CH_USER        clickhouse user (default: clickhouse_user)
#   CH_PASSWORD    clickhouse password (default: clickhouse_pass)
#   CH_DATABASE    target database (default: clickhouse_local)

set -euo pipefail

CH_CONTAINER="${CH_CONTAINER:-local-clickhouse}"
CH_USER="${CH_USER:-clickhouse_user}"
CH_PASSWORD="${CH_PASSWORD:-clickhouse_pass}"
CH_DATABASE="${CH_DATABASE:-clickhouse_local}"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Verify the container is running before touching anything.
if ! docker ps --format '{{.Names}}' | grep -q "^${CH_CONTAINER}$"; then
  echo "!! container '${CH_CONTAINER}' not running"
  echo "   either start it or set CH_CONTAINER=<name> to the correct container"
  exit 1
fi

run_query() {
  docker exec -i "${CH_CONTAINER}" clickhouse-client \
    --user "${CH_USER}" --password "${CH_PASSWORD}" \
    "$@"
}

# Ensure the target database exists before any create-table runs.
echo "==> Ensuring database ${CH_DATABASE} exists"
run_query --query "CREATE DATABASE IF NOT EXISTS ${CH_DATABASE}"

# Logical migration order. Each block is one self-contained stream.
MIGRATIONS=(
  # Transactions — master table (dual-write target)
  "001_create_transactions_table.sql"

  # Kafka engine — consumes transaction events from the 'transaction-log' topic
  "kafka_engine.sql"

  # Merchant API logs
  "merchant_api_logs.sql"
  "kafka_merchant_api_logs.sql"
  "merchant_api_logs_mv.sql"

  # Provider API logs
  "provider_api_logs.sql"
  "kafka_provider_api_logs.sql"
  "provider_api_logs_mv.sql"

  # Provisioning logs
  "provisioning_logs.sql"
  "kafka_provisioning_logs.sql"
  "provisioning_logs_mv.sql"
)

for file in "${MIGRATIONS[@]}"; do
  path="${SCRIPT_DIR}/${file}"
  if [[ ! -f "${path}" ]]; then
    echo "!! skipping missing file: ${file}"
    continue
  fi

  echo "==> Applying ${file}"
  run_query --database "${CH_DATABASE}" --multiquery < "${path}"
done

echo "==> All migrations applied successfully"
