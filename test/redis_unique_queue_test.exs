defmodule RedisUniqueQueueTest do
  use ExUnit.Case
  # doctest RedisUniqueQueue

  setup do
    queue = RedisUniqueQueue.create("test_queue", %{host: "0.0.0.0", port: 6379})
    RedisUniqueQueue.clear(queue)
    {:ok, cleared: true}
  end

  test "return argument error if name not is_bitstring" do
    queue = RedisUniqueQueue.create('qwerty', %{host: "0.0.0.0", port: 6379})
    assert queue == {:error, "argument error"}
  end

  test "return error if name empty" do
    queue = RedisUniqueQueue.create("", %{host: "0.0.0.0", port: 6379})
    assert queue == {:error, "name is empty"}
  end

  test "test push and pop" do
    queue = RedisUniqueQueue.create("test_queue", %{host: "0.0.0.0", port: 6379})
    RedisUniqueQueue.push(queue, "test")
    RedisUniqueQueue.push(queue, "test2")
    {:ok, pop} = RedisUniqueQueue.pop(queue)
    assert pop == ["test"]
  end

  test "test push_multi and pop_multi" do
    queue = RedisUniqueQueue.create("test_queue", %{host: "0.0.0.0", port: 6379})
    RedisUniqueQueue.push_multi(queue, ["test", "test2"])
    {:ok, res} = RedisUniqueQueue.pop_multi(queue, 2)
    assert res == ["test", "test2"]
  end

  test "pop all values" do
    queue = RedisUniqueQueue.create("test_queue", %{host: "0.0.0.0", port: 6379})
    RedisUniqueQueue.push_multi(queue, ["test", "test2", "test3"])
    {:ok, res} = RedisUniqueQueue.pop_all(queue)
    assert res == ["test", "test2", "test3"]
  end

  test "get front and back value" do
    queue = RedisUniqueQueue.create("test_queue", %{host: "0.0.0.0", port: 6379})
    RedisUniqueQueue.push_multi(queue, ["test", "test2", "test3"])
    {:ok, front} = RedisUniqueQueue.front(queue)
    {:ok, back} = RedisUniqueQueue.back(queue)
    assert front == ["test"] && back == ["test3"]
  end

  test "test unique and size" do
    queue = RedisUniqueQueue.create("test_queue", %{host: "0.0.0.0", port: 6379})
    RedisUniqueQueue.push(queue, "test")
    RedisUniqueQueue.push(queue, "test")
    {:ok, size} = RedisUniqueQueue.size(queue)
    assert size == 1
  end

  test "test remove and remove by index" do
    queue = RedisUniqueQueue.create("test_queue", %{host: "0.0.0.0", port: 6379})
    RedisUniqueQueue.push_multi(queue, ["test", "test2", "test3"])
    RedisUniqueQueue.remove(queue, "test2")
    {:ok, remove} = RedisUniqueQueue.all(queue)
    RedisUniqueQueue.remove_item_by_index(queue, 1)
    {:ok, remove_by_index} = RedisUniqueQueue.all(queue)
    assert remove == ["test", "test3"] && remove_by_index == ["test"]
  end

  test "test include?" do
    queue = RedisUniqueQueue.create("test_queue", %{host: "0.0.0.0", port: 6379})
    RedisUniqueQueue.push_multi(queue, ["test", "test2", "test3"])
    {:ok, tr} = RedisUniqueQueue.include?(queue, "test2")
    {:ok, fl} = RedisUniqueQueue.include?(queue, "no")
    assert tr == true && fl == false
  end

  test "test peek" do
    queue = RedisUniqueQueue.create("test_queue", %{host: "0.0.0.0", port: 6379})
    RedisUniqueQueue.push_multi(queue, ["test", "test2", "test3"])
    {:ok, res} = RedisUniqueQueue.peek(queue, 1, 2)
    assert res == ["test2", "test3"]
  end

  test "test expire" do
    queue = RedisUniqueQueue.create("test_queue", %{host: "0.0.0.0", port: 6379})
    RedisUniqueQueue.push_multi(queue, ["test", "test2", "test3"])
    {:ok, size} = RedisUniqueQueue.size(queue)
    RedisUniqueQueue.expire(queue, 1)
    :timer.sleep(2000)
    {:ok, exp} = RedisUniqueQueue.size(queue)
    assert size == 3 && exp == 0
  end

  test "test queue clear" do
    queue = RedisUniqueQueue.create("test_queue", %{host: "0.0.0.0", port: 6379})
    RedisUniqueQueue.push(queue, "test")
    {:ok, size} = RedisUniqueQueue.size(queue)
    RedisUniqueQueue.clear(queue)
    {:ok, new_size} = RedisUniqueQueue.size(queue)
    assert size == 1 && new_size == 0
  end

end
