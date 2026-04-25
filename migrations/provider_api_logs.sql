CREATE TABLE clickhouse_local.provider_api_logs (
    `transaction_reference` String,
    `endpoint_url` String,
    `signature` String,
    `request_payload` String,
    `response_payload` String,
    `req_header` String,
    `resp_header` String,
    `http_status_code` Int32,
    `request_date` Date,
    `request_timestamp` DateTime,
    `response_timestamp` DateTime,
    `provider_name` String,
    `adapter_name` String,
    `provider_channel_id` String,
    `channel` String,
    `error_message` String,
    `_insert_time` DateTime DEFAULT now()
) ENGINE = MergeTree() PARTITION BY toYYYYMM(request_date)
ORDER BY
    (request_timestamp, transaction_reference) SETTINGS index_granularity = 8192