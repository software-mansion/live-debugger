defmodule LiveDebugger.App.Debugger.CallbackTracing.ComponentId do
  @moduledoc """
  Codec for component IDs used in callback tracing filters.

  Component IDs (pid, `Phoenix.LiveComponent.CID`, or `:all`) are encoded
  as Base64 Erlang-term strings so they can be used as HTML form field names
  and stored in filter maps.
  """

  @type component_id :: pid() | Phoenix.LiveComponent.CID.t() | :all

  @doc """
  Encodes a component ID to a Base64 string.
  """
  @spec encode(component_id()) :: binary()
  def encode(id), do: id |> :erlang.term_to_binary() |> Base.encode64()

  @doc """
  Returns the encoded sentinel value representing all components.
  """
  @spec all() :: binary()
  def all, do: encode(:all)

  @doc """
  Decodes a list of encoded component IDs.
  Returns `:all` if the `:all` sentinel is present, otherwise returns the decoded list.
  """
  @spec decode_list([binary()]) :: :all | [pid() | Phoenix.LiveComponent.CID.t()]
  def decode_list(encoded_components) do
    decoded =
      Enum.flat_map(encoded_components, fn encoded ->
        case Base.decode64(encoded) do
          {:ok, binary} -> [:erlang.binary_to_term(binary)]
          _ -> []
        end
      end)

    if :all in decoded, do: :all, else: decoded
  end
end
