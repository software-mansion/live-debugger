defprotocol LiveDebugger.LiveElement do
  alias LiveDebugger.LiveElements.Component, as: LiveComponentElement
  alias LiveDebugger.LiveElements.View, as: LiveViewElement

  @type live_element() :: LiveViewElement.t() | LiveComponentElement.t()

  @spec type(element :: live_element()) :: atom()
  def type(element)

  @spec add_child(parent :: live_element(), child :: live_element()) :: live_element()
  def add_child(parent, child)
end

defimpl LiveDebugger.LiveElement, for: LiveDebugger.LiveElements.Component do
  def type(_element), do: :live_component

  def add_child(parent, child) do
    %{parent | children: parent.children ++ [child]}
  end
end

defimpl LiveDebugger.LiveElement, for: LiveDebugger.LiveElements.View do
  def type(_element), do: :live_view

  def add_child(parent, child) do
    %{parent | children: parent.children ++ [child]}
  end
end
