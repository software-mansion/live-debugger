defmodule LiveDebuggerRefactor.Event do
  @moduledoc """
  Provides a simple way to define structured events in LiveDebugger.

  This module offers a `defevent` macro that generates event structs with enforced fields
  and optional context. Events are useful for tracking and debugging application state
  changes, user interactions, or system events within LiveDebugger.

  ## Usage

  First, use this module in your events module:

  ```elixir
  defmodule LiveDebugger.Events do
    use LiveDebuggerRefactor.Event

    defevent(UserCreated, name: String.t(), email: String.t(), age: integer())
    defevent(ProcessStarted, pid: pid(), module: atom(), timestamp: DateTime.t())
  end
  ```

  Then create event instances:

  ```elixir
  # Create an event with required fields
  event = %LiveDebugger.Events.UserCreated{
    name: "John Doe",
    email: "john.doe@example.com",
    age: 30,
    context: %{
      debugger_pid: self(),
      session_id: "abc123"
    }
  }

  # Context is optional and defaults to an empty map
  simple_event = %LiveDebugger.Events.ProcessStarted{
    pid: self(),
    module: MyModule,
    timestamp: DateTime.utc_now()
  }
  ```

  ## Generated Struct

  The `defevent` macro generates a struct with:
  - All specified fields as enforced keys
  - A `context` field (defaults to `%{}`)
  - Proper type specifications

  ## Examples

  ### Basic Event Definition
  ```elixir
  defevent(ButtonClicked, button_id: String.t(), user_id: integer())
  ```

  ### Event with Complex Types
  ```elixir
  defevent(StateChanged,
    old_state: map(),
    new_state: map(),
    changed_keys: [atom()],
    timestamp: DateTime.t()
  )
  ```
  """

  defmacro __using__(_) do
    quote do
      require LiveDebuggerRefactor.Event
      import LiveDebuggerRefactor.Event
    end
  end

  defmacro defevent(module_name, fields) do
    quote do
      defmodule unquote(module_name) do
        @default_fields [context: %{}]

        @enforce_keys unquote(Keyword.keys(fields))
        defstruct unquote(fields |> Keyword.keys() |> Enum.map(&{&1, nil})) ++ @default_fields

        @type t :: %__MODULE__{
                unquote_splicing(Enum.map(fields, fn {field, type} -> {field, type} end)),
                context: map()
              }
      end
    end
  end
end
