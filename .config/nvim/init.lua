-- Speed up loading when plugins are present
vim.loader.enable()


-- Set space as leader key
vim.g.mapleader = " "
vim.g.maplocalleader = " "

-- Enable relative line numbers
vim.opt.number = true          -- show absolute line number on current line
vim.opt.relativenumber = true  -- show relative line numbers on other lines

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

-- Neovim 0.13-dev leaves default 'packlockfile' as literal "$XDG_CONFIG_HOME/..." when
-- XDG_CONFIG_HOME is unset; vim.pack then creates ./$XDG_CONFIG_HOME in cwd.
vim.o.packlockfile = vim.fn.stdpath('config') .. '/nvim-pack-lock.json'

vim.pack.add({
  'https://github.com/nvim-mini/mini.nvim',
  'https://github.com/neovim/nvim-lspconfig',
  'https://github.com/nvim-treesitter/nvim-treesitter',
})
