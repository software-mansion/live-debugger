defmodule LiveDebugger.App.Debugger.NodeState.Web.NodeStateLive do
  @moduledoc """
  This LiveView displays the state of a particular node (`LiveView` or `LiveComponent`).
  It is meant to be used as a composable nested LiveView in the Debugger page.
  """

  use LiveDebugger.App.Web, :live_view

  alias Phoenix.LiveView.AsyncResult
  alias LiveDebugger.Structs.LvProcess
  alias LiveDebugger.App.Debugger.NodeState.Web.Components, as: NodeStateComponents
  alias LiveDebugger.App.Debugger.NodeState.Queries, as: NodeStateQueries

  alias LiveDebugger.Bus
  alias LiveDebugger.App.Debugger.Events.NodeIdParamChanged
  alias LiveDebugger.Services.CallbackTracer.Events.StateChanged

  @doc """
  Renders the `NodeStateLive` as a nested LiveView component.

  `id` - dom id
  `socket` - parent LiveView socket
  `lv_process` - currently debugged LiveView process
  `params` - query parameters of the page.
  """

  attr(:id, :string, required: true)
  attr(:socket, Phoenix.LiveView.Socket, required: true)
  attr(:lv_process, LvProcess, required: true)
  attr(:node_id, :any, required: true)
  attr(:class, :string, default: "", doc: "CSS class for the container")

  def live_render(assigns) do
    session = %{
      "lv_process" => assigns.lv_process,
      "node_id" => assigns.node_id,
      "parent_pid" => self()
    }

    assigns = assign(assigns, session: session)

    ~H"""
    <%= live_render(@socket, __MODULE__,
      id: @id,
      session: @session,
      container: {:div, class: @class}
    ) %>
    """
  end

  @impl true
  def mount(_params, session, socket) do
    lv_process = session["lv_process"]
    parent_pid = session["parent_pid"]
    node_id = session["node_id"]

    if connected?(socket) do
      Bus.receive_events!(parent_pid)
      Bus.receive_states!(lv_process.pid)
    end

    socket
    |> assign(:lv_process, lv_process)
    |> assign(:node_id, node_id)
    |> assign_async_node_assigns()
    |> ok()
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="flex-1 max-w-full flex flex-col gap-4">
      <.async_result :let={node_assigns} assign={@node_assigns}>
        <:loading>
          <NodeStateComponents.loading />
        </:loading>
        <:failed>
          <NodeStateComponents.failed />
        </:failed>

        <NodeStateComponents.assigns_section
          assigns={node_assigns}
          diff={@diff.result}
          fullscreen_id="assigns-display-fullscreen"
        />
      </.async_result>
    </div>
    """
  end

  @impl true
  def handle_info(%NodeIdParamChanged{node_id: node_id}, socket) do
    socket
    |> assign(:node_id, node_id)
    |> assign_async_node_assigns()
    |> noreply()
  end

  def handle_info(%StateChanged{}, socket) do
    socket
    |> assign_async_node_assigns(calculate_diff?: true)
    |> noreply()
  end

  def handle_info(_, socket), do: {:noreply, socket}

  defp assign_async_node_assigns(socket, opts \\ [])

  defp assign_async_node_assigns(
         %{assigns: %{node_id: node_id, lv_process: %{pid: pid}} = assigns} = socket,
         opts
       )
       when not is_nil(node_id) do
    calculate_diff? = Keyword.get(opts, :calculate_diff?, false)

    old_node_assigns =
      case assigns[:node_assigns] do
        %AsyncResult{result: result} -> result
        _ -> nil
      end

    dbg(assigns)

    assign_async(socket, [:node_assigns, :diff], fn ->
      case NodeStateQueries.fetch_node_assigns(pid, node_id) do
        {:ok, node_assigns} ->
          diff =
            if calculate_diff? do
              MapDiff.diff(old_node_assigns, node_assigns)
            else
              %{}
            end

          dbg(diff)

          {:ok, %{node_assigns: node_assigns, diff: diff}}

        {:error, reason} ->
          {:error, reason}
      end
    end)
  end

  defp assign_async_node_assigns(socket, _opts) do
    assign(socket, :node, AsyncResult.failed(%AsyncResult{}, :no_node_id))
  end
end

defmodule MapDiff do
  @doc """
  Computes a recursive diff between two maps.
  Returns a map of keys that changed, where
  leaf values are tuples {old, new}.
  """
  def diff(map1, map2) when is_map(map1) and is_map(map2) do
    all_keys = (Map.keys(map1) ++ Map.keys(map2)) |> Enum.uniq()

    all_keys
    |> Enum.reduce(%{}, fn key, acc ->
      v1 = Map.get(map1, key, :__missing__)
      v2 = Map.get(map2, key, :__missing__)

      cond do
        v1 == v2 ->
          acc

        is_map(v1) and is_map(v2) ->
          nested_diff = diff(v1, v2)

          if nested_diff == %{} do
            acc
          else
            Map.put(acc, key, nested_diff)
          end

        true ->
          Map.put(acc, key, true)
      end
    end)
  end

  def diff(_, _) do
    %{}
  end
end
