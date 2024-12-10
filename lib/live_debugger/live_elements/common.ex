defmodule LiveDebugger.LiveElements.Common do
  @moduledoc """
  Common functions for LiveElements
  """

  @forbidden_assigns_keys ~w(__changed__ live_debug live_action)a

  def filter_assigns(assigns) do
    assigns
    |> Map.to_list()
    |> Enum.reject(fn {key, _} -> key in @forbidden_assigns_keys end)
    |> Enum.into(%{})
  end
end
