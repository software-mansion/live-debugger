defmodule LiveDebugger.Structs.TraceDisplayTest do
  use ExUnit.Case, async: true

  alias LiveDebugger.Structs.TraceDisplay
  alias LiveDebugger.Fakes

  test "from_trace/1 creates a TraceDisplay struct" do
    trace = Fakes.trace()
    trace_display = TraceDisplay.from_trace(trace)

    assert %TraceDisplay{id: 1, trace: ^trace, render_body?: false} = trace_display
  end

  test "render_body/1 sets render_body? to true" do
    trace_display = %TraceDisplay{
      id: 1,
      trace: Fakes.trace(),
      render_body?: false,
      counter: 0
    }

    updated_trace_display = TraceDisplay.render_body(trace_display)

    assert %TraceDisplay{render_body?: true} = updated_trace_display
  end
end
