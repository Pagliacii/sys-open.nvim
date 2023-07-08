# sys-open.nvim

Open a path/link/github repo under cursor with system app.

I don't know why the `gx` sometimes opens the link and sometimes it doesn't. And I also want `gx` to be able to quickly access GitHub repos like `Pagliacii/sys-open.nvim`, so I wrote this Neovim plugin. Of course, this is my first plugin that I've written. So if you encounter any issues or have any ideas while using it, feel free to fire an issue.

## Features

- customize open command
- open the GitHub repo quickly

## Install

Using [Lazy.nvim](https://github.com/folke/lazy.nvim):

```lua
return {
  {
    "Pagliacii/sys-open.nvim",
    config = true,
    cmd = { "SysOpen" },
    --- optional keybinding
    keys = {
      { "gx", "<cmd>SysOpen<cr>", desc = "Open with the system app", silent = true },
    },
  },
}
```

## Usage

Call `SysOpen`, or use a keybinding likes `gx` above.

## Commands

- `SysOpen`

## Options

Default options:

```lua
opts = {
  open_cmd = nil, -- auto-detected at default
  debug = false, -- enable more debug infos
  silent = false, -- silent the error message
  open_dir = true, -- open the directory path or not
  github_repo = true, -- quick access a GitHub repo
  github_repo_pattern = "^[%w-]+/[%w-.]+$",
  link_pattern = "(https?://[%w-_%.%?%.:/%+=&]+)",
  exclude_chars = "[%[%](){}<>!;,\"']",
}
```

## How

Using `vim.fn.expand("<cWORD>")` to get the word under cursor, and execute the system related `open` to invoke the default app to open it.
