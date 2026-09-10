defmodule LiveDebugger.Env do
  @moduledoc """
  Gives you a save option to check env in runtime
  """

  @endpoint_pubsub_name Application.compile_env(
                          :live_debugger,
                          :endpoint_pubsub_name,
                          LiveDebugger.App.Web.Endpoint.PubSub
                        )

  @bus_pubsub_name Application.compile_env(
                     :live_debugger,
                     :bus_pubsub_name,
                     LiveDebugger.Bus.PubSub
                   )

  def endpoint_pubsub_name(), do: @endpoint_pubsub_name
  def bus_pubsub_name(), do: @bus_pubsub_name

  if Mix.env() == :dev do
    def dev?(), do: true
  else
    def dev?(), do: false
  end

  def unit_test?() do
    Application.get_env(:live_debugger, :unit_test?, false) and
      not Application.get_env(:live_debugger, :e2e?, false)
  end
end
