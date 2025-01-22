defmodule LiveDebugger do
  @moduledoc """
  Debugger for LiveView applications.
  """

  use Phoenix.Component

  attr(:redirect_url, :string, required: true, doc: "The URL of the debugger, e.g. `/dbg`")

  attr(:socket_id, :string,
    required: true,
    doc: "The socket ID of the debugged LiveView"
  )

  attr(:corner, :atom,
    default: :bottom_right,
    doc:
      "The corner of the screen to place the button (possible values: `:top_left`, `:top_right`, `:bottom_left`, `:bottom_right`)"
  )

  attr(:display_socket_id, :boolean,
    default: false,
    doc: "Whether to display the socket ID next to the button"
  )

  def debug_button(assigns) do
    assigns = assign(assigns, :style, button_style(assigns))

    ~H"""
    <div style={@style}>
      <a id="live-debugger-button" href={"#{@redirect_url}/#{@socket_id}"} target="_blank">
        <.bug_icon />
      </a>
      <span :if={@display_socket_id} style="font-size: small;">{@socket_id}</span>
    </div>
    """
  end

  defmodule DebugPanel do
    use Phoenix.LiveComponent

    @impl true
    def mount(socket) do
      {:ok, assign(socket, hidden: true)}
    end

    attr(:id, :string, required: true)
    attr(:redirect_url, :string, required: true)
    attr(:corner, :atom, default: :bottom_right)

    slot(:inner_block)

    @impl true
    def render(assigns) do
      assigns = assign(assigns, :button_style, LiveDebugger.button_style(assigns))
      assigns = assign(assigns, :display, if(assigns.hidden, do: "none", else: "block"))

      ~H"""
      <div id={@id}>
        <button style={@button_style} phx-click="toggle-debugger" phx-target={@myself}>
          <LiveDebugger.bug_icon />
        </button>
        <div style={unless @hidden, do: "display: grid; grid-template-columns: 70% 30%;"}>
          <div>{render_slot(@inner_block)}</div>
          <iframe
            id="live-debugger-iframe"
            src={"#{@redirect_url}"}
            title="LiveDebugger"
            style={"width: 100%; height: 100%; border-left: 2px solid #041c74; display: #{@display}"}
          >
          </iframe>
        </div>
      </div>
      """
    end

    @impl true
    def handle_event("toggle-debugger", _, socket) do
      {:noreply, assign(socket, hidden: not socket.assigns.hidden)}
    end
  end

  def bug_icon(assigns) do
    ~H"""
    <svg
      xmlns="http://www.w3.org/2000/svg"
      fill="none"
      viewBox="0 0 24 24"
      stroke-width="1.5"
      stroke="currentColor"
      style="width: 25px; height: 25px;"
    >
      <path
        stroke-linecap="round"
        stroke-linejoin="round"
        d="M12 12.75c1.148 0 2.278.08 3.383.237 1.037.146 1.866.966 1.866 2.013 0 3.728-2.35 6.75-5.25 6.75S6.75 18.728 6.75 15c0-1.046.83-1.867 1.866-2.013A24.204 24.204 0 0 1 12 12.75Zm0 0c2.883 0 5.647.508 8.207 1.44a23.91 23.91 0 0 1-1.152 6.06M12 12.75c-2.883 0-5.647.508-8.208 1.44.125 2.104.52 4.136 1.153 6.06M12 12.75a2.25 2.25 0 0 0 2.248-2.354M12 12.75a2.25 2.25 0 0 1-2.248-2.354M12 8.25c.995 0 1.971-.08 2.922-.236.403-.066.74-.358.795-.762a3.778 3.778 0 0 0-.399-2.25M12 8.25c-.995 0-1.97-.08-2.922-.236-.402-.066-.74-.358-.795-.762a3.734 3.734 0 0 1 .4-2.253M12 8.25a2.25 2.25 0 0 0-2.248 2.146M12 8.25a2.25 2.25 0 0 1 2.248 2.146M8.683 5a6.032 6.032 0 0 1-1.155-1.002c.07-.63.27-1.222.574-1.747m.581 2.749A3.75 3.75 0 0 1 15.318 5m0 0c.427-.283.815-.62 1.155-.999a4.471 4.471 0 0 0-.575-1.752M4.921 6a24.048 24.048 0 0 0-.392 3.314c1.668.546 3.416.914 5.223 1.082M19.08 6c.205 1.08.337 2.187.392 3.314a23.882 23.882 0 0 1-5.223 1.082"
      />
    </svg>
    """
  end

  def button_style(assigns) do
    corner_css = corner_style(assigns.corner)

    """
      position: fixed;
      height: 40px;
      min-width: 40px;
      padding-left: 5px;
      padding-right: 5px;
      border-radius: 10px;
      background-color: rgba(127, 127, 127, 0.1);
      display: flex;
      gap: 5px;
      justify-content: center;
      align-items: center;
      #{corner_css}
    """
  end

  defp corner_style(:top_left), do: "top: 20px; left: 20px;"
  defp corner_style(:top_right), do: "top: 20px; right: 20px;"
  defp corner_style(:bottom_left), do: "bottom: 20px; left: 20px;"
  defp corner_style(:bottom_right), do: "bottom: 20px; right: 20px;"
  defp corner_style(_), do: ""
end
