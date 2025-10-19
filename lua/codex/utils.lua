---@brief Shared helpers for codex.nvim.
---@module codex.utils

local M = {}

---@param bufnr? integer
---@return string|nil
function M.buffer_path(bufnr)
  local buf = bufnr or vim.api.nvim_get_current_buf()
  local name = vim.api.nvim_buf_get_name(buf)
  if not name or name == "" then
    return nil
  end
  return vim.fn.fnamemodify(name, ":p")
end

---@param path string|nil
---@param base string|nil
---@return string|nil
function M.relative_path(path, base)
  if not path then
    return nil
  end
  local root = base or vim.loop.cwd()
  if not root or root == "" then
    return path
  end
  if path:sub(1, #root) == root then
    local trimmed = path:sub(#root + 1)
    if trimmed:sub(1, 1) == "/" then
      trimmed = trimmed:sub(2)
    end
    return trimmed ~= "" and trimmed or path
  end
  return vim.fn.fnamemodify(path, ":.")
end

---@param winid? integer
---@return boolean
function M.is_window_valid(winid)
  return winid and vim.api.nvim_win_is_valid(winid)
end

---@param bufnr? integer
---@return boolean
function M.is_buffer_valid(bufnr)
  return bufnr and vim.api.nvim_buf_is_valid(bufnr)
end

return M
