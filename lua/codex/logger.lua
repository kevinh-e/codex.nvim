---@brief Minimal logger for codex.nvim.
---@module codex.logger

local M = {}

local levels = {
  error = vim.log.levels.ERROR,
  warn = vim.log.levels.WARN,
  info = vim.log.levels.INFO,
  debug = vim.log.levels.DEBUG,
  trace = vim.log.levels.TRACE,
}

local current_level = levels.warn

---@param level_name string
function M.set_level(level_name)
  local normalized = level_name and level_name:lower() or nil
  current_level = levels[normalized] or levels.warn
end

local function should_log(level)
  return level <= current_level
end

local function fmt_prefix(level, component)
  local parts = { "[codex.nvim]" }
  if component then
    table.insert(parts, "[" .. component .. "]")
  end
  table.insert(parts, "[" .. string.upper(level) .. "]")
  return table.concat(parts, " ")
end

local function log(level_name, component, ...)
  local level_value = levels[level_name]
  if not level_value or not should_log(level_value) then
    return
  end

  local items = { ... }
  for idx, item in ipairs(items) do
    if type(item) == "table" or type(item) == "boolean" then
      items[idx] = vim.inspect(item)
    else
      items[idx] = tostring(item)
    end
  end

  local message = table.concat(items, " ")
  local prefix = fmt_prefix(level_name, component)

  vim.schedule(function()
    if level_value <= vim.log.levels.WARN then
      vim.notify(prefix .. " " .. message, level_value)
    else
      vim.api.nvim_echo({ { prefix .. " " .. message, "None" } }, true, {})
    end
  end)
end

function M.error(component, ...)
  log("error", component, ...)
end

function M.warn(component, ...)
  log("warn", component, ...)
end

function M.info(component, ...)
  log("info", component, ...)
end

function M.debug(component, ...)
  log("debug", component, ...)
end

function M.trace(component, ...)
  log("trace", component, ...)
end

return M
