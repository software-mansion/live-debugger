defmodule LiveDebugger.Utils.Logger do
  @moduledoc """
  This module extends the Logger module with additional information added to messages.
  """

  require Logger

  def info(message) when is_binary(message), do: Logger.info(message)
  def warning(message) when is_binary(message), do: Logger.warning(message)

  @spec error(message :: String.t(), report_message? :: boolean()) :: :ok
  def error(message, report_message? \\ true) when is_binary(message) do
    error_message =
      if report_message? do
        """
        Something went wrong.
        Please report an issue at: https://github.com/software-mansion-labs/live-debugger/issues/new?template=bug_report.md

        Error message:
        #{message}
        """
      else
        message
      end

    Logger.error(error_message)
  end
end
