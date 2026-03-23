defmodule LiveDebugger.Utils.FunctionMatcher do
  def find_matching_clause_line(module, function_name, args) do
    with {:ok, patterns} <- get_function_patterns(module, function_name, length(args)),
         {:ok, matching_clause} <- find_matching_pattern(patterns, args),
         {:ok, file_path} <- get_module_file(module) do
      {:ok, %{file: file_path, line: matching_clause.line}}
    else
      error -> error
    end
  end

  defp get_function_patterns(module, function_name, arity) do
    try do
      beam_file = :code.which(module)
      {:ok, {^module, [{:debug_info, debug_info}]}} = :beam_lib.chunks(beam_file, [:debug_info])
      dbg(module.__info__(:attributes))
      # dbg(beam_file)
      # dbg(debug_info)
      # dbg(Code.fetch_docs(module))

      case debug_info do
        {:debug_info_v1, :elixir_erl, {_version, %{definitions: definitions}, _}} ->
          dbg(definitions)
          patterns = extract_function_clauses(definitions, function_name, arity)

          if Enum.empty?(patterns) do
            {:error, :function_not_found}
          else
            {:ok, patterns}
          end

        {:debug_info_v1, backend, metadata} ->
          {:error, {:unsupported_backend, backend, metadata}}

        other ->
          {:error, {:unsupported_debug_info_format, other}}
      end
    rescue
      error -> {:error, {:exception, error}}
    end
  end

  defp extract_function_clauses(definitions, target_fun, target_arity) do
    definitions
    |> Enum.find_value([], fn
      {{^target_fun, ^target_arity}, _kind, _meta, clauses} ->
        dbg(clauses)
        extract_clause_info(clauses)
        dbg(extract_clause_info(clauses))

      _ ->
        false
    end)
  end

  defp extract_clause_info(clauses) do
    clauses
    |> Enum.with_index(1)
    |> Enum.map(fn {{meta, args, _guards, _body}, clause_num} ->
      %{
        clause: clause_num,
        line: Keyword.get(meta, :line, 0),
        patterns: args
      }
    end)
  end

  defp find_matching_pattern(patterns, args) do
    case Enum.find(patterns, &pattern_matches?(&1.patterns, args)) do
      nil -> {:error, :no_matching_clause}
      matching_clause -> {:ok, matching_clause}
    end
  end

  defp pattern_matches?(ast_patterns, real_args) do
    try do
      patterns = Enum.map(ast_patterns, &elixir_ast_to_pattern/1)
      test_match(patterns, real_args)
    rescue
      _ -> false
    end
  end

  defp elixir_ast_to_pattern(ast) do
    case ast do
      atom when is_atom(atom) ->
        atom

      number when is_number(number) ->
        number

      string when is_binary(string) ->
        string

      {var_name, _meta, nil} when is_atom(var_name) ->
        :_

      {:{}, _meta, elements} ->
        elements
        |> Enum.map(&elixir_ast_to_pattern/1)
        |> List.to_tuple()

      {left, right} ->
        {elixir_ast_to_pattern(left), elixir_ast_to_pattern(right)}

      list when is_list(list) ->
        Enum.map(list, &elixir_ast_to_pattern/1)

      {:%{}, _meta, fields} ->
        fields
        |> Enum.map(fn {key, value} ->
          {elixir_ast_to_pattern(key), elixir_ast_to_pattern(value)}
        end)
        |> Map.new()

      {:%, _meta, [struct_name, {:%{}, _, fields}]} ->
        field_map =
          fields
          |> Enum.map(fn {key, value} ->
            {elixir_ast_to_pattern(key), elixir_ast_to_pattern(value)}
          end)
          |> Map.new()

        {:__struct__, struct_name, field_map}

      {:^, _meta, [var]} ->
        elixir_ast_to_pattern(var)

      _ ->
        :_
    end
  end

  defp test_match(patterns, args) when length(patterns) != length(args), do: false

  defp test_match(patterns, args) do
    Enum.zip(patterns, args)
    |> Enum.all?(fn {pattern, arg} -> matches_value?(pattern, arg) end)
  end

  defp matches_value?(:_, _), do: true
  defp matches_value?(pattern, value) when pattern == value, do: true

  defp matches_value?({:__struct__, struct_name, field_map}, value) when is_struct(value) do
    value.__struct__ == struct_name and
      Enum.all?(field_map, fn {k, v} ->
        matches_value?(v, Map.get(value, k))
      end)
  end

  defp matches_value?(pattern_tuple, value_tuple)
       when is_tuple(pattern_tuple) and is_tuple(value_tuple) do
    if tuple_size(pattern_tuple) == tuple_size(value_tuple) do
      pattern_list = Tuple.to_list(pattern_tuple)
      value_list = Tuple.to_list(value_tuple)
      test_match(pattern_list, value_list)
    else
      false
    end
  end

  defp matches_value?(pattern_map, value_map) when is_map(pattern_map) and is_map(value_map) do
    Enum.all?(pattern_map, fn {k, v} ->
      Map.has_key?(value_map, k) and matches_value?(v, Map.get(value_map, k))
    end)
  end

  defp matches_value?(pattern_list, value_list)
       when is_list(pattern_list) and is_list(value_list) do
    length(pattern_list) == length(value_list) and
      test_match(pattern_list, value_list)
  end

  defp matches_value?(_, _), do: false
  # refactor
  defp get_module_file(module) do
    case :code.which(module) do
      :non_existing ->
        {:error, :module_file_not_found}

      beam_file ->
        source_file = get_source_file_from_beam(beam_file)
        {:ok, source_file}
    end
  end

  defp get_source_file_from_beam(beam_file) do
    try do
      {:ok, {_module, [{:compile_info, compile_info}]}} =
        :beam_lib.chunks(beam_file, [:compile_info])

      case Keyword.get(compile_info, :source) do
        # Fallback to beam file
        nil -> List.to_string(beam_file)
        source_path -> List.to_string(source_path)
      end
    rescue
      # Fallback to beam file
      _ -> List.to_string(beam_file)
    end
  end
end
