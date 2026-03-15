local yo_claude = require("yo-claude")

local function test_defaults()
  -- Reset to defaults
  yo_claude.setup()

  assert(
    yo_claude.config.trigger == (vim.env.YO_CLAUDE_TRIGGER or "CLAUDE:"),
    "unexpected default trigger"
  )
  assert(type(yo_claude.config.scan_on) == "table", "scan_on should be a table")
  assert(yo_claude.config.keymap == nil, "keymap should default to nil")
  assert(type(yo_claude.config.root_markers) == "table", "root_markers should be a table")

  print("  PASS: defaults")
end

local function test_setup_merges_opts()
  yo_claude.setup({ trigger = "HEY:", keymap = "<leader>h" })

  assert(
    yo_claude.config.trigger == "HEY:",
    "trigger should be HEY:, got " .. yo_claude.config.trigger
  )
  assert(yo_claude.config.keymap == "<leader>h", "keymap should be <leader>h")
  -- Unspecified fields should keep defaults
  assert(#yo_claude.config.root_markers > 0, "root_markers should keep defaults")

  -- Reset
  yo_claude.setup()
  print("  PASS: setup merges opts")
end

local function test_env_override()
  local original = vim.env.YO_CLAUDE_TRIGGER
  vim.env.YO_CLAUDE_TRIGGER = "TEST:"

  yo_claude.setup({ trigger = "IGNORED:" })
  assert(
    yo_claude.config.trigger == "TEST:",
    "env should override opts, got " .. yo_claude.config.trigger
  )

  vim.env.YO_CLAUDE_TRIGGER = original
  yo_claude.setup()
  print("  PASS: env var overrides opts")
end

local function test_toggle()
  yo_claude.enabled = true
  assert(yo_claude.enabled == true)

  -- Simulate the toggle command
  yo_claude.enabled = not yo_claude.enabled
  assert(yo_claude.enabled == false)

  yo_claude.enabled = not yo_claude.enabled
  assert(yo_claude.enabled == true)

  print("  PASS: toggle")
end

print("test_init:")
test_defaults()
test_setup_merges_opts()
test_env_override()
test_toggle()
