defmodule LiveDebugger.Services.System.DbgService do
  @moduledoc """
  This module provides wrappers for system functions that are used for debugging.
  """

  @callback tracer(:process, handlerSpec) :: {:ok, pid()} | {:error, error :: term()}
            when handlerSpec: {handlerFun, initialData :: term()},
                 handlerFun: (event :: term(), data :: term() -> newData :: term())
  @callback p(item :: term(), flags :: term()) :: {:ok, matchDesc} | {:error, term()}
            when matchDesc: [matchNum],
                 matchNum: {:matched, node(), integer()} | {:matched, node(), 0, rPCError},
                 rPCError: term()
  @callback tp(module | {module, function, arity}, matchSpec :: term()) ::
              {:ok, matchDesc :: term()} | {:error, term()}

  @doc """
  Wrapper for `:dbg.tracer/2` that starts a tracer for the given type and handler specification.
  """
  @spec tracer(:process, handlerSpec) :: {:ok, pid()} | {:error, error :: term()}
        when handlerSpec: {handlerFun, initialData :: term()},
             handlerFun: (event :: term(), data :: term() -> newData :: term())
  def tracer(type, handler_spec) do
    impl().tracer(type, handler_spec)
  end

  @doc """
  Wrapper for `:dbg.p/2`.
  Traces `Item` in accordance to the value specified by `Flags`.
  `p` stands for **p**rocess.
  """
  @spec p(item :: term(), flags :: term()) :: {:ok, matchDesc} | {:error, term()}
        when matchDesc: [matchNum],
             matchNum: {:matched, node(), integer()} | {:matched, node(), 0, rPCError},
             rPCError: term()
  def p(item, flags) do
    impl().p(item, flags)
  end

  @doc """
  Wrapper for `:dbg.tp/2` that sets up a trace pattern.
  Enables call trace for one or more exported functions specified by `ModuleOrMFA`.
  """
  @spec tp(module | {module, function, arity}, matchSpec :: term()) ::
          {:ok, matchDesc :: term()} | {:error, term()}
  def tp(module, match_spec) do
    impl().tp(module, match_spec)
  end

  defp impl() do
    Application.get_env(
      :live_debugger,
      :dbg_service,
      __MODULE__.Impl
    )
  end

  defmodule Impl do
    @moduledoc false
    @behaviour LiveDebugger.Services.System.DbgService

    @impl true
    def tracer(type, handler_spec) do
      :dbg.tracer(type, handler_spec)
    end

    @impl true
    def p(item, flags) do
      :dbg.p(item, flags)
    end

    @impl true
    def tp(module, match_spec) do
      :dbg.tp(module, match_spec)
    end
  end
end
