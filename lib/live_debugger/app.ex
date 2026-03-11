defmodule LiveDebugger.App do
  @moduledoc """
  Managing web LiveDebugger app.
  """

  @pubsub_name LiveDebugger.Env.endpoint_pubsub_name()

  @spec append_app_children(children :: list()) :: list()
  def append_app_children(children) do
    ignore_startup_errors? = Application.get_env(:live_debugger, :ignore_startup_errors, false)

    endpoint_module =
      if ignore_startup_errors?,
        do: LiveDebugger.App.Web.EndpointStarter,
        else: LiveDebugger.App.Web.Endpoint

    pubsub =
      Supervisor.child_spec({Phoenix.PubSub, name: @pubsub_name}, id: @pubsub_name)

    children ++
      [
        pubsub,
        {endpoint_module,
         [
           check_origin: false,
           pubsub_server: @pubsub_name
         ]}
      ]
  end
end
