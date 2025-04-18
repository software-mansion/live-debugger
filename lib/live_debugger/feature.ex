defmodule LiveDebugger.Feature do
  @moduledoc """
  Feature flags for LiveDebugger.
  If you create a new feature, create a new function here with defined rules for enabling it.
  """

  def enabled?(:highlighting) do
    experimental_feature_enabled?(:highlighting) and
      Application.get_env(:live_debugger, :browser_features?, true) and
      Application.get_env(:live_debugger, :highlighting?, true)
  end

  def enabled?(:dark_mode) do
    experimental_feature_enabled?(:dark_mode)
  end

  def enabled?(:callback_filters) do
    experimental_feature_enabled?(:callback_filters)
  end

  def enabled?(feature_name) do
    raise "Feature #{feature_name} is not allowed"
  end

  defp experimental_feature_enabled?(feature_name) do
    case Application.get_env(:live_debugger, :experimental_features, false) do
      :all -> true
      features when is_list(features) -> Enum.member?(features, feature_name)
      _ -> false
    end
  end
end
