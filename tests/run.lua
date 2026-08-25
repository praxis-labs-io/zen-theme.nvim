-- Test harness for zen-theme.nvim. Run: nvim --headless -u NONE -l tests/run.lua
--
-- Every colorscheme is a fixture under tests/, so a run never depends on what the machine has
-- installed. The E185 regression needs a colorscheme that is NOT on the runtimepath, which is what
-- tests/fixtures-lazy stands in for.

local root = vim.fn.fnamemodify(vim.fn.fnamemodify(debug.getinfo(1, "S").source:sub(2), ":h"), ":h")
vim.opt.rtp:prepend(root)
vim.opt.rtp:prepend(root .. "/tests/fixtures")

local failures, count = {}, 0

local function check(name, got, want)
  count = count + 1
  if got ~= want then
    table.insert(failures, ("%s: got %s, want %s"):format(name, tostring(got), tostring(want)))
  end
end

local dir = vim.fn.tempname()
vim.fn.mkdir(dir, "p")
local state = dir .. "/theme.json"

-- ZenTerm writes atomically: rename over the path, which replaces the inode.
local function publish(tbl)
  local tmp = state .. ".tmp"
  local f = assert(io.open(tmp, "w"))
  f:write(vim.json.encode(tbl))
  f:close()
  assert(os.rename(tmp, state))
end

-- Stop the live instance before dropping it: a leaked watcher from an earlier case would race
-- the next one on the same directory, and the winner is arbitrary.
local function reload()
  local prev = package.loaded["zen-theme"]
  if prev then
    prev.stop()
  end
  package.loaded["zen-theme"] = nil
  return require("zen-theme")
end

local function wait(scheme)
  vim.wait(3000, function() return vim.g.colors_name == scheme end, 20)
end

-- No file: inert, and no error.
os.remove(state)
reload().setup({ path = state })
check("absent file leaves the colorscheme alone", vim.g.colors_name, nil)

-- A published theme is applied, and `dark` drives `background`.
publish({ name = "a", dark = true, nvimColorscheme = "probe-dark" })
reload().setup({ path = state })
check("applies the published colorscheme", vim.g.colors_name, "probe-dark")
check("dark sets background", vim.o.background, "dark")

-- A light theme flips `background` too.
publish({ name = "b", dark = false, nvimColorscheme = "probe-light" })
reload().setup({ path = state })
check("light theme applies", vim.g.colors_name, "probe-light")
check("light sets background", vim.o.background, "light")

-- A rewrite is picked up live, through the atomic rename. The watch is on the directory for
-- exactly this reason: a file watch dies with the replaced inode.
publish({ name = "c", dark = true, nvimColorscheme = "probe-dark" })
local m = reload()
m.setup({ path = state })
publish({ name = "d", dark = false, nvimColorscheme = "probe-light" })
wait("probe-light")
check("re-applies live after an atomic rewrite", vim.g.colors_name, "probe-light")
m.stop()

-- An override beats what the theme file names.
publish({ name = "mine", dark = true, nvimColorscheme = "probe-light" })
reload().setup({ path = state, themes = { mine = "probe-dark" } })
check("override wins over the file", vim.g.colors_name, "probe-dark")

-- A colorscheme nothing provides leaves the current one up rather than raising.
publish({ name = "e", dark = true, nvimColorscheme = "not-installed" })
reload().setup({ path = state })
check("missing colorscheme keeps the current one", vim.g.colors_name, "probe-dark")

-- A theme naming none leaves the current one up. Nothing is guessed from the palette.
publish({ name = "f", dark = true })
reload().setup({ path = state })
check("no name keeps the current one", vim.g.colors_name, "probe-dark")

-- Regression: lazy.nvim leaves a `lazy = true` colorscheme unloaded until asked for it by name,
-- and :colorscheme does not ask. Without the loader call every such theme failed E185, swallowed
-- by the pcall. The stub stands in for lazy and puts the fixture on the rtp when consulted.
local asked = nil
package.loaded["lazy.core.loader"] = {
  colorscheme = function(name)
    asked = name
    vim.opt.rtp:prepend(root .. "/tests/fixtures-lazy")
  end,
}
publish({ name = "g", dark = true, nvimColorscheme = "probe-lazy" })
reload().setup({ path = state })
check("asks lazy to load the colorscheme's owner", asked, "probe-lazy")
check("applies a lazy-loaded colorscheme", vim.g.colors_name, "probe-lazy")
package.loaded["lazy.core.loader"] = nil

vim.fn.delete(dir, "rf")

if #failures == 0 then
  io.stdout:write(("ok  %d checks passed\n"):format(count))
  vim.cmd("qa!")
else
  io.stderr:write(("FAIL  %d of %d\n  %s\n"):format(#failures, count, table.concat(failures, "\n  ")))
  vim.cmd("cq!")
end
