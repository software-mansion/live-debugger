# Because Phoenix works like Phoenix, this module needs to be named in this way
defmodule LiveDebugger.ErrorView do
  @moduledoc false

  def render(template, _), do: Phoenix.Controller.status_message_from_template(template)
end
