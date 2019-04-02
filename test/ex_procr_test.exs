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
    assert make_initials(" ") == "."
    assert make_initials("John ronald reuel Tolkien") == "J.R.R.T."
    assert make_initials("  e.B.Sledge ") == "E.B.S."
    assert make_initials("Apsley Cherry-Garrard") == "A.C-G."
    assert make_initials("Windsor Saxe-\tCoburg - Gotha") == "W.S-C-G."
    assert make_initials("Elisabeth Kubler-- - Ross") == "E.K-R."
    assert make_initials("  Fitz-Simmons Ashton-Burke Leigh") == "F-S.A-B.L."
    assert make_initials("Arleigh \"31-knot\"Burke ") == "A.B."
    assert make_initials(~S{Harry "Bing" Crosby, Kris "Tanto" Paronto}) == "H.C.,K.P."
    assert make_initials("a.s.,b.s.") == "A.S.,B.S."
    assert make_initials("A. Strugatsky, B...Strugatsky.") == "A.S.,B.S."
    assert make_initials("Иржи Кропачек, Йозеф Новотный") == "И.К.,Й.Н."
    assert make_initials("Österreich") == "Ö."
  end
end
