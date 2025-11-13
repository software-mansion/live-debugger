defmodule LiveDebugger.App.Utils.StreamUtilsTest do
  use ExUnit.Case

  alias LiveDebugger.App.Debugger.Streams.StreamUtils

  defmodule DummyStream do
    defstruct [:name, :inserts, :deletes, :reset?, :consumable?]

    def dummy_stream_config_function(id) do
      "#{id}-dummy"
    end
  end

  describe "get_initial_stream_functions/1" do
    test "reduces inserts and deletes correctly" do
      stream = %Phoenix.LiveView.LiveStream{
        name: :items,
        inserts: [{"id-1", 0, %{id: 1}, nil, false}],
        deletes: ["id-1"],
        reset?: false,
        consumable?: false
      }

      {fun_list, config_list, stream_names} =
        StreamUtils.get_initial_stream_functions(
          {[%{timestamp: 1, args: [%{streams: %{items: stream, __configured__: %{}}}]}], nil}
        )

      assert is_list(fun_list)
      assert is_list(config_list)
      assert fun_list == []
      assert stream_names == [:items]
    end

    test "returns only inserts funs when stream contains inserts and deletes" do
      stream = %Phoenix.LiveView.LiveStream{
        name: :items,
        inserts: [{"id-1", 0, %{id: 1}, nil, false}],
        deletes: ["id-2"],
        reset?: false,
        consumable?: false
      }

      {fun_list, config_list, stream_names} =
        StreamUtils.get_initial_stream_functions(
          {[%{timestamp: 1, args: [%{streams: %{items: stream, __configured__: %{}}}]}], nil}
        )

      assert is_list(fun_list)

      {module, name} = extract_info_from_diff_fun(Enum.at(fun_list, 0))
      assert module == LiveDebugger.App.Debugger.Streams.StreamUtils
      assert String.contains?(name, "create_insert_functions")
      assert is_list(config_list)
      assert length(fun_list) == 1
      assert stream_names == [:items]
    end

    test "returns correct funs and preserves configured lambda" do
      stream = %Phoenix.LiveView.LiveStream{
        name: :items,
        inserts: [{"id-1", 0, %{id: 1}, nil, false}],
        deletes: ["id-1"],
        reset?: false,
        consumable?: false
      }

      {fun_list, config_list, stream_names} =
        StreamUtils.get_initial_stream_functions(
          {[
             %{
               timestamp: 1,
               args: [
                 %{
                   streams: %{
                     items: stream,
                     __configured__: %{
                       items: [
                         dom_id: &DummyStream.dummy_stream_config_function/1
                       ]
                     }
                   }
                 }
               ]
             }
           ], nil}
        )

      assert is_list(fun_list)
      assert is_list(config_list)

      {module, name, dom_id_function} = extract_info_from_config_fun(Enum.at(config_list, 0))

      assert module == LiveDebugger.App.Debugger.Streams.StreamUtils
      assert String.contains?(name, "maybe_add_config")
      assert dom_id_function == (&DummyStream.dummy_stream_config_function/1)

      assert fun_list == []
      assert stream_names == [:items]
    end
  end

  describe "get_stream_functions_from_updates/1" do
    test "returns correct funs and stream names for simple update" do
      stream = %Phoenix.LiveView.LiveStream{
        name: :things,
        inserts: [{"id-2", 0, %{id: 2}, nil, false}],
        deletes: ["id-1"],
        reset?: false,
        consumable?: false
      }

      {fun_list, config_list, stream_name} =
        StreamUtils.get_stream_functions_from_updates(stream, [])

      assert is_list(fun_list)
      assert is_list(config_list)
      assert length(fun_list) == 2
      assert stream_name == :things
    end

    test "returns correct fun and preserves configured lambda" do
      stream = %Phoenix.LiveView.LiveStream{
        name: :things,
        inserts: [{"id-2", 0, %{id: 2}, nil, false}],
        deletes: ["id-1"],
        reset?: false,
        consumable?: false
      }

      {fun_list, config_list, stream_name} =
        StreamUtils.get_stream_functions_from_updates(stream,
          dom_id_fun: &DummyStream.dummy_stream_config_function/1
        )

      assert is_list(fun_list)
      assert is_list(config_list)
      {module, name, dom_id_function} = extract_info_from_config_fun(Enum.at(config_list, 0))

      assert module == LiveDebugger.App.Debugger.Streams.StreamUtils
      assert String.contains?(name, "maybe_add_config")

      assert dom_id_function == [
               dom_id_fun:
                 &LiveDebugger.App.Utils.StreamUtilsTest.DummyStream.dummy_stream_config_function/1
             ]

      assert length(fun_list) == 2
      assert stream_name == :things
    end

    test "returns correct funs with reset diff" do
      stream = %Phoenix.LiveView.LiveStream{
        name: :items,
        inserts: [],
        deletes: [],
        reset?: true,
        consumable?: false
      }

      {fun_list, config_list, stream_name} =
        StreamUtils.get_stream_functions_from_updates(stream, [])

      assert is_list(fun_list)
      assert is_list(config_list)

      {module, name} = extract_info_from_diff_fun(Enum.at(fun_list, 0))

      assert module == LiveDebugger.App.Debugger.Streams.StreamUtils
      assert String.contains?(name, "maybe_add_reset")

      assert length(fun_list) == 1
      assert stream_name == :items
    end
  end

  defp extract_info_from_config_fun(config_fun) do
    info = :erlang.fun_info(config_fun)
    env = Enum.at(info[:env], 0)
    dom_id_function = Keyword.fetch!(env, :dom_id)
    module = info[:module]
    name = Atom.to_string(info[:name])
    {module, name, dom_id_function}
  end

  defp extract_info_from_diff_fun(diff_fun) do
    info = :erlang.fun_info(diff_fun)
    module = info[:module]
    name = Atom.to_string(info[:name])
    {module, name}
  end
end
