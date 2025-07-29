defmodule LiveDebuggerRefactor.App.Web.Helpers.HooksTest do
  use ExUnit.Case, async: true

  alias LiveDebuggerRefactor.App.Web.Helpers.Hooks
  alias LiveDebuggerRefactor.Fakes

  describe "check_assigns!/1" do
    test "returns the socket if the assign is found" do
      socket = Fakes.socket(assigns: %{hook: :value})

      assert Hooks.check_assigns!(socket, :hook) == socket
    end

    test "raises an error if the assign is not found" do
      socket = Fakes.socket()

      assert_raise RuntimeError, fn ->
        Hooks.check_assigns!(socket, :not_found)
      end
    end

    test "works for list of keys" do
      socket = Fakes.socket(assigns: %{hook1: :value, hook2: :value2})

      assert Hooks.check_assigns!(socket, [:hook1, :hook2]) == socket
    end

    test "raises an error if any assign is not found in the list" do
      socket = Fakes.socket(assigns: %{hook1: :value})

      assert_raise RuntimeError, fn ->
        Hooks.check_assigns!(socket, [:hook1, :hook2])
      end
    end
  end

  describe "check_stream!/1" do
    test "returns the socket if the stream is found" do
      socket = Fakes.socket(assigns: %{streams: %{hook: :value}})

      assert Hooks.check_stream!(socket, :hook) == socket
    end

    test "raises an error if the stream is not found" do
      socket = Fakes.socket()

      assert_raise RuntimeError, fn ->
        Hooks.check_stream!(socket, :not_found)
      end
    end
  end

  describe "check_hook!/1" do
    test "returns the socket if the hook is found" do
      socket = Fakes.socket(private: %{hooks: [:hook]})

      assert Hooks.check_hook!(socket, :hook) == socket
    end

    test "raises an error if the hook is not found" do
      socket = Fakes.socket()

      assert_raise RuntimeError, fn ->
        Hooks.check_hook!(socket, :not_found)
      end
    end
  end

  describe "register_hook/2" do
    test "adds the hook to the socket" do
      final_socket = Fakes.socket(private: %{hooks: [:hook]})

      socket1 = Fakes.socket(private: %{hooks: []})

      assert Hooks.register_hook(socket1, :hook) == final_socket

      socket2 = Fakes.socket(private: %{})

      assert Hooks.register_hook(socket2, :hook) == final_socket
    end

    test "raises an error if the hook is already registered" do
      socket = Fakes.socket(private: %{hooks: [:hook]})

      assert_raise RuntimeError, fn ->
        Hooks.register_hook(socket, :hook)
      end
    end
  end
end
