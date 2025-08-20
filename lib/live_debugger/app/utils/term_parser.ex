defmodule LiveDebugger.App.Utils.TermParser do
  @moduledoc """
  This module provides functions to parse terms into display tree.
  Based on [Kino.Tree](https://github.com/livebook-dev/kino/blob/main/lib/kino/tree.ex)
  """

  defmodule DisplayElement do
    @moduledoc false
    defstruct [:text, color: nil]

    @type t :: %__MODULE__{
            text: String.t(),
            color: String.t() | nil
          }
  end

  defmodule TermNode do
    @moduledoc """
    Represents a node in the display tree.

    - `kind`: The type of the node (e.g., "atom", "list", "map").
    - `children`: A list of child nodes.
    - `content`: Display elements that represent the content of the node when has no children or not expanded.
    - `expanded_before`: Display elements shown before the node's children when expanded.
    - `expanded_after`: Display elements shown after the node's children when expanded.
    """
    defstruct [:kind, :children, :content, :expanded_before, :expanded_after]

    @type t :: %__MODULE__{
            kind: String.t(),
            children: [TermNode.t()],
            content: [DisplayElement.t()],
            expanded_before: [DisplayElement.t()] | nil,
            expanded_after: [DisplayElement.t()] | nil
          }
  end

  @spec term_to_copy_string(term()) :: String.t()
  def term_to_copy_string(term) do
    term
    |> inspect(limit: :infinity, pretty: true, structs: false)
    |> String.replace(~r/#PID<\d+\.\d+\.\d+>/, fn pid_string ->
      [pid] = Regex.run(~r/\d+\.\d+\.\d+/, pid_string)
      ":erlang.list_to_pid(~c\"<#{pid}>\")"
    end)
    |> String.replace(~r/#.+?<.*?>/, &"\"#{&1}\"")
  end

  @spec term_to_display_tree(term()) :: TermNode.t()
  def term_to_display_tree(term) do
    to_node(term, [])
  end

  @spec to_node(term(), [DisplayElement.t()]) :: TermNode.t()
  defp to_node(string, suffix) when is_binary(string) do
    leaf_node("binary", [green(inspect(string)) | suffix])
  end

  defp to_node(atom, suffix) when is_atom(atom) do
    span =
      if atom in [nil, true, false] do
        magenta(inspect(atom))
      else
        blue(inspect(atom))
      end

    leaf_node("atom", [span | suffix])
  end

  defp to_node(number, suffix) when is_number(number) do
    leaf_node("number", [blue(inspect(number)) | suffix])
  end

  defp to_node({}, suffix) do
    leaf_node("tuple", [black("{}") | suffix])
  end

  defp to_node(tuple, suffix) when is_tuple(tuple) do
    size = tuple_size(tuple)
    children = tuple |> Tuple.to_list() |> to_children(size)
    branch_node("tuple", [black("{...}") | suffix], children, [black("{")], [black("}") | suffix])
  end

  defp to_node([], suffix) do
    leaf_node("list", [black("[]") | suffix])
  end

  defp to_node(list, suffix) when is_list(list) do
    size = length(list)

    children =
      if Keyword.keyword?(list) do
        to_key_value_children(list, size)
      else
        to_children(list, size)
      end

    branch_node("list", [black("[...]") | suffix], children, [black("[")], [black("]") | suffix])
  end

  defp to_node(%Regex{} = regex, suffix) do
    leaf_node("regex", [black(inspect(regex)) | suffix])
  end

  defp to_node(%module{} = struct, suffix) when is_struct(struct) do
    content =
      if Inspect.impl_for(struct) in [Inspect.Any, Inspect.Phoenix.LiveView.Socket] do
        [black("%"), blue(inspect(module)), black("{...}") | suffix]
      else
        [black(inspect(struct)) | suffix]
      end

    map = Map.from_struct(struct)
    size = map_size(map)
    children = to_key_value_children(map, size)

    branch_node(
      "struct",
      content,
      children,
      [black("%"), blue(inspect(module)), black("{")],
      [black("}") | suffix]
    )
  end

  defp to_node(%{} = map, suffix) when map_size(map) == 0 do
    leaf_node("map", [black("%{}") | suffix])
  end

  defp to_node(map, suffix) when is_map(map) do
    size = map_size(map)
    children = map |> Enum.sort() |> to_key_value_children(size)
    branch_node("map", [black("%{...}") | suffix], children, [black("%{")], [black("}") | suffix])
  end

  defp to_node(other, suffix) do
    leaf_node("other", [black(inspect(other)) | suffix])
  end

  defp to_key_value_node({key, value}, suffix) do
    {key_span, sep_span} =
      case to_node(key, []) do
        %TermNode{content: [%DisplayElement{text: ":" <> name} = span]} when is_atom(key) ->
          {%{span | text: name <> ":"}, black(" ")}

        %TermNode{content: [span]} ->
          {%{span | text: inspect(key, width: :infinity)}, black(" => ")}

        %TermNode{content: _content} ->
          {%DisplayElement{text: inspect(key, width: :infinity), color: "text-code-1"},
           black(" => ")}
      end

    case to_node(value, suffix) do
      %TermNode{content: content, children: []} = node ->
        %{node | content: [key_span, sep_span | content]}

      %TermNode{content: content, expanded_before: expanded_before} = node ->
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
    %TermNode{
      kind: kind,
      content: content,
      children: [],
      expanded_before: nil,
      expanded_after: nil
    }
  end

  defp branch_node(kind, content, children, expanded_before, expanded_after) do
    %TermNode{
      kind: kind,
      content: content,
      children: children,
      expanded_before: expanded_before,
      expanded_after: expanded_after
    }
  end

  defp blue(text), do: %DisplayElement{text: text, color: "text-code-1"}
  defp black(text), do: %DisplayElement{text: text, color: "text-code-2"}
  defp magenta(text), do: %DisplayElement{text: text, color: "text-code-3"}
  defp green(text), do: %DisplayElement{text: text, color: "text-code-4"}
end
