defmodule LiveDebugger.GenServers.EtsTableServerTest do
  use ExUnit.Case, async: true

  import Mox

  alias LiveDebugger.Fakes
  alias LiveDebugger.Utils.PubSub, as: PubSubUtils
  alias LiveDebugger.GenServers.EtsTableServer

  setup :verify_on_exit!

  test "start_link/1" do
    assert {:ok, _pid} = EtsTableServer.start_link()
    GenServer.stop(EtsTableServer)
  end

  test "init/1" do
    assert {:ok, %{}} = EtsTableServer.init([])
  end

  describe "gen server api" do
    test "table/1" do
      pid = :c.pid(0, 0, 1)

      LiveDebugger.MockEtsTableServer
      |> expect(:table, fn ^pid -> :some_ref end)

      assert :some_ref = EtsTableServer.table(pid)
    end

    test "watch/1" do
      pid = :c.pid(0, 0, 1)

      LiveDebugger.MockEtsTableServer
      |> expect(:watch, fn ^pid -> :ok end)

      assert :ok = EtsTableServer.watch(pid)
    end
  end

  describe "handle_info/2 with `{:DOWN, _, :process, _, _}`" do
    test "`down`deletes table ref after process down and no watchers left" do
      pid = :c.pid(0, 0, 1)
      ref = :ets.new(:test_table, [])

      other_pid = :c.pid(0, 0, 2)
      other_ref = :ets.new(:test_table, [])

      table_refs = %{
        pid => %EtsTableServer.TableInfo{table: ref},
        other_pid => %EtsTableServer.TableInfo{table: other_ref}
      }

      topic = PubSubUtils.process_status_topic()

      LiveDebugger.MockPubSubUtils
      |> expect(:broadcast, fn ^topic, {:process_status, {:died, _}} -> :ok end)
      |> expect(:broadcast, fn ^topic, {:process_status, {:dead, _}} -> :ok end)

      assert {:noreply, new_table_refs} =
               EtsTableServer.handle_info({:DOWN, :_, :process, pid, :_}, table_refs)

      assert :undefined == :ets.info(ref)
      assert nil == Map.get(new_table_refs, pid)

      assert [{:id, ^other_ref} | _] = :ets.info(other_ref)
      assert other_ref == Map.get(new_table_refs, other_pid).table
    end

    test "removes watcher when it dies" do
      pid = :c.pid(0, 0, 1)
      watcher_pid = :c.pid(0, 0, 2)
      ref = :ets.new(:test_table, [])

      table_refs = %{
        pid => %EtsTableServer.TableInfo{table: ref, watchers: MapSet.new([watcher_pid])}
      }

      assert {:noreply, new_table_refs} =
               EtsTableServer.handle_info({:DOWN, :_, :process, watcher_pid, :_}, table_refs)

      assert MapSet.new([]) == Map.get(new_table_refs, pid).watchers
    end

    test "doesn't delete table if there are watchers left" do
      pid = :c.pid(0, 0, 1)
      watcher_pid = :c.pid(0, 0, 2)
      ref = :ets.new(:test_table, [])

      table_refs = %{
        pid => %EtsTableServer.TableInfo{table: ref, watchers: MapSet.new([watcher_pid])}
      }

      topic = PubSubUtils.process_status_topic()

      LiveDebugger.MockPubSubUtils
      |> expect(:broadcast, fn ^topic, {:process_status, {:died, _}} -> :ok end)

      assert {:noreply, new_table_refs} =
               EtsTableServer.handle_info({:DOWN, :_, :process, pid, :_}, table_refs)

      assert MapSet.new([watcher_pid]) == Map.get(new_table_refs, pid).watchers
    end
  end

  describe "handle_info/2 with `garbage_collect`" do
    test "deletes records if it has too many" do
      pid = :c.pid(0, 0, 1)
      ref = :ets.new(:test_table, [:ordered_set, :public])

      Enum.each(-1..-301//-3, fn id ->
        :ets.insert(ref, {id, Fakes.trace(id: id, pid: pid)})
      end)

      table_refs = %{pid => %EtsTableServer.TableInfo{table: ref}}

      assert {:noreply, _} = EtsTableServer.handle_info(:garbage_collect, table_refs)

      Process.sleep(100)

      assert 100 == :ets.select_count(ref, [{{:"$1", :"$2"}, [], [true]}])
    end

    test "does not trigger when not enough records are in table" do
      pid = :c.pid(0, 0, 1)
      ref = :ets.new(:test_table, [:ordered_set, :public])
      table_refs = %{pid => %EtsTableServer.TableInfo{table: ref}}

      Enum.each(-1..-301//-5, fn id ->
        :ets.insert(ref, {id, Fakes.trace(id: id, pid: pid)})
      end)

      count = :ets.select_count(ref, [{{:"$1", :"$2"}, [], [true]}])

      assert {:noreply, _} = EtsTableServer.handle_info(:garbage_collect, table_refs)

      assert count == :ets.select_count(ref, [{{:"$1", :"$2"}, [], [true]}])
    end
  end

  describe "handle_call/3" do
    test "creates table on event {:get_or_create_table, pid}" do
      pid = :c.pid(0, 0, 1)
      table_refs = %{}

      assert {:reply, ref, new_table_refs} =
               EtsTableServer.handle_call({:get_or_create_table, pid}, self(), table_refs)

      assert [{:id, ^ref} | _] = :ets.info(ref)
      assert ref == Map.get(new_table_refs, pid).table
    end

    test "returns existing table on event {:get_or_create_table, pid}" do
      pid = :c.pid(0, 0, 1)
      ref = :ets.new(:test_table, [])
      table_refs = %{pid => %EtsTableServer.TableInfo{table: ref}}

      assert {:reply, ^ref, new_table_refs} =
               EtsTableServer.handle_call({:get_or_create_table, pid}, self(), table_refs)

      assert ref == Map.get(new_table_refs, pid).table
    end

    test "adds watcher on event {:watch, pid}" do
      pid = :c.pid(0, 0, 1)
      watcher_pid = :c.pid(0, 0, 2)

      table_refs = %{
        pid => %EtsTableServer.TableInfo{table: :ets.new(:test_table, [])}
      }

      assert {:reply, :ok, new_table_refs} =
               EtsTableServer.handle_call({:watch, pid}, {watcher_pid, nil}, table_refs)

      assert MapSet.new([watcher_pid]) == Map.get(new_table_refs, pid).watchers
    end
  end
end
