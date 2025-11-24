defmodule LiveDebugger.App.Debugger.Streams.Queries do
  @moduledoc """
  Queries for `LiveDebugger.App.Debugger.Streams` context.
  """

  alias LiveDebugger.API.TracesStorage

  alias LiveDebugger.App.Debugger.Streams.StreamUtils

  require Logger

  @type streams_result :: %{
          functions: [function()],
          config: map(),
          names: [atom()]
        }

  @spec fetch_streams_from_render_traces(pid :: pid(), node_id :: TreeNode.id()) ::
          {:ok, streams_result()} | {:error, String.t()}
  def fetch_streams_from_render_traces(pid, node_id) do
    with {:ok, render_traces} <- fetch_render_traces(pid, node_id),
         stream_traces <- StreamUtils.extract_stream_traces(render_traces),
         names <- StreamUtils.streams_names(stream_traces),
         funs <- StreamUtils.streams_functions(stream_traces, names),
         config <- StreamUtils.streams_config(stream_traces, names) do
      {:ok, %{functions: funs, config: config, names: names}}
    else
      :end_of_table ->
        :end_of_table

      error ->
        Logger.error("Failed to fetch streams: #{inspect(error)}")
        {:error, "Failed to fetch streams"}
    end
  end

  defp fetch_render_traces(pid, node_id) do
    case TracesStorage.get!(pid, functions: ["render/1"], node_id: node_id) do
      :end_of_table ->
        :end_of_table

      {stream_updates, _trace} ->
        {:ok, stream_updates}
    end
  end
end
