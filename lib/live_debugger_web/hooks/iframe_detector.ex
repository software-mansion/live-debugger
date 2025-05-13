defmodule LiveDebuggerWeb.Hooks.IframeDetector do
  @moduledoc """
  This hook adds a handler for event `detect-iframe` which detects if the current page is an iframe.
  It appends to assigns `:in_iframe?` the result of the detection.
  At the beginning of the mount `:in_iframe?` is set to `false`, after the hook is attached it's set to the result of the detection.
  It works only on the root LiveView, not on nested ones.

  Check `iframe_detector.js` for more details.
  """
  import Phoenix.LiveView
  import Phoenix.Component
  import LiveDebuggerWeb.Helpers

  defmacro __using__(_opts) do
    quote do
      on_mount({LiveDebuggerWeb.Hooks.IframeDetector, :add_hook})
    end
  end

  def on_mount(:add_hook, :not_mounted_at_router, _session, socket) do
    {:cont, socket}
  end

  def on_mount(:add_hook, _params, _session, socket) do
    socket
    |> assign(:in_iframe?, false)
    |> attach_hook(:detect_iframe, :handle_event, &maybe_receive_detect_iframe/3)
    |> cont()
  end

  defp maybe_receive_detect_iframe("detect-iframe", %{"in_iframe?" => in_iframe?}, socket) do
    {:halt, assign(socket, :in_iframe?, in_iframe?)}
  end

  defp maybe_receive_detect_iframe(_, _, socket), do: {:cont, socket}
end
