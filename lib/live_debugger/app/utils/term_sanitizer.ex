defmodule LiveDebugger.App.Utils.TermSanitizer do
  @moduledoc """
  Prepares Elixir terms for JSON encoding by converting non-serializable
  types (Tuples, PIDs, Fns) into inspect-strings or lists.
  """

  @spec sanitize(term()) :: term()
  def sanitize(term) when is_map(term) do
    map =
      if Map.has_key?(term, :__struct__) do
        Map.from_struct(term) |> Map.put("__struct__", inspect(term.__struct__))
      else
        term
      end

    Map.new(map, fn {k, v} ->
      {sanitize_key(k), sanitize(v)}
    end)
  end

  def sanitize(term) when is_list(term) do
    Enum.map(term, &sanitize/1)
  end

  def sanitize(term) when is_tuple(term) do
    term
    |> Tuple.to_list()
    |> Enum.map(&sanitize/1)
  end

  def sanitize(term)
      when is_pid(term) or is_port(term) or is_reference(term) or is_function(term) do
    inspect(term)
  end

  def sanitize(term) when is_binary(term) do
    if String.valid?(term) do
      term
      |> String.replace("\\", "\\\\")
      |> String.replace("\n", "\\n")
      |> String.replace("\r", "\\r")
      |> String.replace("\t", "\\t")
    else
      # Fallback for raw binaries/images
      inspect(term, limit: :infinity)
    end
  end

  # Pass-through for valid JSON primitives
  def sanitize(term) when is_number(term) or is_boolean(term) or is_nil(term) or is_atom(term),
    do: term

  # --------------------------------------------------------------------------
  # Key Handling
  # JSON keys must be strings. Maps in Elixir can have any term as a key.
  # --------------------------------------------------------------------------
  defp sanitize_key(key) when is_binary(key), do: key
  defp sanitize_key(key) when is_atom(key), do: key
  defp sanitize_key(key), do: inspect(key, limit: :infinity)
end
