--------------------------------------------------------------------------------
-- Slash commands: /refine
--------------------------------------------------------------------------------

local _, ns = ...
local L = ns.L
local Safe = ns.Safe

local function Line(fmt, ...)
	local msg = select("#", ...) > 0 and fmt:format(...) or tostring(fmt)
	DEFAULT_CHAT_FRAME:AddMessage("  " .. msg)
end

--------------------------------------------------------------------------------
-- /refine diag (English on purpose: it goes into bug reports)
--------------------------------------------------------------------------------

local function Present(fn)
	return fn and "present" or nil
end

local function Diag()
	local function Check(label, fn)
		local ok, res = pcall(fn)
		local text
		if not ok then
			text = "|cffff4040error|r " .. tostring(res)
		elseif res == nil then
			text = "|cffff4040missing|r"
		elseif issecretvalue and issecretvalue(res) then
			text = "|cffff8000secret|r"
		else
			text = "|cff40ff40ok|r (" .. tostring(res) .. ")"
		end
		Line("%s: %s", label, text)
	end

	ns.Print("diag")
	Check("client", function() return (Safe.CallAll(GetBuildInfo)) end)
	Check("C_SpellBook.GetNumSpellBookSkillLines", function() return C_SpellBook.GetNumSpellBookSkillLines() end)
	Check("C_SpellBook.GetSpellBookItemInfo", function() return Present(C_SpellBook.GetSpellBookItemInfo) end)
	Check("C_SpellBook.PickupSpellBookItem", function() return Present(C_SpellBook.PickupSpellBookItem) end)
	Check("C_SpellBook.IsSpellBookItemLowRank", function() return Present(C_SpellBook.IsSpellBookItemLowRank) end)
	Check("C_Spell.PickupSpell", function() return Present(C_Spell and C_Spell.PickupSpell) end)
	Check("C_Spell.GetSpellSubtext", function() return Present(C_Spell and C_Spell.GetSpellSubtext) end)
	Check("GetActionInfo", function() return Present(GetActionInfo) end)
	Check("PlaceAction", function() return Present(PlaceAction) end)
	Check("C_ActionBar.PutActionInSlot", function() return Present(C_ActionBar and C_ActionBar.PutActionInSlot) end)
	Check("C_ActionBar.IsHighestSpellRank", function() return Present(C_ActionBar and C_ActionBar.IsHighestSpellRank) end)
	Check("Blizzard_PlayerSpells loaded", function()
		local isLoaded = (C_AddOns and C_AddOns.IsAddOnLoaded) or IsAddOnLoaded
		return isLoaded("Blizzard_PlayerSpells") and "yes" or "no (open the spellbook once)"
	end)
	Check("spellbook button", function() return ns.Button.frame and "attached" or "not yet" end)

	local r = ns.Scan()
	if not r then
		Line("scan: not ready")
		return
	end

	Line("skill lines:")
	for _, line in ipairs(r.book.lines) do
		Line("  %d %s: slots %d-%d, %s", line.index, tostring(line.name), line.offset + 1, line.offset + line.count,
			line.skipped and "skipped" or (line.isClass and "class" or "general"))
	end

	local groups, ranked = 0, 0
	for _, g in pairs(r.book.groups) do
		groups = groups + 1
		if g.maxRank then ranked = ranked + 1 end
	end
	Line("spellbook: %d entries, %d spells, %d with ranks", r.book.read, groups, ranked)
	Line("action slots: %d valid, %d spells, %d macros", r.stats.valid, r.stats.spells, r.stats.macros)

	-- our highest rank vs. the game's own "low rank" flag
	local lowRank = C_SpellBook.IsSpellBookItemLowRank
	if lowRank then
		local disagree = 0
		for _, info in pairs(r.book.byID) do
			local g = r.book.groups[info.key]
			if g and g.maxRank and info.rank then
				local isLow = Safe.Call(lowRank, info.slot, ns.Spellbook.Bank())
				if isLow ~= nil and isLow ~= (info.rank < g.maxRank) then disagree = disagree + 1 end
			end
		end
		Line("low rank flag: %s", disagree == 0 and "agrees" or (disagree .. " entries disagree"))
	end

	Line("outdated: %d spells, %d buttons", #r.outdated, r.buttons)
	local isHighest = C_ActionBar and C_ActionBar.IsHighestSpellRank
	for _, o in ipairs(r.outdated) do
		local onBar = ns.Bars.SpellAt(o.slots[1])
		Line("  %s: %s > %s (spell %s, spellbook slot %s), slots %s, game says highest: %s", o.name,
			tostring(o.fromText), tostring(o.toText), tostring(o.spellID), tostring(o.bookSlot),
			table.concat(o.slots, ", "), tostring(isHighest and onBar and Safe.Call(isHighest, onBar)))
	end
	Line("not on your bars: %d (ignored: %d)", #r.missing, #ns.IgnoredList())
end

--------------------------------------------------------------------------------
-- Commands
--------------------------------------------------------------------------------

-- the everyday commands
local function EverydayLines()
	Line("/refine open - " .. L["open the window to choose the spells to ignore"])
	Line("/refine update - " .. L["update your action bars (the same as the spellbook button)"])
	Line("/refine ignore <spell> - " .. L["don't list a spell that isn't on your bars"])
	Line("/refine unignore <spell> - " .. L["list an ignored spell again"])
end

local function Help()
	ns.Print(L["Commands:"])
	EverydayLines()
	Line("|cff808080/refine advanced - " .. L["all commands"] .. "|r")
end

-- everything: also the trainer reminder and the commands for bug reports
local function Advanced()
	ns.Print(L["All commands:"])
	EverydayLines()
	Line("/refine trainer - " .. L["turn the chat line after the trainer on or off"])
	Line("/refine diag - " .. L["check what this client allows"])
	Line("/refine debug - " .. L["toggle debug messages"])
end

local function Update()
	local changed, failed = ns.UpdateBars()
	if changed == nil then return end   -- combat or cursor: already said on screen
	if changed > 0 then
		ns.Print(L["Updated %d action bar button(s)."], changed)
	elseif failed == 0 then
		ns.Print(L["Every spell on your bars is at its highest rank."])
	end
end

local function Ignore(arg)
	local r = ns.Scan()
	local g = r and ns.Spellbook.Find(r.book.groups, arg)
	if not g then
		ns.Print(L["No spell called \"%s\" in your spellbook."], arg or "")
		return
	end
	ns.Ignore(g.maxSpellID or g.spellID)
	ns.Print(L["Ignored: %s."], g.name)
end

local function Unignore(arg)
	local typed = (arg or ""):lower()
	for _, ig in ipairs(ns.IgnoredList()) do
		if ig.key:lower() == typed then
			ns.Unignore(ig.key)
			ns.Print(L["Listed again: %s."], ig.key)
			return
		end
	end
	ns.Print(L["\"%s\" isn't ignored."], arg or "")
end


local COMMANDS = {
	update = Update,
	ignore = Ignore,
	unignore = Unignore,
	open = function() ns.IgnoreWindow.Show() end,
	ignored = function() ns.IgnoreWindow.Show() end,   -- (the old name, still works; not listed)
	advanced = Advanced,
	trainer = function()
		ns.db.trainerNote = not ns.db.trainerNote
		ns.Print(ns.db.trainerNote and L["Chat line after the trainer: on."] or L["Chat line after the trainer: off."])
	end,
	diag = Diag,
	debug = function()
		ns.db.debug = not ns.db.debug
		ns.Print(ns.db.debug and L["Debug messages on."] or L["Debug messages off."])
	end,}

SLASH_REFINE1 = "/refine"
SlashCmdList.REFINE = function(msg)
	local cmd, arg = (msg or ""):match("^%s*(%S*)%s*(.-)%s*$")
	local fn = COMMANDS[(cmd or ""):lower()]
	if fn and ns.db then
		fn(arg ~= "" and arg or nil)
	else
		Help()
	end
end
