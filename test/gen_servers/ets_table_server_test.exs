defmodule LiveDebugger.GenServers.EtsTableServerTest do
  @moduledoc false
  use ExUnit.Case, async: true

  alias LiveDebugger.Utils.PubSub, as: PubSubUtils
  alias LiveDebugger.GenServers.EtsTableServer

  test "start_link/1" do
    assert {:ok, _pid} = EtsTableServer.start_link()
    GenServer.stop(EtsTableServer)
  end

  test "init/1" do
    assert {:ok, %{}} = EtsTableServer.init([])
  end

  describe "gen server api" do
    test "table!/1" do
      pid = :c.pid(0, 0, 1)

      LiveDebugger.MockEtsTableServer
      |> Mox.expect(:table!, fn ^pid -> :some_ref end)

      assert :some_ref = EtsTableServer.table!(pid)
    end

    test "delete_table!/1" do
      pid = :c.pid(0, 0, 1)

      LiveDebugger.MockEtsTableServer
      |> Mox.expect(:delete_table!, fn ^pid -> :ok end)

      assert :ok = EtsTableServer.delete_table!(pid)
    end
  end

  describe "handle_info/2" do
    test "deletes table ref after process down" do
      pid = :c.pid(0, 0, 1)
      ref = :ets.new(:test_table, [])

      other_pid = :c.pid(0, 0, 2)
      other_ref = :ets.new(:test_table, [])

      table_refs = %{pid => ref, other_pid => other_ref}

      topic = PubSubUtils.process_status_topic(pid)

      LiveDebugger.MockPubSubUtils
      |> Mox.expect(:broadcast, fn ^topic, {:process_status, :dead} -> :ok end)

      assert {:noreply, new_table_refs} =
               EtsTableServer.handle_info({:DOWN, :_, :process, pid, :_}, table_refs)

      assert :undefined == :ets.info(ref)
      assert nil == Map.get(new_table_refs, pid)

      assert [{:id, ^other_ref} | _] = :ets.info(other_ref)
      assert other_ref == Map.get(new_table_refs, other_pid)
    end
  end

  describe "handle_call/3" do
    test "deletes table on event {:delete_table, pid}" do
      pid = :c.pid(0, 0, 1)
      ref = :ets.new(:test_table, [])

      other_pid = :c.pid(0, 0, 2)
      other_ref = :ets.new(:test_table, [])

      table_refs = %{pid => ref, other_pid => other_ref}

      assert {:reply, :ok, new_table_refs} =
               EtsTableServer.handle_call({:delete_table, pid}, self(), table_refs)

      assert :undefined == :ets.info(ref)
      assert nil == Map.get(new_table_refs, pid)

      assert [{:id, ^other_ref} | _] = :ets.info(other_ref)
      assert other_ref == Map.get(new_table_refs, other_pid)
    end

    test "ignores delete table on event {:delete_table, pid} when table does not exist" do
      pid = :c.pid(0, 0, 1)
      ref = :ets.new(:test_table, [])

      other_pid = :c.pid(0, 0, 2)

      table_refs = %{pid => ref}

      assert {:reply, :ok, new_table_refs} =
               EtsTableServer.handle_call({:delete_table, other_pid}, self(), table_refs)

      assert [{:id, ^ref} | _] = :ets.info(ref)
      assert ref == Map.get(new_table_refs, pid)

      assert nil == Map.get(new_table_refs, other_pid)
    end

    test "creates table on event {:get_or_create_table, pid}" do
      pid = :c.pid(0, 0, 1)
      table_refs = %{}

      assert {:reply, ref, new_table_refs} =
               EtsTableServer.handle_call({:get_or_create_table, pid}, self(), table_refs)

      assert [{:id, ^ref} | _] = :ets.info(ref)
      assert ref == Map.get(new_table_refs, pid)
    end

    test "returns existing table on event {:get_or_create_table, pid}" do
      pid = :c.pid(0, 0, 1)
      ref = :ets.new(:test_table, [])
      table_refs = %{pid => ref}

      assert {:reply, ^ref, new_table_refs} =
               EtsTableServer.handle_call({:get_or_create_table, pid}, self(), table_refs)

      assert ref == Map.get(new_table_refs, pid)
    end
  end
end
