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
        <link rel="stylesheet" href="/assets/app.css" />
        <script src="/assets/app.js" defer>
        </script>
        <%= custom_head_tags(assigns, :before_closing_head_tag) %>
      </head>
      <body class="theme-dark font-primary-text bg-main-bg text-xs font-normal">
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
    <main class="h-screen w-screen max-w-full">
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
end
