vim.api.nvim_create_autocmd("FileType", {
	pattern = "cpp",
	callback = function()
		vim.bo.expandtab = true
		vim.bo.shiftwidth = 4
		vim.bo.tabstop = 4
		vim.bo.softtabstop = 4
		vim.bo.commentstring = "// %s"
		vim.bo.makeprg = "just test %:p:h"
		vim.bo.errorformat = "%f:%l:%c: %m,%f:%l: %m"
	end,
})

local function target_dir()
	return vim.fs.dirname(vim.api.nvim_buf_get_name(0))
end

local function term(recipe, path, focus)
	path = path or target_dir()
	local buf = vim.api.nvim_create_buf(false, true)
	local height = math.min(math.floor(0.35 * vim.o.lines), 32)
	local win = vim.api.nvim_open_win(buf, focus, {
		split = "below",
		height = height,
	})
	vim.api.nvim_win_call(win, function()
		vim.wo.winbar = " %#Comment#▎%* %#Title#" .. recipe .. "%* %="
		vim.fn.jobstart({ "just", recipe, path }, { term = true })
	end)
	if focus then
		vim.cmd("startinsert")
	end
end

local recipes = {
	CpRun = "run",
	CpTest = "test",
	CpTestDebug = "test-debug",
	CpBench = "bench",
	CpStress = "stress",
	CpGenStress = "gen-stress",
	CpFmt = "fmt",
	CpLint = "lint",
	CpWatch = "watch",
}

for command, recipe in pairs(recipes) do
	vim.api.nvim_create_user_command(command, function(opts)
		term(recipe, opts.args ~= "" and opts.args or nil, command == "CpRun")
	end, { nargs = "?", complete = "dir" })
end

vim.api.nvim_create_user_command("CpNew", function(opts)
	term("new", opts.args ~= "" and opts.args or vim.fn.expand("%:p:h"))
end, { nargs = "?", complete = "dir" })

vim.keymap.set("n", "<leader>rr", "<cmd>CpRun<cr>", { desc = "CP run" })
vim.keymap.set("n", "<leader>rt", "<cmd>CpTest<cr>", { desc = "CP test" })
vim.keymap.set("n", "<leader>rd", "<cmd>CpTestDebug<cr>", { desc = "CP test debug" })
vim.keymap.set("n", "<leader>rb", "<cmd>CpBench<cr>", { desc = "CP bench" })
vim.keymap.set("n", "<leader>rs", "<cmd>CpStress<cr>", { desc = "CP stress" })
vim.keymap.set("n", "<leader>rw", "<cmd>CpWatch<cr>", { desc = "CP watch" })
