defmodule LiveDebugger.LiveComponents.ElixirDisplay do
  use LiveDebuggerWeb, :live_component

  @max_auto_expand_size 6

  @impl true
  def update(assigns, socket) do
    socket
    |> assign(:node, assigns.node)
    |> assign(:level, assigns.level)
    |> assign(:expanded?, auto_expand?(assigns.node, assigns.level))
    |> ok()
  end

  attr(:node, :any, required: true)
  attr(:level, :integer, required: true)
  attr(:expanded?, :boolean, required: true)

  @impl true
  def render(assigns) do
    ~H"""
    <div class="font-mono text-sm text-gray-500">
      <div>
        <div
          class={"flex #{if has_children?(@node), do: "cursor-pointer"}"}
          phx-click={if has_children?(@node), do: "expand-click"}
          phx-target={@myself}
        >
          <div class="mr-0.5 inline-block w-[2ch] flex-shrink-0">
            <.icon
              :if={has_children?(@node) and @expanded?}
              name="hero-chevron-up-micro"
              class="w-4 h-4"
            />
            <.icon
              :if={has_children?(@node) and not @expanded?}
              name="hero-chevron-right-micro"
              class="w-4 h-4"
            />
          </div>
          <div>
            <%= if has_children?(@node) and @expanded? do %>
              <.text_items items={@node.expanded_before} />
            <% else %>
              <.text_items items={@node.content} />
            <% end %>
          </div>
        </div>
      </div>
      <div :if={has_children?(@node) and @expanded?}>
        <ol class="m-0 ml-[2ch] block list-none p-0">
          <%= for child <- @node.children do %>
            <li class="flex flex-col">
              <.live_component id={tmp_id()} module={__MODULE__} node={child} level={@level + 1} />
            </li>
          <% end %>
        </ol>
        <div class="ml-[2ch]">
          <.text_items items={@node.expanded_after} />
        </div>
      </div>
    </div>
    """
  end

  @impl true
  def handle_event("expand-click", _params, socket) do
    socket
    |> assign(:expanded?, not socket.assigns.expanded?)
    |> noreply()
  end

  attr(:items, :list, required: true)

  defp text_items(assigns) do
    ~H"""
    <div class="flex">
      <%= for item <- @items do %>
        <span class="whitespace-pre" style={text_items_style(item)}>{item.text}</span>
      <% end %>
    </div>
    """
  end

  defp text_items_style(item) do
    if item.color, do: "color: #{item.color};", else: ""
  end

  defp tmp_id() do
    to_string(:erlang.ref_to_list(:erlang.make_ref()))
  end

  defp auto_expand?(_node, 1), do: true

  defp auto_expand?(node, _level) do
    node.kind == "tuple" and children_number(node) <= @max_auto_expand_size
  end

  defp has_children?(%{children: nil} = _node), do: false
  defp has_children?(_node), do: true

  defp children_number(%{children: nil} = _node), do: 0
  defp children_number(%{children: children}), do: length(children)

  def parse_item(item) do
    to_node(item, [])
  end

  def to_node(string, suffix) when is_binary(string) do
    leaf_node("binary", [green(inspect(string)) | suffix])
  end

  def to_node(atom, suffix) when is_atom(atom) do
    span =
      if atom in [nil, true, false] do
        magenta(inspect(atom))
      else
        blue(inspect(atom))
      end

    leaf_node("atom", [span | suffix])
  end

  def to_node(number, suffix) when is_number(number) do
    leaf_node("number", [blue(inspect(number)) | suffix])
  end

  def to_node({}, suffix) do
    leaf_node("tuple", [black("{}") | suffix])
  end

  def to_node(tuple, suffix) when is_tuple(tuple) do
    size = tuple_size(tuple)
    children = tuple |> Tuple.to_list() |> to_children(size)
    branch_node("tuple", [black("{...}") | suffix], children, [black("{")], [black("}") | suffix])
  end

  def to_node([], suffix) do
    leaf_node("list", [black("[]") | suffix])
  end

  def to_node(list, suffix) when is_list(list) do
    size = length(list)

    children =
      if Keyword.keyword?(list) do
        to_key_value_children(list, size)
      else
        to_children(list, size)
      end

    branch_node("list", [black("[...]") | suffix], children, [black("[")], [black("]") | suffix])
  end

  def to_node(%Regex{} = regex, suffix) do
    leaf_node("regex", [red(inspect(regex)) | suffix])
  end

  def to_node(%module{} = struct, suffix) when is_struct(struct) do
    if Inspect.impl_for(struct) not in [Inspect.Any, Inspect.Phoenix.LiveView.Socket] do
      leaf_node("struct", [black(inspect(struct)) | suffix])
    else
      map = Map.from_struct(struct)
      size = map_size(map)
      children = to_key_value_children(map, size)

      branch_node(
        "struct",
        [black("%"), blue(inspect(module)), black("{...}") | suffix],
        children,
        [black("%"), blue(inspect(module)), black("{")],
        [black("}") | suffix]
      )
    end
  end

  def to_node(%{} = map, suffix) when map_size(map) == 0 do
    leaf_node("map", [black("%{}") | suffix])
  end

  def to_node(map, suffix) when is_map(map) do
    size = map_size(map)
    children = map |> Enum.sort() |> to_key_value_children(size)
    branch_node("map", [black("%{...}") | suffix], children, [black("%{")], [black("}") | suffix])
  end

  def to_node(other, suffix) do
    leaf_node("other", [black(inspect(other)) | suffix])
  end

  defp to_key_value_node({key, value}, suffix) do
    {key_span, sep_span} =
      case to_node(key, []) do
        %{content: [%{text: ":" <> name} = span]} when is_atom(key) ->
          {%{span | text: name <> ":"}, black(" ")}

        %{content: [span]} ->
          {%{span | text: inspect(key, width: :infinity)}, black(" => ")}
      end

    case to_node(value, suffix) do
      %{content: content, children: nil} = node ->
        %{node | content: [key_span, sep_span | content]}

      %{content: content, expanded_before: expanded_before} = node ->
        %{
          node
          | content: [key_span, sep_span | content],
            expanded_before: [key_span, sep_span | expanded_before]
        }
    end
  end

  defp to_children(items, container_size) do
    Enum.with_index(items, fn item, index ->
      to_node(item, suffix(index, container_size))
    end)
  end

  defp to_key_value_children(items, container_size) do
    Enum.with_index(items, fn item, index ->
      to_key_value_node(item, suffix(index, container_size))
    end)
  end

  defp suffix(index, container_size) do
    if index != container_size - 1 do
      [black(",")]
    else
      []
    end
  end

  defp leaf_node(kind, content) do
    %{
      kind: kind,
      content: content,
      children: nil,
      expanded_before: nil,
      expanded_after: nil
    }
  end

  defp branch_node(kind, content, children, expanded_before, expanded_after) do
    %{
      kind: kind,
      content: content,
      children: children,
      expanded_before: expanded_before,
      expanded_after: expanded_after
    }
  end

  defp black(text), do: %{text: text, color: nil}
  defp red(text), do: %{text: text, color: "red"}
  defp green(text), do: %{text: text, color: "green"}
  defp blue(text), do: %{text: text, color: "blue"}
  defp magenta(text), do: %{text: text, color: "magenta"}
end
