return {
  "akinsho/toggleterm.nvim",
  version = "*",
  config = function()
    require("toggleterm").setup({
      open_mapping = [[<c-\>]],
      direction = "horizontal",
      size = 15,
      shade_terminals = true,
    })

    -- Escape terminal mode easily
    vim.keymap.set("t", "<Esc>", [[<C-\><C-n>]])
  end,
}
