local queue = require("yo-claude.queue")
local scan = require("yo-claude.scan")

---@class yo-claude.Config
---@field trigger string Prefix to look for in comments
---@field scan_on vim.api.keyset.events[] Autocmd events that trigger a scan
---@field keymap? string Keymap for manual scanning
---@field root_markers string[] Markers used to find the project root

local M = {}

---@type table<integer, integer>
local last_changedtick = {}

---@type boolean
M.enabled = true

---@type yo-claude.Config
local defaults = {
  trigger = vim.env.YO_CLAUDE_TRIGGER or "CLAUDE:",
  scan_on = {},
  keymap = nil,
  root_markers = { ".git", ".hg", ".svn", ".root" },
}

---@type yo-claude.Config
M.config = vim.deepcopy(defaults)

---@param opts? yo-claude.Config
function M.setup(opts)
  if opts then
    M.config = vim.tbl_deep_extend("force", defaults, opts) --[[@as yo-claude.Config]]
  end
  if vim.env.YO_CLAUDE_TRIGGER then
    M.config.trigger = vim.env.YO_CLAUDE_TRIGGER
  end

  if M.config.scan_on and #M.config.scan_on > 0 then
    local group = vim.api.nvim_create_augroup("yo-claude", { clear = true })
    vim.api.nvim_create_autocmd(M.config.scan_on, {
      group = group,
      callback = function(args)
        if M.enabled then
          M.scan_and_queue(args.buf)
        end
      end,
    })
  end

  if M.config.keymap then
    vim.keymap.set("n", M.config.keymap, function()
      M.scan_and_queue(0)
    end, { desc = "yo-claude: scan and queue trigger comments" })
  end

  vim.api.nvim_create_user_command("YoClaudeToggle", function()
    M.enabled = not M.enabled
    vim.notify("yo-claude: scanning " .. (M.enabled and "enabled" or "disabled"))
  end, {})
end

---@param bufnr integer
---@return string
local function find_project_root(bufnr)
  -- Try filesystem markers first (matches Claude's cwd)
  local root = vim.fs.root(bufnr, M.config.root_markers)
  if root then
    return root
  end
  -- Fall back to LSP root
  local clients = vim.lsp.get_clients({ bufnr = bufnr })
  for _, client in ipairs(clients) do
    if client.root_dir then
      return client.root_dir
    end
  end
  return vim.fn.getcwd()
end

---@param bufnr integer
function M.scan_and_queue(bufnr)
  bufnr = bufnr == 0 and vim.api.nvim_get_current_buf() or bufnr

  local tick = vim.api.nvim_buf_get_var(bufnr, "changedtick")
  if last_changedtick[bufnr] == tick then
    return
  end
  last_changedtick[bufnr] = tick

  local triggers = scan.find_triggers(bufnr, M.config.trigger)
  if #triggers == 0 then
    return
  end

  local file = vim.fn.fnamemodify(vim.api.nvim_buf_get_name(bufnr), ":~")
  local project_root = find_project_root(bufnr)

  for _, t in ipairs(triggers) do
    queue.push(project_root, {
      file = file,
      line = t.line,
    })
  end

  vim.notify(string.format("yo-claude: queued %d prompt(s)", #triggers), vim.log.levels.INFO)
end

return M
