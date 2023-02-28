-- Global stuff
vim.g.mapleader = ' '

-- General Keybindings
vim.keymap.set('t', '<Esc>', '<C-\\><C-n>')

-- Bootstrap packer.nvim (from: https://github.com/wbthomason/packer.nvim#bootstrapping)
local install_path = vim.fn.stdpath 'data' .. '/site/pack/packer/opt/packer.nvim'

if vim.fn.empty(vim.fn.glob(install_path)) > 0 then
  vim.fn.system { 'git', 'clone', 'https://github.com/wbthomason/packer.nvim', install_path }
  vim.api.nvim_command 'packadd packer.nvim'
end

vim.cmd 'packadd packer.nvim'

require('packer').startup(function(use)
  use 'wbthomason/packer.nvim'

  use 'lukas-reineke/indent-blankline.nvim'
  use { 'nvim-treesitter/nvim-treesitter', run = ':TSUpdate' }

  use 'L3MON4D3/LuaSnip'

  use 'rebelot/kanagawa.nvim'

  use {
    'lewis6991/gitsigns.nvim',
    requires = {
      'nvim-lua/plenary.nvim',
    },
  }

  use 'numToStr/Comment.nvim'

  use 'andweeb/presence.nvim'
end)


-- Options
vim.o.termguicolors = true
vim.o.laststatus = 0
vim.o.hlsearch = false
vim.o.ignorecase = true
vim.o.smartcase = true
vim.o.splitbelow = true
vim.o.splitright = true

vim.bo.expandtab = true
vim.bo.shiftwidth = 4
vim.bo.tabstop = 4
vim.bo.undofile = true

vim.wo.signcolumn = 'yes'
vim.wo.number = true
vim.wo.relativenumber = true
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
    vim.bo.shiftwidth = 2
    vim.bo.tabstop = 2
  end,
  group = indentationGroup,
})

local terminalGroup = vim.api.nvim_create_augroup('Terminal', { clear = true })
-- Hide line numbers in the terminal
vim.api.nvim_create_autocmd('TermOpen', {
  callback = function()
    vim.wo.number = false
    vim.wo.relativenumber = false
  end,
  group = terminalGroup,
})

require('indent_blankline').setup {
  show_current_context = true,
}
require('Comment').setup()
require('gitsigns').setup()
