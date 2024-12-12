defmodule LiveDebugger.ProcessCase do
  use ExUnit.CaseTemplate

  import Mox

  setup _ do
    pid = :c.pid(0, 0, 0)

    stub(LiveDebugger.MockLiveViewScrapper, :state_from_pid, fn _pid ->
      {:ok,
       %{
         socket: %{
           id: "phx-live-view-id",
           view: DbgPocWeb.Root,
           assigns: %{
             name: "David",
             socket_id: "phx-socket-id"
           },
           root_pid: pid
         },
         components:
           {%{
              1 =>
                {DbgPocWeb.LiveComponents.First, "live_first",
                 %{
                   name: "David",
                   myself: %Phoenix.LiveComponent.CID{cid: 1}
                 },
                 %{
                   children_cids: [4, 3]
                 }, :empty},
              2 =>
                {DbgPocWeb.LiveComponents.Second, "live_second",
                 %{
                   id: "live_second",
                   myself: %Phoenix.LiveComponent.CID{cid: 2}
                 },
                 %{
                   children_cids: []
                 }, :empty},
              3 =>
                {DbgPocWeb.LiveComponents.Second, "live_third",
                 %{
                   id: "live_third",
                   myself: %Phoenix.LiveComponent.CID{cid: 3}
                 },
                 %{
                   children_cids: []
                 }, :empty},
              4 =>
                {DbgPocWeb.LiveComponents.Second, "live_fourth",
                 %{
                   id: "live_fourth",
                   myself: %Phoenix.LiveComponent.CID{cid: 4}
                 },
                 %{
                   children_cids: [5]
                 }, :empty},
              5 =>
                {DbgPocWeb.LiveComponents.Second, "live_fifth",
                 %{
                   id: "live_fifth",
                   myself: %Phoenix.LiveComponent.CID{cid: 5}
                 },
                 %{
                   children_cids: []
                 }, :empty}
            },
            %{
              DbgPocWeb.LiveComponents.First => %{"live_first" => 1},
              DbgPocWeb.LiveComponents.Second => %{
                "live_third" => 3,
                "live_second" => 2,
                "live_fourth" => 4,
                "live_fith" => 5
              }
            }, 6}
       }}
    end)

    {:ok, pid: pid}
  end
end
