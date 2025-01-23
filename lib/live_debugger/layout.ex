defmodule LiveDebugger.Layout do
  @moduledoc """
  Inspiration was taken from Phoenix LiveDashboard
  https://github.com/phoenixframework/phoenix_live_dashboard/blob/main/lib/phoenix/live_dashboard/layout_view.ex
  https://github.com/phoenixframework/phoenix_live_dashboard/blob/main/lib/phoenix/live_dashboard/layouts/dash.html.heex
  """

  use Phoenix.Component

  @doc false
  def render(template, assigns)

  def render("root.html", assigns) do
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
        <link rel="stylesheet" href={asset_path(@conn, :css)} />
        <script src={asset_path(@conn, :js)} defer>
        </script>
        <%= custom_head_tags(assigns, :before_closing_head_tag) %>
      </head>
      <body>
        <span
          id="tooltip"
          class="absolute hidden p-1 text-xs bg-white border-1 border-primary rounded-md shadow-md"
        >
        </span>
        <%= @inner_content %>
      </body>
    </html>
    """
  end

  def render("app.html", assigns) do
    ~H"""
    <main class="h-screen w-screen">
      <%= @inner_content %>
    </main>
    """
  end

  @compile {:no_warn_undefined, Phoenix.VerifiedRoutes}

  defp asset_path(conn, asset) when asset in [:css, :js] do
    hash = LiveDebugger.Controllers.Assets.current_hash(asset)

    prefix = conn.private.phoenix_router.live_debugger_prefix()

    Phoenix.VerifiedRoutes.unverified_path(
      conn,
      conn.private.phoenix_router,
      "#{prefix}/#{asset}-#{hash}"
    )
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
end
