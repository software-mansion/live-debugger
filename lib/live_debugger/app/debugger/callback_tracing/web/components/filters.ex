defmodule LiveDebugger.App.Debugger.CallbackTracing.Web.Components.Filters do
  @moduledoc """
  UI components for filters form.
  """

  use LiveDebugger.App.Web, :component

  attr(:title, :string, required: true, doc: "Displayed title of the group")
  attr(:group_name, :atom, required: true, doc: "Name of the group in the form")
  attr(:target, :any, required: true)
  attr(:class, :string, default: "", doc: "Additional class for the group")

  attr(:group_changed?, :boolean,
    required: true,
    doc: "Whether the group has changed from the default filters"
  )

  def filters_group_header(assigns) do
    ~H"""
    <div class={["pb-2 pr-3 h-10 flex items-center justify-between", @class]}>
      <p class="font-medium"><%= @title %></p>
      <button
        :if={@group_changed?}
        type="button"
        class="flex align-center text-link-primary hover:text-link-primary-hover"
        phx-click="reset-group"
        phx-value-group={@group_name}
        phx-target={@target}
      >
        <span>Reset</span>
      </button>
    </div>
    """
  end
end
