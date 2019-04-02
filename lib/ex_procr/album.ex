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
  """
  def str_strip_numbers(s) do
    Enum.map(Regex.scan(~R{\d+}, s), &(Enum.at(&1, 0) |> String.to_integer()))
  end

  @doc """
  Reduces authors to initials.
  """
  def make_initials(authors, sep \\ ".", _trail \\ ".", _hyph \\ "-") do
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

    by_space.(authors)
  end
end
