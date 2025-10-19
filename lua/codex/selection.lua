---@brief Selection helpers used by codex.nvim commands.
---@module codex.selection

local M = {}

---@param bufnr integer
---@param first integer 1-based line number
---@param last integer 1-based line number
---@return string[]
---@return integer @zero-based start line
---@return integer @zero-based end line
function M.get_range_lines(bufnr, first, last)
  local start_idx = math.max(first, 1) - 1
  local end_idx = math.max(last, first) - 1
  local lines = vim.api.nvim_buf_get_lines(bufnr, start_idx, end_idx + 1, false)
  return lines, start_idx, end_idx
end

---@return string[]
---@return integer
---@return integer
function M.get_visual_selection()
  local bufnr = vim.api.nvim_get_current_buf()
  local first = vim.fn.line("'<")
  local last = vim.fn.line("'>")
  return M.get_range_lines(bufnr, first, last)
end

---@param lines string[]
---@return string
function M.lines_to_string(lines)
  if #lines == 0 then
    return ""
  end
  return table.concat(lines, "\n")
end

return M
