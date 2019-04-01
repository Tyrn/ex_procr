defmodule ExProcrTest do
  use ExUnit.Case
  doctest ExProcr

  import ExProcr.Album

  test "greets the world" do
    assert ExProcr.hello() == :world
  end

  test "makes initials" do
    assert make_initials("bravo") == "bravo"
  end
end
