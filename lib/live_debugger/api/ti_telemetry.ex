defmodule TIWiretap do
  def attach! do
    :telemetry.attach_many(
      "ti-wiretap",
      [
        [:thousand_island, :connection, :async_recv],
        [:thousand_island, :connection, :recv],
        [:thousand_island, :connection, :send]
      ],
      &__MODULE__.handle_event/4,
      nil
    )
  end

  def handle_event(event, measurements, meta, config) do
    dbg(event)
    dbg(measurements)
    dbg(meta)
    dbg(config)

    case event do
      [:thousand_island, :connection, :send] ->
        IO.puts("SEND")

      # dbg(measurements.data)

      [:thousand_island, :connection, :recv] ->
        IO.puts("RECV(sync)")

      # dbg(measurements.data)

      [:thousand_island, :connection, :async_recv] ->
        IO.puts("RECV(async)")
        # dbg(measurements.data)
    end
  end
end
