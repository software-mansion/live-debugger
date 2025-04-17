defmodule LiveDebugger.E2ECase do
  @moduledoc """
  This module defines the test case to be used by end-to-end tests.
  """
  use ExUnit.CaseTemplate

  using do
    quote do
      use Wallaby.Feature

      import Wallaby.Query

      @moduletag :e2e

      @dev_app_url Application.compile_env(:live_debugger, :dev_app_url, "")
    end
  end
end
