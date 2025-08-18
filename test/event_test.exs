defmodule LiveDebugger.EventTest do
  @moduledoc false

  use ExUnit.Case, async: true

  defmodule TestEvents do
    @moduledoc false
    use LiveDebugger.Event

    defevent(UserCreated, name: String.t(), email: String.t(), age: integer())
  end

  test "generates a struct with the correct fields with default context" do
    event = %TestEvents.UserCreated{name: "John", email: "john@example.com", age: 30}

    assert event.name == "John"
    assert event.email == "john@example.com"
    assert event.age == 30
    assert event.context == %{}
  end

  test "generates a struct with the correct fields with custom context" do
    event = %TestEvents.UserCreated{
      name: "John",
      email: "john@example.com",
      age: 30,
      context: %{pid: self()}
    }

    assert event.name == "John"
    assert event.email == "john@example.com"
    assert event.age == 30
    assert event.context == %{pid: self()}
  end
end
