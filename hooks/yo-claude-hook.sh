#! /usr/bin/env bash

# yo-claude — unified hook and statusLine script.
# Handles Stop, UserPromptSubmit, and statusLine (no hook_event_name).

set -euo pipefail
shopt -s nullglob

TRIGGER="${YO_CLAUDE_TRIGGER:-CLAUDE:}"
STALE_MS="${YO_CLAUDE_STALE_MS:-900000}" # 15 minutes

PAYLOAD=$(cat)
CWD=$(jq -r '.cwd' <<< "${PAYLOAD}")
EVENT=$(jq -r '.hook_event_name // ""' <<< "${PAYLOAD}")
PROMPT=$(jq -r '.prompt // ""' <<< "${PAYLOAD}")

# Project ID: hash of cwd (sha256sum on linux, shasum on macos)
if command -v sha256sum &> /dev/null; then
  PROJECT_ID=$(printf '%s' "${CWD}" | sha256sum | cut -c1-16)
else
  PROJECT_ID=$(printf '%s' "${CWD}" | shasum -a 256 | cut -c1-16)
fi
QUEUE_DIR="${HOME}/.claude/yo-claude/${PROJECT_ID}"

# --- statusLine mode: display cwd + queue count ---
if [[ -z ${EVENT} ]]; then
  URL="file://${HOSTNAME:-$(hostname)}${CWD}"
  NAME=${CWD//${HOME}/\~}
  STATUS=$(printf $"\e]8;;%s\e\\%s\e]8;;\e\\" "${URL}" "${NAME}")

  FILES=("${QUEUE_DIR}"/*.json)
  STATUS="${STATUS} [$(printf $"\e[33m%d queued\e[0m" "${#FILES[@]}")]"

  printf '%s\n' "${STATUS}"
  exit 0
fi

# --- hook mode: process queued prompts ---

# Block trivial prompts (e.g. ".") that were only meant to wake the hook
block_if_trivial() {
  if [[ ${EVENT} == "UserPromptSubmit" && ${PROMPT} =~ ^[[:space:]]*[.][[:space:]]*$ ]]; then
    jq -n '{ decision: "block", reason: "yo-claude: nothing queued" }'
    exit 0
  fi
}

# Nothing queued
if [[ ! -d ${QUEUE_DIR} ]]; then
  block_if_trivial
  exit 0
fi

# Collect queue files in order
FILES=("${QUEUE_DIR}"/*.json)
if ! ((${#FILES[@]})); then
  block_if_trivial
  exit 0
fi

# Build context from all queued prompts
CONTEXT="The user has left trigger comment(s) in their code for you to address. Read each file at the referenced line to find the full prompt. Remove each trigger comment when you've addressed it."
NOW_MS=$(($(date +%s) * 1000))
PICKED=0
STOLEN=0
STALE=0

for f in "${FILES[@]}"; do
  ENTRY=$(< "${f}") 2> /dev/null || {
    STOLEN=$((STOLEN + 1))
    continue
  }

  # Check staleness based on filename timestamp
  FILE_TS=$(basename "${f}" .json)
  if ((NOW_MS - FILE_TS > STALE_MS)); then
    rm -f "${f}"
    STALE=$((STALE + 1))
    continue
  fi

  rm -f "${f}"

  # Resolve ~ to $HOME for file access
  SOURCE_FILE=$(jq -r '.file' <<< "${ENTRY}")
  LINE=$(jq -r '.line' <<< "${ENTRY}")
  SOURCE_PATH="${SOURCE_FILE/#\~/${HOME}}"

  # Verify the trigger is still present on the referenced line
  if [[ -f ${SOURCE_PATH} ]]; then
    FILE_LINE=$(sed -n "${LINE}p" "${SOURCE_PATH}")
    if [[ ${FILE_LINE} != *"${TRIGGER}"* ]]; then
      continue
    fi
  fi

  CONTEXT="${CONTEXT}"$'\n'"- ${SOURCE_FILE}:${LINE}"
  PICKED=$((PICKED + 1))
done

if ((STOLEN || STALE)); then
  NOTES=""
  if ((STOLEN)); then
    NOTES="${STOLEN} prompt(s) already picked up by another session. "
  fi
  if ((STALE)); then
    NOTES="${NOTES}${STALE} prompt(s) were stale and discarded."
  fi
  CONTEXT="${CONTEXT}"$'\n\n'"(Note: ${NOTES})"
fi

# Nothing left after filtering
if ! ((PICKED)); then
  block_if_trivial
  exit 0
fi

# Output as additional context for Claude's next turn
if [[ ${EVENT} == "UserPromptSubmit" ]]; then
  jq -n --arg ctx "${CONTEXT}" '{
    hookSpecificOutput: {
      hookEventName: "UserPromptSubmit",
      additionalContext: $ctx
    }
  }'
else
  jq -n --arg ctx "${CONTEXT}" '{
    decision: "block",
    reason: $ctx
  }'
fi
