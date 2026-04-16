# nvim-patch-plugin

A Neovim plugin for quickly applying patches with a clean workflow.

## Features

- Opens a dedicated buffer for pasting patches
- Applies patches with automatic fallback (`-p1` → `-p0`)
- Reloads affected files automatically
- Opens vertical diffsplit to review changes
- Simple one-command workflow

## Installation

### lazy.nvim

```lua
{
  "yourname/nvim-patch-plugin",
  config = function()
    require("nvim-patch-plugin").setup()
  end
}
```

### packer.nvim

```lua
use {
  "yourname/nvim-patch-plugin",
  config = function()
    require("nvim-patch-plugin").setup()
  end
}
```

## Usage

1. Run `:Code` (or `:code`)
2. Paste your patch content into the buffer
3. Press `<Enter>` to apply, or `<Esc>` to cancel

The plugin will:
- Apply the patch (tries `-p1` first, falls back to `-p0`)
- Reload all affected files
- Open a vertical diffsplit to review changes

## Workflow

```
:Code           → Opens patch buffer
[paste patch]   → Paste your diff content
<Enter>         → Apply patch, reload files, show diff
```

## How it works

1. Creates a temporary buffer named `patch-input`
2. Parses patch content to detect affected files
3. Applies using `patch` command with automatic level detection
4. Reloads all modified files that are currently open
5. Opens diffsplit on the first affected file

## Requirements

- Neovim 0.5+
- `patch` command-line utility (standard on Unix-like systems)
