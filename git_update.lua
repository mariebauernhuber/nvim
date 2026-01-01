local function check_and_update_nvim_config()
	local config_path = vim.fn.stdpath("config") -- usually ~/.config/nvim
	local cmd = "cd " .. config_path .. " && git fetch origin" .. " && git rev-parse HEAD" .. " && git rev-parse @{u}"

	local handle = io.popen(cmd .. " 2>/dev/null")
	if not handle then
		return
	end
	local output = handle:read("*a")
	handle:close()

	-- very naive parsing, you may want something more robust
	local local_sha, remote_sha = output:match("(%x+)%s*(%x+)")
	if not local_sha or not remote_sha or local_sha == remote_sha then
		return
	end

	-- remote has new commits
	local choice = vim.fn.confirm("Neovim config repo has updates. Pull now?", "&Yes\n&No", 1)

	if choice == 1 then
		vim.fn.jobstart({ "bash", "-lc", "cd " .. config_path .. " && git pull --rebase --autostash" }, {
			stdout_buffered = true,
			stderr_buffered = true,
			on_exit = function(_, code)
				if code == 0 then
					vim.schedule(function()
						vim.notify("Config updated. Restart Neovim to apply.", vim.log.levels.INFO)
						-- You *could* try a live reload here, but restart is safer.
					end)
				else
					vim.schedule(function()
						vim.notify("Git pull failed. Check your config repo.", vim.log.levels.ERROR)
					end)
				end
			end,
		})
	end
end

-- Run once on startup
vim.api.nvim_create_autocmd("VimEnter", {
	callback = function()
		check_and_update_nvim_config()
	end,
})
