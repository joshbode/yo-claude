local M = {}

---@class yo-claude.QueueEntry
---@field file string
---@field line integer

---@param path string
---@return string
local function project_id(path)
  return vim.fn.sha256(path):sub(1, 16)
end

---@param project_root string
---@return string
local function queue_dir(project_root)
  local id = project_id(project_root)
  return vim.fn.expand("~/.claude/yo-claude/" .. id)
end

---@param project_root string
---@param entry yo-claude.QueueEntry
function M.push(project_root, entry)
  local dir = queue_dir(project_root)
  vim.fn.mkdir(dir, "p")

  local s, us = vim.uv.gettimeofday()
  assert(s, "yo-claude: failed to get time of day")
  local timestamp = tostring(s * 1000 + math.floor(us / 1000))
  local path = dir .. "/" .. timestamp .. ".json"

  local tmp = path .. ".tmp"
  local f = io.open(tmp, "w")
  if not f then
    return
  end
  f:write(vim.json.encode(entry))
  f:close()
  vim.uv.fs_rename(tmp, path)
end

return M
