defmodule LiveDebuggerWeb.Live.Nested.GlobalTracesLive do
  use LiveDebuggerWeb, :live_view

  attr(:socket, :map, required: true)
  attr(:id, :string, required: true)
  attr(:lv_process, :map, required: true)
  attr(:params, :map, required: true)
  attr(:class, :string, default: "", doc: "CSS class for the container")

  def live_render(assigns) do
    session = %{
      "lv_process" => assigns.lv_process,
      "id" => assigns.id,
      "params" => assigns.params,
      "parent_pid" => self()
    }

    assigns = assign(assigns, session: session)

    ~H"""
    <%= live_render(@socket, __MODULE__,
      id: @id,
      session: @session,
      container: {:div, class: @class}
    ) %>
    """
  end

  @impl true
  def mount(_params, session, socket) do
    socket
    |> assign(lv_process: session["lv_process"])
    |> assign(id: session["id"])
    |> ok()
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="w-full">
      <h1>Global Traces</h1>
      <%= @lv_process.pid |> inspect() %>
    </div>
    """
  end
end
