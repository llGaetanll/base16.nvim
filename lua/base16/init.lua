local M = {}

M.config = {
  default_theme = 'default-dark',
  on_change = nil,

  -- When true, any highlight group whose background is the theme's background
  -- color (base00) is left unpainted, so whatever the terminal draws behind
  -- nvim shows through. This does not force transparency: an opaque terminal
  -- still looks opaque, a translucent one now passes through.
  transparent = false,
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

-- Clears the background of every highlight group that paints base00, so the
-- terminal background shows through instead. Groups using any other background
-- (floats, popups, statusline, selections) are left alone.
local clear_bgs = function(theme)
  local bg = tonumber(theme.base00:gsub("#", ""), 16)
  if not bg then
    return
  end

  for name, hl in pairs(vim.api.nvim_get_hl(0, {})) do
    if hl.bg == bg then
      hl.bg = nil
      hl.ctermbg = nil

      vim.api.nvim_set_hl(0, name, hl)
    end
  end

  -- These have no background of their own, but nvim still fills them with the
  -- Normal background unless told otherwise.
  for _, name in ipairs { "Normal", "NormalNC", "EndOfBuffer", "NonText", "MsgArea" } do
    local hl = vim.api.nvim_get_hl(0, { name = name })
    hl.bg = nil
    hl.ctermbg = nil

    vim.api.nvim_set_hl(0, name, hl)
  end
end

-- Saves the theme table to a persisted json file in the user's data directory.
local persist_theme = function(theme_tbl)
  local theme_file = vim.fn.stdpath("data") .. "/theme.json"
  local json = vim.fn.json_encode(theme_tbl)

  local file = io.open(theme_file, "w")
  if file then
    file:write(json)
    file:close()
    return true
  end
  return false
end

-- Reads the theme table from the user's data directory, if there is one
local read_theme = function()
  local theme_file = vim.fn.stdpath("data") .. "/theme.json"

  local file = io.open(theme_file, "r")
  if not file then
    return nil
  end

  local content = file:read("*all")
  file:close()

  local ok, theme = pcall(vim.fn.json_decode, content)
  if ok then
    return theme
  else
    return nil
  end
end

-- Resolves the theme if a name is passed in, returns it if it's a table
local resolve_theme = function(theme)
  if type(theme) == "string" then
    return require("base16.themes." .. theme)
  end

  if type(theme) == "table" then
    return theme
  end
end

local apply_theme = function(theme_tbl, on_change)
  set_fgs(theme_tbl)
  set_bgs(theme_tbl)

  local highlights = require "base16.highlights"
  local his = highlights(theme_tbl)
  for hi, val in pairs(his) do
    vim.api.nvim_set_hl(0, hi, val)
  end

  if on_change and type(on_change) == "function" then
    on_change(theme_tbl)
  end

  -- Runs last so that user highlights are made transparent too
  if M.config.transparent then
    clear_bgs(theme_tbl)
  end

  persist_theme(theme_tbl)
end

local theme_cmd = function(on_change)
  return function(cmd_opts)
    local theme_name = cmd_opts.args

    -- Check if a theme name was provided
    if theme_name and theme_name ~= "" then
      local theme_tbl = resolve_theme(theme_name)
      apply_theme(theme_tbl, on_change)
    else
      print("A theme is required")
    end
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

  -- Read the theme from the user settings, otherwise load the default
  local theme_tbl = read_theme()
  if not theme_tbl then
    theme_tbl = resolve_theme(M.config.default_theme)
  end

  apply_theme(theme_tbl, M.config.on_change)

  vim.api.nvim_create_user_command('Theme', theme_cmd(M.config.on_change), {
    nargs = '?',
    complete = theme_cmd_complete
  })
end

return M
