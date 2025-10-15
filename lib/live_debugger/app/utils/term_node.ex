defmodule LiveDebugger.App.Utils.TermNode do
  @moduledoc """
  Represents a node in the display tree.
  Based on [Kino.Tree](https://github.com/livebook-dev/kino/blob/main/lib/kino/tree.ex)

  - `id`: The id of the node. It uses dot notation to represent the path to the node.
  - `open?`: Whether the node is expanded
  - `kind`: The type of the node (e.g., :atom, :list, :map).
  - `children`: A map of child nodes with keys (integer indices for lists/tuples, actual keys for maps).
  - `content`: Display elements that represent the content of the node when has no children or not expanded.
  - `expanded_before`: Display elements shown before the node's children when expanded.
  - `expanded_after`: Display elements shown after the node's children when expanded.
  """

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

  @spec new(kind(), [DisplayElement.t()], Keyword.t()) :: t()
  def new(kind, content, args \\ []) do
    children = Keyword.get(args, :children, [])
    expanded_before = Keyword.get(args, :expanded_before, [])
    expanded_after = Keyword.get(args, :expanded_after, [])
    open? = Keyword.get(args, :open?, false)
    id = Keyword.get(args, :id, "not_indexed")

    %__MODULE__{
      id: id,
      kind: kind,
      content: content,
      children: children,
      expanded_before: expanded_before,
      expanded_after: expanded_after,
      open?: open?
    }
  end

  @spec comma_suffix() :: DisplayElement.t()
  def comma_suffix(), do: DisplayElement.black(",")

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

  @spec remove_child(t(), any()) :: ok_error()
  def remove_child(%__MODULE__{children: children} = term, key) do
    children
    |> Enum.find_index(fn {child_key, _} -> child_key == key end)
    |> case do
      nil ->
        {:error, :child_not_found}

      index ->
        children = List.delete_at(children, index)
        {:ok, %__MODULE__{term | children: children}}
    end
  end

  @spec update_child(t(), any(), (t() -> t())) :: ok_error()
  def update_child(%__MODULE__{children: children} = term, key, update_fn) do
    children
    |> Enum.with_index()
    |> Enum.filter(fn {{child_key, _}, _} -> child_key == key end)
    |> case do
      [{{^key, child}, index}] ->
        children = List.replace_at(children, index, {key, update_fn.(child)})
        {:ok, %__MODULE__{term | children: children}}

      _ ->
        {:error, :child_not_found}
    end
  end
end
