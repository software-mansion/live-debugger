defmodule LiveDebugger.App.Debugger.Streams.Actions do
  @moduledoc """
  Actions for `LiveDebugger.App.Debugger.Streams` context.
  """

  alias LiveDebugger.App.Debugger.Streams.StreamUtils

  @type stream_update_result :: %{
          functions: [function()],
          config: [function()],
          name: atom()
        }

  @spec update_stream(
          stream_updates :: StreamUtils.live_stream_item(),
          dom_id_fun :: (any() -> String.t())
        ) ::
          {:ok, stream_update_result()} | {:error, String.t()}
  def update_stream(stream_updates, dom_id_fun) do
    with name <- stream_updates.name,
         funs <- StreamUtils.stream_update_functions(stream_updates),
         config <-
           StreamUtils.stream_config(stream_updates, dom_id: dom_id_fun) do
      {:ok, %{functions: funs, config: config, name: name}}
    end
  end
end
