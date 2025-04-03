defmodule LiveDebugger.Test.Mocks do
  @moduledoc """
  Utitlity module for enabling and disabling mocks for testing
  """

  def set_mocks(_context) do
    Application.put_env(:live_debugger, :module_service, LiveDebugger.MockModuleService)
    Application.put_env(:live_debugger, :process_service, LiveDebugger.MockProcessService)
    :ok
  end

  def unset_mocks(_context) do
    Application.delete_env(
      :live_debugger,
      :module_service
    )

    Application.delete_env(
      :live_debugger,
      :process_service
    )

    :ok
  end
end
