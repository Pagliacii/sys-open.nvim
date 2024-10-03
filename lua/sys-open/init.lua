local M = {}
M.config = {
  open_cmd = nil,
  debug = false,
  silent = false,
  open_dir = true,
  github_repo = true,
  github_repo_pattern = "^[%w-]+/[%w-.]+$",
  link_pattern = "(https?://[%w-_%.%?%.:/%+=&]+)",
  exclude_chars = "[%[%](){}<>!;,\"']",
}
setmetatable(M, {
  __index = function(_, k)
    return M.config[k]
  end,
})

---Get the cursor word and extract link or path from it
---@return string
function M.get_cursor_word()
  local cursor_word = vim.fn.expand("<cWORD>")
  local link = string.match(cursor_word, M.link_pattern)
  if link then
    if M.debug then
      vim.print("[sys-open] cursor word is a link:", link)
    end
    return link
  end

  cursor_word = string.gsub(cursor_word, M.exclude_chars, "")
  if M.debug then
    vim.print("[sys-open] cursor word:", cursor_word)
  end
  return cursor_word
end

function M.complete_target(target)
  local target_path = vim.fn.expand(target)
  if vim.fn.filereadable(target_path) ~= 0 then
    if M.debug then
      vim.print("[sys-open] target is a file:", target_path)
    end
    return target_path
  end
  if M.open_dir and vim.fn.isdirectory(target_path) ~= 0 then
    if M.debug then
      vim.print("[sys-open] target is a directory:", target_path)
    end
    return target_path
  end

  if M.github_repo and string.match(target, M.github_repo_pattern) ~= nil then
    --seems like a github repo
    if M.debug then
      vim.print("[sys-open] seems like a github repo:", target)
    end
    return string.format("https://github.com/%s", target)
  end
  return target
end

---Get the default open command based on OS
---@param target? string Optional target to open. If not provided, it will be extracted from the cursor word.
---@return string[]
function M.get_open_cmd(target)
  if M.debug then
    vim.print("[sys-open] target:", target)
  end
  if target == nil or target == "" then
    target = M.get_cursor_word()
  end
  target = M.complete_target(target)
  if target == "" then
    if M.debug then
      vim.print("[sys-open] empty target")
    end
    return ""
  end
  local cmd = {}
  if M.open_cmd ~= nil then
    cmd[1] = M.open_cmd
  elseif vim.fn.has("mac") == 1 then
    cmd[1] = "open"
  elseif vim.fn.has("unix") == 1 then
    cmd[1] = "xdg-open"
  elseif vim.fn.executable("pwsh") == 1 then
    cmd = vim.split("pwsh -NoLogo -NoProfile -NonInteractive -Command Start-Process", " ")
  elseif vim.fn.executable("powershell") == 1 then
    cmd = vim.split("powershell -NoLogo -NoProfile -NonInteractive -Command Start-Process", " ")
  elseif vim.fn.executable("wsl-open") == 1 then
    cmd[1] = "wsl-open"
  else
    vim.notify("No default open command found", vim.log.levels.ERROR)
    return {}
  end
  table.insert(cmd, target)
  return cmd
end

---Open the file/link under cursor with system app
---@param target? string Optional target to open. If not provided, it will be extracted from the cursor word.
---@return nil
function M.open(target)
  local cmd = M.get_open_cmd(target)
  if M.debug then
    vim.print("[sys-open] command:", vim.inspect(cmd))
  end
  if #cmd == 0 then
    vim.notify("No command found", vim.log.levels.ERROR)
    return
  end
  vim.fn.jobstart(cmd, {
    on_stderr = function(_, data)
      if M.silent then
        return
      end
      local msg = table.concat(data or {}, "\n")
      if msg ~= "" then
        vim.print(msg)
      end
    end,
  })
end

function M.setup(opts)
  M.config = vim.tbl_extend("force", M.config, opts)
  if M.config.debug then
    M.config.silent = false
    M.config.open_dir = true
    M.config.github_repo = true
  end
  vim.api.nvim_create_user_command("SysOpen", function(t)
    if #t.fargs > 0 then
      M.open(t.fargs[1])
    else
      M.open()
    end
  end, { nargs = "?" })
end

return M
