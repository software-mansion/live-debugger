defmodule LiveDebugger.App.Debugger.Web.Components.HandlerInfo do
  @moduledoc """
  Component for displaying info banners about LiveView/LiveComponent handlers.
  """

  use Phoenix.Component

  import LiveDebugger.App.Web.Components, only: [icon: 1]

  @handler_info %{
    "handle_event/3" => %{
      prefix: "Sends a",
      via_text: "Phoenix LiveView event",
      via_url: "https://hexdocs.pm/phoenix_live_view/Phoenix.LiveView.html#module-bindings",
      callbacks: [
        {"handle_event/3",
         "https://hexdocs.pm/phoenix_live_view/Phoenix.LiveView.html#c:handle_event/3"}
      ]
    },
    "handle_info/2" => %{
      prefix: "Sends a message via",
      via_text: "Kernel.send/2",
      via_url: "https://hexdocs.pm/elixir/Kernel.html#send/2",
      callbacks: [
        {"handle_info/2",
         "https://hexdocs.pm/phoenix_live_view/Phoenix.LiveView.html#c:handle_info/2"}
      ]
    },
    "handle_cast/2" => %{
      prefix: "Sends an async message via",
      via_text: "GenServer.cast/2",
      via_url: "https://hexdocs.pm/elixir/GenServer.html#cast/2",
      callbacks: [
        {"handle_cast/2",
         "https://hexdocs.pm/phoenix_live_view/Phoenix.LiveView.html#c:handle_cast/2"}
      ]
    },
    "handle_call/3" => %{
      prefix: "Sends a sync message via",
      via_text: "GenServer.call/3",
      via_url: "https://hexdocs.pm/elixir/GenServer.html#call/3",
      callbacks: [
        {"handle_call/3",
         "https://hexdocs.pm/phoenix_live_view/Phoenix.LiveView.html#c:handle_call/3"}
      ]
    },
    "update/2" => %{
      prefix: "Sends assigns via",
      via_text: "Phoenix.LiveView.send_update/3",
      via_url: "https://hexdocs.pm/phoenix_live_view/Phoenix.LiveView.html#send_update/3",
      callbacks: [
        {"update/2",
         "https://hexdocs.pm/phoenix_live_view/Phoenix.LiveComponent.html#c:update/2"},
        {"update_many/1",
         "https://hexdocs.pm/phoenix_live_view/Phoenix.LiveComponent.html#c:update_many/1"}
      ]
    }
  }

  @doc """
  Displays info about what a handler does with links to documentation.

  ## Examples

      <.handler_info handler="handle_event/3" />
      <.handler_info handler="handle_info/2" />
  """
  attr(:handler, :string, required: true)

  def handler_info(assigns) do
    info = @handler_info[assigns.handler]
    assigns = assign(assigns, :content, build_handler_info_content(info))

    ~H"""
    <div class="flex items-start gap-2 text-xs text-secondary-text pl-1 pb-2">
      <.icon name="icon-info" class="w-4 h-4 shrink-0 text-info-icon" />
      <span><%= @content %></span>
    </div>
    """
  end

  defp build_handler_info_content(info) do
    link = fn text, url -> ~s(<a href="#{url}" target="_blank" class="underline">#{text}</a>) end

    callbacks_html =
      info.callbacks
      |> Enum.map(fn {text, url} -> link.(text, url) end)
      |> Enum.intersperse(" or ")
      |> Enum.join()

    "#{info.prefix} #{link.(info.via_text, info.via_url)} and triggers #{callbacks_html} callback."
    |> Phoenix.HTML.raw()
  end
end
