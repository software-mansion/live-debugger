defmodule LiveDebugger.App.Debugger.AsyncJobs.Structs.AsyncJob do
  @moduledoc false

  alias LiveDebugger.App.Debugger.AsyncJobs.Structs.AsyncJob.StartAsync
  alias LiveDebugger.App.Debugger.AsyncJobs.Structs.AsyncJob.AsyncAssign

  @type t() :: StartAsync.t() | AsyncAssign.t()

  def identifier(%StartAsync{name: name}), do: name
  def identifier(%AsyncAssign{keys: keys}), do: keys
end
