defmodule LiveDebugger.E2E.StreamsTest do
  use LiveDebugger.E2E.Case, async: true, parameterize: LiveDebugger.E2E.Case.projects()

  defp create_item_btn(page), do: Page.locator(page, "button#create-item")
  defp create_another_item_btn(page), do: Page.locator(page, "button#create-another-item")
  defp reset_items_btn(page), do: Page.locator(page, "button#reset-items")
  defp delete_item_btn(page), do: Page.locator(page, "button#delete-item")
  defp add_new_stream_btn(page), do: Page.locator(page, "button#add-new-stream")

  defp streams_display(page), do: Page.locator(page, "#streams-display-container")

  defp items_display(page), do: Page.locator(page, "#items-display")
  defp another_items_display(page), do: Page.locator(page, "#another_items-display")
  defp new_items_display(page), do: Page.locator(page, "#new_items-display")
  defp component_items_display(page), do: Page.locator(page, "#component_items-display")

  defp items_stream_details(page), do: Page.locator(page, "#items-stream > details")

  defp another_items_stream_details(page),
    do: Page.locator(page, "#another_items-stream > details")

  defp component_items_stream_details(page),
    do: Page.locator(page, "#component_items-stream > details")

  describe "LiveDebugger Streams" do
    @describetag dev_url: "/stream"
    @describetag :dbg_app

    setup %{dbg_app: dbg_app} do
      set_collapsible_open_state(dbg_app, "streams-section-container", "true")
      Page.reload!(dbg_app)
      :ok
    end

    test "User can see modifications of the stream updates", %{
      dev_app: dev_app,
      dbg_app: dbg_app
    } do
      Expect.to_be_visible!(items_display(dbg_app))
      Locator.click!(items_display(dbg_app))

      Expect.to_be_visible!(another_items_display(dbg_app))
      Locator.click!(another_items_display(dbg_app))

      Locator.click!(create_item_btn(dev_app))
      Locator.click!(create_item_btn(dev_app))
      Locator.click!(create_another_item_btn(dev_app))

      Expect.to_have_count!(another_items_stream_details(dbg_app), 1)
      Expect.to_have_count!(items_stream_details(dbg_app), 2)

      Locator.click!(reset_items_btn(dev_app))

      Expect.to_have_count!(items_stream_details(dbg_app), 0)

      Locator.click!(create_item_btn(dev_app))
      Locator.click!(create_item_btn(dev_app))
      Locator.click!(create_item_btn(dev_app))
      Locator.click!(create_item_btn(dev_app))
      Locator.click!(delete_item_btn(dev_app))

      Expect.to_have_count!(items_stream_details(dbg_app), 3)

      Locator.click!(add_new_stream_btn(dev_app))

      Expect.to_be_visible!(new_items_display(dbg_app))
    end

    test "User can see streams in LiveView and LiveComponents", %{
      dev_app: dev_app,
      dbg_app: dbg_app
    } do
      Locator.click!(create_item_btn(dev_app))

      Expect.to_be_visible!(items_display(dbg_app))
      Locator.click!(items_display(dbg_app))

      Expect.to_be_visible!(another_items_display(dbg_app))
      Locator.click!(another_items_display(dbg_app))

      find_component_tree_node(dbg_app, 1) |> Locator.click!()

      Expect.to_contain_text!(find_node_module_info(dbg_app), "StreamComponent")
      Expect.to_be_visible!(component_items_display(dbg_app))

      Locator.click!(component_items_display(dbg_app))

      Expect.to_have_count!(component_items_stream_details(dbg_app), 3)
    end

    test "collapsible state stays after navigation", %{dbg_app: dbg_app} do
      Expect.to_be_visible!(streams_display(dbg_app))
      set_collapsible_open_state(dbg_app, "streams-section-container", "false")
      Page.reload!(dbg_app)
      Expect.not_to_be_visible!(streams_display(dbg_app))

      set_collapsible_open_state(dbg_app, "streams-section-container", "true")
      Page.reload!(dbg_app)
      Expect.to_be_visible!(streams_display(dbg_app))
    end
  end

  test "User can see modifications to the stream that occurred before it was rendered in debugger.",
       %{page: page} do
    dev_app = page
    Page.goto!(dev_app, "/stream")

    Locator.click!(create_item_btn(dev_app))
    Locator.click!(create_item_btn(dev_app))
    Locator.click!(reset_items_btn(dev_app))
    Locator.click!(create_item_btn(dev_app))
    Locator.click!(create_item_btn(dev_app))
    Locator.click!(delete_item_btn(dev_app))
    Locator.click!(create_another_item_btn(dev_app))
    Locator.click!(create_another_item_btn(dev_app))
    Locator.click!(add_new_stream_btn(dev_app))

    dbg_app = open_debugger(dev_app)

    set_collapsible_open_state(dbg_app, "streams-section-container", "true")
    Page.reload!(dbg_app)

    Expect.to_be_visible!(items_display(dbg_app))
    Locator.click!(items_display(dbg_app))

    Expect.to_be_visible!(another_items_display(dbg_app))
    Locator.click!(another_items_display(dbg_app))

    Expect.to_be_visible!(new_items_display(dbg_app))

    Expect.to_have_count!(another_items_stream_details(dbg_app), 2)
    Expect.to_have_count!(items_stream_details(dbg_app), 1)
  end

  describe "without streams" do
    @describetag dev_url: "/"
    @describetag :dbg_app

    test "User does not see streams section if there are no streams", %{dbg_app: dbg_app} do
      Expect.not_to_be_visible!(streams_display(dbg_app))
    end
  end
end
