#! /usr/bin/env bats

HOOK="${BATS_TEST_DIRNAME}/../hooks/yo-claude-hook.sh"

project_id() {
  if command -v sha256sum &> /dev/null; then
    printf '%s' "$1" | sha256sum | cut -c1-16
  else
    printf '%s' "$1" | shasum -a 256 | cut -c1-16
  fi
}

setup() {
  PROJECT=$(mktemp -d)
  ID=$(project_id "${PROJECT}")
  QUEUE_DIR="${HOME}/.claude/yo-claude/${ID}"
  NOW_MS=$(($(date +%s) * 1000))
}

teardown() {
  rm -rf "${PROJECT}" "${QUEUE_DIR}"
}

payload() {
  jq -n --arg cwd "${PROJECT}" "${@}" '{cwd: $cwd} + $ARGS.named'
}

queue_entry() {
  jq -n --arg file "$1" --argjson line "$2" '{file: $file, line: $line}'
}

@test "no queue dir produces no output" {
  run bash "${HOOK}" <<< '{"cwd":"/nonexistent/path"}'
  [[ ${status} -eq 0 ]]
  [[ -z ${output} ]]
}

@test "empty queue dir produces no output" {
  mkdir -p "${QUEUE_DIR}"
  run bash "${HOOK}" <<< "$(payload)"
  [[ ${status} -eq 0 ]]
  [[ -z ${output} ]]
}

@test "valid entry produces Stop block output" {
  mkdir -p "${QUEUE_DIR}"
  echo '-- CLAUDE: fix this' > "${PROJECT}/test.lua"
  queue_entry "${PROJECT}/test.lua" 1 > "${QUEUE_DIR}/${NOW_MS}.json"

  run bash "${HOOK}" <<< "$(payload)"
  [[ ${status} -eq 0 ]]
  echo "${output}" | jq -e '.decision == "block"'
}

@test "queue file consumed after processing" {
  mkdir -p "${QUEUE_DIR}"
  echo '-- CLAUDE: fix this' > "${PROJECT}/test.lua"
  queue_entry "${PROJECT}/test.lua" 1 > "${QUEUE_DIR}/${NOW_MS}.json"

  bash "${HOOK}" <<< "$(payload)" > /dev/null
  files=("${QUEUE_DIR}"/*.json)
  [[ ${#files[@]} -eq 0 || ! -e ${files[0]} ]]
}

@test "stale entry is discarded" {
  mkdir -p "${QUEUE_DIR}"
  echo '-- CLAUDE: fix this' > "${PROJECT}/test.lua"
  STALE_MS=$((NOW_MS - 1000000))
  queue_entry "${PROJECT}/test.lua" 1 > "${QUEUE_DIR}/${STALE_MS}.json"

  run bash "${HOOK}" <<< "$(payload)"
  [[ ${status} -eq 0 ]]
  [[ -z ${output} ]]
}

@test "entry skipped when trigger removed from source" {
  mkdir -p "${QUEUE_DIR}"
  echo 'local x = 1' > "${PROJECT}/test.lua"
  queue_entry "${PROJECT}/test.lua" 1 > "${QUEUE_DIR}/${NOW_MS}.json"

  run bash "${HOOK}" <<< "$(payload)"
  [[ ${status} -eq 0 ]]
  [[ -z ${output} ]]
}

@test "UserPromptSubmit produces correct output format" {
  mkdir -p "${QUEUE_DIR}"
  echo '-- CLAUDE: fix this' > "${PROJECT}/test.lua"
  queue_entry "${PROJECT}/test.lua" 1 > "${QUEUE_DIR}/${NOW_MS}.json"

  run bash "${HOOK}" <<< "$(payload --arg hook_event_name UserPromptSubmit)"
  [[ ${status} -eq 0 ]]
  echo "${output}" | jq -e '.hookSpecificOutput.hookEventName == "UserPromptSubmit"'
}

@test "multiple entries are all picked up" {
  mkdir -p "${QUEUE_DIR}"
  echo '-- CLAUDE: first' > "${PROJECT}/a.lua"
  echo '-- CLAUDE: second' > "${PROJECT}/b.lua"
  queue_entry "${PROJECT}/a.lua" 1 > "${QUEUE_DIR}/${NOW_MS}.json"
  queue_entry "${PROJECT}/b.lua" 1 > "${QUEUE_DIR}/$((NOW_MS + 1)).json"

  run bash "${HOOK}" <<< "$(payload)"
  [[ ${status} -eq 0 ]]
  echo "${output}" | jq -e '.reason | contains("a.lua:1")'
  echo "${output}" | jq -e '.reason | contains("b.lua:1")'
}
