-- Monotonic millisecond clock for perf timing (absoluteTime is nanoseconds).
local function now_ms()
    return hs.timer.absoluteTime() / 1e6
end

-- Returns the registrable base domain (last two dot-separated labels).
-- e.g. www.reddit.com -> reddit.com, m.en.wikipedia.org -> wikipedia.org
local function base_domain(domain)
    local labels = {}
    for label in string.gmatch(domain, "[^.]+") do
        table.insert(labels, label)
    end
    local n = #labels
    if n <= 2 then return domain end
    return labels[n - 1] .. "." .. labels[n]
end

-- Number of dots in a string; used to pick the cleanest representative.
local function dot_count(s)
    local _, n = string.gsub(s, "%.", "")
    return n
end

-- Function to get enabled domains, grouped by base domain so that e.g.
-- reddit.com and www.reddit.com collapse into a single chooser entry.
function get_enabled_domains()
    local t0 = now_ms()
    -- Read /etc/hosts directly (world-readable) instead of spawning the
    -- `hosts` subprocess. This mirrors `hosts enabled`: an entry is "enabled"
    -- if its line is neither blank nor a comment. The `hosts` tool disables
    -- entries by prefixing "#disabled: ", so the comment filter excludes both
    -- disabled entries and ordinary comments.
    local output = ""
    local file = io.open("/etc/hosts", "r")
    if file then
        output = file:read("*a")
        file:close()
    else
        print("[hosts-manager] WARN: could not open /etc/hosts")
    end
    local t_exec = now_ms()

    -- Define blacklist
    local blacklist = {
        ["broadcasthost"] = true,
        ["localhost"] = true
    }

    -- Group enabled domains by their base domain.
    local groups = {}  -- base -> list of domains
    for line in string.gmatch(output, "[^\r\n]+") do
        -- Skip blank lines and comments (incl. "#disabled:" entries).
        if not string.match(line, "^%s*$") and not string.match(line, "^%s*#") then
            local domain = string.match(line, "^%s*%S+%s+(%S+)")
            if domain and not blacklist[domain] then
                local b = base_domain(domain)
                groups[b] = groups[b] or {}
                table.insert(groups[b], domain)
            end
        end
    end

    -- Build one chooser choice per group. The representative shown is the
    -- cleanest variant (fewest dots, then shortest, then alphabetical), and
    -- the full group is carried on the choice so all variants unblock together.
    local choices = {}
    for _, domains in pairs(groups) do
        table.sort(domains, function(a, c)
            local da, dc = dot_count(a), dot_count(c)
            if da ~= dc then return da < dc end
            if #a ~= #c then return #a < #c end
            return a < c
        end)
        local subText = (#domains > 1)
            and (#domains .. " variants: " .. table.concat(domains, ", "))
            or "Unblock this domain"
        table.insert(choices, {text = domains[1], subText = subText, domains = domains})
    end

    table.sort(choices, function(a, c) return a.text < c.text end)

    local t_done = now_ms()
    print(string.format(
        "[hosts-manager] get_enabled_domains: read=%.0fms parse=%.0fms total=%.0fms (%d groups)",
        t_exec - t0, t_done - t_exec, t_done - t0, #choices))
    return choices
end

-- Function to handle domain selection
local function domainSelectionCallback(choice)
    if not choice then
        hs.alert.show("No selection made")
        return
    end
    hs.alert.show("You selected: " .. choice.text)
    -- Proceed to duration input, carrying the whole group of domains
    hs.focus()
    inputDuration(choice.text, choice.domains)
end


-- Function to input duration. `label` is the representative domain shown to
-- the user; `domains` is the full group of variants to unblock together.
function inputDuration(label, domains)
    local option, text = hs.dialog.textPrompt("Enter Duration", "Specify the unblock duration for " .. label, "", "OK", "Cancel")
    if option == "OK" then
        -- Parameters for the POST request
        local url = "http://localhost:" .. 2999 .. "/unblock"  -- Make sure PORT is defined or directly include the port number
        local headers = {["Content-Type"] = "application/json"}
        local data = hs.json.encode({domains = domains, duration_string = text})

        -- Sending the POST request
        hs.http.doAsyncRequest(url, "POST", data, headers, function(status, response)
            if status == 200 then
                hs.alert.show("Unblocked " .. label .. " for " .. text)
            else
                hs.alert.show("Failed to unblock. Status: " .. status)
            end
            print(response)  -- This will print the server response to the Hammerspoon Console
        end)
    else
        hs.alert.show("No duration entered or cancelled")
    end
end



local unblockSiteChooser = hs.chooser.new(domainSelectionCallback)

function handleUnblockHotkey()
    local t0 = now_ms()
    local choices = get_enabled_domains()
    local t_choices = now_ms()
    unblockSiteChooser:choices(choices)
    local t_set = now_ms()
    unblockSiteChooser:show()
    local t_show = now_ms()
    print(string.format(
        "[hosts-manager] open modal: build=%.0fms setChoices=%.0fms show=%.0fms TOTAL=%.0fms",
        t_choices - t0, t_set - t_choices, t_show - t_set, t_show - t0))
end

return handleUnblockHotkey
