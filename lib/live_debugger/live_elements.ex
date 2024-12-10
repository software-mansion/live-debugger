defmodule LiveDebugger.LiveElements do
  alias __MODULE__.Component, as: LiveComponentElement
  alias __MODULE__.View, as: LiveViewElement
  alias LiveDebugger.LiveElement

  @type live_element() :: LiveViewElement.t() | LiveComponentElement.t()

  @doc """
  Returns LiveView root elment and all its children live elements

  ## Example:
  ```elixir

  state = :sys.get_state(pid)
  case LiveDebugger.LiveElements.live_elements(state) do
    {:ok, {root, elements}} -> IO.inspect(root, pretty: true)
    {:error, _} -> IO.puts("Error")
  end
  ```
  """
  @spec live_elements(state :: map()) ::
          {:ok, {LiveViewElement.t(), [live_element()]}} | {:error, term()}
  def live_elements(%{socket: socket, components: components}) do
    with {:ok, root} <- LiveViewElement.parse(socket),
         {components, _, _} <- components do
      elements =
        Enum.map(components, fn component ->
          case LiveComponentElement.parse(component) do
            {:ok, live_component} -> live_component
            {:error, _} -> nil
          end
        end)

      {:ok, {root, elements}}
    end
  end

  def live_elements(_), do: {:error, :invalid_state}

  @doc """
  Creates tree using LiveElemets where root is a LiveView

  ## Example:
  ```elixir

  state = :sys.get_state(pid)
  case LiveDebugger.LiveElements.build_tree(state) do
    {:ok, root} -> IO.inspect(root, pretty: true)
    {:error, _} -> IO.puts("Error")
  end
  ```
  """
  @spec build_tree(state :: map()) :: {:ok, live_element()} | {:error, term()}
  def build_tree(state) do
    with {:ok, {root, live_elements}} <- live_elements(state) do
      cids_map = components_cids_map(state)
      cids_tree = components_cids_tree(cids_map, nil)

      {:ok, add_children(root, cids_tree, live_elements)}
    end
  end

  defp components_cids_map(channel_state) do
    {components, _, _} = channel_state.components

    parent_cids = components |> Enum.map(fn {cid, _} -> {cid, nil} end) |> Enum.into(%{})

    Enum.reduce(components, parent_cids, fn {cid, element}, parent_cids ->
      {_, _, _, info, _} = element
      children_cids = info.children_cids

      Enum.reduce(children_cids, parent_cids, fn child_cid, parent_cids ->
        %{parent_cids | child_cid => cid}
      end)
    end)
    |> Enum.reduce(%{}, fn {cid, parent_cid}, acc ->
      Map.update(acc, parent_cid, [cid], &[cid | &1])
    end)
  end

  defp components_cids_tree(components_cids_map, parent_cid) do
    case Map.pop(components_cids_map, parent_cid) do
      {nil, _} ->
        nil

      {children_cids, components_cids_map} ->
        Enum.map(children_cids, fn cid ->
          {cid, components_cids_tree(components_cids_map, cid)}
        end)
        |> Enum.into(%{})
    end
  end

  defp add_children(parent_element, nil, _live_components), do: parent_element

  defp add_children(parent_element, children_cids_map, live_components) do
    Enum.reduce(children_cids_map, parent_element, fn {cid, children_cids_map}, parent_element ->
      child =
        live_components
        |> Enum.find(fn element -> element.cid == cid end)
        |> add_children(children_cids_map, live_components)

      LiveElement.add_child(parent_element, child)
    end)
  end
end
