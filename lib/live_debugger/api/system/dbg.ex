defmodule LiveDebugger.API.System.Dbg do
  @moduledoc """
  API for interacting with the Erlang's `:dbg` tracing functionalities.

  ## Usage
  1. If you want to trace callbacks you need to start tracer using `tracer/1` function.
  Do not start it multiple times, as it will return an error if the tracer is already running.
  2. Then using `process/1` you can enable tracing for all processes in the system.
  3. To add a trace pattern for a specific function or module, use `trace_pattern/2`.
  If you want to trace more information you can pass `match_spec` created with `flags_to_match_spec/1` function.
  """

  @tracing_flags [:return_trace, :exception_trace]

  @type handler_spec() :: {handler_fun(), initial_data :: term()}
  @type handler_fun() :: (event :: term(), data :: term() -> new_data :: term())

  @callback tracer(handler :: handler_spec()) :: {:ok, pid()} | {:error, term()}
  @callback process(flags :: list()) :: {:ok, term()} | {:error, term()}
  @callback trace_pattern(module() | mfa(), match_spec :: term()) ::
              {:ok, term()} | {:error, term()}
  @callback clear_trace_pattern(module() | mfa()) :: {:ok, term()} | {:error, term()}

  @doc """
  Starts tracer process and returns its PID.
  When tracer is already started, it returns error.
  It uses `:dbg.tracer/2` under the hood.
  """
  @spec tracer(handler_spec()) :: {:ok, pid()} | {:error, term()}
  def tracer(handler_spec), do: impl().tracer(handler_spec)

  @doc """
  Enables tracing for all processes in the system.

  For list of supported flags, see `:dbg.p/2`.
  """
  @spec process(flags :: list()) :: {:ok, term()} | {:error, term()}
  def process(flags \\ []) when is_list(flags) do
    impl().process(flags)
  end

  @doc """
  This is a wrapper for `:dbg.tp/2`.
  Adds a trace pattern for the specified module or MFA (Module, Function, Arity).
  You can create proper `match_spec` by using `flags_to_match_spec/1` function.
  """
  @spec trace_pattern(module() | mfa(), match_spec :: term()) ::
          {:ok, term()} | {:error, term()}
  def trace_pattern(module_or_mfa, match_spec \\ []) when is_list(match_spec) do
    impl().trace_pattern(module_or_mfa, match_spec)
  end

  @doc """
  Removes a trace pattern for the specified module or MFA (Module, Function, Arity).
  This is a wrapper for `:dbg.ctp/1`.
  """
  @spec clear_trace_pattern(module() | mfa()) :: {:ok, term()} | {:error, term()}
  def clear_trace_pattern(module_or_mfa) do
    impl().clear_trace_pattern(module_or_mfa)
  end

  @doc """
  Converts flag to `match_spec` format used by `tp/2` function.
  Available flags are: #{Enum.map_join(@tracing_flags, ", ", &"`:#{&1}`")}
  """
  @spec flag_to_match_spec(flag :: atom()) :: term()
  def flag_to_match_spec(flag) when flag in @tracing_flags do
    [{:_, [], [{flag}]}]
  end

  defp impl() do
    Application.get_env(
      :live_debugger,
      :api_dbg,
      __MODULE__.Impl
    )
  end

  defmodule Impl do
    @moduledoc false
    @behaviour LiveDebugger.API.System.Dbg

    @impl true
    def tracer(handler) do
      :dbg.tracer(:process, handler)
    end

    @impl true
    def process(flags) do
      :dbg.p(:all, flags)
    end

    @impl true
    def trace_pattern(pattern, match_spec) do
      :dbg.tp(pattern, match_spec)
    end

    @impl true
    def clear_trace_pattern(pattern) do
      :dbg.ctp(pattern)
    end
  end
end
