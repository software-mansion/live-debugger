defmodule LiveDebugger.App.Discovery.Web.Components do
  @moduledoc """
  Components used in the discovery page of the LiveDebugger application.
  """

  use LiveDebugger.App.Web, :component

  alias LiveDebugger.Structs.LvProcess
  alias LiveDebugger.App.Utils.Parsers
  alias LiveDebugger.App.Web.Helpers.Routes, as: RoutesHelper

  attr(:title, :string, required: true)

  def header(assigns) do
    ~H"""
    <div class="flex items-center justify-between">
      <.h1><%= @title %></.h1>
      <.button phx-click="refresh">
        <div class="flex items-center gap-2">
          <.icon name="icon-refresh" class="w-4 h-4" />
          <p>Refresh</p>
        </div>
      </.button>
    </div>
    """
  end

  def loading(assigns) do
    ~H"""
    <div class="flex items-center justify-center">
      <.spinner size="md" />
    </div>
    """
  end

  def failed(assigns) do
    ~H"""
    <.alert with_icon heading="Error fetching active LiveViews">
      Check logs for more
    </.alert>
    """
  end

  attr(:grouped_lv_processes, :map, default: %{})

  def live_sessions(assigns) do
    ~H"""
    <div id="live-sessions" class="flex flex-col gap-4">
      <%= if Enum.empty?(@grouped_lv_processes)  do %>
        <div class="p-4 bg-surface-0-bg rounded shadow-custom border border-default-border">
          <p class="text-secondary-text text-center">No active LiveViews</p>
        </div>
      <% else %>
        <.tab_group
          :for={{transport_pid, grouped_lv_processes} <- @grouped_lv_processes}
          transport_pid={transport_pid}
          grouped_lv_processes={grouped_lv_processes}
        />
      <% end %>
    </div>
    """
  end

  attr(:transport_pid, :any, required: true)
  attr(:grouped_lv_processes, :list, required: true)

  def tab_group(assigns) do
    ~H"""
    <div class="w-full h-max flex flex-col shadow-custom rounded-sm bg-surface-2-bg border border-default-border">
      <div class="pl-4 p-3 flex items-center h-10 border-b border-default-border">
        <p class="text-primary-text text-xs font-medium transport-pid">
          <%= Parsers.pid_to_string(@transport_pid) %>
        </p>
      </div>
      <div class="w-full flex bg-surface-0-bg">
        <.list elements={@grouped_lv_processes}>
          <:item :let={{root_lv_process, lv_processes}}>
            <div class="flex items-center w-full">
              <.list_element lv_process={root_lv_process} />
            </div>
            <.list elements={lv_processes} item_class="group">
              <:item :let={lv_process}>
                <div class="flex items-center w-full">
                  <.nested_indent />
                  <.list_element lv_process={lv_process} />
                </div>
              </:item>
            </.list>
          </:item>
        </.list>
      </div>
    </div>
    """
  end

  defp nested_indent(assigns) do
    ~H"""
    <div class="relative w-8 h-12">
      <div class="absolute top-0 right-2 w-1/4 h-1/2 border-b border-l-0 group-last:border-l border-default-border">
      </div>
      <div class="group-last:hidden block absolute top-0 right-2 w-1/4 h-full border-l border-default-border">
      </div>
    </div>
    """
  end

  attr(:lv_process, LvProcess, required: true)

  defp list_element(assigns) do
    ~H"""
    <.link
      navigate={RoutesHelper.debugger_node_inspector(@lv_process.pid)}
      class="flex justify-between items-center h-full w-full text-xs p-1.5 hover:bg-surface-0-bg-hover rounded-sm live-view-link"
    >
      <div class="flex flex-col gap-1">
        <div class="text-link-primary flex items-center gap-1">
          <.icon :if={not @lv_process.nested?} name="icon-liveview" class="w-4 h-4" />
          <p class={if(not @lv_process.nested?, do: "font-medium")}>
            <%= Parsers.module_to_string(@lv_process.module) %>
          </p>
        </div>
        <p class="text-secondary-text">
          <%= Parsers.pid_to_string(@lv_process.pid) %> &middot; <%= @lv_process.socket_id %>
        </p>
      </div>
      <div>
        <.badge
          :if={@lv_process.embedded? and not @lv_process.nested?}
          text="Embedded"
          icon="icon-code"
        />
      </div>
    </.link>
    """
  end
end
