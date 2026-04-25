CREATE TABLE clickhouse_local.provisioning_logs (
    `provider_id` String,
    `adapter_name` String,
    `provider_name` String,
    `provisioning_datetime` DateTime64(3),
    `provisioning_date` Date,
    `provider_status` String,
    `error_message` String,
    `provider_channels` String
) ENGINE = MergeTree() PARTITION BY toYYYYMMDD(provisioning_date)
ORDER BY
    provisioning_datetime SETTINGS index_granularity = 8192