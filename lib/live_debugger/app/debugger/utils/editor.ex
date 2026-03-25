defmodule LiveDebugger.App.Debugger.Utils.Editor do
  @moduledoc """
  Utilities for opening editors
  """

  require Logger

  @term_to_cmd %{
    "vscode" => "code -g",
    "zed" => "zed"
  }

  @spec detect_editor() :: String.t() | nil
  def detect_editor() do
    cond do
      elixir_editor = System.get_env("ELIXIR_EDITOR") ->
        elixir_editor

      mapped_editor = Map.get(@term_to_cmd, System.get_env("TERM_PROGRAM")) ->
        mapped_editor

      system_editor = System.get_env("EDITOR") ->
        system_editor

      true ->
        nil
    end
  end

  @spec get_editor_cmd(String.t(), String.t(), integer()) :: String.t()
  def get_editor_cmd(editor, file, line)
      when is_binary(file) and is_integer(line) and is_binary(editor) do
    if editor =~ "__FILE__" or editor =~ "__LINE__" do
      editor
      |> String.replace("__FILE__", inspect(file))
      |> String.replace("__LINE__", Integer.to_string(line))
    else
      "#{editor} #{inspect(file)}:#{line}"
    end
  end

  @editor_docs_url "https://hexdocs.pm/live_debugger/open_in_editor.html"

  @doc """
  Returns the URL to the "Open in Editor" documentation.
  """
  @spec editor_docs_url() :: String.t()
  def editor_docs_url, do: @editor_docs_url

  @doc """
  Opens a file in the editor. Spawns a separate process to avoid blocking iex.
  On error, sends a flash message to the given pid.
  """
  @spec open_in_editor(String.t(), String.t(), integer(), pid()) :: :ok
  def open_in_editor(editor, file, line, flash_pid) do
    alias LiveDebugger.App.Web.Hooks.Flash.LinkFlashData

    cmd = get_editor_cmd(editor, file, line)

    spawn(fn ->
      case run_shell_cmd(cmd) do
        :ok ->
          :ok

        {:error, reason} ->
          send(flash_pid, {:put_flash, :error, %LinkFlashData{
            text: reason,
            url: @editor_docs_url,
            label: "See the docs"
          }})
      end
    end)

    :ok
  end

  @spec run_shell_cmd(String.t()) :: :ok | {:error, term()}
  def run_shell_cmd(command) do
    case System.shell(command, stderr_to_stdout: true) do
      {_output, 0} ->
        :ok

      {output, status} ->
        msg = format_shell_error(command, output, status)
        Logger.error(msg)
        {:error, msg}
    end
  end

  defp format_shell_error(command, output, 127) do
    command_name =
      output
      |> String.split(":")
      |> Enum.at(-2, command)
      |> String.trim()

    """
    Error when opening editor: Could not find the "#{command_name}" command.
    """
  end

  defp format_shell_error(_command, output, status) do
    "Error when opening editor: Command failed with status #{status}. Output: #{String.trim(output)}"
  end
end
