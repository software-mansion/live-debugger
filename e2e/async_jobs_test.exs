defmodule LiveDebugger.E2E.AsyncJobsTest do
  use LiveDebugger.E2E.Case, async: true, parameterize: LiveDebugger.E2E.Case.projects()

  @moduletag dev_url: "/async_demo"
  @moduletag :dbg_app

  defp async_jobs_section(page), do: Page.locator(page, "#async-jobs")

  defp async_job_name(page, name),
    do: Page.locator(page, "#async-jobs p.font-medium", has_text: name)

  setup %{dbg_app: dbg_app} do
    set_collapsible_open_state(dbg_app, "async-jobs", "true")
    Page.reload!(dbg_app)
    :ok
  end

  test "user can see and track async jobs in LiveView and LiveComponent", %{
    dev_app: dev_app,
    dbg_app: dbg_app
  } do
    Expect.to_contain_text!(find_node_module_info(dbg_app), "AsyncDemo")
    Expect.to_be_visible!(async_jobs_section(dbg_app))
    Expect.to_contain_text!(async_jobs_section(dbg_app), "No active async jobs found")

    Page.locator(dev_app, "#start-async-button") |> Locator.click!()
    Expect.to_be_visible!(async_job_name(dbg_app, ":fetch_data"))
    Expect.to_contain_text!(async_jobs_section(dbg_app), "No active async jobs found")

    Page.locator(dev_app, "#assign-async-button") |> Locator.click!()
    Expect.to_be_visible!(async_job_name(dbg_app, ":async_data1, :async_data2"))
    Expect.to_contain_text!(async_jobs_section(dbg_app), "No active async jobs found")

    find_component_tree_node(dbg_app, 1) |> Locator.click!()
    Expect.to_contain_text!(find_node_module_info(dbg_app), "AsyncDemoComponent")
    Expect.to_contain_text!(async_jobs_section(dbg_app), "No active async jobs found")

    Page.locator(dev_app, "#component-start-async-button") |> Locator.click!()
    Expect.to_be_visible!(async_job_name(dbg_app, ":component_fetch_data"))
    Expect.to_contain_text!(async_jobs_section(dbg_app), "No active async jobs found")

    Page.locator(dev_app, "#component-assign-async-button") |> Locator.click!()

    Expect.to_be_visible!(
      async_job_name(dbg_app, ":component_async_data1, :component_async_data2")
    )

    Expect.to_contain_text!(async_jobs_section(dbg_app), "No active async jobs found")

    Page.locator(dev_app, "#component-long-load-toggle") |> Locator.click!()
    Page.locator(dev_app, "#component-start-cancelable-async-button") |> Locator.click!()
    Expect.to_be_visible!(async_job_name(dbg_app, ":component_cancelable_fetch"))

    Page.locator(dev_app, "#component-cancel-async-button") |> Locator.click!()
    Expect.to_contain_text!(async_jobs_section(dbg_app), "No active async jobs found")
  end
end
