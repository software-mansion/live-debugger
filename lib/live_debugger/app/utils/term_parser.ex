defmodule LiveDebugger.App.Utils.TermParser do
  @moduledoc """
  This module provides functions to parse elixir terms.
  """

  alias LiveDebugger.App.Utils.TermDiffer.Diff
  alias LiveDebugger.App.Utils.TermDiffer
  alias LiveDebugger.App.Utils.TermNode.DisplayElement
  alias LiveDebugger.App.Utils.TermNode

  @doc """
  Convert term into infinite string which can be copied to IEx console.
  """
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
  It creates a TermNode tree ready for display.

  It includes:
  - Indexing the tree
  - Adding comma suffixes
  - Opening proper elements
  """
  @spec term_to_display_tree(term(), open_settings: TermNode.open_settings()) :: TermNode.t()
  def term_to_display_tree(term, opts \\ []) do
    term
    |> to_node()
    |> index_term_node()
    |> update_comma_suffixes()
    |> TermNode.open_with_settings(Keyword.get(opts, :open_settings, :default))
  end

  @doc """
  Updates the term node by id.

  ## Examples

      iex> term_node = TermParser.term_to_display_tree(term)
      iex> update_by_id(term_node, "root.0", fn term_node ->
      ...>   %{term_node | content: [DisplayElement.blue("new value")]}
      ...> end)
      {:ok, %TermNode{...}}
  """
  @spec update_by_id(TermNode.t(), String.t(), (TermNode.t() -> TermNode.t())) ::
          TermNode.ok_error()
  def update_by_id(term_node, path, update_fn)

  def update_by_id(term_node, "root", update_fn) do
    {:ok, update_fn.(term_node)}
  end

  def update_by_id(term_node, "root" <> _ = id, update_fn) do
    ["root" | string_path] = String.split(id, ".")
    path = string_path |> Enum.map(&String.to_integer/1)
    update_by_path(term_node, path, update_fn)
  end

  @doc """
  Updates the term node using calculated term #{Diff}.

  ## Examples

      iex> term_node = TermParser.term_to_display_tree(term)
      iex> diff = TermDiffer.diff(term, new_term)
      iex> update_by_diff(term_node, diff)
      {:ok, %TermNode{...}}
  """
  @spec update_by_diff(TermNode.t(), Diff.t()) :: TermNode.ok_error()
  def update_by_diff(term_node, diff) do
    term_node =
      term_node
      |> update_by_diff!(diff)
      |> index_term_node()
      |> update_comma_suffixes()
      |> TermNode.set_pulse(false, recursive: false)

    {:ok, term_node}
  rescue
    error ->
      {:error, "Invalid diff or term node: #{inspect(error)}"}
  end

  @spec update_by_path(TermNode.t(), [integer()], (TermNode.t() -> TermNode.t())) ::
          TermNode.ok_error()
  defp update_by_path(%TermNode{} = term, [index | path], update_fn) do
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
    {:ok, update_fn.(term)}
  end

  @spec update_by_diff!(TermNode.t(), Diff.t(), Keyword.t()) :: TermNode.t()
  defp update_by_diff!(term_node, diff, opts \\ [])

  defp update_by_diff!(term_node, %Diff{type: :equal}, _opts), do: term_node

  defp update_by_diff!(_, %Diff{type: :primitive} = diff, opts) do
    term = TermDiffer.primitive_new_value(diff)

    case Keyword.get(opts, :key, nil) do
      nil ->
        to_node(term)

      key ->
        {key, term}
        |> to_key_value_node()
        |> elem(1)
    end
    |> TermNode.set_pulse(true, recursive: true)
  end

  defp update_by_diff!(term_node, %Diff{type: type, ins: ins, del: del}, _opts)
       when type in [:list, :tuple] do
    term_node
    |> term_node_reduce_del(del)
    |> term_node_reduce_list_ins(ins)
    |> TermNode.set_pulse(true, recursive: false)
  end

  defp update_by_diff!(term_node, %Diff{type: :struct, diff: diff}, _opts) do
    term_node_reduce_diff!(term_node, diff)
  end

  defp update_by_diff!(term_node, %Diff{type: :map, ins: ins, del: del, diff: diff}, _opts) do
    term_node
    |> term_node_reduce_del(del)
    |> term_node_reduce_map_ins(ins)
    |> term_node_reduce_diff!(diff)
  end

  defp term_node_reduce_del(term_node, del) do
    Enum.reduce(del, term_node, fn {key, _}, term_node_acc ->
      {:ok, term_node_acc} = TermNode.remove_child(term_node_acc, key)
      term_node_acc
    end)
  end

  defp term_node_reduce_list_ins(term_node, ins) do
    Enum.reduce(ins, term_node, fn {index, term}, %TermNode{} = term_node_acc ->
      children =
        List.insert_at(
          term_node_acc.children,
          index,
          {index, term |> to_node() |> TermNode.set_pulse(true, recursive: true)}
        )

      %TermNode{term_node_acc | children: children}
    end)
  end

  defp term_node_reduce_map_ins(term_node, ins) do
    child_keys = term_node.children |> Enum.map(fn {key, _} -> key end)

    {term_node_acc, _} =
      Enum.reduce(ins, {term_node, child_keys}, fn {key, term},
                                                   {%TermNode{} = term_node_acc, child_keys} ->
        child_keys = Enum.sort(child_keys ++ [key])
        index = Enum.find_index(child_keys, &(&1 == key))

        {key, node} = to_key_value_node({key, term})

        children =
          List.insert_at(
            term_node_acc.children,
            index,
            {key, TermNode.set_pulse(node, true, recursive: true)}
          )

        {%TermNode{term_node_acc | children: children}, child_keys}
      end)

    term_node_acc
  end

  defp term_node_reduce_diff!(term_node, diff) do
    term_node =
      Enum.reduce(diff, term_node, fn {key, child_diff}, term_node_acc ->
        {:ok, term_node_acc} =
          TermNode.update_child(term_node_acc, key, fn child ->
            update_by_diff!(child, child_diff, key: key)
          end)

        term_node_acc
      end)

    if Enum.empty?(diff) do
      term_node
    else
      term_node |> TermNode.set_pulse(true, recursive: false)
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
                TermNode.remove_suffix!(child)

              {false, false} ->
                TermNode.add_suffix(child, [TermNode.comma_suffix()])

              _ ->
                child
            end

          {key, child}
      end)

    %TermNode{term_node | children: children}
  end

  @spec to_node(term()) :: TermNode.t()
  defp to_node(string) when is_binary(string) do
    TermNode.new(:binary, [DisplayElement.green(inspect(string))])
  end

  defp to_node(atom) when is_atom(atom) do
    span =
      if atom in [nil, true, false] do
        DisplayElement.magenta(inspect(atom))
      else
        DisplayElement.blue(inspect(atom))
      end

    TermNode.new(:atom, [span])
  end

  defp to_node(number) when is_number(number) do
    TermNode.new(:number, [DisplayElement.blue(inspect(number))])
  end

  defp to_node({}) do
    TermNode.new(:tuple, [DisplayElement.black("{}")],
      open?: false,
      expanded_before: [DisplayElement.black("{")],
      expanded_after: [DisplayElement.black("}")]
    )
  end

  defp to_node(tuple) when is_tuple(tuple) do
    children = tuple |> Tuple.to_list() |> to_children()

    TermNode.new(:tuple, [DisplayElement.black("{...}")],
      children: children,
      expanded_before: [DisplayElement.black("{")],
      expanded_after: [DisplayElement.black("}")]
    )
  end

  defp to_node([]) do
    TermNode.new(:list, [DisplayElement.black("[]")],
      open?: false,
      expanded_before: [DisplayElement.black("[")],
      expanded_after: [DisplayElement.black("]")]
    )
  end

  defp to_node(list) when is_list(list) do
    children =
      if Keyword.keyword?(list) do
        to_key_value_children(list)
      else
        to_children(list)
      end

    TermNode.new(:list, [DisplayElement.black("[...]")],
      children: children,
      expanded_before: [DisplayElement.black("[")],
      expanded_after: [DisplayElement.black("]")]
    )
  end

  defp to_node(%Regex{} = regex) do
    TermNode.new(:regex, [DisplayElement.black(inspect(regex))])
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

    TermNode.new(
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
    TermNode.new(:map, [DisplayElement.black("%{}")],
      expanded_before: [DisplayElement.black("%{")],
      expanded_after: [DisplayElement.black("}")]
    )
  end

  defp to_node(map) when is_map(map) do
    children = map |> Enum.into([]) |> to_key_value_children()

    TermNode.new(:map, [DisplayElement.black("%{...}")],
      children: children,
      expanded_before: [DisplayElement.black("%{")],
      expanded_after: [DisplayElement.black("}")]
    )
  end

  defp to_node(other) do
    TermNode.new(:other, [DisplayElement.black(inspect(other))])
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

    {key, %TermNode{node | key: key}}
  end

  defp to_children(items) when is_list(items) do
    items
    |> Enum.sort()
    |> Enum.with_index(fn item, index ->
      {index, to_node(item)}
    end)
  end

  defp to_key_value_children(items) when is_list(items) do
    items
    |> Enum.sort()
    |> Enum.map(&to_key_value_node/1)
  end

  defp has_comma_suffix?(%TermNode{content: content, expanded_after: expanded_after}) do
    comma_suffix = TermNode.comma_suffix()

    content? =
      last_item_equal?(content, comma_suffix) ||
        last_item_equal?(content, comma_suffix |> DisplayElement.set_pulse(true))

    expanded_after? =
      last_item_equal?(expanded_after, comma_suffix) ||
        last_item_equal?(expanded_after, comma_suffix |> DisplayElement.set_pulse(true))

    if content? != expanded_after?,
      do: raise("Content and expanded_after must have the same comma suffix")

    content?
  end

  defp last_item_equal?([_ | _] = items, item) do
    items |> Enum.reverse() |> hd() |> Kernel.==(item)
  end

  defp last_item_equal?([], _), do: false
end
