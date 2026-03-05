-- LSP Server configurations (NixOS: all LSPs from PATH)
local M = {}

-- Check if command exists
local function cmd_exists(cmd)
  return vim.fn.executable(cmd) == 1
end

-- Register custom LSPs not in lspconfig
function M.register_custom()
  local configs = require("lspconfig.configs")
  local util = require("lspconfig.util")

  if not configs.zuban then
    configs.zuban = {
      default_config = {
        cmd = { "zuban", "server" },
        filetypes = { "python" },
        root_dir = util.root_pattern(
          "pyproject.toml",
          "setup.py",
          "setup.cfg",
          "requirements.txt",
          ".git"
        ),
        single_file_support = true,
      },
    }
  end
end

-- Server configurations
-- Global LSPs: installed via Nix in modules/programs/editor/user.nix
-- Project LSPs: come from devShells (templates)
M.configs = {
  -----------------
  -- Global LSPs --
  -----------------

  -- Lua (neovim config)
  lua_ls = {
    cond = cmd_exists("lua-language-server"),
    settings = {
      Lua = {
        runtime = { version = "LuaJIT" },
        diagnostics = { globals = { "vim" } },
        workspace = { checkThirdParty = false },
        telemetry = { enable = false },
      },
    },
  },

  -- Shell
  bashls = {
    cond = cmd_exists("bash-language-server"),
  },

  -- Web basics (vscode-langservers-extracted)
  html = { cond = cmd_exists("vscode-html-language-server") },
  cssls = { cond = cmd_exists("vscode-css-language-server") },
  jsonls = { cond = cmd_exists("vscode-json-language-server") },
  eslint = { cond = cmd_exists("vscode-eslint-language-server") },

  -- YAML
  yamlls = { cond = cmd_exists("yaml-language-server") },

  -- Typos (spell checker for code)
  typos_lsp = {
    cond = cmd_exists("typos-lsp"),
    filetypes = {
      "python", "lua", "javascript", "typescript", "rust", "go", "c", "cpp",
      "java", "ruby", "php", "sh", "bash", "zsh", "fish", "vim",
      "json", "yaml", "toml", "html", "css", "scss", "nix",
    },
    init_options = {
      diagnosticSeverity = "Hint",
    },
  },

  -- LTeX (grammar checker PT-BR + EN)
  ltex = {
    cond = cmd_exists("ltex-ls"),
    filetypes = { "markdown", "text", "gitcommit", "latex", "tex" },
    settings = {
      ltex = {
        language = "pt-BR",
        java = {
          initialHeapSize = 64,
          maximumHeapSize = 512,
        },
        additionalRules = {
          enablePickyRules = true,
          motherTongue = "pt-BR",
        },
        dictionary = {
          ["pt-BR"] = vim.fn.filereadable(vim.fn.stdpath("config") .. "/spell/pt.utf-8.add") == 1
            and vim.fn.readfile(vim.fn.stdpath("config") .. "/spell/pt.utf-8.add") or {},
          ["en-US"] = vim.fn.filereadable(vim.fn.stdpath("config") .. "/spell/en.utf-8.add") == 1
            and vim.fn.readfile(vim.fn.stdpath("config") .. "/spell/en.utf-8.add") or {},
        },
      },
    },
    cmd_env = {
      JAVA_OPTS = "-Djdk.xml.totalEntitySizeLimit=0",
    },
  },

  -- Nix
  nil_ls = { cond = cmd_exists("nil") },

  -------------------
  -- Project LSPs  --
  -- (from devShell)
  -------------------

  -- Python
  zuban = { cond = cmd_exists("zuban") },
  ruff = {
    cond = cmd_exists("ruff"),
    init_options = {
      settings = {
        lineLength = 100,
      },
    },
  },
  pyright = { enabled = false },
  basedpyright = { enabled = false },

  -- Go
  gopls = { cond = cmd_exists("gopls") },

  -- Rust
  rust_analyzer = { cond = cmd_exists("rust-analyzer") },

  -- TypeScript/JavaScript
  ts_ls = { cond = cmd_exists("typescript-language-server") },

  -- C/C++
  clangd = { cond = cmd_exists("clangd") },

  -- .NET
  roslyn_ls = { cond = cmd_exists("roslyn-ls") },
}

return M
