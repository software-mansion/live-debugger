defmodule LiveDebugger.E2E.AsyncJobsTest do
  use LiveDebugger.E2ECase

  setup_all do
    LiveDebugger.Services.CallbackTracer.GenServers.TracingManager.ping!()
    LiveDebugger.API.SettingsStorage.save(:tracing_enabled_on_start, true)

    :ok
  end

  @sessions 2
  feature "user can see and track async jobs in LiveView and LiveComponent", %{
    sessions: [dev_app, debugger]
  } do
    dev_app
    |> visit("#{@dev_app_url}/async_demo")

    debugger
    |> visit("/")
    |> click(first_link())
    |> assert_has(node_module_info("AsyncDemo"))
    |> assert_has(async_jobs_section())
    |> assert_has(no_async_jobs())

    dev_app
    |> click(button("start-async-button"))

    Process.sleep(100)

    debugger
    |> assert_has(async_job_name(":fetch_data"))

    Process.sleep(600)

    debugger
    |> assert_has(no_async_jobs())

    dev_app
    |> click(button("assign-async-button"))

    Process.sleep(100)

    debugger
    |> assert_has(async_job_name(":async_data1, :async_data2"))

    Process.sleep(600)

    debugger
    |> assert_has(no_async_jobs())
    |> click(component_tree_node(1))
    |> assert_has(node_module_info("AsyncDemoComponent"))
    |> assert_has(no_async_jobs())

    dev_app
    |> click(button("component-start-async-button"))

    Process.sleep(100)

    debugger
    |> assert_has(async_job_name(":component_fetch_data"))

    Process.sleep(600)

    debugger
    |> assert_has(no_async_jobs())

    dev_app
    |> click(button("component-assign-async-button"))

    Process.sleep(100)

    debugger
    |> assert_has(async_job_name(":component_async_data1, :component_async_data2"))

    Process.sleep(600)

    debugger
    |> assert_has(no_async_jobs())

    dev_app
    |> click(button("component-start-cancelable-async-button"))

    Process.sleep(100)

    debugger
    |> assert_has(async_job_name(":component_cancelable_fetch"))

    dev_app
    |> click(button("component-cancel-async-button"))

    Process.sleep(100)

    debugger
    |> assert_has(no_async_jobs())
  end

  defp async_jobs_section(), do: css("#async-jobs")

  defp async_job_name(name), do: css("#async-jobs p.font-medium", text: name)

  defp no_async_jobs(), do: css("#async-jobs", text: "No async jobs found")

  defp node_module_info(text),
    do: css("#node-inspector-basic-info-current-node-module", text: text)

  defp component_tree_node(cid), do: css("#button-tree-node-#{cid}-components-tree")
end
