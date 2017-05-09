defmodule RedisUniqueQueue do
  @moduledoc """
  Is the elixir-implementation of ruby-gem [ruby-redis-unique-queue](https://github.com/MishaConway/ruby-redis-unique-queue)

  """

  @doc """
  Queue creation

  ## Examples

  * with options(redis host and port)

          iex> queue = RedisUniqueQueue.create("test_queue", %{host: "0.0.0.0", port: 6379})
          %RedisUniqueQueue.UniqueQueue{conn: #PID<0.177.0>, name: "test_queue",
          options: %{host: "0.0.0.0", port: 6379}}

  * with Redix connection

          iex> {:ok, conn} = Redix.start_link(host: "0.0.0.0", port: 6379)
          {:ok, #PID<0.163.0>}
          iex> queue = RedisUniqueQueue.create("test_queue", conn)
          %RedisUniqueQueue.UniqueQueue{conn: #PID<0.163.0>, name: "test_queue", options: %{}}

  """

  @spec create(name :: String.t, options :: %{host: String.t, port: port()}) :: %RedisUniqueQueue.UniqueQueue{}
  def create(name, options) when is_bitstring(name) and is_map(options) do
    case String.length(name) do
      0 ->
        {:error, "name is empty"}
      _ ->
        %RedisUniqueQueue.UniqueQueue{name: name, options: options, conn: connect(options)}
    end
  end

  @spec create(name :: String.t, conn :: pid()) :: %RedisUniqueQueue.UniqueQueue{}
  def create(name, conn) when is_bitstring(name) and is_pid(conn) do
    case String.length(name) do
      0 ->
        {:error, "name is empty"}
      _ ->
        %RedisUniqueQueue.UniqueQueue{name: name, conn: conn}
    end
  end

  def create(_name, _options) do
    {:error, "argument error"}
  end

  @doc """
  Push data to the queue

  ## Examples

      iex(2)> RedisUniqueQueue.push(queue, "test")
      {:ok, 1}

  """

  @spec push(queue :: %RedisUniqueQueue.UniqueQueue{}, data :: String.Chars.t) :: {}
  def push(queue, data) do
    Redix.command(queue.conn, ["ZADD", queue.name, time_now(), data])
  end

  @doc """
  Push multiple items onto the queue

  ## Examples

      iex(3)> RedisUniqueQueue.push_multi(queue, ["test2", "test3"])
      {:ok, 2}

  """

  @spec push_multi(queue :: %RedisUniqueQueue.UniqueQueue{}, data :: String.Chars.t) :: {}
  def push_multi(queue, [value]) do
    push(queue, value)
  end

  def push_multi(queue, [head|tail]) do
    data = Enum.reduce([head|tail], ["ZADD", queue.name], fn(x,acc) ->
        List.insert_at(acc, -1, [time_now(), x])
      end) |> List.flatten()
    Redix.command(queue.conn, data)
  end

  def push_multi(queue, value) do
    push(queue, value)
  end

  @doc """
  Pop data from the queue

  ## Examples

      iex(5)> RedisUniqueQueue.pop(queue)
      {:ok, ["test"]}

  """

  @spec pop(queue :: %RedisUniqueQueue.UniqueQueue{}) :: {atom(), []}
  def pop(queue) do
    Redix.command(queue.conn, ["EVAL", atomic_pop_script(queue.name, 0, time_now()), 0])
  end

  @doc """
  Pop all items in the queue

  ## Examples

      iex(5)> RedisUniqueQueue.pop_all(queue)
      {:ok, ["test2", "test3"]}

  """

  @spec pop_all(queue :: %RedisUniqueQueue.UniqueQueue{}) :: {atom(), []}
  def pop_all(queue) do
    Redix.command(queue.conn, ["EVAL", atomic_pop_all_script(queue.name), 0])
  end

  @doc """
  Atomically pop multiple items from the queue

  ## Examples

      iex(5)> RedisUniqueQueue.pop_multi(queue, 2)
      {:ok, ["test2", "test3"]}

  """

  @spec pop_multi(queue :: %RedisUniqueQueue.UniqueQueue{}, amount :: non_neg_integer()) :: {atom(), []}
  def pop_multi(queue, amount) do
    Redix.command(queue.conn, ["EVAL", atomic_pop_multi_script(queue.name, amount), 0])
  end

  @doc """
  Read the first item in the queue

  ## Examples

      iex(5)> RedisUniqueQueue.front(queue)
      {:ok, ["test2"]}

  """

  @spec front(queue :: %RedisUniqueQueue.UniqueQueue{}) :: {atom(), []}
  def front(queue) do
    Redix.command(queue.conn, ["ZRANGE", queue.name, 0, 0])
  end

  @doc """
  Read the last item in the queue

  ## Examples

      iex(5)> RedisUniqueQueue.back(queue)
      {:ok, ["test3"]}

  """

  @spec back(queue :: %RedisUniqueQueue.UniqueQueue{}) :: {atom(), []}
  def back(queue) do
    Redix.command(queue.conn, ["ZREVRANGE", queue.name, 0, 0])
  end

  @doc """
  Remove an arbitrary item from the queue

  ## Examples

      iex(12)> RedisUniqueQueue.remove(queue, ["test","test3"])
      {:ok, 2}

  """

  @spec remove(queue :: %RedisUniqueQueue.UniqueQueue{}, value :: String.Chars.t) :: {}
  def remove(queue, [head|tail]) do
    commands = Enum.reduce([head|tail], ["ZREM", queue.name], fn(x, acc) ->
      List.insert_at(acc, -1, x)
    end)
    Redix.command(queue.conn, commands)
  end

  def remove(queue, data) do
    Redix.command(queue.conn, ["ZREM", queue.name, data])
  end

  @doc """
  Remove an arbitrary item from the queue by index

  ## Examples

      iex(14)> RedisUniqueQueue.remove_item_by_index(queue, 2)
      {:ok, 1}

  """

  def remove_item_by_index(queue, index) do
    Redix.command(queue.conn, ["ZREMRANGEBYRANK", queue.name, index, index])
  end

  @doc """
  Get the size of the queue

  ## Examples

      iex(14)> RedisUniqueQueue.size(queue)
      {:ok, 4}

  """

  @spec size(queue :: %RedisUniqueQueue.UniqueQueue{}) :: {atom(), non_neg_integer()}
  def size(queue) do
    Redix.command(queue.conn, ["ZCARD", queue.name])
  end

  @doc """
  Get all items in the queue

  ## Examples

      iex(14)> RedisUniqueQueue.all(queue)
      {:ok, ["test2", "test3"]}

  """

  @spec all(queue :: %RedisUniqueQueue.UniqueQueue{}) :: {atom(), []}
  def all(queue) do
    {:ok, s} = size(queue)
    peek(queue, 0, s)
  end

  @doc """
  See if an item exists in the queue

  ## Examples

      iex(14)> RedisUniqueQueue.include?(queue, "test")
      {:ok, true}

      iex(15)> RedisUniqueQueue.include?(queue, "test44")
      {:ok, false}

  """

  @spec include?(queue :: %RedisUniqueQueue.UniqueQueue{}, value :: String.Chars.t) :: {atom(), boolean()}
  def include?(queue, data) do
    {:ok, score} = Redix.command(queue.conn, ["ZSCORE", queue.name, data])
    {:ok, !(score == nil)}
  end

  @doc """
  The queue can be cleared of all items

  ## Examples

      iex(14)> RedisUniqueQueue.clear(queue)
      {:ok, 1}

  """

  @spec clear(queue :: %RedisUniqueQueue.UniqueQueue{}) :: {}
  def clear(queue) do
    Redix.command(queue.conn, ["DEL", queue.name])
  end

  @doc """
  Optionally, the queue can also be set to expire (in seconds).

  ## Examples

      iex(14)> RedisUniqueQueue.expire(queue, 30)
      {:ok, 1}

  """

  @spec expire(queue :: %RedisUniqueQueue.UniqueQueue{}, seconds :: pos_integer()) :: {}
  def expire(queue, seconds) do
    Redix.command(queue.conn, ["EXPIRE", queue.name, seconds])
  end

  @doc """
  Peek into arbitrary ranges in the queue

  ## Examples

      iex(14)> RedisUniqueQueue.peek(queue, 1, 2)
      {:ok, ["test2", "test3"]}

  """

  @spec peek(queue :: %RedisUniqueQueue.UniqueQueue{}, from :: non_neg_integer() , amount :: non_neg_integer()) :: {atom(), []}
  def peek(queue, from, amount) do
    Redix.command(queue.conn, ["ZRANGE", queue.name, from, from + amount - 1])
  end

  defp connect(options) do
    {:ok, conn} = Redix.start_link(host: options[:host], port: options[:port])
    conn
  end

  defp time_now() do
    DateTime.utc_now() |> DateTime.to_unix(:microsecond)
  end

  defp atomic_pop_script(name, min_score, max_score) do
    "local name = '#{name}'
    local min_score = #{min_score}
    local max_score = #{max_score}

    local value = redis.call('ZRANGEBYSCORE', name, min_score, max_score, 'LIMIT', '0', '1')

    if not value[1] then
      return ''
    end

    if value[1] then
      redis.call('ZREM', name, value[1])
    end

    return value"
  end

  defp atomic_pop_all_script(name) do
    "local name = '#{name}'

    local size = redis.call('ZCARD', name)

    if not size then
      return ''
    end

    local values = redis.call('ZRANGE', name, 0, size-1)

    redis.call('DEL', name)

    return values"
  end

  defp atomic_pop_multi_script(name, amount) do
    "local name = '#{name}'
    local count = #{amount}

    local values = redis.call('ZRANGE', name, 0, count-1)

    redis.call('ZREMRANGEBYRANK', name, 0, count-1)

    return values"
  end

end
