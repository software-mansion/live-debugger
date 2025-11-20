# Features Overview

LiveDebugger provides a comprehensive set of tools designed to improve Phoenix LiveView debugging and development. From real-time state inspection to performance profiling, these features give you deep visibility into your application's behavior.

## Features

### [Assigns Inspection](assigns_inspection.md)

Inspect the current state of assigns for any LiveView or LiveComponent in your application. Updated in real-time, this feature acts like a live `IO.inspect/1` with context, helping you track state changes, debug reactivity issues, and spot bugs faster.

**Key capabilities:**

- Real-time assign updates
- Copy assigns for IEx processing
- Expandable/collapsible complex data structures
- Immediate feedback on user interactions

### [Callback Tracing](callback_tracing.md)

See how functions in your LiveView application are being called with comprehensive tracing capabilities. Monitor all LiveView and LiveComponent callbacks with detailed execution information including timing, arguments, and execution flow.

**Key capabilities:**

- Filter by callback type, execution time, or search terms
- Detailed argument inspection with fullscreen view
- Copy callback arguments for terminal processing
- Support for all Phoenix.LiveView and Phoenix.LiveComponent callbacks

### [Components Highlighting](components_highlighting.md)

Visually identify and locate components rendered in your current debugged LiveView. Hover over component names in the tree to highlight their corresponding DOM elements in your application.

**Key capabilities:**

- Toggle highlighting mode on/off
- Hover-to-highlight functionality
- Non-intrusive visual feedback

### [Components Tree](components_tree.md)

Examine how LiveComponents are arranged in your debugged LiveView. The tree automatically updates when state changes, showing the complete hierarchy from LiveView root to all nested LiveComponents with their CIDs.

**Key capabilities:**

- Discover your application's structure
- Real-time tree updates on state changes
- View nested LiveView relationships

### [DeadView Mode](dead_view_mode.md)

Debug the state of your application after redirecting or encountering a crash. This feature preserves the last known state and callback history, allowing you to investigate what went wrong even after the process has terminated.

**Key capabilities:**

- Inspect last state of LiveView or LiveComponents
- Review callback execution order
- See which callback crashed the process
- Continue to successor LiveView after debugging
- Status indicator showing alive/dead state

### [Elements Inspection](elements_inspection.md)

Inspect LiveViews and LiveComponents directly from the rendered page by selecting elements with your mouse.

**Key capabilities:**

- Two activation methods: Debug Button or Inspect Element button
- Hover preview with element information
- Click to inspect node
- Highlight elements during selection
- Works in both standalone and DevTools extension modes

## Browser Features

Some features require JavaScript injection into your debugged application for enhanced functionality:

- **Components Highlighting** - Visual DOM highlighting
- **Elements Inspection** - Mouse-based element selection

These features are enabled by default but can be configured. See the [Configuration](config.md) page for details.
