defmodule LiveDebugger.App.Utils.TermNodeTest do
  use ExUnit.Case, async: true

  alias LiveDebugger.App.Utils.TermNode
  alias LiveDebugger.App.Utils.TermNode.DisplayElement
  alias LiveDebugger.Fakes

  describe "new/3" do
    test "creates a new term node with default values" do
      content = [%DisplayElement{text: "atom", color: "text-code-1"}]
      kind = :atom

      assert %TermNode{
               id: "not_indexed",
               kind: :atom,
               content: ^content,
               children: [],
               expanded_before: [],
               expanded_after: [],
               open?: false
             } = TermNode.new(kind, content)
    end

    test "creates a new term node with custom values" do
      id = "custom_id"
      content = [Fakes.display_element()]
      kind = :atom

      children = [
        Fakes.term_node(id: "not_indexed", content: [Fakes.display_element(text: "child")])
      ]

      expanded_before = [Fakes.display_element(text: "expanded_before")]
      expanded_after = [Fakes.display_element(text: "expanded_after")]
      open? = true

      assert %TermNode{
               id: ^id,
               kind: ^kind,
               content: ^content,
               children: ^children,
               expanded_before: ^expanded_before,
               expanded_after: ^expanded_after,
               open?: ^open?
             } =
               TermNode.new(kind, content,
                 id: id,
                 children: children,
                 expanded_before: expanded_before,
                 expanded_after: expanded_after,
                 open?: open?
               )
    end
  end

  describe "has_children?/1" do
    test "returns true if the term node has children" do
      assert TermNode.has_children?(%TermNode{children: [1, 2, 3]})
    end

    test "returns false if the term node has no children" do
      assert not TermNode.has_children?(%TermNode{children: []})
    end
  end

  describe "children_number/1" do
    test "returns the number of children" do
      assert TermNode.children_number(%TermNode{children: [1, 2, 3]}) == 3
    end

    test "returns 0 if the term node has no children" do
      assert TermNode.children_number(%TermNode{children: []}) == 0
    end
  end

  describe "add_suffix/2 properly adds suffix to the term node's content and expanded_after" do
    content = Fakes.display_element(text: "content")

    term_node = Fakes.term_node(id: "root", content: [content])

    suffix = Fakes.display_element(text: "suffix")

    assert %TermNode{
             content: [^content, ^suffix],
             children: [],
             expanded_before: [],
             expanded_after: [^suffix]
           } = TermNode.add_suffix(term_node, [suffix])
  end

  describe "remove_suffix!/1" do
    test "removes last element from the term node's content and expanded_after" do
      suffix = Fakes.display_element(text: "suffix")

      term_node = Fakes.term_node(id: "root", content: [suffix], expanded_after: [suffix])

      assert %TermNode{
               id: "root",
               kind: :atom,
               content: [],
               children: [],
               expanded_before: [],
               expanded_after: []
             } = TermNode.remove_suffix!(term_node)
    end

    test "raises an error if the term node has no suffix to remove" do
      assert_raise RuntimeError, "Term node has no suffix to remove", fn ->
        TermNode.remove_suffix!(%TermNode{content: [], expanded_after: []})
      end
    end
  end

  test "add_prefix/2 properly adds prefix to the term node's content and expanded_before" do
    content = Fakes.display_element(text: "content")

    term_node = Fakes.term_node(id: "root", content: [content])

    prefix = Fakes.display_element(text: "prefix")

    assert %TermNode{
             content: [^prefix, ^content],
             children: [],
             expanded_before: [^prefix],
             expanded_after: []
           } = TermNode.add_prefix(term_node, [prefix])
  end

  describe "remove_child/2" do
    test "removes the child from the term node and returns ok tuple" do
      child2 = Fakes.term_node(id: "root.1")
      child1 = Fakes.term_node(id: "root.0")

      term_node = Fakes.term_node(kind: :tuple, id: "root", children: [{0, child1}, {1, child2}])

      assert {:ok,
              %TermNode{
                id: "root",
                kind: :tuple,
                children: [{0, ^child1}]
              }} = TermNode.remove_child(term_node, 1)
    end

    test "returns error if the child is not found" do
      child1 = Fakes.term_node(id: "root.0")
      term_node = Fakes.term_node(kind: :tuple, id: "root", children: [{0, child1}])

      assert {:error, :child_not_found} = TermNode.remove_child(term_node, 1)
    end
  end

  describe "update_child/3" do
    test "updates the child and returns ok tuple" do
      child = Fakes.term_node(id: "root.0")
      term_node = Fakes.term_node(kind: :tuple, id: "root", children: [{0, child}])

      updated_content = [Fakes.display_element(text: "updated")]

      update_function = fn %TermNode{} = child -> %TermNode{child | content: updated_content} end

      assert {:ok, %TermNode{children: [{0, %TermNode{content: ^updated_content}}]}} =
               TermNode.update_child(term_node, 0, update_function)
    end

    test "returns error if the child is not found" do
      child = Fakes.term_node(id: "root.0")
      term_node = Fakes.term_node(kind: :tuple, id: "root", children: [{0, child}])

      assert {:error, :child_not_found} =
               TermNode.update_child(term_node, 1, &Function.identity/1)
    end
  end

  describe "set_pulse/3" do
    test "updates term node all display elements pulse? field" do
      term_node =
        Fakes.term_node(
          content: [
            Fakes.display_element(text: "key:", pulse?: false),
            Fakes.display_element(text: " ", pulse?: false),
            Fakes.display_element(text: "%{...}", pulse?: false)
          ],
          expanded_before: [Fakes.display_element(text: "%{", pulse?: false)],
          expanded_after: [Fakes.display_element(text: "}", pulse?: false)],
          children: [
            {:key,
             Fakes.term_node(
               content: [
                 Fakes.display_element(text: "counter:", pulse?: false),
                 Fakes.display_element(text: " ", pulse?: false),
                 Fakes.display_element(text: "3", pulse?: false)
               ],
               expanded_before: [],
               expanded_after: []
             )}
          ]
        )

      assert %TermNode{
               content: [
                 %DisplayElement{text: "key:", pulse?: true},
                 %DisplayElement{text: " ", pulse?: true},
                 %DisplayElement{text: "%{...}", pulse?: true}
               ],
               expanded_before: [%DisplayElement{text: "%{", pulse?: true}],
               expanded_after: [%DisplayElement{text: "}", pulse?: true}],
               children: [
                 {:key,
                  %TermNode{
                    content: [
                      %DisplayElement{text: "counter:", pulse?: false},
                      %DisplayElement{text: " ", pulse?: false},
                      %DisplayElement{text: "3", pulse?: false}
                    ],
                    expanded_before: [],
                    expanded_after: []
                  }}
               ]
             } = TermNode.set_pulse(term_node, true, recursive: false)
    end

    test "updates term node all display elements pulse? field and recursively all children" do
      term_node =
        Fakes.term_node(
          content: [
            Fakes.display_element(text: "key:", pulse?: false),
            Fakes.display_element(text: " ", pulse?: false),
            Fakes.display_element(text: "%{...}", pulse?: false)
          ],
          expanded_before: [Fakes.display_element(text: "%{", pulse?: false)],
          expanded_after: [Fakes.display_element(text: "}", pulse?: false)],
          children: [
            {:key,
             Fakes.term_node(
               content: [
                 Fakes.display_element(text: "counter:", pulse?: false),
                 Fakes.display_element(text: " ", pulse?: false),
                 Fakes.display_element(text: "3", pulse?: false)
               ],
               expanded_before: [],
               expanded_after: []
             )}
          ]
        )

      assert %TermNode{
               content: [
                 %DisplayElement{text: "key:", pulse?: true},
                 %DisplayElement{text: " ", pulse?: true},
                 %DisplayElement{text: "%{...}", pulse?: true}
               ],
               expanded_before: [%DisplayElement{text: "%{", pulse?: true}],
               expanded_after: [%DisplayElement{text: "}", pulse?: true}],
               children: [
                 {:key,
                  %TermNode{
                    content: [
                      %DisplayElement{text: "counter:", pulse?: true},
                      %DisplayElement{text: " ", pulse?: true},
                      %DisplayElement{text: "3", pulse?: true}
                    ],
                    expanded_before: [],
                    expanded_after: []
                  }}
               ]
             } = TermNode.set_pulse(term_node, true, recursive: true)
    end
  end
end
