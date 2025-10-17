defmodule LiveDebugger.App.Debugger.CallbackTracing.Structs.TraceDisplayTest do
  use ExUnit.Case, async: true

  alias LiveDebugger.App.Debugger.CallbackTracing.Structs.TraceDisplay
  alias LiveDebugger.Fakes

  test "from_trace/1 creates a TraceDisplay struct" do
    trace = Fakes.trace()
    trace_display = TraceDisplay.from_trace(trace)

    assert %TraceDisplay{trace: ^trace, from_event?: false, render_body?: false} = trace_display
  end

  test "from_trace/2 creates a TraceDisplay struct with proper from_event? value" do
    trace = Fakes.trace()
    trace_display = TraceDisplay.from_trace(trace, true)

    assert %TraceDisplay{trace: ^trace, from_event?: true, render_body?: false} = trace_display
  end

  test "from_trace/2 creates a TraceDisplay struct with proper from_event? value for DiffTrace" do
    trace = Fakes.diff_trace()
    trace_display = TraceDisplay.from_trace(trace, true)

    assert %TraceDisplay{trace: ^trace, from_event?: true, render_body?: false} = trace_display
  end

  test "render_body/1 sets render_body? to true" do
    trace_display = %TraceDisplay{trace: Fakes.trace(), from_event?: false, render_body?: false}
    updated_trace_display = TraceDisplay.render_body(trace_display)

    assert %TraceDisplay{render_body?: true} = updated_trace_display
  end
end
