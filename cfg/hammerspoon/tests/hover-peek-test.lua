-- Pure matching checks for hover-peek.lua; no OCR, network, or UI.
local path = debug.getinfo(1, "S").source:sub(2):match("^(.*)/tests/")
local M = dofile(path .. "/hover-peek.lua")
local failures = 0

local function check(text, opts, want)
	local ref = M.parseRef(text, opts)
	local got = ref and ref.key or "nil"
	if got ~= want then
		failures = failures + 1
		print(("FAIL %q: want %s, got %s"):format(text, want, got))
	end
end

local default = { defaultRepo = "sherwinyu/oryoki" }
local teams = { defaultRepo = "sherwinyu/oryoki", teamKeys = { SHE = true } }

check("#335", default, "github:sherwinyu/oryoki#335")
check("(#335),", default, "github:sherwinyu/oryoki#335")
check("#335", {}, "nil")
check("Gamma-App/Gamma#12", default, "github:gamma-app/gamma#12")
check("https://github.com/sherwinyu/oryoki/pull/332", {}, "github:sherwinyu/oryoki#332")
check("github.com/sherwinyu/oryoki/issues/7.", {}, "github:sherwinyu/oryoki#7")
check("https://linear.app/sherwin/issue/SHE-287/security-websocket", {}, "linear:SHE-287")
check("SHE-287", {}, "linear:SHE-287")
check("(SHE-256)", {}, "linear:SHE-256")
check("UTF-8", {}, "linear:UTF-8") -- no team list yet: any uppercase ID shape
check("UTF-8", teams, "nil")
check("ISO-8601", teams, "nil")
check("sherwin/she-120-fix-thing", teams, "linear:SHE-120")
check("sherwin/she-120-fix-thing", {}, "nil")
check("2026-10-29", teams, "nil")
check("SHE-12a", teams, "nil")

local function checkSelection(text, want)
	local ref = M.refInSelection(text, teams)
	local got = ref and ref.key or "nil"
	if got ~= want then
		failures = failures + 1
		print(("FAIL selection %q: want %s, got %s"):format(text, want, got))
	end
end

checkSelection("SHE-287", "linear:SHE-287")
checkSelection("  #335\n", "github:sherwinyu/oryoki#335")
checkSelection("see SHE-12 and #3", "linear:SHE-12")
checkSelection("no refs here", "nil")
checkSelection(("x "):rep(150) .. "SHE-1", "nil")
checkSelection(nil, "nil")

local tokens = {
	{ text = "Fix", x = 0, y = 0, w = 20, h = 10 },
	{ text = "SHE-12", x = 25, y = 0, w = 40, h = 10 },
}
local hit = M.tokenAt(tokens, 30, 5)
if not hit or hit.text ~= "SHE-12" then failures = failures + 1; print("FAIL tokenAt inside") end
if M.tokenAt(tokens, 100, 5) then failures = failures + 1; print("FAIL tokenAt outside") end
-- Inside both padded rects: the nearer center wins.
hit = M.tokenAt(tokens, 22.5, 5)
if not hit or hit.text ~= "Fix" then failures = failures + 1; print("FAIL tokenAt between") end

-- Extending a partial selection to the word on screen that contains it.
local line = {
	{ text = "#12", x = 0, y = 0, w = 20, h = 10 },
	{ text = "fixes", x = 25, y = 0, w = 30, h = 10 },
	{ text = "(#123)", x = 60, y = 0, w = 40, h = 10 },
	{ text = "#123", x = 0, y = 40, w = 30, h = 10 },
}
hit = M.tokenContaining(line, "123", 101, 5) -- released just past the word
if not hit or hit.text ~= "(#123)" then failures = failures + 1; print("FAIL tokenContaining nearest") end
if M.tokenContaining(line, "999", 50, 5) then failures = failures + 1; print("FAIL tokenContaining none") end
local extended = hit and M.parseRef(hit.text, default)
if not extended or extended.key ~= "github:sherwinyu/oryoki#123" then
	failures = failures + 1; print("FAIL extended ref")
end

if failures > 0 then os.exit(1) end
print("hover-peek: all checks passed")
