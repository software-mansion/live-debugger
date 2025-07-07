defmodule LiveDebuggerRefactor.Event do
  @moduledoc """
  This module is used to defined LiveDebugger events.
  LiveDebugger event is defined as a struct that contains fields specified by developer and the context.
  Each field is a key-value pair where the key is the field name and the value is the type of the field.
  Each field is enforced and has to be present when creating the event.

  Context is a map that may contain context of the event. It is not enforced and can be nil.

  Event are defined by `defevent` macro that accepts module name and a keyword list of fields.
  Each field is a key-value pair where the key is the field name and the value is the type of the field.

  ## Example

  ```elixir
  defmodule LiveDebugger.Events do
    use LiveDebugger.Event

    defevent(UserCreated, name: String.t(), email: String.t(), age: integer())
  end
  ```

  After defining the event, it can be used in the LiveDebugger in the following way:

  ## Example
  ```elixir
  %LiveDebugger.Events.UserCreated{
    name: "John Doe",
    email: "john.doe@example.com",
    age: 30,
    context: %{
      debugger_pid: self()
    }
  }
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
