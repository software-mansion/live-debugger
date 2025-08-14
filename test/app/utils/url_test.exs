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

  describe "update_path/2" do
    test "updates the path of a URL" do
      assert URL.update_path("http://example.com/foo?bar=baz", "/new_path") ==
               "http://example.com/new_path?bar=baz"
    end

    test "handles URLs without query parameters" do
      assert URL.update_path("http://example.com/foo", "/new_path") ==
               "http://example.com/new_path"
    end

    test "adds path when no path exists" do
      assert URL.update_path("http://example.com", "/new_path") ==
               "http://example.com/new_path"
    end
  end

  describe "upsert_query_param/3" do
    test "adds a query parameter in a URL" do
      assert URL.upsert_query_param("http://example.com/foo", "key", "value") ==
               "http://example.com/foo?key=value"
    end

    test "updates a query parameter in a URL with existing parameters" do
      assert URL.upsert_query_param("http://example.com/foo?key1=value1", "key2", "value2") ==
               "http://example.com/foo?key1=value1&key2=value2"
    end
  end

  describe "upsert_query_params/2" do
    test "adds multiple query parameters in a URL" do
      assert URL.upsert_query_params("http://example.com/foo", %{
               "key1" => "value1",
               "key2" => "value2"
             }) ==
               "http://example.com/foo?key1=value1&key2=value2"
    end

    test "updates existing query parameters in a URL" do
      assert URL.upsert_query_params("http://example.com/foo?key1=value1", %{
               "key2" => "value2",
               "key3" => "value3"
             }) ==
               "http://example.com/foo?key1=value1&key2=value2&key3=value3"
    end

    test "doesn't modify the URL if no parameters are provided" do
      assert URL.upsert_query_params("http://example.com/foo", %{}) ==
               "http://example.com/foo"
    end
  end

  describe "remove_query_param/2" do
    test "removes a query parameter from a URL" do
      assert URL.remove_query_param("http://example.com/foo?key=value", "key") ==
               "http://example.com/foo"
    end

    test "doesn't modify the URL if the parameter doesn't exist" do
      assert URL.remove_query_param("http://example.com/foo?key=value", "nonexistent") ==
               "http://example.com/foo?key=value"
    end
  end

  describe "remove_query_params/2" do
    test "removes multiple query parameters from a URL" do
      assert URL.remove_query_params("http://example.com/foo?key1=value1&key2=value2", [
               "key1",
               "key2"
             ]) ==
               "http://example.com/foo"
    end

    test "doesn't modify the URL if no parameters exist" do
      assert URL.remove_query_params("http://example.com/foo?key=value", ["nonexistent"]) ==
               "http://example.com/foo?key=value"
    end
  end

  describe "remove_query_params/1" do
    test "removes all query parameters from a URL" do
      assert URL.remove_query_params("http://example.com/foo?key1=value1&key2=value2") ==
               "http://example.com/foo"
    end
  end

  describe "take_nth_segment/2" do
    test "takes the nth segment of a URL" do
      assert URL.take_nth_segment("http://example.com/foo/bar/baz", 2) == "bar"
    end

    test "returns nil if the URL has no segments" do
      assert URL.take_nth_segment("http://example.com", 2) == nil
    end

    test "returns nil if the nth segment is out of bounds" do
      assert URL.take_nth_segment("http://example.com/foo/bar/baz", 4) == nil
    end

    test "returns the nth segment of a relative URL" do
      assert URL.take_nth_segment("/foo/bar/baz", 2) == "bar"
    end

    test "returns nil if the relative URL has no segments" do
      assert URL.take_nth_segment("/", 2) == nil
    end
  end

  describe "modify_query_params/2" do
    test "modifies query parameters in a URL using a function" do
      assert URL.modify_query_params("http://example.com/foo?key=value", fn params ->
               Map.put(params, "new_key", "new_value")
             end) == "http://example.com/foo?key=value&new_key=new_value"
    end
  end
end
