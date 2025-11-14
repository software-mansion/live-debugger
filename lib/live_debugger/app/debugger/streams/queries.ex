defmodule LiveDebugger.App.Debugger.Streams.Queries do
  @moduledoc """
  Queries for `LiveDebugger.App.Debugger.Streams` context.
  """

  alias LiveDebugger.API.TracesStorage

  alias LiveDebugger.App.Debugger.Streams.StreamUtils

  @spec fetch_node_streams(pid :: pid()) ::
          {:ok, map()} | {:error, term()}
  def fetch_node_streams(pid) do
    opts =
      [
        functions: ["render/1"]
      ]

    case TracesStorage.get!(pid, opts) do
      :end_of_table ->
        {:error, "No render traces found"}

      stream_updates ->
        StreamUtils.get_initial_stream_functions(stream_updates)
    end
  end

  def update_node_streams(_, stream_updates, dom_id_fun) do
    StreamUtils.get_stream_functions_from_updates(stream_updates, dom_id_fun)
  end
end
