-- zen-theme.nvim — follow ZenTerm's theme with a matching Neovim colorscheme.
--
-- ZenTerm publishes the theme it resolved to a JSON state file; this reads it on startup and
-- re-reads it whenever ZenTerm rewrites it, so switching themes in ZenTerm recolors the editor
-- with the chrome. When the file is absent (not running under ZenTerm) the plugin is inert.
--
-- Protocol: docs/nvim-theme-protocol.md in the zen-term repo.

local M = {}

local DEFAULT_PATH = vim.env.HOME .. "/Library/Application Support/ZenTerm/theme.json"

local uv = vim.uv or vim.loop

-- Where the state file is, split for the directory watch below. Set by `setup`.
local path, dir, name
-- User overrides, ZenTerm theme token -> colorscheme name. Consulted ahead of the theme file.
local overrides = {}
-- The colorscheme last applied, so an unrelated rewrite (a palette edit, the same theme
-- reselected) does not reload a colorscheme that is already up.
local applied = nil
local watcher = nil
-- Set while a re-read is already scheduled: one atomic write fires several fs events.
local pending = false

-- The published payload, or nil when there is no file to read or it is not JSON. A partial write
-- cannot be seen (ZenTerm writes atomically), but a truncated or hand-edited file still decodes to
-- nothing rather than throwing.
local function read_state()
  local file = io.open(path, "r")
  if not file then
    return nil
  end
  local text = file:read("*a")
  file:close()
  local ok, state = pcall(vim.json.decode, text)
  if not ok or type(state) ~= "table" then
    return nil
  end
  return state
end

-- Precedence: the user's own mapping, then what the theme file names, then nothing. Nothing means
-- leave the colorscheme alone: guessing one from the palette would be worse than not acting.
local function resolve(state)
  return overrides[state.name] or state.nvimColorscheme
end

-- Apply the state's colorscheme. `background` is set first so a colorscheme that reads it picks the
-- right variant, and the apply is a pcall so a colorscheme the user has not installed leaves the
-- current one up instead of raising.
local function apply(state)
  local scheme = resolve(state)
  if not scheme or scheme == applied then
    return
  end
  if state.dark ~= nil then
    vim.o.background = state.dark and "dark" or "light"
  end
  if pcall(vim.cmd.colorscheme, scheme) then
    applied = scheme
  end
end

-- Read and apply, on the main loop. fs_event callbacks run off it, where touching editor state is
-- not allowed.
local function refresh()
  local state = read_state()
  if state then
    apply(state)
  end
end

-- Watch the containing directory rather than the file: ZenTerm writes atomically, which replaces
-- the inode, and a watch bound to the old one stops firing after the first theme switch.
local function watch()
  if watcher then
    return
  end
  local handle = uv.new_fs_event()
  if not handle then
    return
  end
  local ok = handle:start(dir, {}, function(err, filename)
    if err or (filename and filename ~= name) or pending then
      return
    end
    pending = true
    vim.schedule(function()
      pending = false
      refresh()
    end)
  end)
  if ok then
    watcher = handle
  end
end

--- Stop following ZenTerm's theme. The colorscheme already applied stays up.
function M.stop()
  if watcher then
    watcher:stop()
    watcher = nil
  end
end

--- opts.themes maps a ZenTerm theme token to a colorscheme, taking precedence over what the theme
--- file names. Use it for a theme whose `.ghostty` file you cannot edit. opts.path overrides where
--- the state file is read from.
function M.setup(opts)
  opts = opts or {}
  overrides = opts.themes or {}
  path = opts.path or DEFAULT_PATH
  dir, name = path:match("^(.*)/([^/]+)$")

  local state = read_state()
  if not state then
    return -- not running under ZenTerm
  end
  apply(state)
  watch()
end

return M
