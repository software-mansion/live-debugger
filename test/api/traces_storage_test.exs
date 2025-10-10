defmodule LiveDebugger.API.TracesStorageTest do
  use ExUnit.Case, async: true

  import Mox

  alias LiveDebugger.Utils.Memory
  alias LiveDebugger.Fakes
  alias LiveDebugger.API.TracesStorage.Impl, as: TracesStorageImpl

  @all_functions LiveDebugger.Utils.Callbacks.all_callbacks()
                 |> Enum.map(fn {function, arity} -> "#{function}/#{arity}" end)

  @processes_table_name :lvdbg_traces_processes

  setup :verify_on_exit!

  setup_all do
    :ok = TracesStorageImpl.init()

    %{
      module: CoolApp.LiveViews.UserDashboard,
      pid: :c.pid(0, 0, 1)
    }
  end

  setup context do
    :ets.delete_all_objects(@processes_table_name)
    table = :ets.new(:trace_table, [:ordered_set, :public])

    Map.put(context, :table, table)
  end

  test "insert!/1", %{pid: pid, table: table} do
    trace = Fakes.trace(id: 1, function: :render, pid: pid)

    assert true == TracesStorageImpl.insert!(table, trace)
    assert [{trace.id, trace}] == :ets.lookup(table, trace.id)

    :ets.delete(table)

    assert_raise ArgumentError, fn ->
      TracesStorageImpl.insert!(table, trace)
    end
  end

  test "insert/1", %{pid: pid} do
    trace1 = Fakes.trace(id: 1, function: :render, pid: pid)
    trace2 = Fakes.trace(id: 2, function: :handle_info, pid: pid)

    assert [] = :ets.tab2list(@processes_table_name)

    assert true == TracesStorageImpl.insert(trace1)
    assert [{^pid, table}] = :ets.tab2list(@processes_table_name)
    assert [{trace1.id, trace1}] == :ets.tab2list(table)

    assert true == TracesStorageImpl.insert(trace2)
    assert [{^pid, table}] = :ets.tab2list(@processes_table_name)
    assert [{trace1.id, trace1}, {trace2.id, trace2}] == :ets.tab2list(table)
  end

  test "get_by_id!/2", %{pid: pid, table: table} do
    trace1 = Fakes.trace(id: 1, function: :handle_info, pid: pid)
    trace2 = Fakes.trace(id: 2, function: :render, pid: pid)

    :ets.insert(@processes_table_name, {pid, table})
    :ets.insert(table, {trace1.id, trace1})
    :ets.insert(table, {trace2.id, trace2})

    assert trace1 == TracesStorageImpl.get_by_id!(pid, trace1.id)
    assert trace2 == TracesStorageImpl.get_by_id!(pid, trace2.id)

    assert trace1 == TracesStorageImpl.get_by_id!(table, trace1.id)
    assert trace2 == TracesStorageImpl.get_by_id!(table, trace2.id)

    assert nil == TracesStorageImpl.get_by_id!(pid, 99)

    :ets.delete(table)

    assert_raise ArgumentError, fn ->
      TracesStorageImpl.get_by_id!(table, trace1.id)
    end
  end

  describe "get!/2" do
    test "returns traces with default limit", %{pid: pid, table: table} do
      trace1 = Fakes.trace(id: 1, function: :handle_info, arity: 2, pid: pid)
      trace2 = Fakes.trace(id: 2, function: :render, arity: 1, pid: pid)

      :ets.insert(@processes_table_name, {pid, table})
      :ets.insert(table, {trace1.id, trace1})
      :ets.insert(table, {trace2.id, trace2})

      assert {[^trace1, ^trace2], _} =
               TracesStorageImpl.get!(pid, functions: @all_functions)

      assert {[^trace1, ^trace2], _} =
               TracesStorageImpl.get!(table, functions: @all_functions)
    end

    test "returns traces with limit and continuation", %{pid: pid, table: table} do
      trace1 = Fakes.trace(id: 1, function: :handle_info, arity: 2, pid: pid)
      trace2 = Fakes.trace(id: 2, function: :render, arity: 1, pid: pid)
      trace3 = Fakes.trace(id: 3, function: :handle_event, arity: 3, pid: pid)

      :ets.insert(@processes_table_name, {pid, table})
      :ets.insert(table, {trace1.id, trace1})
      :ets.insert(table, {trace2.id, trace2})
      :ets.insert(table, {trace3.id, trace3})

      # PID as table id
      {traces1, cont} = TracesStorageImpl.get!(pid, limit: 2, functions: @all_functions)
      {traces2, cont} = TracesStorageImpl.get!(pid, cont: cont, functions: @all_functions)

      assert [trace1, trace2] == traces1
      assert [trace3] == traces2
      assert cont == :end_of_table

      assert :end_of_table == TracesStorageImpl.get!(pid, cont: :end_of_table)

      # reference as table id
      {traces1, cont} = TracesStorageImpl.get!(table, limit: 2, functions: @all_functions)
      {traces2, cont} = TracesStorageImpl.get!(table, cont: cont, functions: @all_functions)

      assert [trace1, trace2] == traces1
      assert [trace3] == traces2
      assert cont == :end_of_table

      assert :end_of_table == TracesStorageImpl.get!(table, cont: :end_of_table)
    end

    test "raise ArgumentError when limit is less than 1", %{pid: pid} do
      assert_raise ArgumentError, fn -> TracesStorageImpl.get!(pid, limit: 0) end
      assert_raise ArgumentError, fn -> TracesStorageImpl.get!(pid, limit: -23) end
    end

    test "raise ArgumentError when table does not exist", %{table: table} do
      :ets.delete(table)
      assert_raise ArgumentError, fn -> TracesStorageImpl.get!(table) end
      assert_raise ArgumentError, fn -> TracesStorageImpl.get!(table) end
    end

    test "returns traces with functions filter", %{pid: pid, table: table} do
      trace1 = Fakes.trace(id: 1, function: :handle_info, arity: 2, pid: pid)
      trace2 = Fakes.trace(id: 2, function: :render, arity: 1, pid: pid)
      trace3 = Fakes.trace(id: 3, function: :handle_event, arity: 3, pid: pid)

      :ets.insert(@processes_table_name, {pid, table})
      :ets.insert(table, {trace1.id, trace1})
      :ets.insert(table, {trace2.id, trace2})
      :ets.insert(table, {trace3.id, trace3})

      assert {[^trace1], _} = TracesStorageImpl.get!(pid, functions: ["handle_info/2"])
      assert {[^trace1], _} = TracesStorageImpl.get!(table, functions: ["handle_info/2"])

      assert {[^trace1, ^trace2], _} =
               TracesStorageImpl.get!(pid,
                 functions: ["handle_info/2", "render/1", "mount/1"]
               )

      assert {[^trace1, ^trace2], _} =
               TracesStorageImpl.get!(table,
                 functions: ["handle_info/2", "render/1", "mount/1"]
               )
    end

    test "returns traces with execution time filter", %{pid: pid, table: table} do
      trace1 = Fakes.trace(id: 1, function: :handle_info, arity: 2, pid: pid, execution_time: 11)
      trace2 = Fakes.trace(id: 2, function: :render, arity: 1, pid: pid, execution_time: 25)
      trace3 = Fakes.trace(id: 3, function: :handle_event, arity: 3, pid: pid, execution_time: 99)

      :ets.insert(@processes_table_name, {pid, table})
      :ets.insert(table, {trace1.id, trace1})
      :ets.insert(table, {trace2.id, trace2})
      :ets.insert(table, {trace3.id, trace3})

      assert {[^trace2], _} =
               TracesStorageImpl.get!(pid,
                 execution_times: %{"exec_time_min" => 15, "exec_time_max" => 50},
                 functions: @all_functions
               )

      assert {[^trace2], _} =
               TracesStorageImpl.get!(table,
                 execution_times: %{"exec_time_min" => 15, "exec_time_max" => 50},
                 functions: @all_functions
               )

      assert {[^trace2, ^trace3], _} =
               TracesStorageImpl.get!(pid,
                 execution_times: %{"exec_time_min" => 15, "exec_time_max" => :infinity},
                 functions: @all_functions
               )

      assert {[^trace2, ^trace3], _} =
               TracesStorageImpl.get!(table,
                 execution_times: %{"exec_time_min" => 15, "exec_time_max" => :infinity},
                 functions: @all_functions
               )
    end

    test "returns traces with functions filter and execution time filter", %{
      pid: pid,
      table: table
    } do
      trace1 = Fakes.trace(id: 1, function: :handle_info, arity: 2, pid: pid, execution_time: 11)
      trace2 = Fakes.trace(id: 2, function: :render, arity: 1, pid: pid, execution_time: 25)
      trace3 = Fakes.trace(id: 3, function: :handle_event, arity: 3, pid: pid, execution_time: 99)

      :ets.insert(@processes_table_name, {pid, table})
      :ets.insert(table, {trace1.id, trace1})
      :ets.insert(table, {trace2.id, trace2})
      :ets.insert(table, {trace3.id, trace3})

      assert {[^trace2], _} =
               TracesStorageImpl.get!(pid,
                 functions: ["handle_info/2", "render/1", "mount/1"],
                 execution_times: %{"exec_time_min" => 15, "exec_time_max" => 150}
               )

      assert {[^trace2], _} =
               TracesStorageImpl.get!(table,
                 functions: ["handle_info/2", "render/1", "mount/1"],
                 execution_times: %{"exec_time_min" => 15, "exec_time_max" => 150}
               )
    end

    test "returns traces with node_id filter", %{pid: pid, table: table} do
      cid = %Phoenix.LiveComponent.CID{cid: 3}
      trace1 = Fakes.trace(id: 1, function: :handle_info, arity: 2, pid: pid)
      trace2 = Fakes.trace(id: 2, function: :render, arity: 1, pid: pid, cid: cid)
      trace3 = Fakes.trace(id: 3, function: :handle_event, arity: 3, pid: pid, cid: cid)

      :ets.insert(@processes_table_name, {pid, table})
      :ets.insert(table, {trace1.id, trace1})
      :ets.insert(table, {trace2.id, trace2})
      :ets.insert(table, {trace3.id, trace3})

      assert {[^trace1], _} = TracesStorageImpl.get!(pid, node_id: pid, functions: @all_functions)

      assert {[^trace1], _} =
               TracesStorageImpl.get!(table, node_id: pid, functions: @all_functions)

      assert {[^trace2, ^trace3], _} =
               TracesStorageImpl.get!(pid, node_id: cid, functions: @all_functions)

      assert {[^trace2, ^trace3], _} =
               TracesStorageImpl.get!(table, node_id: cid, functions: @all_functions)
    end

    test "returns :end_of_table when no traces match", %{pid: pid, table: table} do
      trace1 = Fakes.trace(id: 1, function: :handle_info, arity: 2, pid: pid)
      trace2 = Fakes.trace(id: 2, function: :render, arity: 1, pid: pid)

      :ets.insert(@processes_table_name, {pid, table})
      :ets.insert(table, {trace1.id, trace1})
      :ets.insert(table, {trace2.id, trace2})

      assert :end_of_table =
               TracesStorageImpl.get!(pid, functions: ["info/2"])

      assert :end_of_table =
               TracesStorageImpl.get!(table, functions: ["info/2"])
    end

    test "returns only finished traces", %{pid: pid, table: table} do
      trace1 = Fakes.trace(id: 1, function: :handle_info, arity: 2, pid: pid)
      trace2 = Fakes.trace(id: 2, function: :render, pid: pid, execution_time: nil)

      :ets.insert(@processes_table_name, {pid, table})
      :ets.insert(table, {trace1.id, trace1})
      :ets.insert(table, {trace2.id, trace2})

      assert {[^trace1], _} = TracesStorageImpl.get!(pid, functions: @all_functions)
      assert {[^trace1], _} = TracesStorageImpl.get!(table, functions: @all_functions)
    end

    test "filters traces by search_phrase in args maps", %{pid: pid, table: table} do
      trace1 =
        Fakes.trace(
          id: 1,
          module: CoolApp.Dashboard,
          function: :render,
          pid: pid,
          args: [%{note: "hello world"}]
        )

      trace2 =
        Fakes.trace(
          id: 2,
          module: CoolApp.Error,
          function: :render,
          pid: pid,
          args: [%{note: "test phrase here"}]
        )

      :ets.insert(@processes_table_name, {pid, table})
      :ets.insert(table, {trace1.id, trace1})
      :ets.insert(table, {trace2.id, trace2})

      assert {[^trace2], _} =
               TracesStorageImpl.get!(pid,
                 functions: @all_functions,
                 search_phrase: "phrase"
               )

      assert {[^trace2], _} =
               TracesStorageImpl.get!(table,
                 functions: @all_functions,
                 search_phrase: "phrase"
               )
    end

    test "search is case-insensitive", %{pid: pid, table: table} do
      trace1 = Fakes.trace(id: 1, function: :render, pid: pid, args: [%{note: "CaseSensitive"}])

      :ets.insert(@processes_table_name, {pid, table})
      :ets.insert(table, {trace1.id, trace1})

      assert {[^trace1], _} =
               TracesStorageImpl.get!(pid,
                 functions: @all_functions,
                 search_phrase: "casesensitive"
               )

      assert {[^trace1], _} =
               TracesStorageImpl.get!(table,
                 functions: @all_functions,
                 search_phrase: "casesensitive"
               )
    end

    test "returns traces with pagination when phrase searching", %{pid: pid, table: table} do
      trace1 = Fakes.trace(id: 1, pid: pid, args: [%{note: "phrase"}])
      trace2 = Fakes.trace(id: 2, pid: pid, args: [%{note: "phrase"}])
      trace3 = Fakes.trace(id: 3, pid: pid, args: [%{note: ""}])
      trace4 = Fakes.trace(id: 4, pid: pid, args: [%{note: "phrase"}])

      :ets.insert(@processes_table_name, {pid, table})
      :ets.insert(table, {trace1.id, trace1})
      :ets.insert(table, {trace2.id, trace2})
      :ets.insert(table, {trace3.id, trace3})
      :ets.insert(table, {trace4.id, trace4})

      {traces1, cont} =
        TracesStorageImpl.get!(pid, limit: 2, functions: @all_functions, search_phrase: "phrase")

      {traces2, cont} =
        TracesStorageImpl.get!(pid,
          cont: cont,
          functions: @all_functions,
          search_phrase: "phrase"
        )

      assert [trace1, trace2] == traces1
      assert [trace4] == traces2
      assert cont == :end_of_table
    end
  end

  describe "clear!/2" do
    test "clears traces for LiveView", %{pid: pid, table: table} do
      cid = %Phoenix.LiveComponent.CID{cid: 3}

      trace1 = Fakes.trace(id: 1, function: :handle_info, arity: 2, pid: pid)
      trace2 = Fakes.trace(id: 2, function: :render, arity: 1, pid: pid, cid: cid)

      :ets.insert(@processes_table_name, {pid, table})
      :ets.insert(table, {trace1.id, trace1})
      :ets.insert(table, {trace2.id, trace2})

      assert [{trace1.id, trace1}, {trace2.id, trace2}] == :ets.tab2list(table)

      TracesStorageImpl.clear!(pid, trace1.pid)

      assert [{trace2.id, trace2}] == :ets.tab2list(table)
    end

    test "clears traces for LiveComponent", %{pid: pid, table: table} do
      cid = %Phoenix.LiveComponent.CID{cid: 3}

      trace1 = Fakes.trace(id: 1, function: :handle_info, arity: 2, pid: pid)
      trace2 = Fakes.trace(id: 2, function: :render, arity: 1, pid: pid, cid: cid)

      :ets.insert(@processes_table_name, {pid, table})
      :ets.insert(table, {trace1.id, trace1})
      :ets.insert(table, {trace2.id, trace2})

      assert [{trace1.id, trace1}, {trace2.id, trace2}] == :ets.tab2list(table)

      TracesStorageImpl.clear!(pid, trace2.cid)

      assert [{trace1.id, trace1}] == :ets.tab2list(table)
    end

    test "clears all traces for process", %{pid: pid, table: table} do
      cid = %Phoenix.LiveComponent.CID{cid: 3}

      trace1 = Fakes.trace(id: 1, function: :handle_info, arity: 2, pid: pid)
      trace2 = Fakes.trace(id: 2, function: :render, arity: 1, pid: pid, cid: cid)

      :ets.insert(@processes_table_name, {pid, table})
      :ets.insert(table, {trace1.id, trace1})
      :ets.insert(table, {trace2.id, trace2})

      assert [{trace1.id, trace1}, {trace2.id, trace2}] == :ets.tab2list(table)

      TracesStorageImpl.clear!(pid)

      assert [] == :ets.tab2list(table)
    end
  end

  test "get_table/1", %{pid: pid1, table: table1} do
    pid2 = :c.pid(0, 2, 0)
    :ets.insert(@processes_table_name, {pid1, table1})

    assert ^table1 = TracesStorageImpl.get_table(pid1)
    assert table2 = TracesStorageImpl.get_table(pid2)
    assert [{^pid2, ^table2}, {^pid1, ^table1}] = :ets.tab2list(@processes_table_name)
  end

  describe "trim_table/2" do
    test "using ref", %{pid: pid, table: table} do
      approx_size =
        Enum.reduce(-1..-100//-1, 0, fn id, acc ->
          record = {id, Fakes.trace(id: id, pid: pid)}
          :ets.insert(table, record)
          acc + Memory.approx_term_size(record)
        end)

      TracesStorageImpl.trim_table!(table, approx_size * 0.1)

      assert 11 == :ets.select_count(table, [{{:"$1", :"$2"}, [], [true]}])
    end

    test "using pid", %{pid: pid, table: table} do
      :ets.insert(@processes_table_name, {pid, table})

      approx_size =
        Enum.reduce(-1..-100//-1, 0, fn id, acc ->
          record = {id, Fakes.trace(id: id, pid: pid)}
          :ets.insert(table, record)
          acc + Memory.approx_term_size(record)
        end)

      TracesStorageImpl.trim_table!(pid, approx_size * 0.1)

      assert 11 == :ets.select_count(table, [{{:"$1", :"$2"}, [], [true]}])
    end
  end

  describe "delete_table!/1" do
    test "using pid", %{pid: pid, table: table} do
      :ets.insert(@processes_table_name, {pid, table})

      assert true == TracesStorageImpl.delete_table!(pid)

      assert [] == :ets.tab2list(@processes_table_name)
      assert :undefined == :ets.info(table)

      assert false == TracesStorageImpl.delete_table!(pid)
    end

    test "using ref", %{pid: pid, table: table} do
      :ets.insert(@processes_table_name, {pid, table})

      assert true == TracesStorageImpl.delete_table!(table)

      assert [] == :ets.tab2list(@processes_table_name)
      assert :undefined == :ets.info(table)

      assert false == TracesStorageImpl.delete_table!(table)
    end

    test "raise ArgumentError when table does not exist but is kept in processes table", %{
      pid: pid,
      table: table
    } do
      :ets.insert(@processes_table_name, {pid, table})
      :ets.delete(table)
      assert_raise ArgumentError, fn -> TracesStorageImpl.delete_table!(table) end
      assert [] == :ets.tab2list(@processes_table_name)
    end
  end

  test "get_all_tables/0" do
    pid1 = :c.pid(0, 1, 0)
    pid2 = :c.pid(0, 2, 0)
    table1 = :ets.new(:table1, [:ordered_set, :public])
    table2 = :ets.new(:table2, [:ordered_set, :public])

    :ets.insert(@processes_table_name, {pid1, table1})
    :ets.insert(@processes_table_name, {pid2, table2})

    assert [{^pid1, ^table1}, {^pid2, ^table2}] = TracesStorageImpl.get_all_tables()
  end

  describe "table_size/1" do
    test "returns the memory size of an ETS table in bytes" do
      table = :ets.new(:test_table, [:public])
      # Initial size of an empty ETS table
      initial_size = TracesStorageImpl.table_size(table)

      assert initial_size >= 0
      :ets.insert(table, {:key, "value"})

      size = TracesStorageImpl.table_size(table)

      assert size - initial_size == 80
      :ets.delete(table)
    end

    test "returns 0 ig there is no ETS table" do
      table = :non_existing_table
      assert TracesStorageImpl.table_size(table) == 0
    end
  end
end
