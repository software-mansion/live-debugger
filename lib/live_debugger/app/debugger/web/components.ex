defmodule LiveDebugger.App.Debugger.Web.Components do
  @moduledoc """
  Components used in the debugger page of the LiveDebugger application.
  """

  use LiveDebugger.App.Web, :component

  alias LiveDebugger.Structs.LvProcess
  alias LiveDebugger.App.Utils.Parsers
  alias LiveDebugger.App.Web.Helpers.Routes, as: RoutesHelper

  attr(:lv_process, LvProcess, required: true)
  attr(:id, :string, required: true)

  attr(:icon, :string,
    default: "",
    doc: "Icon to add before module name. If empty string no icon added."
  )

  def live_view_link(assigns) do
    assigns = assign(assigns, :module_string, Parsers.module_to_string(assigns.lv_process.module))

    ~H"""
    <.link
      href={RoutesHelper.debugger_node_inspector(@lv_process.pid)}
      class="w-full flex gap-1 text-primary-text"
    >
      <.icon :if={@icon != ""} name={@icon} class="w-4 h-4 shrink-0 text-link-primary" />
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
