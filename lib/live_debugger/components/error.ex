defmodule LiveDebugger.Components.Error do
  @moduledoc false

  use LiveDebuggerWeb, :component

  slot(:heading, required: true)
  slot(:description)

  def error_component(assigns) do
    ~H"""
    <div class="h-full flex flex-col items-center justify-center mx-8 text-center">
      <.icon name="icon-exclamation-circle" class="w-12 h-12 text-primary-900" />
      <div class="font-semibold text-xl mb-2">
        <%= render_slot(@heading) %>
      </div>
      <p class="mb-4"><%= render_slot(@description) %></p>
      <.link navigate="/">
        <.button>
          See active LiveViews
        </.button>
      </.link>
    </div>
    """
  end

  def not_found_component(assigns) do
    ~H"""
    <.error_component>
      <:heading>Debugger disconnected</:heading>
      <:description>We couldn't find any LiveView associated with the given socket id</:description>
    </.error_component>
    """
  end

  def unexpected_error_component(assigns) do
    ~H"""
    <.error_component>
      <:heading>Unexpected error</:heading>
      <:description>
        Debugger encountered unexpected error. Check logs for more information
      </:description>
    </.error_component>
    """
  end

  def session_limit_component(assigns) do
    ~H"""
    <.error_component>
      <:heading>Session limit reached</:heading>
      <:description>In OTP 26 and older versions you can open only one debugger window</:description>
    </.error_component>
    """
  end
end
