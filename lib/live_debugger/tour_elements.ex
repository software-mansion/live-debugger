defmodule LiveDebugger.TourElements do
  @moduledoc """
  Map of important debugger UI elements and their HTML IDs.
  Used by the tour to target elements for highlight, and spotlight actions.
  """

  @elements %{
    navbar: "#navbar",
    navbar_return_button: "#return-button",
    navbar_settings_button: "#settings-button-container",
    navbar_connected: "#navbar-connected",
    navbar_connected_tooltip: "#navbar-connected-tooltip",
    navbar_gc_warning: "#gc-disabled-warning-tooltip",

    # Node Basic Info
    node_basic_info: "#node-inspector-basic-info",
    node_module_name: "#node-inspector-basic-info-current-node-module",
    node_module_path: "#node-inspector-basic-info-current-node-module-path",
    copy_module_name: "#copy-button-module-name",
    copy_module_path: "#copy-button-module-path",
    send_event_button: "#send-event-button",
    open_in_editor: "#open-in-editor",
    show_components_tree: "#show-components-tree-button",
    send_event_fullscreen: "#send-event-fullscreen",

    # Callback Traces
    callback_traces_section: "#traces-list",
    callback_traces_search_bar: "#callback-traces-search-bar",
    callback_traces_toggle_tracing: "#tracing-tooltip",
    callback_traces_filters_button: "#filters-tooltip",
    callback_traces_first_trace: "#traces-list-stream > :first-child",

    # Inspect Button
    inspect_button: "#inspect-button-tooltip",

    # Settings
    refresh_tracing_button: "#refresh_tracing_button"
  }

  @doc """
  Returns the HTML element ID for a given tour element name.

  ## Examples

      iex> LiveDebugger.TourElements.id(:navbar)
      "navbar"

      iex> LiveDebugger.TourElements.id(:navbar_connected)
      "navbar-connected"
  """
  @spec id(atom()) :: String.t() | nil
  def id(name) when is_atom(name) do
    Map.get(@elements, name)
  end

  @doc """
  Returns the HTML element ID for a given tour element name.
  Raises if the element name is not found.
  """
  @spec id!(atom()) :: String.t()
  def id!(name) when is_atom(name) do
    case Map.fetch(@elements, name) do
      {:ok, id} -> id
      :error -> raise ArgumentError, "Unknown tour element: #{inspect(name)}"
    end
  end

  @doc """
  Returns all available tour element names.
  """
  @spec names() :: [atom()]
  def names, do: Map.keys(@elements)

  @doc """
  Returns the full map of element names to IDs.
  """
  @spec all() :: %{atom() => String.t()}
  def all, do: @elements
end
