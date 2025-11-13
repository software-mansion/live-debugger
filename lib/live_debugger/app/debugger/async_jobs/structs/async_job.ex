defmodule LiveDebugger.App.Debugger.AsyncJobs.Structs.AsyncJob do
  @moduledoc false

  alias LiveDebugger.App.Debugger.AsyncJobs.Structs.AsyncJob.StartAsync
  alias LiveDebugger.App.Debugger.AsyncJobs.Structs.AsyncJob.AsyncAssign

  @type t() :: StartAsync.t() | AsyncAssign.t()

  def identifier(async) when is_struct(async, StartAsync), do: async.name
  def identifier(async) when is_struct(async, AsyncAssign), do: async.keys
end
