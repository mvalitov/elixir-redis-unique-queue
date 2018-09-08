use Mix.Config

config :redis_unique_queue, :redis,
    config: %{host: "0.0.0.0", port: 6379}
config :redis_unique_queue, scripts_set_name: "REDIS_UNIQUE_QUEUE_SCRIPTS_LIST"
