#! /usr/bin/env bash

# Removes the yo-claude hooks from ~/.claude/settings.json

set -euo pipefail

SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)
HOOK_PATH="${SCRIPT_DIR}/hooks/yo-claude-hook.sh"
SETTINGS="${HOME}/.claude/settings.json"

if [[ ! -f ${SETTINGS} ]]; then
  echo "Nothing to uninstall — ${SETTINGS} not found."
  exit 0
fi

if ! command -v jq &>/dev/null; then
  echo "Error: jq is required" >&2
  exit 1
fi

EVENTS=(Stop UserPromptSubmit)

for event in "${EVENTS[@]}"; do
  UPDATED=$(jq --arg cmd "${HOOK_PATH}" "
    if .hooks.${event} then
      .hooks.${event} |= map(select(.hooks | all(.command != \$cmd))) |
      if .hooks.${event} == [] then del(.hooks.${event}) else . end |
      if .hooks == {} then del(.hooks) else . end
    else . end
  " "${SETTINGS}")
  echo "${UPDATED}" >"${SETTINGS}"
done

echo "Removed yo-claude hooks from ${SETTINGS}"
