defmodule LiveDebugger.E2E.SendEventTest do
  use LiveDebugger.E2E.Case, async: true, parameterize: LiveDebugger.E2E.Case.projects()

  @moduletag dev_url: "/"
  @moduletag :dbg_app

  defp send_event_button(page), do: Page.locator(page, "button#send-event-button")
  defp send_event_fullscreen(page), do: Page.locator(page, "dialog#send-event-fullscreen[open]")
  defp handler_select(page), do: Page.locator(page, "select#send-event-fullscreen-form_handler")
  defp event_input(page), do: Page.locator(page, "input#send-event-fullscreen-form_event")
  defp code_mirror_textbox(page), do: Page.locator(page, ~s|div.cm-content[role="textbox"]|)

  defp send_button(page),
    do: Page.locator(page, ~s|dialog#send-event-fullscreen button[type="submit"]|)

  defp dispatch_event(page, handler, opts) do
    Locator.click!(send_event_button(page))
    Expect.to_be_visible!(send_event_fullscreen(page))
    Locator.select_option!(handler_select(page), handler)

    if opts[:event] do
      Locator.fill!(event_input(page), opts[:event])
    end

    if opts[:payload] do
      Locator.fill!(code_mirror_textbox(page), opts[:payload])
    end

    Locator.click!(send_button(page))
    Expect.not_to_be_visible!(send_event_fullscreen(page))
  end

  test "user can send events to LiveView and LiveComponent", %{dbg_app: dbg_app} do
    Expect.to_be_visible!(find_sidebar_basic_info(dbg_app))
    Expect.to_be_visible!(find_assigns_entry(dbg_app, "counter", "0"))

    dispatch_event(dbg_app, "handle_info/2", payload: ":increment")
    Expect.to_be_visible!(find_assigns_entry(dbg_app, "counter", "1"))

    find_component_tree_node(dbg_app, 5) |> Locator.click!()
    Expect.to_be_visible!(find_assigns_entry(dbg_app, "show_child?", "false"))

    dispatch_event(dbg_app, "handle_event/3", event: "show_child")
    Expect.to_be_visible!(find_assigns_entry(dbg_app, "show_child?", "true"))

    dispatch_event(dbg_app, "update/2", payload: "%{show_child?: false}")
    Expect.to_be_visible!(find_assigns_entry(dbg_app, "show_child?", "false"))
  end
end
