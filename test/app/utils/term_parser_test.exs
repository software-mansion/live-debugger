defmodule LiveDebugger.App.Utils.TermParserTest do
  use ExUnit.Case, async: true

  alias LiveDebugger.App.Utils.TermNode
  alias LiveDebugger.App.Utils.TermNode.DisplayElement
  alias LiveDebugger.App.Utils.TermParser
  alias LiveDebugger.Fakes

  defmodule TestStruct do
    defstruct [:field1, :field2]
  end

  describe "term_to_display_tree/1" do
    test "parses a string term" do
      term = "Hello, World!"

      expected = %TermNode{
        id: "root",
        kind: :binary,
        open?: true,
        children: [],
        content: [%DisplayElement{text: "\"Hello, World!\"", color: "text-code-4"}],
        expanded_before: [],
        expanded_after: []
      }

      assert TermParser.term_to_display_tree(term) == expected
    end

    test "parses an atom term" do
      term = :hello

      expected = %TermNode{
        id: "root",
        kind: :atom,
        open?: true,
        children: [],
        content: [%DisplayElement{text: ":hello", color: "text-code-1"}],
        expanded_before: [],
        expanded_after: []
      }

      assert TermParser.term_to_display_tree(term) == expected
    end

    test "parses a number term" do
      term = 42

      expected = %TermNode{
        id: "root",
        kind: :number,
        open?: true,
        children: [],
        content: [%DisplayElement{text: "42", color: "text-code-1"}],
        expanded_before: [],
        expanded_after: []
      }

      assert TermParser.term_to_display_tree(term) == expected
    end

    test "parses a tuple term" do
      term = {:ok, "Hello"}

      expected = %TermNode{
        id: "root",
        kind: :tuple,
        open?: true,
        children: [
          {0,
           %TermNode{
             id: "root.0",
             kind: :atom,
             open?: false,
             children: [],
             content: [
               %DisplayElement{text: ":ok", color: "text-code-1"},
               %DisplayElement{text: ",", color: "text-code-2"}
             ],
             expanded_before: [],
             expanded_after: [%DisplayElement{text: ",", color: "text-code-2"}]
           }},
          {1,
           %TermNode{
             id: "root.1",
             kind: :binary,
             open?: false,
             children: [],
             content: [%DisplayElement{text: "\"Hello\"", color: "text-code-4"}],
             expanded_before: [],
             expanded_after: []
           }}
        ],
        content: [%DisplayElement{text: "{...}", color: "text-code-2"}],
        expanded_before: [%DisplayElement{text: "{", color: "text-code-2"}],
        expanded_after: [%DisplayElement{text: "}", color: "text-code-2"}]
      }

      assert TermParser.term_to_display_tree(term) == expected
    end

    test "parses empty tuple term" do
      term = {}

      expected = %TermNode{
        id: "root",
        kind: :tuple,
        open?: true,
        children: [],
        content: [%DisplayElement{text: "{}", color: "text-code-2"}],
        expanded_before: [],
        expanded_after: []
      }

      assert TermParser.term_to_display_tree(term) == expected
    end

    test "parses a list term" do
      term = [1, 2, 3]

      expected = %TermNode{
        id: "root",
        kind: :list,
        open?: true,
        children: [
          {0,
           %TermNode{
             id: "root.0",
             kind: :number,
             open?: false,
             children: [],
             content: [
               %DisplayElement{text: "1", color: "text-code-1"},
               %DisplayElement{text: ",", color: "text-code-2"}
             ],
             expanded_before: [],
             expanded_after: [%DisplayElement{text: ",", color: "text-code-2"}]
           }},
          {1,
           %TermNode{
             id: "root.1",
             kind: :number,
             open?: false,
             children: [],
             content: [
               %DisplayElement{text: "2", color: "text-code-1"},
               %DisplayElement{text: ",", color: "text-code-2"}
             ],
             expanded_before: [],
             expanded_after: [%DisplayElement{text: ",", color: "text-code-2"}]
           }},
          {2,
           %TermNode{
             id: "root.2",
             kind: :number,
             open?: false,
             children: [],
             content: [%DisplayElement{text: "3", color: "text-code-1"}],
             expanded_before: [],
             expanded_after: []
           }}
        ],
        content: [%DisplayElement{text: "[...]", color: "text-code-2"}],
        expanded_before: [%DisplayElement{text: "[", color: "text-code-2"}],
        expanded_after: [%DisplayElement{text: "]", color: "text-code-2"}]
      }

      assert TermParser.term_to_display_tree(term) == expected
    end

    test "parses empty list term" do
      term = []

      expected = %TermNode{
        id: "root",
        kind: :list,
        open?: true,
        children: [],
        content: [%DisplayElement{text: "[]", color: "text-code-2"}],
        expanded_before: [],
        expanded_after: []
      }

      assert TermParser.term_to_display_tree(term) == expected
    end

    test "parses regex term" do
      term = ~r/hello/

      expected = %TermNode{
        id: "root",
        kind: :regex,
        open?: true,
        children: [],
        content: [%DisplayElement{text: "~r/hello/", color: "text-code-2"}],
        expanded_before: [],
        expanded_after: []
      }

      assert TermParser.term_to_display_tree(term) == expected
    end

    test "parses constant terms" do
      terms = [nil, true, false]

      Enum.map(terms, fn term ->
        expected = %TermNode{
          id: "root",
          kind: :atom,
          open?: true,
          children: [],
          content: [%DisplayElement{text: inspect(term), color: "text-code-3"}],
          expanded_before: [],
          expanded_after: []
        }

        assert TermParser.term_to_display_tree(term) == expected
      end)
    end

    test "parses empty map term" do
      term = %{}

      expected = %TermNode{
        id: "root",
        kind: :map,
        open?: true,
        children: [],
        content: [%DisplayElement{text: "%{}", color: "text-code-2"}],
        expanded_before: [],
        expanded_after: []
      }

      assert TermParser.term_to_display_tree(term) == expected
    end

    test "parses struct without `Inspect.Any` implementation" do
      term = %TestStruct{field1: "value1", field2: 42}

      "Elixir." <> struct_name = __MODULE__.TestStruct |> Atom.to_string()

      expected = %TermNode{
        id: "root",
        kind: :struct,
        open?: true,
        children: [
          field1: %TermNode{
            id: "root.0",
            kind: :binary,
            open?: false,
            children: [],
            content: [
              %DisplayElement{text: "field1:", color: "text-code-1"},
              %DisplayElement{text: " ", color: "text-code-2"},
              %DisplayElement{text: "\"value1\"", color: "text-code-4"},
              %DisplayElement{text: ",", color: "text-code-2"}
            ],
            expanded_before: [
              %DisplayElement{text: "field1:", color: "text-code-1"},
              %DisplayElement{text: " ", color: "text-code-2"}
            ],
            expanded_after: [%DisplayElement{text: ",", color: "text-code-2"}]
          },
          field2: %TermNode{
            id: "root.1",
            kind: :number,
            open?: false,
            children: [],
            content: [
              %DisplayElement{text: "field2:", color: "text-code-1"},
              %DisplayElement{text: " ", color: "text-code-2"},
              %DisplayElement{text: "42", color: "text-code-1"}
            ],
            expanded_before: [
              %DisplayElement{text: "field2:", color: "text-code-1"},
              %DisplayElement{text: " ", color: "text-code-2"}
            ],
            expanded_after: []
          }
        ],
        content: [
          %DisplayElement{text: "%", color: "text-code-2"},
          %DisplayElement{text: struct_name, color: "text-code-1"},
          %DisplayElement{text: "{...}", color: "text-code-2"}
        ],
        expanded_before: [
          %DisplayElement{text: "%", color: "text-code-2"},
          %DisplayElement{text: struct_name, color: "text-code-1"},
          %DisplayElement{text: "{", color: "text-code-2"}
        ],
        expanded_after: [%DisplayElement{text: "}", color: "text-code-2"}]
      }

      assert TermParser.term_to_display_tree(term) == expected
    end

    test "parses structs" do
      {:ok, term} = Date.new(2023, 5, 10)

      expected = %TermNode{
        id: "root",
        kind: :struct,
        open?: true,
        children: [
          calendar: %TermNode{
            id: "root.0",
            kind: :atom,
            open?: false,
            children: [],
            content: [
              %DisplayElement{text: "calendar:", color: "text-code-1"},
              %DisplayElement{text: " ", color: "text-code-2"},
              %DisplayElement{text: "Calendar.ISO", color: "text-code-1"},
              %DisplayElement{text: ",", color: "text-code-2"}
            ],
            expanded_before: [
              %DisplayElement{text: "calendar:", color: "text-code-1"},
              %DisplayElement{text: " ", color: "text-code-2"}
            ],
            expanded_after: [%DisplayElement{text: ",", color: "text-code-2"}]
          },
          month: %TermNode{
            id: "root.1",
            kind: :number,
            open?: false,
            children: [],
            content: [
              %DisplayElement{text: "month:", color: "text-code-1"},
              %DisplayElement{text: " ", color: "text-code-2"},
              %DisplayElement{text: "5", color: "text-code-1"},
              %DisplayElement{text: ",", color: "text-code-2"}
            ],
            expanded_before: [
              %DisplayElement{text: "month:", color: "text-code-1"},
              %DisplayElement{text: " ", color: "text-code-2"}
            ],
            expanded_after: [%DisplayElement{text: ",", color: "text-code-2"}]
          },
          day: %TermNode{
            id: "root.2",
            kind: :number,
            open?: false,
            children: [],
            content: [
              %DisplayElement{text: "day:", color: "text-code-1"},
              %DisplayElement{text: " ", color: "text-code-2"},
              %DisplayElement{text: "10", color: "text-code-1"},
              %DisplayElement{text: ",", color: "text-code-2"}
            ],
            expanded_before: [
              %DisplayElement{text: "day:", color: "text-code-1"},
              %DisplayElement{text: " ", color: "text-code-2"}
            ],
            expanded_after: [%DisplayElement{text: ",", color: "text-code-2"}]
          },
          year: %TermNode{
            id: "root.3",
            kind: :number,
            open?: false,
            children: [],
            content: [
              %DisplayElement{text: "year:", color: "text-code-1"},
              %DisplayElement{text: " ", color: "text-code-2"},
              %DisplayElement{text: "2023", color: "text-code-1"}
            ],
            expanded_before: [
              %DisplayElement{text: "year:", color: "text-code-1"},
              %DisplayElement{text: " ", color: "text-code-2"}
            ],
            expanded_after: []
          }
        ],
        content: [%DisplayElement{text: "~D[2023-05-10]", color: "text-code-2"}],
        expanded_before: [
          %DisplayElement{text: "%", color: "text-code-2"},
          %DisplayElement{text: "Date", color: "text-code-1"},
          %DisplayElement{text: "{", color: "text-code-2"}
        ],
        expanded_after: [%DisplayElement{text: "}", color: "text-code-2"}]
      }

      assert TermParser.term_to_display_tree(term) == expected
    end

    test "parses map terms" do
      term = %{
        "key1" => "value1",
        "key2" => 42,
        "key3" => :test
      }

      expected = %TermNode{
        id: "root",
        kind: :map,
        open?: true,
        children: [
          {"key1",
           %TermNode{
             id: "root.0",
             kind: :binary,
             open?: false,
             children: [],
             content: [
               %DisplayElement{text: "\"key1\"", color: "text-code-4"},
               %DisplayElement{text: " => ", color: "text-code-2"},
               %DisplayElement{text: "\"value1\"", color: "text-code-4"},
               %DisplayElement{text: ",", color: "text-code-2"}
             ],
             expanded_before: [
               %DisplayElement{text: "\"key1\"", color: "text-code-4"},
               %DisplayElement{text: " => ", color: "text-code-2"}
             ],
             expanded_after: [%DisplayElement{text: ",", color: "text-code-2"}]
           }},
          {"key2",
           %TermNode{
             id: "root.1",
             kind: :number,
             open?: false,
             children: [],
             content: [
               %DisplayElement{text: "\"key2\"", color: "text-code-4"},
               %DisplayElement{text: " => ", color: "text-code-2"},
               %DisplayElement{text: "42", color: "text-code-1"},
               %DisplayElement{text: ",", color: "text-code-2"}
             ],
             expanded_before: [
               %DisplayElement{text: "\"key2\"", color: "text-code-4"},
               %DisplayElement{text: " => ", color: "text-code-2"}
             ],
             expanded_after: [%DisplayElement{text: ",", color: "text-code-2"}]
           }},
          {"key3",
           %TermNode{
             id: "root.2",
             kind: :atom,
             open?: false,
             children: [],
             content: [
               %DisplayElement{text: "\"key3\"", color: "text-code-4"},
               %DisplayElement{text: " => ", color: "text-code-2"},
               %DisplayElement{text: ":test", color: "text-code-1"}
             ],
             expanded_before: [
               %DisplayElement{text: "\"key3\"", color: "text-code-4"},
               %DisplayElement{text: " => ", color: "text-code-2"}
             ],
             expanded_after: []
           }}
        ],
        content: [%DisplayElement{text: "%{...}", color: "text-code-2"}],
        expanded_before: [%DisplayElement{text: "%{", color: "text-code-2"}],
        expanded_after: [%DisplayElement{text: "}", color: "text-code-2"}]
      }

      assert TermParser.term_to_display_tree(term) == expected
    end

    test "parses map with struct keys correctly" do
      term = %{
        %Phoenix.LiveComponent.CID{cid: 1} => "CID",
        Date.new(2025, 7, 8) => "Date"
      }

      {{:ok, date}, cid} = {Date.new(2025, 7, 8), %Phoenix.LiveComponent.CID{cid: 1}}

      expected = %TermNode{
        id: "root",
        kind: :map,
        open?: true,
        children: [
          {{:ok, date},
           %TermNode{
             id: "root.0",
             kind: :binary,
             open?: false,
             children: [],
             content: [
               %DisplayElement{text: "{:ok, ~D[2025-07-08]}", color: "text-code-2"},
               %DisplayElement{text: " => ", color: "text-code-2"},
               %DisplayElement{text: "\"Date\"", color: "text-code-4"},
               %DisplayElement{text: ",", color: "text-code-2"}
             ],
             expanded_before: [
               %DisplayElement{text: "{:ok, ~D[2025-07-08]}", color: "text-code-2"},
               %DisplayElement{text: " => ", color: "text-code-2"}
             ],
             expanded_after: [%DisplayElement{text: ",", color: "text-code-2"}]
           }},
          {cid,
           %TermNode{
             id: "root.1",
             kind: :binary,
             open?: false,
             children: [],
             content: [
               %DisplayElement{text: "%Phoenix.LiveComponent.CID{cid: 1}", color: "text-code-1"},
               %DisplayElement{text: " => ", color: "text-code-2"},
               %DisplayElement{text: "\"CID\"", color: "text-code-4"}
             ],
             expanded_before: [
               %DisplayElement{text: "%Phoenix.LiveComponent.CID{cid: 1}", color: "text-code-1"},
               %DisplayElement{text: " => ", color: "text-code-2"}
             ],
             expanded_after: []
           }}
        ],
        content: [%DisplayElement{text: "%{...}", color: "text-code-2"}],
        expanded_before: [%DisplayElement{text: "%{", color: "text-code-2"}],
        expanded_after: [%DisplayElement{text: "}", color: "text-code-2"}]
      }

      assert TermParser.term_to_display_tree(term) == expected
    end
  end

  describe "term_to_copy_string/1" do
    test "converts sample assigns to copyable string" do
      assigns = %{
        list: [
          %Phoenix.LiveComponent.CID{cid: 1},
          %Phoenix.LiveComponent.CID{cid: 2}
        ],
        name: "Charlie",
        counter: 0,
        __changed__: %{},
        flash: %{},
        counter_very_slow: 0,
        counter_slow: 0,
        datetime: ~U[2025-06-06 12:33:27.641576Z],
        single_element_list: [%Phoenix.LiveComponent.CID{cid: 1}],
        long_assign:
          "Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.",
        live_action: nil
      }

      assert TermParser.term_to_copy_string(assigns) ==
               inspect(assigns, limit: :infinity, pretty: true, structs: false)
    end

    test "converts a term with a PID to copyable string" do
      term = %{
        pid: :c.pid(0, 123, 0)
      }

      assert TermParser.term_to_copy_string(term) ==
               "%{pid: :erlang.list_to_pid(~c\"<0.123.0>\")}"
    end
  end

  describe "update_by_id/3" do
    test "updates root node" do
      term_node = Fakes.term_node(id: "root", open?: true)

      assert {:ok, %TermNode{open?: false}} =
               TermParser.update_by_id(term_node, "root", &close_term_node/1)
    end

    test "updates child node" do
      child = Fakes.term_node(id: "root.0", open?: true)
      term_node = Fakes.term_node(id: "root", open?: true, children: [{0, child}])

      assert {:ok, %TermNode{open?: true, children: [{0, %TermNode{open?: false}}]}} =
               TermParser.update_by_id(term_node, "root.0", &close_term_node/1)
    end

    test "returns error if the term node is not found" do
      term_node = Fakes.term_node(id: "root", open?: true)

      assert {:error, :child_not_found} =
               TermParser.update_by_id(term_node, "root.1", &close_term_node/1)
    end
  end

  describe "update_by_diff/2" do
    test "doesn't update if type is equal" do
    end

    test "updates nested elements" do
    end

    test "properly adds suffixes" do
    end

    test "properly opens lists and tuples within default limits" do
    end

    test "returns error if the term node and diff are not complatible" do
    end
  end

  defp close_term_node(term_node) do
    %TermNode{term_node | open?: false}
  end
end
