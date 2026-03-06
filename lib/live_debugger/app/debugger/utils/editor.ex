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
