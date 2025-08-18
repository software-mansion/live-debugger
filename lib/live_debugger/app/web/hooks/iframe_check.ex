defmodule LiveDebugger.App.Web.Hooks.IframeCheck do
  @moduledoc """
  This hook is used to check if the current page is inside an iframe.
  It assigns the `:in_iframe?` assign based on the connect params.

  Mock is created for it to simulate LiveDebugger in iframe in e2e tests.
  """

  @callback on_mount(
              :add_hook,
              params :: map(),
              session :: map(),
              socket :: Phoenix.LiveView.Socket.t()
            ) ::
              {:cont, Phoenix.LiveView.Socket.t()}

  def on_mount(:add_hook, params, session, socket) do
    impl().on_mount(:add_hook, params, session, socket)
  end

  defp impl() do
    Application.get_env(
      :live_debugger,
      :iframe_check,
      __MODULE__.Impl
    )
  end

  defmodule Impl do
    @moduledoc false

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
end
