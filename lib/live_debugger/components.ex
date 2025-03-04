defmodule LiveDebugger.Components do
  @moduledoc """
  This module provides reusable components for LiveDebugger.
  """

  use Phoenix.Component

  import LiveDebuggerWeb.Helpers

  alias Phoenix.LiveView.JS

  @report_issue_url "https://github.com/software-mansion-labs/live-debugger/issues/new/choose"

  @doc """
  Renders an alert with
  """
  attr(:variant, :string,
    required: true,
    values: ["danger", "success", "warning", "info"]
  )

  attr(:class, :any, default: nil, doc: "Additional classes to add to the alert.")
  attr(:with_icon, :boolean, default: false, doc: "Whether to show an icon.")
  attr(:heading, :string, default: nil, doc: "Heading for the alert.")
  attr(:rest, :global)
  slot(:inner_block, required: true)

  def alert(assigns) do
    ~H"""
    <div
      class={[
        "bg-#{@variant}-50 border border-#{@variant}-100 text-#{@variant}-800 text-sm p-2 flex flex-col gap-1 rounded-lg"
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
  attr(:variant, :string, default: "primary", values: ["primary", "secondary", "tertiary"])
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
  Renders a card.
  """
  attr(:color, :string,
    default: "primary",
    values: ["primary", "secondary", "danger", "success", "warning", "info", "gray"]
  )

  attr(:class, :any, default: nil, doc: "Additional classes to add to the card.")
  attr(:rest, :global)
  slot(:inner_block, required: true)

  def card(assigns) do
    ~H"""
    <div
      class={["border-2 border-#{@color}-600 shadow-2xl p-2 rounded-lg" | List.wrap(@class)]}
      {@rest}
    >
      <%= render_slot(@inner_block) %>
    </div>
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
  attr(:label_style, :any, default: nil, doc: "CSS style for the label")
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
        "block [&>summary>.rotate-icon]:open:rotate-90 [&>summary_.hide-on-open]:open:hidden"
        | List.wrap(@class)
      ]}
      {show_collapsible_assign(@open)}
      {@rest}
    >
      <summary
        class={[
          "block flex items-center cursor-pointer" | List.wrap(@label_class)
        ]}
        style={@label_style}
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

  def collapsible_section(assigns) do
    ~H"""
    <div class={[
      "w-full min-w-[20rem] lg:max-w-[32rem] h-max flex shadow-custom border border-secondary-200"
      | List.wrap(@class)
    ]}>
      <.collapsible
        id={@id}
        title={@title}
        open={@open}
        class="bg-white rounded-sm w-full"
        label_class="h-12 p-2 lg:pl-4 lg:pointer-events-none pointer-events-auto border-b border-secondary-100"
        chevron_class="lg:hidden flex text-primary-900"
      >
        <:label>
          <div class="flex justify-between items-center w-full">
            <div class="font-medium text-sm"><%= @title %></div>
            <div class="w-max !pointer-events-auto">
              <%= render_slot(@right_panel) %>
            </div>
          </div>
        </:label>
        <div class={["w-full flex overflow-auto rounded-sm bg-white p-2" | List.wrap(@inner_class)]}>
          <%= render_slot(@inner_block) %>
        </div>
      </.collapsible>
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
    values: ["primary", "secondary", "tertiary"],
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
    <div class={["p-4 bg-white rounded shadow-custom border border-secondary-200" | List.wrap(@class)]}>
      <table class="w-full">
        <thead class="border-b border-secondary-200">
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
            class={"h-11 #{if @on_row_click, do: "cursor-pointer hover:bg-secondary-50"}"}
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
        class={"h-20 bg-white rounded shadow-custom border border-secondary-200 #{if @on_element_click, do: "cursor-pointer hover:bg-secondary-50"}"}
        phx-click={@on_element_click}
        phx-target={@element_click_target}
        {@element_attributes_fun.(elem)}
      >
        <div class="flex flex-col justify-center h-full p-4 gap-1">
          <p class="font-medium"><%= render_slot(@title, elem) %></p>
          <p class="text-secondary-600">
            <%= render_slot(@description, elem) %>
          </p>
        </div>
      </div>
    </div>
    """
  end

  @doc """
  Renders a fullscreen using Fullscreen hook.
  If you want to open fullscreen from a button, you can use `phx-hook="OpenFullscreen"` and `data-fullscreen-id` attributes.
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
        "relative h-max w-full lg:w-max lg:min-w-[50rem] p-2 overflow-auto hidden flex-col rounded-md backdrop:bg-black backdrop:opacity-50"
        | List.wrap(@class)
      ]}
    >
      <div class="w-full h-12 py-auto px-3 flex justify-between items-center border-b border-secondary-100">
        <div class="font-semibold text-base"><%= @title %></div>
        <.icon_button
          id={"#{@id}-close"}
          phx-click={JS.dispatch("#{@id}-close", to: "##{@id}")}
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
  """
  attr(:id, :string, required: true, doc: "Same as `id` of the fullscreen.")
  attr(:title, :string, default: "")

  attr(:class, :any, default: nil, doc: "Additional classes to be added to the button.")

  attr(:icon, :string,
    default: "icon-expand",
    doc: "Icon to be displayed as a button"
  )

  def fullscreen_button(assigns) do
    ~H"""
    <.icon_button
      id={"#{@id}-button"}
      phx-click={JS.dispatch("#{@id}-open", to: "##{@id}")}
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

  def nested_badge(assigns) do
    ~H"""
    <div class="py-1 px-1.5 w-max flex gap-0.5 border border-secondary-200 text-primary-900 text-3xs font-semibold rounded-xl items-center">
      <svg
        xmlns="http://www.w3.org/2000/svg"
        viewBox="0 0 24 24"
        fill="none"
        class="w-4 h-4 text-primary-900"
      >
        <path
          fill-rule="evenodd"
          clip-rule="evenodd"
          d="M3.25 5C3.25 4.0335 4.0335 3.25 5 3.25H9.69281C10.6593 3.25 11.4428 4.0335 11.4428 5V9.69281C11.4428 10.6593 10.6593 11.4428 9.69281 11.4428H8.09637V15.6536C8.09637 15.7917 8.2083 15.9036 8.34637 15.9036H12.5572V14.3072C12.5572 13.3407 13.3407 12.5572 14.3072 12.5572H19C19.9665 12.5572 20.75 13.3407 20.75 14.3072V19C20.75 19.9665 19.9665 20.75 19 20.75H14.3072C13.3407 20.75 12.5572 19.9665 12.5572 19V17.4036H8.34637C7.37988 17.4036 6.59637 16.6201 6.59637 15.6536V11.4428H5C4.0335 11.4428 3.25 10.6593 3.25 9.69281V5ZM5 4.75C4.86193 4.75 4.75 4.86193 4.75 5V9.69281C4.75 9.83088 4.86193 9.94281 5 9.94281H9.69281C9.83088 9.94281 9.94281 9.83088 9.94281 9.69281V5C9.94281 4.86193 9.83088 4.75 9.69281 4.75H5ZM14.0572 14.3072C14.0572 14.1691 14.1691 14.0572 14.3072 14.0572H19C19.1381 14.0572 19.25 14.1691 19.25 14.3072V19C19.25 19.1381 19.1381 19.25 19 19.25H14.3072C14.1691 19.25 14.0572 19.1381 14.0572 19V14.3072Z"
          fill="#4C2B8A"
        />
      </svg>
      <p>Nested</p>
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
  Renders topbar with possible link to return to the main page.
  """
  attr(:return_link?, :boolean,
    required: true,
    doc: "Whether to show a link to return to the main page."
  )

  slot(:inner_block)

  def topbar(assigns) do
    ~H"""
    <div class="w-full h-12 shrink-0 py-auto px-4 flex items-center gap-2 bg-primary-900 text-white text-sm font-topbar font-medium">
      <.link :if={@return_link?} patch="/">
        <.icon_button icon="icon-arrow-left" size="md" />
      </.link>
      <span>LiveDebugger</span>
      <%= @inner_block && render_slot(@inner_block) %>
    </div>
    """
  end

  attr(:class, :any, default: nil)
  attr(:text, :string, default: "See any issue? Report it")

  def report_issue(assigns) do
    assigns = assign(assigns, :report_issue_url, @report_issue_url)

    ~H"""
    <div class={[
      "px-6 py-3 flex justify-center gap-1 text-xs "
      | List.wrap(@class)
    ]}>
      <div>
        <%= @text %>
        <.link href={@report_issue_url} target="_blank" class="underline hover:text-gray-400">
          here
        </.link>
      </div>
    </div>
    """
  end

  attr(:variant, :string, required: true, values: ["danger", "success", "warning", "info"])

  defp alert_icon(assigns) do
    {icon_name, icon_class} =
      case assigns.variant do
        "danger" -> {"icon-x-circle", "text-danger-800"}
        "success" -> {"icon-check-circle", "text-success-800"}
        "warning" -> {"icon-exclamation-circle", "text-warning-800"}
        "info" -> {"icon-information-circle", "text-info-800"}
      end

    assigns = assign(assigns, name: icon_name, class: icon_class)

    ~H"""
    <.icon name={@name} class={@class} />
    """
  end

  defp button_color_classes(variant) do
    case variant do
      "primary" ->
        "bg-primary-900 text-white hover:bg-primary-950"

      "secondary" ->
        "bg-white text-primary-900 border border-secondary-200 hover:bg-secondary-100"

      "tertiary" ->
        "bg-transparent text-primary-900 border border-primary-900 hover:bg-secondary-50"
    end
  end

  defp button_size_classes("md"), do: "py-2 px-3"
  defp button_size_classes("sm"), do: "py-1.5 px-2"
end
