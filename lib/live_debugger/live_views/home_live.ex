defmodule LiveDebugger.LiveViews.HomeLive do
  use LiveDebuggerWeb, :live_view

  alias LiveDebugger.LiveComponents.ElixirDisplay

  @mock_data %{
    id: 1,
    email: "user@example.com",
    inserted_at: ~U[2022-01-01T10:00:00Z],
    addresses: [
      %{
        country: "pl",
        city: "Kraków",
        street: "Karmelicka",
        zip: "00123"
      }
    ]
  }

  @impl true
  def render(assigns) do
    assigns = assign(assigns, :mock_data, @mock_data)

    ~H"""
    <.container max_width="full">
      <.h1 class="m-5 mb-6">Hello from LiveDebugger</.h1>
      <.live_component
        id="elixir-display"
        module={ElixirDisplay}
        node={@mock_data |> ElixirDisplay.to_node([]) |> dbg()}
        level={1}
      />
    </.container>
    """
  end
end
