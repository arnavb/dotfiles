-- Global stuff
vim.g.mapleader = ' '

-- General Keybindings
vim.keymap.set('t', '<Esc>', '<C-\\><C-n>')

-- From https://github.com/folke/lazy.nvim#-installation
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"

if not vim.loop.fs_stat(lazypath) then
  vim.fn.system({
    "git",
    "clone",
    "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    "--branch=stable", -- latest stable release
    lazypath,
  })
end

vim.opt.rtp:prepend(lazypath)

require("lazy").setup({
   'lukas-reineke/indent-blankline.nvim',
   'nvim-treesitter/nvim-treesitter',
   'rebelot/kanagawa.nvim',
   'lewis6991/gitsigns.nvim',
   'numToStr/Comment.nvim',
   'andweeb/presence.nvim',
})

vim.opt.mouse = ""

-- Options
vim.o.termguicolors = true
vim.o.laststatus = 0
vim.o.hlsearch = false
vim.o.ignorecase = true
vim.o.smartcase = true
vim.o.splitbelow = true
vim.o.splitright = true

vim.go.expandtab = true
vim.go.shiftwidth = 4
vim.go.tabstop = 4

vim.o.undofile = true
vim.o.signcolumn = 'yes'
vim.o.number = true
vim.o.relativenumber = true
vim.o.breakindent = true
vim.o.showbreak = "↪ "
vim.o.pumheight = 10

vim.cmd [[ colorscheme kanagawa ]]

-- Treesitter
require('nvim-treesitter.configs').setup {
  ensure_installed = 'all',
  ignore_install = { 'haskell' }, -- Currently broken: https://github.com/tree-sitter/tree-sitter-haskell/issues/34
  highlight = {
    enable = true,
  },
}

-- Autocmds
-- Two space indentation
local indentationGroup = vim.api.nvim_create_augroup('Indentation', { clear = true })
vim.api.nvim_create_autocmd('FileType', {
  pattern = 'lua',
  callback = function()
    vim.opt_local.shiftwidth = 2
    vim.opt_local.tabstop = 2
  end,
  group = indentationGroup,
})

local terminalGroup = vim.api.nvim_create_augroup('Terminal', { clear = true })
-- Hide line numbers in the terminal
vim.api.nvim_create_autocmd('TermOpen', {
  callback = function()
    vim.opt_local.number = false
    vim.opt_local.relativenumber = false
  end,
  group = terminalGroup,
})

require('indent_blankline').setup {
  show_current_context = true,
}
require('Comment').setup()
require('gitsigns').setup()
