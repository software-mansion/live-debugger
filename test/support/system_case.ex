defmodule LiveDebugger.SystemCase do
  @moduledoc false

  use ExUnit.CaseTemplate

  alias LiveDebugger.MockProcessService

  setup do
    live_view_pid = :c.pid(0, 0, 0)
    socket_id = "phx-GBsi_6M7paYhySQj"

    Mox.stub(MockProcessService, :state, fn pid ->
      if live_view_pid == pid do
        {:ok,
         %{
           socket: %Phoenix.LiveView.Socket{
             id: socket_id,
             endpoint: LiveDebuggerDev.Endpoint,
             view: LiveDebuggerDev.LiveViews.Main,
             parent_pid: nil,
             root_pid: pid,
             router: LiveDebuggerDev.Router,
             assigns: %{
               assign: :value,
               counter: 0,
               __changed__: %{},
               flash: %{},
               live_action: nil,
               datetime: nil
             }
           },
           components:
             {%{
                1 =>
                  {LiveDebuggerDev.LiveComponents.ManyAssigns, "many_assigns",
                   %{
                     id: "many_assigns",
                     c: "some value",
                     p: 213,
                     myself: %Phoenix.LiveComponent.CID{cid: 1},
                     __changed__: %{}
                   },
                   %{
                     root_view: LiveDebuggerDev.LiveViews.Main,
                     children_cids: []
                   }, nil},
                2 =>
                  {LiveDebuggerDev.LiveComponents.Send, "send_outer",
                   %{
                     id: "send_outer",
                     myself: %Phoenix.LiveComponent.CID{cid: 2},
                     __changed__: %{},
                     flash: %{}
                   },
                   %{
                     root_view: LiveDebuggerDev.LiveViews.Main,
                     children_cids: [6, 7]
                   }, nil},
                3 =>
                  {LiveDebuggerDev.LiveComponents.Conditional, "conditional",
                   %{
                     id: "conditional",
                     myself: %Phoenix.LiveComponent.CID{cid: 3},
                     __changed__: %{},
                     flash: %{},
                     show_child?: false
                   },
                   %{
                     root_view: LiveDebuggerDev.LiveViews.Main,
                     children_cids: []
                   }, nil},
                4 =>
                  {LiveDebuggerDev.LiveComponents.Reccursive, "reccursive",
                   %{
                     id: "reccursive",
                     counter: 2,
                     myself: %Phoenix.LiveComponent.CID{cid: 4},
                     __changed__: %{},
                     flash: %{}
                   },
                   %{
                     root_view: LiveDebuggerDev.LiveViews.Main,
                     children_cids: [5]
                   }, nil},
                5 =>
                  {LiveDebuggerDev.LiveComponents.Reccursive, "reccursive|",
                   %{
                     id: "reccursive|",
                     counter: 1,
                     myself: %Phoenix.LiveComponent.CID{cid: 5},
                     __changed__: %{},
                     flash: %{}
                   },
                   %{
                     root_view: LiveDebuggerDev.LiveViews.Main,
                     children_cids: [8]
                   }, nil},
                6 =>
                  {LiveDebuggerDev.LiveComponents.Name, "name_inner",
                   %{
                     name: "Eve",
                     myself: %Phoenix.LiveComponent.CID{cid: 6},
                     __changed__: %{},
                     flash: %{}
                   },
                   %{
                     root_view: LiveDebuggerDev.LiveViews.Main,
                     children_cids: []
                   }, nil},
                7 =>
                  {LiveDebuggerDev.LiveComponents.LiveComponentWithVeryVeryLongName, "long_name",
                   %{
                     id: "long_name",
                     myself: %Phoenix.LiveComponent.CID{cid: 7},
                     __changed__: %{},
                     flash: %{}
                   },
                   %{
                     root_view: LiveDebuggerDev.LiveViews.Main,
                     children_cids: []
                   }, nil},
                8 =>
                  {LiveDebuggerDev.LiveComponents.Reccursive, "reccursive||",
                   %{
                     id: "reccursive||",
                     counter: 0,
                     myself: %Phoenix.LiveComponent.CID{cid: 8},
                     __changed__: %{},
                     flash: %{}
                   },
                   %{
                     root_view: LiveDebuggerDev.LiveViews.Main,
                     children_cids: []
                   }, nil}
              },
              %{
                LiveDebuggerDev.LiveComponents.Reccursive => %{
                  "reccursive" => 4,
                  "reccursive|" => 5,
                  "reccursive||" => 8
                },
                LiveDebuggerDev.LiveComponents.Name => %{"name_inner" => 6},
                LiveDebuggerDev.LiveComponents.LiveComponentWithVeryVeryLongName => %{
                  "long_name" => 7
                },
                LiveDebuggerDev.LiveComponents.ManyAssigns => %{"many_assigns" => 1},
                LiveDebuggerDev.LiveComponents.Conditional => %{"conditional" => 3},
                LiveDebuggerDev.LiveComponents.Send => %{"send_outer" => 2}
              }, 9}
         }}
      else
        {:ok, :not_live_view}
      end
    end)

    {:ok, pid: live_view_pid, socket_id: socket_id}
  end
end
