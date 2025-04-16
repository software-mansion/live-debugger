defmodule LiveDebugger.Feature do
  @moduledoc """
  Feature flags for LiveDebugger. If you create a new feature, you need to add it to the @experimental_features list.
  This way we can easily find all the features that are experimental and not ready for production.
  """

  @experimental_features [
    :dark_mode,
    :highlighting,
    :callback_filters
  ]

  def enabled?(feature_name) when feature_name in @experimental_features do
    case Application.get_env(:live_debugger, :experimental_features?, false) do
      :all -> true
      features when is_list(features) -> Enum.member?(features, feature_name)
      _ -> false
    end
  end

  def enabled?(feature_name) do
    raise "Feature #{feature_name} is not allowed"
  end
end
