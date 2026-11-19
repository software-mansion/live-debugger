defmodule LiveDebugger.E2E.AssignsTest do
  use LiveDebugger.E2E.Case, async: true, parameterize: LiveDebugger.E2E.Case.projects()

  @moduletag dev_url: "/"
  @moduletag :dbg_app

  defp term_entry(page, container_id, key, value) do
    Page.locator(
      page,
      ~s|xpath=//*[@id="#{container_id}"]//*[contains(normalize-space(text()), "#{key}:")]/../..//*[contains(normalize-space(text()), "#{value}")]|
    )
  end

  defp show_button(page, selector) do
    Page.evaluate!(
      page,
      """
      (sel) => {
        const el = document.querySelector(sel);
        if (el) el.style.display = 'block';
      }
      """,
      selector
    )
  end

  defp click_pin_button(page, assign_key) do
    selector = ~s|#all-assigns button[phx-click="pin-assign"][phx-value-key="#{assign_key}"]|
    show_button(page, selector)
    Page.locator(page, selector) |> Locator.click!(force: true)
  end

  defp click_unpin_button(page, assign_key) do
    selector = ~s|#pinned-assigns button[phx-click="unpin-assign"][phx-value-key="#{assign_key}"]|
    show_button(page, selector)
    Page.locator(page, selector) |> Locator.click!(force: true)
  end

  defp deep_value_pre(page, container),
    do: page |> Page.locator("#{container} pre") |> Locator.filter(has_text: ~s|"deep value"|)

  test "user can search assigns using the searchbar", %{dbg_app: dbg_app} do
    Expect.to_be_visible!(term_entry(dbg_app, "all-assigns", "counter", "0"))

    Expect.not_to_be_visible!(deep_value_pre(dbg_app, "#all-assigns"))

    Page.locator(dbg_app, "#assigns-search-input") |> Locator.fill!("deep value")
    Expect.to_be_visible!(deep_value_pre(dbg_app, "#all-assigns"))

    Page.reload!(dbg_app)

    Page.locator(dbg_app, ~s|button[aria-label="Icon expand"]|) |> Locator.click!()

    Expect.not_to_be_visible!(deep_value_pre(dbg_app, "#all-assigns-fullscreen"))

    Page.locator(dbg_app, "#assigns-search-input-fullscreen") |> Locator.fill!("deep value")
    Expect.to_be_visible!(deep_value_pre(dbg_app, "#all-assigns-fullscreen"))
  end

  test "user can pin and unpin specific assigns", %{dev_app: dev_app, dbg_app: dbg_app} do
    Expect.to_contain_text!(Page.locator(dbg_app, "#pinned-assigns"), "No pinned assigns")

    click_pin_button(dbg_app, "counter")
    Expect.to_be_visible!(term_entry(dbg_app, "pinned-assigns", "counter", "0"))

    Page.locator(dev_app, "#increment-button") |> Locator.click!()
    Page.locator(dev_app, "#increment-button") |> Locator.click!()
    Page.locator(dev_app, "#send-button") |> Locator.click!()

    Expect.to_be_visible!(term_entry(dbg_app, "all-assigns", "counter", "2"))
    Expect.to_be_visible!(term_entry(dbg_app, "pinned-assigns", "counter", "2"))

    click_unpin_button(dbg_app, "counter")
    Expect.to_contain_text!(Page.locator(dbg_app, "#pinned-assigns"), "No pinned assigns")
  end

  test "user can see temporary assigns", %{dev_app: dev_app, dbg_app: dbg_app} do
    Expect.to_be_visible!(term_entry(dbg_app, "temporary-assigns", "message", "nil"))

    Page.locator(dev_app, "#append-message") |> Locator.click!()
    Expect.to_be_visible!(term_entry(dbg_app, "temporary-assigns", "message", "%{...}"))

    Page.locator(dev_app, "#increment-button") |> Locator.click!()
    Expect.to_be_visible!(term_entry(dbg_app, "temporary-assigns", "message", "%{...}"))

    Page.goto!(dev_app, "/nested")
    Page.get_by_role(dbg_app, :button, name: "Continue") |> Locator.click!()

    Expect.to_contain_text!(Page.locator(dbg_app, "#temporary-assigns"), "No temporary assigns")
  end

  test "user can go through assigns change history", %{dev_app: dev_app, dbg_app: dbg_app} do
    Page.locator(dev_app, "#increment-button") |> Locator.click!()
    Page.locator(dev_app, "#increment-button") |> Locator.click!()
    Page.locator(dev_app, "#send-button") |> Locator.click!()

    Page.locator(dbg_app, ~s|#all-assigns button[phx-click="open-assigns-history"]|)
    |> Locator.click!()

    Expect.to_be_visible!(term_entry(dbg_app, "history-old-assigns", "counter", "2"))
    Expect.to_be_visible!(term_entry(dbg_app, "history-old-assigns", "datetime", "nil"))
    Expect.to_be_visible!(term_entry(dbg_app, "history-new-assigns", "counter", "2"))
    Expect.to_be_visible!(term_entry(dbg_app, "history-new-assigns", "datetime", "~U["))

    Page.locator(dbg_app, ~s|button[phx-click="go-back"]|) |> Locator.click!()
    Expect.to_be_visible!(term_entry(dbg_app, "history-old-assigns", "counter", "1"))
    Expect.to_be_visible!(term_entry(dbg_app, "history-old-assigns", "datetime", "nil"))
    Expect.to_be_visible!(term_entry(dbg_app, "history-new-assigns", "counter", "2"))
    Expect.to_be_visible!(term_entry(dbg_app, "history-new-assigns", "datetime", "nil"))

    Page.locator(dbg_app, ~s|button[phx-click="go-forward"]|) |> Locator.click!()
    Expect.to_be_visible!(term_entry(dbg_app, "history-old-assigns", "counter", "2"))
    Expect.to_be_visible!(term_entry(dbg_app, "history-old-assigns", "datetime", "nil"))
    Expect.to_be_visible!(term_entry(dbg_app, "history-new-assigns", "counter", "2"))
    Expect.to_be_visible!(term_entry(dbg_app, "history-new-assigns", "datetime", "~U["))

    Page.locator(dbg_app, ~s|button[phx-click="go-back-end"]|) |> Locator.click!()
    Expect.to_be_visible!(term_entry(dbg_app, "history-new-assigns", "counter", "0"))
    Expect.to_be_visible!(term_entry(dbg_app, "history-new-assigns", "datetime", "nil"))

    Page.locator(dbg_app, ~s|button[phx-click="go-forward-end"]|) |> Locator.click!()
    Expect.to_be_visible!(term_entry(dbg_app, "history-new-assigns", "counter", "2"))
    Expect.to_be_visible!(term_entry(dbg_app, "history-new-assigns", "datetime", "~U["))

    Page.locator(dev_app, "#increment-button") |> Locator.click!()
    Page.locator(dev_app, "#increment-button") |> Locator.click!()

    Expect.to_be_visible!(term_entry(dbg_app, "history-old-assigns", "counter", "3"))
    Expect.to_be_visible!(term_entry(dbg_app, "history-new-assigns", "counter", "4"))

    Page.locator(dbg_app, "#assigns-history-close") |> Locator.click!()
    find_switch_tracing_button(dbg_app) |> Locator.click!()
    find_clear_traces_button(dbg_app) |> Locator.click!()

    Page.locator(dbg_app, ~s|#all-assigns button[phx-click="open-assigns-history"]|)
    |> Locator.click!()

    Expect.to_contain_text!(Page.locator(dbg_app, "#assigns-history"), "No history records")
  end
end
