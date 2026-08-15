--!strict
-- T-151 (GDD §13.2). CI-style hardcoded-string audit: walks src/ for every
-- .lua/.luau file, scans it with the pure HardcodedStringLint (T-151), and
-- prints a violations report. Exits non-zero when any violation exists —
-- the "zero violations required before Phase 18 sign-off" gate (T-202's IP
-- naming lint is wired the same way alongside this one).
--
-- Requires HardcodedStringLint by relative path rather than duplicating its
-- logic, so the TestEZ spec and this real audit share one source of truth.
--
-- Run via: lune run scripts/lint-hardcoded-strings

local fs = require("@lune/fs")
local process = require("@lune/process")
local stdio = require("@lune/stdio")

local HardcodedStringLint = require("../src/shared/modules/HardcodedStringLint")

local SCAN_ROOTS = { "src/client", "src/shared", "src/server" }

local function isLuaFile(name: string): boolean
	return name:match("%.lua$") ~= nil or name:match("%.luau$") ~= nil
end

local function walk(path: string, files: { string })
	for _, entry in fs.readDir(path) do
		local fullPath = path .. "/" .. entry
		if fs.isDir(fullPath) then
			walk(fullPath, files)
		elseif isLuaFile(entry) then
			table.insert(files, fullPath)
		end
	end
end

local files: { string } = {}
for _, root in SCAN_ROOTS do
	if fs.isDir(root) then
		walk(root, files)
	end
end
table.sort(files)

local totalViolations = 0
for _, path in files do
	local content = fs.readFile(path)
	local violations = HardcodedStringLint.scan(content)
	for _, violation in violations do
		totalViolations += 1
		print(`{path}:{violation.line}: {violation.text}`)
	end
end

if totalViolations == 0 then
	stdio.write("Hardcoded-string lint: 0 violations\n")
	process.exit(0)
else
	stdio.write(`Hardcoded-string lint: {totalViolations} violation(s) found\n`)
	process.exit(1)
end
