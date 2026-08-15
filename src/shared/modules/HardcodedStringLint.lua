-- T-151 (GDD §13.2). Pure hardcoded-string detector: scans Lua source text
-- line-by-line for an assignment to a player-facing text property using a
-- plain, non-empty string literal rather than a call routed through the
-- translator. Takes source text as a plain string (not a filesystem path)
-- so it's fully testable without touching disk and reusable outside Roblox
-- — the Lune CI runner (T-151) requires this exact module and calls it per
-- file, so the detection logic has one source of truth for both the
-- TestEZ spec and the real audit.

local HardcodedStringLint = {}

-- Properties Roblox renders directly to the player as visible text.
HardcodedStringLint.TEXT_PROPERTIES = { "Text", "PlaceholderText", "ActionText", "ObjectText" }

-- A line containing this is assumed to already route through the
-- translator (or is a deliberate, explicit exemption) and is skipped.
-- Pattern-escaped: `(` is a capture-group opener in Lua patterns.
local EXEMPT_MARKERS = { ":Translate%(", "lint%-disable" }

export type Violation = { line: number, text: string }

local function buildPropertyPattern(propertyName: string): string
	-- `<ident>.PropertyName = "literal"` / '...' — a plain, non-empty string
	-- literal, not a variable, function call, or concatenation.
	return "%." .. propertyName .. "%s*=%s*[\"'][^\"']+[\"']"
end

local PROPERTY_PATTERNS: { string } = {}
for _, propertyName in HardcodedStringLint.TEXT_PROPERTIES do
	table.insert(PROPERTY_PATTERNS, buildPropertyPattern(propertyName))
end

function HardcodedStringLint.scan(sourceText: string): { Violation }
	local violations: { Violation } = {}
	local lineNumber = 0

	for line in (sourceText .. "\n"):gmatch("(.-)\n") do
		lineNumber += 1

		local exempt = false
		for _, marker in EXEMPT_MARKERS do
			if line:find(marker) then
				exempt = true
				break
			end
		end

		if not exempt then
			for _, pattern in PROPERTY_PATTERNS do
				if line:find(pattern) then
					local trimmed = line:match("^%s*(.-)%s*$") or line
					table.insert(violations, { line = lineNumber, text = trimmed })
					break -- one violation per line is enough
				end
			end
		end
	end

	return violations
end

return HardcodedStringLint
