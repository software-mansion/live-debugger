defmodule LiveDebugger.E2E.StreamsTest do
  use LiveDebugger.E2ECase

  setup_all do
    LiveDebugger.Services.CallbackTracer.GenServers.TracingManager.ping!()
    LiveDebugger.API.SettingsStorage.save(:tracing_enabled_on_start, false)

    :ok
  end

  setup %{sessions: [_dev_app, debugger]} do
    debugger
    |> visit("/")
    |> set_collapsible_open_state("streams-section-container", "true")

    :ok
  end

  @sessions 2
  feature "User can see modifications of the stream updates", %{
    sessions: [dev_app, debugger]
  } do
    dev_app
    |> visit(@dev_app_url <> "/stream")

    debugger
    |> visit("/")
    |> select_live_view()
    |> assert_has(items_display())
    |> click(items_display())
    |> assert_has(another_items_display())
    |> click(another_items_display())

    dev_app
    |> click(create_item_button())
    |> click(create_item_button())
    |> click(create_another_item_button())

    debugger
    |> assert_has(another_items_stream(count: 1))
    |> assert_has(items_stream(count: 2))

    dev_app
    |> click(reset_items_button())

    debugger
    |> assert_has(items_stream(count: 0))

    dev_app
    |> click(create_item_button())
    |> click(create_item_button())
    |> click(create_item_button())
    |> click(create_item_button())
    |> click(delete_item_button())

    debugger
    |> assert_has(items_stream(count: 3))

    dev_app
    |> click(add_new_stream_button())

    debugger
    |> assert_has(new_items_display())
  end

  @sessions 2
  feature "User can see modifications to the stream that occurred before it was rendered in debugger.",
          %{
            sessions: [dev_app, debugger]
          } do
    dev_app
    |> visit(@dev_app_url <> "/stream")
    |> click(create_item_button())
    |> click(create_item_button())
    |> click(reset_items_button())
    |> click(create_item_button())
    |> click(create_item_button())
    |> click(delete_item_button())
    |> click(create_another_item_button())
    |> click(create_another_item_button())
    |> click(add_new_stream_button())

    debugger
    |> visit("/")
    |> select_live_view()
    |> assert_has(items_display())
    |> click(items_display())
    |> assert_has(another_items_display())
    |> click(another_items_display())
    |> assert_has(new_items_display())

    debugger
    |> assert_has(another_items_stream(count: 2))
    |> assert_has(items_stream(count: 1))
  end

  @sessions 2
  feature "User can see streams in LiveView and LiveComponents",
          %{
            sessions: [dev_app, debugger]
          } do
    dev_app
    |> visit(@dev_app_url <> "/stream")
    |> click(create_item_button())

    debugger
    |> visit("/")
    |> select_live_view()
    |> assert_has(items_display())
    |> click(items_display())
    |> assert_has(another_items_display())
    |> click(another_items_display())

    debugger
    |> click(component_tree_node(1))
    |> assert_has(node_module_info("StreamComponent"))
    |> assert_has(component_items_display())
    |> click(component_items_display())
    |> assert_has(component_items_stream(count: 3))
  end

  @sessions 2
  feature "User don't see streams section if there are no streams",
          %{
            sessions: [dev_app, debugger]
          } do
    dev_app
    |> visit(@dev_app_url)

    debugger
    |> visit("/")
    |> select_live_view()
    |> refute_has(streams_display())
  end

  @sessions 2
  feature "collapsible state stays after navigation", %{
    sessions: [dev_app, debugger]
  } do
    dev_app
    |> visit(@dev_app_url <> "/stream")

    debugger
    |> visit("/")
    |> select_live_view()
    |> assert_has(streams_display())
    |> click(streams_collapsible())
    |> refute_has(streams_display())
    |> visit("/")
    |> select_live_view()
    |> refute_has(streams_display())
    |> click(streams_collapsible())
    |> assert_has(streams_display())
  end

  defp component_tree_node(cid), do: css("#button-tree-node-#{cid}-components-tree")

  defp create_item_button(), do: css("button#create-item")
  defp create_another_item_button(), do: css("button#create-another-item")
  defp reset_items_button(), do: css("button#reset-items")
  defp delete_item_button(), do: css("button#delete-item")
  defp add_new_stream_button(), do: css("button#add-new-stream")

  defp streams_display(), do: css("#streams-display-container")
  defp streams_collapsible(), do: css("summary#streams-section-container-summary")

  defp node_module_info(text),
    do: css("#node-inspector-basic-info-current-node-module", text: text)

  defp items_display(), do: css("#items-display")
  defp another_items_display(), do: css("#another_items-display")
  defp new_items_display(), do: css("#new_items-display")
  defp component_items_display(), do: css("#component_items-display")

  defp items_stream(opts), do: css("#items-stream details", opts)
  defp another_items_stream(opts), do: css("#another_items-stream details", opts)
  defp component_items_stream(opts), do: css("#component_items-stream details", opts)

  defp set_collapsible_open_state(debugger, section_id, state) do
    debugger
    |> execute_script(
      """
      localStorage.setItem(`lvdbg:collapsible-open-${arguments[0]}`, arguments[1])
      """,
      [section_id, state]
    )
  end
end
