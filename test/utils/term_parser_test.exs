defmodule LiveDebugger.Utils.TermParserTest do
  use ExUnit.Case, async: true

  alias LiveDebugger.Utils.TermParser

  defmodule TestStruct do
    defstruct [:field1, :field2]
  end

  describe "term_to_display_tree/1" do
    test "parses a string term" do
      term = "Hello, World!"

      expected = %{
        kind: "binary",
        children: nil,
        content: [%{text: "\"Hello, World!\"", color: "text-code-4"}],
        expanded_before: nil,
        expanded_after: nil
      }

      assert TermParser.term_to_display_tree(term) == expected
    end

    test "parses an atom term" do
      term = :hello

      expected = %{
        kind: "atom",
        children: nil,
        content: [%{text: ":hello", color: "text-code-1"}],
        expanded_before: nil,
        expanded_after: nil
      }

      assert TermParser.term_to_display_tree(term) == expected
    end

    test "parses a number term" do
      term = 42

      expected = %{
        kind: "number",
        children: nil,
        content: [%{text: "42", color: "text-code-1"}],
        expanded_before: nil,
        expanded_after: nil
      }

      assert TermParser.term_to_display_tree(term) == expected
    end

    test "parses a tuple term" do
      term = {:ok, "Hello"}

      expected = %{
        kind: "tuple",
        children: [
          %{
            kind: "atom",
            children: nil,
            content: [%{text: ":ok", color: "text-code-1"}, %{text: ",", color: "text-code-2"}],
            expanded_before: nil,
            expanded_after: nil
          },
          %{
            kind: "binary",
            children: nil,
            content: [%{text: "\"Hello\"", color: "text-code-4"}],
            expanded_before: nil,
            expanded_after: nil
          }
        ],
        content: [%{text: "{...}", color: "text-code-2"}],
        expanded_before: [%{text: "{", color: "text-code-2"}],
        expanded_after: [%{text: "}", color: "text-code-2"}]
      }

      assert TermParser.term_to_display_tree(term) == expected
    end

    test "parses empty tuple term" do
      term = {}

      expected = %{
        kind: "tuple",
        children: nil,
        content: [%{text: "{}", color: "text-code-2"}],
        expanded_before: nil,
        expanded_after: nil
      }

      assert TermParser.term_to_display_tree(term) == expected
    end

    test "parses a list term" do
      term = [1, 2, 3]

      expected = %{
        kind: "list",
        children: [
          %{
            kind: "number",
            children: nil,
            content: [%{text: "1", color: "text-code-1"}, %{text: ",", color: "text-code-2"}],
            expanded_before: nil,
            expanded_after: nil
          },
          %{
            kind: "number",
            children: nil,
            content: [%{text: "2", color: "text-code-1"}, %{text: ",", color: "text-code-2"}],
            expanded_before: nil,
            expanded_after: nil
          },
          %{
            kind: "number",
            children: nil,
            content: [%{text: "3", color: "text-code-1"}],
            expanded_before: nil,
            expanded_after: nil
          }
        ],
        content: [%{text: "[...]", color: "text-code-2"}],
        expanded_before: [%{text: "[", color: "text-code-2"}],
        expanded_after: [%{text: "]", color: "text-code-2"}]
      }

      assert TermParser.term_to_display_tree(term) == expected
    end

    test "parses empty list term" do
      term = []

      expected = %{
        kind: "list",
        children: nil,
        content: [%{text: "[]", color: "text-code-2"}],
        expanded_before: nil,
        expanded_after: nil
      }

      assert TermParser.term_to_display_tree(term) == expected
    end

    test "parses regex term" do
      term = ~r/hello/

      expected = %{
        kind: "regex",
        children: nil,
        content: [%{text: "~r/hello/", color: "text-code-2"}],
        expanded_before: nil,
        expanded_after: nil
      }

      assert TermParser.term_to_display_tree(term) == expected
    end

    test "parses constant terms" do
      terms = [nil, true, false]

      Enum.map(terms, fn term ->
        expected = %{
          kind: "atom",
          children: nil,
          content: [%{text: inspect(term), color: "text-code-3"}],
          expanded_before: nil,
          expanded_after: nil
        }

        assert TermParser.term_to_display_tree(term) == expected
      end)
    end

    test "parses empty map term" do
      term = %{}

      expected = %{
        kind: "map",
        children: nil,
        content: [%{text: "%{}", color: "text-code-2"}],
        expanded_before: nil,
        expanded_after: nil
      }

      assert TermParser.term_to_display_tree(term) == expected
    end

    test "parses struct without `Inspect.Any` implementation" do
      term = %TestStruct{field1: "value1", field2: 42}

      "Elixir." <> struct_name = __MODULE__.TestStruct |> Atom.to_string()

      expected = %{
        kind: "struct",
        children: [
          %{
            kind: "binary",
            children: nil,
            content: [
              %{text: "field1:", color: "text-code-1"},
              %{text: " ", color: "text-code-2"},
              %{text: "\"value1\"", color: "text-code-4"},
              %{text: ",", color: "text-code-2"}
            ],
            expanded_before: nil,
            expanded_after: nil
          },
          %{
            kind: "number",
            children: nil,
            content: [
              %{text: "field2:", color: "text-code-1"},
              %{text: " ", color: "text-code-2"},
              %{text: "42", color: "text-code-1"}
            ],
            expanded_before: nil,
            expanded_after: nil
          }
        ],
        content: [
          %{color: "text-code-2", text: "%"},
          %{text: struct_name, color: "text-code-1"},
          %{text: "{...}", color: "text-code-2"}
        ],
        expanded_before: [
          %{text: "%", color: "text-code-2"},
          %{text: struct_name, color: "text-code-1"},
          %{text: "{", color: "text-code-2"}
        ],
        expanded_after: [%{text: "}", color: "text-code-2"}]
      }

      assert TermParser.term_to_display_tree(term) == expected
    end

    test "parses structs" do
      {:ok, term} = Date.new(2023, 5, 10)

      expected = %{
        children: [
          %{
            kind: "atom",
            children: nil,
            content: [
              %{text: "calendar:", color: "text-code-1"},
              %{text: " ", color: "text-code-2"},
              %{text: "Calendar.ISO", color: "text-code-1"},
              %{text: ",", color: "text-code-2"}
            ],
            expanded_before: nil,
            expanded_after: nil
          },
          %{
            kind: "number",
            children: nil,
            content: [
              %{text: "month:", color: "text-code-1"},
              %{text: " ", color: "text-code-2"},
              %{text: "5", color: "text-code-1"},
              %{text: ",", color: "text-code-2"}
            ],
            expanded_before: nil,
            expanded_after: nil
          },
          %{
            kind: "number",
            children: nil,
            content: [
              %{text: "day:", color: "text-code-1"},
              %{text: " ", color: "text-code-2"},
              %{text: "10", color: "text-code-1"},
              %{text: ",", color: "text-code-2"}
            ],
            expanded_before: nil,
            expanded_after: nil
          },
          %{
            kind: "number",
            children: nil,
            content: [
              %{text: "year:", color: "text-code-1"},
              %{text: " ", color: "text-code-2"},
              %{text: "2023", color: "text-code-1"}
            ],
            expanded_before: nil,
            expanded_after: nil
          }
        ],
        content: [%{color: "text-code-2", text: "~D[2023-05-10]"}],
        expanded_before: [
          %{text: "%", color: "text-code-2"},
          %{text: "Date", color: "text-code-1"},
          %{text: "{", color: "text-code-2"}
        ],
        expanded_after: [%{text: "}", color: "text-code-2"}],
        kind: "struct"
      }

      assert TermParser.term_to_display_tree(term) == expected
    end

    test "parses map terms" do
      term = %{
        "key1" => "value1",
        "key2" => 42,
        "key3" => :test
      }

      expected = %{
        kind: "map",
        children: [
          %{
            kind: "binary",
            children: nil,
            content: [
              %{text: "\"key1\"", color: "text-code-4"},
              %{text: " => ", color: "text-code-2"},
              %{text: "\"value1\"", color: "text-code-4"},
              %{text: ",", color: "text-code-2"}
            ],
            expanded_before: nil,
            expanded_after: nil
          },
          %{
            kind: "number",
            children: nil,
            content: [
              %{text: "\"key2\"", color: "text-code-4"},
              %{text: " => ", color: "text-code-2"},
              %{text: "42", color: "text-code-1"},
              %{text: ",", color: "text-code-2"}
            ],
            expanded_before: nil,
            expanded_after: nil
          },
          %{
            kind: "atom",
            children: nil,
            content: [
              %{text: "\"key3\"", color: "text-code-4"},
              %{text: " => ", color: "text-code-2"},
              %{text: ":test", color: "text-code-1"}
            ],
            expanded_before: nil,
            expanded_after: nil
          }
        ],
        content: [%{text: "%{...}", color: "text-code-2"}],
        expanded_before: [%{text: "%{", color: "text-code-2"}],
        expanded_after: [%{text: "}", color: "text-code-2"}]
      }

      assert TermParser.term_to_display_tree(term) == expected
    end
  end
end
