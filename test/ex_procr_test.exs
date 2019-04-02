defmodule ExProcrTest do
  use ExUnit.Case
  doctest ExProcr

  import ExProcr.Album

  test "greets the world" do
    assert ExProcr.hello() == :world
  end

  test "strips numbers from a string" do
    assert str_strip_numbers("ab11cdd2k.144") == [11, 2, 144]
    assert str_strip_numbers("144") == [144]
    assert str_strip_numbers("Ignacio Vazquez-Abrams") == []
    assert str_strip_numbers("") == []
  end

  test "makes initials" do
    assert make_initials("bravo") == "B"
  end
end
