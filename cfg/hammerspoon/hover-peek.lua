-- Select a Linear issue ID or GitHub PR/issue ref in WezTerm (or press the
-- hotkey over one in any app) to see a popover. Text around the mouse is read
-- with OCR (hover-peek/ocr.swift). Data comes from linear-cli and gh, cached on disk.
local M = {}
local home = os.getenv("HOME")

M.config = {
	-- Apps that copy a mouse selection to the clipboard on release (WezTerm's
	-- default); selecting a match there opens the popover immediately.
	selectionApps = { "com.github.wez.wezterm" },
	-- Open Linear links in the desktop app (linear://) instead of the browser.
	linearDesktop = true,
	-- Looks up whatever is under the mouse in any app; press again to close.
	hotkey = { { "ctrl", "alt", "cmd", "shift" }, "i" },
	-- Bare #123 refers to this repo.
	defaultRepo = "sherwinyu/oryoki",
	-- Cached entries older than this are shown, then refreshed in the background.
	staleSeconds = 300,
	teamsTtlSeconds = 24 * 3600,
	capture = { w = 560, h = 56 },
	width = 440,
	linearCli = home .. "/.local/bin/linear-cli",
	gh = "/opt/homebrew/bin/gh",
	cacheDir = home .. "/.cache/hover-peek",
}

---------------------------------------------------------------------------
-- Matching (pure; covered by tests/hover-peek-test.lua)
---------------------------------------------------------------------------

local function trim(s)
	return (s:gsub("^[%(%[{<\"'`]+", ""):gsub("[%)%]}>\"'`,.;:!?]+$", ""))
end

-- opts.defaultRepo resolves bare #123. opts.teamKeys (set of uppercase keys)
-- allows Linear IDs anywhere in a token, in any case (e.g. sherwin/she-12-fix);
-- without it, only a whole uppercase token like SHE-12 counts.
function M.parseRef(text, opts)
	opts = opts or {}
	local s = trim(text)
	local repo, number = s:match("github%.com/([%w._-]+/[%w._-]+)/pull/(%d+)")
	if not repo then repo, number = s:match("github%.com/([%w._-]+/[%w._-]+)/issues/(%d+)") end
	if not repo then repo, number = s:match("^([%w._-]+/[%w._-]+)#(%d+)$") end
	if not repo and opts.defaultRepo then
		number = s:match("^#(%d+)$")
		if number then repo = opts.defaultRepo end
	end
	if repo then
		return { kind = "github", repo = repo, number = tonumber(number), key = "github:" .. repo:lower() .. "#" .. number }
	end

	local id = s:match("linear%.app/[%w_-]+/issue/(%a%w*%-%d+)")
	if not id and opts.teamKeys then
		for team, num in s:gmatch("%f[%w](%a%w*)%-(%d+)%f[%W]") do
			if opts.teamKeys[team:upper()] then id = team .. "-" .. num; break end
		end
	elseif not id then
		id = s:match("^%u[%u%d]+%-%d+$")
	end
	if id then
		id = id:upper()
		return { kind = "linear", id = id, key = "linear:" .. id }
	end
end

-- First ref among the words of a short selection; long selections are ignored.
function M.refInSelection(text, opts)
	if type(text) ~= "string" or #text > 200 then return nil end
	for word in text:gmatch("%S+") do
		local ref = M.parseRef(word, opts)
		if ref then return ref end
	end
end

-- Nearest token whose text contains the selected text (plain match).
function M.tokenContaining(tokens, selected, x, y)
	local best, bestDistance
	for _, t in ipairs(tokens) do
		if t.text:find(selected, 1, true) then
			local dx = math.max(t.x - x, 0, x - (t.x + t.w))
			local dy = math.max(t.y - y, 0, y - (t.y + t.h))
			local distance = dx * dx + dy * dy
			if not best or distance < bestDistance then best, bestDistance = t, distance end
		end
	end
	return best
end

-- Tokens are screen rects {text, x, y, w, h}; returns the one under the point.
function M.tokenAt(tokens, x, y, pad)
	pad = pad or 3
	local best, bestDistance
	for _, t in ipairs(tokens) do
		if x >= t.x - pad and x <= t.x + t.w + pad and y >= t.y - pad and y <= t.y + t.h + pad then
			local dx, dy = x - (t.x + t.w / 2), y - (t.y + t.h / 2)
			local distance = dx * dx + dy * dy
			if not best or distance < bestDistance then best, bestDistance = t, distance end
		end
	end
	return best
end

if not hs then return M end

---------------------------------------------------------------------------
-- Cache and fetching
---------------------------------------------------------------------------

local cachePath = M.config.cacheDir .. "/cache.json"
local cache = {}
local inflight = {}
-- Bump when the cached item shape changes; older entries are refetched.
local schema = 2

local function saveCache()
	hs.json.write(cache, cachePath, false, true)
end

local function run(cmd, args, callback)
	local task = hs.task.new(cmd, function(code, out, err) callback(code == 0, out or "", err or "") end, args)
	if not task or not task:start() then callback(false, "", "could not start " .. cmd) end
end

local function decode(s)
	local ok, value = pcall(hs.json.decode, s)
	return ok and value or nil
end

local function linearQuery(query, callback)
	run(M.config.linearCli, { "api", "query", "--output", "json", "--compact", "--no-pager", query }, function(_, out, err)
		local response = decode(out)
		if response and response.data then return callback(response.data) end
		local detail = response and response.details and response.details[1]
		local message = detail and (detail.extensions and detail.extensions.userPresentableMessage or detail.message)
		callback(nil, message or (response and response.message) or err:match("[^\n]+") or "linear-cli failed")
	end)
end

local fetchers = {}

function fetchers.linear(ref, callback)
	-- ref.id is validated by parseRef, so it is safe to inline.
	linearQuery(([[{ issue(id: "%s") { identifier title url priorityLabel description
		state { name color type } assignee { displayName avatarUrl } } }]]):format(ref.id), function(data, err)
		local issue = data and data.issue
		if not issue then return callback(nil, err or "Issue not found") end
		local state, assignee = issue.state or {}, issue.assignee
		callback({
			schema = schema, source = "linear", ref = issue.identifier, title = issue.title, url = issue.url,
			state = state.name, stateColor = state.color, stateType = state.type,
			priority = issue.priorityLabel ~= "No priority" and issue.priorityLabel or nil,
			assignee = assignee and assignee.displayName, avatar = assignee and assignee.avatarUrl,
			body = issue.description,
		})
	end)
end

local function githubItem(ref, item, pr)
	local state = item.state == "open" and "Open" or "Closed"
	if pr and item.merged then state = "Merged"
	elseif pr and item.draft and item.state == "open" then state = "Draft"
	elseif not pr and item.state_reason == "not_planned" then state = "Not planned" end
	return {
		schema = schema, source = "github", kind = pr and "pr" or "issue",
		ref = ref.repo:match("[^/]+$") .. "#" .. ref.number, title = item.title, url = item.html_url,
		state = state, author = item.user and item.user.login,
		files = item.changed_files, additions = item.additions, deletions = item.deletions,
		body = item.body,
	}
end

function fetchers.github(ref, callback)
	-- The pulls endpoint has diff stats; fall back to issues for plain issues.
	local path = ("repos/%s/%%s/%d"):format(ref.repo, ref.number)
	run(M.config.gh, { "api", path:format("pulls") }, function(ok, out)
		local pr = ok and decode(out)
		if pr and pr.title then return callback(githubItem(ref, pr, true)) end
		run(M.config.gh, { "api", path:format("issues") }, function(ok2, out2, err)
			local issue = ok2 and decode(out2)
			if issue and issue.title then return callback(githubItem(ref, issue, false)) end
			callback(nil, (decode(out2) or {}).message or err:match("[^\n]+") or "gh failed")
		end)
	end)
end

-- Calls onResult(item, fetchedAt, refreshing, err) once with cached data (if
-- any), then again when a needed fetch finishes.
local function lookup(ref, onResult)
	local entry = cache[ref.key]
	if entry and entry.item.schema ~= schema then entry = nil end
	local stale = not entry or os.time() - entry.at > M.config.staleSeconds
	if entry then onResult(entry.item, entry.at, stale) end
	if not stale then return end
	if inflight[ref.key] then table.insert(inflight[ref.key], onResult); return end
	inflight[ref.key] = { onResult }
	fetchers[ref.kind](ref, function(item, err)
		local waiting = inflight[ref.key]
		inflight[ref.key] = nil
		if item then
			cache[ref.key] = { at = os.time(), item = item }
			saveCache()
		end
		local current = cache[ref.key]
		for _, callback in ipairs(waiting) do
			if item then callback(item, current.at, false)
			elseif not current then callback(nil, nil, false, err)
			else callback(current.item, current.at, false) end
		end
	end)
end

local teamKeys

local function refreshTeams()
	local teams = cache._teams
	if teams then
		teamKeys = {}
		for _, key in ipairs(teams.keys) do teamKeys[key] = true end
		if os.time() - teams.at < M.config.teamsTtlSeconds then return end
	end
	linearQuery("{ teams(first: 250) { nodes { key } } }", function(data)
		if not data then return end
		local keys = {}
		teamKeys = {}
		for _, team in ipairs(data.teams.nodes) do
			keys[#keys + 1] = team.key
			teamKeys[team.key] = true
		end
		cache._teams = { at = os.time(), keys = keys }
		saveCache()
	end)
end

---------------------------------------------------------------------------
-- OCR helper: a long-lived process; one image path in, one JSON line out.
---------------------------------------------------------------------------

local ocrSource = hs.configdir .. "/hover-peek/ocr.swift"
local ocrBinary = M.config.cacheDir .. "/hover-peek-ocr"
local shotPath = M.config.cacheDir .. "/capture.png"
local ocrTask, ocrPending, ocrBuffer, ocrBuilding

local function ocrReady(callback)
	if ocrTask and ocrTask:isRunning() then return callback(true) end
	local source = hs.fs.attributes(ocrSource, "modification")
	local binary = hs.fs.attributes(ocrBinary, "modification")
	if not binary or (source and source > binary) then
		if ocrBuilding then return callback(false) end
		ocrBuilding = true
		hs.alert.show("hover-peek: building OCR helper…", 2)
		return run("/usr/bin/swiftc", { "-O", "-o", ocrBinary, ocrSource }, function(ok, _, err)
			ocrBuilding = false
			if not ok then
				print("hover-peek: swiftc failed: " .. err)
				hs.alert.show("hover-peek: OCR helper failed to build (see console)")
				return callback(false)
			end
			ocrReady(callback)
		end)
	end
	ocrBuffer, ocrPending = "", nil
	ocrTask = hs.task.new(ocrBinary, function()
		ocrTask = nil
		if ocrPending then ocrPending(nil); ocrPending = nil end
	end, function(_, out)
		ocrBuffer = ocrBuffer .. (out or "")
		local line, rest = ocrBuffer:match("^(.-)\n(.*)$")
		while line do
			ocrBuffer = rest
			local callback = ocrPending
			ocrPending = nil
			if callback then callback(decode(line)) end
			line, rest = ocrBuffer:match("^(.-)\n(.*)$")
		end
		return true
	end, {})
	if not ocrTask:start() then ocrTask = nil; return callback(false) end
	-- Input sent right after launch can be lost before the pipes are wired up.
	hs.timer.doAfter(0.3, function() callback(ocrTask ~= nil) end)
end

-- Calls back with the tokens near the point, in screen coordinates.
local function ocrAround(point, callback)
	if ocrPending then return end
	local screen = hs.mouse.getCurrentScreen()
	local full = screen:fullFrame()
	local size = M.config.capture
	local rect = {
		x = math.max(full.x, math.min(point.x - size.w / 2, full.x + full.w - size.w)),
		y = math.max(full.y, math.min(point.y - size.h / 2, full.y + full.h - size.h)),
		w = size.w, h = size.h,
	}
	local image = screen:snapshot({ x = rect.x - full.x, y = rect.y - full.y, w = rect.w, h = rect.h })
	if not image or not image:saveToFile(shotPath) then return end
	ocrReady(function(ready)
		if not ready or ocrPending then return end
		local pending
		pending = function(tokens)
			for _, t in ipairs(tokens or {}) do
				t.x, t.y = rect.x + t.x * rect.w, rect.y + t.y * rect.h
				t.w, t.h = t.w * rect.w, t.h * rect.h
			end
			callback(tokens or {})
		end
		ocrPending = pending
		ocrTask:setInput(shotPath .. "\n")
		-- Never let a lost reply block later lookups.
		hs.timer.doAfter(2, function()
			if ocrPending == pending then ocrPending = nil end
		end)
	end)
end

---------------------------------------------------------------------------
-- Popover
---------------------------------------------------------------------------

local function expanded(r, by)
	return { x = r.x - by, y = r.y - by, w = r.w + 2 * by, h = r.h + 2 * by }
end

local function contains(r, p)
	return p.x >= r.x and p.x <= r.x + r.w and p.y >= r.y and p.y <= r.y + r.h
end

local margin = 14 -- room around the card for its CSS shadow
local view, shown, keyTap

local function escape(s)
	return (tostring(s or ""):gsub("[&<>\"]", { ["&"] = "&amp;", ["<"] = "&lt;", [">"] = "&gt;", ['"'] = "&quot;" }))
end

local function ago(at)
	local seconds = os.time() - at
	if seconds < 60 then return "just now" end
	if seconds < 3600 then return math.floor(seconds / 60) .. "m ago" end
	if seconds < 86400 then return math.floor(seconds / 3600) .. "h ago" end
	return math.floor(seconds / 86400) .. "d ago"
end

-- Light markdown for the description: bold, code, headings, bullets; link text only.
local function describe(body)
	if type(body) ~= "string" then return "" end
	body = body:gsub("\r", ""):gsub("<!%-%-.-%-%->", ""):gsub("!%[[^%]]*%]%([^)]*%)", "")
		:gsub("%+%+%+[^\n]*", "")
	body = body:gsub("\n%s*\n[%s\n]*", "\n\n"):gsub("^%s+", ""):gsub("%s+$", "")
	if #body > 6000 then body = body:sub(1, 6000) .. "…" end
	local html = escape(body)
		:gsub("%[([^%]\n]*)%]%([^)\n]*%)", "%1")
		:gsub("`([^`\n]+)`", "<code>%1</code>")
		:gsub("%*%*([^*\n]+)%*%*", "<b>%1</b>")
	html = ("\n" .. html):gsub("\n#+%s*([^\n]*)", "\n<b>%1</b>"):gsub("\n%s*[%*%-] ", "\n• ")
	return html:sub(2)
end

-- Paths from GitHub Octicons (16px), MIT licensed.
local octicons = {
	pr = { "M1.5 3.25a2.25 2.25 0 1 1 3 2.122v5.256a2.251 2.251 0 1 1-1.5 0V5.372A2.25 2.25 0 0 1 1.5 3.25Zm5.677-.177L9.573.677A.25.25 0 0 1 10 .854V2.5h1A2.5 2.5 0 0 1 13.5 5v5.628a2.251 2.251 0 1 1-1.5 0V5a1 1 0 0 0-1-1h-1v1.646a.25.25 0 0 1-.427.177L7.177 3.427a.25.25 0 0 1 0-.354ZM3.75 2.5a.75.75 0 1 0 0 1.5.75.75 0 0 0 0-1.5Zm0 9.5a.75.75 0 1 0 0 1.5.75.75 0 0 0 0-1.5Zm8.25.75a.75.75 0 1 0 1.5 0 .75.75 0 0 0-1.5 0Z" },
	draft = { "M3.25 1A2.25 2.25 0 0 1 4 5.372v5.256a2.251 2.251 0 1 1-1.5 0V5.372A2.251 2.251 0 0 1 3.25 1Zm9.5 14a2.25 2.25 0 1 1 0-4.5 2.25 2.25 0 0 1 0 4.5ZM2.5 3.25a.75.75 0 1 0 1.5 0 .75.75 0 0 0-1.5 0ZM3.25 12a.75.75 0 1 0 0 1.5.75.75 0 0 0 0-1.5Zm9.5 0a.75.75 0 1 0 0 1.5.75.75 0 0 0 0-1.5ZM14 7.5a1.25 1.25 0 1 1-2.5 0 1.25 1.25 0 0 1 2.5 0Zm0-4.25a1.25 1.25 0 1 1-2.5 0 1.25 1.25 0 0 1 2.5 0Z" },
	merged = { "M5.45 5.154A4.25 4.25 0 0 0 9.25 7.5h1.378a2.251 2.251 0 1 1 0 1.5H9.25A5.734 5.734 0 0 1 5 7.123v3.505a2.25 2.25 0 1 1-1.5 0V5.372a2.25 2.25 0 1 1 1.95-.218ZM4.25 13.5a.75.75 0 1 0 0-1.5.75.75 0 0 0 0 1.5Zm8.5-4.5a.75.75 0 1 0 0-1.5.75.75 0 0 0 0 1.5ZM5 3.25a.75.75 0 1 0 0 .005V3.25Z" },
	prClosed = { "M3.25 1A2.25 2.25 0 0 1 4 5.372v5.256a2.251 2.251 0 1 1-1.5 0V5.372A2.251 2.251 0 0 1 3.25 1Zm9.5 5.5a.75.75 0 0 1 .75.75v3.378a2.251 2.251 0 1 1-1.5 0V7.25a.75.75 0 0 1 .75-.75Zm-2.03-5.273a.75.75 0 0 1 1.06 0l.97.97.97-.97a.748.748 0 0 1 1.265.332.75.75 0 0 1-.205.729l-.97.97.97.97a.751.751 0 0 1-.018 1.042.751.751 0 0 1-1.042.018l-.97-.97-.97.97a.749.749 0 0 1-1.275-.326.749.749 0 0 1 .215-.734l.97-.97-.97-.97a.75.75 0 0 1 0-1.06ZM2.5 3.25a.75.75 0 1 0 1.5 0 .75.75 0 0 0-1.5 0ZM3.25 12a.75.75 0 1 0 0 1.5.75.75 0 0 0 0-1.5Zm9.5 0a.75.75 0 1 0 0 1.5.75.75 0 0 0 0-1.5Z" },
	issueOpen = { "M8 9.5a1.5 1.5 0 1 0 0-3 1.5 1.5 0 0 0 0 3Z", "M8 0a8 8 0 1 1 0 16A8 8 0 0 1 8 0ZM1.5 8a6.5 6.5 0 1 0 13 0 6.5 6.5 0 0 0-13 0Z" },
	issueClosed = { "M11.28 6.78a.75.75 0 0 0-1.06-1.06L7.25 8.69 5.78 7.22a.75.75 0 0 0-1.06 1.06l2 2a.75.75 0 0 0 1.06 0l3.5-3.5Z", "M16 8A8 8 0 1 1 0 8a8 8 0 0 1 16 0Zm-1.5 0a6.5 6.5 0 1 0-13 0 6.5 6.5 0 0 0 13 0Z" },
	notPlanned = { "M8 0a8 8 0 1 1 0 16A8 8 0 0 1 8 0ZM1.5 8a6.5 6.5 0 1 0 13 0 6.5 6.5 0 0 0-13 0Zm9.78-2.22-5.5 5.5a.749.749 0 0 1-1.275-.326.749.749 0 0 1 .215-.734l5.5-5.5a.751.751 0 0 1 1.042.018.751.751 0 0 1 .018 1.042Z" },
}

-- GitHub state -> icon and color, for PRs and issues.
local githubStyles = {
	pr = { Open = { "pr", "#1f883d" }, Draft = { "draft", "#59636e" },
		Merged = { "merged", "#8250df" }, Closed = { "prClosed", "#d1242f" } },
	issue = { Open = { "issueOpen", "#1f883d" }, Closed = { "issueClosed", "#8250df" },
		["Not planned"] = { "notPlanned", "#59636e" } },
}

local function octicon(name, color)
	local paths = {}
	for _, d in ipairs(octicons[name]) do paths[#paths + 1] = ('<path d="%s"/>'):format(d) end
	return ('<svg class="icon" viewBox="0 0 16 16" fill="%s">%s</svg>'):format(color, table.concat(paths))
end

-- Linear-style workflow state icons, drawn in the state's color.
local function linearIcon(stateType, color)
	local ring = '<circle cx="7" cy="7" r="6" fill="none" stroke="%s" stroke-width="1.5"%s/>'
	local shape
	if stateType == "started" then
		shape = ring:format(color, "") .. ('<path d="M7 3.5a3.5 3.5 0 0 1 0 7Z" fill="%s"/>'):format(color)
	elseif stateType == "completed" then
		shape = ('<circle cx="7" cy="7" r="7" fill="%s"/>'):format(color)
			.. '<path d="M4.3 7.2l1.8 1.8 3.6-3.7" fill="none" stroke="#fff" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round"/>'
	elseif stateType == "canceled" then
		shape = ('<circle cx="7" cy="7" r="7" fill="%s"/>'):format(color)
			.. '<path d="M4.8 4.8l4.4 4.4M9.2 4.8l-4.4 4.4" stroke="#fff" stroke-width="1.5" stroke-linecap="round"/>'
	elseif stateType == "backlog" or stateType == "triage" then
		shape = ring:format(color, ' stroke-dasharray="2.2 1.6"')
	else
		shape = ring:format(color, "")
	end
	return '<svg class="icon" viewBox="0 0 14 14">' .. shape .. "</svg>"
end

local css = [[
:root { --bg: #ffffff; --fg: #1f2328; --muted: #8a8f98; --soft: #59636e;
	--border: rgba(0,0,0,.08); --code: rgba(0,0,0,.05); --add: #1a7f37; --del: #d1242f; }
@media (prefers-color-scheme: dark) {
	:root { --bg: #1f2023; --fg: #e6e8eb; --muted: #8a8f98; --soft: #b4b9c0;
		--border: rgba(255,255,255,.09); --code: rgba(255,255,255,.08); --add: #3fb950; --del: #f85149; }
}
html, body { margin: 0; background: transparent; }
body { padding: 14px; font: 14px/1.45 -apple-system, BlinkMacSystemFont, "Inter", sans-serif;
	color: var(--fg); -webkit-font-smoothing: antialiased; }
.card { background: var(--bg); border: 1px solid var(--border); border-radius: 12px;
	box-shadow: 0 8px 28px rgba(0,0,0,.18), 0 1px 3px rgba(0,0,0,.08); cursor: pointer; overflow: hidden; }
.section { padding: 12px 16px; }
.section + .section { border-top: 1px solid var(--border); }
.head { display: flex; align-items: center; gap: 8px; color: var(--muted); }
.who { margin-left: auto; display: flex; align-items: center; gap: 7px; color: var(--fg); }
.avatar { width: 20px; height: 20px; border-radius: 50%; object-fit: cover; }
.initial { width: 20px; height: 20px; border-radius: 50%; background: var(--code); color: var(--soft);
	font-size: 11px; display: flex; align-items: center; justify-content: center; }
.title { font-size: 15px; font-weight: 500; overflow-wrap: anywhere; }
.head + .title { margin-top: 6px; }
.muted { color: var(--muted); }
.gh { display: flex; gap: 10px; }
.gh .icon { width: 18px; height: 18px; flex: none; margin-top: 2px; }
.desc { font-size: 13px; color: var(--soft); white-space: pre-wrap; overflow-wrap: anywhere;
	max-height: 190px; overflow-y: auto; cursor: auto; }
.desc code { font: 12px ui-monospace, SFMono-Regular, Menlo, monospace; background: var(--code);
	border-radius: 4px; padding: 0 3px; }
.desc b { color: var(--fg); font-weight: 600; }
.desc::-webkit-scrollbar { width: 6px; }
.desc::-webkit-scrollbar-thumb { background: var(--border); border-radius: 3px; }
.foot { display: flex; align-items: center; gap: 6px; color: var(--soft); }
.foot .icon { width: 15px; height: 15px; flex: none; }
.foot .when { margin-left: auto; color: var(--muted); font-size: 12px; }
.add { color: var(--add); } .del { color: var(--del); }
.error { color: var(--del); }
]]

local function linearCard(item)
	local who = '<span class="who"><span class="muted">Unassigned</span></span>'
	if item.assignee then
		local initial = ('<span class="initial">%s</span>'):format(escape(item.assignee:sub(1, 1):upper()))
		local face = item.avatar and ('<img class="avatar" src="%s">'):format(escape(item.avatar)) or initial
		who = ('<span class="who">%s%s</span>'):format(face, escape(item.assignee))
	end
	local head = ('<div class="section"><div class="head"><span>%s</span>%s</div><div class="title">%s</div></div>')
		:format(escape(item.ref), who, escape(item.title))
	local foot = ('%s<span>%s</span>%s'):format(linearIcon(item.stateType, escape(item.stateColor or "#8a8f98")),
		escape(item.state), item.priority and ('<span class="muted">· %s</span>'):format(escape(item.priority)) or "")
	return head, foot
end

local function githubCard(item)
	local style = (githubStyles[item.kind] or githubStyles.issue)[item.state] or { "issueOpen", "#59636e" }
	local head = ('<div class="section gh">%s<div><div class="title">%s</div><div class="muted">%s%s</div></div></div>')
		:format(octicon(style[1], style[2]), escape(item.title), escape(item.ref),
			item.author and (" · " .. escape(item.author)) or "")
	local foot = "<span>" .. escape(item.state) .. "</span>"
	if item.files then
		foot = foot .. ('<span>· %d files</span><span class="add">+%d</span><span class="del">-%d</span>')
			:format(item.files, item.additions or 0, item.deletions or 0)
	end
	return head, foot
end

local function render(ref, item, at, err)
	local content
	if item then
		local head, foot = (item.source == "linear" and linearCard or githubCard)(item)
		local desc = describe(item.body)
		content = head
			.. (desc ~= "" and ('<div class="section desc">%s</div>'):format(desc) or "")
			.. ('<div class="section foot">%s<span class="when" id="when">%s</span></div>'):format(foot, at and ago(at) or "")
	else
		local label = ref.kind == "linear" and ref.id or (ref.repo:match("[^/]+$") .. "#" .. ref.number)
		content = ('<div class="section"><div class="head">%s</div><div class="title %s">%s</div></div>')
			:format(escape(label), err and "error" or "muted", escape(err or "Loading…"))
	end
	return ([[<!doctype html><html><head><meta charset="utf-8"><style>%s</style></head><body>
<div class="card" data-url="%s">%s</div>
<script>
const card = document.querySelector('.card');
const post = (m) => { try { webkit.messageHandlers.hoverPeek.postMessage(m) } catch (e) {} };
card.addEventListener('click', (e) => {
	// Clicks in the description are for reading and scrolling, not opening.
	if (!e.target.closest('.desc') && card.dataset.url) post({ open: card.dataset.url });
});
for (const img of document.querySelectorAll('img.avatar')) {
	img.addEventListener('error', () => img.remove());
}
new ResizeObserver(() => post({ height: Math.ceil(card.getBoundingClientRect().height) })).observe(card);
</script></body></html>]]):format(css, escape(item and item.url), content)
end

-- Below the anchor, or above it when there is no room; kept on screen.
local function place(height)
	local anchor = shown.anchor
	-- hs.screen.find(point) means a grid position, not coordinates, so search by frame.
	local screen = hs.mouse.getCurrentScreen()
	for _, candidate in ipairs(hs.screen.allScreens()) do
		if contains(candidate:fullFrame(), anchor) then screen = candidate; break end
	end
	local bounds = screen:frame()
	local w, h = M.config.width + 2 * margin, height + 2 * margin
	local x = math.max(bounds.x, math.min(anchor.x - margin, bounds.x + bounds.w - w))
	local y = anchor.y + anchor.h + 4 - margin
	if y + h > bounds.y + bounds.h then y = math.max(bounds.y, anchor.y - 4 - h + margin) end
	shown.frame = { x = x, y = y, w = w, h = h }
	view:frame(shown.frame)
end

local function ensureView()
	if view then return view end
	local content = hs.webview.usercontent.new("hoverPeek")
	content:setCallback(function(message)
		local body = message.body
		if not shown or type(body) ~= "table" then return end
		if body.open then
			local url = body.open
			if M.config.linearDesktop and hs.urlevent.getDefaultHandler("linear") then
				url = url:gsub("^https://linear%.app/", "linear://")
			end
			hs.urlevent.openURL(url)
			M.hide()
		elseif body.height then
			place(body.height)
		end
	end)
	view = hs.webview.new({ x = 0, y = 0, w = M.config.width, h = 100 }, { developerExtrasEnabled = false }, content)
		:windowStyle({ "borderless", "nonactivating" })
		:transparent(true)
		:shadow(false)
		:level(hs.drawing.windowLevels.popUpMenu)
		:behaviorAsLabels({ "canJoinAllSpaces", "transient" })
		:allowTextEntry(false)
	return view
end

function M.hide()
	if keyTap then keyTap:stop() end
	if view then view:hide() end
	shown = nil
end

function M.show(ref, anchor)
	ensureView()
	if shown and shown.ref.key == ref.key then return end
	shown = { ref = ref, anchor = anchor }
	local this = shown
	view:html(render(ref))
	place(60)
	view:show()
	-- Typing, or scrolling or clicking elsewhere, dismisses; the event still goes through.
	keyTap = keyTap or hs.eventtap.new({
		hs.eventtap.event.types.keyDown, hs.eventtap.event.types.scrollWheel,
		hs.eventtap.event.types.leftMouseDown, hs.eventtap.event.types.rightMouseDown,
	}, function(event)
		-- Clicks and scrolls inside the popover are for the popover.
		local typing = event:getType() == hs.eventtap.event.types.keyDown
		if shown and (typing or not contains(shown.frame, event:location())) then
			hs.timer.doAfter(0, M.hide)
		end
		return false
	end)
	keyTap:start()
	lookup(ref, function(item, at, _, err)
		if shown ~= this then return end
		-- A refresh that changed nothing only updates the age, keeping the scroll position.
		local signature = item and hs.json.encode(item) or err or ""
		if this.signature == signature then
			view:evaluateJavaScript(("document.getElementById('when').textContent = '%s'"):format(at and ago(at) or ""))
		else
			this.signature = signature
			view:html(render(ref, item, at, err))
		end
	end)
end

---------------------------------------------------------------------------
-- Triggers
---------------------------------------------------------------------------

local function matchOpts()
	return { defaultRepo = M.config.defaultRepo, teamKeys = teamKeys }
end

function M.peekAt(point)
	ocrAround(point, function(tokens)
		local token = M.tokenAt(tokens, point.x, point.y)
		local ref = token and M.parseRef(token.text, matchOpts())
		if ref then
			M.show(ref, { x = token.x, y = token.y, w = token.w, h = token.h })
		else
			hs.alert.show("No Linear issue or PR under the mouse", 1)
		end
	end)
end

-- A partial selection (123 of #123, SHE of SHE-287) is extended to the
-- on-screen word that contains it, read with OCR around the release point.
local function peekAtSelection(text, point)
	local ref = M.refInSelection(text, matchOpts())
	if ref then return M.show(ref, { x = point.x - 4, y = point.y - 8, w = 8, h = 16 }) end
	local selected = type(text) == "string" and text:match("^%s*(%S+)%s*$")
	if not selected or #selected > 40 then return end
	ocrAround(point, function(tokens)
		local token = M.tokenContaining(tokens, selected, point.x, point.y)
		ref = token and M.parseRef(token.text, matchOpts())
		if ref then M.show(ref, { x = token.x, y = token.y, w = token.w, h = token.h }) end
	end)
end

-- The selecting app copies on mouse release; a clipboard change right after
-- the release is the selection. Other clipboard changes are never read.
local function onMouseUp(event)
	local app = hs.application.frontmostApplication()
	if not app or not M.selectionApps[app:bundleID() or ""] then return false end
	local point, count = event:location(), hs.pasteboard.changeCount()
	hs.timer.doAfter(0.15, function()
		if hs.pasteboard.changeCount() == count then return end
		peekAtSelection(hs.pasteboard.getContents(), point)
	end)
	return false
end

-- Close once the mouse leaves the anchor, the popover, and the gap between them.
local function tick()
	if not shown then return end
	local a, f = shown.anchor, shown.frame
	local x1, y1 = math.min(a.x, f.x + margin), math.min(a.y, f.y + margin)
	local x2 = math.max(a.x + a.w, f.x + f.w - margin)
	local y2 = math.max(a.y + a.h, f.y + f.h - margin)
	local area = expanded({ x = x1, y = y1, w = x2 - x1, h = y2 - y1 }, 10)
	if not contains(area, hs.mouse.absolutePosition()) then M.hide() end
end

function M:start(opts)
	for k, v in pairs(opts or {}) do M.config[k] = v end
	hs.fs.mkdir(M.config.cacheDir)
	cache = hs.json.read(cachePath) or {}
	M.selectionApps = {}
	for _, id in ipairs(M.config.selectionApps) do M.selectionApps[id] = true end
	refreshTeams()
	ocrReady(function() end)
	-- Without it, snapshots show only the wallpaper and Hammerspoon's own windows.
	if hs.screenRecordingState and not hs.screenRecordingState(false) then
		hs.alert.show("hover-peek needs Screen Recording permission for Hammerspoon", 4)
	end
	self.timer = self.timer or hs.timer.doEvery(0.1, tick)
	self.selectionTap = self.selectionTap
		or hs.eventtap.new({ hs.eventtap.event.types.leftMouseUp }, onMouseUp):start()
	local mods, key = table.unpack(M.config.hotkey)
	self.hotkey = self.hotkey or hs.hotkey.bind(mods, key, function()
		if shown then M.hide() else M.peekAt(hs.mouse.absolutePosition()) end
	end)
	return self
end

function M:stop()
	M.hide()
	if self.timer then self.timer:stop(); self.timer = nil end
	if self.selectionTap then self.selectionTap:stop(); self.selectionTap = nil end
	if self.hotkey then self.hotkey:delete(); self.hotkey = nil end
	if ocrTask then ocrTask:terminate(); ocrTask = nil end
	return self
end

return M
