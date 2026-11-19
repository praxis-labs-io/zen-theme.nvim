# zen-theme.nvim

Neovim follows **[ZenTerm](https://github.com/praxis-labs-io/zen-term)'s theme**.

[Install](#install) · [Docs](https://github.com/praxis-labs-io/zen-term/blob/main/docs/nvim-theme-protocol.md)

Pick a theme in ZenTerm and your editor recolors with the terminal and the chrome, live,
with no restart. Outside ZenTerm the plugin is inert, so your config stays portable.

## Install

With [lazy.nvim](https://github.com/folke/lazy.nvim):

```lua
{
  "praxis-labs-io/zen-theme.nvim",
  lazy = false,
  priority = 1000,
  opts = {},
}
```

Declare the colorschemes ZenTerm might name alongside it, so a theme switch never has to
clone one mid-session:

```lua
{ "rose-pine/neovim", name = "rose-pine", lazy = true },
{ "catppuccin/nvim", name = "catppuccin", lazy = true },
{ "folke/tokyonight.nvim", lazy = true },
```

Under a distro that sets its own colorscheme at startup (LazyVim, for one), load this
after that so it applies last.

## Requirements

- [ZenTerm](https://github.com/praxis-labs-io/zen-term) 1.1.0 or later, the first release that
  publishes the state file.
- Neovim 0.10+ (uses `vim.uv`, `vim.json`).
- The colorschemes you want it to reach, installed. This plugin applies a colorscheme; it
  does not ship any.

## How it works

ZenTerm publishes the theme it resolved to a JSON state file. This plugin reads it on
startup and re-reads it whenever ZenTerm rewrites it.

Each ZenTerm theme names the Neovim colorscheme to wear in its own `.ghostty` file:

```
nvim-colorscheme = kanagawa-dragon
```

Every theme ZenTerm bundles carries one. Add the line to a theme file of your own in
`~/.config/zen-term/themes/` and it is mapped too, in the same file that holds its
colors. The key changes no color, and ZenTerm's theme parser ignores it, so the file is
still a valid ghostty theme.

`vim.o.background` comes from the published theme's own light or dark reading, so a light
theme flips the editor along with everything else.

## Configuration

```lua
require("zen-theme").setup({
  -- ZenTerm theme token -> colorscheme, taking precedence over what the theme file names.
  -- For a theme whose .ghostty file you would rather not edit.
  themes = {
    ["gruvbox-dark"] = "gruvbox-material",
  },
  -- Where to read the published theme. Point it at a dev build's state file.
  path = vim.env.HOME .. "/Library/Application Support/ZenTerm/theme.json",
})
```

`require("zen-theme").stop()` stops following. Whatever colorscheme is up stays up.

## Behavior worth knowing

- **A colorscheme you have not installed leaves yours alone.** The apply runs through
  `pcall`, so a name you cannot resolve is a no-op rather than an error on every theme
  switch.
- **A theme that names no colorscheme leaves yours alone too.** Nothing is guessed from
  the palette.
- **Two running ZenTerms share one state file**, so a dev build beside the installed app
  is last-writer-wins. The next theme change in either corrects it.

## Related

[zen-navigator.nvim](https://github.com/praxis-labs-io/zen-navigator.nvim) walks
`Ctrl-hjkl` across Neovim splits and ZenTerm panes as one motion.

## Documentation

The contract is documented at
[`docs/nvim-theme-protocol.md`](https://github.com/praxis-labs-io/zen-term/blob/main/docs/nvim-theme-protocol.md)
in the ZenTerm repo, including the full payload. Both ends are written against it, and
nothing in it depends on the terminal backend.

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md). Report vulnerabilities privately through the
[Security tab](https://github.com/praxis-labs-io/zen-theme.nvim/security).

## License

[MIT](LICENSE).

Part of the [Zen family](https://github.com/praxis-labs-io) from Praxis Labs.
