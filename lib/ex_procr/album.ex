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
    s
  end

  @doc """
  Reduces authors to initials.
  """
  def make_initials(authors, _sep \\ ".", _trail \\ ".", _hyph \\ "-") do
    by_space = fn s -> s end
    by_space.(authors)
  end
end
