defmodule LiveDebugger.App.Debugger.AsyncJobs.QueriesTest do
  use ExUnit.Case, async: true

  import Mox

  alias LiveDebugger.App.Debugger.AsyncJobs.Queries, as: AsyncJobsQueries
  alias LiveDebugger.App.Debugger.AsyncJobs.Structs.AsyncJob.StartAsync
  alias LiveDebugger.App.Debugger.AsyncJobs.Structs.AsyncJob.AsyncAssign
  alias LiveDebugger.MockAPILiveViewDebug
  alias LiveDebugger.MockAPITracesStorage
  alias LiveDebugger.Structs.Trace.FunctionTrace
  alias Phoenix.LiveView.Socket

  setup :verify_on_exit!

  describe "fetch_async_jobs/2 with pid and LiveView pid as node_id" do
    test "returns empty list when no live_async data exists for component" do
      pid = :c.pid(0, 1, 0)
      node_id = :c.pid(0, 2, 0)

      MockAPILiveViewDebug
      |> expect(:socket, fn ^pid ->
        {:ok, %Socket{private: %{}}}
      end)
      |> expect(:live_components, fn ^pid ->
        {:ok, []}
      end)

      assert {:ok, []} = AsyncJobsQueries.fetch_async_jobs(pid, node_id)
    end

    test "returns multiple async jobs for LiveView with mixed tasks" do
      pid = :c.pid(0, 1, 0)
      task_pid1 = :c.pid(0, 2, 0)
      task_pid2 = :c.pid(0, 3, 0)
      ref1 = make_ref()
      ref2 = make_ref()

      MockAPILiveViewDebug
      |> expect(:socket, fn ^pid ->
        {:ok,
         %Socket{
           private: %{
             live_async:
               Map.new([
                 {:my_task, {ref1, task_pid1, :start}},
                 {[:data], {ref2, task_pid2, :assign}}
               ])
           }
         }}
      end)
      |> expect(:live_components, fn ^pid ->
        {:ok, []}
      end)

      assert {:ok, jobs} = AsyncJobsQueries.fetch_async_jobs(pid, pid)
      assert length(jobs) == 2

      assert Enum.any?(jobs, fn job ->
               match?(%StartAsync{pid: ^task_pid1, name: :my_task, ref: ^ref1}, job)
             end)

      assert Enum.any?(jobs, fn job ->
               match?(%AsyncAssign{pid: ^task_pid2, keys: [:data], ref: ^ref2}, job)
             end)
    end
  end

  describe "fetch_async_jobs/2 with pid and component CID as node_id" do
    test "returns empty list when no live_async data exists for component" do
      pid = :c.pid(0, 1, 0)
      cid = %Phoenix.LiveComponent.CID{cid: 1}

      MockAPILiveViewDebug
      |> expect(:socket, fn ^pid ->
        {:ok, %Socket{private: %{}}}
      end)
      |> expect(:live_components, fn ^pid ->
        {:ok, [%{cid: 1, private: %{}}]}
      end)

      assert {:ok, []} = AsyncJobsQueries.fetch_async_jobs(pid, cid)
    end

    test "returns both StartAsync and AsyncAssign jobs for component with mixed tasks" do
      pid = :c.pid(0, 1, 0)
      cid = %Phoenix.LiveComponent.CID{cid: 1}
      task_pid1 = :c.pid(0, 2, 0)
      task_pid2 = :c.pid(0, 3, 0)
      ref1 = make_ref()
      ref2 = make_ref()

      MockAPILiveViewDebug
      |> expect(:socket, fn ^pid ->
        {:ok, %Socket{private: %{}}}
      end)
      |> expect(:live_components, fn ^pid ->
        {:ok,
         [
           %{
             cid: 1,
             private: %{
               live_async:
                 Map.new([
                   {:component_task, {ref1, task_pid1, :start}},
                   {[:component_data], {ref2, task_pid2, :assign}}
                 ])
             }
           }
         ]}
      end)

      assert {:ok, jobs} = AsyncJobsQueries.fetch_async_jobs(pid, cid)
      assert length(jobs) == 2

      assert Enum.any?(jobs, fn job ->
               match?(%StartAsync{pid: ^task_pid1, name: :component_task, ref: ^ref1}, job)
             end)

      assert Enum.any?(jobs, fn job ->
               match?(%AsyncAssign{pid: ^task_pid2, keys: [:component_data], ref: ^ref2}, job)
             end)
    end

    test "returns async jobs only for matching component CID" do
      pid = :c.pid(0, 1, 0)
      cid = %Phoenix.LiveComponent.CID{cid: 2}
      task_pid = :c.pid(0, 2, 0)
      ref = make_ref()

      MockAPILiveViewDebug
      |> expect(:socket, fn ^pid ->
        {:ok, %Socket{private: %{}}}
      end)
      |> expect(:live_components, fn ^pid ->
        {:ok,
         [
           %{
             cid: 1,
             private: %{
               live_async: %{
                 wrong_task: {make_ref(), :c.pid(0, 99, 0), :start}
               }
             }
           },
           %{
             cid: 2,
             private: %{
               live_async: %{
                 correct_task: {ref, task_pid, :start}
               }
             }
           }
         ]}
      end)

      assert {:ok, [%StartAsync{pid: ^task_pid, name: :correct_task, ref: ^ref}]} =
               AsyncJobsQueries.fetch_async_jobs(pid, cid)
    end

    test "returns error when component with given CID is not found" do
      pid = :c.pid(0, 1, 0)
      cid = %Phoenix.LiveComponent.CID{cid: 999}

      MockAPILiveViewDebug
      |> expect(:socket, fn ^pid ->
        {:ok, %Socket{private: %{}}}
      end)
      |> expect(:live_components, fn ^pid ->
        {:ok, [%{cid: 1, private: %{}}]}
      end)

      assert {:ok, []} = AsyncJobsQueries.fetch_async_jobs(pid, cid)
    end
  end

  describe "fetch_async_jobs/1 with trace reference" do
    test "returns empty list when trace has no live_async data" do
      ets_ref = make_ref()
      trace_id = -1

      MockAPITracesStorage
      |> expect(:get_by_id!, fn ^ets_ref, ^trace_id ->
        %FunctionTrace{
          return_value: {
            :ok,
            %Socket{
              private: %{}
            }
          }
        }
      end)

      assert {:ok, []} = AsyncJobsQueries.fetch_async_jobs({ets_ref, trace_id})
    end

    test "returns multiple async jobs from trace" do
      ets_ref = make_ref()
      trace_id = -1
      task_pid1 = :c.pid(0, 2, 0)
      task_pid2 = :c.pid(0, 3, 0)
      ref1 = make_ref()
      ref2 = make_ref()

      MockAPITracesStorage
      |> expect(:get_by_id!, fn ^ets_ref, ^trace_id ->
        %FunctionTrace{
          return_value: {
            :ok,
            %Socket{
              private: %{
                live_async:
                  Map.new([
                    {:trace_task, {ref1, task_pid1, :start}},
                    {[:trace_data], {ref2, task_pid2, :assign}}
                  ])
              }
            }
          }
        }
      end)

      assert {:ok, jobs} = AsyncJobsQueries.fetch_async_jobs({ets_ref, trace_id})
      assert length(jobs) == 2

      assert Enum.any?(jobs, fn job ->
               match?(%StartAsync{pid: ^task_pid1, name: :trace_task, ref: ^ref1}, job)
             end)

      assert Enum.any?(jobs, fn job ->
               match?(%AsyncAssign{pid: ^task_pid2, keys: [:trace_data], ref: ^ref2}, job)
             end)
    end

    test "returns error when trace is not found" do
      ets_ref = make_ref()
      trace_id = -999

      MockAPITracesStorage
      |> expect(:get_by_id!, fn ^ets_ref, ^trace_id ->
        nil
      end)

      assert {:error, "Trace not found"} = AsyncJobsQueries.fetch_async_jobs({ets_ref, trace_id})
    end
  end
end
