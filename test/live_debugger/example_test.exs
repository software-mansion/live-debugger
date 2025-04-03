defmodule LiveDebugger.ExampleTest do
  use ExUnit.Case, async: true
  use Wallaby.Feature

  import Wallaby.Query
  import LiveDebugger.Test.Mocks

  setup :unset_mocks

  describe "Smoke" do
    feature "live debugger sessions page", %{session: session} do
      session
      |> visit("/")
      |> assert_has(css("h1", text: "Active LiveViews"))
    end
  end

  describe "basic functionality" do
    @sessions 3
    feature "active live view sessions can be seen in live debugger", %{sessions: [s1, s2, s3]} do
      s1
      |> visit("http://localhost:4005/")

      s2
      |> visit("http://localhost:4005/")

      s3
      |> visit("/")
      |> assert_has(css("#live-view-sessions > div", count: 2))
    end
  end
end
