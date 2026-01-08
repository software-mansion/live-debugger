defmodule LiveDebugger.App.Web.Layout do
  @moduledoc """
  Layout of the Application.
  It uses `phoenix` and `phoenix_live_view.js` of debugged application to dependency conflicts.
  """

  use Phoenix.Component

  @doc false
  def render(template, assigns)

  def render("root.html", assigns) do
    assigns =
      assigns
      |> assign(:update_checks?, Application.get_env(:live_debugger, :update_checks?, true))
      |> assign(:current_version, Application.spec(:live_debugger)[:vsn] |> to_string())

    ~H"""
    <!DOCTYPE html>
    <html lang="en">
      <head>
        <%= custom_head_tags(assigns, :after_opening_head_tag) %>
        <meta charset="utf-8" />
        <meta http-equiv="X-UA-Compatible" content="IE=edge" />
        <meta
          name="viewport"
          content="width=device-width, initial-scale=1.0, minimum-scale=1.0, maximum-scale=1.0, shrink-to-fit=no, user-scalable=no"
        />
        <meta name="csrf-token" content={Phoenix.Controller.get_csrf_token()} />
        <title>LiveDebugger</title>
        <link rel="stylesheet" href="/assets/live_debugger/app.css" />

        <%= custom_head_tags(assigns, :before_closing_head_tag) %>
      </head>
      <body class="theme-light dark:theme-dark text-primary-text bg-main-bg text-xs font-normal">
        <script src="/assets/phoenix/phoenix.js">
        </script>
        <script src="/assets/phoenix_live_view/phoenix_live_view.js">
        </script>
        <script src="/assets/live_debugger/app.js">
        </script>
        <script>
          let liveSocket = new window.LiveView.LiveSocket('/live', window.Phoenix.Socket, {
            longPollFallbackMs: 2500,
            params: {
              _csrf_token: window.getCsrfToken(),
              "in_iframe?": window.location !== window.parent.location
            },
            hooks: window.createHooks(),
            dom: {
              onBeforeElUpdated: window.saveDialogAndDetailsState(),
            },
          });

          window.setTheme();

          const checkForUpdate = <%= @update_checks? %>;
          const currentVersion = "<%= @current_version %>";

          if (checkForUpdate) {
            window.checkForUpdate(currentVersion);
          }

          liveSocket.connect();

          window.liveSocket = liveSocket;
        </script>
        <span id="tooltip" class="absolute hidden p-2 text-xs rounded bg-tooltip-bg text-tooltip-text">
        </span>
        <.new_version_popup />
        <%= @inner_content %>
      </body>
    </html>
    """
  end

  def render("app.html", assigns) do
    ~H"""
    <main class="h-screen w-screen max-w-full">
      <LiveDebugger.App.Web.Components.flash_group flash={@flash} />
      <%= @inner_content %>
    </main>
    """
  end

  defp custom_head_tags(assigns, key) do
    case assigns do
      %{^key => components} when is_list(components) ->
        assigns = assign(assigns, :components, components)

        ~H"""
        <%= for component <- @components do %>
          <%= component.(assigns) %>
        <% end %>
        """

      _ ->
        nil
    end
  end

  defp new_version_popup(assigns) do
    ~H"""
    <LiveDebugger.App.Web.Components.popup
      id="new-version-popup"
      title="New Version Available"
      wrapper_class="hidden"
      on_close={Phoenix.LiveView.JS.add_class("hidden", to: "#new-version-popup")}
    >
      <div class="flex flex-col gap-4">
        <p class="text-xs">
          The
          <.link
            href="https://hex.pm/packages/live_debugger"
            target="_blank"
            class="text-xs text-link-primary hover:text-link-primary-hover"
          >
            <span id="new-version-popup-version" class="font-medium"></span>
          </.link>
          version of LiveDebugger is available! Update to get the latest features and improvements.
        </p>

        <div class="flex flex-col gap-2">
          <p class="text-xs font-medium text-primary-text">
            Update your <code class="text-xs font-mono text-primary-text">mix.exs</code>
            file if needed and run:
          </p>
          <div class="relative group">
            <div class="bg-surface-1-bg border border-default-border rounded px-3 py-2 pr-10">
              <code class="text-xs font-mono text-primary-text">
                mix deps.update live_debugger
              </code>
            </div>
            <div class="absolute right-2 top-1/2 -translate-y-1/2">
              <LiveDebugger.App.Web.Components.copy_button
                id="update-command-copy"
                value="mix deps.update live_debugger"
                variant="icon"
              />
            </div>
          </div>
        </div>
      </div>
    </LiveDebugger.App.Web.Components.popup>
    """
  end
end
