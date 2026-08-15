--!strict
-- T-170 (GDD §17.2). CI-style drift guard for the anti-cheat audit
-- checklist (ANTI_CHEAT_AUDIT.md): scans every `Service.Client:Method`
-- definition under src/server/services/*.lua and cross-checks it against
-- the checklist's "Client-invokable surface" table, one line per
-- RemoteEvent per the DoD. Fails (non-zero exit) if either side has an
-- entry the other doesn't:
--   * a Client method exists in code with no checklist row -> a new
--     RemoteEvent shipped without an anti-cheat audit line.
--   * a checklist row names a Service/Method no longer in code -> a stale
--     entry (renamed/removed method), left to silently rot otherwise.
--
-- Run via: lune run scripts/audit-remote-events

local fs = require("@lune/fs")
local process = require("@lune/process")
local stdio = require("@lune/stdio")

local SERVICES_ROOT = "src/server/services"
local CHECKLIST_PATH = "ANTI_CHEAT_AUDIT.md"
local CHECKLIST_SECTION_HEADER = "## Client-invokable surface"

type Entry = { service: string, method: string }

local function entryKey(entry: Entry): string
	return entry.service .. "." .. entry.method
end

local function scanCodeEntries(): { Entry }
	local entries: { Entry } = {}
	for _, fileName in fs.readDir(SERVICES_ROOT) do
		if fileName:match("%.lua$") then
			local path = SERVICES_ROOT .. "/" .. fileName
			local content = fs.readFile(path)
			for service, method in content:gmatch("\nfunction%s+(%a+)%.Client:(%a+)") do
				table.insert(entries, { service = service, method = method })
			end
		end
	end
	return entries
end

local function scanChecklistEntries(): { Entry }
	local content = fs.readFile(CHECKLIST_PATH)

	local sectionStart = content:find(CHECKLIST_SECTION_HEADER, 1, true)
	assert(sectionStart, `{CHECKLIST_PATH} is missing the "{CHECKLIST_SECTION_HEADER}" section`)
	local nextSectionStart = content:find("\n## ", sectionStart + #CHECKLIST_SECTION_HEADER)
	local section = content:sub(sectionStart, nextSectionStart or #content)

	local entries: { Entry } = {}
	for line in section:gmatch("[^\n]+") do
		local service, method = line:match("^| ?([%a]+) ?| ?([%a]+) ?|")
		if service and method and service ~= "Service" and not line:match("^| ?%-%-%-") then
			table.insert(entries, { service = service, method = method })
		end
	end
	return entries
end

local codeEntries = scanCodeEntries()
local checklistEntries = scanChecklistEntries()

local codeKeys: { [string]: boolean } = {}
for _, entry in codeEntries do
	codeKeys[entryKey(entry)] = true
end
local checklistKeys: { [string]: boolean } = {}
for _, entry in checklistEntries do
	checklistKeys[entryKey(entry)] = true
end

local missingFromChecklist: { string } = {}
for _, entry in codeEntries do
	if not checklistKeys[entryKey(entry)] then
		table.insert(missingFromChecklist, entryKey(entry))
	end
end

local staleInChecklist: { string } = {}
for _, entry in checklistEntries do
	if not codeKeys[entryKey(entry)] then
		table.insert(staleInChecklist, entryKey(entry))
	end
end

table.sort(missingFromChecklist)
table.sort(staleInChecklist)

if #missingFromChecklist == 0 and #staleInChecklist == 0 then
	stdio.write(`Anti-cheat audit: {#codeEntries} Client method(s), 0 drift from {CHECKLIST_PATH}\n`)
	process.exit(0)
end

for _, key in missingFromChecklist do
	print(`Missing from {CHECKLIST_PATH}: {key} (exists in code, no audit row)`)
end
for _, key in staleInChecklist do
	print(`Stale in {CHECKLIST_PATH}: {key} (audited but no longer exists in code)`)
end
stdio.write(`Anti-cheat audit: {#missingFromChecklist + #staleInChecklist} drift issue(s) found\n`)
process.exit(1)
