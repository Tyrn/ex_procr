defmodule ExProcr.Album do
  @doc """
  Runs through the ammo belt and does copying, in the reverse order if necessary.
  """
  def copy(opt) do
    IO.inspect(opt)
    {:ok, p} = Counter.start_link()
    v = %{o: opt, cpid: p}

    ammo_belt = traverse_tree_dst(v, v.o.args.src_dir)

    for {{src, dst}, i} <- Enum.with_index(ammo_belt) do
      File.copy!(src, dst)
      IO.puts("#{i + 1}")
    end

    IO.puts("total: #{Counter.val(v.cpid)}")
  end

  @doc """
  Returns total count of audio files in a given directory
  and its subdirectories.
  """
  def audiofiles_count(dir) do
    dir |> audiofiles_count_lazily() |> Enum.sum()
  end

  defp audiofiles_count_lazily(dir) do
    abs = Stream.map(File.ls!(dir), &Path.join(dir, &1))
    {dirs, files} = Enum.split_with(abs, &File.dir?/1)

    Stream.flat_map(dirs, &audiofiles_count_lazily/1)
    |> Stream.concat(Stream.map(files, fn _ -> 1 end))
  end

  @doc """
  Returns a tuple of: (0) naturally sorted list of
  offspring directory paths (1) naturally sorted list
  of offspring file paths.
  """
  def list_dir_groom(_v, abs_path) do
    lst = File.ls!(abs_path)
    # Absolute paths do not go into sorting.
    {dirs, files} = Enum.split_with(lst, &File.dir?(Path.join(abs_path, &1)))

    {
      Enum.map(Enum.sort(dirs, &str_le_n/2), &Path.join(abs_path, &1)),
      Enum.map(Enum.sort(files, &str_le_n/2), &Path.join(abs_path, &1))
    }
  end

  def decorate_dir_name(_v, _i, path) do
    Path.basename(path)
  end

  def decorate_file_name(_v, _i, _dst_step, path) do
    Path.basename(path)
  end

  @doc """
  Traverse it!
  """
  def traverse_tree_dst(v, src_dir, dst_step \\ []) do
    {dirs, files} = list_dir_groom(v, src_dir)

    for {d, i} <- Enum.with_index(dirs) do
      step = dst_step ++ [decorate_dir_name(v, i, d)]
      File.mkdir!(Path.join([v.o.args.dst_dir] ++ step))
      traverse_tree_dst(v, d, step)
    end
    |> Stream.concat()
    |> Stream.concat(
      for {f, i} <- Enum.with_index(files) do
        Counter.inc(v.cpid)

        {
          f,
          Path.join(
            [v.o.args.dst_dir] ++
              dst_step ++ [decorate_file_name(v, i, dst_step, f)]
          )
        }
      end
    )
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
