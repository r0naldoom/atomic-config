-- Noctalia native theme sync
-- Temas sincronizados com Noctalia

return {
  -- ef-themes (Emacs themes portados para Neovim)
  {
    "oonamo/ef-themes.nvim",
    lazy = true,
  },

  -- thorn (green theme, dark warm)
  {
    "jpwol/thorn.nvim",
    lazy = false,
    priority = 1000,
    config = function()
      require("thorn").setup({
        transparent = true,
        background = "warm",
      })
      local sync = require("noctalia-sync")
      sync.setup()
    end,
  },

  -- gruvbox-material (sainnhe)
  {
    "sainnhe/gruvbox-material",
    lazy = false,
    priority = 1000,
    config = function()
      vim.g.gruvbox_material_background = "medium"
      vim.g.gruvbox_material_foreground = "material"
      vim.g.gruvbox_material_enable_italic = true
      vim.g.gruvbox_material_enable_bold = true
      vim.g.gruvbox_material_transparent_background = 2
      vim.g.gruvbox_material_diagnostic_virtual_text = "colored"
      vim.g.gruvbox_material_better_performance = true
      local sync = require("noctalia-sync")
      sync.setup()
    end,
  },
}
