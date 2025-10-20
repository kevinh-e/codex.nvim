# codex.nvim

Lightweight Neovim integration for the Codex CLI. Inspired by
[`claudecode.nvim`](https://github.com/coder/claudecode.nvim), this plugin gives
you a Codex-focused terminal pane, helpers to mention files, and commands to
stream selections to Codex – all written in pure Lua.

## Quick Start (Lazy)

```lua
{
  "kevinh-e/codex.nvim",
  dir = "/absolute/path/to/codex.nvim", -- drop if using the GitHub repo directly
  opts = {
    auto_start = true,
    terminal = {
      cmd = { "/usr/local/bin/codex" }, -- falls back to `vim.fn.exepath("codex")`
    },
  },
  keys = {
    { "<leader>cc", "<cmd>Codex<cr>", desc = "Toggle Codex" },
    { "<leader>cf", "<cmd>CodexFocus<cr>", desc = "Focus Codex terminal" },
    { "<leader>cs", "<cmd>'<,'>CodexSend<cr>", mode = "v", desc = "Send selection to Codex" },
    { "<leader>ca", "<cmd>CodexAdd %<cr>", desc = "Add current file to Codex" },
  },
}
```

You need a working Codex CLI (`codex` in the example above). Change the command
if you use a wrapper script or different executable.

### Automatic setup

The plugin now self-initialises with sensible defaults as soon as it is loaded.
If you want to tweak those defaults _before_ Neovim starts, set
`vim.g.codex_auto_setup` in your `init.lua`:

```lua
vim.g.codex_auto_setup = {
  terminal = {
    cmd = { "/path/to/codex-cli" },
    layout = "horizontal",
  },
}
```

Set it to `false` if you prefer to call `require("codex").setup()` manually.

## Commands

- `:Codex` toggles the dedicated Codex terminal split.
- `:CodexFocus` re-focuses the terminal window (spawns it if needed).
- `:[range]CodexSend [text]` sends a visual selection (`[range]`) or ad-hoc text
  to Codex.
- `:[range]CodexAdd [path]` sends an `@file` mention (optionally with line
  numbers) to Codex. Defaults to the current buffer when `[path]` is omitted.

## Configuration

```lua
require("codex").setup({
  auto_start = false,          -- automatically spawn Codex when Neovim starts
  log_level = "warn",          -- one of: error, warn, info, debug, trace
  terminal = {
    cmd = { "codex" },         -- string | list | function() -> command
    layout = "vertical",       -- "vertical" | "horizontal"
    width = 50,                -- width for vertical splits
    height = 15,               -- height for horizontal splits
    focus_on_open = true,      -- jump to the terminal when it opens
    env = {},                  -- extra environment variables
    cwd = nil,                 -- spawn Codex from this directory
  },
  mention = {
    prefix = "@",              -- prefix used when mentioning files
    include_line_numbers = true,
  },
})
```

The helper functions `require("codex").toggle()`, `.focus()`, `.send()` and
`.mention()` are also available if you prefer mapping directly to Lua calls.

### CLI path detection

`codex.nvim` will resolve the Codex binary using the first match of:

1. `vim.env.CODEX_CLI`, `CODEX_BIN`, or `CODEX_PATH`
2. `vim.fn.exepath("codex")`
3. Literal `"codex"` (letting your `$PATH` resolve it)

If none of these work, a warning is emitted when you try to open the terminal.
Override `terminal.cmd` to point at a custom script or pass additional CLI
arguments.

## Roadmap

This MVP focuses on reliable terminal management and file/selection helpers. The
next set of improvements will look at richer Codex protocol integrations such
as diff management and custom sessions. Contributions are very welcome!
