defmodule LiveDebugger.Services.CallbackTracer.Queries.PathsTest do
  use ExUnit.Case, async: true

  import Mox

  alias LiveDebugger.Services.CallbackTracer.Queries.Paths
  alias LiveDebugger.MockAPIModule

  setup :verify_on_exit!

  describe "compiled_modules_directories/0" do
    test "returns directories for LiveView and LiveComponent modules" do
      MockAPIModule
      |> expect(:all, fn ->
        [
          {~c"Test.LiveViewModule", ~c"/app/lib/test/live_view.beam", true},
          {~c"Test.LiveComponentModule", ~c"/app/lib/test/live_component.beam", true}
        ]
      end)
      |> stub(:loaded?, fn _ -> true end)
      |> stub(:live_module?, fn _ -> true end)

      assert Paths.compiled_modules_directories() == ["/app/lib/test"]
    end

    test "returns empty list when no modules are available" do
      MockAPIModule
      |> expect(:all, fn -> [] end)

      assert Paths.compiled_modules_directories() == []
    end

    test "filters out debugger modules" do
      MockAPIModule
      |> expect(:all, fn ->
        [
          {~c"LiveDebugger.TestModule", ~c"/app/lib/live_debugger/test.beam", true},
          {~c"LiveDebugger.App.Web.TestModule", ~c"/app/lib/live_debugger/app.beam", true},
          {~c"Elixir.LiveDebugger.TestModule", ~c"/app/lib/debugger/test.beam", true}
        ]
      end)
      |> stub(:loaded?, fn _ -> true end)
      |> stub(:live_module?, fn _ -> true end)

      assert Paths.compiled_modules_directories() == []
    end

    test "filters out unloaded modules" do
      MockAPIModule
      |> expect(:all, fn ->
        [
          {~c"Test.LiveViewModule", ~c"/app/lib/test/live_view.beam", true},
          {~c"Test.UnloadedModule", ~c"/app/lib/test/unloaded.beam", false}
        ]
      end)
      |> stub(:loaded?, fn module ->
        case module do
          :"Test.LiveViewModule" -> true
          :"Test.UnloadedModule" -> false
        end
      end)
      |> stub(:live_module?, fn _ -> true end)

      assert Paths.compiled_modules_directories() == ["/app/lib/test"]
    end

    test "filters out non-live modules" do
      MockAPIModule
      |> expect(:all, fn ->
        [
          {~c"Test.LiveViewModule", ~c"/app/lib/live/module.beam", true},
          {~c"Test.RegularModule", ~c"/app/lib/regular/module.beam", true}
        ]
      end)
      |> stub(:loaded?, fn _ -> true end)
      |> stub(:live_module?, fn module ->
        case module do
          :"Test.LiveViewModule" -> true
          :"Test.RegularModule" -> false
        end
      end)

      assert Paths.compiled_modules_directories() == ["/app/lib/live"]
    end

    test "returns multiple unique directories" do
      MockAPIModule
      |> expect(:all, fn ->
        [
          {~c"Test.LiveViewModule", ~c"/app/lib/views/module.beam", true},
          {~c"Test.LiveComponentModule", ~c"/app/lib/components/component.beam", true},
          {~c"Test.AnotherLiveView", ~c"/app/lib/views/another.beam", true}
        ]
      end)
      |> stub(:loaded?, fn _ -> true end)
      |> stub(:live_module?, fn _ -> true end)

      result = Paths.compiled_modules_directories()

      assert length(result) == 2
      assert "/app/lib/views" in result
      assert "/app/lib/components" in result
    end
  end
end
