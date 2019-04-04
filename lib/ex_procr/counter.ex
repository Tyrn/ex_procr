defmodule Counter do
  def start_link do
    Agent.start_link(fn -> 0 end)
  end

  def val(pid) do
    Agent.get(pid, fn count -> count end)
  end

  def inc(pid) do
    Agent.update(pid, fn count -> count + 1 end)
  end
end
