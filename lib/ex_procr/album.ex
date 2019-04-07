defmodule ExProcr.Album do
  @moduledoc """
  Making an audio album. Any function taking a path
  argument, defined in this project, takes an ABSOLUTE PATH.
  """

  defp twimc(optimus) do
    # Call once to set everything for everybody.
    #
    # {:ok, ppid} =
    #  :python.start([
    #    {:python, 'python'},
    #    {:python_path, '/home/alexey/spaces/elixir/ex_procr'}
    #  ])
    # rr = :python.start([{:python_path, to_charlist(Path.expand("python"))}, {:python, 'python'}])
    # fyto = :python.call(ppid, :mama, :add, [22, 20])

    IO.inspect(optimus)

    total = optimus.args.src_dir |> one_for_audiofile() |> Enum.sum()

    %{
      o: optimus,
      total: total,
      width: total |> Integer.to_string() |> String.length(),
      cpid: Counter.init(if optimus.flags.reverse, do: total, else: 1)
    }
  end

  @doc """
  Runs through the ammo belt and does copying, in the reverse order if necessary.
  """
  def copy(optimus) do
    v = twimc(optimus)

    ammo_belt = traverse_flat_dst(v, v.o.args.src_dir)

    for {{src, dst}, i} <- Enum.with_index(ammo_belt) do
      File.copy!(src, dst)
      IO.puts("#{pad(i + 1, v.width, " ")}")
    end

    IO.puts("counter: #{Counter.val(v.cpid)}, total: #{v.total}")
  end

  def aud_file?(path) do
    Enum.member?(
      [".MP3", ".M4A", ".M4B", ".OGG", ".WMA", ".FLAC"],
      path |> Path.extname() |> String.upcase()
    )
  end

  defp one_for_audiofile(dir) do
    # ...zero for anything else. To be Enum.sum()'ed.
    abs = Stream.map(File.ls!(dir), &Path.join(dir, &1))
    {dirs, files} = Enum.split_with(abs, &File.dir?/1)

    Stream.flat_map(dirs, &one_for_audiofile/1)
    |> Stream.concat(Stream.map(files, &if(aud_file?(&1), do: 1, else: 0)))
  end

  @doc """
  Returns a tuple of: (0) naturally sorted list of
  offspring directory paths (1) naturally sorted list
  of offspring file paths.
  """
  def list_dir_groom(v, dir) do
    lst = File.ls!(dir)
    # Absolute paths do not go into sorting.
    {dirs, all_files} = Enum.split_with(lst, &File.dir?(Path.join(dir, &1)))
    files = Stream.filter(all_files, &aud_file?/1)

    {
      Enum.map(Enum.sort(dirs, &cmp(v, &1, &2)), &Path.join(dir, &1)),
      Enum.map(
        Enum.sort(files, &cmp(v, Path.rootname(&1), Path.rootname(&2))),
        &Path.join(dir, &1)
      )
    }
  end

  def decorate_dir_name(v, i, path) do
    if v.o.flags.strip_decorations do
      ""
    else
      pad(i, 3, "0") <> "-"
    end <> Path.basename(path)
  end

  defp artist(v, forw_dash \\ true) do
    if v.o.options.artist_tag != nil do
      if forw_dash do
        "-" <> v.o.options.artist_tag
      else
        v.o.options.artist_tag <> "-"
      end
    else
      ""
    end
  end

  def decorate_file_name(v, i, dst_step, path) do
    cond do
      v.o.flags.strip_decorations ->
        Path.basename(path)

      true ->
        prefix =
          pad(i, v.width, "0") <>
            if v.o.flags.prepend_subdir_name and
                 not v.o.flags.tree_dst and dst_step != [] do
              "-" <> Enum.join(dst_step, "-") <> "-"
            else
              "-"
            end

        prefix <>
          if v.o.options.unified_name != nil do
            v.o.options.unified_name <> artist(v) <> Path.extname(path)
          else
            Path.basename(path)
          end
    end
  end

  @doc """
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
  """
  def traverse_flat_dst(v, src_dir, dst_step \\ []) do
    {dirs, files} = list_dir_groom(v, src_dir)

    for d <- dirs do
      step = dst_step ++ [Path.basename(d)]
      traverse_flat_dst(v, d, step)
    end
    |> Stream.concat()
    |> Stream.concat(
      for f <- files do
        dst_path =
          Path.join(
            v.o.args.dst_dir,
            decorate_file_name(v, Counter.val(v.cpid), dst_step, f)
          )

        Counter.inc(v.cpid)
        {f, dst_path}
      end
    )
  end

  @doc """
  ## Examples

      iex> ExProcr.Album.pad(3, 5, "0")
      "00003"
      iex> ExProcr.Album.pad(15331, 3, " ")
      "15331"

  """
  def pad(value, n, ch) do
    value |> Integer.to_string() |> String.pad_leading(n, ch)
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
  """
  def cmp(v, s1, s2) do
    le = fn l, r -> if v.o.flags.reverse, do: r <= l, else: l <= r end

    cond do
      v.o.flags.sort_lex ->
        le.(s1, s2)

      true ->
        str1 = str_strip_numbers(s1)
        str2 = str_strip_numbers(s2)
        if str1 != [] and str2 != [], do: le.(str1, str2), else: le.(s1, s2)
    end
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
