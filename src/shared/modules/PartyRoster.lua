-- T-120 (GDD §12.2). Pure party-membership rules: leader tracking, size cap,
-- ready-status, and leader-promotion-on-leave. Works with any hashable
-- "member" value (`any` — never introspected, just compared/keyed), so it
-- works directly with Player instances; PartyService owns the one
-- Roblox-facing wrapper per party and feeds it real Players.
--
-- Takes `maxSize` as a constructor arg rather than reading PartyConfig
-- itself, so it stays testable without any Roblox APIs — the same reasoning
-- DodgeStateMachine documents for taking its durations as constructor args.

local PartyRoster = {}
PartyRoster.__index = PartyRoster

export type PartyRoster = typeof(setmetatable(
	{} :: {
		leader: any,
		maxSize: number,
		members: { any },
		ready: { [any]: boolean },
	},
	PartyRoster
))

function PartyRoster.new(leader: any, maxSize: number): PartyRoster
	return setmetatable({
		leader = leader,
		maxSize = maxSize,
		members = { leader },
		ready = { [leader] = false },
	}, PartyRoster)
end

function PartyRoster.isLeader(self: PartyRoster, member: any): boolean
	return self.leader == member
end

function PartyRoster.size(self: PartyRoster): number
	return #self.members
end

function PartyRoster.hasRoom(self: PartyRoster): boolean
	return self:size() < self.maxSize
end

function PartyRoster.contains(self: PartyRoster, member: any): boolean
	for _, existing in self.members do
		if existing == member then
			return true
		end
	end
	return false
end

-- Returns false (no change) if the roster is full or the member is already in it.
function PartyRoster.addMember(self: PartyRoster, member: any): boolean
	if not self:hasRoom() or self:contains(member) then
		return false
	end
	table.insert(self.members, member)
	self.ready[member] = false
	return true
end

-- Removes `member`. If they were the leader, promotes the earliest-joined
-- remaining member. Returns true if the roster is now empty (the caller
-- should disband the party).
function PartyRoster.removeMember(self: PartyRoster, member: any): boolean
	for i, existing in self.members do
		if existing == member then
			table.remove(self.members, i)
			break
		end
	end
	self.ready[member] = nil

	if #self.members == 0 then
		return true
	end
	if self.leader == member then
		self.leader = self.members[1]
	end
	return false
end

function PartyRoster.setReady(self: PartyRoster, member: any, isReady: boolean)
	if self:contains(member) then
		self.ready[member] = isReady
	end
end

function PartyRoster.allReady(self: PartyRoster): boolean
	for _, member in self.members do
		if not self.ready[member] then
			return false
		end
	end
	return true
end

return PartyRoster
