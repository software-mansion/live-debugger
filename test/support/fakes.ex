defmodule LiveDebugger.Fakes do
  @moduledoc """
  Fake complex structures
  """

  def trace(opts \\ []) do
    default = [
      id: 1,
      module: LiveDebuggerTest.LiveView,
      function: :render,
      arity: 1,
      args: [%{socket_id: "socket_id"}],
      socket_id: "socket_id",
      pid: :c.pid(0, 1, 0),
      timestamp: :erlang.timestamp(),
      execution_time: 1,
      exception: false
    ]

    fields = Keyword.merge(default, opts)

    Kernel.struct!(LiveDebugger.Structs.Trace, fields)
  end

  def state(opts \\ []) do
    socket_id = Keyword.get(opts, :socket_id, "phx-GBsi_6M7paYhySQj")
    parent_pid = Keyword.get(opts, :parent_pid, nil)
    transport_pid = Keyword.get(opts, :transport_pid, :c.pid(0, 7, 0))
    module = Keyword.get(opts, :module, LiveDebuggerWeb.Main)

    host_uri =
      if Keyword.get(opts, :embedded?, false) do
        :not_mounted_at_router
      else
        Keyword.get(opts, :host_uri, "https://localhost:4000")
      end

    root_pid =
      case Keyword.get(opts, :nested?, nil) do
        false ->
          if not Keyword.has_key?(opts, :pid), do: raise("pid is required for nested processes")
          Keyword.get(opts, :pid)

        _ ->
          Keyword.get(opts, :root_pid, :c.pid(0, 0, 0))
      end

    %{
      socket: %Phoenix.LiveView.Socket{
        id: socket_id,
        endpoint: LiveDebuggerDev.Endpoint,
        view: module,
        parent_pid: parent_pid,
        root_pid: root_pid,
        router: LiveDebuggerDev.Router,
        transport_pid: transport_pid,
        host_uri: host_uri,
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
    }
  end
end
