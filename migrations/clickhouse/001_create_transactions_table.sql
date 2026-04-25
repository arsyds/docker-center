-- ClickHouse DDL for transactions table (dual-write target)
--
-- Engine: ReplacingMergeTree(updated_at)
--   - updated_at acts as the version column
--   - on merge, the row with the highest updated_at wins per ORDER BY key
--   - no ALTER TABLE UPDATE mutations are used — every state change is a new INSERT
--   - queries must use FINAL for correct deduplication before merge completes
--     e.g. SELECT * FROM transactions FINAL WHERE merchant_id = ?
--
-- Partition: toYYYYMM(transaction_date)
--   - isolates merges per month, improves FINAL query performance
--   - use do_not_merge_across_partitions_select_final=1 for further optimization
--
-- ORDER BY: (merchant_id, transaction_date, reference, merchant_reference, id)
--   - merchant_id first for the common tenant-filter pattern
--   - transaction_date aligned with partitioning
--   - reference + merchant_reference for direct transaction lookup
--   - id last to guarantee row uniqueness for RMT deduplication
--
-- Nullability policy: this table does not use Nullable(T). All columns that may be
-- absent in PG are declared as non-nullable with a DEFAULT sentinel. This matches
-- the ClickHouse Cloud policy and avoids the storage/merge overhead of Nullable.

CREATE TABLE IF NOT EXISTS clickhouse_local.transactions
(
    id                                  UUID,
    merchant_id                         UUID,
    store_id                            UUID,
    transaction_timestamp               DateTime64(3, 'UTC'),
    status_changed_timestamp            DateTime64(3, 'UTC') DEFAULT toDateTime64(0, 3, 'UTC'),
    transaction_date                    DateTime64(3, 'UTC'),
    transaction_type                    String,
    transaction_status                  String,
    previous_transaction_status         String  DEFAULT '',
    transaction_expired_time            DateTime64(3, 'UTC') DEFAULT toDateTime64(0, 3, 'UTC'),
    transaction_valid_time              Int32,
    transaction_paid_at                 DateTime64(3, 'UTC') DEFAULT toDateTime64(0, 3, 'UTC'),
    channel                             String  DEFAULT '',
    channel_group                       String  DEFAULT '',
    amount                              Float64 DEFAULT -1,
    fee                                 Float64 DEFAULT -1,
    provider_fee                        Float64 DEFAULT -1,
    fee_type                            String  DEFAULT '',
    fee_id                              UUID    DEFAULT toUUID('00000000-0000-0000-0000-000000000000'),
    merchant_fixed_fee                  Float64 DEFAULT -1,
    merchant_percentage_fee             Float64 DEFAULT -1,
    merchant_amount                     Float64 DEFAULT -1,
    provider_id                         UUID    DEFAULT toUUID('00000000-0000-0000-0000-000000000000'),
    provider_channel_id                 UUID    DEFAULT toUUID('00000000-0000-0000-0000-000000000000'),
    provider_fee_id                     UUID    DEFAULT toUUID('00000000-0000-0000-0000-000000000000'),
    provider_snap                       Bool,
    provider_response_code              String  DEFAULT '',
    provider_response_message           String  DEFAULT '',
    provider_reference                  String  DEFAULT '',
    provider_status_changed_timestamp   DateTime64(3, 'UTC') DEFAULT toDateTime64(0, 3, 'UTC'),
    provider_previous_response_code     String  DEFAULT '',
    provider_previous_response_message  String  DEFAULT '',
    reference                           String  DEFAULT '',
    merchant_reference                  String  DEFAULT '',
    merchant_callback_url               String  DEFAULT '',
    merchant_callback_response_code     String  DEFAULT '',
    merchant_callback_response_message  String  DEFAULT '',
    merchant_callback_sent_timestamp    DateTime64(3, 'UTC') DEFAULT toDateTime64(0, 3, 'UTC'),
    revenue                             Float64 DEFAULT -1,
    bank_code                           String  DEFAULT '',
    bank_account_id                     UUID    DEFAULT toUUID('00000000-0000-0000-0000-000000000000'),
    additional_info                     String  DEFAULT '',
    acquirer                            String  DEFAULT '',
    settlement_status                   String,
    settled_at                          DateTime64(3, 'UTC') DEFAULT toDateTime64(0, 3, 'UTC'),
    is_settled                          Bool,
    settlement_batch_id                 String  DEFAULT '',
    response_code                       String  DEFAULT '',
    response_message                    String  DEFAULT '',
    previous_response_code              String  DEFAULT '',
    previous_response_message           String  DEFAULT '',
    currency                            String  DEFAULT '',
    retrieval_reference_number          String  DEFAULT '',
    mpan                                String  DEFAULT '',
    payer_name                          String  DEFAULT '',
    payer_phone_number                  String  DEFAULT '',
    created_at                          DateTime64(3, 'UTC'),
    updated_at                          DateTime64(3, 'UTC'),
    deleted_at                          DateTime64(3, 'UTC') DEFAULT toDateTime64(0, 3, 'UTC')
)
ENGINE = ReplacingMergeTree(updated_at)
PARTITION BY toYYYYMM(transaction_date)
ORDER BY (merchant_id, transaction_date, reference, merchant_reference, id)
SETTINGS index_granularity = 8192;
