---@brief Entry point for codex.nvim.
---@module codex

local config = require("codex.config")
local logger = require("codex.logger")
local terminal = require("codex.terminal")
local selection = require("codex.selection")
local utils = require("codex.utils")

local M = {}

local current_config = config.defaults()
local commands_created = false
local configured = false

function M.is_configured()
  return configured
end

local function resolve_workspace_root()
  return current_config.terminal and current_config.terminal.cwd or vim.loop.cwd()
end

local function relative_path(path)
  return utils.relative_path(path, resolve_workspace_root())
end

local function create_commands()
  if commands_created then
    return
  end

  vim.api.nvim_create_user_command("Codex", function()
    terminal.toggle()
  end, { desc = "Toggle Codex terminal" })

  vim.api.nvim_create_user_command("CodexFocus", function()
    terminal.focus()
  end, { desc = "Focus Codex terminal" })

  vim.api.nvim_create_user_command("CodexSend", function(opts)
    if opts.args ~= "" then
      terminal.send(opts.args)
      return
    end

    if opts.range == 0 then
      logger.warn("commands", "No range supplied to CodexSend")
      return
    end

    local bufnr = vim.api.nvim_get_current_buf()
    local lines = selection.get_range_lines(bufnr, opts.line1, opts.line2)
    if #lines == 0 then
      logger.warn("commands", "CodexSend range produced no content")
      return
    end
    terminal.send(lines)
  end, {
    desc = "Send selection or text to Codex",
    range = true,
    nargs = "*",
  })

  vim.api.nvim_create_user_command("CodexAdd", function(opts)
    local path
    if opts.args ~= "" then
      path = vim.fn.fnamemodify(opts.args, ":p")
    else
      path = utils.buffer_path()
    end

    if not path then
      logger.warn("commands", "No path resolved for CodexAdd")
      return
    end

    local mention_path = relative_path(path) or path
    local range

    if opts.range ~= 0 then
      local bufnr = vim.api.nvim_get_current_buf()
      local _, start_idx, end_idx = selection.get_range_lines(bufnr, opts.line1, opts.line2)
      range = { start_line = start_idx, end_line = end_idx }
    end

    terminal.send_mention(mention_path, range)
  end, {
    desc = "Mention a file (or range) to Codex",
    range = true,
    nargs = "?",
    complete = "file",
  })

  commands_created = true
end

---@param opts table|nil
function M.setup(opts)
  current_config = config.resolve(opts)
  logger.set_level(current_config.log_level or "warn")

  terminal.setup(current_config.terminal, current_config.mention)
  create_commands()

  if current_config.auto_start then
    vim.schedule(function()
      terminal.open(current_config.terminal.focus_on_open ~= false)
    end)
  end

  configured = true
  return current_config
end

function M.toggle()
  terminal.toggle()
end

function M.focus()
  terminal.focus()
end

function M.send(text)
  terminal.send(text)
end

function M.mention(path, range)
  local resolved = path or utils.buffer_path()
  if not resolved then
    logger.warn("mention", "No path provided to Codex mention")
    return
  end
  local mention_path = relative_path(resolved) or resolved
  terminal.send_mention(mention_path, range)
end

---@return table
function M.current_config()
  return current_config
end

return M
