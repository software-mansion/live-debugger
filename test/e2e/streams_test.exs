defmodule LiveDebugger.E2E.StreamsTest do
  use LiveDebugger.E2ECase

  setup_all do
    LiveDebugger.Services.CallbackTracer.GenServers.TracingManager.ping!()
    LiveDebugger.API.SettingsStorage.save(:tracing_enabled_on_start, false)

    :ok
  end

  @sessions 2
  feature "User can see elements and changes of the stream", %{
    sessions: [dev_app, debugger]
  } do
    dev_app
    |> visit(@dev_app_url <> "/stream")

    debugger
    |> visit("/")
    |> click(first_link())
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

  def create_item_button(), do: css("button#create-item")
  def create_another_item_button(), do: css("button#create-another-item")
  def reset_items_button(), do: css("button#reset-items")
  def delete_item_button(), do: css("button#delete-item")
  def add_new_stream_button(), do: css("button#add-new-stream")

  def streams(), do: css("#streams-display-container")

  def items_display(), do: css("#items-display")
  def another_items_display(), do: css("#another_items-display")
  def new_items_display(), do: css("#new_items-display")

  def items_stream(opts), do: css("#items-stream details", opts)
  def another_items_stream(opts), do: css("#another_items-stream details", opts)
end
