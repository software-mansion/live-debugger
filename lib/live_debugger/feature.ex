defmodule LiveDebugger.Feature do
  @moduledoc """
  Feature flags for LiveDebugger.
  If you create a new feature that can be enabled or disabled, create a new function here with defined rules for enabling it.
  """

  def enabled?(:garbage_collection) do
    Application.get_env(:live_debugger, :garbage_collection?, true)
  end

  def enabled?(:highlighting) do
    Application.get_env(:live_debugger, :browser_features?, true) and
      Application.get_env(:live_debugger, :highlighting?, true)
  end

  def enabled?(feature_name) do
    raise "Feature #{feature_name} is not allowed"
  end
end
