# Services

Long-running, side-effecting subsystems.
Each service owns one concern, runs under its own supervisor, and communicates with the rest of LiveDebugger via `LiveDebugger.Bus`.

## File / folder structure

Each service lives in its own directory and follows the same skeleton:

```text
services/<service_name>/
├── supervisor.ex         # entry point in the app tree which is registered
├── events.ex             # event structs this service publishes (Bus payloads)
├── gen_servers/          # processes owned by this service
│   └── *.ex
├── actions/              # side-effect-performing functions (write to ETS, broadcast, …)
├── queries/              # read-only functions (lookups, aggregations)
└── README.md             # one-paragraph overview of the service
```

Not every service has every directory — they are added when more files are needed.

## Communication between services

Services should **not** call each other. Cross-service communication goes through `LiveDebugger.Bus` (built on `Phoenix.PubSub`). There are 3 topics to use.

- `lvdbg/*` — general events
- `lvdbg/traces/*` — trace data
- `lvdbg/states/*` — LiveView state snapshots

The wildcard segment is usually a pid (debugged process or debugger LV) so subscribers can scope to a single target.

## List of services

### CallbackTracer

Sets up `:dbg.tracer`, monitors and manages it, parses raw traces, and broadcasts them on the bus.
Reacts to module recompilations by re-applying trace patterns.
GenServers: `TracingManager` (lifecycle), `TraceHandler` (parse + persist + broadcast).

### ClientCommunicator

Owns the Phoenix channel used by the debugged app's browser-side `client.js`.
Forwards messages between the debugger and the client (highlight node, inspect element, redirect).
GenServer: `ClientCommunicator`.

### GarbageCollector

Periodically trims ETS tables (traces, states) to stay within configured size limits and deletes tables for processes nobody is watching.
GenServers: `GarbageCollector` (scheduler), `TableWatcher` (per-table observer).

### ProcessMonitor

Watches the BEAM for LiveView process births and deaths and emits `LiveViewBorn` / `LiveViewDied` events.
GenServers: `DebuggedProcessesMonitor`, `DebuggerProcessesMonitor`.

### SuccessorDiscoverer

When a LiveView dies (e.g. page reload) a new one usually replaces it almost immediately.
This service finds the successor in the same browser window so the debugger can switch to it without the user noticing the gap.
GenServer: `SuccessorDiscoverer`.

### TelemetryHandler

Attaches to `:telemetry` events emitted by Phoenix/LiveView and republishes the relevant ones on the bus.
GenServer: `TelemetryHandler`.

## Adding a new service

- Create `services/<name>/` with `supervisor.ex`.
- Put processes in `gen_servers/`, side effects in `actions/`, lookups in `queries/`.
- Add the supervisor to the application tree (`lib/live_debugger/services.ex`).
- Subscribe to the bus from inside your GenServer if you need to react to other services' events.
- Define event structs in `events.ex` if you emit something.
- Add a `README.md` summarizing what the service does and why.
