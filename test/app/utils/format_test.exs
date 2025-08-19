defmodule LiveDebugger.App.Utils.FormatTest do
  use ExUnit.Case, async: true

  alias LiveDebugger.App.Utils.Format

  test "kebab_to_text/1 converts kebab case to sentence" do
    assert Format.kebab_to_text("hello-world") == "Hello world"
    assert Format.kebab_to_text("oneword") == "Oneword"
  end
end
