defmodule LiveDebugger.App.Web.Components do
  @moduledoc """
  Core components used in the LiveDebugger application.
  These are the general building blocks.
  """

  use Phoenix.Component

  alias LiveDebugger.App.Utils.Format
  alias LiveDebugger.App.Debugger.Web.Components.Pages
  alias Phoenix.LiveView.JS

  @report_issue_url "https://github.com/software-mansion/live-debugger/issues/new/choose"

  @doc """
  Alert message component. Use it to display error messages or warnings.
  """
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
        <.icon :if={@with_icon} name="icon-x-circle" class="text-error-icon" />
        <p class="font-medium"><%= @heading %></p>
      </div>
      <%= render_slot(@inner_block) %>
    </div>
    """
  end

  @doc """
  Checkbox element usable in forms.

  ## Examples

    <.form for={@form}>
      <.checkbox field={@form[:my_field]} label="My Field" />
    </.form>
  """
  attr(:field, Phoenix.HTML.FormField, required: true)
  attr(:label, :string, default: nil)

  attr(:wrapper_class, :any, default: nil, doc: "Additional classes for the wrapper div.")
  attr(:input_class, :any, default: nil, doc: "Additional classes for the input element.")
  attr(:label_class, :any, default: nil, doc: "Additional classes for the label element.")
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

  @doc """
  Select dropdown element usable in forms.

  ## Examples

    <.form for={@form}>
      <.select field={@form[:my_field]} label="My Field" options={[{"Option 1", "1"}, {"Option 2", "2"}]} />
    </.form>
  """
  attr(:field, Phoenix.HTML.FormField, required: true)
  attr(:label, :string, default: nil)

  attr(:options, :list,
    required: true,
    doc: "List of {label, value} tuples for the select options"
  )

  attr(:wrapper_class, :any, default: nil, doc: "Additional classes for the wrapper div.")
  attr(:select_class, :any, default: nil, doc: "Additional classes for the select element.")
  attr(:label_class, :any, default: nil, doc: "Additional classes for the label element.")
  attr(:rest, :global)

  def select(assigns) do
    ~H"""
    <div class={["flex flex-col gap-2" | List.wrap(@wrapper_class)]}>
      <label :if={@label} for={@field.id} class={["font-medium text-sm" | List.wrap(@label_class)]}>
        <%= @label %>
      </label>
      <select
        id={@field.id}
        name={@field.name}
        class={[
          "w-full rounded bg-surface-0-bg border border-default-border text-xs"
          | List.wrap(@select_class)
        ]}
        {@rest}
      >
        <%= Phoenix.HTML.Form.options_for_select(@options, @field.value) %>
      </select>
    </div>
    """
  end

  @doc """
  Text input element usable in forms.

  ## Examples

    <.form for={@form}>
      <.text_input field={@form[:my_field]} label="My Field" placeholder="Enter text..." />
    </.form>
  """
  attr(:field, Phoenix.HTML.FormField, required: true)
  attr(:label, :string, default: nil)

  attr(:wrapper_class, :any, default: nil, doc: "Additional classes for the wrapper div.")
  attr(:input_class, :any, default: nil, doc: "Additional classes for the input element.")
  attr(:label_class, :any, default: nil, doc: "Additional classes for the label element.")
  attr(:rest, :global, include: ~w(type placeholder))

  def text_input(assigns) do
    ~H"""
    <div class={["flex flex-col gap-2" | List.wrap(@wrapper_class)]}>
      <label :if={@label} for={@field.id} class={["font-medium text-sm" | List.wrap(@label_class)]}>
        <%= @label %>
      </label>
      <input
        type={@rest[:type] || "text"}
        id={@field.id}
        name={@field.name}
        value={@field.value}
        class={[
          "w-full rounded bg-surface-0-bg border border-default-border text-xs placeholder:text-ui-muted px-3 py-2"
          | List.wrap(@input_class)
        ]}
        {@rest}
      />
    </div>
    """
  end

  @doc """
  Textarea element usable in forms.

  ## Examples

    <.form for={@form}>
      <.textarea field={@form[:my_field]} label="My Field" placeholder="Enter text..." />
    </.form>
  """
  attr(:field, Phoenix.HTML.FormField, required: true)
  attr(:label, :string, default: nil)

  attr(:wrapper_class, :any, default: nil, doc: "Additional classes for the wrapper div.")
  attr(:textarea_class, :any, default: nil, doc: "Additional classes for the textarea element.")
  attr(:label_class, :any, default: nil, doc: "Additional classes for the label element.")
  attr(:rest, :global, include: ~w(rows placeholder))

  def textarea(assigns) do
    ~H"""
    <div class={["flex flex-col gap-2" | List.wrap(@wrapper_class)]}>
      <label :if={@label} for={@field.id} class={["font-medium text-sm" | List.wrap(@label_class)]}>
        <%= @label %>
      </label>
      <textarea
        id={@field.id}
        name={@field.name}
        class={[
          "w-full rounded bg-surface-0-bg border border-default-border text-xs placeholder:text-ui-muted resize-y"
          | List.wrap(@textarea_class)
        ]}
        {@rest}
      ><%= @field.value %></textarea>
    </div>
    """
  end

  attr(:field, Phoenix.HTML.FormField, required: true)
  attr(:label, :string, default: nil)
  attr(:wrapper_class, :any, default: nil, doc: "Additional classes for the wrapper div.")
  attr(:label_class, :any, default: nil, doc: "Additional classes for the label element.")
  attr(:rest, :global)

  def codearea(assigns) do
    ~H"""
    <div
      id={"#{@field.id}-codearea-wrapper"}
      phx-hook="CodeMirrorTextarea"
      data-value={@field.value}
      class={["flex flex-col gap-2" | List.wrap(@wrapper_class)]}
    >
      <label :if={@label} for={@field.id} class={["font-medium text-sm" | List.wrap(@label_class)]}>
        <%= @label %>
      </label>
      <textarea id={@field.id} name={@field.name} class="hidden" phx-debounce="250" {@rest}><%= @field.value %></textarea>
      <div id={"#{@field.id}-codemirror"} phx-update="ignore"></div>
    </div>
    """
  end

  @doc """
  Button component with customizable variant and size.
  """
  attr(:variant, :string, default: "primary", values: ["primary", "secondary"])
  attr(:size, :string, default: "md", values: ["md", "sm"])
  attr(:class, :any, default: nil, doc: "Additional classes to add to the button.")
  attr(:rest, :global, include: ~w(disabled))

  slot(:inner_block, required: true)

  def button(assigns) do
    ~H"""
    <button
      class={
        [
          "w-max h-max rounded text-xs font-semibold disabled:opacity-50 disabled:pointer-events-none",
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
          <div>
            <div class="hide-on-open">Info when closed</div>
            <div class="show-on-open">Info when open</div>
          </div>
        </:label>
        <div>Content</div>
      </.collapsible>
  """

  attr(:id, :string, required: true)
  attr(:class, :any, default: nil, doc: "CSS class for parent container")
  attr(:label_class, :any, default: nil, doc: "CSS class for the label")
  attr(:chevron_class, :any, default: nil, doc: "CSS class for the chevron icon")
  attr(:open, :boolean, default: false, doc: "Whether the collapsible is open by default")

  attr(:save_state_in_browser, :boolean,
    default: false,
    doc: "Whether to save the open/closed state in the browser's local storage"
  )

  attr(:icon, :string,
    default: "icon-chevron-right",
    doc: "Icon for chevron. It will be rotated 90 degrees when the collapsible is open"
  )

  attr(:rest, :global)

  slot(:label, required: true)
  slot(:inner_block, required: true)

  def collapsible(assigns) do
    assigns =
      assigns
      |> assign(:open, to_string(assigns.open))
      |> assign(:save_state_in_browser, to_string(assigns.save_state_in_browser))

    ~H"""
    <details
      id={@id}
      phx-hook="Collapsible"
      data-open={@open}
      data-save-state-in-browser={@save_state_in_browser}
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
  Static collapsible element. It doesn't perform any client-side actions.


  ## Examples

      <.static_collapsible id="collapsible" open={true}>
        <:label :let={open}>
          <%= if(open, do: "Open", else: "Closed") %>
        </:label>
        <div>Content</div>
      </.static_collapsible>
  """

  attr(:open, :boolean, required: true, doc: "State of the collapsible")
  attr(:class, :any, default: nil, doc: "CSS class for parent container")
  attr(:label_class, :any, default: nil, doc: "CSS class for the label")
  attr(:chevron_class, :any, default: nil, doc: "CSS class for the chevron icon")

  attr(:rest, :global)

  slot(:label, required: true)
  slot(:inner_block, required: true)

  def static_collapsible(assigns) do
    ~H"""
    <div class={["block" | List.wrap(@class)]}>
      <div class={["flex items-center cursor-pointer" | List.wrap(@label_class)]} {@rest}>
        <.icon
          name="icon-chevron-right"
          class={["shrink-0", if(@open, do: "rotate-90") | List.wrap(@chevron_class)]}
        />
        <%= render_slot(@label, @open) %>
      </div>
      <%= if(@open, do: render_slot(@inner_block)) %>
    </div>
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
  attr(:kind, :atom, values: [:info, :error], doc: "used for styling and flash lookup")
  attr(:rest, :global, doc: "the arbitrary HTML attributes to add to the flash container")

  def flash(assigns) do
    message = Phoenix.Flash.get(assigns.flash, assigns.kind)

    assigns =
      assigns
      |> assign_new(:id, fn -> "flash-#{assigns.kind}" end)
      |> assign(:message, message)

    ~H"""
    <div
      :if={@message}
      id={@id}
      phx-hook="AutoClearFlash"
      role="alert"
      class={[
        "max-sm:animate-fade-in-mobile sm:animate-fade-in fixed left-2 bottom-2 w-80 sm:w-96 z-50 rounded-sm p-4 flex justify-between items-center gap-3",
        @kind == :error && "bg-error-bg text-error-text border-error-text border",
        @kind == :info &&
          "bg-info-bg text-info-text border-info-border border"
      ]}
      {@rest}
    >
      <div class="flex gap-3 items-start">
        <div>
          <.icon :if={@kind == :error} name="icon-x-circle" class="text-error-icon w-3 h-3" />
          <.icon :if={@kind == :info} name="icon-info" class="text-info-icon w-3 h-3" />
        </div>
        <p>
          <%= if is_map(@message) do %>
            <strong><%= @message.module %></strong>
            <span><%= @message.text %></span>
            <.link
              href={@message.url}
              target="_blank"
              class="font-bold underline hover:opacity-80 ml-1"
            >
              <%= Map.get(@message, :label, "Link") %>
            </.link>
          <% else %>
            <%= @message %>
          <% end %>
        </p>
      </div>
      <button
        phx-click={
          "lv:clear-flash"
          |> JS.push(value: %{key: @kind})
          |> JS.hide(
            to: "##{@id}",
            time: 200,
            transition: "max-sm:animate-fade-out-mobile sm:animate-fade-out"
          )
        }
        aria-label="close"
      >
        <.icon name="icon-cross w-4 h-4" />
      </button>
    </div>
    """
  end

  @doc """
  Shows the flash group with standard titles and content.

  ## Examples

      <.flash_group flash={@flash} />
  """
  attr(:flash, :map, required: true, doc: "the map of flash messages")
  attr(:id, :string, default: "flash-group", doc: "the optional id of flash container")

  def flash_group(assigns) do
    ~H"""
    <div id={@id}>
      <.flash kind={:info} flash={@flash} />
      <.flash kind={:error} flash={@flash} />
    </div>
    """
  end

  attr(:id, :string, required: true)
  attr(:title, :string, required: true)
  attr(:class, :any, default: nil)
  attr(:title_class, :any, default: nil)
  attr(:inner_class, :any, default: nil)

  slot(:right_panel)
  slot(:title_sub_panel)
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
      <div class="px-4 flex items-center h-12 p-2 border-b border-default-border">
        <div class="flex justify-between items-center w-full gap-2">
          <div class={[
            "font-medium text-sm min-w-26 flex items-center gap-2"
            | List.wrap(@title_class)
          ]}>
            <p><%= @title %></p>
            <%= render_slot(@title_sub_panel) %>
          </div>
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

  attr(:id, :string, required: true)
  attr(:title, :string, required: true)

  attr(:save_state_in_browser, :boolean,
    default: false,
    doc: "Whether to save the open/closed state in the browser's local storage"
  )

  attr(:class, :any, default: nil)
  attr(:title_class, :any, default: nil)
  attr(:inner_class, :any, default: nil)

  slot(:right_panel)
  slot(:inner_block)

  def collapsible_section(assigns) do
    ~H"""
    <.collapsible
      id={@id}
      phx-hook="CollapsedSectionPulse"
      class={[
        "w-full min-w-[20rem] flex flex-col shadow-custom rounded-sm bg-surface-0-bg border border-default-border"
        | List.wrap(@class)
      ]}
      label_class="pr-4 flex items-center h-12 p-2 border-b border-default-border"
      save_state_in_browser={@save_state_in_browser}
    >
      <:label>
        <div class="ml-1 flex justify-between items-center w-full gap-2">
          <div class={["font-medium text-sm min-w-26" | List.wrap(@title_class)]}><%= @title %></div>
          <div class="w-max">
            <%= render_slot(@right_panel) %>
          </div>
        </div>
      </:label>
      <div class={[
        "flex flex-1 overflow-auto rounded-sm bg-surface-0-bg" | List.wrap(@inner_class)
      ]}>
        <%= render_slot(@inner_block) %>
      </div>
    </.collapsible>
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
  Button with only an icon in it.
  """

  attr(:icon, :string, required: true, doc: "Icon to be displayed as a button.")

  attr(:variant, :string,
    default: "primary",
    values: ["primary", "secondary"],
    doc: "Variant of the button."
  )

  attr(:class, :any, default: nil, doc: "Additional classes to add to the button.")
  attr(:rest, :global, include: ~w(id disabled))

  def icon_button(assigns) do
    assigns =
      assign(assigns, :aria_label, assigns[:"aria-label"] || Format.kebab_to_text(assigns.icon))

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

  @doc """
  Renders a list of elements using the `item` slot.

  ## Examples

      <.list elements={["Item 1", "Item 2", "Item 3"]}>
        <:item :let={item}>
          <div class="p-2 bg-gray-100 rounded">
            <%= item %>
          </div>
        </:item>
      </.list>
  """
  attr(:elements, :list,
    required: true,
    doc: "Elements that will be displayed in the list's `item` slot."
  )

  attr(:class, :any, default: nil, doc: "Additional classes for the list container.")
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
  Renders a sidebar slide over element.
  Clicking outside or the cross icon results in the `close-sidebar` event being triggered.
  """

  attr(:id, :string, required: true)
  attr(:sidebar_hidden?, :boolean, default: true, doc: "The default state of the sidebar")
  attr(:event_target, :any, default: nil, doc: "The target of the closing sidebar event")
  attr(:page, :atom, required: true, values: [:node_inspector, :global_traces])
  attr(:trigger_sidebar, :boolean, default: false)

  slot(:inner_block)

  def sidebar_slide_over(assigns) do
    ~H"""
    <span
      :if={@trigger_sidebar}
      class="hidden [--open-sidebar:1] md_ct:[--open-sidebar:0]"
      id="sidebar-auto-opener"
      phx-hook="OpenComponentsTree"
      data-cmd={Pages.get_open_sidebar_js(@page)}
    >
    </span>
    <div class="w-max flex bg-sidebar-bg shadow-custom h-full">
      <div
        id={@id}
        phx-hook="CloseSidebarOnResize"
        data-cmd={Pages.get_close_sidebar_js(@page)}
        class={[
          (@sidebar_hidden? && "hidden") || "flex",
          "fixed inset-0 bg-black/25 justify-end items-start md_ct:flex md_ct:static md_ct:inset-auto md_ct:bg-transparent z-20",
          "[--narrow-view:1]",
          "md_ct:[--narrow-view:0]"
        ]}
      >
        <div
          class="w-full h-full md_ct:hidden"
          phx-click="close-sidebar"
          {@event_target && %{:"phx-target" => @event_target} || %{}}
        >
        </div>
        <div
          class="shrink-0 h-full w-80 bg-sidebar-bg flex flex-col gap-1 justify-between border-x border-default-border md_ct:border-l"
          id="components-tree-sidebar-container"
        >
          <.icon_button
            :if={!@sidebar_hidden?}
            icon="icon-cross"
            class="absolute top-4 right-4 md_ct:hidden"
            variant="secondary"
            phx-click="close-sidebar"
            {@event_target && %{:"phx-target" => @event_target} || %{}}
          />
          <%= render_slot(@inner_block) %>
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

  attr(:send_close_event, :boolean,
    default: false,
    doc:
      "Whether to send a `fullscreen-closed` event to the server when the fullscreen is closed."
  )

  attr(:class, :any,
    default: nil,
    doc: "Additional classes to be added to the fullscreen element."
  )

  slot(:inner_block, required: true)
  slot(:search_bar_slot)
  slot(:header, doc: "Optional custom header slot to replace the default one")

  def fullscreen(assigns) do
    ~H"""
    <dialog
      id={@id}
      phx-hook="Fullscreen"
      data-send-close-event={@send_close_event}
      class={[
        "relative h-max w-full xl:w-max xl:min-w-[50rem] bg-surface-0-bg overflow-auto hidden flex-col rounded-md backdrop:bg-black backdrop:opacity-50"
        | List.wrap(@class)
      ]}
    >
      <div phx-click-away={JS.dispatch("close", to: "##{@id}")}>
        <%= if @header != [] do %>
          <%= render_slot(@header) %>
        <% else %>
          <div class="w-full h-12 py-auto px-3 flex justify-between items-center border-b border-default-border pt-1">
            <div class="flex justify-between items-center w-full font-semibold text-primary-text text-base">
              <%= @title %>
              <div class="mr-2 font-normal"><%= render_slot(@search_bar_slot) %></div>
            </div>
            <.icon_button
              id={"#{@id}-close"}
              phx-click={JS.dispatch("close", to: "##{@id}")}
              icon="icon-cross"
              variant="secondary"
            />
          </div>
        <% end %>
        <div class="overflow-auto flex flex-col gap-2 text-primary-text">
          <%= render_slot(@inner_block) %>
        </div>
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
    <.tooltip id={@id <> "-tooltip"} content="Fullscreen" position="top-center">
      <.icon_button
        id={"#{@id}-button"}
        phx-click={@rest[:"phx-click"] || JS.dispatch("open", to: "##{@id}")}
        icon={@icon}
        data-fullscreen-id={@id}
        variant="secondary"
        {@rest}
      />
    </.tooltip>
    """
  end

  @doc """
  Circle spinner component used to indicate loading state.
  """
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

  @doc """
  Renders a badge with text and icon.
  Used to add small labels in UI (e.g. `Embedded`).
  """
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
  Renders a status dot with a tooltip.
  """

  attr(:status, :atom, required: true)
  attr(:pulse?, :boolean, default: false)
  attr(:tooltip, :string, required: true)

  def status_dot(assigns) do
    assigns =
      case assigns.status do
        :success -> assign(assigns, :bg_class, "bg-status-dot-success-bg")
        :warning -> assign(assigns, :bg_class, "bg-status-dot-warning-bg")
        :error -> assign(assigns, :bg_class, "bg-status-dot-error-bg")
      end

    ~H"""
    <.tooltip id="loading-dot-tooltip" content={@tooltip}>
      <span class="relative flex size-2">
        <span
          :if={@pulse?}
          class={"absolute inline-flex h-full w-full animate-ping rounded-full #{@bg_class} opacity-75"}
        >
        </span>
        <span class={"relative inline-flex size-2 rounded-full #{@bg_class}"}></span>
      </span>
    </.tooltip>
    """
  end

  @doc """
  Renders a tooltip using Tooltip hook.
  """
  attr(:id, :string, required: true, doc: "ID of the tooltip.")
  attr(:content, :string, default: nil)

  attr(:position, :string,
    default: "top",
    values: ["top", "bottom", "left", "right", "top-center"]
  )

  attr(:rest, :global)

  attr(:fullscreen?, :boolean,
    default: false,
    doc: "Whether the tooltip is in fullscreen mode"
  )

  slot(:inner_block, required: true)

  def tooltip(assigns) do
    ~H"""
    <div
      id={@id}
      phx-hook={if @fullscreen?, do: nil, else: "Tooltip"}
      data-tooltip={if @fullscreen?, do: nil, else: @content}
      data-position={if @fullscreen?, do: nil, else: @position}
      {@rest}
    >
      <%= render_slot(@inner_block) %>
    </div>
    """
  end

  @doc """
  Link to report an issue on GitHub.
  """
  attr(:class, :any, default: nil)
  attr(:text, :string, default: "See any issues?")

  def report_issue(assigns) do
    assigns = assign(assigns, :report_issue_url, @report_issue_url)

    ~H"""
    <div class={[
      "px-6 py-3 flex gap-1 text-xs mt-auto"
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
  attr(:id, :string, required: true, doc: "ID of the switch.")
  attr(:disabled, :boolean, default: false, doc: "Whether the switch is disabled.")
  attr(:rest, :global)

  def toggle_switch(assigns) do
    ~H"""
    <label class={
      [
        "inline-flex items-center pr-6 py-3",
        if(@disabled, do: "opacity-50 pointer-events-none", else: "cursor-pointer")
      ] ++ List.wrap(@wrapper_class)
    }>
      <span class="text-xs font-normal text-primary-text mx-2">
        <%= @label %>
      </span>
      <form>
        <input
          id={@id}
          type="checkbox"
          class="sr-only peer"
          checked={@checked}
          disabled={@disabled}
          {@rest}
        />
        <div class="relative w-9 h-5 bg-ui-muted peer-focus:outline-none peer-focus:ring-2 peer-focus:ring-ui-accent rounded-full peer peer-checked:after:translate-x-full rtl:peer-checked:after:-translate-x-full after:content-[''] after:absolute after:top-[2px] after:start-[2px] after:bg-ui-surface after:rounded-full after:h-4 after:w-4 after:transition-all peer-checked:bg-ui-accent ">
        </div>
      </form>
    </label>
    """
  end

  @doc """
  Renders a button which copies specified value to clipboard.
  """
  attr(:id, :string, required: true)
  attr(:value, :string, required: true)
  attr(:fullscreen?, :boolean, default: false)
  attr(:variant, :string, default: "icon", values: ["icon", "icon-button", "button"])
  attr(:text, :string, default: "Copy")
  attr(:class, :any, default: nil, doc: "Additional classes to add to the button.")
  attr(:rest, :global)

  def copy_button(assigns) do
    ~H"""
    <.tooltip id={@id <> "-tooltip"} content="Copy" position="top-center" fullscreen?={@fullscreen?}>
      <.icon_button
        :if={@variant == "icon" or @variant == "icon-button"}
        id={@id}
        icon="icon-copy"
        variant="secondary"
        class={[
          if(@variant == "icon",
            do: "w-max! h-max! p-0! bg-inherit border-none hover:text-secondary-text"
          )
          | List.wrap(@class)
        ]}
        phx-hook="CopyButton"
        data-info="<span class='icon-check mr-[0.1rem] w-4 h-4'></span>Copied"
        data-value={@value}
        {@rest}
      />
      <.button
        :if={@variant == "button"}
        id={@id}
        variant="secondary"
        size="sm"
        class={["h-7!" | List.wrap(@class)]}
        phx-hook="CopyButton"
        data-info="<span class='icon-check mr-[0.1rem] w-4 h-4'></span>Copied"
        data-value={@value}
        {@rest}
      >
        <%= @text %>
      </.button>
    </.tooltip>
    """
  end

  @doc """
  Renders an icon with navbar styles.
  """
  attr(:icon, :string, required: true, doc: "Icon to be displayed.")
  attr(:class, :any, default: nil, doc: "Additional classes to add to the nav icon.")
  attr(:icon_class, :any, default: nil, doc: "Additional classes to add to the icon.")
  attr(:selected?, :boolean, default: false, doc: "Whether the icon is selected.")
  attr(:disabled?, :boolean, default: false, doc: "Whether the icon is disabled.")

  attr(:rest, :global, include: ~w(id))

  def nav_icon(assigns) do
    selected_class =
      if assigns.selected? do
        "text-navbar-icon-hover bg-navbar-icon-bg-hover"
      else
        "text-navbar-icon hover:text-navbar-icon-hover hover:bg-navbar-icon-bg-hover"
      end

    disabled_class =
      if assigns.disabled? do
        "opacity-50 pointer-events-none"
      end

    assigns = assign(assigns, :selected_class, selected_class)
    assigns = assign(assigns, :disabled_class, disabled_class)

    ~H"""
    <button
      aria-label={Format.kebab_to_text(@icon)}
      class={[
        "w-8 h-8 px-[0.25rem] py-[0.25rem] w-max h-max rounded text-xs font-semibold  #{@selected_class} #{@disabled_class}"
        | List.wrap(@class)
      ]}
      {@rest}
    >
      <.icon name={@icon} class={["h-6 w-6", @icon_class]} />
    </button>
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
        min="0"
        step="1"
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
  Renders a radio button component.
  """
  attr(:name, :string, required: true)
  attr(:value, :string, required: true)
  attr(:label, :string, required: true)
  attr(:checked, :boolean, default: false)

  attr(:class, :string, default: "", doc: "Additional classes to add to the radio button")

  def radio_button(assigns) do
    ~H"""
    <label class={[
      "flex items-center gap-2 px-3 py-2 rounded cursor-pointer hover:bg-surface-1-bg transition-colors"
      | List.wrap(@class)
    ]}>
      <input
        type="radio"
        name={@name}
        value={@value}
        checked={@checked}
        class="w-4 h-4 appearance-none rounded-full border-1 border-default-border bg-white cursor-pointer checked:border-ui-accent checked:bg-white relative before:content-[''] before:absolute before:top-1/2 before:left-1/2 before:-translate-x-1/2 before:-translate-y-1/2 before:w-2 before:h-2 before:rounded-full before:bg-transparent checked:before:bg-ui-accent"
      />
      <span class="text-xs"><%= @label %></span>
    </label>
    """
  end

  attr(:variant, :string, default: "info", values: ~w(info warning))
  attr(:size, :string, default: "md", values: ~w(sm md))
  attr(:class, :string, default: "", doc: "Additional classes to add to the info block")

  slot(:header)
  slot(:inner_block)

  def info_block(assigns) do
    ~H"""
    <div class={
      [
        "flex border shadow-custom rounded",
        info_block_size_classes(@size),
        info_block_color_classes(@variant)
      ] ++ List.wrap(@class)
    }>
      <div :if={@size == "md"} class="w-4 mr-2">
        <.icon name={info_block_icon_name(@variant)} class="w-4 h-4" />
      </div>
      <div class="flex flex-col gap-1">
        <div :if={@header != []} class="font-semibold">
          <%= render_slot(@header) %>
        </div>
        <%= render_slot(@inner_block) %>
      </div>
    </div>
    """
  end

  defp info_block_size_classes("sm"), do: "py-[0.3rem] px-[0.55rem] text-3xs"
  defp info_block_size_classes("md"), do: "py-[1rem] px-[1rem] text-xs"

  defp info_block_color_classes("info"), do: "bg-info-bg border-info-border text-info-text"

  defp info_block_color_classes("warning"),
    do: "bg-warning-bg border-warning-border text-warning-text"

  defp info_block_icon_name("info"), do: "icon-info"
  defp info_block_icon_name("warning"), do: "icon-triangle-alert"

  @doc """
  Renders a simple popup dialog.

  ## Examples

      <.popup id="new-version-popup" title="New Version Available">
        A new version is available!
      </.popup>
  """
  attr(:id, :string, required: true)
  attr(:title, :string, default: nil)
  attr(:show, :boolean, default: true)
  attr(:class, :any, default: nil)
  attr(:wrapper_class, :any, default: nil)
  attr(:on_close, :any, default: nil)

  slot(:inner_block, required: true)

  def popup(assigns) do
    ~H"""
    <div :if={@show} id={@id} class={["fixed inset-0 z-50", @wrapper_class]}>
      <div class="fixed inset-0 bg-black/50" phx-click={@on_close}></div>
      <dialog
        open
        class={[
          "fixed inset-0 max-w-md bg-surface-0-bg rounded-lg shadow-xl border border-default-border"
          | List.wrap(@class)
        ]}
      >
        <div class="flex flex-col">
          <div
            :if={@title}
            class="px-4 py-3 border-b border-default-border flex justify-between items-center"
          >
            <h2 class="font-semibold text-sm text-primary-text"><%= @title %></h2>
            <.icon_button
              id={"#{@id}-close"}
              phx-click={@on_close}
              icon="icon-cross"
              variant="secondary"
            />
          </div>
          <div class="p-4 text-primary-text">
            <%= render_slot(@inner_block) %>
          </div>
        </div>
      </dialog>
    </div>
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
