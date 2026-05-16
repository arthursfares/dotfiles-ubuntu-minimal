local map = vim.keymap.set

-- Buffer navigation
map("n", "<Tab>", ":bnext<CR>", { silent = true })
map("n", "<S-Tab>", ":bprevious<CR>", { silent = true })
map("n", "<leader>x", ":bdelete<CR>", { silent = true, desc = "Close buffer" })

-- Window navigation
map("n", "<C-h>", "<C-w>h")
map("n", "<C-j>", "<C-w>j")
map("n", "<C-k>", "<C-w>k")
map("n", "<C-l>", "<C-w>l")

-- Clear search highlight
map("n", "<Esc>", ":noh<CR>", { silent = true })
