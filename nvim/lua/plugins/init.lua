return {
  {
    "nyoom-engineering/oxocarbon.nvim",
    lazy = false,
    priority = 1000,
    config = function()
      vim.opt.background = "dark"   -- or "light"
      vim.cmd.colorscheme("oxocarbon")
    end,
  },
}
