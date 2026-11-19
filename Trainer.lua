--------------------------------------------------------------------------------
-- After the trainer: one chat line when spells on your bars got a new rank.
-- Turned off with /refine trainer.
--------------------------------------------------------------------------------

local _, ns = ...
local L = ns.L
local Safe = ns.Safe

local CHECK_DELAY = 0.5   -- let the spellbook settle after the trainer closes

local open, learned, before = false, false, 0

local function OutdatedCount()
	local r = ns.Scan()
	return r and #r.outdated or 0
end

-- "open the spellbook (P)", with the player's own key for it
local function OpenSpellbookText()
	local key = Safe.Call(GetBindingKey, "TOGGLESPELLBOOK")
	if key then
		local text = Safe.Call(GetBindingText, key) or key
		return L["open the spellbook (%s)"]:format(text)
	end
	return L["open the spellbook"]
end

local function Report()
	local n = OutdatedCount()
	ns.Debug("trainer closed: learned %s, outdated %d (was %d)", tostring(learned), n, before)
	if n > 0 and (learned or n > before) then
		if n == 1 then
			ns.Print(L["1 spell on your bars has a new rank: %s to update it."], OpenSpellbookText())
		else
			ns.Print(L["%d spells on your bars have a new rank: %s to update them."], n, OpenSpellbookText())
		end
	end
	learned = false
end

ns.On("TRAINER_SHOW", function()
	if open then return end
	open, learned = true, false
	before = OutdatedCount()
end)

local function OnLearned()
	if open then learned = true end
end
ns.On("LEARNED_SPELL_IN_SKILL_LINE", OnLearned)
ns.On("LEARNED_SPELL_IN_TAB", OnLearned)   -- older clients

ns.On("TRAINER_CLOSED", function()
	if not open then return end
	open = false
	if not ns.db or not ns.db.trainerNote then return end
	C_Timer.After(CHECK_DELAY, Report)
end)
