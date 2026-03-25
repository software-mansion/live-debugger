defmodule LiveDebugger.Utils.FunctionMatcher do
  @moduledoc """
  https://github.com/elixir-lang/elixir/blob/v1.20.0-rc.3/lib/elixir/lib/exception.ex#L245
  """
  alias LiveDebugger.Structs.Trace.FunctionTrace.SourceLocation

  def find_matching_clause_line(module, function_name, args) do
    with {:ok, clauses} <- get_function_clauses(module, function_name, length(args)),
         {:ok, matching} <- find_matching(clauses, args),
         {:ok, file_path} <- get_module_file(module) do
      {:ok, %SourceLocation{source_file: file_path, line: matching.line}}
    end
  end

  defp get_function_clauses(module, function_name, arity) do
    with [_ | _] = path <- :code.which(module),
         {:ok, {_, [debug_info: debug_info]}} <- :beam_lib.chunks(path, [:debug_info]),
         {:debug_info_v1, backend, data} <- debug_info,
         {:ok, %{definitions: defs}} <- backend.debug_info(:elixir_v1, module, data, []),
         {_, _kind, _, clauses} <- List.keyfind(defs, {function_name, arity}, 0) do
      enriched =
        for {meta, ex_args, guards, _body} <- clauses do
          scope = :elixir_erl.scope(meta, true)
          ann = :elixir_erl.get_ann(meta)

          {erl_args, scope} =
            :elixir_erl_clauses.match(
              ann,
              &:elixir_erl_pass.translate_args/3,
              ex_args,
              scope
            )

          erl_guards =
            Enum.map(guards, fn guard ->
              {erl_guard, _scope} = :elixir_erl_pass.translate(guard, ann, scope)
              erl_guard
            end)

          %{
            line: Keyword.get(meta, :line, 0),
            erl_args: erl_args,
            erl_guards: erl_guards
          }
        end

      {:ok, enriched}
    else
      _ -> {:error, :cannot_read_debug_info}
    end
  end

  defp find_matching(clauses, args) do
    Enum.find_value(clauses, {:error, :no_matching_clause}, fn clause ->
      case try_match_clause(clause, args) do
        true -> {:ok, clause}
        false -> false
      end
    end)
  end

  defp try_match_clause(clause, args) do
    try do
      ann = :erl_anno.new(0)

      binding = :orddict.store(:VAR, List.to_tuple(args), [])

      pattern_tuple = {:tuple, ann, clause.erl_args}

      {:value, _, binding} =
        :erl_eval.expr({:match, ann, pattern_tuple, {:var, ann, :VAR}}, binding, :none)

      check_guards(clause.erl_guards, binding)
    rescue
      _ -> false
    catch
      _, _ -> false
    end
  end

  defp check_guards([], _binding), do: true

  defp check_guards(guards, binding) do
    Enum.any?(guards, fn guard ->
      try do
        {:value, true, _} = :erl_eval.expr(guard, binding, :none)
        true
      rescue
        _ -> false
      catch
        _, _ -> false
      end
    end)
  end

  defp get_module_file(module) do
    case module.module_info(:compile)[:source] do
      nil -> {:error, :module_file_not_found}
      source -> {:ok, List.to_string(source)}
    end
  end
end
