defmodule LiveDebugger.App.Web.Plugs.AllowIframe do
  @moduledoc """
  Plug allowing application to be embedded in iframes.
  """
  import Plug.Conn

  @spec init(any) :: any
  def init(opts), do: opts

  @spec call(Plug.Conn.t(), any) :: Plug.Conn.t()
  def call(conn, _opts) do
    conn
    |> delete_resp_header("x-frame-options")
    |> delete_resp_header("content-security-policy")
  end
end
