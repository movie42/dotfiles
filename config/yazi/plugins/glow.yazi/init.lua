local M = {}

function M:peek(job)
	local child, err = Command("glow")
		:args({ "--style", "dark", "--width", tostring(job.area.w), tostring(job.file.url) })
		:stdout(Command.PIPED)
		:stderr(Command.NULL)
		:spawn()

	if not child then
		return Err(err)
	end

	local limit = job.area.h
	local i, lines = 0, {}
	repeat
		local line, event = child:read_line()
		if event ~= 0 then
			break
		end
		lines[#lines + 1] = ui.Line(ya.parse_ansi(line:gsub("\n$", "")))
		i = i + 1
	until i >= limit

	child:start_kill()
	ya.preview_widgets(job, { ui.Paragraph(job.area, lines) })
end

function M:seek(job)
	local h = cx.active.current.hovered
	if h and h.url == job.file.url then
		ya.manager_emit("peek", { math.max(0, cx.active.preview.skip + job.units), only_if = job.file.url })
	end
end

return M
