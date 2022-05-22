-- Global stuff
vim.g.mapleader = ' '

-- Keybindings
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

  use 'jose-elias-alvarez/null-ls.nvim'
  use 'neovim/nvim-lspconfig'
  use 'hrsh7th/nvim-cmp'
  use 'hrsh7th/cmp-nvim-lsp'
  use 'ray-x/lsp_signature.nvim'
  use {
    'CosmicNvim/cosmic-ui',
    requires = { 'MunifTanjim/nui.nvim', 'nvim-lua/plenary.nvim' },
  }
  use 'onsails/lspkind.nvim'

  use 'L3MON4D3/LuaSnip'

  use 'marko-cerovac/material.nvim'

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

vim.g.material_style = 'deep ocean'
vim.cmd [[ colorscheme material ]]

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

local formattingGroup = vim.api.nvim_create_augroup('LspFormatting', { clear = true })
local terminalGroup = vim.api.nvim_create_augroup('Terminal', { clear = true })

-- Hide line numbers in the terminal
vim.api.nvim_create_autocmd('TermOpen', {
  callback = function()
    vim.wo.number = false
    vim.wo.relativenumber = false
  end,
  group = terminalGroup,
})

-- Language Servers
local cmp = require 'cmp'
local luasnip = require 'luasnip'
local lspkind = require 'lspkind'

---@param hl_name string
---@return table
local function border(hl_name)
  return {
    { '╭', hl_name },
    { '─', hl_name },
    { '╮', hl_name },
    { '│', hl_name },
    { '╯', hl_name },
    { '─', hl_name },
    { '╰', hl_name },
    { '│', hl_name },
  }
end

cmp.setup {
  snippet = {
    expand = function(args)
      luasnip.lsp_expand(args.body)
    end,
  },
  mapping = cmp.mapping.preset.insert {
    ['<C-Space>'] = cmp.mapping.complete(),
    ['<Tab>'] = cmp.mapping(function(fallback)
      if cmp.visible() then
        cmp.confirm { select = true }
      elseif luasnip.expand_or_jumpable() then
        luasnip.expand_or_jump()
      else
        fallback()
      end
    end, { 'i', 's' }),
    ['<S-Tab>'] = cmp.mapping(function(fallback)
      if luasnip.jumpable(-1) then
        luasnip.jump(-1)
      else
        fallback()
      end
    end, { 'i', 's' }),
  },
  sources = {
    { name = 'luasnip' },
    { name = 'nvim_lsp' },
  },
  completion = {
    completeopt = 'menu,menuone,noinsert',
  },
  window = {
    completion = {
      border = border 'CmpBorder',
    },
    documentation = {
      border = border 'CmpDocBorder',
    },
  },
  formatting = {
    format = lspkind.cmp_format { mode = 'symbol_text' },
  },
  experimental = {
    ghost_text = true,
  },
}

require('indent_blankline').setup {
  show_current_context = true,
}
require('Comment').setup()
require('gitsigns').setup()

local capabilities = require('cmp_nvim_lsp').update_capabilities(vim.lsp.protocol.make_client_capabilities())
local lspconfig = require 'lspconfig'

---@param bufnr number
local function common_on_attach(_, bufnr)
  local opts = { buffer = bufnr, silent = true }
  vim.keymap.set('n', 'K', vim.lsp.buf.hover, opts)
  vim.keymap.set('n', 'gd', vim.lsp.buf.definition, opts)
  vim.keymap.set('n', 'gr', vim.lsp.buf.references, opts)
  vim.keymap.set('n', '[d', vim.diagnostic.goto_prev)
  vim.keymap.set('n', ']d', vim.diagnostic.goto_next)
  vim.keymap.set('n', 'gn', require('cosmic-ui').rename, { silent = true })
  vim.keymap.set('n', '<leader>ga', require('cosmic-ui').code_actions, { silent = true })
  vim.keymap.set('v', '<leader>ga', require('cosmic-ui').range_code_actions, { silent = true })
end

require('lsp_signature').setup {}
require('cosmic-ui').setup()

require('null-ls').setup {
  sources = {
    require('null-ls').builtins.formatting.stylua,
  },
  on_attach = function(client, bufnr)
    if client.supports_method 'textDocument/formatting' then
      vim.api.nvim_create_autocmd('BufWritePre', {
        group = formattingGroup,
        buffer = bufnr,
        callback = function()
          vim.lsp.buf.format { bufnr = bufnr }
        end,
      })
    end
  end,
}

lspconfig.cmake.setup {
  capabilities = capabilities,
  on_attach = common_on_attach,
}

local runtime_path = vim.split(package.path, ';')
table.insert(runtime_path, 'lua/?.lua')
table.insert(runtime_path, 'lua/?/init.lua')

local neovim_parent_dir = vim.fn.resolve(vim.fn.stdpath 'config')
local buffer_file_name = vim.fn.expand '%:p'

local third_party_libraries

-- Include neovim runtime files if configuring, love2d otherwise
if string.sub(buffer_file_name, 1, string.len(neovim_parent_dir)) == neovim_parent_dir then
  third_party_libraries = vim.api.nvim_get_runtime_file('', true)
else
  third_party_libraries = { '${3rd}/love2d/library' }
end

lspconfig.sumneko_lua.setup {
  capabilities = capabilities,
  on_attach = common_on_attach,
  settings = {
    Lua = {
      runtime = {
        version = 'LuaJIT',
        path = runtime_path,
      },
      diagnostics = {
        globals = { 'vim' },
      },
      telemetry = {
        enable = false,
      },
      workspace = {
        checkThirdParty = false,
        library = third_party_libraries,
      },
    },
  },
}

vim.lsp.handlers['textDocument/hover'] = vim.lsp.with(vim.lsp.handlers.hover, {
  border = 'rounded',
})

vim.lsp.handlers['textDocument/signatureHelp'] = vim.lsp.with(vim.lsp.handlers.signatureHelp, {
  border = 'rounded',
})

-- Diagnostics
local diagnosticSigns = {
  Error = ' ',
  Warn = ' ',
  Hint = ' ',
  Info = ' ',
}

for type, icon in pairs(diagnosticSigns) do
  local hl = 'DiagnosticSign' .. type
  vim.fn.sign_define(hl, { text = icon, texthl = hl, numhl = '' })
end

vim.diagnostic.config {
  underline = true,
  signs = true,
  severity_sort = true,
  float = {
    border = 'rounded',
    focusable = false,
    header = { '  Diagnostics:', 'Normal' },
    source = 'always',
  },
  virtual_text = {
    spacing = 4,
    source = 'always',
    severity = {
      min = vim.diagnostic.severity.HINT,
    },
  },
}
