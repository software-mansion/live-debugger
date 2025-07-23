defmodule LiveDebuggerRefactor.App.Debugger.NestedLiveViewLinks.Web.NestedLiveViewLinksLive do
  use LiveDebuggerRefactor.App.Web, :live_view

  alias Phoenix.LiveView.AsyncResult
  alias LiveDebuggerRefactor.App.Debugger.Web.Components, as: DebuggerComponents

  @impl true
  def mount(_params, _session, socket) do
    socket
    |> assign(nested_lv_processes: AsyncResult.ok([]))
    |> ok()
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="w-full px-4 py-3 gap-3 flex flex-col border-b border-default-border">
      <.async_result :let={nested_lv_processes} assign={@nested_lv_processes}>
        <:loading>
          <.spinner size="sm" class="m-auto" />
        </:loading>
        <.nested_live_views_links_label nested_lv_processes={nested_lv_processes} />
        <%= unless Enum.empty?(nested_lv_processes) do %>
          <div class="pl-2 flex flex-col gap-1">
            <DebuggerComponents.live_view_link
              :for={{nested_lv_process, index} <- Enum.with_index(nested_lv_processes)}
              lv_process={nested_lv_process}
              id={"nested_live_view_link_#{index}"}
              icon="icon-nested"
            />
          </div>
        <% end %>
      </.async_result>
    </div>
    """
  end

  attr(:nested_lv_processes, :list, required: true)

  defp nested_live_views_links_label(assigns) do
    label =
      if Enum.empty?(assigns.nested_lv_processes) do
        "No nested LiveViews"
      else
        "Nested LiveViews"
      end

    assigns = assign(assigns, :label, label)

    ~H"""
    <p class="pl-2 shrink-0 font-medium text-secondary-text"><%= @label %></p>
    """
  end
end
