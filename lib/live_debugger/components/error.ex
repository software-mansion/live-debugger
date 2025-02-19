defmodule LiveDebugger.Components.Error do
  @moduledoc false

  use LiveDebuggerWeb, :component

  slot(:heading, required: true)
  slot(:description)
  slot(:bottom)

  def error_component(assigns) do
    ~H"""
    <div class="h-full flex flex-col items-center justify-center mx-8 text-center">
      <.icon name="icon-exclamation-circle" class="w-16 h-16" />
      <div class="text-2xl font-extrabold leading-10 sm:text-3xl">
        <%= render_slot(@heading) %>
      </div>
      <p class="text-base font-medium mb-4"><%= render_slot(@description) %></p>
      <%= render_slot(@bottom) %>
    </div>
    """
  end

  def not_found_component(assigns) do
    ~H"""
    <.error_component>
      <:heading>Debugger disconnected</:heading>
      <:description>We couldn't find any LiveView associated with the given socket id</:description>
      <:bottom>
        <.link navigate="/" class="underline">
          See available LiveSessions
        </.link>
      </:bottom>
    </.error_component>
    """
  end

  def unexpected_error_component(assigns) do
    ~H"""
    <.error_component>
      <:heading>Unexpected error</:heading>
      <:description>Debugger encountered unexpected error - check logs for more</:description>
      <:bottom>
        <.link navigate="/" class="underline">
          See available LiveSessions
        </.link>
      </:bottom>
    </.error_component>
    """
  end

  def session_limit_component(assigns) do
    ~H"""
    <.error_component>
      <:heading>Session limit reached</:heading>
      <:description>In OTP 26 and older versions you can open only one debugger window.</:description>
      <:bottom>
        <span>You can close this window</span>
      </:bottom>
    </.error_component>
    """
  end
end
