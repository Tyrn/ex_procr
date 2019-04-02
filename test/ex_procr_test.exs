defmodule ExProcrTest do
  use ExUnit.Case
  doctest ExProcr

  import ExProcr.Album

  test "greets the world" do
    assert ExProcr.hello() == :world
  end

  test "strips numbers from a string" do
    assert str_strip_numbers("ab11cdd2k.144") == "ab11cdd2k.144"
  end

  test "makes initials" do
    assert make_initials("bravo") == "bravo"
  end
end
