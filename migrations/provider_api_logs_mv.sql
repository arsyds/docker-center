CREATE MATERIALIZED VIEW clickhouse_local.provider_api_logs_mv TO clickhouse_local.provider_api_logs (
    `transaction_reference` String,
    `endpoint_url` String,
    `signature` String,
    `request_payload` String,
    `response_payload` String,
    `req_header` String,
    `resp_header` String,
    `http_status_code` String,
    `request_date` Date,
    `request_timestamp` DateTime64(6, 'Asia/Jakarta'),
    `response_timestamp` DateTime64(6, 'Asia/Jakarta'),
    `provider_name` String,
    `adapter_name` String,
    `provider_channel_id` String,
    `channel` String,
    `error_message` String
) AS
SELECT
    transaction_reference,
    endpoint_url,
    signature,
    request_payload,
    response_payload,
    req_header,
    resp_header,
    http_status_code,
    toDate(
        parseDateTimeBestEffort(request_date, 6, 'Asia/Jakarta')
    ) AS request_date,
    parseDateTimeBestEffort(request_timestamp, 6, 'Asia/Jakarta') AS request_timestamp,
    parseDateTimeBestEffort(response_timestamp, 6, 'Asia/Jakarta') AS response_timestamp,
    provider_name,
    adapter_name,
    provider_channel_id,
    channel,
    error_message
FROM
    clickhouse_local.kafka_provider_api_logs;