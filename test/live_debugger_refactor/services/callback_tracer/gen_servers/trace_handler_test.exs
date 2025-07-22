defmodule LiveDebuggerRefactor.Services.CallbackTracer.GenServers.TraceHandlerTest do
  use ExUnit.Case

  import Mox

  setup :verify_on_exit!
  setup :set_mox_from_context

  alias LiveDebuggerRefactor.Services.CallbackTracer.GenServers.TraceHandler
  alias LiveDebuggerRefactor.MockAPIDbg
  alias LiveDebuggerRefactor.MockAPIModule

  describe "handle_cast/2" do
    test "handles compiler traces" do
      pid = :c.pid(0, 1, 0)

      MockAPIDbg
      |> expect(:trace_pattern, 19, fn _, _ -> :ok end)

      MockAPIModule
      |> expect(:all, fn -> [{~c"Debugged.TestModule", ~c"delete_component", true}] end)
      |> expect(:loaded?, fn _ -> true end)
      |> expect(:behaviours, 2, fn _ -> [Phoenix.LiveView] end)

      trace =
        {:new_trace,
         {:trace_ts, pid, :return_from, {Mix.Tasks.Compile.Elixir, :run, 1}, {:ok, []},
          {1753, 174_270, 660_820}}, -1}

      assert TraceHandler.handle_cast(trace, nil) == {:noreply, nil}

      Process.sleep(500)
    end
  end
end
