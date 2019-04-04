defmodule ExProcr.Album do
  @doc """
  Runs through the ammo belt and does copying, in the reverse order if necessary.
  """
  def copy(opt) do
    IO.inspect(opt)
  end

  @doc """
  Returns a tuple of: (0) naturally sorted list of
  offspring directory paths (1) naturally sorted list
  of offspring file paths.
  """
  def list_dir_groom(abs_path) do
    raw_list = File.ls!(abs_path)
    # Absolute paths do not go into sorting.
    raw_dirs = for x <- raw_list, File.dir?(Path.join(abs_path, x)), do: x
    raw_files = for x <- raw_list, File.regular?(Path.join(abs_path, x)), do: x

    dirs =
      for x <- Enum.sort(raw_dirs, &str_le_n/2) do
        Path.join(abs_path, x)
      end

    files =
      for x <- Enum.sort(raw_files, &str_le_n/2) do
        Path.join(abs_path, x)
      end

    {dirs, files}
  end

  @doc """
  Traverse it lazily!
  """
  def traverse_tree_dst_lazy_r(src_dir) do
    {dirs, files} = list_dir_groom(src_dir)

    for x <- files do
      x
    end
    |> Stream.concat(
      for x <- dirs do
        traverse_tree_dst_lazy_r(x)
      end
      |> Stream.concat()
    )
  end

  @doc """
  Traverse it lazily!
  """
  def traverse_tree_dst_lazy(src_dir) do
    {dirs, files} = list_dir_groom(src_dir)

    for x <- dirs do
      traverse_tree_dst_lazy(x)
    end
    |> Stream.concat()
    |> Stream.concat(
      for x <- files do
        x
      end
    )
  end

  @doc """
  Traverse it!
  """
  def traverse_tree_dst(src_dir, _dst_step \\ nil) do
    {dirs, files} = list_dir_groom(src_dir)

    for {x, i} <- Enum.with_index(dirs) do
      IO.puts("dir #{i}: #{x}")
      traverse_tree_dst(x)
    end

    for {x, i} <- Enum.with_index(files) do
      IO.puts("file #{i}: #{x}")
    end

    nil
  end

  @doc """
  ## Examples

      iex> ExProcr.Album.zero_pad(3, 5)
      "00003"
      iex> ExProcr.Album.zero_pad(15331, 3)
      "15331"

  """
  def zero_pad(value, n) do
    value |> Integer.to_string() |> String.pad_leading(n, "0")
  end

  @doc """
  Returns True, if path has extension ext, case and leading dot insensitive.

  ## Examples

      iex> ExProcr.Album.has_ext_of("party/foxtrot.MP3", "mp3")
      true

  """
  def has_ext_of(path, ext) do
    path
    |> Path.extname()
    |> String.trim(".")
    |> String.upcase() == ext |> String.trim(".") |> String.upcase()
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
