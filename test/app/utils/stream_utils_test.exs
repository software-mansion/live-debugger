defmodule LiveDebugger.App.Utils.StreamUtilsTest do
  use ExUnit.Case

  alias LiveDebugger.App.Debugger.NodeState.StreamUtils

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
      assert length(fun_list) == 0
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
      assert module == LiveDebugger.App.Debugger.NodeState.StreamUtils
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

      assert module == LiveDebugger.App.Debugger.NodeState.StreamUtils
      assert String.contains?(name, "maybe_add_config")
      assert dom_id_function == (&DummyStream.dummy_stream_config_function/1)

      assert length(fun_list) == 0
      assert stream_names == [:items]
    end

    test "returns correct funs with reset" do
      stream = %Phoenix.LiveView.LiveStream{
        name: :items,
        inserts: [],
        deletes: [],
        reset?: true,
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
                     __configured__: %{}
                   }
                 }
               ]
             }
           ], nil}
        )

      assert is_list(fun_list)
      assert is_list(config_list)

      {module, name} = extract_info_from_diff_fun(Enum.at(fun_list, 0))

      assert module == LiveDebugger.App.Debugger.NodeState.StreamUtils
      assert String.contains?(name, "maybe_add_reset")

      assert length(fun_list) == 0
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

      updates = [%{things: stream, __configured__: %{}}]

      {fun_list, config_list, stream_names} =
        StreamUtils.get_stream_functions_from_updates(updates)

      assert is_list(fun_list)
      assert is_list(config_list)
      assert length(fun_list) == 2
      assert stream_names == [:things]
    end

    test "returns correct fun and preserves configured lambda" do
      stream = %Phoenix.LiveView.LiveStream{
        name: :things,
        inserts: [{"id-2", 0, %{id: 2}, nil, false}],
        deletes: ["id-1"],
        reset?: false,
        consumable?: false
      }

      updates = [
        %{
          things: stream,
          __configured__: %{
            things: [
              dom_id: &DummyStream.dummy_stream_config_function/1
            ]
          }
        }
      ]

      {fun_list, config_list, stream_names} =
        StreamUtils.get_stream_functions_from_updates(updates)

      assert is_list(fun_list)
      assert is_list(config_list)
      {module, name, dom_id_function} = extract_info_from_config_fun(Enum.at(config_list, 0))

      assert module == LiveDebugger.App.Debugger.NodeState.StreamUtils
      assert String.contains?(name, "maybe_add_config")
      assert dom_id_function == (&DummyStream.dummy_stream_config_function/1)

      assert length(fun_list) == 2
      assert stream_names == [:things]
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
