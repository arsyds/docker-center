#!/bin/bash

DUMP_DIR="./dumps/$(date +%Y%m%d_%H%M%S)"
mkdir -p "$DUMP_DIR"

# ─── PostgreSQL ──────────────────────────────────────────────────────────────
PG_CONTAINER="local-postgres"
PG_USER="postgres_user"
PG_DB="psql_local"

echo "Dumping PostgreSQL..."

if ! docker ps --format '{{.Names}}' | grep -q "^${PG_CONTAINER}$"; then
    echo "  [skip] Container ${PG_CONTAINER} is not running"
else
    docker exec "$PG_CONTAINER" \
        pg_dump -U "$PG_USER" -d "$PG_DB" --no-password \
        > "$DUMP_DIR/postgres_${PG_DB}.sql"
    echo "  Saved: $DUMP_DIR/postgres_${PG_DB}.sql"
fi

# ─── ClickHouse ──────────────────────────────────────────────────────────────
CH_CONTAINER="local-clickhouse"
CH_USER="clickhouse_user"
CH_PASS="clickhouse_pass"
CH_DB="clickhouse_local"

echo "Dumping ClickHouse..."

if ! docker ps --format '{{.Names}}' | grep -q "^${CH_CONTAINER}$"; then
    echo "  [skip] Container ${CH_CONTAINER} is not running"
else
    CH_DUMP="$DUMP_DIR/clickhouse_${CH_DB}.sql"

    echo "-- ClickHouse dump: database=${CH_DB}" > "$CH_DUMP"
    echo "-- Generated: $(date -u +%Y-%m-%dT%H:%M:%SZ)" >> "$CH_DUMP"
    echo "" >> "$CH_DUMP"
    echo "CREATE DATABASE IF NOT EXISTS ${CH_DB};" >> "$CH_DUMP"
    echo "" >> "$CH_DUMP"

    # Fetch table names and engine types (tab-separated)
    TABLE_INFO=$(docker exec "$CH_CONTAINER" \
        clickhouse-client \
            --user="$CH_USER" \
            --password="$CH_PASS" \
            --query="SELECT name, engine FROM system.tables WHERE database = '${CH_DB}' ORDER BY name" \
        2>/dev/null)

    while IFS=$'\t' read -r TABLE ENGINE; do
        [ -z "$TABLE" ] && continue

        echo "  Processing table: $TABLE ($ENGINE)"
        echo "-- Table: ${TABLE} (${ENGINE})" >> "$CH_DUMP"

        # DDL — SHOW CREATE TABLE returns literal \n; convert to real newlines
        docker exec "$CH_CONTAINER" \
            clickhouse-client \
                --user="$CH_USER" \
                --password="$CH_PASS" \
                --query="SHOW CREATE TABLE ${CH_DB}.${TABLE}" \
            2>/dev/null \
            | sed 's/\\n/\n/g; s/\\t/\t/g' >> "$CH_DUMP"

        printf ';\n\n' >> "$CH_DUMP"

        # Skip data dump for Kafka engines and Materialized Views
        if [[ "$ENGINE" == "Kafka" || "$ENGINE" == "MaterializedView" ]]; then
            echo "-- (data skipped for engine: ${ENGINE})" >> "$CH_DUMP"
            echo "" >> "$CH_DUMP"
            continue
        fi

        ROW_COUNT=$(docker exec "$CH_CONTAINER" \
            clickhouse-client \
                --user="$CH_USER" \
                --password="$CH_PASS" \
                --query="SELECT count() FROM ${CH_DB}.${TABLE}" \
            2>/dev/null)

        if [[ "$ROW_COUNT" =~ ^[0-9]+$ ]] && [ "$ROW_COUNT" -gt 0 ]; then
            docker exec "$CH_CONTAINER" \
                clickhouse-client \
                    --user="$CH_USER" \
                    --password="$CH_PASS" \
                    --query="SELECT * FROM ${CH_DB}.${TABLE} FORMAT SQLInsert SETTINGS output_format_sql_insert_table_name='${TABLE}'" \
                2>/dev/null >> "$CH_DUMP"
            echo "" >> "$CH_DUMP"
        fi

    done <<< "$TABLE_INFO"

    echo "  Saved: $CH_DUMP"
fi

echo "Done. Dumps saved to: $DUMP_DIR"
