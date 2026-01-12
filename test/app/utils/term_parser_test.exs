defmodule LiveDebugger.App.Utils.TermParserTest do
  use ExUnit.Case, async: true

  alias LiveDebugger.App.Utils.TermNode
  alias LiveDebugger.App.Utils.TermNode.DisplayElement
  alias LiveDebugger.App.Utils.TermParser
  alias LiveDebugger.App.Utils.TermDiffer
  alias LiveDebugger.App.Utils.TermDiffer.Diff
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
        expanded_before: [%DisplayElement{text: "{", color: "text-code-2"}],
        expanded_after: [%DisplayElement{text: "}", color: "text-code-2"}]
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
        expanded_before: [%DisplayElement{text: "[", color: "text-code-2"}],
        expanded_after: [%DisplayElement{text: "]", color: "text-code-2"}]
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
        expanded_before: [%DisplayElement{text: "%{", color: "text-code-2"}],
        expanded_after: [%DisplayElement{text: "}", color: "text-code-2"}]
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
            key: :field1,
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
            key: :field2,
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
            key: :calendar,
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
          day: %TermNode{
            id: "root.1",
            kind: :number,
            key: :day,
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
          month: %TermNode{
            id: "root.2",
            kind: :number,
            key: :month,
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
          year: %TermNode{
            id: "root.3",
            kind: :number,
            key: :year,
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
             key: "key1",
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
             key: "key2",
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
             key: "key3",
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
             key: {:ok, date},
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
             key: cid,
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
      term = %{a: 1, b: [1, 2, 3]}
      term_node = TermParser.term_to_display_tree(term)

      diff = %Diff{type: :equal}

      assert {:ok, ^term_node} = TermParser.update_by_diff(term_node, diff)
    end

    test "updates primitive values" do
      old_term = "Old Term"
      new_term = "New Term"

      term_node = %TermNode{content: [%DisplayElement{text: "Old Term", color: "text-code-1"}]}

      diff = TermDiffer.diff(old_term, new_term)

      assert {:ok,
              %TermNode{content: [%DisplayElement{text: "\"New Term\"", color: "text-code-4"}]}} =
               TermParser.update_by_diff(term_node, diff)
    end

    test "updates nested elements in maps" do
      old_term = %{
        user: %{
          name: "Alice",
          settings: %{
            theme: "light",
            notifications: true
          }
        }
      }

      new_term = %{
        user: %{
          name: "Alice",
          settings: %{
            theme: "dark",
            notifications: false
          }
        }
      }

      term_node = TermParser.term_to_display_tree(old_term)
      diff = TermDiffer.diff(old_term, new_term)

      assert {:ok, updated_node} = TermParser.update_by_diff(term_node, diff)

      {_, user_node} = Enum.find(updated_node.children, fn {key, _} -> key == :user end)
      {_, name_node} = Enum.find(user_node.children, fn {key, _} -> key == :name end)
      {_, settings_node} = Enum.find(user_node.children, fn {key, _} -> key == :settings end)
      {_, theme_node} = Enum.find(settings_node.children, fn {key, _} -> key == :theme end)

      assert name_node.content == [
               %DisplayElement{text: "name:", color: "text-code-1", pulse?: false},
               %DisplayElement{text: " ", color: "text-code-2", pulse?: false},
               %DisplayElement{text: "\"Alice\"", color: "text-code-4", pulse?: false},
               %DisplayElement{text: ",", color: "text-code-2", pulse?: false}
             ]

      assert theme_node.content == [
               %DisplayElement{text: "theme:", color: "text-code-1", pulse?: true},
               %DisplayElement{text: " ", color: "text-code-2", pulse?: true},
               %DisplayElement{text: "\"dark\"", color: "text-code-4", pulse?: true}
             ]
    end

    test "handles list insertions and deletions" do
      old_term = [1, 2, 3]
      new_term = [0, 2, 3, 4]

      term_node = TermParser.term_to_display_tree(old_term)
      diff = TermDiffer.diff(old_term, new_term)

      assert {:ok, updated_node} = TermParser.update_by_diff(term_node, diff)

      assert length(updated_node.children) == 4

      assert {0,
              %TermNode{
                content: [
                  %DisplayElement{text: "0", color: "text-code-1"},
                  %DisplayElement{text: ",", color: "text-code-2"}
                ]
              }} = Enum.at(updated_node.children, 0)

      assert {3,
              %TermNode{
                content: [
                  %DisplayElement{text: "4", color: "text-code-1"}
                ]
              }} = Enum.at(updated_node.children, 3)
    end

    test "properly adds and removes comma suffixes" do
      term_node1 = %{a: 1, b: 2}
      term_node2 = %{a: 1, b: 2, c: 3}

      term_node = TermParser.term_to_display_tree(term_node1)
      diff = TermDiffer.diff(term_node1, term_node2)

      assert {:ok, updated_node} = TermParser.update_by_diff(term_node, diff)

      {_, b_node} = Enum.find(updated_node.children, fn {key, _} -> key == :b end)
      assert List.last(b_node.content) == %DisplayElement{text: ",", color: "text-code-2"}
      assert List.last(b_node.expanded_after) == %DisplayElement{text: ",", color: "text-code-2"}

      term_node3 = %{a: 1, b: 2}
      diff = TermDiffer.diff(term_node2, term_node3)

      assert {:ok, final_node} = TermParser.update_by_diff(updated_node, diff)

      {_, b_node} = Enum.find(final_node.children, fn {key, _} -> key == :b end)
      refute List.last(b_node.content) == %DisplayElement{text: ",", color: "text-code-2"}
      refute List.last(b_node.expanded_after) == %DisplayElement{text: ",", color: "text-code-2"}
    end

    test "properly opens lists and tuples within default limits" do
      old_term = %{small: [1], large: [1, 2, 3, 4]}
      new_term = %{small: [1, 2], large: [1, 2, 3, 4, 5]}

      term_node = TermParser.term_to_display_tree(old_term)
      diff = TermDiffer.diff(old_term, new_term)

      assert {:ok, updated_node} = TermParser.update_by_diff(term_node, diff)

      assert updated_node.open? == true

      assert {_, %TermNode{open?: true}} =
               Enum.find(updated_node.children, fn {key, _} -> key == :small end)

      assert {_, %TermNode{open?: false}} =
               Enum.find(updated_node.children, fn {key, _} -> key == :large end)
    end

    test "handles struct updates" do
      old_term = %TestStruct{field1: "old", field2: 1}
      new_term = %TestStruct{field1: "new", field2: 2}

      term_node = TermParser.term_to_display_tree(old_term)
      diff = TermDiffer.diff(old_term, new_term)

      assert {:ok, updated_node} = TermParser.update_by_diff(term_node, diff)

      {_, field1_node} = Enum.find(updated_node.children, fn {key, _} -> key == :field1 end)

      assert field1_node.content == [
               %DisplayElement{text: "field1:", color: "text-code-1", pulse?: true},
               %DisplayElement{text: " ", color: "text-code-2", pulse?: true},
               %DisplayElement{text: "\"new\"", color: "text-code-4", pulse?: true},
               %DisplayElement{text: ",", color: "text-code-2", pulse?: false}
             ]

      {_, field2_node} = Enum.find(updated_node.children, fn {key, _} -> key == :field2 end)

      assert field2_node.content == [
               %DisplayElement{text: "field2:", color: "text-code-1", pulse?: true},
               %DisplayElement{text: " ", color: "text-code-2", pulse?: true},
               %DisplayElement{text: "2", color: "text-code-1", pulse?: true}
             ]
    end

    test "handles map key additions and deletions" do
      old_term = %{"a" => 1, "b" => 2}
      new_term = %{"b" => 2, "d" => 4}

      term_node = TermParser.term_to_display_tree(old_term)
      diff = TermDiffer.diff(old_term, new_term)

      assert {:ok, updated_node} = TermParser.update_by_diff(term_node, diff)

      refute Enum.any?(updated_node.children, fn {key, _} -> key == "a" end)

      assert {_, d_node} = Enum.find(updated_node.children, fn {key, _} -> key == "d" end)

      assert d_node.content == [
               %DisplayElement{text: "\"d\"", color: "text-code-4", pulse?: true},
               %DisplayElement{text: " => ", color: "text-code-2", pulse?: true},
               %DisplayElement{text: "4", color: "text-code-1", pulse?: true}
             ]
    end

    test "correctly updates node ids" do
      old_term = %{items: [1, 2], metadata: %{version: 1}}
      new_term = %{items: [1, 2, 3], metadata: %{version: 2}}

      term_node = TermParser.term_to_display_tree(old_term)
      diff = TermDiffer.diff(old_term, new_term)

      assert {:ok,
              %TermNode{
                id: "root",
                children: [
                  {:items,
                   %TermNode{
                     id: "root.0",
                     children: [
                       {0, %TermNode{id: "root.0.0"}},
                       {1, %TermNode{id: "root.0.1"}},
                       {2, %TermNode{id: "root.0.2"}}
                     ]
                   }},
                  {:metadata,
                   %TermNode{
                     id: "root.1",
                     children: [
                       {:version, %TermNode{id: "root.1.0"}}
                     ]
                   }}
                ]
              }} = TermParser.update_by_diff(term_node, diff)
    end

    test "returns error if the term node and diff are not compatible" do
      invalid_diff = %Diff{
        type: :map,
        diff: %{non_existent_key: Fakes.term_diff_primitive()}
      }

      old_term = :not_a_map

      term_node = TermParser.term_to_display_tree(old_term)

      assert {:error, _} = TermParser.update_by_diff(term_node, invalid_diff)
    end
  end

  defp close_term_node(%TermNode{} = term_node) do
    %TermNode{term_node | open?: false}
  end
end
