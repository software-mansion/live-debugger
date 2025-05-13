defmodule LiveDebuggerWeb.Components.Links do
  @moduledoc """
  Adds styling for links.
  """
  use LiveDebuggerWeb, :component

  alias LiveDebugger.Structs.LvProcess
  alias LiveDebugger.Utils.Parsers
  alias LiveDebuggerWeb.Helpers.RoutesHelper

  attr(:lv_process, LvProcess, required: true)
  attr(:id, :string, required: true)
  attr(:icon, :any, default: nil, doc: "Icon to add before module name. If `nil` no icon added.")

  def live_view(assigns) do
    assigns = assign(assigns, :module_string, Parsers.module_to_string(assigns.lv_process.module))

    ~H"""
    <.link
      href={RoutesHelper.channel_dashboard(@lv_process.pid)}
      class="w-full flex gap-1 text-primary-text"
    >
      <.icon :if={@icon} name={@icon} class="w-4 h-4 shrink-0 text-link-primary" />
      <.tooltip
        id={@id}
        content={"#{@module_string} | #{@lv_process.socket_id} | #{Parsers.pid_to_string(@lv_process.pid)}"}
      >
        <p class="text-link-primary truncate">
          <%= @module_string %>
        </p>
      </.tooltip>
    </.link>
    """
  end
end
