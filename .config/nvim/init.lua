-- Speed up loading when plugins are present
vim.loader.enable()


-- Set space as leader key
vim.g.mapleader = " "
vim.g.maplocalleader = " "

-- Enable relative line numbers
vim.opt.number = true          -- show absolute line number on current line
vim.opt.relativenumber = true  -- show relative line numbers on other lines

-- Set indent sizes
vim.opt.tabstop = 2
vim.opt.shiftwidth = 2
vim.opt.softtabstop = 2
vim.opt.expandtab = true

-- Leader-e open netrw file explorer - just a test that lua config is working
vim.keymap.set('n', '<leader>e', ':Ex<CR>', { noremap = true, silent = true })

vim.keymap.set('v', '>', '>gv', { desc = 'Indent and keep selection' })
vim.keymap.set('v', '<', '<gv', { desc = 'Unindent and keep selection' })

-- W - write to file, create all path dirs if they don't exist yet
vim.api.nvim_create_user_command("W", function()
  local dir = vim.fn.expand("%:p:h")
  vim.fn.mkdir(dir, "p")
  vim.cmd("write")
end, { bar = true})

-- Note: vim.keymap.set() is non-recursive by default (equivalent to :noremap),
-- so we don't need to pass { noremap = true }.

-- Simple navigation between opened buffers
vim.keymap.set("n", "<leader>b", ":ls<CR>:b ", { desc = "List and switch buffers" })

-- Crazy up/down replaced with centered up/down
vim.keymap.set("n", "<C-d>", "<C-d>zz")
vim.keymap.set("n", "<C-u>", "<C-u>zz")

-- Center view upon moving the search
vim.keymap.set("n", "n", "nzzzv")
vim.keymap.set("n", "N", "Nzzzv")

-- Select the last pasted text
vim.keymap.set("n", "gp", "`[v`]")

-- Commit and push my dotfiles repo - useful when editing configs form inside nvim
vim.api.nvim_create_user_command("SaveDotfiles", function()
  vim.cmd('!cd ~/src/dotfiles && git aacm "update configs" && git push')
end, {})

vim.pack.add({
  'https://github.com/nvim-mini/mini.nvim',
  'https://github.com/neovim/nvim-lspconfig',
  'https://github.com/nvim-treesitter/nvim-treesitter',
  'https://github.com/folke/tokyonight.nvim',
})

-- Load optional plugins
vim.cmd('packadd tokyonight.nvim')
vim.cmd('packadd nvim-treesitter')
vim.cmd('colorscheme tokyonight')

-- Treesitter: install markdown parsers, start highlighting
require('nvim-treesitter').install({ 'markdown', 'markdown_inline' }):wait(300000)

vim.api.nvim_create_autocmd('FileType', {
  callback = function()
    pcall(vim.treesitter.start)
  end,
})


-- =====================================================================
-- Rust + multi-file workflow   (added for the ./rust-vim course)
-- Everything below is explained in rust-vim/00-setup.md
-- =====================================================================

-- ---- mini.nvim modules ----------------------------------------------
require('mini.icons').setup()       -- filetype icons used by pick/files
require('mini.extra').setup()       -- extra pickers (diagnostics, lsp symbols)
require('mini.pick').setup()        -- fuzzy finder
require('mini.files').setup()       -- file explorer as an editable buffer
require('mini.statusline').setup()  -- shows which file/buffer you are in

-- ---- finding things --------------------------------------------------
vim.keymap.set('n', '<leader>ff', '<cmd>Pick files<cr>',      { desc = 'Find file by name' })
vim.keymap.set('n', '<leader>fg', '<cmd>Pick grep_live<cr>',  { desc = 'Grep across project' })
vim.keymap.set('n', '<leader>fb', '<cmd>Pick buffers<cr>',    { desc = 'Find open buffer' })
vim.keymap.set('n', '<leader>fh', '<cmd>Pick help<cr>',       { desc = 'Find help tag' })
vim.keymap.set('n', '<leader>fd', '<cmd>Pick diagnostic<cr>', { desc = 'Find diagnostic' })
vim.keymap.set('n', '<leader>fs', '<cmd>Pick lsp scope="document_symbol"<cr>', { desc = 'Find symbol in file' })

-- <leader>e was netrw; mini.files is a directory you can edit like text
vim.keymap.set('n', '<leader>e', function()
  MiniFiles.open(vim.api.nvim_buf_get_name(0))
end, { desc = 'File explorer at current file' })

