# Changelog

## 0.4.1 (2025-09-09)

### Bug fixes
  * Checking if module has `:module_info` exported by @kraleppa in [#731](https://github.com/software-mansion/live-debugger/pull/731)
  * Weird css behaviour on flash and fullscreen by @srzeszut in [#727](https://github.com/software-mansion/live-debugger/pull/727)
  * Fix truncated tooltip by @hhubert6 in [#733](https://github.com/software-mansion/live-debugger/pull/733)
  * Lack of exception trace by @hhubert6 in [#732](https://github.com/software-mansion/live-debugger/pull/732)

## 0.4.0 (2025-08-28)

### Features:
  * Add search to query api by @samrobinsonsauce in [#538](https://github.com/software-mansion/live-debugger/pull/538)
  * Add search bar to global traces by @samrobinsonsauce in [#570](https://github.com/software-mansion/live-debugger/pull/570)
  * Create debug websocket with client browser by @kraleppa in [#619](https://github.com/software-mansion/live-debugger/pull/619)
  * Add menu to debug button by @kraleppa in [#623](https://github.com/software-mansion/live-debugger/pull/623)
  * Inspecting elements from the browser by @kraleppa in [#642](https://github.com/software-mansion/live-debugger/pull/642)
  * Sending window initialized event to LiveDebugger by @kraleppa in [#651](https://github.com/software-mansion/live-debugger/pull/651)
  * Better handling of nested LiveViews inspection by @kraleppa in [#650](https://github.com/software-mansion/live-debugger/pull/650)
  * Create successor discoverer serivce by @kraleppa in [#655](https://github.com/software-mansion/live-debugger/pull/655)
  * Display node info during highlighting by @kraleppa in [#679](https://github.com/software-mansion/live-debugger/pull/679)
  * Inspecting elements from LiveDebugger by @kraleppa in [#685](https://github.com/software-mansion/live-debugger/pull/685)
  * Redirect to active live views by @GuzekAlan in [#691](https://github.com/software-mansion/live-debugger/pull/691)
  * Highlight search phrase inside callback trace body by @hhubert6 in [#692](https://github.com/software-mansion/live-debugger/pull/692)
  * Event struct by @GuzekAlan in [#703](https://github.com/software-mansion/live-debugger/pull/703)
  * Add inspect button tooltip by @hhubert6 in [#705](https://github.com/software-mansion/live-debugger/pull/705)
  * Disable inspecting in dead view mode by @GuzekAlan in [#707](https://github.com/software-mansion/live-debugger/pull/707)

### Bug fixes
  * Fix LiveViewDebugService by @hhubert6 in [#534](https://github.com/software-mansion/live-debugger/pull/534)
  * Add PubSub name as config value by @GuzekAlan in [#537](https://github.com/software-mansion/live-debugger/pull/537)
  * Fix displaying maps with structs as keys by @kraleppa in [#571](https://github.com/software-mansion/live-debugger/pull/571)
  * Fix issue with duplicated windowID by @kraleppa in [#686](https://github.com/software-mansion/live-debugger/pull/686)
  * Fix search query limited by page size by @hhubert6 in [#682](https://github.com/software-mansion/live-debugger/pull/682)
  * Fix collapsible not cloasing on refresh by @GuzekAlan in [#693](https://github.com/software-mansion/live-debugger/pull/693)
  * Fixed typo in debug button and removed event context by @kraleppa in [#698](https://github.com/software-mansion/live-debugger/pull/698)
  * Fix highlighting on dead view mode by @GuzekAlan in [#694](https://github.com/software-mansion/live-debugger/pull/694)
  * Disabling debug menu when inspect mode changed by @kraleppa in [#706](https://github.com/software-mansion/live-debugger/pull/706)
  * Fix highlighting in dead view mode by @hhubert6 in [#710](https://github.com/software-mansion/live-debugger/pull/710)
  * Fixed scrolling with debug options menu by @kraleppa in [#711](https://github.com/software-mansion/live-debugger/pull/711)

### Refactor
  * Switch to debug module by @hhubert6 in [#496](https://github.com/software-mansion/live-debugger/pull/496)
  * Simplified pubsub routing by @kraleppa in [#529](https://github.com/software-mansion/live-debugger/pull/529)
  * Add link in global traces view to preview given node by @hhubert6 in [#528](https://github.com/software-mansion/live-debugger/pull/528)
  * Create `LiveDebugger.API.System.Module` by @hhubert6 in [#565](https://github.com/software-mansion/live-debugger/pull/565)
  * Create `LiveDebugger.API.System.Process` by @hhubert6 in [#568](https://github.com/software-mansion/live-debugger/pull/568)
  * Added event behaviour by @kraleppa in [#567](https://github.com/software-mansion/live-debugger/pull/567)
  * Add api for `:dbg` module by @GuzekAlan in [#566](https://github.com/software-mansion/live-debugger/pull/566)
  * Implement event bus by @kraleppa in [#572](https://github.com/software-mansion/live-debugger/pull/572)
  * Create `SettingsStorage` api by @GuzekAlan in [#574](https://github.com/software-mansion/live-debugger/pull/574)
  * Create `LiveDebuggerRefactor.API.LiveViewDebug` by @hhubert6 in [#573](https://github.com/software-mansion/live-debugger/pull/573)
  * Create `LiveDebuggerRefactor.API.TracesStorage` by @hhubert6 in [#576](https://github.com/software-mansion/live-debugger/pull/576)
  * Create base for each service by @kraleppa in [#578](https://github.com/software-mansion/live-debugger/pull/578)
  * Create `LiveDebuggerRefactor.API.LiveViewDiscovery` by @hhubert6 in [#581](https://github.com/software-mansion/live-debugger/pull/581)
  * Create API for `StatesStorage` by @GuzekAlan in [#579](https://github.com/software-mansion/live-debugger/pull/579)
  * Create tests for `TracesStorage` by @hhubert6 in [#587](https://github.com/software-mansion/live-debugger/pull/587)
  * Add tracing manager genserver by @kraleppa in [#588](https://github.com/software-mansion/live-debugger/pull/588)
  * Create `ProcessMonitor `genserver by @hhubert6 in [#603](https://github.com/software-mansion/live-debugger/pull/603)
  * Create `StateManager` GenServer by @GuzekAlan in [#604](https://github.com/software-mansion/live-debugger/pull/)
  * Move general UI modules and lay foundation for UI by @GuzekAlan in [#591](https://github.com/software-mansion/live-debugger/pull/)
  * Create `TableWatcher` GenServer by @hhubert6 in [#607](https://github.com/software-mansion/live-debugger/pull/)
  * Prepare api for `GarbageCollector` by @hhubert6 in [#609](https://github.com/software-mansion/live-debugger/pull/)
  * Add action for `StateManager` by @GuzekAlan in [#610](https://github.com/software-mansion/live-debugger/pull/)
  * Create TraceHandler GenServer by @kraleppa in [#611](https://github.com/software-mansion/live-debugger/pull/)
  * Create `GarbageCollector` GenServer by @hhubert6 in [#612](https://github.com/software-mansion/live-debugger/pull/)
  * Send event after state save by @GuzekAlan in [#615](https://github.com/software-mansion/live-debugger/pull/)
  * Create settings context for UI by @GuzekAlan in [#613](https://github.com/software-mansion/live-debugger/pull/)
  * Create `nested_live_view_links` context by @hhubert6 in [#617](https://github.com/software-mansion/live-debugger/pull/)
  * Create `Discovery` context by @hhubert6 in [#616](https://github.com/software-mansion/live-debugger/pull/)
  * Create `node_state` context (part I) by @hhubert6 in [#621](https://github.com/software-mansion/live-debugger/pull/)
  * Add `ComponentsTree` UI context by @GuzekAlan in [#618](https://github.com/software-mansion/live-debugger/pull/)
  * Create `node_state` context (part II) by @hhubert6 in [#624](https://github.com/software-mansion/live-debugger/pull/)
  * Switch debug ws connection based on refactor flag by @kraleppa in [#629](https://github.com/software-mansion/live-debugger/pull/)
  * Add hooks and HooksComponents functionalities by @GuzekAlan in [#632](https://github.com/software-mansion/live-debugger/pull/)
  * Create actions and queries for `settings` context by @hhubert6 in [#626](https://github.com/software-mansion/live-debugger/pull/)
  * Better structure in assets by @kraleppa in [#638](https://github.com/software-mansion/live-debugger/pull/)
  * Add data loading for `discovery` context by @hhubert6 in [#636](https://github.com/software-mansion/live-debugger/pull/)
  * `discovery` context async assigning by @hhubert6 in [#646](https://github.com/software-mansion/live-debugger/pull/)
  * Add HookComponents for `callback_tracing` by @GuzekAlan in [#637](https://github.com/software-mansion/live-debugger/pull/)
  * Add data loading and handlers for `node_state` context by @hhubert6 in [#645](https://github.com/software-mansion/live-debugger/pull/)
  * Data loading and handlers for `nested_live_view_links` by @hhubert6 in [#648](https://github.com/software-mansion/live-debugger/pull/)
  * Move filters to `callback_tracing` context by @GuzekAlan in [#649](https://github.com/software-mansion/live-debugger/pull/)
  * Data loading and handlers for `components_tree` context by @hhubert6 in [#652](https://github.com/software-mansion/live-debugger/pull/)
  * Add nested LiveViews and missing components by @GuzekAlan in [#653](https://github.com/software-mansion/live-debugger/pull/)
  * Add `ExistingTraces` hook by @hhubert6 in [#656](https://github.com/software-mansion/live-debugger/pull/)
  * Add `FilterNewTraces` hook by @hhubert6 in [#662](https://github.com/software-mansion/live-debugger/pull/)
  * Add `TracingFuse` hook by @hhubert6 in [#664](https://github.com/software-mansion/live-debugger/pull/)
  * Add `DisplayNewTraces` hook by @hhubert6 in [#670](https://github.com/software-mansion/live-debugger/pull/)
  * Add DebuggerLive, small fixes, add missing modules by @GuzekAlan in [#665](https://github.com/software-mansion/live-debugger/pull/)
  * Move config component by @GuzekAlan in [#676](https://github.com/software-mansion/live-debugger/pull/)
  * Add `SocketDiscoveryController` by @hhubert6 in [#677](https://github.com/software-mansion/live-debugger/pull/)
  * Add behaviour for `callback_tracing` HookComponents by @hhubert6 in [#673](https://github.com/software-mansion/live-debugger/pull/)
  * Add DeadViewMode handling by @GuzekAlan in [#674](https://github.com/software-mansion/live-debugger/pull/)
  * Validate with e2e tests, remove old code by @GuzekAlan in [#680](https://github.com/software-mansion/live-debugger/pull/)
  * Rename modules to remove "refactor" suffix by @GuzekAlan in [#683](https://github.com/software-mansion/live-debugger/pull/)
  * Connect successor finding service to debugger_live by @GuzekAlan in [#687](https://github.com/software-mansion/live-debugger/pull/)
  * Don't reload in iframe, remove Window Discovery by @GuzekAlan in [#690](https://github.com/software-mansion/live-debugger/pull/)
  * Use DebugSocket in components highlighting by @hhubert6 in [#697](https://github.com/software-mansion/live-debugger/pull/)

### Other
  * Chore: Change version to v0.4.0-dev by @kraleppa in [#524](https://github.com/software-mansion/live-debugger/pull/)
  * Task: Add docs for components tree by @GuzekAlan in [#492](https://github.com/software-mansion/live-debugger/pull/)
  * Task: Add docs for components tree by @GuzekAlan in [#492](https://github.com/software-mansion/live-debugger/pull/)
  * Task: Add docs for components tree by @GuzekAlan in [#492](https://github.com/software-mansion/live-debugger/pull/)
  * Taks: Add docs for components highlighting by @hhubert6 in [#508](https://github.com/software-mansion/live-debugger/pull/)
  * Task: Add docs for assigns inspection by @hhubert6 in [#509](https://github.com/software-mansion/live-debugger/pull/)
  * Docs: Describe Dead View Mode by @GuzekAlan in [#527](https://github.com/software-mansion/live-debugger/pull/)
  * Task: Describe callback tracing in docs by @GuzekAlan in [#533](https://github.com/software-mansion/live-debugger/pull/)
  * Tests: added test-cases for TraceHandler by @kraleppa in [#614](https://github.com/software-mansion/live-debugger/pull/)
  * Chore: adjust path in assets workflow by @kraleppa in [#644](https://github.com/software-mansion/live-debugger/pull/)
  * Task: Add tests for searching in callback traces by @hhubert6 in [#699](https://github.com/software-mansion/live-debugger/pull/)
  * Docs: Elements Inspection by @hhubert6 in [#708](https://github.com/software-mansion/live-debugger/pull/)
  * Enhancement: Update existing docs to new version by @GuzekAlan in [#709](https://github.com/software-mansion/live-debugger/pull/)
  * Tests: add tests for elements inspection by @kraleppa in [#704](https://github.com/software-mansion/live-debugger/pull/)

## 0.3.2 (2025-08-18)

### Bug fixes
  * Expanding deleted trace error by @GuzekAlan in [#678](https://github.com/software-mansion/live-debugger/pull/)

## 0.3.1 (2025-07-08)

### Enhancements:
  * Add PubSub name as config value by @GuzekAlan in [#537](https://github.com/software-mansion/live-debugger/pull/)

### Bug fixes
  * Fix displaying maps with structs as keys by @kraleppa in [#571](https://github.com/software-mansion/live-debugger/pull/)

## 0.3.0 (2025-06-25)

### Features:
  * Implement displaying event handling time by @hhubert6 in [#277](https://github.com/software-mansion/live-debugger/pull/)
  * Implement caching mechanism by @GuzekAlan in [#364](https://github.com/software-mansion/live-debugger/pull/)
  * Create form for filtering by execution time by @hhubert6 in [#361](https://github.com/software-mansion/live-debugger/pull/)
  * Implement filtering by execution time by @hhubert6 in [#379](https://github.com/software-mansion/live-debugger/pull/)
  * Add view with active LiveViews per window by @kraleppa in [#382](https://github.com/software-mansion/live-debugger/pull/)
  * Adjust devtools extension for firefox by @hhubert6 in [#388](https://github.com/software-mansion/live-debugger/pull/)
  * Update callback execution time info according to designs by @hhubert6 in [#422](https://github.com/software-mansion/live-debugger/pull/)
  * Add mode for disconnected LiveViews by @GuzekAlan in [#412](https://github.com/software-mansion/live-debugger/pull/)
  * Apply new navigation to UI by @kraleppa in [#433](https://github.com/software-mansion/live-debugger/pull/)
  * Mark arguments of callback traces by @kraleppa in [#436](https://github.com/software-mansion/live-debugger/pull/)
  * Add settings panel by @kraleppa in [#435](https://github.com/software-mansion/live-debugger/pull/)
  * Update execution time filters to new designs by @hhubert6 in [#425](https://github.com/software-mansion/live-debugger/pull/)
  * Global traces preparations by @kraleppa in [#447](https://github.com/software-mansion/live-debugger/pull/)
  * Garbage collection of ets records by @GuzekAlan in [#439](https://github.com/software-mansion/live-debugger/pull/)
  * Copy module to clipboard by @hhubert6 in [#413](https://github.com/software-mansion/live-debugger/pull/)
  * Add global traces list by @kraleppa in [#470](https://github.com/software-mansion/live-debugger/pull/)
  * Applied new designs to filters form by @kraleppa in [#488](https://github.com/software-mansion/live-debugger/pull/)
  * Copy elixir terms to clipboard by @hhubert6 in [#480](https://github.com/software-mansion/live-debugger/pull/)
  * Add module in label for global traces by @GuzekAlan in [#494](https://github.com/software-mansion/live-debugger/pull/)
  * Filters sidebar in global callback traces view by @kraleppa in [#491](https://github.com/software-mansion/live-debugger/pull/)
  * Bind settings buttons to actions by @GuzekAlan in [#504](https://github.com/software-mansion/live-debugger/pull/)
  * Add aria label to buttons with only icons by @GuzekAlan in [#522](https://github.com/software-mansion/live-debugger/pull/)

### Bug fixes
  * Fixed callback tracing after components switching by @kraleppa in [#373](https://github.com/software-mansion/live-debugger/pull/)
  * Allowed iframe in LiveDebugger router for Phoenix 1.8+ by @kraleppa in [#372](https://github.com/software-mansion/live-debugger/pull/)
  * LiveDebugger stops working after code reload by @GuzekAlan in [#384](https://github.com/software-mansion/live-debugger/pull/)
  * Fixed assigns refreshing after changing node by @kraleppa in [#390](https://github.com/software-mansion/live-debugger/pull/)
  * Hide module reloading behind config flag by @GuzekAlan in [#420](https://github.com/software-mansion/live-debugger/pull/)
  * All traces are loaded when no callback name is checked in filters by @hhubert6 in [#432](https://github.com/software-mansion/live-debugger/pull/)
  * Fix duplicated ids in `toggle_switch` component by @kraleppa in [#446](https://github.com/software-mansion/live-debugger/pull/)
  * Fix selection of node inspector on navigation menu by @kraleppa in [#451](https://github.com/software-mansion/live-debugger/pull/)
  * Use `external_url` for live_debugger_tags' url by @GuzekAlan in [#452](https://github.com/software-mansion/live-debugger/pull/)
  * Fix collapsibles by @GuzekAlan in [#469](https://github.com/software-mansion/live-debugger/pull/)
  * Extension redirects not working properly by @hhubert6 in [#468](https://github.com/software-mansion/live-debugger/pull/)
  * Wrong color on dark mode fullscreen body by @GuzekAlan in [#472](https://github.com/software-mansion/live-debugger/pull/)
  * Not updated PubSub mocks in e2e tests by @hhubert6 in [#489](https://github.com/software-mansion/live-debugger/pull/)
  * Handling crashing callback by @hhubert6 in [#505](https://github.com/software-mansion/live-debugger/pull/)
  * Add missing spinner on successor finding by @kraleppa in [#514](https://github.com/software-mansion/live-debugger/pull/)
  * Fix scrollbar size on firefox by @kraleppa in [#515](https://github.com/software-mansion/live-debugger/pull/)
  * Fix z-index of sidebar by @kraleppa in [#518](https://github.com/software-mansion/live-debugger/pull/)
  * Disable highlighting after node selection by @kraleppa in [#517](https://github.com/software-mansion/live-debugger/pull/)
  * Moved z-index of sidebar to nested div by @kraleppa in [#520](https://github.com/software-mansion/live-debugger/pull/)

### Refactors
  * Simplified routing and created `linked_view` hook by @kraleppa in [#376](https://github.com/software-mansion/live-debugger/pull/)
  * Make LvProcess use ProcessService by @GuzekAlan in [#394](https://github.com/software-mansion/live-debugger/pull/)
  * Adjust pubsub channels to the new routing system by @kraleppa in [#411](https://github.com/software-mansion/live-debugger/pull/)
  * Add routing backward compatibility to extension by @kraleppa in [#423](https://github.com/software-mansion/live-debugger/pull/)
  * Adjusted navigation of return arrow by @kraleppa in [#440](https://github.com/software-mansion/live-debugger/pull/)
  * Refactored LiveViews structure by @kraleppa in [#457](https://github.com/software-mansion/live-debugger/pull/)
  * Extracted logic and components from traces_live by @kraleppa in [#466](https://github.com/software-mansion/live-debugger/pull/)
  * Udpate to lucide icons by @GuzekAlan in [#456](https://github.com/software-mansion/live-debugger/pull/)
  * Consolidate sidebar children by @samrobinsonsauce in [#506](https://github.com/software-mansion/live-debugger/pull/)

### Other
  * Chore: update GitHub workflows by @kraleppa in [#374](https://github.com/software-mansion/live-debugger/pull/)
  * Chore: update shields in README.md by @kraleppa in [#375](https://github.com/software-mansion/live-debugger/pull/)
  * Task: Improve e2e tests by @hhubert6 in [#393](https://github.com/software-mansion/live-debugger/pull/)
  * rename node to nodejs in .tool-versions file by @joaothallis in [#414](https://github.com/software-mansion/live-debugger/pull/)
  * Chore: Backward compatibility workflow by @kraleppa in [#419](https://github.com/software-mansion/live-debugger/pull/)
  * Task: Add custom LiveDebugger url config by @GuzekAlan in [#438](https://github.com/software-mansion/live-debugger/pull/)
  * Fix typo in URL.to_relative/1 spec by @rhcarvalho in [#445](https://github.com/software-mansion/live-debugger/pull/)
  * Task: Bump Tailwind to 4.1.8 by @GuzekAlan in [#467](https://github.com/software-mansion/live-debugger/pull/)
  * Chore: Update firefox extension to meet requirements by @hhubert6 in [#502](https://github.com/software-mansion/live-debugger/pull/)
  * Chore: Cancel previous CI workflow if new commit pushed by @kraleppa in [#519](https://github.com/software-mansion/live-debugger/pull/)
  * Chore: Change description in settings by @kraleppa in [#521](https://github.com/software-mansion/live-debugger/pull/)

## 0.2.4 (2025-05-28)

### Enhancements:
  * Add custom LiveDebugger url config by @GuzekAlan in [#442](https://github.com/software-mansion/live-debugger/pull/)
  * Adjust required versions and correct `phoenix_live_view` dependency by @kraleppa in [#419](https://github.com/software-mansion/live-debugger/pull/)

### Bug fixes
  * Extension reload on any browser navigation by @hhubert6 in [#418](https://github.com/software-mansion/live-debugger/pull/)
  * Fix traces filtering by @hhubert6 in [#443](https://github.com/software-mansion/live-debugger/pull/)

## 0.2.3 (2025-05-21)

### Enhancements:
  * Hide module reloading after config flag by @GuzekAlan in [#421](https://github.com/software-mansion/live-debugger/pull/)

## 0.2.2 (2025-05-14)

### Bug fixes
  * Fixed assigns refreshing after changing node by @kraleppa in [#386](https://github.com/software-mansion/live-debugger/pull/)
  * LiveDebugger stops working after code reload by @GuzekAlan in [#391](https://github.com/software-mansion/live-debugger/pull/)

## 0.2.1 (2025-05-12)

### Bug fixes
  * Fixed callback tracing after components switching
  * Allowed iframe in LiveDebugger router for Phoenix 1.8

## 0.2.0 (2025-05-07)

### Features:
  * Components highlighting
  * Chrome DevTools extension support
  * Dark mode
  * Callback traces filtering

### Bug fixes
  * Fix triggering highlighting on hover by @GuzekAlan in [#353](https://github.com/software-mansion/live-debugger/pull/)
  * Add config to disable LiveDebugger by @kraleppa in [#357](https://github.com/software-mansion/live-debugger/pull/)
  * Fix traces separator after filters updated by @hhubert6 in [#362](https://github.com/software-mansion/live-debugger/pull/)

## 0.1.7 (2025-04-29)

### Enhancements:
  * Enhanced UI layout styling and accessibility by @GuzekAlan in [#287](https://github.com/software-mansion/live-debugger/pull/)
  * Updated styling for scrollbars by @kraleppa in [#292](https://github.com/software-mansion/live-debugger/pull/)
  * Improved components tree styling by @GuzekAlan in [#291](https://github.com/software-mansion/live-debugger/pull/)
  * Added `server` option to config by @kraleppa in [#337](https://github.com/software-mansion/live-debugger/pull/)

### Bug fixes
  * Fixed z-index of fullscreen button by @hhubert6 in [#288](https://github.com/software-mansion/live-debugger/pull/)
  * Fixed id multiplication from components tree by @GuzekAlan in [#286](https://github.com/software-mansion/live-debugger/pull/)
  * Fixed assigns not scrollable by @GuzekAlan in [#294](https://github.com/software-mansion/live-debugger/pull/)
  * Fixed components tree with only one node by @GuzekAlan in [#326](https://github.com/software-mansion/live-debugger/pull/)

## 0.1.6 (2025-04-23)

### Bug fixes
  * Fixed problems with responsive UI on wider screens
  * Fixed UI alignment of fullscreen button in callback traces

## 0.1.5 (2025-04-18)

### Enhancements
  * New routing mechanism
  * Added flash messages
  * UI fixes
  * New installation process

### Bug fixes
  * Fixed initialization console.log message format
  * Fixed error associated with navigating to different LiveView while node is selected
  * Fixed components tree loading error without browser features turned on

## 0.1.4 (2025-03-31)

### Enhancements
  * Better support for nested LiveViews

### Bug fixes
  * Igniter intaller adds LiveDebugger dependency as `only: :dev`

## 0.1.3 (2025-03-27)

### Enhancements
  * New color scheme
  * Added LiveDebugger logo to navber
  * Added igniter installer

### Bug fixes
  * Fixed browser error associated with LiveView dependency mismatch
  * Minor UI fixes

## 0.1.2 (2025-03-20)

### Enhancements
  * Added visual separator between past and "just-loaded" events
  * Changed routing system
  * Improved the way to display Elixir structs

### Bug fixes
  * Fixed bug associated with unexpected exits during state fetching
  * Fixed LiveDebugger crash on OTP 26

## 0.1.1 (2025-03-10)

### Enhancements
  * Split dev assets and prod assets
  * Faster callback traces
  * Refreshing callback traces
  * Refactored LiveViewDiscoveryService
  * Adjusted rate limiting mechanism
  * Added spinner when loading callback body in collapsible

### Bug fixes
  * Fixed debug button styling
  * Fixed display of single entry list
  * Added missing font
  * Fixed collapsible section closing on desktop view

## 0.1.0 (2025-02-27)

### Enhancements
  * New UI ✨
  * Callback tracing is stopped by default
  * Added preview of callback arguments to traces list
  * Added basic nested LiveView support
  * Added “report issue” section 

### Bug fixes
  * Fixed error associated with missing ETS table
  * Debug button cannot be lost when changing size of the browser
  * Fixed debug button behavior on right click
  * Fixed issue associated with duplicated HTML ids

## 0.1.0-rc.1 (2025-02-11)

### Enhancements
  * Changed installation process
  * Introduced a new way of handling browser features
  * Made debug button draggable
  * Renamed `Events` sections to `Callback traces`

## 0.1.0-rc.0 (2025-02-06)

### Enhancements
  * Added fullscreen mode for displaying elixir structures
  * Added return icon in desktop view of channel dashboard
  * Removed obsolete logs

### Bug fixes
  * Fixed bug associated with rendering conditional components in nodes tree
  * Fixed loading of historical events
  * Fixed error associated with fetching state of not dead process

## 0.0.3 (2025-02-03)

### Enhancements
  * Refactored library to Application
  * Hiding sidebar after selecting tree node

### Bug fixes
  * Fixed errors associated with PID rediscovery on OTP 26
  * Fixed LiveDebugger button (updated z-index)

## 0.0.2 (2025-01-23)

### Bug fixes
  * Fixed compatibility with LiveView 0.20

## 0.0.1 (2025-01-22)

