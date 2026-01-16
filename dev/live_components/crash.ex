defmodule LiveDebuggerDev.LiveComponents.Crash do
  use DevWeb, :live_component

  defmodule User do
    defstruct [:name]
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.box title="Crash [LiveComponent]" color="red">
        <div class="flex flex-col gap-2">
          <.button phx-click="crash" color="red" phx-target={@myself}>Crash</.button>
          <.button phx-click="crash_after_sleep" color="red" phx-target={@myself}>
            Crash after 4s
          </.button>

          <.button phx-click="crash_argument" color="red" phx-target={@myself}>
            ArgumentError
          </.button>

          <.button phx-click="crash_case" color="red" phx-target={@myself}>
            CaseClauseError
          </.button>

          <.button phx-click="crash_match" color="red" phx-target={@myself}>
            MatchError
          </.button>

          <.button phx-click="crash_exit" color="red" phx-target={@myself}>
            exit
          </.button>

          <.button phx-click="crash_throw" color="red" phx-target={@myself}>
            throw
          </.button>

          <.button phx-click="crash_function_clause" color="red" phx-target={@myself}>
            FunctionClauseError
          </.button>

          <.button phx-click="crash_undefined" color="red" phx-target={@myself}>
            UndefinedFunctionError
          </.button>

          <.button phx-click="crash_arithmetic" color="red" phx-target={@myself}>
            ArithmeticError
          </.button>

          <.button phx-click="crash_linked" color="red" phx-target={@myself}>
            Linked Process Crash
          </.button>

          <.button phx-click="crash_protocol" color="red" phx-target={@myself}>
            Protocol Error
          </.button>

          <.button phx-click="crash_key" color="red" phx-target={@myself}>
            KeyError
          </.button>

          <.button phx-click="crash_bad_return" color="red" phx-target={@myself}>
            Bad Return
          </.button>
        </div>
      </.box>
    </div>
    """
  end

  defp hide_value(val), do: val

  @impl true
  def handle_event("crash", _, _) do
    raise "Exception in handle_event"
  end

  def handle_event("crash_after_sleep", _, _) do
    Process.sleep(4000)
    raise "Exception in handle_event"
  end

  def handle_event("crash_argument", _, socket) do
    _ = apply(String, :to_integer, ["invalid_integer"])
    {:noreply, socket}
  end

  def handle_event("crash_case", _, socket) do
    val = hide_value(:unexpected)

    case val do
      :expected -> :ok
    end

    {:noreply, socket}
  end

  def handle_event("crash_match", _, socket) do
    mismatch = hide_value({:error, "mismatch"})
    {:ok, _val} = mismatch
    {:noreply, socket}
  end

  def handle_event("crash_exit", _, socket) do
    exit(:exit_reason)
    {:noreply, socket}
  end

  def handle_event("crash_throw", _, socket) do
    throw(:throw_value)
    {:noreply, socket}
  end

  def handle_event("crash_function_clause", _, socket) do
    val = hide_value(:error)
    private_function(val)
    {:noreply, socket}
  end

  def handle_event("crash_undefined", _, socket) do
    apply(List, :this_function_does_not_exist, [[1, 2, 3]])
    {:noreply, socket}
  end

  def handle_event("crash_arithmetic", _, socket) do
    zero = hide_value(0)
    _result = 1 / zero
    {:noreply, socket}
  end

  def handle_event("crash_linked", _, socket) do
    spawn_link(fn ->
      raise "link died"
    end)

    {:noreply, socket}
  end

  def handle_event("crash_protocol", _, socket) do
    val = hide_value(12345)
    Enum.map(val, fn x -> x * 2 end)
    {:noreply, socket}
  end

  def handle_event("crash_key", _, socket) do
    user = %User{name: "test"}
    _ = Map.fetch!(user, :age)
    {:noreply, socket}
  end

  def handle_event("crash_bad_return", _, socket) do
    {:ok, socket}
  end

  defp private_function(:ok), do: :ok
end
