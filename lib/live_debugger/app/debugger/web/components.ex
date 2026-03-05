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

  attr(:lv_processes, :map, required: true)
  attr(:current_lv_process_pid, :any, default: nil)

  def associated_lv_processes_tree(assigns) do
    ~H"""
    <.list elements={@lv_processes} class="!p-0 overflow-x-hidden">
      <:item :let={{parent_lv_process, lv_processes}}>
        <div class="flex items-center w-full">
          <.list_element
            lv_process={parent_lv_process}
            current_lv_process_pid={@current_lv_process_pid}
          />
        </div>
        <.lv_processes_tree
          lv_processes={lv_processes}
          current_lv_process_pid={@current_lv_process_pid}
        />
      </:item>
    </.list>
    """
  end

  attr(:lv_processes, :map, required: true)
  attr(:current_lv_process_pid, :any, default: nil)

  def lv_processes_tree(assigns) do
    ~H"""
    <.list
      :if={@lv_processes}
      elements={@lv_processes}
      item_class="group"
      class="!p-0 overflow-x-hidden"
    >
      <:item :let={{parent_lv_process, lv_processes}}>
        <div class="flex items-center w-full">
          <.nested_indent />
          <.list_element
            lv_process={parent_lv_process}
            current_lv_process_pid={@current_lv_process_pid}
          />
        </div>
        <div :if={lv_processes} class="flex w-full">
          <.nested_indent single_entry?={false} />
          <.lv_processes_tree
            lv_processes={lv_processes}
            current_lv_process_pid={@current_lv_process_pid}
          />
        </div>
      </:item>
    </.list>
    """
  end

  attr(:single_entry?, :boolean, default: true)

  def nested_indent(assigns) do
    ~H"""
    <div class={["relative w-8", if(@single_entry?, do: "h-8")]}>
      <div
        :if={@single_entry?}
        class="absolute top-0 right-2 w-1/4 h-1/2 border-b border-l-0 group-last:border-l border-default-border"
      >
      </div>
      <div class="group-last:hidden block absolute top-0 right-2 w-1/4 h-full border-l border-default-border">
      </div>
    </div>
    """
  end

  attr(:lv_process, LvProcess, required: true)
  attr(:current_lv_process_pid, :any, default: nil)

  def list_element(assigns) do
    assigns = assign(assigns, :module_string, Parsers.module_to_string(assigns.lv_process.module))

    ~H"""
    <div class="flex w-full items-center overflow-x-hidden">
      <.tooltip
        id={Parsers.pid_to_string(@lv_process.pid) <> "_tooltip"}
        content={"#{@module_string} | #{@lv_process.socket_id} | #{Parsers.pid_to_string(@lv_process.pid)}"}
        position="left"
        class="w-full"
      >
        <button
          id={Parsers.pid_to_string(@lv_process.pid)}
          phx-click="select-live-view"
          phx-hook="Highlight"
          phx-value-search-value={@lv_process.socket_id}
          phx-value-module={@lv_process.module}
          phx-value-root-socket-id={@lv_process.root_socket_id}
          phx-value-id={Parsers.pid_to_string(@lv_process.pid)}
          class={[
            "h-full w-full text-xs p-1.5 rounded-sm flex gap-1 min-w-0 w-full",
            if(@current_lv_process_pid == @lv_process.pid,
              do: "bg-surface-2-bg font-semibold",
              else: "hover:bg-surface-0-bg-hover"
            )
          ]}
        >
          <.icon name="icon-liveview" class="w-4 h-4 text-accent-icon" />
          <p class={["truncate w-9/10 text-left", if(not @lv_process.nested?, do: "font-semibold")]}>
            <%= Parsers.module_to_string(@lv_process.module) %>
          </p>
        </button>
      </.tooltip>
    </div>
    """
  end
end
