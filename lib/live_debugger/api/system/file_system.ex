defmodule LiveDebugger.API.System.FileSystem do
  @moduledoc """
  API for interacting with file system monitoring functionalities.

  This module wraps the `FileSystem` library to allow for easier testing and mocking.
  """

  @callback start_link(opts :: keyword()) :: GenServer.on_start()
  @callback subscribe(name :: atom()) :: :ok

  @doc """
  Starts a FileSystem monitor process with the given options.

  Options:
  - `:dirs` - list of directories to monitor
  - `:name` - name to register the process under
  """
  @spec start_link(keyword()) :: GenServer.on_start()
  def start_link(opts), do: impl().start_link(opts)

  @doc """
  Subscribes the current process to file system events from the named monitor.

  The subscribing process will receive messages in the format:
  `{:file_event, pid, {path, events}}`
  """
  @spec subscribe(atom()) :: :ok
  def subscribe(name), do: impl().subscribe(name)

  defp impl() do
    Application.get_env(
      :live_debugger,
      :api_file_system,
      __MODULE__.Impl
    )
  end

  defmodule Impl do
    @moduledoc false
    @behaviour LiveDebugger.API.System.FileSystem

    @impl true
    def start_link(opts) do
      FileSystem.start_link(opts)
    end

    @impl true
    def subscribe(name) do
      FileSystem.subscribe(name)
    end
  end
end
