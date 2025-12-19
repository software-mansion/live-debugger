defmodule LiveDebugger.App.Debugger.Actions.UserEventsTest do
  use ExUnit.Case, async: true

  import Mox

  alias LiveDebugger.App.Debugger.Actions.UserEvents, as: UserEventsActions
  alias LiveDebugger.MockAPIUserEvents
  alias LiveDebugger.Fakes
  alias Phoenix.LiveComponent.CID

  setup :verify_on_exit!

  describe "send/3" do
    test "sends LiveView event via handle_event/3" do
      lv_process = Fakes.lv_process()

      params = %{
        "handler" => "handle_event/3",
        "event" => "click",
        "payload" => ~s(%{key: "value"})
      }

      MockAPIUserEvents
      |> expect(:send_lv_event, fn ^lv_process, nil, "click", %{key: "value"} -> :ok end)

      assert {:ok, _} = UserEventsActions.send(params, lv_process, lv_process.pid)
    end

    test "sends LiveView event to LiveComponent when node_id is CID" do
      lv_process = Fakes.lv_process()
      cid = %CID{cid: 1}
      params = %{"handler" => "handle_event/3", "event" => "submit", "payload" => "%{}"}

      MockAPIUserEvents
      |> expect(:send_lv_event, fn ^lv_process, ^cid, "submit", %{} -> :ok end)

      assert {:ok, _} = UserEventsActions.send(params, lv_process, cid)
    end

    test "defaults empty payload to empty map for handle_event/3" do
      lv_process = Fakes.lv_process()
      params = %{"handler" => "handle_event/3", "event" => "click", "payload" => ""}

      MockAPIUserEvents
      |> expect(:send_lv_event, fn ^lv_process, nil, "click", %{} -> :ok end)

      assert {:ok, _} = UserEventsActions.send(params, lv_process, lv_process.pid)
    end

    test "returns error when event is empty for handle_event/3" do
      lv_process = Fakes.lv_process()
      params = %{"handler" => "handle_event/3", "event" => "", "payload" => "%{}"}

      assert {:error, "Event cannot be empty"} =
               UserEventsActions.send(params, lv_process, lv_process.pid)
    end

    test "sends info message via handle_info/2" do
      lv_process = Fakes.lv_process()
      params = %{"handler" => "handle_info/2", "payload" => ~s({:my_message, "data"})}

      MockAPIUserEvents
      |> expect(:send_info_message, fn ^lv_process, {:my_message, "data"} ->
        {:my_message, "data"}
      end)

      assert {:ok, _} =
               UserEventsActions.send(params, lv_process, lv_process.pid)
    end

    test "sends GenServer cast via handle_cast/2" do
      lv_process = Fakes.lv_process()
      params = %{"handler" => "handle_cast/2", "payload" => ":my_cast"}

      MockAPIUserEvents
      |> expect(:send_genserver_cast, fn ^lv_process, :my_cast -> :ok end)

      assert {:ok, _} = UserEventsActions.send(params, lv_process, lv_process.pid)
    end

    test "sends GenServer call via handle_call/3" do
      lv_process = Fakes.lv_process()
      params = %{"handler" => "handle_call/3", "payload" => ":get_state"}

      MockAPIUserEvents
      |> expect(:send_genserver_call, fn ^lv_process, :get_state -> {:ok, %{}} end)

      assert {:ok, _} = UserEventsActions.send(params, lv_process, lv_process.pid)
    end

    test "sends component update via update/2" do
      lv_process = Fakes.lv_process()
      cid = %CID{cid: 1}
      params = %{"handler" => "update/2", "payload" => ~s(%{new_assign: "value"})}

      MockAPIUserEvents
      |> expect(:send_component_update, fn ^lv_process, ^cid, %{new_assign: "value"} -> :ok end)

      assert {:ok, _} = UserEventsActions.send(params, lv_process, cid)
    end

    test "returns error when payload is empty for non-event handlers" do
      lv_process = Fakes.lv_process()
      params = %{"handler" => "handle_info/2", "payload" => ""}

      assert {:error, "Payload cannot be empty"} =
               UserEventsActions.send(params, lv_process, lv_process.pid)
    end

    test "returns error when payload has syntax error" do
      lv_process = Fakes.lv_process()
      params = %{"handler" => "handle_info/2", "payload" => "%{invalid"}

      assert {:error, "Syntax error:" <> _} =
               UserEventsActions.send(params, lv_process, lv_process.pid)
    end
  end

  describe "parse_elixir_term/1" do
    test "parses various Elixir terms" do
      assert {:ok, %{}} = UserEventsActions.parse_elixir_term("%{}")
      assert {:ok, %{key: "value"}} = UserEventsActions.parse_elixir_term(~s(%{key: "value"}))
      assert {:ok, {:ok, "data"}} = UserEventsActions.parse_elixir_term(~s({:ok, "data"}))
      assert {:ok, [1, 2, 3]} = UserEventsActions.parse_elixir_term("[1, 2, 3]")
      assert {:ok, :my_atom} = UserEventsActions.parse_elixir_term(":my_atom")
    end

    test "returns error for invalid input" do
      assert {:error, "Payload cannot be empty"} = UserEventsActions.parse_elixir_term("")
      assert {:error, "Syntax error:" <> _} = UserEventsActions.parse_elixir_term("%{invalid")

      assert {:error, "Evaluation error:" <> _} =
               UserEventsActions.parse_elixir_term("undefined_var")
    end
  end
end
