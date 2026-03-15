local M = {}

---@param bufnr integer
---@param lines string[]
---@param filetype? string
function M.set_buf(bufnr, lines, filetype)
  vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, lines)
  if filetype then
    vim.bo[bufnr].filetype = filetype
  end
end

---@param dir string
---@return string[]
function M.list_json_files(dir)
  local files = {}
  local handle = vim.uv.fs_scandir(dir)
  if not handle then
    return files
  end
  while true do
    local name, typ = vim.uv.fs_scandir_next(handle)
    if not name then
      break
    end
    if typ == "file" and name:match("%.json$") then
      table.insert(files, dir .. "/" .. name)
    end
  end
  table.sort(files)
  return files
end

---@param dir string
function M.rmdir(dir)
  local handle = vim.uv.fs_scandir(dir)
  if not handle then
    return
  end
  while true do
    local name, typ = vim.uv.fs_scandir_next(handle)
    if not name then
      break
    end
    local path = dir .. "/" .. name
    if typ == "directory" then
      M.rmdir(path)
    else
      vim.uv.fs_unlink(path)
    end
  end
  vim.uv.fs_rmdir(dir)
end

return M
