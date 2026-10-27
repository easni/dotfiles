-- 1. Force the method to zathura_simple BEFORE loading VimTeX
vim.g.vimtex_view_method = "zathura_simple"

-- 2. Add the plugin
vim.pack.add { "https://github.com/lervag/vimtex" }

vim.g.vimtex_quickfix_autoclose_after_keystrokes = 1
