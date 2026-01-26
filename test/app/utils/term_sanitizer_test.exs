defmodule LiveDebugger.App.Utils.TermSanitizerTest do
  use ExUnit.Case, async: true

  alias LiveDebugger.App.Utils.TermSanitizer

  describe "sanitize/1" do
    test "passes through JSON primitives" do
      assert TermSanitizer.sanitize(123) == 123
      assert TermSanitizer.sanitize(12.34) == 12.34
      assert TermSanitizer.sanitize(true) == true
      assert TermSanitizer.sanitize(false) == false
      assert TermSanitizer.sanitize(nil) == nil
      assert TermSanitizer.sanitize(:atom) == :atom
    end

    test "sanitizes strings and escapes special characters" do
      assert TermSanitizer.sanitize("hello") == "hello"
      assert TermSanitizer.sanitize("line\nbreak") == "line\\nbreak"
      assert TermSanitizer.sanitize("tab\tcharacter") == "tab\\tcharacter"
      assert TermSanitizer.sanitize("carriage\rreturn") == "carriage\\rreturn"
      assert TermSanitizer.sanitize("back\\slash") == "back\\\\slash"
    end

    test "handles invalid unicode binaries by inspecting them" do
      binary = <<255, 255>>
      assert TermSanitizer.sanitize(binary) == inspect(binary)
    end

    test "sanitizes lists recursively" do
      assert TermSanitizer.sanitize([1, "a", :b]) == [1, "a", :b]
      assert TermSanitizer.sanitize([[1], [2]]) == [[1], [2]]
    end

    test "converts tuples to lists and sanitizes elements" do
      assert TermSanitizer.sanitize({1, 2}) == [1, 2]
      assert TermSanitizer.sanitize({:ok, "value"}) == [:ok, "value"]
      assert TermSanitizer.sanitize({{1}, {2}}) == [[1], [2]]
    end

    test "sanitizes maps and handles keys" do
      assert TermSanitizer.sanitize(%{a: 1}) == %{a: 1}
      assert TermSanitizer.sanitize(%{"b" => 2}) == %{"b" => 2}

      # Non-string/atom keys are inspected
      assert TermSanitizer.sanitize(%{123 => "value"}) == %{"123" => "value"}
      assert TermSanitizer.sanitize(%{{1, 2} => "tuple_key"}) == %{"{1, 2}" => "tuple_key"}
    end

    test "handles structs by converting to map and stringifying __struct__" do
      date = ~D[2023-01-01]
      sanitized = TermSanitizer.sanitize(date)

      assert is_map(sanitized)
      assert sanitized["__struct__"] == "Date"
      assert sanitized[:year] == 2023
      assert sanitized[:month] == 1
      assert sanitized[:day] == 1
    end

    test "inspects opaque types" do
      pid = self()
      ref = make_ref()
      fun = fn -> :ok end

      assert TermSanitizer.sanitize(pid) == inspect(pid)
      assert TermSanitizer.sanitize(ref) == inspect(ref)
      assert TermSanitizer.sanitize(fun) == inspect(fun)
    end

    test "handles deeply nested complex structures" do
      complex = %{
        user: %{
          id: 1,
          name: "Test",
          meta: {1, 2}
        },
        items: [
          %URI{scheme: "http", host: "example.com"},
          self()
        ]
      }

      sanitized = TermSanitizer.sanitize(complex)

      assert sanitized[:user][:id] == 1
      assert sanitized[:user][:meta] == [1, 2]

      [uri, pid_str] = sanitized[:items]
      assert uri["__struct__"] == "URI"
      assert uri[:host] == "example.com"
      assert pid_str == inspect(self())
    end
  end
end
