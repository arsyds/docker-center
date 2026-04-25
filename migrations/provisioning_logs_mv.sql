CREATE MATERIALIZED VIEW clickhouse_local.provisioning_logs_mv TO clickhouse_local.provisioning_logs (
    `provider_id` String,
    `provider_name` String,
    `adapter_name` String,
    `provisioning_datetime` DateTime64(6, 'Asia/Jakarta'),
    `provisioning_date` Date,
    `provider_status` String,
    `error_message` String,
    `provider_channels` String
) AS
SELECT
    provider_id,
    provider_name,
    adapter_name,
    parseDateTimeBestEffort(provisioning_datetime, 6, 'Asia/Jakarta') AS provisioning_datetime,
    toDate(provisioning_datetime) AS provisioning_date,
    provider_status,
    error_message,
    provider_channels
FROM
    clickhouse_local.kafka_provisioning_logs;