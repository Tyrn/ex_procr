defmodule ExProcr.Album do
  @doc """
  Runs through the ammo belt and does copying, in the reverse order if necessary.
  """
  def copy(opt) do
    IO.inspect(opt)
  end

  @doc """
  Reduces authors to initials.
  """
  def make_initials(authors, sep \\ ".", trail \\ ".", hyph \\ "-") do
    authors
  end
end
