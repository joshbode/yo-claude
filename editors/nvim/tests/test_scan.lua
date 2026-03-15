local helpers = require("tests.helpers")
local scan = require("yo-claude.scan")

local function test_find_triggers_plain_text()
  local buf = vim.api.nvim_create_buf(false, true)
  helpers.set_buf(buf, {
    "local x = 1",
    "-- CLAUDE: fix this",
    "local y = 2",
    "-- CLAUDE: and this",
  })

  local triggers = scan.find_triggers(buf, "CLAUDE:")
  assert(#triggers == 2, "expected 2 triggers, got " .. #triggers)
  assert(triggers[1].line == 2, "expected line 2, got " .. triggers[1].line)
  assert(triggers[2].line == 4, "expected line 4, got " .. triggers[2].line)

  vim.api.nvim_buf_delete(buf, { force = true })
  print("  PASS: find_triggers plain text")
end

local function test_find_triggers_none()
  local buf = vim.api.nvim_create_buf(false, true)
  helpers.set_buf(buf, {
    "local x = 1",
    "local y = 2",
  })

  local triggers = scan.find_triggers(buf, "CLAUDE:")
  assert(#triggers == 0, "expected 0 triggers, got " .. #triggers)

  vim.api.nvim_buf_delete(buf, { force = true })
  print("  PASS: find_triggers no matches")
end

local function test_find_triggers_custom_prefix()
  local buf = vim.api.nvim_create_buf(false, true)
  helpers.set_buf(buf, {
    "-- TODO: something",
    "-- YO: do this",
    "local x = 1",
  })

  local triggers = scan.find_triggers(buf, "YO:")
  assert(#triggers == 1, "expected 1 trigger, got " .. #triggers)
  assert(triggers[1].line == 2, "expected line 2, got " .. triggers[1].line)

  vim.api.nvim_buf_delete(buf, { force = true })
  print("  PASS: find_triggers custom prefix")
end

local function test_find_triggers_inline()
  local buf = vim.api.nvim_create_buf(false, true)
  helpers.set_buf(buf, {
    "local x = 1 -- CLAUDE: fix this",
    "local y = 2",
  })

  local triggers = scan.find_triggers(buf, "CLAUDE:")
  assert(#triggers == 1, "expected 1 trigger, got " .. #triggers)
  assert(triggers[1].line == 1, "expected line 1, got " .. triggers[1].line)

  vim.api.nvim_buf_delete(buf, { force = true })
  print("  PASS: find_triggers inline comment")
end

print("test_scan:")
test_find_triggers_plain_text()
test_find_triggers_none()
test_find_triggers_custom_prefix()
test_find_triggers_inline()
