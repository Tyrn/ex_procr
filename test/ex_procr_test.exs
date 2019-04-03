defmodule ExProcrTest do
  use ExUnit.Case
  doctest ExProcr
  doctest ExProcr.Album

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

  test "lists of integers are not insane" do
    assert [1, 2] < [1, 2, 3] == true
    assert [1, 3] > [1, 2, 3] == true
  end

  test "less than or equal" do
    assert str_le_n("", "") == true
    assert str_le_n("2a", "10a") == true
    assert str_le_n("alfa", "bravo") == true
  end

  test "greater than or equal" do
    assert str_ge_n("", "") == true
    assert str_ge_n("2a", "10a") == false
    assert str_ge_n("alfa", "bravo") == false
  end

  test "sorts naturally" do
    assert Enum.sort(
             ["bravo", "10", "alfa", "12", "9", "8"],
             &str_le_n/2
           ) == ["8", "9", "10", "12", "alfa", "bravo"]
  end

  test "sorts naturally in descending order" do
    assert Enum.sort(
             ["bravo", "10", "alfa", "12", "9", "8"],
             &str_ge_n/2
           ) == ["bravo", "alfa", "12", "10", "9", "8"]
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
    assert make_initials("österreich") == "Ö."
  end
end
