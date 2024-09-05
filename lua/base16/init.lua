local M = {}

M.config = {
  theme = 'default-dark'
}

local set_fgs = function(theme)
  for k, v in pairs(theme) do
    local hi = k:gsub("^%l", string.upper) .. 'Fg'

    vim.api.nvim_set_hl(0, hi, { fg = v })
  end
end

local set_bgs = function(theme)
  for k, v in pairs(theme) do
    local hi = k:gsub("^%l", string.upper) .. 'Bg'

    vim.api.nvim_set_hl(0, hi, { bg = v })
  end
end

local resolve_theme = function(theme)
  if type(theme) == "string" then
    return require("base16.themes." .. theme)
  end

  if type(theme) == "table" then
    return theme
  end
end

local highlights = require "base16.highlights"

function M.setup(opts)
  M.config = vim.tbl_deep_extend("force", M.config, opts or {})

  local theme = resolve_theme(M.config.theme)

  set_fgs(theme)
  set_bgs(theme)

  local his = highlights(theme)
  for hi, val in pairs(his) do
    vim.api.nvim_set_hl(0, hi, val)
  end
end

return M
