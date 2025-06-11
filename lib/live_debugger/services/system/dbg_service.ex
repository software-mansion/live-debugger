defmodule LiveDebugger.Services.System.DbgService do
  @moduledoc """
  This module provides wrappers for system functions that are used for debugging.
  """

  @type port_generator() :: (-> port())
  @type handler_spec() :: {handler_fun(), initial_data :: term()}
  @type handler_fun() :: (event :: term(), data :: term() -> new_data :: term())
  @type module_spec() ::
          (-> {tracer_module :: atom(), tracer_state :: term()})
          | {tracer_module :: atom(), tracer_state :: term()}

  @callback tracer(:port, port_generator()) :: {:ok, pid()} | {:error, term()}
  @callback tracer(:process, handler_spec()) :: {:ok, pid()} | {:error, term()}
  @callback tracer(:module, module_spec()) :: {:ok, pid()} | {:error, term()}
  @callback tracer(:file, filename :: :file.name_all()) :: {:ok, pid()} | {:error, term()}

  @type match_desc() :: [match_num()]
  @type match_num() :: {:matched, node(), integer()} | {:matched, node(), 0, rPCError :: term()}

  @callback p(item :: term(), flags :: term()) :: {:ok, match_desc()} | {:error, term()}

  @callback tp(module() | mfa(), match_spec :: term()) :: {:ok, match_desc()} | {:error, term()}

  @callback ctp(module() | mfa(), match_spec :: term()) :: {:ok, match_desc()} | {:error, term()}

  @doc """
  Wrapper for `:dbg.tracer/2` that starts a tracer for the given type and handler specification.
  """
  @spec tracer(:port, port_generator()) :: {:ok, pid()} | {:error, term()}
  @spec tracer(:process, handler_spec()) :: {:ok, pid()} | {:error, term()}
  @spec tracer(:module, module_spec()) :: {:ok, pid()} | {:error, term()}
  @spec tracer(:file, filename :: :file.name_all()) :: {:ok, pid()} | {:error, term()}
  def tracer(type, handler_spec), do: impl().tracer(type, handler_spec)

  @doc """
  Wrapper for `:dbg.p/2`.
  Traces `Item` in accordance to the value specified by `Flags`.
  `p` stands for **p**rocess.
  """
  @spec p(item :: term(), flags :: term()) :: {:ok, match_desc()} | {:error, term()}
  def p(item, flags), do: impl().p(item, flags)

  @doc """
  Wrapper for `:dbg.tp/2` that sets up a trace pattern.
  Enables call trace for one or more exported functions specified by `ModuleOrMFA`.
  """
  @spec tp(module() | mfa(), match_spec :: term()) :: {:ok, match_desc()} | {:error, term()}
  def tp(module, match_spec), do: impl().tp(module, match_spec)

  @doc """
  Wrapper for `:dbg.ctp/2` that ends tracing for given pattern
  """
  @spec ctp(module() | mfa(), match_spec :: term()) :: {:ok, match_desc()} | {:error, term()}
  def ctp(module, match_spec), do: impl().ctp(module, match_spec)

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

    @impl true
    def ctp(module, match_spec) do
      :dbg.ctp(module, match_spec)
    end
  end
end
