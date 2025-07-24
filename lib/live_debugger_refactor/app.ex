defmodule LiveDebuggerRefactor.App do
  @moduledoc """
  Managing web LiveDebugger app.
  """

  @pubsub_name Application.compile_env(
                 :live_debugger,
                 :endpoint_pubsub_name,
                 LiveDebuggerRefactor.App.Web.Endpoint.PubSub
               )

  @spec append_app_children(children :: list()) :: list()
  def append_app_children(children) do
    pubsub =
      Supervisor.child_spec({Phoenix.PubSub, name: @pubsub_name}, id: @pubsub_name)

    children ++
      [
        pubsub,
        {LiveDebuggerRefactor.App.Web.Endpoint,
         [
           check_origin: false,
           pubsub_server: @pubsub_name
         ]}
      ]
  end
end
