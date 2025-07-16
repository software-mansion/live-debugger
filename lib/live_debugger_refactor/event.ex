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

  @typedoc """
  General type for all events.

  It is a map with the following keys:
  - `:__struct__` - the name of the event module
  - `:context` - the context of the event
  - `optional(atom())` - the fields of the event
  """
  @type t :: %{
          :__struct__ => atom(),
          :context => map(),
          optional(atom()) => any()
        }

  @doc """
  Brings the event definition functionality into scope.

  This macro should be used at the top of your events module to import
  the `defevent` macro and make it available for defining events.

  ## Example

  ```elixir
  defmodule LiveDebugger.Events do
    use LiveDebuggerRefactor.Event
    # Now you can use defevent/2
  end
  ```
  """
  defmacro __using__(_) do
    quote do
      require LiveDebuggerRefactor.Event
      import LiveDebuggerRefactor.Event
    end
  end

  @doc """
  Defines a new event struct with enforced fields and optional context.

  This macro generates a complete event module with:
  - A struct definition with all specified fields as enforced keys
  - A `context` field that defaults to an empty map
  - Type specifications
  """
  defmacro defevent(module_name, fields \\ []) do
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
