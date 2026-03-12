defmodule LiveDebugger.App.Web.EndpointStarter do
  @moduledoc """
  Wrapper around `LiveDebugger.App.Web.Endpoint` that handles startup failures gracefully.

  When `config :live_debugger, ignore_startup_errors: true` is set, a port conflict or
  other startup error will log an error and allow the host application to continue running
  without LiveDebugger, instead of crashing the whole application.
  """

  require Logger

  def child_spec(opts) do
    %{LiveDebugger.App.Web.Endpoint.child_spec(opts) | start: {__MODULE__, :start_link, [opts]}}
  end

  def start_link(opts) do
    case LiveDebugger.App.Web.Endpoint.start_link(opts) do
      {:ok, pid} ->
        {:ok, pid}

      {:error, reason} ->
        if Application.get_env(:live_debugger, :ignore_startup_errors, false) do
          Logger.error(
            "LiveDebugger failed to start: #{inspect(reason)}. " <>
              "LiveDebugger will be unavailable. " <>
              "To disable LiveDebugger entirely, set `config :live_debugger, disabled?: true`."
          )

          Application.put_env(:live_debugger, :live_debugger_tags, [])

          :ignore
        else
          {:error, reason}
        end
    end
  end
end
