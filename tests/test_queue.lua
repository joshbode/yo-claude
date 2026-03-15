local helpers = require("tests.helpers")
local queue = require("yo-claude.queue")

local TEST_ROOT = vim.fn.tempname() .. "/yo-claude-test-project"

local function setup()
  -- Clean up any previous test state
  local id = vim.fn.sha256(TEST_ROOT):sub(1, 16)
  local dir = vim.fn.expand("~/.claude/yo-claude/" .. id)
  helpers.rmdir(dir)
end

local function test_push_creates_file()
  setup()

  queue.push(TEST_ROOT, { file = "~/test/foo.lua", line = 42 })

  local id = vim.fn.sha256(TEST_ROOT):sub(1, 16)
  local dir = vim.fn.expand("~/.claude/yo-claude/" .. id)
  local files = helpers.list_json_files(dir)
  assert(#files == 1, "expected 1 queue file, got " .. #files)

  local content = vim.fn.readfile(files[1])
  local entry = vim.json.decode(table.concat(content))
  assert(entry.file == "~/test/foo.lua", "unexpected file: " .. entry.file)
  assert(entry.line == 42, "unexpected line: " .. entry.line)

  helpers.rmdir(dir)
  print("  PASS: push creates queue file")
end

local function test_push_multiple()
  setup()

  queue.push(TEST_ROOT, { file = "~/test/a.lua", line = 1 })
  -- Ensure distinct timestamps
  vim.uv.sleep(2)
  queue.push(TEST_ROOT, { file = "~/test/b.lua", line = 2 })

  local id = vim.fn.sha256(TEST_ROOT):sub(1, 16)
  local dir = vim.fn.expand("~/.claude/yo-claude/" .. id)
  local files = helpers.list_json_files(dir)
  assert(#files == 2, "expected 2 queue files, got " .. #files)

  -- Files should be sorted by timestamp (oldest first)
  local c1 = vim.json.decode(table.concat(vim.fn.readfile(files[1])))
  local c2 = vim.json.decode(table.concat(vim.fn.readfile(files[2])))
  assert(c1.file == "~/test/a.lua", "first file should be a.lua")
  assert(c2.file == "~/test/b.lua", "second file should be b.lua")

  helpers.rmdir(dir)
  print("  PASS: push multiple creates ordered files")
end

local function test_push_atomic()
  setup()

  queue.push(TEST_ROOT, { file = "~/test/foo.lua", line = 1 })

  local id = vim.fn.sha256(TEST_ROOT):sub(1, 16)
  local dir = vim.fn.expand("~/.claude/yo-claude/" .. id)

  -- No .tmp files should remain
  local handle = vim.uv.fs_scandir(dir)
  assert(handle, "queue dir should exist")
  while true do
    local name = vim.uv.fs_scandir_next(handle)
    if not name then
      break
    end
    assert(not name:match("%.tmp$"), "found leftover .tmp file: " .. name)
  end

  helpers.rmdir(dir)
  print("  PASS: push is atomic (no .tmp files remain)")
end

print("test_queue:")
test_push_creates_file()
test_push_multiple()
test_push_atomic()
