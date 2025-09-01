defmodule LiveDebugger.TidewaveMcp.Tools.SeeActiveLiveViews do
  def tools do
    [
      %{
        name: "see_active_live_views",
        description: """
        Lists all active live views in your app.
        """,
        inputSchema: %{
          type: "object",
          required: [],
          properties: %{}
        },
        callback: &see_active_live_views/1
      }
    ]
  end

  def see_active_live_views(_args) do
    live_views =
      Enum.map(LiveDebugger.API.LiveViewDebug.list_liveviews(), fn live_view ->
        "* #{live_view.view}"
      end)

    {:ok, Enum.join(live_views, "\n")}
  end
end
