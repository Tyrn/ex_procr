defmodule ExProcr.Album do
  @doc """
  Runs through the ammo belt and does copying, in the reverse order if necessary.
  """
  def copy(opt) do
    IO.inspect(opt)
  end

  @doc """
  Returns a vector of integer numbers
  embedded in a string argument.

  ## Examples

      iex> ExProcr.Album.str_strip_numbers("Book 03, Chapter 11")
      [3, 11]
      iex> ExProcr.Album.str_strip_numbers("Mission of Gravity")
      []

  """
  def str_strip_numbers(s) do
    Enum.map(Regex.scan(~R{\d+}, s), &(Enum.at(&1, 0) |> String.to_integer()))
  end

  @doc """
  Returns true if s1 is less than or equal to s2. If both strings
  contain digits, attempt is made to compare strings naturally.

  ## Examples

      iex> ExProcr.Album.str_le_n("Chapter 8", "Chapter 10")
      true

  """
  def str_le_n(s1, s2) do
    str1 = str_strip_numbers(s1)
    str2 = str_strip_numbers(s2)

    if str1 != [] and str2 != [], do: str1 <= str2, else: s1 <= s2
  end

  @doc """
  Returns true if s1 is greater than or equal to s2. If both strings
  contain digits, attempt is made to compare strings naturally.
  """
  def str_ge_n(s1, s2) do
    str_le_n(s2, s1)
  end

  @doc """
  Reduces authors to initials.

  ## Examples

      iex> ExProcr.Album.make_initials("I. Vazquez-Abrams, Ronnie G. Barrett")
      "I.V-A.,R.G.B."
      iex> ExProcr.Album.make_initials(~S{William "Wild Bill" Donovan})
      "W.D."

  """
  def make_initials(authors, sep \\ ".", trail \\ ".", hyph \\ "-") do
    by_space = fn s ->
      Enum.join(
        for(
          x <- Regex.split(~r{[\s#{sep}]+}, s),
          x != "",
          do: x |> String.slice(0, 1) |> String.upcase()
        ),
        sep
      )
    end

    by_hyph = fn s ->
      Enum.join(
        for(
          x <- Regex.split(~r{\s*(?:#{hyph}\s*)+}, s),
          do: x |> by_space.()
        ),
        hyph
      ) <> trail
    end

    sans_monikers = Regex.replace(~R{\"(?:\\.|[^\"\\])*\"}, authors, " ")

    Enum.join(
      for(
        author <- String.split(sans_monikers, ","),
        do: author |> by_hyph.()
      ),
      ","
    )
  end
end
