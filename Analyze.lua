--------------------------------------------------------------------------------
-- Analysis: what the spellbook knows vs. what the action bars hold.
-- Pure logic (no game API), so it can be tested outside the game.
--------------------------------------------------------------------------------

local _, ns = ...

-- "Rank 3", "Grau 3", "Rang 3" -> 3; nil when there's no number (no rank)
function ns.ParseRank(text)
	if type(text) ~= "string" then return nil end
	local digits = text:match("(%d+)")
	return digits and tonumber(digits) or nil
end

local function ByName(a, b)
	return a.name < b.name
end

--------------------------------------------------------------------------------
-- ns.Analyze(groups, onBars, ignored)
--
--   groups  = { [key] = { name, isClass, maxRank, maxRankText, maxSpellID, maxSlot, spellID } }
--             one entry per spell of the spellbook (all its ranks together);
--             maxRank is nil for spells without ranks
--   onBars  = { { slot, key, rank, rankText, isMacro }, ... }
--             every action slot holding a spell or a macro that shows a spell;
--             key is nil when the spell isn't in the spellbook
--   ignored = { [key] = true }
--
-- Returns {
--   outdated = { { key, name, fromRank, fromText, toRank, toText, spellID, bookSlot, slots }, ... },
--   missing  = { { key, name, spellID }, ... },
--   buttons  = number of action slots that would change,
-- }
--
-- A spell is outdated when the highest rank of it on the bars is lower than the
-- highest rank in the spellbook. Only the slots holding that highest rank are
-- changed: lower ranks of the same spell are left alone (kept on purpose).
-- Macros count as "on the bars" but are never changed.
--------------------------------------------------------------------------------

function ns.Analyze(groups, onBars, ignored)
	ignored = ignored or {}
	local present, highest = {}, {}

	for _, entry in ipairs(onBars) do
		local key = entry.key
		if key and groups[key] then
			present[key] = true
			if not entry.isMacro and entry.rank then
				local h = highest[key]
				if not h or entry.rank > h.rank then
					highest[key] = { rank = entry.rank, text = entry.rankText, slots = { entry.slot } }
				elseif entry.rank == h.rank then
					table.insert(h.slots, entry.slot)
				end
			end
		end
	end

	local result = { outdated = {}, missing = {}, buttons = 0 }

	for key, h in pairs(highest) do
		local g = groups[key]
		if g.maxRank and h.rank < g.maxRank then
			table.sort(h.slots)
			table.insert(result.outdated, {
				key = key,
				name = g.name,
				fromRank = h.rank,
				fromText = h.text,
				toRank = g.maxRank,
				toText = g.maxRankText,
				spellID = g.maxSpellID,
				bookSlot = g.maxSlot,
				slots = h.slots,
			})
			result.buttons = result.buttons + #h.slots
		end
	end

	for key, g in pairs(groups) do
		if g.isClass and not present[key] and not ignored[key] then
			table.insert(result.missing, { key = key, name = g.name, spellID = g.maxSpellID or g.spellID })
		end
	end

	table.sort(result.outdated, ByName)
	table.sort(result.missing, ByName)
	return result
end
