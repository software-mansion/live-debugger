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

    - `id`: The id of the node. It uses dot notation to represent the path to the node.
    - `open?`: Whether the node is expanded
    - `kind`: The type of the node (e.g., :atom, :list, :map).
    - `children`: A map of child nodes with keys (integer indices for lists/tuples, actual keys for maps).
    - `content`: Display elements that represent the content of the node when has no children or not expanded.
    - `expanded_before`: Display elements shown before the node's children when expanded.
    - `expanded_after`: Display elements shown after the node's children when expanded.
    """
    defstruct [:id, :kind, :children, :content, :expanded_before, :expanded_after, open?: false]

    @type kind() :: :atom | :binary | :number | :tuple | :list | :map | :struct | :regex | :other

    @type t :: %__MODULE__{
            id: String.t(),
            kind: kind(),
            open?: boolean(),
            children: [{any(), t()}],
            content: [DisplayElement.t()],
            expanded_before: [DisplayElement.t()] | nil,
            expanded_after: [DisplayElement.t()] | nil
          }

    @spec has_children?(t()) :: boolean()
    def has_children?(%__MODULE__{children: []}), do: false
    def has_children?(%__MODULE__{}), do: true

    @spec children_number(t()) :: integer()
    def children_number(%__MODULE__{children: children}), do: length(children)
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
    to_node(term, [], "root")
  end

  @spec update_by_id(term(), String.t(), (TermNode.t() -> {:ok, TermNode.t()} | {:error, any()})) ::
          {:ok, term()} | {:error, any()}
  def update_by_id(term, "root", update_fn) do
    update_fn.(term)
  end

  def update_by_id(term, "root" <> _ = id, update_fn) do
    ["root" | string_path] = String.split(id, ".")
    path = string_path |> Enum.map(&String.to_integer/1) |> IO.inspect(label: "path")
    update_by_path(term, path, update_fn)
  end

  defp update_by_path(term, [index | path], update_fn) do
    with {key, child} <- Enum.at(term.children, index),
         {:ok, updated_child} <- update_by_path(child, path, update_fn) do
      children = List.replace_at(term.children, index, {key, updated_child})
      {:ok, %TermNode{term | children: children}}
    else
      nil ->
        {:error, :child_not_found}

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp update_by_path(term, [], update_fn) do
    update_fn.(term)
  end

  @spec to_node(term(), [DisplayElement.t()], String.t()) :: TermNode.t()
  defp to_node(string, suffix, id_path) when is_binary(string) do
    leaf_node(id_path, :binary, [green(inspect(string)) | suffix])
  end

  defp to_node(atom, suffix, id_path) when is_atom(atom) do
    span =
      if atom in [nil, true, false] do
        magenta(inspect(atom))
      else
        blue(inspect(atom))
      end

    leaf_node(id_path, :atom, [span | suffix])
  end

  defp to_node(number, suffix, id_path) when is_number(number) do
    leaf_node(id_path, :number, [blue(inspect(number)) | suffix])
  end

  defp to_node({}, suffix, id_path) do
    leaf_node(id_path, :tuple, [black("{}") | suffix])
  end

  defp to_node(tuple, suffix, id_path) when is_tuple(tuple) do
    size = tuple_size(tuple)
    children = tuple |> Tuple.to_list() |> to_children(size, id_path)

    branch_node(id_path, :tuple, [black("{...}") | suffix], children, [black("{")], [
      black("}") | suffix
    ])
  end

  defp to_node([], suffix, id_path) do
    leaf_node(id_path, :list, [black("[]") | suffix])
  end

  defp to_node(list, suffix, id_path) when is_list(list) do
    size = length(list)

    children =
      if Keyword.keyword?(list) do
        to_key_value_children(list, size, id_path)
      else
        to_children(list, size, id_path)
      end

    branch_node(id_path, :list, [black("[...]") | suffix], children, [black("[")], [
      black("]") | suffix
    ])
  end

  defp to_node(%Regex{} = regex, suffix, id_path) do
    leaf_node(id_path, :regex, [black(inspect(regex)) | suffix])
  end

  defp to_node(%module{} = struct, suffix, id_path) when is_struct(struct) do
    content =
      if Inspect.impl_for(struct) in [Inspect.Any, Inspect.Phoenix.LiveView.Socket] do
        [black("%"), blue(inspect(module)), black("{...}") | suffix]
      else
        [black(inspect(struct)) | suffix]
      end

    map = Map.from_struct(struct)
    size = map_size(map)
    children = map |> Map.to_list() |> to_key_value_children(size, id_path)

    branch_node(
      id_path,
      :struct,
      content,
      children,
      [black("%"), blue(inspect(module)), black("{")],
      [black("}") | suffix]
    )
  end

  defp to_node(%{} = map, suffix, id_path) when map_size(map) == 0 do
    leaf_node(id_path, :map, [black("%{}") | suffix])
  end

  defp to_node(map, suffix, id_path) when is_map(map) do
    size = map_size(map)
    children = map |> Enum.sort() |> to_key_value_children(size, id_path)

    branch_node(id_path, :map, [black("%{...}") | suffix], children, [black("%{")], [
      black("}") | suffix
    ])
  end

  defp to_node(other, suffix, id_path) do
    leaf_node(id_path, :other, [black(inspect(other)) | suffix])
  end

  @spec to_key_value_node({any(), any()}, [DisplayElement.t()], String.t()) ::
          {any(), TermNode.t()}
  defp to_key_value_node({key, value}, suffix, id_path) do
    {key_span, sep_span} =
      case to_node(key, [], "not_used_id_path") do
        %TermNode{content: [%DisplayElement{text: ":" <> name} = span]} when is_atom(key) ->
          {%{span | text: name <> ":"}, black(" ")}

        %TermNode{content: [span]} ->
          {%{span | text: inspect(key, width: :infinity)}, black(" => ")}

        %TermNode{content: _content} ->
          {%DisplayElement{text: inspect(key, width: :infinity), color: "text-code-1"},
           black(" => ")}
      end

    node = to_node(value, suffix, id_path)
    node = %TermNode{node | content: [key_span, sep_span | node.content]}

    node =
      if TermNode.has_children?(node) do
        %TermNode{node | expanded_before: [key_span, sep_span | node.expanded_before]}
      else
        node
      end

    {key, node}
  end

  @spec to_children(list(), integer(), String.t()) :: [{integer(), TermNode.t()}]
  defp to_children(items, container_size, id_path) do
    Enum.with_index(items, fn item, index ->
      {index, to_node(item, suffix(index, container_size), "#{id_path}.#{index}")}
    end)
  end

  @spec to_key_value_children([{any(), any()}], integer(), String.t()) :: [{any(), TermNode.t()}]
  defp to_key_value_children(items, container_size, id_path) do
    Enum.with_index(items, fn item, index ->
      to_key_value_node(item, suffix(index, container_size), "#{id_path}.#{index}")
    end)
  end

  defp suffix(index, container_size) do
    if index != container_size - 1 do
      [black(",")]
    else
      []
    end
  end

  defp leaf_node(id_path, kind, content) when is_binary(id_path) and is_atom(kind) do
    %TermNode{
      id: id_path,
      kind: kind,
      content: content,
      children: [],
      expanded_before: nil,
      expanded_after: nil
    }
  end

  defp branch_node(id_path, kind, content, children, expanded_before, expanded_after)
       when is_binary(id_path) and is_atom(kind) do
    %TermNode{
      id: id_path,
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
