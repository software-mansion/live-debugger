defmodule LiveDebugger.App.Debugger.Resources.Components do
  @moduledoc false

  use LiveDebugger.App.Web, :component

  alias LiveDebugger.App.Web.LiveComponents.LiveDropdown
  alias LiveDebugger.App.Debugger.Resources.Structs.ProcessInfo
  alias LiveDebugger.Utils.Memory

  @refresh_intervals [
    {"1 second", 1000},
    {"5 seconds", 5000},
    {"15 seconds", 15000},
    {"30 seconds", 30000}
  ]

  @keys_order ~w(
    initial_call
    current_function
    registered_name
    status
    message_queue_len
    priority
    reductions
    memory
    total_heap_size
    heap_size
    stack_size
  )a

  @memory_keys ~w(memory total_heap_size heap_size stack_size)a

  attr(:id, :string, required: true)
  attr(:name, :string, required: true)
  attr(:class, :string, default: "", doc: "Additional classes to add to the dropdown container")

  attr(:selected_interval, :integer,
    required: true,
    doc: "Currently selected refresh interval in milliseconds"
  )

  def refresh_select(assigns) do
    assigns = assign(assigns, :options, @refresh_intervals)

    ~H"""
    <.live_component module={LiveDropdown} id={@id} class={@class} direction={:bottom_left}>
      <:button>
        <.refresh_button selected_interval={@selected_interval} />
      </:button>
      <div class="min-w-44 flex flex-col p-2 gap-1">
        <.form for={%{}} phx-change="change-refresh-interval">
          <.radio_button
            :for={{label, value} <- @options}
            name={@name}
            value={value}
            label={label}
            checked={value == @selected_interval}
          />
        </.form>
      </div>
    </.live_component>
    """
  end

  attr(:process_info, ProcessInfo, required: true)

  def process_info(assigns) do
    assigns = assign(assigns, keys_order: @keys_order)

    ~H"""
    <div>
      <%= for key <- @keys_order do %>
        <div class="flex py-1">
          <span class="font-medium w-36 flex-shrink-0"><%= display_key(key) %>:</span>
          <span class={"font-code #{value_color_class(key)} truncate"}>
            <%= @process_info |> Map.get(key) |> display_value(key) %>
          </span>
        </div>
      <% end %>
    </div>
    """
  end

  attr(:selected_interval, :integer, required: true)

  defp refresh_button(assigns) do
    ~H"""
    <button
      aria-label="Refresh Rate"
      class={[
        "border border-default-border rounded-md p-2 text-accent-text flex items-center gap-1"
      ]}
    >
      <.icon name="icon-stopwatch" class="h-4 w-4" />
      <span class="text-xs font-semibold">
        Refresh Rate (<%= Kernel.round(@selected_interval / 1000) %> s)
      </span>
    </button>
    """
  end

  defp display_key(key) do
    key
    |> to_string()
    |> String.replace(":", " ")
    |> String.split("_")
    |> Enum.map(&String.capitalize/1)
    |> Enum.join(" ")
  end

  defp value_color_class(:message_queue_len), do: "text-code-1"
  defp value_color_class(:reductions), do: "text-code-1"
  defp value_color_class(:memory), do: "text-code-4"
  defp value_color_class(:total_heap_size), do: "text-code-4"
  defp value_color_class(:heap_size), do: "text-code-4"
  defp value_color_class(:stack_size), do: "text-code-4"
  defp value_color_class(_), do: "text-code-2"

  defp display_value(mfa, :current_function), do: mfa_to_string(mfa)
  defp display_value(mfa, :initial_call), do: mfa_to_string(mfa)
  defp display_value(priority, :priority), do: "#{priority}"
  defp display_value(status, :status), do: "#{status}"
  defp display_value([], :registered_name), do: ""

  defp display_value(size, key) when key in @memory_keys do
    Memory.bytes_to_pretty_string(size)
  end

  defp display_value(value, _key), do: inspect(value)

  defp mfa_to_string({module, function, arity}) do
    "#{inspect(module)}.#{function}/#{arity}"
  end
end
