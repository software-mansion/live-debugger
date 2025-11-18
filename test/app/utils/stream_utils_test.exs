defmodule LiveDebugger.App.Utils.StreamUtilsTest do
  use ExUnit.Case

  alias LiveDebugger.App.Debugger.Streams.StreamUtils

  defmodule DummyStream do
    def dummy_stream_config_function(id) do
      "#{id}-dummy"
    end
  end

  describe "extract_stream_traces/1" do
    test "extracts traces correctly" do
      traces = [
        %{
          timestamp: 1,
          args: [
            %{
              streams: %{
                items: %Phoenix.LiveView.LiveStream{
                  name: :items,
                  inserts: [{"id-1", 0, %{id: 1}, nil, false}],
                  deletes: ["id-1"],
                  reset?: false,
                  consumable?: false
                },
                __configured__: %{
                  items: [dom_id: &DummyStream.dummy_stream_config_function/1]
                }
              }
            }
          ]
        }
      ]

      stream_entries = StreamUtils.extract_stream_traces(traces)
      assert length(stream_entries) == 1

      first_entry = hd(stream_entries)
      assert Map.has_key?(first_entry, :items)

      assert first_entry[:__configured__][:items] == [
               dom_id: &DummyStream.dummy_stream_config_function/1
             ]
    end
  end

  describe "streams_names/1" do
    test "returns list of stream names" do
      stream_entries = [
        %{
          items: %Phoenix.LiveView.LiveStream{
            name: :items,
            inserts: [],
            deletes: [],
            reset?: false,
            consumable?: false
          },
          another_items: %Phoenix.LiveView.LiveStream{
            name: :another_items,
            inserts: [],
            deletes: [],
            reset?: false,
            consumable?: false
          },
          __configured__: %{}
        }
      ]

      names = StreamUtils.streams_names(stream_entries)
      assert Enum.sort(names) == [:another_items, :items]
    end
  end

  describe "streams_functions/2" do
    test "returns functions for inserts and deletes" do
      stream_entries = [
        %{
          items: %Phoenix.LiveView.LiveStream{
            name: :items,
            inserts: [{"id-1", 0, %{id: 1}, nil, false}],
            deletes: ["id-2"],
            reset?: false,
            consumable?: false
          },
          __configured__: %{}
        }
      ]

      names = StreamUtils.streams_names(stream_entries)
      funs = StreamUtils.streams_functions(stream_entries, names)
      assert is_list(funs)
      assert length(funs) == 1
    end
  end

  describe "streams_config/2" do
    test "returns config functions for streams" do
      stream_entries = [
        %{
          items: %Phoenix.LiveView.LiveStream{
            name: :items,
            inserts: [],
            deletes: [],
            reset?: false,
            consumable?: false
          },
          __configured__: %{
            items: [dom_id: &DummyStream.dummy_stream_config_function/1]
          }
        }
      ]

      names = StreamUtils.streams_names(stream_entries)
      config_funs = StreamUtils.streams_config(stream_entries, names)

      assert is_list(config_funs)
      {module, name, dom_id_fun} = extract_info_from_config_fun(hd(config_funs))
      assert module == LiveDebugger.App.Debugger.Streams.StreamUtils
      assert String.contains?(name, "maybe_add_config")
      assert dom_id_fun == (&DummyStream.dummy_stream_config_function/1)
    end
  end

  defp extract_info_from_config_fun(config_fun) do
    info = :erlang.fun_info(config_fun)
    env = Enum.at(info[:env], 0)
    dom_id_fun = Keyword.fetch!(env, :dom_id)
    module = info[:module]
    name = Atom.to_string(info[:name])
    {module, name, dom_id_fun}
  end
end
