--------------------------------------------------------------------------------
-- Scan and update: compares the spellbook with the action bars, and puts the
-- highest rank on the slots that need it. Out of combat only.
--------------------------------------------------------------------------------

local _, ns = ...
local L = ns.L
local Safe = ns.Safe

--------------------------------------------------------------------------------
-- Ignored spells (per character, kept by spell ID, matched by name)
--------------------------------------------------------------------------------

local function KeyOf(byID, spellID)
	local known = byID and byID[spellID]
	return known and known.key or ns.Spellbook.SpellName(spellID)
end

local function IgnoredKeys(byID)
	local keys = {}
	for spellID in pairs(ns.Char().ignored) do
		local key = KeyOf(byID, spellID)
		if key then keys[key] = true end
	end
	return keys
end

function ns.Ignore(spellID)
	if not spellID then return end
	ns.Char().ignored[spellID] = true
	ns.Fire("CHANGED")
end

-- stops ignoring every ignored ID that has this name
function ns.Unignore(key)
	local ignored = ns.Char().ignored
	local byID = ns.last and ns.last.book.byID
	for spellID in pairs(ignored) do
		if KeyOf(byID, spellID) == key then ignored[spellID] = nil end
	end
	ns.Fire("CHANGED")
end

-- { { key, spellID }, ... } sorted by name
function ns.IgnoredList()
	local list, seen = {}, {}
	local byID = ns.last and ns.last.book.byID
	for spellID in pairs(ns.Char().ignored) do
		local key = KeyOf(byID, spellID) or ("#" .. spellID)
		if not seen[key] then
			seen[key] = true
			table.insert(list, { key = key, spellID = spellID })
		end
	end
	table.sort(list, function(a, b) return a.key < b.key end)
	return list
end

--------------------------------------------------------------------------------
-- Scan
--------------------------------------------------------------------------------

-- reads the spellbook and the bars; the result is also kept in ns.last
function ns.Scan()
	if not ns.db then return nil end
	local book = ns.Spellbook.Read()
	local onBars, stats = ns.Bars.Read(book.byID)
	local result = ns.Analyze(book.groups, onBars, IgnoredKeys(book.byID))
	result.book, result.onBars, result.stats = book, onBars, stats
	ns.last = result
	return result
end

--------------------------------------------------------------------------------
-- Update
--------------------------------------------------------------------------------

local function CursorHasSpell()
	return (Safe.CallAll(GetCursorInfo)) == "spell"
end

-- puts the highest rank on the cursor: the spellbook entry itself, or the
-- spell by its ID
local function Pickup(o)
	if o.bookSlot and C_SpellBook and C_SpellBook.PickupSpellBookItem then
		pcall(C_SpellBook.PickupSpellBookItem, o.bookSlot, ns.Spellbook.Bank())
		if CursorHasSpell() then return "spellbook" end
		ClearCursor()
	end
	local pickup = (C_Spell and C_Spell.PickupSpell) or PickupSpell
	if o.spellID and pickup then
		pcall(pickup, o.spellID)
		if CursorHasSpell() then return "spell ID" end
		ClearCursor()
	end
	return nil
end

local function Place(slot)
	local place = PlaceAction or (C_ActionBar and C_ActionBar.PutActionInSlot)
	if not place then return false end
	return (pcall(place, slot))
end

-- true when the slot now holds the highest rank
local function Confirm(o, slot, byID)
	local id = ns.Bars.SpellAt(slot)
	if id == nil then return false, id end
	if id == o.spellID then return true, id end
	local known = byID[id]
	return (known and known.key == o.key and known.rank == o.toRank) and true or false, id
end

-- updates every outdated slot; returns changed, failed (nil, reason when it
-- can't start)
function ns.UpdateBars()
	if not ns.db then return nil, "loading" end
	if InCombatLockdown() then
		ns.ScreenError(L["You can't change your action bars in combat."])
		return nil, "combat"
	end
	if Safe.CallAll(GetCursorInfo) then
		ns.ScreenError(L["Drop what's on your cursor first."])
		return nil, "cursor"
	end

	local result = ns.Scan()
	local byID = result.book.byID
	local changed, failed = 0, 0

	for _, o in ipairs(result.outdated) do
		for _, slot in ipairs(o.slots) do
			local how = Pickup(o)
			if not how then
				failed = failed + 1
				ns.Debug("%s: couldn't pick up %s (spell %s, spellbook slot %s)", tostring(slot), o.name,
					tostring(o.spellID), tostring(o.bookSlot))
			else
				local placed = Place(slot)
				ClearCursor()   -- drops the old rank the slot gave back
				local ok, now = Confirm(o, slot, byID)
				if placed and ok then
					changed = changed + 1
					ns.Debug("slot %d: %s %s -> %s (from the %s)", slot, o.name, tostring(o.fromText),
						tostring(o.toText), how)
				else
					failed = failed + 1
					ns.Debug("slot %d: %s not changed (placed %s, slot now holds spell %s)", slot, o.name,
						tostring(placed), tostring(now))
				end
			end
		end
	end
	ClearCursor()

	if failed > 0 then
		ns.ScreenError(L["Some action bar buttons couldn't be changed. Type /refine diag."])
	end
	ns.Fire("CHANGED")
	return changed, failed
end
