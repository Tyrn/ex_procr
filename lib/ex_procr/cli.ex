defmodule ExProcr.CLI do
  @moduledoc """
  Handle the command line.
  """

  def main(argv) do
    argv
    |> parse_args()
    |> ExProcr.Album.copy()
  end

  @utility_description """
  pcx "Procrustes" SmArT is a CLI utility for copying subtrees containing
  supported audio files in sequence, naturally sorted. The end result is a
  "flattened" copy of the source subtree. "Flattened" means that only a namesake
  of the root source directory is created, where all the files get copied to,
  names prefixed with a serial number. Tag "Track Number" is set, tags "Title",
  "Artist", and "Album" can be replaced optionally. The writing process is
  strictly sequential: either starting with the number one file, or in the
  reversed order. This can be important for some mobile devices.
  """

  @doc """
  Parse the command line.
  """
  def parse_args(argv) do
    Optimus.new!(
      name: "pcx",
      # description: "Audio album builder",
      # version: "0.1.0",
      # author: "Tyrn",
      about: @utility_description,
      allow_unknown_args: false,
      parse_double_dash: true,
      args: [
        src_dir: [
          value_name: "SRC_DIR",
          help: "source directory",
          required: true
        ],
        dst_dir: [
          value_name: "DST_DIR",
          help: "general destination directory",
          required: true
        ]
      ],
      flags: [
        verbose: [
          short: "-v",
          long: "--verbose",
          help: "verbose output"
        ],
        drop_tracknumber: [
          short: "-d",
          long: "--drop-tracknumber",
          help: "do not set track numbers"
        ],
        strip_decorations: [
          short: "-s",
          long: "--strip-decorations",
          help: "strip file and directory name decorations"
        ],
        file_title: [
          short: "-f",
          long: "--file-title",
          help: "use file name for title tag"
        ],
        file_title_num: [
          short: "-F",
          long: "--file-title-num",
          help: "use numbered file name for title tag"
        ],
        sort_lex: [
          short: "-x",
          long: "--sort-lex",
          help: "sort files lexicographically"
        ],
        tree_dst: [
          short: "-t",
          long: "--tree-dst",
          help: "retain the tree structure of the source album at destination"
        ],
        drop_dst: [
          short: "-p",
          long: "--drop-dst",
          help: "do not create destination directory"
        ],
        reverse: [
          short: "-r",
          long: "--reverse",
          help: "copy files in reverse order (number one file is the last to be copied)"
        ],
        prepend_subdir_name: [
          short: "-i",
          long: "--prepend-subdir-name",
          help: "prepend current subdirectory name to a file name"
        ]
      ]
    )
    |> Optimus.parse!(argv)
  end
end
