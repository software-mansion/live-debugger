defmodule LiveDebuggerDev.Layout do
  use Phoenix.Component

  import LiveDebuggerDev.Components

  @doc false
  def render(template, assigns)

  def render("root.html", assigns) do
    ~H"""
    <!DOCTYPE html>
    <html lang="en" class="h-full">
      <head>
        <meta charset="utf-8" />
        <meta name="viewport" content="width=device-width, initial-scale=1" />
        <title>DevApp</title>
        <link rel="shortcut icon" href="#" />
        <script src="https://cdn.tailwindcss.com">
        </script>
      </head>
      <body>
        <script src="/assets/phoenix/phoenix.js">
        </script>
        <script src="/assets/phoenix_live_view/phoenix_live_view.js">
        </script>
        <%= Application.get_env(:live_debugger, :live_debugger_tags) %>
        <script>
          // Set global hooks and uploaders objects to be used by the LiveSocket,
          // so they can be overwritten in user provided templates.
          window.hooks = {}
          window.uploaders = {}

          let liveSocket =
            new window.LiveView.LiveSocket(
              "/live",
              window.Phoenix.Socket,
              { hooks, uploaders }
            )
          liveSocket.connect()

          window.addEventListener("phx:live_reload:attached", ({detail: reloader}) => {
            // Enable server log streaming to client. Disable with reloader.disableServerLogs()
            reloader.enableServerLogs()

            // Open configured PLUG_EDITOR at file:line of the clicked element's HEEx component
            //
            //   * click with "c" key pressed to open at caller location
            //   * click with "d" key pressed to open at function component definition location
            let keyDown
            window.addEventListener("keydown", e => keyDown = e.key)
            window.addEventListener("keyup", e => keyDown = null)
            window.addEventListener("click", e => {
              if(keyDown === "c"){
                e.preventDefault()
                e.stopImmediatePropagation()
                reloader.openEditorAtCaller(e.target)
              } else if(keyDown === "d"){
                e.preventDefault()
                e.stopImmediatePropagation()
                reloader.openEditorAtDef(e.target)
              }
            }, true)

            window.liveReloader = reloader
          })
        </script>

        <%= @inner_content %>
      </body>
    </html>
    """
  end

  def render("app.html", assigns) do
    ~H"""
    <main class="p-5">
      <.navbar />
      <%= @inner_content %>
    </main>
    """
  end

  def render("embedded.html", assigns) do
    assigns = assign(assigns, v: Map.get(assigns, :socket, assigns[:conn]))

    ~H"""
    <main class="p-5">
      <.navbar />
      <.box title="Embedded Live View [LiveView]" color="purple">
        <%= live_render(@v, LiveDebuggerDev.LiveViews.Nested,
          id: "phx-embedded_with_nested",
          session: %{"id" => "embedded_with_nested"},
          sticky: true
        ) %>
      </.box>
      <%= @inner_content %>
    </main>
    """
  end
end
