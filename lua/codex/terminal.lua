---@brief Terminal management for codex.nvim.
---@module codex.terminal

local logger = require("codex.logger")
local utils = require("codex.utils")

local M = {}

---@class CodexTerminalState
---@field config table
---@field mention table
---@field job_id integer|nil
---@field bufnr integer|nil
---@field winid integer|nil
local state = {
  config = nil,
  mention = {},
  job_id = nil,
  bufnr = nil,
  winid = nil,
}

local function command_head(cmd)
  if type(cmd) == "string" then
    if cmd:find("%s") then
      return cmd:match("^%S+")
    end
    return cmd
  elseif type(cmd) == "table" then
    return cmd[1]
  end
end

local function format_command(cmd)
  if type(cmd) == "string" then
    return cmd
  elseif type(cmd) == "table" then
    local parts = {}
    for _, part in ipairs(cmd) do
      table.insert(parts, tostring(part))
    end
    return table.concat(parts, " ")
  end
  return "<invalid>"
end

---@param config table
---@param mention table
function M.setup(config, mention)
  state.config = config
  state.mention = mention or {}
end

local function resolve_cmd()
  local cmd = state.config and state.config.cmd
  if type(cmd) == "function" then
    local ok, result = pcall(cmd)
    if not ok then
      return nil, result
    end
    cmd = result
  end

  if type(cmd) == "string" or type(cmd) == "table" then
    local head = command_head(cmd)
    if type(head) == "string" and head ~= "" then
      if vim.fn.executable(head) == 0 then
        logger.warn(
          "terminal",
          string.format(
            "Codex command '%s' is not executable. Adjust terminal.cmd or export CODEX_CLI.",
            format_command(cmd)
          )
        )
      end
    end
    return cmd, nil
  end

  return nil, "terminal.cmd must be a string, list, or function returning one"
end

local function job_running()
  if not state.job_id then
    return false
  end

  local status = vim.fn.jobwait({ state.job_id }, 0)
  return status[1] == -1
end

local function decide_focus(explicit)
  local cfg = state.config or {}
  if explicit ~= nil then
    return explicit
  end
  return cfg.focus_on_open ~= false
end

local function open_split(should_focus)
  local cfg = state.config or {}
  local layout = cfg.layout or "vertical"
  local previous_win = vim.api.nvim_get_current_win()

  if layout == "horizontal" then
    vim.cmd("botright split")
    local target_height = cfg.height or 15
    pcall(vim.api.nvim_win_set_height, 0, target_height)
  else
    vim.cmd("botright vsplit")
    local target_width = cfg.width or 50
    pcall(vim.api.nvim_win_set_width, 0, target_width)
  end

  local win = vim.api.nvim_get_current_win()
  if not should_focus and vim.api.nvim_win_is_valid(previous_win) then
    vim.schedule(function()
      if vim.api.nvim_win_is_valid(previous_win) then
        vim.api.nvim_set_current_win(previous_win)
      end
    end)
  end
  return win
end

local function attach_buffer(win, bufnr)
  vim.api.nvim_win_set_buf(win, bufnr)
  vim.bo[bufnr].bufhidden = "hide"
  vim.bo[bufnr].filetype = "codex-terminal"
  vim.bo[bufnr].modifiable = false
end

local function ensure_window(focus)
  local should_focus = decide_focus(focus)
  if utils.is_window_valid(state.winid) then
    if should_focus then
      vim.api.nvim_set_current_win(state.winid)
    end
    return state.winid
  end

  local win = open_split(should_focus)
  if utils.is_buffer_valid(state.bufnr) then
    attach_buffer(win, state.bufnr)
  end
  state.winid = win
  return win
end

local function start_terminal(focus)
  local cmd, err = resolve_cmd()
  if not cmd then
    logger.error("terminal", "Unable to resolve command:", err)
    return false
  end

  local should_focus = decide_focus(focus)
  local win = open_split(should_focus)
  local buf = vim.api.nvim_create_buf(false, true)
  attach_buffer(win, buf)

  local opts = {
    cwd = state.config and state.config.cwd or nil,
    env = state.config and state.config.env or nil,
    on_exit = function(_, code)
      logger.info("terminal", "Codex terminal exited with code", code)
      state.job_id = nil
      state.winid = nil
      state.bufnr = nil
    end,
  }

  local job_id = vim.fn.termopen(cmd, opts)
  if job_id == 0 then
    logger.error("terminal", "Failed to spawn codex terminal")
    return false
  end

  state.job_id = job_id
  state.bufnr = buf
  state.winid = win

  if should_focus then
    vim.api.nvim_set_current_win(win)
    vim.cmd("startinsert")
  end

  return true
end

---@param focus boolean|nil
---@return boolean
function M.open(focus)
  if job_running() then
    local should_focus = decide_focus(focus)
    ensure_window(should_focus)
    if should_focus then
      vim.cmd("startinsert")
    end
    return true
  end

  return start_terminal(focus)
end

function M.toggle()
  if utils.is_window_valid(state.winid) then
    vim.api.nvim_win_close(state.winid, true)
    state.winid = nil
    return
  end

  M.open(true)
end

function M.focus()
  if not M.open(true) then
    logger.warn("terminal", "Codex terminal is not running")
  end
end

function M.close()
  if job_running() then
    if utils.is_buffer_valid(state.bufnr) then
      vim.api.nvim_buf_delete(state.bufnr, { force = true })
    end
  end
  state.job_id = nil
  state.bufnr = nil
  state.winid = nil
end

local function send_chunk(payload)
  if not job_running() then
    local ok = start_terminal(true)
    if not ok then
      return false
    end
  end

  if type(payload) == "table" then
    vim.fn.chansend(state.job_id, payload)
  else
    vim.fn.chansend(state.job_id, payload)
  end
  return true
end

---@param text string|string[]
function M.send(text)
  local payload = text
  if type(text) == "table" then
    payload = vim.tbl_map(function(line)
      if line:sub(-1) == "\n" then
        return line
      end
      return line .. "\n"
    end, text)
  elseif type(text) == "string" and not text:match("\n$") then
    payload = text .. "\n"
  end

  if not send_chunk(payload) then
    logger.error("terminal", "Unable to send payload to Codex process")
  end
end

---@param path string
---@param range { start_line: integer, end_line: integer }|nil
function M.send_mention(path, range)
  if not path then
    logger.warn("terminal", "Attempted to mention empty path")
    return
  end

  local mention_cfg = state.mention or {}
  local prefix = mention_cfg.prefix or "@"
  local text = prefix .. path

  if mention_cfg.include_line_numbers ~= false and range then
    text = string.format("%s:%d:%d", text, range.start_line + 1, range.end_line + 1)
  end

  M.send(text)
end

---@return boolean
function M.is_running()
  return job_running()
end

---@return integer|nil
function M.bufnr()
  return state.bufnr
end

return M
