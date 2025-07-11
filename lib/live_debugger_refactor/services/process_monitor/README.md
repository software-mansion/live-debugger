## ProcessMonitor

This service is tasked with monitoring the status of LiveView processes created by a debugged application, notifying the LiveDebugger when a LiveView process starts or terminates.

### Overview

The Process Monitor performs two essential functions:

- It detects the initiation of new LiveView processes, facilitating real-time monitoring of the application’s activity and resource allocation.
- It identifies when LiveView processes terminate, which can provide critical insights into process stability or potential issues within the application.
