defmodule Mix.Tasks.BuildDevtools do
  use Mix.Task

  @shortdoc "Builds the DevTools extension for Chrome or Firefox"

  @moduledoc """
  Build the browser DevTools extension.

      mix build_devtools chrome
      mix build_devtools firefox
      mix build_devtools
  """

  @impl true
  def run([]) do
    build("chrome")
    Mix.shell().info("✅ DevTools extension built for chrome")

    build("firefox")
    Mix.shell().info("✅ DevTools extension built for firefox")
  end

  @impl true
  def run([target]) when target in ["chrome", "firefox"] do
    build(target)
    Mix.shell().info("✅ DevTools extension built for #{target}")
  end

  def run(_) do
    Mix.raise("Usage: mix build_devtools chrome|firefox")
  end

  defp build(target) do
    build_dir = "devtools_#{target}"
    zip_path = "devtools_#{target}.zip"
    common_dir = "devtools/common"

    File.mkdir_p!(build_dir)

    copy_recursive(common_dir, build_dir)
    copy_recursive("devtools/#{target}", build_dir)

    zip_dir(build_dir, zip_path)
  end

  defp copy_recursive(src, dest) do
    for file <- Path.wildcard(Path.join(src, "**")) do
      rel_path = Path.relative_to(file, src)
      dest_path = Path.join(dest, rel_path)

      cond do
        File.dir?(file) ->
          File.mkdir_p!(dest_path)

        File.regular?(file) ->
          File.mkdir_p!(Path.dirname(dest_path))
          File.cp!(file, dest_path)
      end
    end
  end

  defp zip_dir(src_dir, zip_path) do
    files =
      Path.wildcard(Path.join(src_dir, "**"), match_dot: true)
      |> Enum.filter(&File.regular?/1)
      |> Enum.map(&to_charlist/1)

    :zip.create(to_charlist(zip_path), files)
  end
end
