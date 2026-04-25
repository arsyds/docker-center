CREATE TABLE clickhouse_local.kafka_provisioning_logs (
    `provider_id` String,
    `adapter_name` String,
    `provider_name` String,
    `provisioning_datetime` String,
    `provider_status` String,
    `error_message` String,
    `provider_channels` String
) ENGINE = Kafka SETTINGS kafka_broker_list = 'broker-1:9092,broker-2:9092,broker-3:9092',
kafka_topic_list = 'provisioning-log',
kafka_format = 'JSONEachRow',
kafka_group_name = 'provisioning-log-ch',
kafka_num_consumers = 1,
kafka_thread_per_consumer = 1,
kafka_commit_on_select = true