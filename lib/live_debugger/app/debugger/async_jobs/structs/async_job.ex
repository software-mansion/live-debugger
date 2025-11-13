defmodule LiveDebugger.App.Debugger.AsyncJobs.Structs.AsyncJob do
  @moduledoc false

  alias LiveDebugger.App.Debugger.AsyncJobs.Structs.AsyncJob.StartAsync
  alias LiveDebugger.App.Debugger.AsyncJobs.Structs.AsyncJob.AsyncAssign

  @type t() :: StartAsync.t() | AsyncAssign.t()
end
