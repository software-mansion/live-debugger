## StateManager

This service is dedicated to managing and storing the state of LiveView processes created by a debugged application. It ensures that these states are accessible particularly in DeadView mode, facilitating post-mortem analysis and debugging.

### Overview

This service utilizes Erlang's ETS (Erlang Term Storage) tables to cache and maintain the latest state of LiveView processes. This aids in ensuring that even after a LiveView process terminates, its state remains accessible for debugging and analysis.
