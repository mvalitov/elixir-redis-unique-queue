use Mix.Config

config :redis_unique_queue, :redis,
    config: %{host: "0.0.0.0", port: 6379}
