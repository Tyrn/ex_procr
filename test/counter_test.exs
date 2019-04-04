defmodule CounterTest do
  use ExUnit.Case

  test "initial count is zero" do
    {:ok, pid} = Counter.start_link()
    assert Counter.val(pid) == 0
  end

  test "inc adds to the counter" do
    {:ok, pid} = Counter.start_link()
    Counter.inc(pid)
    assert Counter.val(pid) == 1
    Counter.inc(pid)
    assert Counter.val(pid) == 2
  end
end
