# yo-claude Queue Format

## Queue Directory

Queue files are stored in:

```
~/.claude/yo-claude/<project-id>/
```

Where `<project-id>` is a deterministic hash of the project root directory path.

## Queue Files

Each queued prompt is a single JSON file named with a millisecond Unix timestamp:

```
1742041845123.json
```

Files sort lexicographically by creation time. The hook processes them in order
and deletes each file after reading it.

## File Schema

```json
{
  "file": "~/repos/project/src/api.ts",
  "line": 42
}
```

| Field  | Type   | Required | Description                                  |
|--------|--------|----------|----------------------------------------------|
| `file` | string | yes      | Absolute file path (`$HOME` replaced with `~`) |
| `line` | number | yes      | Line number where the trigger comment appears |

The queue file is a pointer — Claude reads the actual prompt from the source
file at the referenced line.

## Trigger Detection

Trigger comments are detected by scanning treesitter `comment` nodes for a
configurable prefix (default: `CLAUDE:`).

Examples of trigger comments across languages:

```typescript
// CLAUDE: refactor this to use async/await
```

```python
# CLAUDE: add type hints to this function
```

```lua
-- CLAUDE: simplify this logic
```

## Lifecycle

1. Editor scans for trigger comments and writes queue files (atomic: write to temp, rename)
2. Claude Code's `Stop` hook reads queue files in order
3. Hook verifies the trigger is still present on the referenced line
4. Hook deletes the queue file and outputs the file reference as context
5. Claude reads the source file, addresses the prompt, and removes the trigger comment
6. User can withdraw a prompt by either deleting the queue file or removing the comment
