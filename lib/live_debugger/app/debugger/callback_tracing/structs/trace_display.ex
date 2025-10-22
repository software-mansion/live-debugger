defmodule LiveDebugger.App.Debugger.CallbackTracing.Structs.TraceDisplay do
  @moduledoc """
  Wrapper for trace to display it in the UI.

  * `trace` - trace to display
  * `from_event?` - whether the trace comes from an event
  * `render_body?` - whether to render the body of the trace
  """

  alias LiveDebugger.Structs.Trace
  alias LiveDebugger.Structs.DiffTrace

  defstruct [
    :id,
    :from_event?,
    :render_body?,
    :type,
    :title,
    :subtitle,
    :subtitle_link,
    :body,
    :side_section_left,
    :side_section_right
  ]

  @type type() :: :normal | :diff | :error
  @type side_section_left() :: {:timestamp, non_neg_integer()}
  @type side_section_right() ::
          {:execution_time, non_neg_integer() | nil} | {:size, non_neg_integer()}

  @type t() :: %__MODULE__{
          id: Trace.id(),
          from_event?: boolean(),
          render_body?: boolean(),
          type: type(),
          title: String.t(),
          subtitle: String.t() | nil,
          subtitle_link: String.t() | nil,
          body: list(term()),
          side_section_left: side_section_left(),
          side_section_right: side_section_right()
        }

  @spec from_trace(Trace.t() | DiffTrace.t(), boolean()) :: t()
  def from_trace(trace, from_event? \\ false) do
    %__MODULE__{
      id: trace.id,
      from_event?: from_event?,
      render_body?: false,
      type: get_type(trace),
      title: "Test title",
      subtitle: "Test module",
      subtitle_link: RoutesHelper.debugger_node_inspector(trace.pid, trace.cid),
      body: [{"Arg 1 (render/1)", %{"test" => "test"}}],
      side_section_left: {:timestamp, 1_761_118_075},
      side_section_right: {:execution_time, 1_761_118_075}
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
end
