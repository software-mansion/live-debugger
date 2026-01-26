defmodule LiveDebugger.Services.CallbackTracer.TraceUtils do
  @moduledoc """
  Utility functions for traces.
  """

  alias LiveDebugger.App.Utils.Parsers

  alias LiveDebugger.Structs.Trace.ErrorTrace

  @spec format_ts({mega :: integer(), sec :: integer(), micro :: integer()}) :: String.t()
  def format_ts({mega, sec, micro}) do
    unix_micro = (mega * 1_000_000 + sec) * 1_000_000 + micro
    Parsers.parse_timestamp(unix_micro)
  end

  @spec add_error_to_trace(
          trace :: map(),
          message :: String.t(),
          stacktrace :: String.t(),
          raw_error_banner :: String.t()
        ) :: map()
  def add_error_to_trace(trace, message, stacktrace, raw_error_banner) do
    %{
      trace
      | error:
          ErrorTrace.new(
            shorten_message(message),
            stacktrace,
            raw_error_banner <> message <> " \n" <> stacktrace
          ),
        type: :exception_from
    }
  end

  @spec normalize_error({reason :: any(), stacktrace :: list()}) :: {String.t(), String.t()}
  def normalize_error({reason, stacktrace}) when is_list(stacktrace) do
    {
      Exception.format_banner(:error, reason),
      Exception.format_stacktrace(stacktrace)
    }
  end

  def normalize_error(reason) do
    {
      "** (stop) " <> inspect(reason),
      "(Stacktrace not available)"
    }
  end

  defp shorten_message(message) do
    message
    |> String.split(~r/\.(\s|$)/, parts: 2)
    |> List.first()
  end
end
