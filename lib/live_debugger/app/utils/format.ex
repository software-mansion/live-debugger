defmodule LiveDebugger.App.Utils.Format do
  @moduledoc """
  Formatting functionalities to transform elements into expected format.
  """

  @doc """
  Change kebab case string to sentence.
  """
  @spec kebab_to_text(text :: String.t()) :: String.t()
  def kebab_to_text(text) do
    text
    |> String.capitalize()
    |> String.replace("-", " ")
  end
end
