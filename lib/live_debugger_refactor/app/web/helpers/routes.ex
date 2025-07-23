defmodule LiveDebuggerRefactor.App.Web.Helpers.Routes do
  @moduledoc """
  Helper module for generating verified routes in the LiveDebuggerRefactor application.
  See `Phoenix.VerifiedRoutes` for more details.
  """

  use Phoenix.VerifiedRoutes,
    endpoint: LiveDebuggerRefactor.App.Web.Endpoint,
    router: LiveDebuggerRefactor.App.Web.Router

  @spec discovery() :: String.t()
  def discovery() do
    ~p"/"
  end

  @spec settings(return_to :: String.t() | nil) :: String.t()
  def settings(return_to \\ nil)

  def settings(nil) do
    ~p"/settings"
  end

  def settings(return_to) do
    ~p"/settings?return_to=#{return_to}"
  end
end
