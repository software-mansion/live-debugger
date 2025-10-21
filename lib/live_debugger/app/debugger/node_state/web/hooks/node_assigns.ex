defmodule LiveDebugger.App.Debugger.NodeState.Web.Hooks.NodeAssigns do
  @moduledoc """
  This hook is responsible for fetching assigns of specific node.
  """

  use LiveDebugger.App.Web, :hook

  alias Phoenix.LiveView.AsyncResult
  alias LiveDebugger.App.Debugger.NodeState.Queries, as: NodeStateQueries
  alias LiveDebugger.App.Utils.TermDiffer
  alias LiveDebugger.App.Utils.TermDiffer.Diff
  alias LiveDebugger.App.Utils.TermParser
  alias LiveDebugger.Utils.Memory

  @required_assigns [
    :node_id,
    :lv_process
  ]

  @assigns_size_events [:assigns_size_1, :assigns_size_2]

  @doc """
  Initializes the hook by attaching the hook to the socket and checking the required assigns.
  """
  @spec init(Phoenix.LiveView.Socket.t()) :: Phoenix.LiveView.Socket.t()
  def init(socket) do
    socket
    |> check_assigns!(@required_assigns)
    |> attach_hook(:node_assigns, :handle_async, &handle_async/3)
    |> register_hook(:node_assigns)
    |> assign(:node_assigns_info, AsyncResult.loading())
    |> assign(:assigns_sizes, AsyncResult.loading())
    |> assign_async_node_assigns()
  end

  @doc """
  Assigns the async node assigns to the socket.

  ## Options

  - `:reset` - If `true`, assigns won't diff current assigns with new ones.
  """
  @spec assign_async_node_assigns(Phoenix.LiveView.Socket.t(), Keyword.t()) ::
          Phoenix.LiveView.Socket.t()
  def assign_async_node_assigns(socket, opts \\ [])

  def assign_async_node_assigns(
        %{assigns: %{node_id: node_id, lv_process: %{pid: pid}}} = socket,
        opts
      )
      when not is_nil(node_id) do
    node_assigns_info =
      if Keyword.get(opts, :reset, false) do
        AsyncResult.loading()
      else
        socket.assigns.node_assigns_info
      end

    assigns_sizes =
      if Keyword.get(opts, :reset, false) do
        AsyncResult.loading()
      else
        socket.assigns.assigns_sizes
      end

    socket
    |> assign(:node_assigns_info, node_assigns_info)
    |> assign(:assigns_sizes, assigns_sizes)
    |> start_async(:fetch_node_assigns, fn ->
      NodeStateQueries.fetch_node_assigns(pid, node_id)
    end)
  end

  def assign_async_node_assigns(socket, _) do
    socket
    |> assign(:node_assigns_info, AsyncResult.failed(%AsyncResult{}, :no_node_id))
  end

  defp handle_async(
         :fetch_node_assigns,
         {:ok, {:ok, node_assigns}},
         %{
           assigns: %{
             node_assigns_info: %AsyncResult{ok?: true, result: {old_assigns, old_term_node, _}}
           }
         } =
           socket
       ) do
    node_assigns_info =
      case TermDiffer.diff(old_assigns, node_assigns) do
        %Diff{type: :equal} ->
          AsyncResult.ok(socket.assigns.node_assigns_info.result)

        diff ->
          copy_string = TermParser.term_to_copy_string(node_assigns)

          case TermParser.update_by_diff(old_term_node, diff) do
            {:ok, term_node} ->
              AsyncResult.ok({node_assigns, term_node, copy_string})

            {:error, reason} ->
              AsyncResult.failed(socket.assigns.node_assigns_info, reason)
          end
      end

    socket
    |> assign(:node_assigns_info, node_assigns_info)
    |> assign_size_async(node_assigns)
    |> halt()
  end

  defp handle_async(:fetch_node_assigns, {:ok, {:ok, node_assigns}}, socket) do
    term_node = TermParser.term_to_display_tree(node_assigns)
    copy_string = TermParser.term_to_copy_string(node_assigns)

    socket
    |> assign(:node_assigns_info, AsyncResult.ok({node_assigns, term_node, copy_string}))
    |> assign_size_async(node_assigns)
    |> halt()
  end

  defp handle_async(:fetch_node_assigns, {:ok, {:error, reason}}, socket) do
    socket
    |> assign(:node_assigns_info, AsyncResult.failed(socket.assigns.node_assigns_info, reason))
    |> halt()
  end

  defp handle_async(:fetch_node_assigns, {:exit, reason}, socket) do
    socket
    |> assign(:node_assigns_info, AsyncResult.failed(socket.assigns.node_assigns_info, reason))
    |> halt()
  end

  defp handle_async(ev, {:ok, assigns_sizes}, socket) when ev in @assigns_size_events do
    socket
    |> assign(:assigns_sizes, AsyncResult.ok(assigns_sizes))
    |> halt()
  end

  defp handle_async(ev, {:exit, {reason, _}}, socket) when ev in @assigns_size_events do
    socket
    |> assign(:assigns_sizes, AsyncResult.failed(%AsyncResult{}, reason))
    |> halt()
  end

  defp handle_async(_, _, socket), do: {:cont, socket}

  # If one async task is already running, we start the second async task
  # If both async tasks are running, we start the second async task
  # It stops already running second async tasks and start a new one
  defp assign_size_async(%{private: %{live_async: %{assigns_size_1: _}}} = socket, assigns) do
    start_async(socket, :assigns_size_2, fn -> calculate_assigns_size(assigns) end)
  end

  # If assigns are not calculated, we start the first async task
  defp assign_size_async(socket, assigns) do
    start_async(socket, :assigns_size_1, fn -> calculate_assigns_size(assigns) end)
  end

  defp calculate_assigns_size(assigns) do
    Process.sleep(2000)
    %{heap_size: assigns_heap_size(assigns), serialized_size: assigns_serialized_size(assigns)}
  end

  defp assigns_heap_size(assigns) do
    assigns |> Memory.term_heap_size() |> Memory.bytes_to_pretty_string()
  end

  defp assigns_serialized_size(assigns) do
    assigns |> Memory.serialized_term_size() |> Memory.bytes_to_pretty_string()
  end
end
