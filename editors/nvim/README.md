# yo-claude.nvim

Neovim plugin for [yo-claude](../../README.md) — leave trigger comments in your
code and have Claude Code pick them up automatically.

## Installation

### lazy.nvim

```lua
{
  'joshbode/yo-claude',
  subdir = 'editors/nvim',
  opts = {},
}
```

### packer.nvim

```lua
use {
  'joshbode/yo-claude',
  rtp = 'editors/nvim',
  config = function()
    require('yo-claude').setup()
  end,
}
```

### vim-plug

```vim
Plug 'joshbode/yo-claude', { 'rtp': 'editors/nvim' }
lua require('yo-claude').setup()
```

### mini.deps

```lua
MiniDeps.add({
  source = 'joshbode/yo-claude',
  hooks = {
    post_install = function(args)
      vim.opt.runtimepath:append(args.path .. '/editors/nvim')
    end,
  },
})
require('yo-claude').setup()
```

## Options

```lua
require('yo-claude').setup({
  -- Prefix to look for in comments (default: 'CLAUDE:')
  -- Overridden by $YO_CLAUDE_TRIGGER if set
  trigger = 'CLAUDE:',

  -- Autocmd events that trigger a scan (default: {})
  -- Example: { 'BufWritePost' } to scan on save
  scan_on = {},

  -- Optional keymap for manual scanning (default: nil)
  keymap = '<leader>c',

  -- Markers used to find the project root (default below)
  -- The project root must match Claude Code's working directory
  root_markers = { '.git', '.hg', '.svn', '.root' },
})
```

### Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `YO_CLAUDE_TRIGGER` | `CLAUDE:` | Overrides `opts.trigger`. Ensures the editor and hook agree on the prefix. |
| `YO_CLAUDE_STALE_MS` | `900000` (15 min) | Queue entries older than this are discarded by the hook. |

## Commands

| Command | Description |
|---------|-------------|
| `:YoClaudeToggle` | Enable/disable automatic scanning (from `scan_on` events). Manual keymap still works. |

## Hook Installation

The Claude Code hook must also be installed for prompts to be picked up. From
the repo root:

```sh
./install.sh
```

See the [main README](../../README.md) for details.

## Usage

Write a trigger comment anywhere in your code:

```typescript
// CLAUDE: refactor this to use async/await
function fetchData(url: string) {
  return fetch(url).then((r) => r.json());
}
```

On keymap press (or on save if `scan_on = { 'BufWritePost' }`), the comment
location is queued. When Claude Code
finishes its current task, it picks up the queue, reads the file, and addresses
the prompt.

Remove the comment before Claude picks it up to withdraw the request.
