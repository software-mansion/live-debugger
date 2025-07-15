defmodule LiveDebuggerRefactor.App.Web.Helpers do
  @moduledoc false

  @type socket() :: Phoenix.LiveView.Socket.t()

  @spec ok(socket()) :: {:ok, socket()}
  def ok(socket), do: {:ok, socket}

  @spec noreply(socket()) :: {:noreply, socket()}
  def noreply(socket), do: {:noreply, socket}

  @spec cont(socket()) :: {:cont, socket()}
  def cont(socket), do: {:cont, socket}

  @spec halt(socket()) :: {:halt, socket()}
  def halt(socket), do: {:halt, socket}
end
