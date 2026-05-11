defmodule LiveDebugger.API.System.Dbg do
  @moduledoc """
  API for interacting with Erlang's tracing functionalities.

  The implementation uses `:erlang.trace/3` and `:erlang.trace_pattern/3` BIFs
  directly (instead of going through `:dbg`) to reduce per-message overhead in
  the tracer. The public surface and trace message shape are preserved so that
  the rest of the CallbackTracer stack is unaffected.

  ## Usage
  1. If you want to trace callbacks you need to start tracer using `tracer/1` function.
  Do not start it multiple times, as it will return an error if the tracer is already running.
  2. Then using `process/1` you can enable tracing for all processes in the system.
  3. To add a trace pattern for a specific function or module, use `trace_pattern/2`.
  If you want to trace more information you can pass `match_spec` created with `flag_to_match_spec/1` function.
  """

  @tracing_flags [:return_trace, :exception_trace]

  @type handler_spec() :: {handler_fun(), initial_data :: term()}
  @type handler_fun() :: (event :: term(), data :: term() -> new_data :: term())

  @callback tracer(handler :: handler_spec()) :: {:ok, pid()} | {:error, term()}
  @callback process(flags :: list()) :: {:ok, term()} | {:error, term()}
  @callback process(pid(), flags :: list()) :: {:ok, term()} | {:error, term()}
  @callback trace_pattern(module() | mfa(), match_spec :: term()) ::
              {:ok, term()} | {:error, term()}
  @callback clear_trace_pattern(module() | mfa()) :: {:ok, term()} | {:error, term()}
  @callback stop() :: :ok

  @doc """
  Starts a tracer process and returns its PID.
  When a tracer is already started, returns an error.

  The tracer is a plain Erlang process that loops on `receive` and calls
  the supplied handler for every trace message produced by the BEAM tracing
  BIFs. This mirrors what `:dbg.tracer(:process, handler)` did, but without
  the `:dbg` server in the middle.
  """
  @spec tracer(handler_spec()) :: {:ok, pid()} | {:error, term()}
  def tracer(handler_spec), do: impl().tracer(handler_spec)

  @doc """
  Enables tracing for all processes in the system using `:erlang.trace/3`.

  Accepts the same short flag mnemonics as `:dbg.p/2` (e.g. `:c`, `:s`, `:p`)
  for compatibility with the existing call sites; they are translated into
  the BIF's full flag names internally. Long names (e.g. `:call`, `:timestamp`,
  `:procs`) pass through unchanged.
  """
  @spec process(flags :: list()) :: {:ok, term()} | {:error, term()}
  def process(flags) when is_list(flags) do
    impl().process(flags)
  end

  @doc """
  Enables tracing for a specific process using `:erlang.trace/3`.
  """
  @spec process(pid(), flags :: list()) :: {:ok, term()} | {:error, term()}
  def process(pid, flags) when is_list(flags) and is_pid(pid) do
    impl().process(pid, flags)
  end

  @doc """
  Adds a trace pattern for the specified module or MFA (Module, Function, Arity).
  This is a wrapper for `:erlang.trace_pattern/3` with `:global` scope.
  You can create proper `match_spec` by using `flag_to_match_spec/1` function.
  """
  @spec trace_pattern(module() | mfa(), match_spec :: term()) ::
          {:ok, term()} | {:error, term()}
  def trace_pattern(module_or_mfa, match_spec \\ []) when is_list(match_spec) do
    impl().trace_pattern(module_or_mfa, match_spec)
  end

  @doc """
  Removes a trace pattern for the specified module or MFA (Module, Function, Arity).
  This is a wrapper for `:erlang.trace_pattern/3` with `false` match spec.
  """
  @spec clear_trace_pattern(module() | mfa()) :: {:ok, term()} | {:error, term()}
  def clear_trace_pattern(module_or_mfa) do
    impl().clear_trace_pattern(module_or_mfa)
  end

  @doc """
  Stops the tracer process and clears all active trace flags and patterns.
  """
  @spec stop() :: :ok
  def stop() do
    impl().stop()
  end

  @doc """
  Converts flag to `match_spec` format used by `trace_pattern/2`.
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

    # Registered name of the tracer process. The `process/1,2` calls look it
    # up here because `:erlang.trace/3` requires the tracer pid to be passed
    # alongside the trace flags.
    @tracer_name :live_debugger_tracer

    # Translation table for the short flag mnemonics historically accepted by
    # `:dbg.p/2`. Long names pass through unchanged via the default branch in
    # `translate_flag/1`.
    @flag_translation %{
      s: :send,
      r: :receive,
      m: :messages,
      c: :call,
      p: :procs,
      sos: :set_on_spawn,
      sol: :set_on_link,
      sofs: :set_on_first_spawn,
      sofl: :set_on_first_link
    }

    @impl true
    def tracer({handler_fun, initial_data})
        when is_function(handler_fun, 2) do
      case Process.whereis(@tracer_name) do
        nil ->
          parent = self()
          ref = make_ref()

          pid =
            :erlang.spawn(fn ->
              Process.register(self(), @tracer_name)
              send(parent, {:tracer_ready, ref})
              loop(handler_fun, initial_data)
            end)

          receive do
            {:tracer_ready, ^ref} -> {:ok, pid}
          after
            5_000 ->
              Process.exit(pid, :kill)
              {:error, :tracer_setup_timeout}
          end

        _existing ->
          {:error, :already_started}
      end
    end

    @impl true
    def process(flags), do: do_process(:all, flags)

    @impl true
    def process(pid, flags), do: do_process(pid, flags)

    @impl true
    def trace_pattern(pattern, match_spec) do
      result = :erlang.trace_pattern(normalize_pattern(pattern), match_spec, [])
      {:ok, result}
    catch
      kind, reason -> {:error, {kind, reason}}
    end

    @impl true
    def clear_trace_pattern(pattern) do
      result = :erlang.trace_pattern(normalize_pattern(pattern), false, [])
      {:ok, result}
    catch
      kind, reason -> {:error, {kind, reason}}
    end

    @impl true
    def stop() do
      safe(fn -> :erlang.trace(:all, false, [:all]) end)
      safe(fn -> :erlang.trace_pattern({:_, :_, :_}, false, []) end)
      safe(fn -> :erlang.trace_pattern({:_, :_, :_}, false, [:local]) end)

      case Process.whereis(@tracer_name) do
        nil ->
          :ok

        pid ->
          ref = Process.monitor(pid)
          send(pid, :stop)

          receive do
            {:DOWN, ^ref, _, _, _} -> :ok
          after
            1_000 ->
              Process.exit(pid, :kill)
              :ok
          end
      end
    end

    # Tracer process loop. Receives raw trace tuples from the BEAM and
    # dispatches them to the user-provided handler, threading state through
    # each call. A `:stop` message terminates the loop with reason `:done`,
    # which is what the existing `TracingManager` expects on the monitor's
    # `:DOWN` message.
    defp loop(handler_fun, data) do
      receive do
        :stop ->
          exit(:done)

        msg ->
          new_data = handler_fun.(msg, data)
          loop(handler_fun, new_data)
      end
    end

    defp do_process(target, flags) do
      case Process.whereis(@tracer_name) do
        nil ->
          {:error, :tracer_not_started}

        tracer ->
          result =
            :erlang.trace(target, true, [{:tracer, tracer} | translate_flags(flags)])

          {:ok, result}
      end
    catch
      kind, reason -> {:error, {kind, reason}}
    end

    defp normalize_pattern({_mod, _fun, _arity} = mfa), do: mfa
    defp normalize_pattern(module) when is_atom(module), do: {module, :_, :_}

    defp translate_flags(flags), do: Enum.map(flags, &translate_flag/1)
    defp translate_flag(flag), do: Map.get(@flag_translation, flag, flag)

    defp safe(fun) do
      fun.()
      :ok
    catch
      _, _ -> :ok
    end
  end
end
