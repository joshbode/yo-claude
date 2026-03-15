-- Minimal init for headless test runs
vim.cmd([[let &rtp.=','.getcwd()]])
vim.o.swapfile = false
