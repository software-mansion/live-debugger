defmodule LiveDebugger.Services.CallbackTracer.Queries.Paths do
  @moduledoc """
  Queries the paths of the traced modules.
  """

  alias LiveDebugger.API.System.Module, as: ModuleAPI
  alias LiveDebugger.Utils.Modules, as: UtilsModules

  @doc """
  Returns a list of all paths of the traced modules.
  """
  @spec all_paths() :: [String.t()]
  def all_paths() do
    ModuleAPI.all()
    |> Enum.map(fn {module_charlist, compiled_path, _} ->
      {module_charlist |> to_string |> String.to_atom(), to_string(compiled_path)}
    end)
    |> Enum.filter(&loaded?/1)
    |> Enum.reject(&debugger_module?/1)
    |> Enum.filter(&live_module?/1)
    |> Enum.map(fn {_, file_path} -> Path.dirname(file_path) end)
    |> Enum.uniq()
  end

  defp loaded?({module, _}), do: ModuleAPI.loaded?(module)
  defp debugger_module?({module, _}), do: UtilsModules.debugger_module?(module)
  defp live_module?({module, _}), do: ModuleAPI.live_module?(module)
end
