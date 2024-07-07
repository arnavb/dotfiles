-- Global stuff
vim.g.mapleader = ' '

-- General Keybindings
vim.keymap.set('t', '<Esc>', '<C-\\><C-n>')

-- From https://github.com/folke/lazy.nvim#-installation
local lazypath = vim.fn.stdpath 'data' .. '/lazy/lazy.nvim'

if not vim.loop.fs_stat(lazypath) then
  vim.fn.system {
    'git',
    'clone',
    '--filter=blob:none',
    'https://github.com/folke/lazy.nvim.git',
    '--branch=stable', -- latest stable release
    lazypath,
  }
end

vim.opt.rtp:prepend(lazypath)

require('lazy').setup {
  { 'lukas-reineke/indent-blankline.nvim', main = 'ibl', opts = {} },
  'nvim-treesitter/nvim-treesitter',
  'rebelot/kanagawa.nvim',
  'EdenEast/nightfox.nvim',
  { 'lewis6991/gitsigns.nvim', opts = {} },
  'andweeb/presence.nvim',
  {
    'm4xshen/hardtime.nvim',
    dependencies = {
      'MunifTanjim/nui.nvim',
      'nvim-lua/plenary.nvim',
    },
    opts = {},
  },

  -- LSP
  {
    'neovim/nvim-lspconfig',
    dependencies = {
      { 'williamboman/mason.nvim', opts = {} },
      'williamboman/mason-lspconfig.nvim',
      'WhoIsSethDaniel/mason-tool-installer.nvim',
    },
  },
  {
    'hrsh7th/nvim-cmp',
    dependencies = {
      'L3MON4D3/LuaSnip',
      'saadparwaiz1/cmp_luasnip',
      'rafamadriz/friendly-snippets',
      'hrsh7th/cmp-nvim-lsp',
    },
  },
  {
    'stevearc/conform.nvim',
    opts = {},
  },
  'mfussenegger/nvim-lint',
  {
    'rachartier/tiny-inline-diagnostic.nvim',
    event = 'VeryLazy',
    config = function()
      vim.opt.updatetime = 100
      require('tiny-inline-diagnostic').setup {
        signs = {
          arrow = '',
        },
      }
    end,
  },
  { 'folke/neodev.nvim', opts = {} },
}

vim.opt.mouse = ''

-- Options
vim.o.termguicolors = true
vim.o.laststatus = 0
vim.o.spell = true
vim.o.hlsearch = false
vim.o.ignorecase = true
vim.o.smartcase = true
vim.o.splitbelow = true
vim.o.splitright = true

vim.opt_local.expandtab = true
vim.opt_local.shiftwidth = 4
vim.opt_local.tabstop = 4

vim.o.undofile = true
vim.o.signcolumn = 'yes'
vim.o.number = true
vim.o.relativenumber = true
vim.o.breakindent = true
vim.o.showbreak = '↪ '
vim.o.pumheight = 10

vim.cmd [[ colorscheme carbonfox ]]

require('ibl').setup {
  scope = { enabled = false },
}

-- Treesitter
---@diagnostic disable-next-line: missing-fields
require('nvim-treesitter.configs').setup {
  ensure_installed = 'all',
  highlight = {
    enable = true,
  },
}

local parser_config = require('nvim-treesitter.parsers').get_parser_configs()
parser_config.fsharp = {
  install_info = {
    url = 'https://github.com/ionide/tree-sitter-fsharp',
    branch = 'main',
    files = { 'src/scanner.c', 'src/parser.c' },
  },
  filetype = 'fsharp',
}

local settings = {
  lua_ls = {
    Lua = {
      workspace = { checkThirdParty = false },
      telemetry = { enable = false },
      diagnostics = {
        globals = { 'vim' },
      },
    },
  },
  fsautocomplete = {},
  pyright = {},
  black = {},
  stylua = {},
  luacheck = {},
}

