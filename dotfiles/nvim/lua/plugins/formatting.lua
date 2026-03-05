-- Formatting with conform.nvim (NixOS: formatters from PATH)
return {
  {
    "stevearc/conform.nvim",
    event = { "BufWritePre" },
    cmd = { "ConformInfo" },
    keys = {
      {
        "<leader>cf",
        function()
          require("conform").format({ async = true, lsp_fallback = true })
        end,
        mode = { "n", "v" },
        desc = "Format buffer",
      },
    },
    opts = {
      formatters_by_ft = {
        -- Lua (global)
        lua = { "stylua" },
        -- Shell (global)
        sh = { "shfmt" },
        bash = { "shfmt" },
        fish = { "fish_indent" },
        -- Nix (global)
        nix = { "alejandra" },
        -- Python (from devShell)
        python = { "ruff_format", "ruff_fix" },
        -- Web (from devShell)
        javascript = { "prettier" },
        typescript = { "prettier" },
        javascriptreact = { "prettier" },
        typescriptreact = { "prettier" },
        html = { "prettier" },
        css = { "prettier" },
        json = { "prettier" },
        yaml = { "prettier" },
        markdown = { "prettier" },
        -- Go (from devShell)
        go = { "gofumpt" },
        -- Rust (from devShell)
        rust = { "rustfmt" },
        -- C/C++ (from devShell)
        c = { "clang-format" },
        cpp = { "clang-format" },
      },
      format_on_save = {
        timeout_ms = 500,
        lsp_fallback = true,
      },
      formatters = {
        shfmt = {
          prepend_args = { "-i", "2" },
        },
        stylua = {
          prepend_args = { "--indent-type", "Spaces", "--indent-width", "2" },
        },
      },
    },
    init = function()
      vim.o.formatexpr = "v:lua.require'conform'.formatexpr()"
    end,
  },
}
