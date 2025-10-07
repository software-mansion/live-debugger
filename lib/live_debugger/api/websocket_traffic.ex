defmodule WS do
  use Bitwise

  # Dekoduje krótką, zamaskowaną ramkę tekstową (FIN=1, opcode=1, len<126)
  def decode(<<0x81, masked_len, rest::binary>>) when (masked_len &&& 0x80) == 0x80 do
    len = masked_len &&& 0x7F
    <<m1, m2, m3, m4, masked::binary-size(len)>> = rest
    mask = <<m1, m2, m3, m4>>

    data =
      masked
      |> :binary.bin_to_list()
      |> Enum.with_index()
      |> Enum.map(fn {byte, i} ->
        byte ^^^ :binary.at(mask, rem(i, 4))
      end)
      |> :binary.list_to_bin()

    data
  end
end
