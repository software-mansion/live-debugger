defmodule LiveDebugger.E2E.Utils do
  @moduledoc "Helpers for the browser suite."

  alias Playwright.Locator
  alias Playwright.Page

  def find_assigns_entry(page, key, value) do
    Page.locator(
      page,
      ~s|xpath=//*[@id="assigns"]//*[contains(normalize-space(text()), "#{key}:")]/../..//*[contains(normalize-space(text()), "#{value}")]|
    )
  end

  def find_traces(page), do: Page.locator(page, "#traces-list-stream details")

  def find_switch_tracing_button(page),
    do: Page.locator(page, ~s|button[phx-click="switch-tracing"]|)

  def find_clear_traces_button(page), do: Page.locator(page, ~s|button[phx-click="clear-traces"]|)

  def find_refresh_traces_button(page),
    do: Page.locator(page, ~s|button[phx-click="refresh-history"]|)

  def find_filters_button(page), do: Page.locator(page, ~s|button[aria-label="Open filters"]|)

  def get_dev_pid(page) do
    pid_el = Page.locator(page, "#current-pid")
    Locator.wait_for!(pid_el)
    pid_el |> Locator.text_content!() |> to_string() |> String.trim()
  end

  def return_button(page), do: Page.locator(page, "#return-button")
  def find_node_inspector_button(page), do: Page.locator(page, "#node-inspector-navbar-item a")

  def find_node_module_info(page),
    do: Page.locator(page, "#node-inspector-basic-info-current-node-module")

  def find_component_tree_node(page, cid),
    do: Page.locator(page, "#button-tree-node-#{cid}-components-tree")

  def find_sidebar_basic_info(page), do: Page.locator(page, "#node-inspector-basic-info")
  def find_global_traces_navbar_item(page), do: Page.locator(page, "#global-traces-navbar-item a")

  def restart_tracing(page) do
    find_switch_tracing_button(page) |> Locator.click!()
    find_clear_traces_button(page) |> Locator.click!()
    find_switch_tracing_button(page) |> Locator.click!()
  end

  def set_collapsible_open_state(page, section_id, state) do
    Page.evaluate!(
      page,
      "([id, st]) => localStorage.setItem(`lvdbg:collapsible-open-${id}`, st)",
      [section_id, state]
    )
  end

  def open_debugger(dev_app) do
    Page.locator(dev_app, "#live-debugger-debug-button") |> Locator.click!()

    Page.expect_popup!(dev_app, fn ->
      Page.get_by_text(dev_app, "Open in new tab") |> Locator.click!()
    end)
  end
end