-- ---- buffers and windows ---------------------------------------------
vim.keymap.set('n', ']b', '<cmd>bnext<cr>',          { desc = 'Next buffer' })
vim.keymap.set('n', '[b', '<cmd>bprevious<cr>',      { desc = 'Previous buffer' })
vim.keymap.set('n', '<leader>x', '<cmd>bdelete<cr>', { desc = 'Close buffer' })

-- window jumps without the <C-w> prefix
for _, k in ipairs({ 'h', 'j', 'k', 'l' }) do
  vim.keymap.set('n', '<C-' .. k .. '>', '<C-w>' .. k, { desc = 'Focus window ' .. k })
end

-- ---- quickfix: where compiler errors and grep hits land ---------------
vim.keymap.set('n', ']q', '<cmd>cnext<cr>zz',      { desc = 'Next quickfix item' })
vim.keymap.set('n', '[q', '<cmd>cprevious<cr>zz',  { desc = 'Previous quickfix item' })
vim.keymap.set('n', '<leader>q', '<cmd>copen<cr>', { desc = 'Open quickfix list' })

-- ---- treesitter: syntax-aware highlighting, indent, text objects ------
require('nvim-treesitter').install({ 'rust', 'toml', 'markdown', 'markdown_inline', 'lua' })
vim.api.nvim_create_autocmd('FileType', {
  pattern = { 'rust', 'toml', 'markdown', 'lua' },
  callback = function()
    pcall(vim.treesitter.start)
    vim.bo.indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
  end,
})

-- ---- diagnostics ------------------------------------------------------
vim.diagnostic.config({
  virtual_text = { current_line = true },  -- full message only on the line you are on
  severity_sort = true,
  signs = {
    text = {
      [vim.diagnostic.severity.ERROR] = 'E',
      [vim.diagnostic.severity.WARN]  = 'W',
      [vim.diagnostic.severity.INFO]  = 'I',
      [vim.diagnostic.severity.HINT]  = 'H',
    },
  },
})

-- ---- LSP: rust-analyzer ----------------------------------------------
-- Base config ships with nvim-lspconfig (lsp/rust_analyzer.lua); we only override settings.
vim.lsp.config('rust_analyzer', {
  settings = {
    ['rust-analyzer'] = {
      check = { command = 'clippy' },  -- lint on save, not just typecheck
      cargo = { allFeatures = true },
    },
  },
})
vim.lsp.enable('rust_analyzer')

vim.api.nvim_create_autocmd('LspAttach', {
  callback = function(ev)
    local client = vim.lsp.get_client_by_id(ev.data.client_id)
    if not client then return end

    -- nvim already maps grn/gra/grr/gri/grt/gO/K by default. gd is not one of them.
    vim.keymap.set('n', 'gd', vim.lsp.buf.definition, { buffer = ev.buf, desc = 'Goto definition' })

    if client:supports_method('textDocument/inlayHint') then
      vim.lsp.inlay_hint.enable(true, { bufnr = ev.buf })
    end
    if client:supports_method('textDocument/completion') then
      vim.lsp.completion.enable(true, client.id, ev.buf, { autotrigger = true })
    end
    if client:supports_method('textDocument/formatting') then
      vim.api.nvim_create_autocmd('BufWritePre', {
        buffer = ev.buf,
        callback = function() vim.lsp.buf.format({ bufnr = ev.buf, id = client.id }) end,
      })
    end
  end,
})

vim.keymap.set('n', '<leader>i', function()
  vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled())
end, { desc = 'Toggle inlay type hints' })

-- ---- :make runs cargo, errors go to the quickfix list -----------------
vim.api.nvim_create_autocmd('FileType', {
  pattern = 'rust',
  callback = function() vim.cmd('compiler cargo') end,
})
-- --message-format=short keeps the quickfix list one line per diagnostic
-- instead of rustc's multi-line rendering. Read the full text inline instead.
vim.keymap.set('n', '<leader>rr', '<cmd>make run<cr>',  { desc = 'cargo run' })
vim.keymap.set('n', '<leader>rt', '<cmd>make test<cr>', { desc = 'cargo test' })
vim.keymap.set('n', '<leader>rc', '<cmd>make clippy --message-format=short<cr>', { desc = 'cargo clippy' })
vim.keymap.set('n', '<leader>rk', '<cmd>make check --message-format=short<cr>',  { desc = 'cargo check' })
