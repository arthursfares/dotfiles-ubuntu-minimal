return {
  "nvim-telescope/telescope.nvim",
  branch = "0.1.x",
  dependencies = {
    "nvim-lua/plenary.nvim",
    -- Optional: native fzf sorter for much faster matching.
    -- Requires `make` and a C compiler (already installed).
    {
      "nvim-telescope/telescope-fzf-native.nvim",
      build = "make",
    },
  },
  config = function()
    local telescope = require("telescope")

    telescope.setup({
      defaults = {
        layout_strategy = "horizontal",
        layout_config = { prompt_position = "top" },
        sorting_strategy = "ascending",
        path_display = { "truncate" },
      },
      pickers = {
        find_files = { hidden = true },  -- include dotfiles
      },
    })

    pcall(telescope.load_extension, "fzf")

    local builtin = require("telescope.builtin")
    local map = vim.keymap.set
    map("n", "<leader>ff", builtin.find_files,  { desc = "Find files" })
    map("n", "<leader>fg", builtin.live_grep,   { desc = "Live grep" })
    map("n", "<leader>fb", builtin.buffers,     { desc = "List buffers" })
    map("n", "<leader>fh", builtin.help_tags,   { desc = "Help tags" })
    map("n", "<leader>fr", builtin.resume,      { desc = "Resume last picker" })
    map("n", "<leader>fd", builtin.diagnostics, { desc = "Diagnostics" })
    map("n", "<leader>fs", builtin.lsp_document_symbols, { desc = "Document symbols" })
  end,
}
