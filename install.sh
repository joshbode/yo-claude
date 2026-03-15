#! /usr/bin/env bash

# Installs the yo-claude hooks into ~/.claude/settings.json

set -euo pipefail

SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)
HOOK_PATH="${SCRIPT_DIR}/hooks/yo-claude-hook.sh"
SETTINGS="${HOME}/.claude/settings.json"

if [[ ! -f ${HOOK_PATH} ]]; then
  echo "Error: hook script not found at ${HOOK_PATH}" >&2
  exit 1
fi

if ! command -v jq &> /dev/null; then
  echo "Error: jq is required" >&2
  exit 1
fi

# Ensure settings file exists
if [[ ! -f ${SETTINGS} ]]; then
  mkdir -p "$(dirname "${SETTINGS}")"
  echo '{}' > "${SETTINGS}"
fi

# shellcheck disable=SC2016
HOOK_ENTRY='[{ "matcher": "", "hooks": [{ "type": "command", "command": $cmd }] }]'
EVENTS=(Stop UserPromptSubmit)
INSTALLED=0

for event in "${EVENTS[@]}"; do
  # Skip if already installed for this event
  if jq -e --arg cmd "${HOOK_PATH}" ".hooks.${event} // [] | map(.hooks // []) | flatten | map(select(.command == \$cmd)) | length > 0" "${SETTINGS}" &> /dev/null; then
    echo "yo-claude ${event} hook is already installed."
    continue
  fi

  UPDATED=$(jq --arg cmd "${HOOK_PATH}" "
    .hooks //= {} |
    .hooks.${event} //= [] |
    .hooks.${event} += ${HOOK_ENTRY}
  " "${SETTINGS}")
  echo "${UPDATED}" > "${SETTINGS}"
  echo "Installed yo-claude ${event} hook."
  INSTALLED=$((INSTALLED + 1))
done

if ! ((INSTALLED)); then
  echo "Nothing to do — all hooks already installed."
fi
