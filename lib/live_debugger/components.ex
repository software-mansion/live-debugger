defmodule LiveDebugger.Components do
  @moduledoc """
  This module provides reusable components for LiveDebugger.
  """

  use Phoenix.Component

  import LiveDebuggerWeb.Helpers

  alias Phoenix.LiveView.JS
  alias LiveDebugger.LiveHelpers.Routes

  @report_issue_url "https://github.com/software-mansion/live-debugger/issues/new/choose"

  @doc """
  Renders an alert
  Right now we have styles only for `danger` variant, but it'll change soon
  """
  attr(:variant, :string, required: true, values: ["danger"])

  attr(:class, :any, default: nil, doc: "Additional classes to add to the alert.")
  attr(:with_icon, :boolean, default: false, doc: "Whether to show an icon.")
  attr(:heading, :string, default: nil, doc: "Heading for the alert.")
  attr(:rest, :global)
  slot(:inner_block, required: true)

  def alert(assigns) do
    ~H"""
    <div
      class={[
        "bg-error-bg border border-error-border text-error-text text-sm p-2 flex flex-col gap-1 rounded-lg"
        | List.wrap(@class)
      ]}
      {@rest}
    >
      <div class="flex items-center gap-2">
        <.alert_icon :if={@with_icon} variant={@variant} />
        <p class="font-medium"><%= @heading %></p>
      </div>
      <%= render_slot(@inner_block) %>
    </div>
    """
  end

  @doc """
  Renders a button.

  """
  attr(:variant, :string, default: "primary", values: ["primary", "secondary"])
  attr(:size, :string, default: "md", values: ["md", "sm"])
  attr(:class, :any, default: nil, doc: "Additional classes to add to the button.")
  attr(:rest, :global)
  slot(:inner_block, required: true)

  def button(assigns) do
    ~H"""
    <button
      class={
        [
          "w-max h-max rounded text-xs font-semibold",
          button_color_classes(@variant),
          button_size_classes(@size)
        ] ++
          List.wrap(@class)
      }
      {@rest}
    >
      <%= render_slot(@inner_block) %>
    </button>
    """
  end

  @doc """
  Collapsible element that can be toggled open and closed.
  It uses the `details` and `summary` HTML elements.
  If you add `hide-on-open` class to element it will be hidden when collapsible is opened.

  ## Examples

      <.collapsible id="collapsible" open={true}>
        <:label>
          <div>Collapsible <div class="hide-on-open">Info when closed</div></div>
        </:label>
        <div>Content</div>
      </.collapsible>
  """

  attr(:id, :string, required: true)
  attr(:class, :any, default: nil, doc: "CSS class for parent container")
  attr(:label_class, :any, default: nil, doc: "CSS class for the label")
  attr(:chevron_class, :any, default: nil, doc: "CSS class for the chevron icon")
  attr(:open, :boolean, default: false, doc: "Whether the collapsible is open by default")

  attr(:icon, :string,
    default: "icon-chevron-right",
    doc: "Icon for chevron. It will be rotated 90 degrees when the collapsible is open"
  )

  attr(:rest, :global)

  slot(:label, required: true)
  slot(:inner_block, required: true)

  def collapsible(assigns) do
    ~H"""
    <details
      id={@id}
      class={[
        "block [&>summary>.rotate-icon]:open:rotate-90 [&>summary_.hide-on-open]:open:hidden [&>summary_.show-on-open]:open:flex"
        | List.wrap(@class)
      ]}
      {show_collapsible_assign(@open)}
    >
      <summary
        class={[
          "block flex items-center cursor-pointer" | List.wrap(@label_class)
        ]}
        {@rest}
      >
        <.icon name={@icon} class={["rotate-icon shrink-0" | List.wrap(@chevron_class)]} />
        <%= render_slot(@label) %>
      </summary>
      <%= render_slot(@inner_block) %>
    </details>
    """
  end

  attr(:id, :string, required: true)
  attr(:title, :string, required: true)
  attr(:class, :any, default: nil)
  attr(:inner_class, :any, default: nil)
  attr(:open, :boolean, default: true)

  slot(:right_panel)
  slot(:inner_block)

  def section(assigns) do
    ~H"""
    <div class={[
      "w-full min-w-[20rem] lg:max-w-[32rem] h-max flex flex-col shadow-custom rounded-sm bg-surface-0-bg border border-default-border"
      | List.wrap(@class)
    ]}>
      <div class="pl-4 flex items-center h-12 p-2 border-b border-default-border">
        <div class="flex justify-between items-center w-full">
          <div class="font-medium text-sm"><%= @title %></div>
          <div class="w-max">
            <%= render_slot(@right_panel) %>
          </div>
        </div>
      </div>
      <div class={["w-full flex overflow-auto rounded-sm bg-surface-0-bg p-2" | List.wrap(@class)]}>
        <%= render_slot(@inner_block) %>
      </div>
    </div>
    """
  end

  @doc """
  Used to add Hook to element based on condition.
  """
  def show_collapsible_assign(true), do: %{:"phx-hook" => "CollapsibleOpen"}
  def show_collapsible_assign(_), do: %{}

  @doc """
  Typography component to render headings.
  """
  attr(:class, :any, default: nil, doc: "Additional classes to add to the heading.")
  attr(:rest, :global)
  slot(:inner_block, required: true)

  def h1(assigns) do
    ~H"""
    <h1 class={["text-xl font-semibold" | List.wrap(@class)]} {@rest}>
      <%= render_slot(@inner_block) %>
    </h1>
    """
  end

  @doc """
  Renders an icon.
  Not all icons are available. If you want to use an icon check if it exists in the `assets/icons` folder.
  `name` must start with `icon-`
  ## Examples

      <.icon name="icon-play" />
  """
  attr(:name, :string, required: true, doc: "The name of the icon. Must start with `icon-`.")
  attr(:class, :any, default: nil, doc: "Additional classes to add to the icon.")
  attr(:rest, :global)

  def icon(%{name: "icon-" <> _} = assigns) do
    ~H"""
    <span class={[@name, List.wrap(@class)]} {@rest}></span>
    """
  end

  @doc """
  Renders a button with an icon in it.
  """

  attr(:icon, :string, required: true, doc: "Icon to be displayed as a button.")

  attr(:size, :string,
    default: "md",
    values: ["md", "sm"],
    doc: "Size of the button."
  )

  attr(:variant, :string,
    default: "primary",
    values: ["primary", "secondary"],
    doc: "Variant of the button."
  )

  attr(:class, :any, default: nil, doc: "Additional classes to add to the button.")

  attr(:rest, :global, include: ~w(id))

  def icon_button(assigns) do
    {button_class, icon_class} =
      case assigns.size do
        "md" -> {"w-8! h-8! px-[0.25rem] py-[0.25rem]", "h-6 w-6"}
        "sm" -> {"w-7! h-7! px-[0.375rem] py-[0.375rem]", "h-4 w-4"}
      end

    assigns =
      assigns
      |> assign(:button_class, button_class)
      |> assign(:icon_class, icon_class)

    ~H"""
    <.button class={[@button_class | List.wrap(@class)]} variant={@variant} {@rest}>
      <.icon name={@icon} class={@icon_class} />
    </.button>
    """
  end

  attr(:icon, :string, required: true, doc: "Icon to be displayed.")
  attr(:class, :any, default: nil, doc: "Additional classes to add to the nav icon.")

  attr(:rest, :global, include: ~w(id))

  def nav_icon(assigns) do
    ~H"""
    <button
      class={[
        "w-8! h-8! px-[0.25rem] py-[0.25rem] w-max h-max rounded text-xs font-semibold text-navbar-icon hover:text-navbar-icon-hover hover:bg-navbar-icon-bg-hover"
        | List.wrap(@class)
      ]}
      {@rest}
    >
      <.icon name={@icon} class="h-6 w-6" />
    </button>
    """
  end

  attr(:rows, :list, default: [], doc: "Elements that will be displayed in the list")
  attr(:class, :any, default: nil, doc: "Additional classes.")
  attr(:on_row_click, :string, default: nil)
  attr(:row_click_target, :any, default: nil)

  attr(:row_attributes_fun, :any,
    default: &empty_map/1,
    doc: "Function to return HTML attributes for each row based on row data"
  )

  slot :column, doc: "Columns with column labels" do
    attr(:label, :string, doc: "Column label")
    # Default is not supported for slot arguments
    attr(:class, :any)
  end

  def table(assigns) do
    ~H"""
    <div class={[
      "p-4 bg-surface-0-bg rounded shadow-custom border border-default-border" | List.wrap(@class)
    ]}>
      <table class="w-full">
        <thead class="border-b border-default-border">
          <tr class="h-11 mx-16">
            <th :for={col <- @column} class="first:pl-2 font-medium text-left">
              <%= Map.get(col, :label, "") %>
            </th>
          </tr>
        </thead>
        <tbody>
          <tr
            :for={row <- @rows}
            phx-click={@on_row_click}
            phx-target={@row_click_target}
            class={"h-11 #{if @on_row_click, do: "cursor-pointer hover:bg-surface-1-bg"}"}
            {@row_attributes_fun.(row)}
          >
            <td :for={col <- @column} class={["first:pl-2" | List.wrap(Map.get(col, :class))]}>
              <%= render_slot(col, row) %>
            </td>
          </tr>
        </tbody>
      </table>
    </div>
    """
  end

  attr(:elements, :list,
    default: [],
    doc: "List of maps with field `:title` and optional `:description`"
  )

  attr(:class, :any, default: nil, doc: "Additional classes.")
  attr(:on_element_click, :string, default: nil)
  attr(:element_click_target, :any, default: nil)

  attr(:element_attributes_fun, :any,
    default: &empty_map/1,
    doc: "Function to return HTML attributes for each row based on row data"
  )

  slot(:title, required: true, doc: "Slot that describes how to access title from given map")
  slot(:description, doc: "Slot that describes how to access description from given map")

  def list(assigns) do
    ~H"""
    <div class={["flex flex-col gap-2" | List.wrap(@class)]}>
      <div
        :for={elem <- @elements}
        class={"h-20 bg-surface-0-bg rounded shadow-custom border border-default-border #{if @on_element_click, do: "cursor-pointer hover:bg-surface-1-bg"}"}
        phx-click={@on_element_click}
        phx-target={@element_click_target}
        {@element_attributes_fun.(elem)}
      >
        <div class="flex flex-col justify-center h-full p-4 gap-1">
          <p class="font-medium"><%= render_slot(@title, elem) %></p>
          <p class="text-secondary-text">
            <%= render_slot(@description, elem) %>
          </p>
        </div>
      </div>
    </div>
    """
  end

  @doc """
  Renders a fullscreen using Fullscreen hook.
  It can be opened and via browser "open" event (by default) with JS.dispatch or via server event (check example in fullscreen button).

  You can use `fullscreen_button` to open this fullscreen.
  You can close the fullscreen using X button or by pressing ESC key.
  """
  attr(:id, :string, required: true)
  attr(:title, :string, default: "", doc: "Title of the fullscreen.")

  attr(:class, :any,
    default: nil,
    doc: "Additional classes to be added to the fullscreen element."
  )

  slot(:inner_block, required: true)

  def fullscreen(assigns) do
    ~H"""
    <dialog
      id={@id}
      phx-hook="Fullscreen"
      class={[
        "relative h-max w-full lg:w-max lg:min-w-[50rem] bg-surface-0-bg p-2 overflow-auto hidden flex-col rounded-md backdrop:bg-black backdrop:opacity-50"
        | List.wrap(@class)
      ]}
    >
      <div class="w-full h-12 py-auto px-3 flex justify-between items-center border-b border-default-border">
        <div class="font-semibold text-primary-text text-base"><%= @title %></div>
        <.icon_button
          id={"#{@id}-close"}
          phx-click={JS.dispatch("close", to: "##{@id}")}
          icon="icon-cross-small"
          variant="secondary"
          size="sm"
        />
      </div>
      <div class="overflow-auto flex flex-col gap-2 p-2">
        <%= render_slot(@inner_block) %>
      </div>
    </dialog>
    """
  end

  @doc """
  Renders a button which will show a fullscreen when clicked.
  You can override `phx-click` value, but remember to push correct event at the end of `handle_event` function.

  ## Examples
      <.fullscreen_button
        id="my-fullscreen"
        on_click="open-fullscreen"
        icon="icon-expand"
      />

      @impl true
      def handle_event("open-fullscreen", _, socket) do
        trace_id = String.to_integer(string_id)

        socket
        |> push_event("my-fullscreen-open", %{})
        |> noreply()
      end
  """
  attr(:id, :string, required: true, doc: "Same as `id` of the fullscreen.")
  attr(:on_click, :any, default: nil)
  attr(:on_click_target, :any, default: nil)
  attr(:on_click_data, :any, default: nil)
  attr(:class, :any, default: nil, doc: "Additional classes to be added to the button.")

  attr(:icon, :string,
    default: "icon-expand",
    doc: "Icon to be displayed as a button"
  )

  def fullscreen_button(assigns) do
    ~H"""
    <.icon_button
      id={"#{@id}-button"}
      phx-click={@on_click || JS.dispatch("open", to: "##{@id}")}
      phx-target={@on_click_target}
      phx-value-data={@on_click_data}
      icon={@icon}
      size="sm"
      data-fullscreen-id={@id}
      class={@class}
      variant="secondary"
    />
    """
  end

  attr(:class, :any, default: nil, doc: "CSS class")

  attr(:size, :string,
    default: "md",
    values: ["xs", "sm", "md", "lg", "xl"],
    doc: "Size of the spinner"
  )

  attr(:show, :boolean, default: true, doc: "show or hide spinner")
  attr(:rest, :global)

  def spinner(assigns) do
    size_class =
      case assigns.size do
        "xs" -> "h-4 w-4"
        "sm" -> "h-6 w-6"
        "md" -> "h-8 w-8"
        "lg" -> "h-10 w-10"
        "xl" -> "h-12 w-12"
      end

    assigns = assign(assigns, :size_class, size_class)

    ~H"""
    <svg
      {@rest}
      class={
        ["animate-spin", @size_class, unless(@show, do: "hidden")] ++
          List.wrap(@class)
      }
      xmlns="http://www.w3.org/2000/svg"
      fill="none"
      viewBox="0 0 24 24"
    >
      <circle class="opacity-10" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4" />
      <path
        class="none"
        fill="currentColor"
        d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"
      />
    </svg>
    """
  end

  attr(:text, :string, required: true)
  attr(:icon, :string, required: true)

  def badge(assigns) do
    ~H"""
    <div class="py-1 px-1.5 w-max flex gap-0.5 bg-surface-0-bg border border-default-border text-3xs font-semibold rounded-xl items-center">
      <.icon class="w-3 h-3 text-accent-icon" name={@icon} />
      <p class="text-accent-text"><%= @text %></p>
    </div>
    """
  end

  @doc """
  Renders a tooltip using Tooltip hook.
  """
  attr(:id, :string, required: true)
  attr(:content, :string, default: nil)
  attr(:position, :string, default: "top", values: ["top", "bottom"])
  attr(:rest, :global)
  slot(:inner_block, required: true)

  def tooltip(assigns) do
    ~H"""
    <div
      id={"tooltip_" <> @id}
      phx-hook="Tooltip"
      data-tooltip={@content}
      data-position={@position}
      {@rest}
    >
      <%= render_slot(@inner_block) %>
    </div>
    """
  end

  @doc """
  Renders navbar with possible link to return to the main page.
  """
  attr(:return_link?, :boolean,
    required: true,
    doc: "Whether to show a link to return to the main page."
  )

  slot(:inner_block)

  def navbar(assigns) do
    ~H"""
    <div class="w-full h-12 shrink-0 py-auto px-4 flex items-center gap-2 bg-navbar-bg text-navbar-logo border-b border-navbar-border">
      <.link :if={@return_link?} patch={Routes.live_views_dashboard()}>
        <.nav_icon icon="icon-arrow-left" />
      </.link>

      <.icon name="icon-logo-text" class="h-6 w-32" />
      <%= @inner_block && render_slot(@inner_block) %>
    </div>
    """
  end

  attr(:class, :any, default: nil)
  attr(:text, :string, default: "See any issues?")

  def report_issue(assigns) do
    assigns = assign(assigns, :report_issue_url, @report_issue_url)

    ~H"""
    <div class={[
      "px-6 py-3 flex justify-center gap-1 text-xs "
      | List.wrap(@class)
    ]}>
      <div>
        <%= @text %>
        <.link
          href={@report_issue_url}
          target="_blank"
          class="text-link-primary hover:text-link-primary-hover"
        >
          Report it here
        </.link>
      </div>
    </div>
    """
  end

  attr(:variant, :string, required: true, values: ["danger"])

  defp alert_icon(assigns) do
    {icon_name, icon_class} =
      case assigns.variant do
        "danger" -> {"icon-x-circle", "text-error-icon"}
      end

    assigns = assign(assigns, name: icon_name, class: icon_class)

    ~H"""
    <.icon name={@name} class={@class} />
    """
  end

  defp button_color_classes(variant) do
    case variant do
      "primary" ->
        "bg-button-primary-bg text-button-primary-content hover:bg-button-primary-bg-hover hover:text-button-primary-content-hover"

      "secondary" ->
        "bg-button-secondary-bg text-button-secondary-content border-button-secondary-border border hover:bg-button-secondary-bg-hover hover:text-button-secondary-content-hover hover:border-button-secondary-border-hover"
    end
  end

  defp button_size_classes("md"), do: "py-2 px-3"
  defp button_size_classes("sm"), do: "py-1.5 px-2"
end
