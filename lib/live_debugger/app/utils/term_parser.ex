defmodule LiveDebugger.App.Utils.TermParser do
  @moduledoc """
  This module provides functions to parse terms into display tree.
  Based on [Kino.Tree](https://github.com/livebook-dev/kino/blob/main/lib/kino/tree.ex)
  """

  alias LiveDebugger.App.Utils.TermDiffer.Diff
  alias LiveDebugger.App.Utils.TermDiffer

  require Logger

  defmodule DisplayElement do
    @moduledoc false
    defstruct [:text, color: nil]

    @type t :: %__MODULE__{
            text: String.t(),
            color: String.t() | nil
          }

    @spec blue(String.t()) :: t()
    def blue(text), do: %__MODULE__{text: text, color: "text-code-1"}

    @spec black(String.t()) :: t()
    def black(text), do: %__MODULE__{text: text, color: "text-code-2"}

    @spec magenta(String.t()) :: t()
    def magenta(text), do: %__MODULE__{text: text, color: "text-code-3"}

    @spec green(String.t()) :: t()
    def green(text), do: %__MODULE__{text: text, color: "text-code-4"}
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

    @type ok_error() :: {:ok, t()} | {:error, any()}

    @spec has_children?(t()) :: boolean()
    def has_children?(%__MODULE__{children: []}), do: false
    def has_children?(%__MODULE__{}), do: true

    @spec children_number(t()) :: integer()
    def children_number(%__MODULE__{children: children}), do: length(children)

    @spec add_suffix(t(), [DisplayElement.t()]) :: t()
    def add_suffix(
          %__MODULE__{content: content, expanded_after: expanded_after} = term_node,
          suffix
        )
        when is_list(suffix) do
      content = content ++ suffix
      expanded_after = expanded_after ++ suffix
      %__MODULE__{term_node | content: content, expanded_after: expanded_after}
    end

    @spec remove_suffix(t()) :: t()
    def remove_suffix(%__MODULE__{content: content, expanded_after: expanded_after} = term_node) do
      content = content |> Enum.reverse() |> tl() |> Enum.reverse()
      expanded_after = expanded_after |> Enum.reverse() |> tl() |> Enum.reverse()

      %__MODULE__{term_node | content: content, expanded_after: expanded_after}
    end

    @spec add_prefix(t(), [DisplayElement.t()]) :: t()
    def add_prefix(
          %__MODULE__{content: content, expanded_before: expanded_before} = term_node,
          prefix
        )
        when is_list(prefix) do
      content = prefix ++ content
      expanded_before = prefix ++ expanded_before
      %__MODULE__{term_node | content: content, expanded_before: expanded_before}
    end

    @spec remove_child(t(), any()) :: {:ok, t()} | {:error, any()}
    def remove_child(%__MODULE__{children: children} = term, key) do
      children
      |> Enum.find_index(fn {child_key, _} -> child_key == key end)
      |> case do
        nil ->
          {:error, :child_not_found}

        index ->
          children = List.delete_at(children, index)
          {:ok, %TermNode{term | children: children}}
      end
    end

    @spec update_child(t(), any(), (t() -> t())) :: {:ok, t()} | {:error, any()}
    def update_child(%__MODULE__{children: children} = term, key, update_fn) do
      children
      |> Enum.with_index()
      |> Enum.filter(fn {{child_key, _}, _} -> child_key == key end)
      |> case do
        [{{^key, child}, index}] ->
          children = List.replace_at(children, index, {key, update_fn.(child)})
          {:ok, %TermNode{term | children: children}}

        _ ->
          {:error, :child_not_found}
      end
    end
  end

  @comma_suffix DisplayElement.black(",")

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

  @doc """
  It creates an indexed TermNode tree with comma suffixes and first element opened.
  """
  @spec term_to_display_tree(term()) :: TermNode.t()
  def term_to_display_tree(term) do
    node =
      term
      |> to_node()
      |> index_term_node()
      |> update_comma_suffixes()

    %TermNode{node | open?: true}
  end

  @spec update_by_id(TermNode.t(), String.t(), (TermNode.t() -> TermNode.ok_error())) ::
          TermNode.ok_error()
  def update_by_id(term_node, "root", update_fn) do
    update_fn.(term_node)
  end

  def update_by_id(term_node, "root" <> _ = id, update_fn) do
    ["root" | string_path] = String.split(id, ".")
    path = string_path |> Enum.map(&String.to_integer/1)
    update_by_path(term_node, path, update_fn)
  end

  @spec update_by_diff(TermNode.t(), Diff.t()) :: TermNode.ok_error()
  def update_by_diff(term_node, diff) do
    term_node =
      term_node
      |> update_by_diff!(diff)
      |> index_term_node()
      |> update_comma_suffixes()

    {:ok, term_node}
  rescue
    error ->
      {:error, "Invalid diff or term node: #{inspect(error)}"}
  end

  @spec update_by_diff!(TermNode.t(), Diff.t(), Keyword.t()) :: TermNode.t()
  defp update_by_diff!(term_node, diff, opts \\ [])

  defp update_by_diff!(_, %Diff{type: :primitive} = diff, opts) do
    term = TermDiffer.primitive_new_value(diff)

    maybe_to_key_value_node(term, opts)
  end

  defp update_by_diff!(term_node, %Diff{type: type, ins: ins, del: del}, _opts)
       when type in [:list, :tuple] do
    term_node =
      Enum.reduce(del, term_node, fn {index, _}, term_node ->
        {:ok, term_node} = TermNode.remove_child(term_node, index)
        term_node
      end)

    term_node =
      Enum.reduce(ins, term_node, fn {index, term}, term_node ->
        children = List.insert_at(term_node.children, index, {index, to_node(term)})
        %TermNode{term_node | children: children}
      end)

    term_node
  end

  defp update_by_diff!(term_node, %Diff{type: :struct, diff: diff}, _opts) do
    Enum.reduce(diff, term_node, fn {key, child_diff}, term_node ->
      {:ok, term_node} =
        TermNode.update_child(term_node, key, fn child ->
          update_by_diff!(child, child_diff, key: key)
        end)

      term_node
    end)
  end

  defp update_by_diff!(term_node, %Diff{type: :map, ins: ins, del: del, diff: diff}, _opts) do
    term_node =
      Enum.reduce(del, term_node, fn {key, _}, term_node ->
        {:ok, term_node} = TermNode.remove_child(term_node, key)
        term_node
      end)

    child_keys = term_node.children |> Enum.map(fn {key, _} -> key end)

    {term_node, _} =
      Enum.reduce(ins, {term_node, child_keys}, fn {key, term}, {term_node, child_keys} ->
        child_term_node = maybe_to_key_value_node(term, key: key)
        child_keys = Enum.sort(child_keys ++ [key])
        index = Enum.find_index(child_keys, &(&1 == key))
        children = List.insert_at(term_node.children, index, child_term_node)
        {%TermNode{term_node | children: children}, child_keys}
      end)

    Enum.reduce(diff, term_node, fn {key, child_diff}, term_node ->
      {:ok, term_node} =
        TermNode.update_child(term_node, key, fn child ->
          update_by_diff!(child, child_diff, key: key)
        end)

      term_node
    end)
  end

  defp maybe_to_key_value_node(term, opts) do
    case Keyword.get(opts, :key, nil) do
      nil ->
        to_node(term)

      key ->
        {key, term}
        |> to_key_value_node()
        |> elem(1)
    end
  end

  @spec index_term_node(TermNode.t()) :: TermNode.t()
  defp index_term_node(%TermNode{children: children} = term_node, id_path \\ "root") do
    new_children =
      children
      |> Enum.with_index()
      |> Enum.map(fn {{key, child}, idx} ->
        {key, index_term_node(child, "#{id_path}.#{idx}")}
      end)

    %TermNode{term_node | children: new_children, id: id_path}
  end

  @spec update_comma_suffixes(TermNode.t()) :: TermNode.t()
  defp update_comma_suffixes(%TermNode{children: []} = term_node), do: term_node

  defp update_comma_suffixes(%TermNode{children: children} = term_node) do
    size = length(children)

    children =
      Enum.with_index(children, fn
        {key, child}, index ->
          child = update_comma_suffixes(child)

          last_child? = index == size - 1

          child =
            case {last_child?, has_comma_suffix?(child)} do
              {true, true} ->
                child |> TermNode.remove_suffix()

              {false, false} ->
                child |> TermNode.add_suffix([@comma_suffix])

              _ ->
                child
            end

          {key, child}
      end)

    %TermNode{term_node | children: children}
  end

  @spec update_by_path(TermNode.t(), [integer()], (TermNode.t() -> TermNode.ok_error())) ::
          TermNode.ok_error()
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

  @spec to_node(term()) :: TermNode.t()
  defp to_node(string) when is_binary(string) do
    node(:binary, [DisplayElement.green(inspect(string))])
  end

  defp to_node(atom) when is_atom(atom) do
    span =
      if atom in [nil, true, false] do
        DisplayElement.magenta(inspect(atom))
      else
        DisplayElement.blue(inspect(atom))
      end

    node(:atom, [span])
  end

  defp to_node(number) when is_number(number) do
    node(:number, [DisplayElement.blue(inspect(number))])
  end

  defp to_node({}) do
    node(:tuple, [DisplayElement.black("{}")])
  end

  defp to_node(tuple) when is_tuple(tuple) do
    children = tuple |> Tuple.to_list() |> to_children()

    node(:tuple, [DisplayElement.black("{...}")],
      children: children,
      expanded_before: [DisplayElement.black("{")],
      expanded_after: [DisplayElement.black("}")]
    )
  end

  defp to_node([]) do
    node(:list, [DisplayElement.black("[]")])
  end

  defp to_node(list) when is_list(list) do
    children =
      if Keyword.keyword?(list) do
        to_key_value_children(list)
      else
        to_children(list)
      end

    node(:list, [DisplayElement.black("[...]")],
      children: children,
      expanded_before: [DisplayElement.black("[")],
      expanded_after: [DisplayElement.black("]")]
    )
  end

  defp to_node(%Regex{} = regex) do
    node(:regex, [DisplayElement.black(inspect(regex))])
  end

  defp to_node(%module{} = struct) when is_struct(struct) do
    content =
      if Inspect.impl_for(struct) in [Inspect.Any, Inspect.Phoenix.LiveView.Socket] do
        [
          DisplayElement.black("%"),
          DisplayElement.blue(inspect(module)),
          DisplayElement.black("{...}")
        ]
      else
        [DisplayElement.black(inspect(struct))]
      end

    children =
      struct
      |> Map.from_struct()
      |> Map.to_list()
      |> to_key_value_children()

    node(
      :struct,
      content,
      children: children,
      expanded_before: [
        DisplayElement.black("%"),
        DisplayElement.blue(inspect(module)),
        DisplayElement.black("{")
      ],
      expanded_after: [DisplayElement.black("}")]
    )
  end

  defp to_node(%{} = map) when map_size(map) == 0 do
    node(:map, [DisplayElement.black("%{}")])
  end

  defp to_node(map) when is_map(map) do
    children = map |> Enum.sort() |> to_key_value_children()

    node(:map, [DisplayElement.black("%{...}")],
      children: children,
      expanded_before: [DisplayElement.black("%{")],
      expanded_after: [DisplayElement.black("}")]
    )
  end

  defp to_node(other) do
    node(:other, [DisplayElement.black(inspect(other))])
  end

  defp to_key_value_node({key, value}) do
    {key_span, sep_span} =
      case to_node(key) do
        %TermNode{content: [%DisplayElement{text: ":" <> name} = span]} when is_atom(key) ->
          {%{span | text: name <> ":"}, DisplayElement.black(" ")}

        %TermNode{content: [span]} ->
          {%{span | text: inspect(key, width: :infinity)}, DisplayElement.black(" => ")}

        %TermNode{content: _content} ->
          {%DisplayElement{text: inspect(key, width: :infinity), color: "text-code-1"},
           DisplayElement.black(" => ")}
      end

    node = value |> to_node() |> TermNode.add_prefix([key_span, sep_span])

    {key, node}
  end

  defp to_children(items) when is_list(items) do
    Enum.with_index(items, fn item, index ->
      {index, to_node(item)}
    end)
  end

  defp to_key_value_children(items) when is_list(items) do
    Enum.map(items, &to_key_value_node/1)
  end

  defp node(kind, content, opts \\ []) when is_atom(kind) do
    children = Keyword.get(opts, :children, [])
    expanded_before = Keyword.get(opts, :expanded_before, [])
    expanded_after = Keyword.get(opts, :expanded_after, [])
    open? = Keyword.get(opts, :open?, false)
    id = Keyword.get(opts, :id, "not_indexed")

    %TermNode{
      id: id,
      kind: kind,
      content: content,
      children: children,
      expanded_before: expanded_before,
      expanded_after: expanded_after,
      open?: open?
    }
  end

  defp has_comma_suffix?(%TermNode{content: content, expanded_after: expanded_after}) do
    content? = last_item_equal?(content, @comma_suffix)
    expanded_after? = last_item_equal?(expanded_after, @comma_suffix)

    if content? != expanded_after?,
      do: raise("Content and expanded_after must have the same comma suffix")

    content?
  end

  defp last_item_equal?([_ | _] = items, item) do
    items |> Enum.reverse() |> hd() |> Kernel.==(item)
  end

  defp last_item_equal?([], _), do: false
end
