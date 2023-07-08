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
		return link
	end

	cursor_word = string.gsub(cursor_word, M.exclude_chars, "")
	if M.debug then
		vim.print("[sys-open] cursor word:", cursor_word)
	end

	target_path = vim.fn.expand(cursor_word)
	if vim.fn.filereadable(target_path) ~= 0 then
		return target_path
	end
	if M.open_dir and vim.fn.isdirectory(target_path) ~= 0 then
		return target_path
	end

	if M.github_repo and string.match(cursor_word, M.github_repo_pattern) ~= nil then
		--seems like a github repo
		return string.format("https://github.com/%s", cursor_word)
	end
	return ""
end

---Get the default open command based on OS
---@return string
function M:default_open_cmd()
	local open_cmd = "open"
	if jit.os:find("Windows") then
		if vim.fn.executable("pwsh") then
			open_cmd = "pwsh -NoLogo -NoProfile -NonInteractive -Command Start-Process"
		else
			open_cmd = "cmd.exe /c start"
		end
	elseif jit.os:find("Linux") then
		open_cmd = "xdg-open"
	end
	return open_cmd
end

---Construct the execute command
---@param target string
---@return string
function M.cmd_factory(target)
	local open_cmd = M.open_cmd
	if not open_cmd then
		open_cmd = M:default_open_cmd()
	end

	return string.format([[%s "%s"]], open_cmd, target)
end

---Open the file/link under cursor with system app
function M.open()
	local target = M.get_cursor_word()
	if target == "" then
		if M.debug then
			vim.print("[sys-open] no such target:", vim.fn.expand("<cWORD>"))
		end
		return
	end

	local cmd = M.cmd_factory(target)
	if M.debug then
		vim.print("[sys-open] command:", cmd)
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
	vim.api.nvim_create_user_command("SysOpen", M.open, {})
end

return M
