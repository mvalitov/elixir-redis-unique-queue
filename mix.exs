defmodule RedisUniqueQueue.Mixfile do
  use Mix.Project

  def project do
    [app: :redis_unique_queue,
     version: "0.1.5",
     elixir: "~> 1.6",
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     package: package(),
     homepage_url: "https://hexdocs.pm/redis_unique_queue",
     source_url: "https://github.com/mvalitov/elixir-redis-unique-queue",
     description: "A unique FIFO queue with atomic operations built on top of Redis.",
     deps: deps()]
  end

  def package do
    [name: :redis_unique_queue,
     files: ["lib", "mix.exs"],
     maintainers: ["Marsel Valitov"],
     licenses: ["MIT"],
     links: %{"Github" => "https://github.com/mvalitov/elixir-redis-unique-queue"}]
  end
  # Configuration for the OTP application
  #
  # Type "mix help compile.app" for more information
  def application do
    # Specify extra applications you'll use from Erlang/Elixir
    [extra_applications: [:logger, :redix]]
  end

  # Dependencies can be Hex packages:
  #
  #   {:my_dep, "~> 0.3.0"}
  #
  # Or git/path repositories:
  #
  #   {:my_dep, git: "https://github.com/elixir-lang/my_dep.git", tag: "0.1.0"}
  #
  # Type "mix help deps" for more examples and options
  defp deps do
    [{:redix, ">= 0.0.0"},
    {:earmark, "~> 0.1", only: :dev},
    {:ex_doc, "~> 0.11", only: :dev}]
  end
end
