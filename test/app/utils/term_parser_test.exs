defmodule LiveDebugger.App.Utils.TermParserTest do
  use ExUnit.Case, async: true

  alias LiveDebugger.App.Utils.TermParser.DisplayElement
  alias LiveDebugger.App.Utils.TermParser.TermNode
  alias LiveDebugger.App.Utils.TermParser

  defmodule TestStruct do
    defstruct [:field1, :field2]
  end

  describe "term_to_display_tree/1" do
    test "parses a string term" do
      term = "Hello, World!"

      expected = %TermNode{
        id: "root",
        kind: :binary,
        children: [],
        content: [%DisplayElement{text: "\"Hello, World!\"", color: "text-code-4"}],
        expanded_before: nil,
        expanded_after: nil
      }

      assert TermParser.term_to_display_tree(term) == expected
    end

    test "parses an atom term" do
      term = :hello

      expected = %TermNode{
        id: "root",
        kind: :atom,
        children: [],
        content: [%DisplayElement{text: ":hello", color: "text-code-1"}],
        expanded_before: nil,
        expanded_after: nil
      }

      assert TermParser.term_to_display_tree(term) == expected
    end

    test "parses a number term" do
      term = 42

      expected = %TermNode{
        id: "root",
        kind: :number,
        children: [],
        content: [%DisplayElement{text: "42", color: "text-code-1"}],
        expanded_before: nil,
        expanded_after: nil
      }

      assert TermParser.term_to_display_tree(term) == expected
    end

    test "parses a tuple term" do
      term = {:ok, "Hello"}

      expected = %TermNode{
        id: "root",
        kind: :tuple,
        children: [
          %TermNode{
            id: "root.0",
            kind: :atom,
            children: [],
            content: [
              %DisplayElement{text: ":ok", color: "text-code-1"},
              %DisplayElement{text: ",", color: "text-code-2"}
            ],
            expanded_before: nil,
            expanded_after: nil
          },
          %TermNode{
            id: "root.1",
            kind: :binary,
            children: [],
            content: [%DisplayElement{text: "\"Hello\"", color: "text-code-4"}],
            expanded_before: nil,
            expanded_after: nil
          }
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
        children: [],
        content: [%DisplayElement{text: "{}", color: "text-code-2"}],
        expanded_before: nil,
        expanded_after: nil
      }

      assert TermParser.term_to_display_tree(term) == expected
    end

    test "parses a list term" do
      term = [1, 2, 3]

      expected = %TermNode{
        id: "root",
        kind: :list,
        children: [
          %TermNode{
            id: "root.0",
            kind: :number,
            children: [],
            content: [
              %DisplayElement{text: "1", color: "text-code-1"},
              %DisplayElement{text: ",", color: "text-code-2"}
            ],
            expanded_before: nil,
            expanded_after: nil
          },
          %TermNode{
            id: "root.1",
            kind: :number,
            children: [],
            content: [
              %DisplayElement{text: "2", color: "text-code-1"},
              %DisplayElement{text: ",", color: "text-code-2"}
            ],
            expanded_before: nil,
            expanded_after: nil
          },
          %TermNode{
            id: "root.2",
            kind: :number,
            children: [],
            content: [%DisplayElement{text: "3", color: "text-code-1"}],
            expanded_before: nil,
            expanded_after: nil
          }
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
        children: [],
        content: [%DisplayElement{text: "[]", color: "text-code-2"}],
        expanded_before: nil,
        expanded_after: nil
      }

      assert TermParser.term_to_display_tree(term) == expected
    end

    test "parses regex term" do
      term = ~r/hello/

      expected = %TermNode{
        id: "root",
        kind: :regex,
        children: [],
        content: [%DisplayElement{text: "~r/hello/", color: "text-code-2"}],
        expanded_before: nil,
        expanded_after: nil
      }

      assert TermParser.term_to_display_tree(term) == expected
    end

    test "parses constant terms" do
      terms = [nil, true, false]

      Enum.map(terms, fn term ->
        expected = %TermNode{
          id: "root",
          kind: :atom,
          children: [],
          content: [%DisplayElement{text: inspect(term), color: "text-code-3"}],
          expanded_before: nil,
          expanded_after: nil
        }

        assert TermParser.term_to_display_tree(term) == expected
      end)
    end

    test "parses empty map term" do
      term = %{}

      expected = %TermNode{
        id: "root",
        kind: :map,
        children: [],
        content: [%DisplayElement{text: "%{}", color: "text-code-2"}],
        expanded_before: nil,
        expanded_after: nil
      }

      assert TermParser.term_to_display_tree(term) == expected
    end

    test "parses struct without `Inspect.Any` implementation" do
      term = %TestStruct{field1: "value1", field2: 42}

      "Elixir." <> struct_name = __MODULE__.TestStruct |> Atom.to_string()

      expected = %TermNode{
        id: "root",
        kind: :struct,
        children: [
          %TermNode{
            id: "root.0",
            kind: :binary,
            children: [],
            content: [
              %DisplayElement{text: "field1:", color: "text-code-1"},
              %DisplayElement{text: " ", color: "text-code-2"},
              %DisplayElement{text: "\"value1\"", color: "text-code-4"},
              %DisplayElement{text: ",", color: "text-code-2"}
            ],
            expanded_before: nil,
            expanded_after: nil
          },
          %TermNode{
            id: "root.1",
            kind: :number,
            children: [],
            content: [
              %DisplayElement{text: "field2:", color: "text-code-1"},
              %DisplayElement{text: " ", color: "text-code-2"},
              %DisplayElement{text: "42", color: "text-code-1"}
            ],
            expanded_before: nil,
            expanded_after: nil
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
        children: [
          %TermNode{
            id: "root.0",
            kind: :atom,
            children: [],
            content: [
              %DisplayElement{text: "calendar:", color: "text-code-1"},
              %DisplayElement{text: " ", color: "text-code-2"},
              %DisplayElement{text: "Calendar.ISO", color: "text-code-1"},
              %DisplayElement{text: ",", color: "text-code-2"}
            ],
            expanded_before: nil,
            expanded_after: nil
          },
          %TermNode{
            id: "root.1",
            kind: :number,
            children: [],
            content: [
              %DisplayElement{text: "month:", color: "text-code-1"},
              %DisplayElement{text: " ", color: "text-code-2"},
              %DisplayElement{text: "5", color: "text-code-1"},
              %DisplayElement{text: ",", color: "text-code-2"}
            ],
            expanded_before: nil,
            expanded_after: nil
          },
          %TermNode{
            id: "root.2",
            kind: :number,
            children: [],
            content: [
              %DisplayElement{text: "day:", color: "text-code-1"},
              %DisplayElement{text: " ", color: "text-code-2"},
              %DisplayElement{text: "10", color: "text-code-1"},
              %DisplayElement{text: ",", color: "text-code-2"}
            ],
            expanded_before: nil,
            expanded_after: nil
          },
          %TermNode{
            id: "root.3",
            kind: :number,
            children: [],
            content: [
              %DisplayElement{text: "year:", color: "text-code-1"},
              %DisplayElement{text: " ", color: "text-code-2"},
              %DisplayElement{text: "2023", color: "text-code-1"}
            ],
            expanded_before: nil,
            expanded_after: nil
          }
        ],
        content: [%DisplayElement{text: "~D[2023-05-10]", color: "text-code-2"}],
        expanded_before: [
          %DisplayElement{text: "%", color: "text-code-2"},
          %DisplayElement{text: "Date", color: "text-code-1"},
          %DisplayElement{text: "{", color: "text-code-2"}
        ],
        expanded_after: [%DisplayElement{text: "}", color: "text-code-2"}],
        kind: :struct
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
        children: [
          %TermNode{
            id: "root.0",
            kind: :binary,
            children: [],
            content: [
              %DisplayElement{text: "\"key1\"", color: "text-code-4"},
              %DisplayElement{text: " => ", color: "text-code-2"},
              %DisplayElement{text: "\"value1\"", color: "text-code-4"},
              %DisplayElement{text: ",", color: "text-code-2"}
            ],
            expanded_before: nil,
            expanded_after: nil
          },
          %TermNode{
            id: "root.1",
            kind: :number,
            children: [],
            content: [
              %DisplayElement{text: "\"key2\"", color: "text-code-4"},
              %DisplayElement{text: " => ", color: "text-code-2"},
              %DisplayElement{text: "42", color: "text-code-1"},
              %DisplayElement{text: ",", color: "text-code-2"}
            ],
            expanded_before: nil,
            expanded_after: nil
          },
          %TermNode{
            id: "root.2",
            kind: :atom,
            children: [],
            content: [
              %DisplayElement{text: "\"key3\"", color: "text-code-4"},
              %DisplayElement{text: " => ", color: "text-code-2"},
              %DisplayElement{text: ":test", color: "text-code-1"}
            ],
            expanded_before: nil,
            expanded_after: nil
          }
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

      expected = %TermNode{
        id: "root",
        kind: :map,
        children: [
          %TermNode{
            id: "root.0",
            kind: :binary,
            children: [],
            content: [
              %DisplayElement{text: "{:ok, ~D[2025-07-08]}", color: "text-code-2"},
              %DisplayElement{text: " => ", color: "text-code-2"},
              %DisplayElement{text: "\"Date\"", color: "text-code-4"},
              %DisplayElement{text: ",", color: "text-code-2"}
            ],
            expanded_before: nil,
            expanded_after: nil
          },
          %TermNode{
            id: "root.1",
            kind: :binary,
            children: [],
            content: [
              %DisplayElement{text: "%Phoenix.LiveComponent.CID{cid: 1}", color: "text-code-1"},
              %DisplayElement{text: " => ", color: "text-code-2"},
              %DisplayElement{text: "\"CID\"", color: "text-code-4"}
            ],
            expanded_before: nil,
            expanded_after: nil
          }
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
end
