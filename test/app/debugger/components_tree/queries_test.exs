defmodule LiveDebugger.App.Debugger.ComponentsTree.QueriesTest do
  use ExUnit.Case, async: true

  import Mox

  alias LiveDebugger.App.Debugger.ComponentsTree.Queries, as: ComponentsTreeQueries
  alias LiveDebugger.App.Debugger.Structs.TreeNode
  alias LiveDebugger.MockAPILiveViewDebug
  alias LiveDebugger.MockAPIStatesStorage
  alias LiveDebugger.Structs.LvState

  setup :verify_on_exit!

  describe "fetch_components_tree/1" do
    test "returns root TreeNode for valid pid" do
      pid = :c.pid(0, 11, 0)

      expect(MockAPIStatesStorage, :get!, fn ^pid ->
        %LvState{
          pid: pid,
          socket: %{id: "phx-somevalueid", view: LiveDebuggerTest.SomeModuleLive},
          components: [%{cid: 1, module: LiveDebuggerTest.LiveComponent, children_cids: []}]
        }
      end)

      assert {:ok, %{tree: tree}} = ComponentsTreeQueries.fetch_components_tree(pid)

      assert %TreeNode{
               id: ^pid,
               dom_id: %{},
               type: :live_view,
               module: LiveDebuggerTest.SomeModuleLive,
               children: [
                 %TreeNode{
                   id: %Phoenix.LiveComponent.CID{cid: 1},
                   dom_id: %{},
                   type: :live_component,
                   module: LiveDebuggerTest.LiveComponent,
                   children: []
                 }
               ]
             } = tree
    end

    test "returns root TreeNode for valid pid when state not saved in StatesStorage" do
      pid = :c.pid(0, 11, 0)

      expect(MockAPIStatesStorage, :get!, fn ^pid -> nil end)

      MockAPILiveViewDebug
      |> expect(:socket, fn ^pid ->
        {:ok, %{id: "phx-somevalueid", view: LiveDebuggerTest.SomeModuleLive}}
      end)
      |> expect(:live_components, fn ^pid ->
        {:ok, [%{cid: 1, module: LiveDebuggerTest.LiveComponent, children_cids: []}]}
      end)

      assert {:ok, %{tree: tree}} = ComponentsTreeQueries.fetch_components_tree(pid)

      assert %TreeNode{
               id: ^pid,
               dom_id: %{},
               type: :live_view,
               module: LiveDebuggerTest.SomeModuleLive,
               children: [
                 %TreeNode{
                   id: %Phoenix.LiveComponent.CID{cid: 1},
                   dom_id: %{},
                   type: :live_component,
                   module: LiveDebuggerTest.LiveComponent,
                   children: []
                 }
               ]
             } = tree
    end
  end
end
