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

vim.api.nvim_create_user_command("W", function()
  local dir = vim.fn.expand("%:p:h")
  vim.fn.mkdir(dir, "p")
  vim.cmd("write")
end, { bar = true})

