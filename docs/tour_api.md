# Tour API

The Tour API allows a client application to control the LiveDebugger UI remotely — spotlighting elements, highlighting components, and guiding users through interactive tours.

The API is exposed as `window.LiveDebuggerTour` in the client app's browser and communicates with the debugger via the existing WebSocket channel.

## Setup

The Tour API is automatically available when browser features are enabled. No additional configuration is needed — `LiveDebuggerTour` is set on `window` after the debug socket connects.

## Actions

### `spotlight(target, dismiss?)`

Dims everything except the target element. The target is elevated above a full-screen overlay, blocking interaction with the rest of the page.

```js
// Default dismiss: "click-target" — user must click the element
LiveDebuggerTour.spotlight("send-event-button");

// Dismiss on any click
LiveDebuggerTour.spotlight("navbar", "click-anywhere");
```

### `highlight(target, dismiss?)`

Outlines the target element without blocking the rest of the page.

```js
// Default dismiss: "click-anywhere"
LiveDebuggerTour.highlight("navbar-connected");

// Dismiss only when clicking the element
LiveDebuggerTour.highlight("send-event-button", "click-target");
```

### `clear()`

Removes all tour effects (highlights, spotlights, overlays).

```js
LiveDebuggerTour.clear();
```

## Dismiss Modes

| Mode | Behavior | Callback? |
|------|----------|-----------|
| `"click-anywhere"` | Clears on any click | No |
| `"click-target"` | Clears only when user clicks the target element | Yes — triggers `onStepCompleted` |

## Callbacks

### `onStepCompleted(fn)`

Called when the user completes a `"click-target"` step. Receives `{ target }` with the element ID.

```js
LiveDebuggerTour.onStepCompleted(({ target }) => {
  console.log("User clicked:", target);
});
```

### `onFetchCurrentStep(fn)`

Called when the debugger reloads and needs to restore the current tour step. Use this to re-send the active step so it survives page navigation.

```js
LiveDebuggerTour.onFetchCurrentStep(() => {
  // Re-send whatever step the tour is currently on
  LiveDebuggerTour.spotlight("send-event-button");
});
```

## Settings Control

Lock or unlock the debugger's settings page during a tour.

```js
LiveDebuggerTour.disableSettings(); // Disables all toggles, shows info banner
LiveDebuggerTour.enableSettings();  // Re-enables toggles
```

## Available Target Elements

Target elements are identified by their HTML `id`. See `LiveDebugger.TourElements` for the full map. Key targets:

| Name | ID | Description |
|------|----|-------------|
| Navbar | `navbar` | Top navigation bar |
| PID indicator | `navbar-connected` | Monitored PID / connection status |
| Return button | `return-button` | Back navigation button |
| Settings button | `settings-button` | Settings gear icon |
| Node basic info | `node-inspector-basic-info` | Module/path/type info panel |
| Send Event | `send-event-button` | "Send Event" button |
| Open in Editor | `open-in-editor` | "Open in Editor" button |
| Components Tree | `show-components-tree-button` | "Show Components Tree" button |
| Inspect button | `inspect-button-tooltip` | Element inspection toggle |

## Multi-Step Tour Example

```js
const steps = [
  { target: "navbar-connected", action: "spotlight" },
  { target: "send-event-button", action: "spotlight" },
  { target: "open-in-editor", action: "spotlight" },
];
let current = 0;

function showStep() {
  if (current >= steps.length) {
    LiveDebuggerTour.clear();
    return;
  }
  LiveDebuggerTour.spotlight(steps[current].target);
}

LiveDebuggerTour.onStepCompleted(() => {
  current++;
  showStep();
});

LiveDebuggerTour.onFetchCurrentStep(() => {
  // Restore after debugger reload
  showStep();
});

showStep();
```

## Elixir API (`LiveDebugger.Tour`)

For LiveView templates, use the Elixir adapter which returns `Phoenix.LiveView.JS` commands. No inline JavaScript needed.

```elixir
alias LiveDebugger.Tour

# In HEEx templates — use with phx-click, phx-mounted, etc.
<button phx-click={Tour.spotlight(:send_event_button)}>Click Send Event</button>
<button phx-click={Tour.highlight(:navbar_connected)}>Highlight PID</button>
<button phx-click={Tour.spotlight(:navbar, "click-anywhere")}>Spotlight Navbar</button>
<button phx-click={Tour.clear()}>Clear</button>

# Settings control
<button phx-click={Tour.enable_settings()}>Enable</button>
<button phx-click={Tour.disable_settings()}>Disable</button>
```

Accepts atom keys from `LiveDebugger.TourElements` (`:navbar`, `:send_event_button`, etc.) or raw string element IDs (`"my-custom-id"`).

## Architecture

```
Client App Browser
  │
  │  LiveDebuggerTour.spotlight("send-event-button")
  ↓
  debugChannel.push("tour:action", payload)
  ↓
Channel.handle_in("tour:" <> _)
  → PubSub broadcast to "client:tour:receive"
  ↓
DebuggerLive.handle_info({"tour:" <> _, payload})
  → push_event(socket, "tour-action", payload)
  ↓
Tour JS Hook (assets/app/hooks/tour.js)
  → applies CSS spotlight/highlight to target element
  ↓
User clicks target
  → hook pushEvent("step-completed", {target})
  ↓
DebuggerLive.handle_event("step-completed", payload)
  → Client.push_event!("step-completed", payload)
  ↓
Client App Browser
  → debugChannel.on("step-completed") → onStepCompleted callback
```

## Key Files

| File | Purpose |
|------|---------|
| `assets/client/services/tour.js` | Tour API module (exported as `window.LiveDebuggerTour`) |
| `assets/client/client.js` | Initializes tour, wires up channel |
| `assets/app/hooks/tour.js` | Debugger-side JS hook (applies CSS effects) |
| `assets/app/app.css` | Tour CSS classes (`.tour-highlight`, `.tour-overlay`, `.tour-spotlight-target`) |
| `lib/live_debugger/client/channel.ex` | Routes `tour:` messages to `client:tour:receive` PubSub |
| `lib/live_debugger/app/debugger/web/debugger_live.ex` | Subscribes to tour events, forwards to hook |
| `lib/live_debugger/tour.ex` | Elixir API — returns `JS.dispatch` commands for templates |
| `lib/tour_elements.ex` | Map of element names to HTML IDs |
