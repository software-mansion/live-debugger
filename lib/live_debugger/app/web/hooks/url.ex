defmodule LiveDebugger.App.Web.Hooks.URL do
  @moduledoc """
  This hook assigns the `:url` assign based on the current URL.
  It is triggered on handle_params callback.
  """

  import Phoenix.LiveView
  import Phoenix.Component

  alias LiveDebugger.App.Utils.URL

  def on_mount(:add_hook, :not_mounted_at_router, _session, socket) do
    {:cont, socket}
  end

  def on_mount(:add_hook, _params, _session, socket) do
    {:cont, attach_hook(socket, :url, :handle_params, &handle_params/3)}
  end

  defp handle_params(_params, url, socket) do
    {:cont, assign(socket, :url, URL.to_relative(url))}
  end
end
