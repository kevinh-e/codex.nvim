if vim.fn.has("nvim-0.8.0") ~= 1 then
  vim.api.nvim_err_writeln("codex.nvim requires Neovim >= 0.8.0")
  return
end

if vim.g.loaded_codex then
  return
end
vim.g.loaded_codex = 1

local ok, codex = pcall(require, "codex")
if not ok then
  vim.notify("codex.nvim failed to load. Check your installation.", vim.log.levels.ERROR)
  return
end

local auto_opts = vim.g.codex_auto_setup
if auto_opts ~= false then
  local opts = type(auto_opts) == "table" and auto_opts or nil
  vim.defer_fn(function()
    if codex.is_configured and codex.is_configured() then
      return
    end
    codex.setup(opts)
  end, 0)
end
