defmodule LiveDebugger.App.Debugger.Utils.EditorTest do
  use ExUnit.Case, async: false

  alias LiveDebugger.App.Debugger.Utils.Editor

  describe "creates correct editor command" do
    test "uses ELIXIR_EDITOR when set" do
      with_env(%{"ELIXIR_EDITOR" => "code -g", "EDITOR" => "zed"}, fn ->
        editor = Editor.detect_editor()

        assert Editor.get_editor_cmd(editor, "lib/app.ex", 15) ==
                 ~s(code -g "lib/app.ex":15)
      end)
    end

    test "falls back to EDITOR when ELIXIR_EDITOR and TERM_PROGRAM is missing" do
      with_env(%{"ELIXIR_EDITOR" => nil, "TERM_PROGRAM" => nil, "EDITOR" => "vim"}, fn ->
        editor = Editor.detect_editor()

        assert Editor.get_editor_cmd(editor, "lib/app.ex", 15) ==
                 ~s(vim "lib/app.ex":15)
      end)
    end

    test "detects VS Code via TERM_PROGRAM when envs are nil" do
      with_env(
        %{
          "ELIXIR_EDITOR" => nil,
          "EDITOR" => nil,
          "TERM_PROGRAM" => "vscode"
        },
        fn ->
          editor = Editor.detect_editor()

          assert Editor.get_editor_cmd(editor, "lib/app.ex", 15) ==
                   ~s(code -g "lib/app.ex":15)
        end
      )
    end
  end

  test "replaces __FILE__ and __LINE__ correctly" do
    complex_cmd = "idea --open __FILE__ --line __LINE__ --wait"

    with_env(%{"ELIXIR_EDITOR" => complex_cmd}, fn ->
      editor = Editor.detect_editor()
      result = Editor.get_editor_cmd(editor, "my file.ex", 50)

      assert result == ~s(idea --open "my file.ex" --line 50 --wait)
    end)
  end

  # Sets envs only for the duration of the test
  defp with_env(env_map, fun) do
    original_state = Map.new(env_map, fn {k, _} -> {k, System.get_env(k)} end)

    System.put_env(env_map)

    try do
      fun.()
    after
      Enum.each(original_state, fn
        {k, nil} -> System.delete_env(k)
        {k, val} -> System.put_env(k, val)
      end)
    end
  end
end
