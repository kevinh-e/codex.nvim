---@brief Configuration helpers for codex.nvim.
---@module codex.config

local M = {}

local function default_terminal_cmd()
  local env_path = vim.env.CODEX_CLI or vim.env.CODEX_BIN or vim.env.CODEX_PATH
  if env_path and env_path ~= "" then
    return { env_path }
  end

  local exepath = vim.fn.exepath("codex")
  if exepath ~= nil and exepath ~= "" then
    return { exepath }
  end

  -- Fall back to plain command; termopen will still try PATH
  return { "codex" }
end

local defaults = {
  auto_start = false,
  log_level = "warn",
  terminal = {
    ---@type string|string[]|fun():string|string[]
    cmd = default_terminal_cmd,
    ---@type "vertical"|"horizontal"
    layout = "vertical",
    width = 50,
    height = 15,
    focus_on_open = true,
    env = {},
    cwd = nil,
  },
  mention = {
    prefix = "@",
    include_line_numbers = true,
  },
}

---@return table
function M.defaults()
  return vim.deepcopy(defaults)
end

---Merge user options with defaults.
---@param opts table|nil
---@return table
function M.resolve(opts)
  if opts == nil then
    return M.defaults()
  end
  return vim.tbl_deep_extend("force", M.defaults(), opts)
end

return M
