defmodule LiveDebugger.App.Debugger.AsyncJobs.Components do
  @moduledoc """
  Components for the async jobs.
  """

  use LiveDebugger.App.Web, :component

  alias LiveDebugger.App.Debugger.AsyncJobs.Structs.AsyncJob
  alias LiveDebugger.App.Utils.Parsers

  attr(:id, :string, required: true)
  attr(:async_job, :map, required: true)

  def async_job(assigns) do
    ~H"""
    <div
      id={@id}
      class="w-full grid grid-cols-[1fr_auto] border rounded border-default-border bg-surface-1-bg px-4 py-3"
    >
      <.tooltip id={@id <> "-subtitle-tooltip"} content="Async job type" class="w-max">
        <div class="text-primary text-2xs font-normal truncate">
          <%= async_job_subtitle(@async_job) %>
        </div>
      </.tooltip>
      <.tooltip id={@id <> "-pid-tooltip"} content="PID of the async job process" class="w-max">
        <span class="text-primary text-2xs font-normal">
          <%= Parsers.pid_to_string(@async_job.pid) %>
        </span>
      </.tooltip>

      <.tooltip
        id={@id <> "-identifier-tooltip"}
        content={identifier_tooltip_content(@async_job)}
        class="w-max"
      >
        <p class="font-medium text-sm col-span-2">
          <%= identifier(@async_job) %>
        </p>
      </.tooltip>
    </div>
    """
  end

  defp async_job_subtitle(%AsyncJob.StartAsync{}), do: "start_async/3"
  defp async_job_subtitle(%AsyncJob.AsyncAssign{}), do: "assign/3"

  defp identifier(async_job) do
    async_job
    |> AsyncJob.identifier()
    |> case do
      name when is_atom(name) -> inspect(name)
      keys when is_list(keys) -> Parsers.list_to_string(keys)
    end
  end

  defp identifier_tooltip_content(%AsyncJob.StartAsync{}) do
    "Name of the async job"
  end

  defp identifier_tooltip_content(%AsyncJob.AsyncAssign{}) do
    "Keys of the async assign"
  end
end
