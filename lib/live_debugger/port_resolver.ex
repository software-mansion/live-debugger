defmodule LiveDebugger.PortResolver do
  @moduledoc """
  Resolves the port for the LiveDebugger endpoint.

  When `auto_port: true` is configured, scans upward from the configured port
  to find an available one (up to `@max_attempts` tries). Skipped for non-TCP
  IP configurations (e.g. Unix sockets).
  """

  require Logger

  @max_attempts 3

  @spec resolve(ip :: term(), port :: term(), auto_port? :: boolean()) :: term()
  def resolve(ip, port, auto_port?) do
    if auto_port? and tcp_ip?(ip) and is_integer(port) and port > 0 do
      find_available_port(ip, port, @max_attempts)
    else
      port
    end
  end

  defp tcp_ip?({_, _, _, _}), do: true
  defp tcp_ip?({_, _, _, _, _, _, _, _}), do: true
  defp tcp_ip?(_), do: false

  defp find_available_port(_ip, port, 0) do
    Logger.warning(
      "LiveDebugger: could not find an available port after #{@max_attempts} attempts, " <>
        "using port #{port}"
    )

    port
  end

  defp find_available_port(ip, port, attempts_left) do
    inet_family = if tuple_size(ip) == 4, do: :inet, else: :inet6

    case :gen_tcp.listen(port, [inet_family, {:ip, ip}]) do
      {:ok, socket} ->
        :gen_tcp.close(socket)
        port

      {:error, :eaddrinuse} ->
        Logger.warning("LiveDebugger: port #{port} is already in use, trying #{port + 1}")
        find_available_port(ip, port + 1, attempts_left - 1)

      {:error, _} ->
        port
    end
  end
end
