defmodule LiveDebugger.App.Debugger.Utils.Editor do
  @moduledoc """
  Utilities for opening editors
  """

  @term_to_cmd %{
    "vscode" => "code -g",
    "zed" => "zed"
  }

  require Logger

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
        msg = "#{output} Status: #{status}"
        Logger.error(msg)
        {:error, msg}
    end
  end
end
