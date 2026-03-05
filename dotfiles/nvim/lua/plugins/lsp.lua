-- LSP Configuration (NixOS: LSPs from PATH, no Mason)
local servers = require("lsp.servers")
local diagnostics = require("lsp.diagnostics")

return {
  {
    "neovim/nvim-lspconfig",
    event = { "BufReadPre", "BufNewFile" },
    init = function()
      vim.diagnostic.config(diagnostics.config)
    end,
    config = function()
      local lspconfig = require("lspconfig")

      -- Register custom LSPs
      servers.register_custom()

      -- Setup each server (only if available in PATH)
      for server, config in pairs(servers.configs) do
        local should_setup = config.enabled ~= false
          and (config.cond == nil or config.cond == true)

        if should_setup then
          -- Remove our custom fields before passing to lspconfig
          local lsp_config = vim.tbl_extend("force", {}, config)
          lsp_config.cond = nil
          lsp_config.enabled = nil

          lspconfig[server].setup(lsp_config)
        end
      end
    end,
  },
}
