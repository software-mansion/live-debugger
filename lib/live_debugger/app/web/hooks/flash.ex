defmodule LiveDebugger.App.Web.Hooks.Flash do
  @moduledoc """
  Functionalities to make flash messages work inside LiveComponents
  See: https://sevenseacat.net/posts/2023/flash-messages-in-phoenix-liveview-components/
  """
  import Phoenix.LiveView

  @doc """
  Attaches hook to handle flash messages
  """
  def on_mount(:add_hook, _params, _session, socket) do
    {:cont, attach_hook(socket, :flash, :handle_info, &maybe_receive_flash/2)}
  end

  @doc """
  Extended Phoenix.LiveView.put_flash/3 which works inside nested LiveViews/LiveComponents.
  If used in nested LiveView use root LiveView's pid.
  """
  @spec push_flash(
          socket :: Phoenix.LiveView.Socket.t(),
          key :: String.t() | atom(),
          message :: String.t()
        ) ::
          Phoenix.LiveView.Socket.t()
  def push_flash(socket, key, message)
      when is_binary(message) and key in [:error, :info] do
    push_flash(socket, key, message, self())
  end

  @spec push_flash(
          socket :: Phoenix.LiveView.Socket.t(),
          key :: String.t() | atom(),
          message :: String.t(),
          pid :: pid()
        ) ::
          Phoenix.LiveView.Socket.t()
  def push_flash(socket, key, message, pid)
      when is_pid(pid) and is_binary(message) and key in [:error, :info] do
    send(pid, {:put_flash, key, message})

    socket
  end

  defp maybe_receive_flash({:put_flash, key, message}, socket) do
    {:halt, put_flash(socket, key, message)}
  end

  defp maybe_receive_flash(_, socket), do: {:cont, socket}
end
