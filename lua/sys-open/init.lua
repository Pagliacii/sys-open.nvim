local M = {}
M.config = {
	debug = false,
	silent = false,
}
setmetatable(M, {
	__index = function(_, k)
		return M.config[k]
	end,
})

---Extract the first link from the input string
---@param s string
---@return string
local function find_link(s)
	for url in string.gmatch(s, "https?://%S+") do
		return url
	end
end

---Get the cursor word and extract link or path from it
---@return string
local function get_cursor_word()
	local cursor_word = string.gsub(vim.fn.expand("<cWORD>"), "[%[%](){}<>!;]", "")
	local link = find_link(cursor_word)
	if link then
		return link
	end
	if vim.fn.filereadable(cursor_word) == 1 then
		return cursor_word
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
	local target = get_cursor_word()
	if not target then
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
	vim.tbl_extend("force", M.config, opts)
	vim.api.nvim_create_user_command("SysOpen", M.open, {})
end

return M
