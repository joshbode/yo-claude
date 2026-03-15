local M = {}

---@class yo-claude.Trigger
---@field line integer

---@param bufnr integer
---@param trigger string
---@return yo-claude.Trigger[]?
local function scan_treesitter(bufnr, trigger)
  local ok, parser = pcall(vim.treesitter.get_parser, bufnr)
  if not ok or not parser then
    return nil
  end
  ---@cast parser vim.treesitter.LanguageTree

  ---@type yo-claude.Trigger[]
  local results = {}

  parser:for_each_tree(function(tree, lang_tree)
    local lang = lang_tree:lang()
    local query_ok, query = pcall(vim.treesitter.query.get, lang, "highlights")
    if not query_ok or not query then
      return
    end
    ---@cast query vim.treesitter.Query

    local root = tree:root()
    for id, node in query:iter_captures(root, bufnr, 0, -1) do
      local name = query.captures[id]
      if name and (name == "comment" or vim.startswith(name, "comment.")) then
        local text = vim.treesitter.get_node_text(node, bufnr)
        if text:find(trigger, 1, true) then
          local row = select(1, node:range()) + 1
          table.insert(results, { line = row })
        end
      end
    end
  end)

  return results
end

---@param bufnr integer
---@param trigger string
---@return yo-claude.Trigger[]
local function scan_lines(bufnr, trigger)
  ---@type yo-claude.Trigger[]
  local results = {}
  local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
  for i, line in ipairs(lines) do
    if line:find(trigger, 1, true) then
      table.insert(results, { line = i })
    end
  end
  return results
end

---@param bufnr integer
---@param trigger string
---@return yo-claude.Trigger[]
function M.find_triggers(bufnr, trigger)
  return scan_treesitter(bufnr, trigger) or scan_lines(bufnr, trigger)
end

return M
