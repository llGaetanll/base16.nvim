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

local apply_theme = function(theme)
  local theme = resolve_theme(theme)

  set_fgs(theme)
  set_bgs(theme)

  local highlights = require "base16.highlights"
  local his = highlights(theme)
  for hi, val in pairs(his) do
    vim.api.nvim_set_hl(0, hi, val)
  end
end

local theme_cmd = function(cmd_opts)
  local theme_name = cmd_opts.args

  -- Check if a theme name was provided
  if theme_name and theme_name ~= "" then
    apply_theme(theme_name)
  else
    print("A theme is required")
  end
end

local theme_cmd_complete = function(ArgLead, CmdLine, CursorPos)
  -- Get the plugin directory
  local current_file = debug.getinfo(1, "S").source:sub(2)

  -- Get the directory of the current file
  local base_dir = vim.fn.fnamemodify(current_file, ":h")
  local themes_dir = base_dir .. "/themes"

  -- Check if the directory exists
  if vim.fn.isdirectory(themes_dir) ~= 1 then
    return {}
  end

  -- Get all .lua files in the themes directory
  local files = vim.fn.glob(themes_dir .. "/*.lua", false, true)
  local themes = {}

  -- Extract just the filenames without extension
  for _, file in ipairs(files) do
    local theme_name = vim.fn.fnamemodify(file, ":t:r")

    -- Only include themes that match the partial input
    if theme_name:find(ArgLead) == 1 then
      table.insert(themes, theme_name)
    end
  end

  return themes
end

function M.setup(opts)
  M.config = vim.tbl_deep_extend("force", M.config, opts or {})

  apply_theme(M.config.theme)

  vim.api.nvim_create_user_command('Theme', theme_cmd, {
    nargs = '?',
    complete = theme_cmd_complete
  })
end

return M
