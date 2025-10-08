defmodule BanditByteCounts do
  @moduledoc "Logs request/response byte counts (and WS frame bytes) from Bandit telemetry"
  require Logger

  def attach! do
    # Detach safely if already attached
    try do
      :telemetry.detach("bandit-byte-counts")
    rescue
      _ -> :ok
    end

    :telemetry.attach_many(
      "bandit-byte-counts",
      [
        [:bandit, :request, :stop],
        [:bandit, :request, :exception],
        [:bandit, :websocket, :stop]
      ],
      &__MODULE__.handle/4,
      nil
    )
  end

  def handle([:bandit, :request, :stop], meas, meta, _cfg) do
    req = Map.get(meas, :req_body_bytes, 0)
    resp = Map.get(meas, :resp_body_bytes, 0)
    resp_uncompressed = Map.get(meas, :resp_uncompressed_body_bytes)
    compression = Map.get(meas, :resp_compression_method)

    duration_us =
      meas
      |> Map.get(:duration, 0)
      |> System.convert_time_unit(:native, :microsecond)

    Logger.info(fn ->
      parts = [
        "HTTP #{meta.conn.method} #{meta.conn.request_path}",
        "req=#{req}B",
        "resp=#{resp}B",
        resp_uncompressed && "resp_uncompressed=#{resp_uncompressed}B",
        compression && "compression=#{compression}",
        "duration=#{duration_us}µs"
      ]

      Enum.reject(parts, &is_nil/1) |> Enum.join(" | ")
    end)
  end

  def handle([:bandit, :request, :exception], meas, meta, _cfg) do
    duration_us =
      meas
      |> Map.get(:duration, 0)
      |> System.convert_time_unit(:native, :microsecond)

    Logger.warning(
      "HTTP exception #{meta.conn.method} #{meta.conn.request_path} in #{duration_us}µs"
    )
  end

  def handle([:bandit, :websocket, :stop], meas, meta, _cfg) do
    dbg(meta)
    rtxt = Map.get(meas, :recv_text_frame_bytes, 0)
    rbin = Map.get(meas, :recv_binary_frame_bytes, 0)
    stxt = Map.get(meas, :send_text_frame_bytes, 0)
    sbin = Map.get(meas, :send_binary_frame_bytes, 0)

    Logger.info(
      "WS #{inspect(meta.websock)} | recv_text=#{rtxt}B recv_bin=#{rbin}B | send_text=#{stxt}B send_bin=#{sbin}B"
    )
  end

  def handle(_event, _meas, _meta, _cfg), do: :ok
end
