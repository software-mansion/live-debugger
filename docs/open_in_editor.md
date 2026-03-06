# Open files in your editor

This feature allows you to open files and specific lines directly from the **LiveDebugger** in your preferred editor.

## How it works
The debugger determines which editor to use by checking environment variables in the following order:
1. **`ELIXIR_EDITOR`**: Elixir-specific editor (takes priority).
2. **`TERM_PROGRAM`**: Automatically set by integrated terminals (e.g., in VS Code or Zed).
3. **`EDITOR`**: Default system editor (used if ELIXIR_EDITOR is not set and integrated terminal is not detected).


## Integrated Terminal Support
If you are using an integrated terminal inside **VS Code** or **Zed**, the editor opens automatically via the `TERM_PROGRAM` variable.

## GUI Editors
Add the following to your shell profile (`.zshrc`, `.bashrc`, etc.) to ensure files open in your preferred editor from any terminal session:

For Visual Studio Code
    export ELIXIR_EDITOR="code --goto"
For Zed
    export ELIXIR_EDITOR="zed"

For complex setups use the `__FILE__` and `__LINE__` placeholders.

```bash
export ELIXIR_EDITOR="my_editor +__LINE__ __FILE__"
```

## Terminal Editors

Opening terminal editor directly is not supported because of the potential lock of the iex session. 
We recommend using **Tmux** to open the file in a new window or a split pane.

### Example configuration

For Tmux and Helix
    
    export ELIXIR_EDITOR="tmux neww 'hx __FILE__:__LINE__'"
