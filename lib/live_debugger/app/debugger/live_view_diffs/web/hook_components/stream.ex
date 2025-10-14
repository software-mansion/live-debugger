defmodule LiveDebugger.App.Debugger.LiveViewDiffs.Web.HookComponents.Stream do
  @moduledoc """
  Hook component for displaying the diffs stream.
  """

  use LiveDebugger.App.Web, :hook_component

  @required_assigns [:id, :existing_diffs_status]

  @impl true
  def init(socket) do
    socket
    |> check_assigns!(@required_assigns)
    |> check_stream!(:existing_diffs)
    |> register_hook(:diffs_stream)
  end

  attr(:id, :string, required: true)
  attr(:existing_diffs_status, :atom, required: true)
  attr(:existing_diffs, Phoenix.LiveView.LiveStream, required: true)

  slot(:diff, required: true, doc: "Used for styling diff element. Remember to add `id`")

  @impl true
  def render(assigns) do
    ~H"""
    <div id={"#{@id}-stream"} phx-update="stream" class="flex flex-col gap-2">
      <div id={"#{@id}-stream-empty"} class="only:block hidden text-secondary-text text-center">
        <div :if={@existing_diffs_status == :ok}>
          No diffs have been recorded yet.
        </div>
        <div :if={@existing_diffs_status == :loading} class="w-full flex items-center justify-center">
          <.spinner size="sm" />
        </div>
        <.alert
          :if={@existing_diffs_status == :error}
          with_icon
          heading="Error fetching historical diffs"
        >
          New events will still be displayed as they come. Check logs for more information
        </.alert>
      </div>
      <%= for {dom_id, wrapped_diff} <- @existing_diffs do %>
        <%= render_slot(@diff, {dom_id, wrapped_diff}) %>
      <% end %>
    </div>
    """
  end
end
