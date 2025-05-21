defmodule LiveDebuggerWeb.Hooks.IframeCheck do
  @moduledoc """
  This hook is used to check if the current page is inside an iframe.
  It assigns the `:in_iframe?` assign based on the connect params.
  """
  import Phoenix.LiveView
  import Phoenix.Component

  def on_mount(:add_hook, _params, _session, socket) do
    in_iframe? =
      if connected?(socket) do
        socket
        |> get_connect_params()
        |> Map.get("in_iframe?", false)
      else
        false
      end

    {:cont, assign(socket, :in_iframe?, in_iframe?)}
  end
end
