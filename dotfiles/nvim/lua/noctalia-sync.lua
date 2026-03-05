-- Noctalia theme sync module
-- Lê o colorscheme do Noctalia settings.json e aplica o tema correspondente

local M = {}

-- Mapeamento Noctalia colorscheme -> neovim colorscheme
local theme_map = {
    ["Thorn"] = "thorn-dark-warm",
    ["EfCherie"] = "ef-cherie",
    ["Gruvbox-Material"] = "gruvbox-material",
    ["Tokyo-Night"] = "tokyonight-night",
}

function M.get_theme()
    local settings_path = vim.fn.expand("~/.config/noctalia/settings.json")
    local file = io.open(settings_path, "r")
    if not file then
        return nil
    end

    local content = file:read("*a")
    file:close()

    local scheme = content:match('"predefinedScheme"%s*:%s*"([^"]+)"')
    if scheme then
        return theme_map[scheme] or scheme:lower()
    end
    return nil
end

function M.apply()
    local theme = M.get_theme()
    if not theme then
        vim.notify("noctalia-sync: could not read Noctalia settings", vim.log.levels.WARN)
        return
    end

    local ok, err = pcall(vim.cmd.colorscheme, theme)
    if ok then
        vim.notify("Theme: " .. theme, vim.log.levels.INFO)
    else
        vim.notify("Failed to load theme: " .. theme .. " - " .. tostring(err), vim.log.levels.ERROR)
    end
end

function M.setup()
    local theme = M.get_theme()
    if theme then
        vim.schedule(function()
            pcall(vim.cmd.colorscheme, theme)
        end)
    end
end

return M
