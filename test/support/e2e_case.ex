defmodule LiveDebugger.E2ECase do
  @moduledoc """
  This module defines the test case to be used by end-to-end tests.
  """
  use ExUnit.CaseTemplate

  using do
    quote do
      use Wallaby.Feature

      import Wallaby.Query
      import LiveDebugger.Support.CssQueries
      import Mox

      @moduletag :e2e

      @dev_app_url Application.compile_env(:live_debugger, :dev_app_url, "")

      setup :set_mox_from_context

      setup do
        LiveDebugger.MockIframeCheck
        |> stub(:on_mount, fn _, _, _, socket ->
          {:cont, Phoenix.Component.assign(socket, :in_iframe?, false)}
        end)

        :ok
      end
    end
  end
end
