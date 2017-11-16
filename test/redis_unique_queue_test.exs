defmodule RedisUniqueQueueTest do
  use ExUnit.Case
  # doctest RedisUniqueQueue

  @redis_config Application.get_env(:redis_unique_queue, :redis)[:config]

  setup do
    {:ok, queue} = RedisUniqueQueue.create("test_queue", @redis_config)
    RedisUniqueQueue.clear(queue)
    {:ok, queue: queue}
  end

  test "return argument error if name not is_bitstring" do
    assert {:error, "argument error"} == RedisUniqueQueue.create('qwerty', @redis_config)
  end

  test "return error if name empty" do
    assert {:error, "name is empty"} == RedisUniqueQueue.create("", @redis_config)
  end

  test "test push and pop", %{queue: queue} do
    RedisUniqueQueue.push(queue, "test")
    RedisUniqueQueue.push(queue, "test2")
    assert {:ok, ["test"]} == RedisUniqueQueue.pop(queue)
  end

  test "test push_multi and pop_multi", %{queue: queue} do
    RedisUniqueQueue.push_multi(queue, ["test", "test2"])
    assert {:ok, ["test", "test2"]} == RedisUniqueQueue.pop_multi(queue, 2)
  end

  test "pop all values", %{queue: queue} do
    RedisUniqueQueue.push_multi(queue, ["test", "test2", "test3"])
    assert {:ok, ["test", "test2", "test3"]} == RedisUniqueQueue.pop_all(queue)
  end

  test "get front and back value", %{queue: queue} do
    RedisUniqueQueue.push_multi(queue, ["test", "test2", "test3"])
    {:ok, front} = RedisUniqueQueue.front(queue)
    {:ok, back} = RedisUniqueQueue.back(queue)
    assert front == ["test"] && back == ["test3"]
  end

  test "test unique and size", %{queue: queue} do
    RedisUniqueQueue.push(queue, "test")
    RedisUniqueQueue.push(queue, "test")
    assert {:ok, 1} == RedisUniqueQueue.size(queue)
  end

  test "test remove and remove by index", %{queue: queue} do
    RedisUniqueQueue.push_multi(queue, ["test", "test2", "test3"])
    RedisUniqueQueue.remove(queue, "test2")
    {:ok, remove} = RedisUniqueQueue.all(queue)
    RedisUniqueQueue.remove_item_by_index(queue, 1)
    {:ok, remove_by_index} = RedisUniqueQueue.all(queue)
    assert remove == ["test", "test3"] && remove_by_index == ["test"]
  end

  test "test include?", %{queue: queue} do
    RedisUniqueQueue.push_multi(queue, ["test", "test2", "test3"])
    {:ok, tr} = RedisUniqueQueue.include?(queue, "test2")
    {:ok, fl} = RedisUniqueQueue.include?(queue, "no")
    assert tr == true && fl == false
  end

  test "test peek", %{queue: queue} do
    RedisUniqueQueue.push_multi(queue, ["test", "test2", "test3"])
    {:ok, res} = RedisUniqueQueue.peek(queue, 1, 2)
    assert res == ["test2", "test3"]
  end

  test "test expire", %{queue: queue} do
    RedisUniqueQueue.push_multi(queue, ["test", "test2", "test3"])
    {:ok, size} = RedisUniqueQueue.size(queue)
    RedisUniqueQueue.expire(queue, 1)
    :timer.sleep(2000)
    {:ok, exp} = RedisUniqueQueue.size(queue)
    assert size == 3 && exp == 0
  end

  test "test queue clear", %{queue: queue} do
    RedisUniqueQueue.push(queue, "test")
    {:ok, size} = RedisUniqueQueue.size(queue)
    RedisUniqueQueue.clear(queue)
    {:ok, new_size} = RedisUniqueQueue.size(queue)
    assert size == 1 && new_size == 0
  end

end
