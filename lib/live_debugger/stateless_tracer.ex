defmodule LiveDebugger.StatelessTracer do
  def trace(
        {:remote_macro, meta, Phoenix.Component.Declarative, :__pattern__!, 2},
        env
      ) do
    IO.inspect("[TRACER] ~H macro   #{env.file}:#{env.line}")
    dbg(meta)
    :ok
  end

  def trace(
        {:remote_macro, meta, module, function, arity},
        env
      ) do
    IO.inspect("[TRACER] remote_macro #{module}.#{function}/#{arity} #{env.file}:#{env.line}}")
    dbg(meta)
    :ok
  end

  def trace(
        {:imported_macro, meta, module, function, arity},
        env
      ) do
    IO.inspect("[TRACER] imported_macro #{module}.#{function}/#{arity} #{env.file}:#{env.line}")
    dbg(meta)
    :ok
  end

  def trace(
        {:imported_quoted, meta, module, name, [arity]},
        env
      ) do
    IO.inspect("[TRACER] quoted #{module}.#{name}/#{arity} #{env.file}:#{env.line}")
    dbg(meta)
    :ok
  end

  # def trace({:remote_function, meta, Map, :get, arity}, env) when arity in [2, 3] do
  #   IO.puts("""
  #   [TRACER] Map.get/#{arity} called at #{env.file}:#{meta[:line] || env.line}
  #   """)

  #   :ok
  # end

  # def trace({:remote_macro, meta, Phoenix.Component.Declarative, :__pattern__!, 2}, env) do
  #   IO.inspect("[TRACER] function}  #{env.file}:#{env.line}}")

  #   :ok
  # end

  def trace(_event, _env), do: :ok
end
