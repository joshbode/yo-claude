# yo-claude

Leave trigger comments in your code. Claude Code picks them up automatically.

```typescript
// CLAUDE: refactor this to use async/await
function fetchData(url: string) {
  return fetch(url).then((r) => r.json());
}
```

## How it works

1. You write a trigger comment (default prefix: `CLAUDE:`) anywhere in your code
2. Your editor scans for trigger comments and queues their location
3. Claude Code's hook fires when it finishes a task (or when you send a message)
4. The hook reads the queue, verifies the comment is still there, and tells Claude
5. Claude reads the file, addresses the prompt, and removes the trigger comment

Remove the comment or delete the queue file to withdraw a request before it's
picked up.

If Claude is idle when you queue a comment, type `.` and press Enter to wake it
up. The hook will pick up the queued work without wasting a model request.

## Installation

### Hook (required)

The hook script integrates with Claude Code's
[hooks](https://code.claude.com/docs/en/hooks) system. Run from the repo root:

```sh
./install.sh
```

This registers the hook for both `Stop` and `UserPromptSubmit` events in
`~/.claude/settings.json`.

To uninstall:

```sh
./uninstall.sh
```

### Editor Plugin

- [Neovim](editors/nvim/README.md)

## Configuration

### Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `YO_CLAUDE_TRIGGER` | `CLAUDE:` | Trigger prefix to look for in comments. Shared between the hook and editor plugins. |
| `YO_CLAUDE_STALE_MS` | `900000` (15 min) | Queue entries older than this are discarded. |

Environment variables take precedence over editor plugin configuration to ensure
the hook and editor agree on the trigger prefix.

## Architecture

yo-claude is editor-agnostic by design. The queue format and hook script work
independently of any editor — see [spec/queue-format.md](spec/queue-format.md).

```
yo-claude/
  hooks/            # Claude Code hook script (editor-agnostic)
  editors/
    nvim/           # Neovim plugin
  spec/             # Queue format specification
```

Editor plugins are thin clients that scan for trigger comments and write queue
files. The hook script does the rest.

## Development

[mise](https://mise.jdx.dev/) manages all tooling (neovim, shellcheck, shfmt,
stylua, bats, etc.):

```sh
mise trust
mise install
```

Run linters and tests:

```sh
mise run check    # shellcheck, shfmt, stylua, emmylua_check
mise run test     # lua tests (headless neovim) + hook tests (bats)
```

### Pre-commit hook

Install the git pre-commit hook to lint and test changed files automatically:

```sh
mise run pre-commit:install
```

## Requirements

- [Claude Code](https://code.claude.com/) CLI
- [jq](https://jqlang.github.io/jq/)

## License

MIT
