# Changelog

## 0.4.3 (2025-11-05)

### Bug fixes
  * Fix highlighting with embedded LiveViews [#797](https://github.com/software-mansion/live-debugger/pull/797)

### Enhancements
  * Route to same page after redirect to new process [#803](https://github.com/software-mansion/live-debugger/pull/803)
  * Add features page to docs [#829](https://github.com/software-mansion/live-debugger/pull/829)

## 0.4.2 (2025-10-09)

### Bug fixes
  * Fix crash when refreshing during callback execution in [#760](https://github.com/software-mansion/live-debugger/pull/760)
  * Explicit formats in SocketDiscoveryController in [#754](https://github.com/software-mansion/live-debugger/pull/754)
  * Fix positioning of return arrow in [#788](https://github.com/software-mansion/live-debugger/pull/788)
  * Fix highlighting LiveViews in LiveComponents in [#725](https://github.com/software-mansion/live-debugger/pull/725)
  * Add phoenix ~> 1.7 dep in [#791](https://github.com/software-mansion/live-debugger/pull/791)

## 0.4.1 (2025-09-09)

### Bug fixes
  * Checking if module has `:module_info` exported in [#731](https://github.com/software-mansion/live-debugger/pull/731)
  * Weird css behaviour on flash and fullscreen in [#727](https://github.com/software-mansion/live-debugger/pull/727)
  * Fix truncated tooltip in [#733](https://github.com/software-mansion/live-debugger/pull/733)
  * Lack of exception trace in [#732](https://github.com/software-mansion/live-debugger/pull/732)

## 0.4.0 (2025-08-28)

### Features:
  * Add search to query api in [#538](https://github.com/software-mansion/live-debugger/pull/538)
  * Add search bar to global traces in [#570](https://github.com/software-mansion/live-debugger/pull/570)
  * Create debug websocket with client browser in [#619](https://github.com/software-mansion/live-debugger/pull/619)
  * Add menu to debug button in [#623](https://github.com/software-mansion/live-debugger/pull/623)
  * Inspecting elements from the browser in [#642](https://github.com/software-mansion/live-debugger/pull/642)
  * Sending window initialized event to LiveDebugger in [#651](https://github.com/software-mansion/live-debugger/pull/651)
  * Better handling of nested LiveViews inspection in [#650](https://github.com/software-mansion/live-debugger/pull/650)
  * Create successor discoverer serivce in [#655](https://github.com/software-mansion/live-debugger/pull/655)
  * Display node info during highlighting in [#679](https://github.com/software-mansion/live-debugger/pull/679)
  * Inspecting elements from LiveDebugger in [#685](https://github.com/software-mansion/live-debugger/pull/685)
  * Redirect to active live views in [#691](https://github.com/software-mansion/live-debugger/pull/691)
  * Highlight search phrase inside callback trace body in [#692](https://github.com/software-mansion/live-debugger/pull/692)
  * Event struct in [#703](https://github.com/software-mansion/live-debugger/pull/703)
  * Add inspect button tooltip in [#705](https://github.com/software-mansion/live-debugger/pull/705)
  * Disable inspecting in dead view mode in [#707](https://github.com/software-mansion/live-debugger/pull/707)

### Bug fixes
  * Fix LiveViewDebugService in [#534](https://github.com/software-mansion/live-debugger/pull/534)
  * Add PubSub name as config value in [#537](https://github.com/software-mansion/live-debugger/pull/537)
  * Fix displaying maps with structs as keys in [#571](https://github.com/software-mansion/live-debugger/pull/571)
  * Fix issue with duplicated windowID in [#686](https://github.com/software-mansion/live-debugger/pull/686)
  * Fix search query limited by page size in [#682](https://github.com/software-mansion/live-debugger/pull/682)
  * Fix collapsible not cloasing on refresh in [#693](https://github.com/software-mansion/live-debugger/pull/693)
  * Fixed typo in debug button and removed event context in [#698](https://github.com/software-mansion/live-debugger/pull/698)
  * Fix highlighting on dead view mode in [#694](https://github.com/software-mansion/live-debugger/pull/694)
  * Disabling debug menu when inspect mode changed in [#706](https://github.com/software-mansion/live-debugger/pull/706)
  * Fix highlighting in dead view mode in [#710](https://github.com/software-mansion/live-debugger/pull/710)
  * Fixed scrolling with debug options menu in [#711](https://github.com/software-mansion/live-debugger/pull/711)

### Refactor
  * Switch to debug module in [#496](https://github.com/software-mansion/live-debugger/pull/496)
  * Simplified pubsub routing in [#529](https://github.com/software-mansion/live-debugger/pull/529)
  * Add link in global traces view to preview given node in [#528](https://github.com/software-mansion/live-debugger/pull/528)
  * Create `LiveDebugger.API.System.Module` in [#565](https://github.com/software-mansion/live-debugger/pull/565)
  * Create `LiveDebugger.API.System.Process` in [#568](https://github.com/software-mansion/live-debugger/pull/568)
  * Added event behaviour in [#567](https://github.com/software-mansion/live-debugger/pull/567)
  * Add api for `:dbg` module in [#566](https://github.com/software-mansion/live-debugger/pull/566)
  * Implement event bus in [#572](https://github.com/software-mansion/live-debugger/pull/572)
  * Create `SettingsStorage` api in [#574](https://github.com/software-mansion/live-debugger/pull/574)
  * Create `LiveDebuggerRefactor.API.LiveViewDebug` in [#573](https://github.com/software-mansion/live-debugger/pull/573)
  * Create `LiveDebuggerRefactor.API.TracesStorage` in [#576](https://github.com/software-mansion/live-debugger/pull/576)
  * Create base for each service in [#578](https://github.com/software-mansion/live-debugger/pull/578)
  * Create `LiveDebuggerRefactor.API.LiveViewDiscovery` in [#581](https://github.com/software-mansion/live-debugger/pull/581)
  * Create API for `StatesStorage` in [#579](https://github.com/software-mansion/live-debugger/pull/579)
  * Create tests for `TracesStorage` in [#587](https://github.com/software-mansion/live-debugger/pull/587)
  * Add tracing manager genserver in [#588](https://github.com/software-mansion/live-debugger/pull/588)
  * Create `ProcessMonitor `genserver in [#603](https://github.com/software-mansion/live-debugger/pull/603)
  * Create `StateManager` GenServer in [#604](https://github.com/software-mansion/live-debugger/pull/604)
  * Move general UI modules and lay foundation for UI in [#591](https://github.com/software-mansion/live-debugger/pull/591)
  * Create `TableWatcher` GenServer in [#607](https://github.com/software-mansion/live-debugger/pull/607)
  * Prepare api for `GarbageCollector` in [#609](https://github.com/software-mansion/live-debugger/pull/609)
  * Add action for `StateManager` in [#610](https://github.com/software-mansion/live-debugger/pull/610)
  * Create TraceHandler GenServer in [#611](https://github.com/software-mansion/live-debugger/pull/611)
  * Create `GarbageCollector` GenServer in [#612](https://github.com/software-mansion/live-debugger/pull/612)
  * Send event after state save in [#615](https://github.com/software-mansion/live-debugger/pull/615)
  * Create settings context for UI in [#613](https://github.com/software-mansion/live-debugger/pull/613)
  * Create `nested_live_view_links` context in [#617](https://github.com/software-mansion/live-debugger/pull/617)
  * Create `Discovery` context in [#616](https://github.com/software-mansion/live-debugger/pull/616)
  * Create `node_state` context (part I) in [#621](https://github.com/software-mansion/live-debugger/pull/621)
  * Add `ComponentsTree` UI context in [#618](https://github.com/software-mansion/live-debugger/pull/618)
  * Create `node_state` context (part II) in [#624](https://github.com/software-mansion/live-debugger/pull/624)
  * Switch debug ws connection based on refactor flag in [#629](https://github.com/software-mansion/live-debugger/pull/629)
  * Add hooks and HooksComponents functionalities in [#632](https://github.com/software-mansion/live-debugger/pull/632)
  * Create actions and queries for `settings` context in [#626](https://github.com/software-mansion/live-debugger/pull/626)
  * Better structure in assets in [#638](https://github.com/software-mansion/live-debugger/pull/638)
  * Add data loading for `discovery` context in [#636](https://github.com/software-mansion/live-debugger/pull/636)
  * `discovery` context async assigning in [#646](https://github.com/software-mansion/live-debugger/pull/646)
  * Add HookComponents for `callback_tracing` in [#637](https://github.com/software-mansion/live-debugger/pull/637)
  * Add data loading and handlers for `node_state` context in [#645](https://github.com/software-mansion/live-debugger/pull/645)
  * Data loading and handlers for `nested_live_view_links` in [#648](https://github.com/software-mansion/live-debugger/pull/648)
  * Move filters to `callback_tracing` context in [#649](https://github.com/software-mansion/live-debugger/pull/649)
  * Data loading and handlers for `components_tree` context in [#652](https://github.com/software-mansion/live-debugger/pull/652)
  * Add nested LiveViews and missing components in [#653](https://github.com/software-mansion/live-debugger/pull/653)
  * Add `ExistingTraces` hook in [#656](https://github.com/software-mansion/live-debugger/pull/656)
  * Add `FilterNewTraces` hook in [#662](https://github.com/software-mansion/live-debugger/pull/662)
  * Add `TracingFuse` hook in [#664](https://github.com/software-mansion/live-debugger/pull/664)
  * Add `DisplayNewTraces` hook in [#670](https://github.com/software-mansion/live-debugger/pull/670)
  * Add DebuggerLive, small fixes, add missing modules in [#665](https://github.com/software-mansion/live-debugger/pull/665)
  * Move config component in [#676](https://github.com/software-mansion/live-debugger/pull/676)
  * Add `SocketDiscoveryController` in [#677](https://github.com/software-mansion/live-debugger/pull/677)
  * Add behaviour for `callback_tracing` HookComponents in [#673](https://github.com/software-mansion/live-debugger/pull/673)
  * Add DeadViewMode handling in [#674](https://github.com/software-mansion/live-debugger/pull/674)
  * Validate with e2e tests, remove old code in [#680](https://github.com/software-mansion/live-debugger/pull/680)
  * Rename modules to remove "refactor" suffix in [#683](https://github.com/software-mansion/live-debugger/pull/683)
  * Connect successor finding service to debugger_live in [#687](https://github.com/software-mansion/live-debugger/pull/687)
  * Don't reload in iframe, remove Window Discovery in [#690](https://github.com/software-mansion/live-debugger/pull/690)
  * Use DebugSocket in components highlighting in [#697](https://github.com/software-mansion/live-debugger/pull/697)

### Other
  * Chore: Change version to v0.4.0-dev in [#524](https://github.com/software-mansion/live-debugger/pull/524)
  * Task: Add docs for components tree in [#492](https://github.com/software-mansion/live-debugger/pull/492)
  * Task: Add docs for components tree in [#492](https://github.com/software-mansion/live-debugger/pull/492)
  * Task: Add docs for components tree in [#492](https://github.com/software-mansion/live-debugger/pull/492)
  * Taks: Add docs for components highlighting in [#508](https://github.com/software-mansion/live-debugger/pull/508)
  * Task: Add docs for assigns inspection in [#509](https://github.com/software-mansion/live-debugger/pull/509)
  * Docs: Describe Dead View Mode in [#527](https://github.com/software-mansion/live-debugger/pull/527)
  * Task: Describe callback tracing in docs in [#533](https://github.com/software-mansion/live-debugger/pull/533)
  * Tests: added test-cases for TraceHandler in [#614](https://github.com/software-mansion/live-debugger/pull/614)
  * Chore: adjust path in assets workflow in [#644](https://github.com/software-mansion/live-debugger/pull/644)
  * Task: Add tests for searching in callback traces in [#699](https://github.com/software-mansion/live-debugger/pull/699)
  * Docs: Elements Inspection in [#708](https://github.com/software-mansion/live-debugger/pull/708)
  * Enhancement: Update existing docs to new version in [#709](https://github.com/software-mansion/live-debugger/pull/709)
  * Tests: add tests for elements inspection in [#704](https://github.com/software-mansion/live-debugger/pull/704)

## 0.3.2 (2025-08-18)

### Bug fixes
  * Expanding deleted trace error in [#678](https://github.com/software-mansion/live-debugger/pull/678)

## 0.3.1 (2025-07-08)

### Enhancements:
  * Add PubSub name as config value in [#537](https://github.com/software-mansion/live-debugger/pull/537)

### Bug fixes
  * Fix displaying maps with structs as keys in [#571](https://github.com/software-mansion/live-debugger/pull/571)

## 0.3.0 (2025-06-25)

### Features:
  * Implement displaying event handling time in [#277](https://github.com/software-mansion/live-debugger/pull/277)
  * Implement caching mechanism in [#364](https://github.com/software-mansion/live-debugger/pull/364)
  * Create form for filtering by execution time in [#361](https://github.com/software-mansion/live-debugger/pull/361)
  * Implement filtering by execution time in [#379](https://github.com/software-mansion/live-debugger/pull/379)
  * Add view with active LiveViews per window in [#382](https://github.com/software-mansion/live-debugger/pull/382)
  * Adjust devtools extension for firefox in [#388](https://github.com/software-mansion/live-debugger/pull/388)
  * Update callback execution time info according to designs in [#422](https://github.com/software-mansion/live-debugger/pull/422)
  * Add mode for disconnected LiveViews in [#412](https://github.com/software-mansion/live-debugger/pull/412)
  * Apply new navigation to UI in [#433](https://github.com/software-mansion/live-debugger/pull/433)
  * Mark arguments of callback traces in [#436](https://github.com/software-mansion/live-debugger/pull/436)
  * Add settings panel in [#435](https://github.com/software-mansion/live-debugger/pull/435)
  * Update execution time filters to new designs in [#425](https://github.com/software-mansion/live-debugger/pull/425)
  * Global traces preparations in [#447](https://github.com/software-mansion/live-debugger/pull/447)
  * Garbage collection of ets records in [#439](https://github.com/software-mansion/live-debugger/pull/439)
  * Copy module to clipboard in [#413](https://github.com/software-mansion/live-debugger/pull/413)
  * Add global traces list in [#470](https://github.com/software-mansion/live-debugger/pull/470)
  * Applied new designs to filters form in [#488](https://github.com/software-mansion/live-debugger/pull/488)
  * Copy elixir terms to clipboard in [#480](https://github.com/software-mansion/live-debugger/pull/480)
  * Add module in label for global traces in [#494](https://github.com/software-mansion/live-debugger/pull/494)
  * Filters sidebar in global callback traces view in [#491](https://github.com/software-mansion/live-debugger/pull/491)
  * Bind settings buttons to actions in [#504](https://github.com/software-mansion/live-debugger/pull/504)
  * Add aria label to buttons with only icons in [#522](https://github.com/software-mansion/live-debugger/pull/522)

### Bug fixes
  * Fixed callback tracing after components switching in [#373](https://github.com/software-mansion/live-debugger/pull/373)
  * Allowed iframe in LiveDebugger router for Phoenix 1.8+ in [#372](https://github.com/software-mansion/live-debugger/pull/372)
  * LiveDebugger stops working after code reload in [#384](https://github.com/software-mansion/live-debugger/pull/384)
  * Fixed assigns refreshing after changing node in [#390](https://github.com/software-mansion/live-debugger/pull/390)
  * Hide module reloading behind config flag in [#420](https://github.com/software-mansion/live-debugger/pull/420)
  * All traces are loaded when no callback name is checked in filters in [#432](https://github.com/software-mansion/live-debugger/pull/432)
  * Fix duplicated ids in `toggle_switch` component in [#446](https://github.com/software-mansion/live-debugger/pull/446)
  * Fix selection of node inspector on navigation menu in [#451](https://github.com/software-mansion/live-debugger/pull/451)
  * Use `external_url` for live_debugger_tags' url in [#452](https://github.com/software-mansion/live-debugger/pull/452)
  * Fix collapsibles in [#469](https://github.com/software-mansion/live-debugger/pull/469)
  * Extension redirects not working properly in [#468](https://github.com/software-mansion/live-debugger/pull/468)
  * Wrong color on dark mode fullscreen body in [#472](https://github.com/software-mansion/live-debugger/pull/472)
  * Not updated PubSub mocks in e2e tests in [#489](https://github.com/software-mansion/live-debugger/pull/489)
  * Handling crashing callback in [#505](https://github.com/software-mansion/live-debugger/pull/505)
  * Add missing spinner on successor finding in [#514](https://github.com/software-mansion/live-debugger/pull/514)
  * Fix scrollbar size on firefox in [#515](https://github.com/software-mansion/live-debugger/pull/515)
  * Fix z-index of sidebar in [#518](https://github.com/software-mansion/live-debugger/pull/518)
  * Disable highlighting after node selection in [#517](https://github.com/software-mansion/live-debugger/pull/517)
  * Moved z-index of sidebar to nested div in [#520](https://github.com/software-mansion/live-debugger/pull/520)

### Refactors
  * Simplified routing and created `linked_view` hook in [#376](https://github.com/software-mansion/live-debugger/pull/376)
  * Make LvProcess use ProcessService in [#394](https://github.com/software-mansion/live-debugger/pull/394)
  * Adjust pubsub channels to the new routing system in [#411](https://github.com/software-mansion/live-debugger/pull/411)
  * Add routing backward compatibility to extension in [#423](https://github.com/software-mansion/live-debugger/pull/423)
  * Adjusted navigation of return arrow in [#440](https://github.com/software-mansion/live-debugger/pull/440)
  * Refactored LiveViews structure in [#457](https://github.com/software-mansion/live-debugger/pull/457)
  * Extracted logic and components from traces_live in [#466](https://github.com/software-mansion/live-debugger/pull/466)
  * Udpate to lucide icons in [#456](https://github.com/software-mansion/live-debugger/pull/456)
  * Consolidate sidebar children in [#506](https://github.com/software-mansion/live-debugger/pull/506)

### Other
  * Chore: update GitHub workflows in [#374](https://github.com/software-mansion/live-debugger/pull/374)
  * Chore: update shields in README.md in [#375](https://github.com/software-mansion/live-debugger/pull/375)
  * Task: Improve e2e tests in [#393](https://github.com/software-mansion/live-debugger/pull/393)
  * rename node to nodejs in .tool-versions file in [#414](https://github.com/software-mansion/live-debugger/pull/414)
  * Chore: Backward compatibility workflow in [#419](https://github.com/software-mansion/live-debugger/pull/419)
  * Task: Add custom LiveDebugger url config in [#438](https://github.com/software-mansion/live-debugger/pull/438)
  * Fix typo in URL.to_relative/1 spec in [#445](https://github.com/software-mansion/live-debugger/pull/445)
  * Task: Bump Tailwind to 4.1.8 in [#467](https://github.com/software-mansion/live-debugger/pull/467)
  * Chore: Update firefox extension to meet requirements in [#502](https://github.com/software-mansion/live-debugger/pull/502)
  * Chore: Cancel previous CI workflow if new commit pushed in [#519](https://github.com/software-mansion/live-debugger/pull/519)
  * Chore: Change description in settings in [#521](https://github.com/software-mansion/live-debugger/pull/521)

## 0.2.4 (2025-05-28)

### Enhancements:
  * Add custom LiveDebugger url config in [#442](https://github.com/software-mansion/live-debugger/pull/442)
  * Adjust required versions and correct `phoenix_live_view` dependency in [#419](https://github.com/software-mansion/live-debugger/pull/419)

### Bug fixes
  * Extension reload on any browser navigation in [#418](https://github.com/software-mansion/live-debugger/pull/418)
  * Fix traces filtering in [#443](https://github.com/software-mansion/live-debugger/pull/443)

## 0.2.3 (2025-05-21)

### Enhancements:
  * Hide module reloading after config flag in [#421](https://github.com/software-mansion/live-debugger/pull/421)

## 0.2.2 (2025-05-14)

### Bug fixes
  * Fixed assigns refreshing after changing node in [#386](https://github.com/software-mansion/live-debugger/pull/386)
  * LiveDebugger stops working after code reload in [#391](https://github.com/software-mansion/live-debugger/pull/391)

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
  * Fix triggering highlighting on hover in [#353](https://github.com/software-mansion/live-debugger/pull/353)
  * Add config to disable LiveDebugger in [#357](https://github.com/software-mansion/live-debugger/pull/357)
  * Fix traces separator after filters updated in [#362](https://github.com/software-mansion/live-debugger/pull/362)

## 0.1.7 (2025-04-29)

### Enhancements:
  * Enhanced UI layout styling and accessibility in [#287](https://github.com/software-mansion/live-debugger/pull/287)
  * Updated styling for scrollbars in [#292](https://github.com/software-mansion/live-debugger/pull/292)
  * Improved components tree styling in [#291](https://github.com/software-mansion/live-debugger/pull/291)
  * Added `server` option to config in [#337](https://github.com/software-mansion/live-debugger/pull/337)

### Bug fixes
  * Fixed z-index of fullscreen button in [#288](https://github.com/software-mansion/live-debugger/pull/288)
  * Fixed id multiplication from components tree in [#286](https://github.com/software-mansion/live-debugger/pull/286)
  * Fixed assigns not scrollable in [#294](https://github.com/software-mansion/live-debugger/pull/294)
  * Fixed components tree with only one node in [#326](https://github.com/software-mansion/live-debugger/pull/326)

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

