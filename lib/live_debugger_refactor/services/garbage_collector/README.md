## GarbageCollector

This service is designed to manage and periodically clean Erlang's ETS tables to maintain them within specified size limits.

### Overview

This service routinely checks ETS tables for their sizes and usage, removing unobserved tables entirely or trimming tables to ensure they do not exceed predefined size limits. It performs two main tasks:

- It detects and deletes any ETS tables that are not being accessed or observed to free up resources.
- It periodically trims the contents of active ETS tables to ensure they do not exceed the maximum allowed size, maintaining system efficiency and preventing memory bloat.
