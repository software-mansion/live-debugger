defmodule LiveDebuggerWeb.Assigns do
  @moduledoc """
  This module contains functions for assigning values to the socket.
  """

  import Phoenix.Component
  import Phoenix.LiveView

  @doc """
  Assigns the `:in_iframe?` assign based on the connect params.
  """
  def assign_in_iframe?(socket) do
    in_iframe? =
      if connected?(socket) do
        socket
        |> get_connect_params()
        |> Map.get("in_iframe?", false)
      else
        false
      end

    assign(socket, :in_iframe?, in_iframe?)
  end
end
