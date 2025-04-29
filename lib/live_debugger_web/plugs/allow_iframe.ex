defmodule LiveDebuggerWeb.Plugs.AllowIframe do
  @moduledoc """
  Plug to allow iframes to be embedded in the application.
  """
  import Plug.Conn

  @spec init(any) :: any
  def init(opts), do: opts

  @spec call(Plug.Conn.t(), any) :: Plug.Conn.t()
  def call(conn, _opts) do
    delete_resp_header(conn, "x-frame-options")
  end
end
