defmodule ExProcr.Album do
  @moduledoc """
  Making an audio album. Any function taking a path
  argument, defined in this project, takes an ABSOLUTE PATH.
  """

  defp twimc(optimus) do
    # Call once to set up everything for everybody.
    if File.exists?(optimus.args.src_dir) do
      nil
    else
      IO.puts("Source directory \"#{optimus.args.src_dir}\" is not there.")
      exit(:shutdown)
    end

    if File.exists?(optimus.args.dst_dir) do
      nil
    else
      IO.puts("Destination path \"#{optimus.args.dst_dir}\" is not there.")
      exit(:shutdown)
    end

    # Forming basic destination: absolute path <> prefix <> destination name.
    executive_dst =
      Path.join(
        optimus.args.dst_dir,
        if optimus.flags.drop_dst do
          ""
        else
          if optimus.options.album_num != nil do
            pad(optimus.options.album_num, 2, "0") <> "-"
          else
            ""
          end <>
            if optimus.options.unified_name != nil do
              artist(optimus, false) <> optimus.options.unified_name
            else
              optimus.args.src_dir |> Path.basename()
            end
        end
      )

    {:ok, ppid} = :python.start()

    file_type =
      if optimus.options.file_type != nil do
        optimus.options.file_type
      else
        ""
      end

    total =
      :python.call(
        ppid,
        :mutagenstub,
        :audiofiles_count,
        [optimus.args.src_dir, file_type]
      )

    if total < 1 do
      IO.puts(
        "There are no supported audio files" <>
          " in the source directory \"#{optimus.args.src_dir}\"."
      )

      exit(:shutdown)
    else
      nil
    end

    if optimus.flags.drop_dst do
      nil
    else
      if File.exists?(executive_dst) do
        IO.puts("Destination directory \"#{executive_dst}\" already exists.")
        exit(:shutdown)
      else
        File.mkdir!(executive_dst)
      end
    end

    %{
      o: optimus,
      total: total,
      width: total |> Integer.to_string() |> String.length(),
      cpid: Counter.init(if optimus.flags.reverse, do: total, else: 1),
      ppid: ppid,
      count:
        if optimus.flags.reverse do
          &Counter.dec/1
        else
          &Counter.inc/1
        end,
      read_count: &Counter.val/1,
      album_tag:
        if optimus.options.unified_name != nil and
             optimus.options.album_tag == nil do
          optimus.options.unified_name
        else
          optimus.options.album_tag
        end,
      tree_dst:
        if optimus.flags.tree_dst and optimus.flags.reverse do
          IO.puts("  *** -t option ignored (conflicts with -r) ***")
          false
        else
          optimus.flags.tree_dst
        end,
      file_type: file_type,
      dst: executive_dst
    }
  end

  @doc """
  Runs through the ammo belt and does copying, in the reverse order if necessary.
  """
  def copy(optimus) do
    v = twimc(optimus)

    ammo_belt =
      if v.tree_dst do
        traverse_tree_dst(v, v.o.args.src_dir)
      else
        traverse_flat_dst(v, v.o.args.src_dir)
      end

    if v.o.flags.verbose, do: nil, else: IO.write("Starting ")

    if v.o.flags.reverse do
      for {entry, i} <- Enum.with_index(ammo_belt) do
        copy_file(v, entry, v.total - i)
      end
    else
      for {entry, i} <- Enum.with_index(ammo_belt) do
        copy_file(v, entry, i + 1)
      end
    end

    if v.o.flags.verbose, do: nil, else: IO.puts(" Done (#{v.total}).")
  end

  defp p_if_true(list, cond, extra) do
    if cond, do: extra ++ list, else: list
  end

  defp set_tags(v, _src, _dst, i) do
    title = fn s ->
      s
      # cond do
      #   v.o.flags.file_title_num ->
      #     Integer.to_string(i) <> ">" <> Path.rootname(Path.basename(src))

      #   v.o.flags.file_title ->
      #     Path.rootname(Path.basename(src))

      #   true ->
      #     Integer.to_string(i) <> " " <> s
      # end
    end

    tracknumber = not v.o.flags.drop_tracknumber
    artist_album = v.o.options.artist_tag != nil and v.o.options.album_tag != nil
    artist = v.o.options.artist_tag != nil and v.o.options.album_tag == nil
    album = v.o.options.artist_tag == nil and v.o.options.album_tag != nil

    tags =
      []
      |> p_if_true(
        tracknumber,
        ["tracknumber", Integer.to_string(i) <> "/" <> Integer.to_string(v.total)]
      )
      |> p_if_true(
        artist_album,
        [
          "title",
          title.(
            make_initials(v.o.options.artist_tag) <>
              " - " <> v.o.options.album_tag
          )
        ]
      )
      |> p_if_true(artist_album, ["artist", v.o.options.artist_tag])
      |> p_if_true(artist_album, ["album", v.o.options.album_tag])
      |> p_if_true(artist, ["title", title.(v.o.options.artist_tag)])
      |> p_if_true(artist, ["artist", v.o.options.artist_tag])
      |> p_if_true(album, ["title", title.(v.o.options.album_tag)])
      |> p_if_true(album, ["album", v.o.options.album_tag])

    IO.inspect(tags)
  end

  defp copy_file(v, entry, i) do
    {src, dst} = entry
    File.copy!(src, dst)
    # set_tags(v, src, dst, i)

    if v.o.flags.verbose do
      IO.puts("#{pad(i, v.width, " ")}\u26ac#{v.total} #{dst}")
    else
      IO.write(".")
    end
  end

  def aud_file?(v, path) do
    :python.call(v.ppid, :mutagenstub, :is_audiofile, [path, v.file_type])
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
    files = Stream.filter(all_files, &aud_file?(v, Path.join(dir, &1)))

    {
      Enum.map(Enum.sort(dirs, &cmp(v, &1, &2)), &Path.join(dir, &1)),
      Enum.map(
        Enum.sort(files, &cmp(v, Path.rootname(&1), Path.rootname(&2))),
        &Path.join(dir, &1)
      )
    }
  end

  defp decorate_dir_name(v, i, path) do
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

  defp decorate_file_name(v, i, dst_step, path) do
    cond do
      v.o.flags.strip_decorations ->
        Path.basename(path)

      true ->
        prefix =
          pad(i, v.width, "0") <>
            if v.o.flags.prepend_subdir_name and
                 not v.tree_dst and dst_step != [] do
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
  Recursively traverses the source directory and yields a sequence
  of (src, tree dst) pairs; the destination directory and file names
  get decorated according to options.
  """
  def traverse_tree_dst(v, src_dir, dst_step \\ []) do
    {dirs, files} = list_dir_groom(v, src_dir)

    for {d, i} <- Enum.with_index(dirs) do
      step = dst_step ++ [decorate_dir_name(v, i, d)]
      File.mkdir!(Path.join([v.dst] ++ step))
      traverse_tree_dst(v, d, step)
    end
    |> Stream.concat()
    |> Stream.concat(
      for {f, i} <- Enum.with_index(files) do
        {
          f,
          Path.join(
            [v.dst] ++
              dst_step ++ [decorate_file_name(v, i, dst_step, f)]
          )
        }
      end
    )
  end

  @doc """
  Recursively traverses the source directory and yields a sequence
  of (src, flat dst) pairs; the destination directory and file names
  get decorated according to options.
  """
  def traverse_flat_dst(v, src_dir, dst_step \\ []) do
    {dirs, files} = list_dir_groom(v, src_dir)

    traverse = fn d ->
      step = dst_step ++ [Path.basename(d)]
      traverse_flat_dst(v, d, step)
    end

    handle = fn f ->
      dst_path =
        Path.join(
          v.dst,
          decorate_file_name(v, v.read_count.(v.cpid), dst_step, f)
        )

      v.count.(v.cpid)
      {f, dst_path}
    end

    if v.o.flags.reverse do
      Stream.map(files, handle)
      |> Stream.concat(Stream.flat_map(dirs, traverse))
    else
      Stream.flat_map(dirs, traverse)
      |> Stream.concat(Stream.map(files, handle))
    end
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
