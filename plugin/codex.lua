if vim.fn.has("nvim-0.8.0") ~= 1 then
  vim.api.nvim_err_writeln("codex.nvim requires Neovim >= 0.8.0")
  return
end

if vim.g.loaded_codex then
  return
end
vim.g.loaded_codex = 1

if vim.g.codex_auto_setup then
  vim.defer_fn(function()
    require("codex").setup(vim.g.codex_auto_setup)
  end, 0)
end

local ok, _ = pcall(require, "codex")
if not ok then
  vim.notify("codex.nvim failed to load. Check your installation.", vim.log.levels.ERROR)
end
