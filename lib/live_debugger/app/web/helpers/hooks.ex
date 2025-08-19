defmodule LiveDebugger.App.Web.Helpers.Hooks do
  @moduledoc """
  Set of helper functions for working with hooks.
  """

  alias Phoenix.LiveView.Socket, as: LiveViewSocket

  @doc """
  Checks if the given key (or keys) is present in the assigns of the socket.
  Raises an error if the key is not found.
  """
  @spec check_assigns!(LiveViewSocket.t(), atom() | [atom()]) :: LiveViewSocket.t()
  def check_assigns!(%LiveViewSocket{} = socket, keys) when is_list(keys) do
    Enum.each(keys, &check_assigns!(socket, &1))

    socket
  end

  def check_assigns!(%LiveViewSocket{assigns: assigns} = socket, key)
      when is_atom(key) and is_map_key(assigns, key) do
    socket
  end

  def check_assigns!(%LiveViewSocket{}, key) when is_atom(key) do
    raise "Assign #{key} not found in assigns"
  end

  @doc """
  Checks if the given key is present in the streams of the socket.
  Raises an error if the key is not found.
  """
  @spec check_stream!(LiveViewSocket.t(), atom()) :: LiveViewSocket.t()
  def check_stream!(%LiveViewSocket{assigns: %{streams: streams}} = socket, key)
      when is_map_key(streams, key) do
    socket
  end

  def check_stream!(%LiveViewSocket{}, key) do
    raise "Stream #{key} not found in assigns.streams"
  end

  @doc """
  Checks if the given key is present in the hooks of the socket.
  Raises an error if the key is not found.
  """
  @spec check_hook!(LiveViewSocket.t(), atom()) :: LiveViewSocket.t()
  def check_hook!(%LiveViewSocket{private: private} = socket, key) do
    if Map.has_key?(private, :hooks) and key in private.hooks do
      socket
    else
      raise "Hook #{key} not found in socket.private.hooks"
    end
  end

  @doc """
  Checks if the given key is present in the private of the socket.
  Raises an error if the key is not found.
  """
  @spec check_private!(LiveViewSocket.t(), atom()) :: LiveViewSocket.t()
  def check_private!(%LiveViewSocket{private: private} = socket, key) do
    if Map.has_key?(private, key) do
      socket
    else
      raise "Private key #{key} not found in socket.private"
    end
  end

  @doc """
  Add a hook to the socket via `socket.private.hooks`.
  """
  @spec register_hook(LiveViewSocket.t(), atom()) :: LiveViewSocket.t()
  def register_hook(%LiveViewSocket{private: private} = socket, key) do
    cond do
      !Map.has_key?(private, :hooks) ->
        Phoenix.LiveView.put_private(socket, :hooks, [key])

      key in private.hooks ->
        raise "Hook #{key} already registered"

      true ->
        Phoenix.LiveView.put_private(socket, :hooks, [key | private.hooks])
    end
  end
end