require('mason-tool-installer').setup {
  ensure_installed = vim.tbl_keys(settings),
}

local capabilities = vim.lsp.protocol.make_client_capabilities()
capabilities = require('cmp_nvim_lsp').default_capabilities(capabilities)

require('mason-lspconfig').setup_handlers {
  function(server_name)
    require('lspconfig')[server_name].setup {
      capabilities = capabilities,
      settings = settings[server_name],
    }
  end,
}

local cmp = require 'cmp'
local luasnip = require 'luasnip'
require('luasnip.loaders.from_vscode').lazy_load()
luasnip.config.setup {}

cmp.setup {
  snippet = {
    expand = function(args)
      luasnip.lsp_expand(args.body)
    end,
  },
  completion = {
    completeopt = 'menu,menuone,noinsert',
  },
  mapping = cmp.mapping.preset.insert {
    ['<C-u>'] = cmp.mapping.scroll_docs(-4),
    ['<C-d>'] = cmp.mapping.scroll_docs(4),
    ['<C-f>'] = cmp.mapping(function(fallback)
      if luasnip.expand_or_locally_jumpable() then
        luasnip.expand_or_jump()
      else
        fallback()
      end
    end, { 'i', 's' }),
    ['<C-b>'] = cmp.mapping(function(fallback)
      if luasnip.locally_jumpable(-1) then
        luasnip.jump(-1)
      else
        fallback()
      end
    end, { 'i', 's' }),
  },
  sources = {
    { name = 'nvim_lsp' },
    { name = 'luasnip' },
  },
}

-- Setup formatting
require('conform').setup {
  formatters_by_ft = {
    lua = { 'stylua' },
    python = { 'black' },
  },
  format_on_save = {},
}

-- Setup linting
require('lint').linters_by_ft = {
  lua = { 'luacheck' },
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

-- Disable spellcheck for certain files
local spellDisableGroup = vim.api.nvim_create_augroup('SpellDisable', { clear = true })
vim.api.nvim_create_autocmd('FileType', {
  pattern = 'fsharp',
  callback = function()
    vim.opt_local.spell = false
  end,
  group = spellDisableGroup,
})

-- Linting
local lintingGroup = vim.api.nvim_create_augroup('Linting', { clear = true })
vim.api.nvim_create_autocmd({ 'BufWritePost' }, {
  callback = function()
    require('lint').try_lint()
  end,
  group = lintingGroup,
})

-- LSP keymaps
local lspAttachGroup = vim.api.nvim_create_augroup('LspAttachGroup', { clear = true })
vim.api.nvim_create_autocmd({ 'LspAttach' }, {
  callback = function(event)
    local map = function(keys, func, desc)
      vim.keymap.set('n', keys, func, { buffer = event.buf, desc = 'LSP: ' .. desc })
    end

    map('gd', vim.lsp.buf.definition, 'Goto Definition')
    map('gr', vim.lsp.buf.references, 'Goto References')
    map('gI', vim.lsp.buf.implementation, 'Goto Implementation')
    map('<leader>D', vim.lsp.buf.type_definition, 'Goto Type Definition')
    map('<leader>rn', vim.lsp.buf.rename, 'Rename')
    map('<leader>ca', vim.lsp.buf.code_action, 'Code Action')
    map('K', vim.lsp.buf.hover, 'Hover')
    map('gD', vim.lsp.buf.declaration, 'Goto Declaration')
  end,
  group = lspAttachGroup,
})

if vim.fn.has 'wsl' ~= 0 then
  vim.g.clipboard = {
    name = 'win32yank-wsl',
    copy = {
      ['+'] = 'win32yank.exe -i --crlf',
      ['*'] = 'win32yank.exe -i --crlf',
    },
    paste = {
      ['+'] = 'win32yank.exe -o --lf',
      ['*'] = 'win32yank.exe -o --lf',
    },
    cache_enabled = true,
  }
end

vim.diagnostic.config { virtual_text = false }
