## CallbackTracer

This service is responsible for setting up `:dbg.tracer`, monitoring and managing it, parsing raw traces and finally sending them to the bus.

### Overview

The CallbackTracer initializes `:dbg.tracer` to collect callback-related data. It continuously monitors the tracer for errors and exceptions. Trace data sent from the tracer is received by a GenServer within the service, which then analyzes and persists this data before broadcasting it to the event bus. The service also adapts tracer configurations in response to system changes like module recompilations to maintain accurate and relevant data collection.
