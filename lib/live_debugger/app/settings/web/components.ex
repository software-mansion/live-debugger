defmodule LiveDebugger.App.Settings.Web.Components do
  @moduledoc """
  Components used in the settings page of the LiveDebugger application.
  """

  use LiveDebugger.App.Web, :component

  attr(:id, :string, required: true)
  attr(:label, :string, required: true)
  attr(:description, :string, required: true)
  attr(:checked, :boolean, default: false)
  attr(:rest, :global)

  def settings_switch(assigns) do
    ~H"""
    <div class="flex items-center">
      <.toggle_switch id={@id} checked={@checked} wrapper_class="pr-3 py-0" {@rest} />
      <div class="flex flex-col gap-0.5">
        <p class="font-semibold"><%= @label %></p>
        <p class="text-secondary-text"><%= @description %></p>
      </div>
    </div>
    """
  end

  def dark_mode_button(assigns) do
    ~H"""
    <.mode_button
      id="dark-mode-switch"
      icon="icon-moon"
      text="Dark"
      class="dark:hidden text-button-secondary-content bg-button-secondary-bg hover:bg-button-secondary-bg-hover border border-default-border"
      phx-hook="ToggleTheme"
    />
    <.mode_button
      icon="icon-moon"
      text="Dark"
      disabled
      class="hidden dark:flex text-button-primary-content bg-button-primary-bg"
    />
    """
  end

  def light_mode_button(assigns) do
    ~H"""
    <.mode_button
      id="light-mode-switch"
      icon="icon-sun"
      text="Light"
      class="hidden dark:flex text-button-secondary-content bg-button-secondary-bg hover:bg-button-secondary-bg-hover border border-default-border"
      phx-hook="ToggleTheme"
    />
    <.mode_button
      icon="icon-sun"
      text="Light"
      disabled
      class="dark:hidden text-button-primary-content bg-button-primary-bg"
    />
    """
  end

  attr(:icon, :string, required: true)
  attr(:text, :string, required: true)
  attr(:class, :string, default: "")
  attr(:rest, :global, include: ~w(disabled))

  defp mode_button(assigns) do
    ~H"""
    <button
      class={[
        "flex items-center justify-center gap-2 py-2 px-4 rounded",
        @class
      ]}
      {@rest}
    >
      <.icon name={@icon} class="w-5 h-5" />
      <p><%= @text %></p>
    </button>
    """
  end
end
