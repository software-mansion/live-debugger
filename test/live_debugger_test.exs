defmodule LiveDebuggerTest do
  @moduledoc false

  use ExUnit.Case, async: false

  import Mox

  setup :verify_on_exit!

  setup do
    on_exit(fn ->
      Application.delete_env(:live_debugger, :ip)
      Application.delete_env(:live_debugger, :port)
      Application.delete_env(:live_debugger, :external_url)
      Application.delete_env(:live_debugger, :live_debugger_tags)
    end)
  end

  describe "update_live_debugger_tags/0" do
    test "generates tags for standard IP tuple" do
      Application.put_env(:live_debugger, :ip, {127, 0, 0, 1})
      Application.put_env(:live_debugger, :port, 4007)

      LiveDebugger.MockAPISettingsStorage
      |> expect(:get, fn :debug_button -> true end)

      LiveDebugger.update_live_debugger_tags()

      tags = Application.get_env(:live_debugger, :live_debugger_tags)
      refute is_nil(tags)
      refute tags == []
    end

    test "does not crash with Unix socket IP and sets empty tags" do
      Application.put_env(:live_debugger, :ip, {:local, "/tmp/live_debugger.sock"})
      Application.put_env(:live_debugger, :port, 0)

      LiveDebugger.update_live_debugger_tags()

      tags = Application.get_env(:live_debugger, :live_debugger_tags)
      assert tags == []
    end

    test "generates tags when Unix socket IP is used with external_url" do
      Application.put_env(:live_debugger, :ip, {:local, "/tmp/live_debugger.sock"})
      Application.put_env(:live_debugger, :port, 0)
      Application.put_env(:live_debugger, :external_url, "https://debugger-myapp.example.com")

      LiveDebugger.MockAPISettingsStorage
      |> expect(:get, fn :debug_button -> true end)

      LiveDebugger.update_live_debugger_tags()

      tags = Application.get_env(:live_debugger, :live_debugger_tags)
      refute is_nil(tags)
      refute tags == []
    end
  end
end
