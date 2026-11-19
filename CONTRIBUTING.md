# Contributing

## Setup

Neovim 0.10 or later. Point your plugin manager at the clone instead of the
published repo:

```lua
{ dir = "~/path/to/zen-theme.nvim", lazy = false, priority = 1000, opts = {} }
```

To see it work end to end you need [ZenTerm](https://github.com/praxis-labs-io/zen-term)
1.1.0 or later: switch themes there and watch the editor follow.

## Tests

```sh
nvim --headless -u NONE -l tests/run.lua
```

It runs against the colorschemes under `tests/fixtures`, so the result does not
depend on what your machine has installed. A behavior change comes with a check
in `tests/run.lua`, in the same commit.

## Boundaries

ZenTerm writes the state file and this plugin only reads it. The file's shape is
ZenTerm's contract, in
[`docs/nvim-theme-protocol.md`](https://github.com/praxis-labs-io/zen-term/blob/main/docs/nvim-theme-protocol.md).
A change that needs a new field starts there.

## Pull requests

- One subject per pull request. Implementation, cleanup and unrelated
  refactors are separate commits.
- Tests pass before you open it.
- If the change alters behavior a user sees, the README says so.

Report a vulnerability privately, from the Security tab, rather than in an issue.
