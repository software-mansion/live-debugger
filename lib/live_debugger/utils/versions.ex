defmodule LiveDebugger.Utils.Versions do
  @moduledoc """
  This module is responsible for checking `:phoenix_live_view` version in terms of certain
  features that were introduced to maintain compatibility across different versions.
  """

  @live_view_vsn Application.spec(:phoenix_live_view, :vsn) |> to_string()

  def live_component_destroyed_telemetry_supported?() do
    # [:phoenix, :live_component, :destroyed] telemetry event was added in 1.1.0
    Version.match?(@live_view_vsn, ">= 1.1.0-rc.0")
  end

  def live_view_streams_order_changed?() do
    # ordering of stream inserts changed in 1.0.2
    Version.match?(@live_view_vsn, ">= 1.0.2")
  end
end
