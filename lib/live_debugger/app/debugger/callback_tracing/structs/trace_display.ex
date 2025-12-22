defmodule LiveDebugger.App.Debugger.CallbackTracing.Structs.TraceDisplay do
  @moduledoc """
  Wrapper for trace to display it in the UI.

  * `trace` - trace to display
  * `from_event?` - whether the trace comes from an event
  * `render_body?` - whether to render the body of the trace
  """

  alias LiveDebugger.Structs.Trace
  alias LiveDebugger.Structs.Trace.FunctionTrace
  alias LiveDebugger.Structs.Trace.DiffTrace
  alias LiveDebugger.Structs.Trace.TraceError
  alias LiveDebugger.App.Utils.Parsers
  alias LiveDebugger.CommonTypes

  defstruct [
    :id,
    :from_event?,
    :render_body?,
    :type,
    :title,
    :subtitle,
    :subtitle_link_data,
    :body,
    :side_section_left,
    :side_section_right,
    :error
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
          subtitle_link_data: %{pid: pid(), cid: CommonTypes.cid()} | nil,
          body: list({String.t(), term()}),
          side_section_left: side_section_left(),
          side_section_right: side_section_right(),
          error: TraceError.t() | nil
        }

  @spec from_trace(Trace.t(), boolean()) :: t()
  def from_trace(trace, from_event? \\ false) do
    %__MODULE__{
      id: trace.id,
      from_event?: from_event?,
      render_body?: false,
      type: get_type(trace),
      title: get_title(trace),
      subtitle: get_subtitle(trace),
      subtitle_link_data: get_subtitle_link_data(trace),
      body: get_body(trace),
      side_section_left: get_side_section_left(trace),
      side_section_right: get_side_section_right(trace),
      error: get_error(trace)
    }
  end

  @spec render_body(t(), boolean()) :: t()
  def render_body(%__MODULE__{} = trace, value? \\ true) do
    Map.put(trace, :render_body?, value?)
  end

  @spec short_content(t(), boolean()) :: String.t()
  def short_content(trace_display, full? \\ false) do
    trace_display.body
    |> Enum.map(fn {_label, content} -> content end)
    |> Enum.map_join(" ", &inspect(&1, limit: if(full?, do: :infinity, else: 10), structs: false))
  end

  defp get_type(%{type: :exception_from}), do: :error
  defp get_type(%DiffTrace{}), do: :diff
  defp get_type(_), do: :normal

  defp get_title(%FunctionTrace{} = trace), do: FunctionTrace.callback_name(trace)
  defp get_title(%DiffTrace{}), do: "Diff sent"

  defp get_subtitle(%FunctionTrace{module: module, cid: cid}) do
    module_string = Parsers.module_to_string(module)
    cid_string = if cid, do: " (#{cid})", else: ""

    module_string <> cid_string
  end

  defp get_subtitle(%DiffTrace{}), do: nil

  defp get_subtitle_link_data(%FunctionTrace{pid: pid, cid: cid}) do
    %{pid: pid, cid: cid}
  end

  defp get_subtitle_link_data(%DiffTrace{}), do: nil

  defp get_body(%FunctionTrace{args: args} = trace) do
    Enum.with_index(args, fn arg, index ->
      {"Arg #{index} (#{FunctionTrace.arg_name(trace, index)})", arg}
    end)
  end

  defp get_body(%DiffTrace{body: body}), do: [{"Diff content", body}]

  defp get_side_section_left(%{timestamp: timestamp}) do
    {:timestamp, timestamp}
  end

  defp get_side_section_right(%FunctionTrace{execution_time: execution_time}) do
    {:execution_time, execution_time}
  end

  defp get_side_section_right(%DiffTrace{size: size}) do
    {:size, size}
  end

  defp get_error(%FunctionTrace{error: error}) when error != nil do
    error
  end

  defp get_error(%FunctionTrace{
         type: :exception_from,
         return_value: {:error, %RuntimeError{message: _} = error}
       }) do
    %TraceError{
      message: Exception.format_banner(:error, error),
      stacktrace: nil,
      raw_error: nil
    }
  end

  defp get_error(%FunctionTrace{error: error}) do
    error
  end

  defp get_error(_), do: nil
end
