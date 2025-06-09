defmodule LiveDebuggerWeb.Components do
  @moduledoc """
  This module provides reusable components for LiveDebugger.
  """

  use Phoenix.Component

  alias LiveDebugger.Utils.Parsers
  alias Phoenix.LiveView.JS

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
  Renders a checkbox.
  """
  attr(:field, Phoenix.HTML.FormField, required: true)
  attr(:label, :string, default: nil)

  attr(:wrapper_class, :any, default: nil)
  attr(:input_class, :any, default: nil)
  attr(:label_class, :any, default: nil)
  attr(:rest, :global, include: ~w(type))

  def checkbox(assigns) do
    ~H"""
    <div class={["flex items-center gap-2" | List.wrap(@wrapper_class)]}>
      <input
        id={@field.id}
        name={@field.name}
        type="checkbox"
        checked={@field.value}
        class={[
          "w-4 h-4 text-ui-accent border border-default-border"
          | List.wrap(@input_class)
        ]}
        {@rest}
      />
      <label :if={@label} for={@field.id} class={["" | List.wrap(@label_class)]}>
        <%= @label %>
      </label>
    </div>
    """
  end

  attr(:value_field, Phoenix.HTML.FormField, required: true)
  attr(:unit_field, Phoenix.HTML.FormField, required: true)
  attr(:units, :list, required: true)
  attr(:rest, :global, include: ~w(min max placeholder))

  def input_with_units(assigns) do
    assigns =
      assigns
      |> assign(:errors, assigns.value_field.errors)

    ~H"""
    <div class={[
      "shadow-sm flex items-center rounded-[4px] outline outline-1 -outline-offset-1 has-[input:focus-within]:outline has-[input:focus-within]:outline-2 has-[input:focus-within]:-outline-offset-2",
      @errors == [] && "outline-default-border has-[input:focus-within]:outline-ui-accent",
      @errors != [] && "outline-error-text has-[input:focus-within]:outline-error-text"
    ]}>
      <input
        id={@value_field.id}
        name={@value_field.name}
        type="number"
        class="block remove-arrow max-w-20 bg-surface-0-bg border-none py-2.5 pl-2 pr-3 text-xs text-primary-text placeholder:text-ui-muted focus:ring-0"
        value={Phoenix.HTML.Form.normalize_value("number", @value_field.value)}
        {@rest}
      />
      <div class="grid shrink-0 grid-cols-1 focus-within:relative">
        <select
          id={@unit_field.id}
          name={@unit_field.name}
          class="border-none bg-surface-0-bg col-start-1 row-start-1 w-full appearance-none rounded-md py-1.5 pl-3 pr-7 text-xs text-secondary-text placeholder:text-gray-400 focus:outline focus:outline-2 focus:-outline-offset-2 focus:outline-ui-accent"
        >
          <%= Phoenix.HTML.Form.options_for_select(@units, @unit_field.value) %>
        </select>
      </div>
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
  `hide-on-open` and `show-on-open` css classes are used to hide or show elements based on the open state of the collapsible.

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
    assigns = assign(assigns, :open, to_string(assigns.open))

    ~H"""
    <details
      id={@id}
      phx-hook="Collapsible"
      data-open={@open}
      class={[
        "block"
        | List.wrap(@class)
      ]}
    >
      <summary
        id={@id <> "-summary"}
        class={["flex items-center cursor-pointer" | List.wrap(@label_class)]}
        {@rest}
      >
        <.icon name={@icon} class={["rotate-icon shrink-0" | List.wrap(@chevron_class)]} />
        <%= render_slot(@label) %>
      </summary>
      <%= render_slot(@inner_block) %>
    </details>
    """
  end

  @doc """
  Renders flash notices.

  ## Examples

      <.flash flash={@flash} />
      <.flash phx-mounted={show("#flash")}>Welcome Back!</.flash>
  """
  attr(:id, :string, doc: "the optional id of flash container")
  attr(:flash, :map, default: %{}, doc: "the map of flash messages to display")
  attr(:rest, :global, doc: "the arbitrary HTML attributes to add to the flash container")

  def flash(assigns) do
    message = Phoenix.Flash.get(assigns.flash, :error)

    assigns =
      assigns
      |> assign_new(:id, fn -> "flash" end)
      |> assign(:message, message)

    ~H"""
    <div
      :if={@message}
      id={@id}
      phx-hook="AutoClearFlash"
      role="alert"
      class={[
        "fixed left-2 bottom-2 w-80 sm:w-96 z-50 rounded-sm p-4 flex justify-between items-center gap-3",
        "bg-error-bg text-error-text border-error-text border"
      ]}
      {@rest}
    >
      <div class="flex gap-3 items-start">
        <div>
          <.icon name="icon-x-circle" class="text-error-icon w-3 h-3" />
        </div>
        <p>
          <%= @message %>
        </p>
      </div>
      <button
        phx-click={
          "lv:clear-flash"
          |> JS.push(value: %{key: :error})
          |> JS.hide(
            to: "##{@id}",
            time: 200,
            transition: "max-sm:animate-fadeOutMobile sm:animate-fadeOut"
          )
        }
        aria-label="close"
      >
        <.icon name="icon-cross w-4 h-4" />
      </button>
    </div>
    """
  end

  attr(:id, :string, required: true)
  attr(:title, :string, required: true)
  attr(:class, :any, default: nil)
  attr(:inner_class, :any, default: nil)

  slot(:right_panel)
  slot(:inner_block)

  def section(assigns) do
    ~H"""
    <div
      id={@id}
      class={[
        "w-full min-w-[20rem] flex flex-col shadow-custom rounded-sm bg-surface-0-bg border border-default-border"
        | List.wrap(@class)
      ]}
    >
      <div class="pl-4 flex items-center h-12 p-2 border-b border-default-border">
        <div class="flex justify-between items-center w-full">
          <div class="font-medium text-sm"><%= @title %></div>
          <div class="w-max">
            <%= render_slot(@right_panel) %>
          </div>
        </div>
      </div>
      <div class={[
        "flex flex-1 overflow-auto rounded-sm bg-surface-0-bg" | List.wrap(@inner_class)
      ]}>
        <%= render_slot(@inner_block) %>
      </div>
    </div>
    """
  end

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
    <span class={[@name | List.wrap(@class)]} {@rest}></span>
    """
  end

  @doc """
  Renders a button with an icon in it.
  """

  attr(:icon, :string, required: true, doc: "Icon to be displayed as a button.")

  attr(:variant, :string,
    default: "primary",
    values: ["primary", "secondary"],
    doc: "Variant of the button."
  )

  attr(:class, :any, default: nil, doc: "Additional classes to add to the button.")

  attr(:rest, :global, include: ~w(id))

  def icon_button(assigns) do
    assigns =
      assign(assigns, :aria_label, assigns[:"aria-label"] || Parsers.kebab_to_text(assigns.icon))

    ~H"""
    <.button
      aria-label={@aria_label}
      class={["w-7! h-7! px-[0.2rem] py-[0.2rem]" | List.wrap(@class)]}
      variant={@variant}
      {@rest}
    >
      <.icon name={@icon} class="h-4 w-4" />
    </.button>
    """
  end

  attr(:elements, :list,
    required: true,
    doc: "Elements that will be displayed in the list's `item` slot."
  )

  attr(:class, :any, default: nil, doc: "Additional classes.")
  attr(:item_class, :any, default: nil, doc: "Additional classes for each item.")

  slot(:item, required: true)

  def list(assigns) do
    ~H"""
    <ul class={[
      "w-full flex flex-col overflow-auto p-2" | List.wrap(@class)
    ]}>
      <li :for={elem <- @elements} class={@item_class}>
        <%= render_slot(@item, elem) %>
      </li>
    </ul>
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
        "relative h-max w-full xl:w-max xl:min-w-[50rem] bg-surface-0-bg overflow-auto hidden flex-col rounded-md backdrop:bg-black backdrop:opacity-50"
        | List.wrap(@class)
      ]}
    >
      <div class="w-full h-12 py-auto px-3 flex justify-between items-center border-b border-default-border">
        <div class="font-semibold text-primary-text text-base"><%= @title %></div>
        <.icon_button
          id={"#{@id}-close"}
          phx-click={JS.dispatch("close", to: "##{@id}")}
          icon="icon-cross"
          variant="secondary"
        />
      </div>
      <div class="overflow-auto flex flex-col gap-2 p-4 text-primary-text">
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
        phx-click="open-fullscreen"
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

  attr(:icon, :string,
    default: "icon-expand",
    doc: "Icon to be displayed as a button"
  )

  attr(:rest, :global, include: ~w(class))

  def fullscreen_button(assigns) do
    ~H"""
    <.icon_button
      id={"#{@id}-button"}
      phx-click={@rest[:"phx-click"] || JS.dispatch("open", to: "##{@id}")}
      icon={@icon}
      data-fullscreen-id={@id}
      variant="secondary"
      {@rest}
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
        ["animate-spin", @size_class, if(!@show, do: "hidden")] ++
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
  attr(:id, :string, required: true, doc: "ID of the tooltip. Prefix is added automatically.")
  attr(:content, :string, default: nil)

  attr(:position, :string,
    default: "top",
    values: ["top", "bottom", "left", "right", "top-center"]
  )

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

  attr(:class, :any, default: nil)
  attr(:text, :string, default: "See any issues?")

  def report_issue(assigns) do
    assigns = assign(assigns, :report_issue_url, @report_issue_url)

    ~H"""
    <div class={[
      "px-6 py-3 flex gap-1 text-xs "
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

  @doc """
  Renders a switch component.

  Based on [Tailwind CSS Toggle - Flowbite](https://flowbite.com/docs/forms/toggle)
  """
  attr(:checked, :boolean, default: false, doc: "Whether the switch is checked.")
  attr(:label, :string, default: "", doc: "Label for the switch.")
  attr(:wrapper_class, :any, default: nil, doc: "Additional classes to add to the switch.")
  attr(:id, :string, default: nil, doc: "ID of the switch.")
  attr(:rest, :global)

  def toggle_switch(assigns) do
    ~H"""
    <label class={[
      "inline-flex items-center cursor-pointer pr-6 py-3"
      | List.wrap(@wrapper_class)
    ]}>
      <span class="text-xs font-normal text-primary-text mx-2">
        <%= @label %>
      </span>
      <input id={@id} type="checkbox" class="sr-only peer" checked={@checked} {@rest} />
      <div class="relative w-9 h-5 bg-ui-muted peer-focus:outline-none peer-focus:ring-2 peer-focus:ring-ui-accent rounded-full peer peer-checked:after:translate-x-full rtl:peer-checked:after:-translate-x-full after:content-[''] after:absolute after:top-[2px] after:start-[2px] after:bg-ui-surface after:rounded-full after:h-4 after:w-4 after:transition-all peer-checked:bg-ui-accent ">
      </div>
    </label>
    """
  end

  @doc """
  Renders a button which copies specified value to clipboard.
  """
  attr(:id, :string, required: true)
  attr(:value, :string, required: true)
  attr(:variant, :string, default: "icon", values: ["icon", "icon-button"])
  attr(:rest, :global)

  def copy_button(assigns) do
    ~H"""
    <.tooltip id={@id} content="Copy" position="top-center">
      <.icon_button
        id={"copy-button_" <> @id}
        icon="icon-copy"
        variant="secondary"
        class={
          if(@variant == "icon",
            do: "w-max! h-max! p-0! bg-inherit border-none hover:text-secondary-text"
          )
        }
        phx-hook="CopyButton"
        data-info="<span class='icon-check mr-[0.1rem] w-4 h-4'></span>Copied"
        data-value={@value}
        {@rest}
      />
    </.tooltip>
    """
  end

  @doc """
  Renders an icon with navbar styles.
  """
  attr(:icon, :string, required: true, doc: "Icon to be displayed.")
  attr(:class, :any, default: nil, doc: "Additional classes to add to the nav icon.")
  attr(:selected?, :boolean, default: false, doc: "Whether the icon is selected.")

  attr(:rest, :global, include: ~w(id))

  def nav_icon(assigns) do
    selected_class =
      if assigns.selected? do
        "text-navbar-icon-hover bg-navbar-icon-bg-hover"
      else
        "text-navbar-icon hover:text-navbar-icon-hover hover:bg-navbar-icon-bg-hover"
      end

    assigns = assign(assigns, :selected_class, selected_class)

    ~H"""
    <button
      aria-label={Parsers.kebab_to_text(@icon)}
      class={[
        "w-8! h-8! px-[0.25rem] py-[0.25rem] w-max h-max rounded text-xs font-semibold  #{@selected_class}"
        | List.wrap(@class)
      ]}
      {@rest}
    >
      <.icon name={@icon} class="h-6 w-6" />
    </button>
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
