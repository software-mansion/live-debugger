defmodule LiveDebugger.PortResolverTest do
  use ExUnit.Case, async: false

  alias LiveDebugger.PortResolver

  @ip {127, 0, 0, 1}

  describe "resolve/3" do
    test "returns configured port when auto_port is false" do
      assert PortResolver.resolve(@ip, 4007, false) == 4007
    end

    test "returns same port when auto_port is true and port is free" do
      assert PortResolver.resolve(@ip, 39_871, true) == 39_871
    end

    test "finds next available port when configured port is occupied" do
      {:ok, socket} = :gen_tcp.listen(39_872, [:inet, {:ip, @ip}, {:reuseaddr, true}])

      resolved = PortResolver.resolve(@ip, 39_872, true)

      :gen_tcp.close(socket)

      assert resolved == 39_873
    end

    test "stops after max attempts and returns the next port" do
      sockets =
        for port <- 39_874..39_876 do
          {:ok, socket} = :gen_tcp.listen(port, [:inet, {:ip, @ip}, {:reuseaddr, true}])
          socket
        end

      resolved = PortResolver.resolve(@ip, 39_874, true)

      Enum.each(sockets, &:gen_tcp.close/1)

      # After 3 failed attempts (39874, 39875, 39876), returns 39877
      assert resolved == 39_877
    end

    test "skips auto_port for Unix socket IP" do
      assert PortResolver.resolve({:local, "/tmp/test.sock"}, 4007, true) == 4007
    end

    test "skips auto_port when port is not a positive integer" do
      assert PortResolver.resolve(@ip, 0, true) == 0
    end
  end
end
