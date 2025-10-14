defmodule LiveDebugger.Services.CallbackTracer.Actions.LvDiff do
  @moduledoc """
  This module provides actions for LiveView diffs.
  """

  alias LiveDebugger.Structs.LvDiff

  @doc """
  Creates a non-empty diff from raw diff trace. If diff is empty, returns nil.
  """
  @spec maybe_create_diff(non_neg_integer(), pid(), non_neg_integer(), iodata()) ::
          {:ok, LvDiff.t() | nil} | {:error, term()}
  def maybe_create_diff(n, pid, timestamp, iodata) do
    body_binary = IO.iodata_to_binary(iodata)
    body_size = byte_size(body_binary)

    with {:ok, message_json} <- Jason.decode(body_binary),
         diff when not is_nil(diff) <- get_diff(message_json) do
      {:ok, LvDiff.new(n, diff, pid, timestamp, body_size)}
    else
      nil -> {:ok, nil}
      error -> error
    end
  end

  defp get_diff([_, _, _, "diff", payload]), do: payload
  defp get_diff([_, _, _, _type, %{"response" => %{"diff" => diff}}]), do: diff
  defp get_diff(_), do: nil
end
