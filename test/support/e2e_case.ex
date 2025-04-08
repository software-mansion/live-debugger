defmodule LiveDebugger.E2ECase do
  use ExUnit.CaseTemplate

  using do
    quote do
      use Wallaby.Feature

      import Wallaby.Query

      @moduletag :e2e

      @dev_app_url LiveDebuggerDev.Endpoint.url()
    end
  end
end
