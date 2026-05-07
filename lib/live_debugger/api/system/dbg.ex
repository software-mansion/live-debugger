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
  @type port_fun() :: (-> port())
  @type ip_params() :: :inet.port_number() | {:inet.port_number(), pos_integer()}

  @callback tracer(:process, handler :: handler_spec()) :: {:ok, pid()} | {:error, term()}
  @callback tracer(:port, port_fun()) :: {:ok, pid()} | {:error, term()}
  @callback trace_port(type :: :ip, params :: ip_params()) :: port_fun()
  @callback trace_client(
              type :: :ip,
              params :: {:inet.hostname() | :inet.ip_address(), :inet.port_number()},
              handler :: handler_spec()
            ) :: pid()
  @callback process(flags :: list()) :: {:ok, term()} | {:error, term()}
  @callback process(pid(), flags :: list()) :: {:ok, term()} | {:error, term()}
  @callback trace_pattern(module() | mfa(), match_spec :: term()) ::
              {:ok, term()} | {:error, term()}
  @callback clear_trace_pattern(module() | mfa()) :: {:ok, term()} | {:error, term()}
  @callback stop() :: :ok

  @doc """
  Starts a `:dbg` tracer.

    * `tracer(:process, handler_spec)` — events are delivered as Erlang
      messages to the handler running in the dbg-spawned tracer process.
      Higher overhead under burst because every event hits the Erlang
      process mailbox.

    * `tracer(:port, port_fun)` — events are encoded by a C port driver
      and written to the port's sink (TCP socket for `:ip`, file for
      `:file`), bypassing the Erlang process mailbox on the producer side.
      `port_fun` is typically obtained from `trace_port/2`.
  """
  @spec tracer(:process, handler_spec()) :: {:ok, pid()} | {:error, term()}
  @spec tracer(:port, port_fun()) :: {:ok, pid()} | {:error, term()}
  def tracer(mode, arg)
  def tracer(:process, handler_spec), do: impl().tracer(:process, handler_spec)

  def tracer(:port, port_fun) when is_function(port_fun, 0),
    do: impl().tracer(:port, port_fun)

  @doc """
  Returns a port generator fun for `:dbg.trace_port/2`.
  For `:ip`, accepts a port number (with default queue size) or
  `{port, queue_size}`. Pass `0` to bind to an OS-assigned port.
  """
  @spec trace_port(type :: :ip, params :: ip_params()) :: port_fun()
  def trace_port(type, params), do: impl().trace_port(type, params)

  @doc """
  Starts a trace client process that consumes events from the given source.
  For `:ip`, connects to the listening tracer port and invokes the handler
  per event. The handler also receives `{:drop, N}` tuples when the producer
  queue overflowed since the last delivery.
  """
  @spec trace_client(
          :ip,
          {:inet.hostname() | :inet.ip_address(), :inet.port_number()},
          handler_spec()
        ) :: pid()
  def trace_client(type, params, handler_spec),
    do: impl().trace_client(type, params, handler_spec)

  @doc """
  Enables tracing for all processes in the system.

  For list of supported flags, see `:dbg.p/2`.
  """
  @spec process(flags :: list()) :: {:ok, term()} | {:error, term()}
  def process(flags) when is_list(flags) do
    impl().process(flags)
  end

  @doc """
  Enables tracing for a specific process.
  """
  @spec process(pid(), flags :: list()) :: {:ok, term()} | {:error, term()}
  def process(pid, flags) when is_list(flags) and is_pid(pid) do
    impl().process(pid, flags)
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
  Stops dbg process.
  This is a wrapper for `:dbg.stop/0`
  """
  @spec stop() :: :ok
  def stop() do
    impl().stop()
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
    def tracer(:process, handler) do
      :dbg.tracer(:process, handler)
    end

    def tracer(:port, port_fun) do
      :dbg.tracer(:port, port_fun)
    end

    @impl true
    def trace_port(:ip, params) do
      :dbg.trace_port(:ip, params)
    end

    @impl true
    def trace_client(:ip, {host, port}, handler) do
      :dbg.trace_client(:ip, {host, port}, handler)
    end

    @impl true
    def process(flags) do
      :dbg.p(:all, flags)
    end

    @impl true
    def process(pid, flags) do
      :dbg.p(pid, flags)
    end

    @impl true
    def trace_pattern(pattern, match_spec) do
      :dbg.tp(pattern, match_spec)
    end

    @impl true
    def clear_trace_pattern(pattern) do
      :dbg.ctp(pattern)
    end

    @impl true
    def stop() do
      :dbg.stop()
    end
  end
end
