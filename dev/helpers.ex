defmodule LiveDebuggerDev.Helpers do
  @moduledoc false

  def very_long_assigns_map() do
    %{
      a: 1,
      b: 2,
      c: "some value",
      d: %{nested: "value"},
      e: [1, 2, 3],
      f: [a: 1, b: 2],
      g: [a: 1, b: 2, c: [1, 2, 3]],
      h: [a: 1, b: 2, c: [a: 1, b: 2]],
      i: :some_atom,
      j: 78,
      k: "Text",
      l: 12,
      m: 34,
      n: 56,
      o: "Some Long value which should be split to multiple lines.",
      p: 213,
      q: :abf,
      r: :other_atom,
      s: :fgh,
      t: :ijk,
      u: :lmn,
      v: :very_long_atom_with_multiple_words_xxxxx_xxxxxxx_xxxxxxxxxxxxx,
      w: :short_atom,
      x: :short,
      y: "Last long value of string with example text to be shown on the propoer component"
    }
  end
end
