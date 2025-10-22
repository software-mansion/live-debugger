defmodule LiveDebugger.App.Debugger.CallbackTracing.Structs.TraceDisplay do
  @moduledoc """
  Wrapper for trace to display it in the UI.

  * `trace` - trace to display
  * `from_event?` - whether the trace comes from an event
  * `render_body?` - whether to render the body of the trace
  """

  alias LiveDebugger.Structs.Trace
  alias LiveDebugger.Structs.DiffTrace
  alias LiveDebugger.CommonTypes

  defstruct [
    :id,
    :from_event?,
    :render_body?,
    :module,
    :title,
    :body,
    :timestamp,
    :side_info,
    :type,
    :pid,
    :cid
  ]

  @type type() :: :normal | :diff | :error
  @type side_info() :: {:execution_time, non_neg_integer() | nil} | {:size, non_neg_integer()}

  @type t() :: %__MODULE__{
          # Helper stuff for rendering in stream
          id: Trace.id(),
          from_event?: boolean(),
          render_body?: boolean(),

          # Data for rendering in UI
          module: String.t() | nil,
          title: String.t(),
          body: list(term()),
          timestamp: non_neg_integer(),
          side_info: side_info(),
          type: type(),
          pid: pid(),
          cid: CommonTypes.cid() | nil
        }

  @spec from_trace(Trace.t() | DiffTrace.t(), boolean()) :: t()
  def from_trace(trace, from_event? \\ false) do
    %__MODULE__{
      id: trace.id,
      from_event?: from_event?,
      render_body?: false,
      module: "Test module",
      title: "Test title",
      body: [{"Arg 1 (render/1)", %{"test" => "test"}}],
      timestamp: 1_761_118_075,
      side_info: get_side_info(trace),
      type: get_type(trace),
      pid: trace.pid,
      cid: trace.cid
    }
  end

  @spec render_body(t()) :: t()
  def render_body(%__MODULE__{} = trace) do
    Map.put(trace, :render_body?, true)
  end

  def short_content(trace_display, full? \\ false) do
    trace_display.body
    |> Enum.map(fn {_label, content} -> content end)
    |> Enum.map_join(" ", &inspect(&1, limit: if(full?, do: :infinity, else: 10), structs: false))
  end

  defp get_type(%{type: :exception_from}), do: :error
  defp get_type(%LiveDebugger.Structs.DiffTrace{}), do: :diff
  defp get_type(_), do: :normal

  defp get_side_info(%LiveDebugger.Structs.DiffTrace{size: size}) do
    {:size, size}
  end

  defp get_side_info(%LiveDebugger.Structs.Trace{execution_time: execution_time}) do
    {:execution_time, execution_time}
  end

  defp get_side_info(_), do: nil
end
