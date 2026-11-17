--------------------------------------------------------------------------------
-- Spellbook: every active spell the character knows, all ranks of a spell
-- together. Low ranks hidden by the spellbook's own filter are still read.
--------------------------------------------------------------------------------

local _, ns = ...
local Safe = ns.Safe

local Spellbook = {}
ns.Spellbook = Spellbook

function Spellbook.Bank()
	return Enum and Enum.SpellBookSpellBank and Enum.SpellBookSpellBank.Player or 0
end

local function SpellItemType()
	return Enum and Enum.SpellBookItemType and Enum.SpellBookItemType.Spell or 1
end

-- the first skill line is General (racials, professions, Attack...); the rest
-- belong to the class
local function IsGeneralLine(index, name)
	if index == 1 then return true end
	return name ~= nil and name == (_G.GENERAL or "General")
end

function Spellbook.SpellName(spellID)
	if C_Spell and C_Spell.GetSpellName then
		return Safe.Call(C_Spell.GetSpellName, spellID)
	end
	return Safe.Call(GetSpellInfo, spellID)
end

-- "Rank 3" (the game's own, translated text), or nil
function Spellbook.RankText(spellID)
	local text = Safe.Call(C_Spell and C_Spell.GetSpellSubtext or GetSpellSubtext, spellID)
	if text == "" then return nil end
	return text
end

--------------------------------------------------------------------------------
-- Spellbook.Read() -> {
--   groups = { [name] = { name, isClass, spellID, slot, maxRank, maxRankText, maxSpellID, maxSlot } },
--   byID   = { [spellID] = { key, rank, text, slot } },   -- every rank of every spell
--   lines  = { { index, name, offset, count, skipped, isClass }, ... },
--   read   = number of spellbook entries read,
-- }
--------------------------------------------------------------------------------

function Spellbook.Read()
	local groups, byID, lines = {}, {}, {}
	local book = C_SpellBook or {}
	local bank = Spellbook.Bank()
	local spellType = SpellItemType()
	local read = 0

	local numLines = Safe.Call(book.GetNumSpellBookSkillLines) or 0
	for index = 1, numLines do
		local info = Safe.Call(book.GetSpellBookSkillLineInfo, index)
		if info then
			local lineName = Safe.Field(info, "name")
			local offset = tonumber(Safe.Field(info, "itemIndexOffset")) or 0
			local count = tonumber(Safe.Field(info, "numSpellBookItems")) or 0
			local skipped = (Safe.Field(info, "shouldHide") or Safe.Field(info, "isGuild")
				or Safe.Field(info, "offSpecID") ~= nil) and true or false
			local isClass = not IsGeneralLine(index, lineName)
			table.insert(lines, {
				index = index, name = lineName, offset = offset, count = count,
				skipped = skipped, isClass = isClass,
			})

			if not skipped then
				for slot = offset + 1, offset + count do
					local item = Safe.Call(book.GetSpellBookItemInfo, slot, bank)
					local spellID = Safe.Field(item, "spellID")
					local name = Safe.Field(item, "name")
					if spellID and name and name ~= ""
						and Safe.Field(item, "itemType") == spellType
						and not Safe.Field(item, "isPassive")
						and not Safe.Field(item, "isOffSpec") then
						read = read + 1
						local text = Safe.Field(item, "subName")
						if not ns.ParseRank(text) then text = Spellbook.RankText(spellID) end
						local rank = ns.ParseRank(text)
						byID[spellID] = { key = name, rank = rank, text = text, slot = slot }

						local g = groups[name]
						if not g then
							g = { name = name, isClass = isClass, spellID = spellID, slot = slot }
							groups[name] = g
						elseif isClass then
							g.isClass = true
						end
						if rank and (not g.maxRank or rank > g.maxRank) then
							g.maxRank, g.maxRankText, g.maxSpellID, g.maxSlot = rank, text, spellID, slot
						end
					end
				end
			end
		end
	end

	return { groups = groups, byID = byID, lines = lines, read = read }
end

-- the spellbook entry for a typed name (any case), or nil
function Spellbook.Find(groups, typed)
	typed = typed and typed:lower():gsub("^%s+", ""):gsub("%s+$", "")
	if not typed or typed == "" then return nil end
	for key, g in pairs(groups) do
		if key:lower() == typed then return g end
	end
	return nil
end
