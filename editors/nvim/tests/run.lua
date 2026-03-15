-- Test runner: discovers and runs all test_*.lua files
local info = debug.getinfo(1, "S")
assert(info, "failed to get debug info")
local test_dir = vim.fn.fnamemodify(info.source:sub(2), ":h")
local files = vim.fn.glob(test_dir .. "/test_*.lua", false, true)
table.sort(files)

local failed = false
for _, f in ipairs(files) do
  local ok, err = pcall(dofile, f)
  if not ok then
    print("FAIL: " .. vim.fn.fnamemodify(f, ":t") .. "\n  " .. err)
    failed = true
  end
end

if failed then
  print("\nSome tests FAILED")
  vim.cmd("cquit! 1")
else
  print("\nAll tests passed")
  vim.cmd("quitall!")
end
