--------------------------------------------------------------------------------
-- Action bars: which spell each action slot holds (all bars and pages,
-- including the stance and form bars). Macros are read too, to know a spell
-- is on the bars, but they are never changed.
--------------------------------------------------------------------------------

local _, ns = ...
local Safe = ns.Safe

local Bars = {}
ns.Bars = Bars

Bars.MAX_SLOT = 180

local function HasActionFn()
	return (C_ActionBar and C_ActionBar.HasAction) or HasAction
end

-- the spell a macro shows: with subType "spell" the game already gives it,
-- otherwise the id is the macro's
local function MacroSpell(id, subType)
	if subType == "spell" then return id end
	return Safe.Call(GetMacroSpell, id)
end

--------------------------------------------------------------------------------
-- Bars.Read(byID) -> entries, stats
--   entries = { { slot, spellID, key, rank, rankText, isMacro }, ... }
--   stats   = { valid, spells, macros }
-- byID is Spellbook.Read().byID; spells not in it are looked up by name.
--------------------------------------------------------------------------------

function Bars.Read(byID)
	local entries = {}
	local stats = { valid = 0, spells = 0, macros = 0 }
	local hasAction = HasActionFn()
	if not hasAction then return entries, stats end

	for slot = 1, Bars.MAX_SLOT do
		local ok, has = pcall(hasAction, slot)
		if ok then
			stats.valid = stats.valid + 1
			if Safe.Value(has) then
				local kind, id, subType = Safe.CallAll(GetActionInfo, slot)
				local spellID, isMacro
				if kind == "spell" then
					spellID = id
					stats.spells = stats.spells + 1
				elseif kind == "macro" and id then
					spellID = MacroSpell(id, subType)
					isMacro = true
					stats.macros = stats.macros + 1
				end
				if type(spellID) == "number" then
					local known = byID[spellID]
					local key, rank, text
					if known then
						key, rank, text = known.key, known.rank, known.text
					else
						key = ns.Spellbook.SpellName(spellID)
						text = ns.Spellbook.RankText(spellID)
						rank = ns.ParseRank(text)
					end
					table.insert(entries, {
						slot = slot, spellID = spellID, key = key,
						rank = rank, rankText = text, isMacro = isMacro,
					})
				end
			end
		end
	end
	return entries, stats
end

-- the spell in one slot (nil when it isn't a spell)
function Bars.SpellAt(slot)
	local kind, id = Safe.CallAll(GetActionInfo, slot)
	if kind == "spell" then return id end
	return nil
end
