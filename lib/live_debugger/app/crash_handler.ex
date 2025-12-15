defmodule LiveDebugger.App.CrashHandler do
  require Logger

  def handle_event(_event, _measurements, metadata, _config) do
    socket = metadata.socket
    reason = metadata.reason
    stacktrace = metadata.stacktrace

    formatted_stacktrace = Exception.format_stacktrace(stacktrace)

    error_message = Exception.message(reason)

    full_console_dump = Exception.format(:error, reason, stacktrace)
    dbg({full_console_dump, formatted_stacktrace, error_message})
  end
end
