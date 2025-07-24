defmodule LiveDebuggerRefactor.App.Utils.UrlTest do
  use ExUnit.Case, async: true

  alias LiveDebuggerRefactor.App.Utils.URL

  describe "to_relative/1" do
    test "converts absolute URL to relative URL" do
      assert URL.to_relative("http://example.com/foo?bar=baz") == "/foo?bar=baz"
    end

    test "handles URLs without query parameters" do
      assert URL.to_relative("http://example.com/foo") == "/foo"
    end

    test "handles URLs with only query parameters" do
      assert URL.to_relative("http://example.com?bar=baz") == "?bar=baz"
    end
  end
end
