# RedisUniqueQueue

Is the elixir-implementation of ruby-gem [ruby-redis-unique-queue](https://github.com/MishaConway/ruby-redis-unique-queue)

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `redis_unique_queue` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [{:redis_unique_queue, "~> 0.1.0"}]
end
```

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at [https://hexdocs.pm/redis_unique_queue](https://hexdocs.pm/redis_unique_queue).

## Usage


Queue creation

    queue = RedisUniqueQueue.create("test_queue", %{host: "0.0.0.0", port: 6379})

Push data to the queue

    RedisUniqueQueue.push(queue, "test")

Push multiple items onto the queue

    RedisUniqueQueue.push_multi(queue, ["test2", "test3"])

Pop data from the queue

    RedisUniqueQueue.pop(queue)

Atomically pop multiple items from the queue

    RedisUniqueQueue.pop_multi(queue, 2)

Pop all items in the queue

    RedisUniqueQueue.pop_all(queue)

Get the size of the queue

    RedisUniqueQueue.size(queue)

Read the first item in the queue

    RedisUniqueQueue.front(queue)

Read the last item in the queue

    RedisUniqueQueue.back(queue)

See if an item exists in the queue

    RedisUniqueQueue.include?(queue, "test")

Remove an arbitrary item from the queue

    RedisUniqueQueue.remove(queue, "test2")

Remove an arbitrary item from the queue by index

    RedisUniqueQueue.remove_item_by_index(queue, 2)

Get all items in the queue

    RedisUniqueQueue.all(queue)

Peek into arbitrary ranges in the queue

    RedisUniqueQueue.peek(queue)

The queue can be cleared of all items

    RedisUniqueQueue.clear(queue)

Optionally, the queue can also be set to expire (in seconds).

    RedisUniqueQueue.expire(queue, 60)
