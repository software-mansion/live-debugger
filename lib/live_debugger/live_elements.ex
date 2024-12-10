defmodule LiveDebugger.LiveElements do
  alias __MODULE__.Component, as: LiveComponentElement
  alias __MODULE__.View, as: LiveViewElement
  alias LiveDebugger.LiveElement

  @type live_element() :: LiveViewElement.t() | LiveComponentElement.t()

  @forbidden_assigns_keys ~w(__changed__ live_debug live_action)a

  @doc """
  Returns LiveView root elment and all its children live elements
  """
  @spec live_elements(state :: map()) :: {:ok, {LiveViewElement.t(), [live_element()]}} | {:error, term()}
  def live_elements(state) do
    with {:ok, root} <- get_root_element(state),
        {components, _, _} <- Map.get(state, :components, {:error, :invalid_state}) do
          elements =
            Enum.map(components, fn {cid, element} ->
              {module, id, assigns, _, _} = element

              %LiveComponentElement{
                id: id,
                cid: cid,
                module: module,
                assigns: filter_assigns(assigns),
                children: []
              }
            end)

          {:ok, {root, elements}}
        end
  end

  @doc """
  Creates tree using LiveElemets where root is a LiveView
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
    {children_cids, components_cids_map} = Map.pop(components_cids_map, parent_cid, nil)

    if children_cids do
      Enum.map(children_cids, fn cid ->
        {cid, components_cids_tree(components_cids_map, cid)}
      end)
      |> Enum.into(%{})
    else
      nil
    end
  end

  defp add_children(parent_element, nil, _elements), do: parent_element

  defp add_children(parent_element, children_cids_map, elements) do
    Enum.reduce(children_cids_map, parent_element, fn {cid, children_cids_map}, parent_element ->
      child =
        elements
        |> Enum.find(fn element -> element.cid == cid end)
        |> add_children(children_cids_map, elements)

      LiveElement.add_child(parent_element, child)
    end)
  end

  defp get_root_element(%{socket: %{id: id, view: view, assigns: assigns}}) do
    {:ok, %LiveViewElement{
      id: id,
      module: view,
      assigns: filter_assigns(assigns),
      children: []
    }}
  end

  defp get_root_element(_), do: {:error, :invalid_state}

  defp filter_assigns(assigns) do
    assigns
    |> Map.to_list()
    |> Enum.reject(fn {key, _} -> key in @forbidden_assigns_keys end)
    |> Enum.into(%{})
  end
end
