-- Minimal init for headless test runs
vim.cmd([[let &rtp.=','.getcwd() .. '/editors/nvim']])
vim.o.swapfile = false
