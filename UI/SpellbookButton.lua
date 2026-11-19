--------------------------------------------------------------------------------
-- The Refine button: a small square button in the spellbook, on the line of
-- the category title ("General", "Frost"...), its right edge lined up with the
-- page arrows at the bottom. It shows a golden check mark when every
-- spell on the bars is at its highest rank (nothing to do), and an orange
-- refresh symbol with a count when some can be updated. A small (i)
-- in the corner shows while class spells aren't on any bar (and aren't
-- ignored). The tooltip lists both; the right-click menu ignores spells.
--
-- It is our own frame, parented to the spellbook and anchored to it; nothing of
-- Blizzard's spellbook code or frames is hooked or changed (their positions are
-- only read, to line the button up with the title).
--------------------------------------------------------------------------------

local _, ns = ...
local L = ns.L

local Button = {}
ns.Button = Button

local SIZE = 40
local ICON_SIZE = 24
local CHECK_SIZE = 21
local CHECK_FILE_SIZE = 29  -- the fallback check texture has some empty space around it
local ICON_CHECK_ATLAS = "common-icon-checkmark-yellow"     -- a large, clean golden check
local ICON_ATLAS = "UI-RefreshButton"
local ICON_FILE = "Interface\\Buttons\\UI-RefreshButton"
local ICON_CHECK = "Interface\\Buttons\\UI-CheckBox-Check"   -- fallback: the check of the game's check boxes
local ICON_INFO = "Interface\\FriendsFrame\\InformationIcon"
local INFO_SIZE = 13
local COLOR_OK = { 0.35, 1, 0.35 }         -- tooltip text: everything up to date
local COLOR_PLAIN = { 1, 1, 1 }            -- nothing to do: the check as the game draws it
local COLOR_TODO = { 1, 0.6, 0.15 }        -- orange: something to update
local COLOR_COMBAT = { 0.45, 0.45, 0.45 }  -- greyed out in combat
local TITLE_SLACK = 40      -- the category title is the first thing on the left page
local FALLBACK_X, FALLBACK_Y = -60, -12   -- from the left page's top right, when the title can't be measured
local MENU_HEIGHT = 400     -- the right-click menu scrolls past this
local MAX_LISTED = 15       -- spells listed in the tooltip

local button
local titleOffset           -- { x, y } of the title line's right end, from the left page's top left

--------------------------------------------------------------------------------
-- Tooltip
--------------------------------------------------------------------------------

local function ShowTooltip(self)
	local r = ns.last
	GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
	GameTooltip:SetText(ns.NAME, 1, 1, 1)

	if InCombatLockdown() then
		GameTooltip:AddLine(L["You can't change your action bars in combat."], 1, 0.2, 0.2, true)
	end

	if r then
		if #r.outdated > 0 then
			GameTooltip:AddLine(" ")
			GameTooltip:AddLine(L["To update:"])
			for _, o in ipairs(r.outdated) do
				local change = ("%s » %s"):format(o.fromText or o.fromRank, o.toText or o.toRank)
				if #o.slots > 1 then
					change = change .. " " .. L["(%d buttons)"]:format(#o.slots)
				end
				GameTooltip:AddDoubleLine(o.name, change, 1, 1, 1, COLOR_TODO[1], COLOR_TODO[2], COLOR_TODO[3])
			end
		else
			GameTooltip:AddLine(L["Every spell on your bars is at its highest rank."],
				COLOR_OK[1], COLOR_OK[2], COLOR_OK[3], true)
		end

		if #r.missing > 0 then
			GameTooltip:AddLine(" ")
			GameTooltip:AddLine(L["Not on your bars:"])
			for i = 1, math.min(#r.missing, MAX_LISTED) do
				GameTooltip:AddLine(r.missing[i].name, 0.85, 0.85, 0.85)
			end
			if #r.missing > MAX_LISTED then
				GameTooltip:AddLine(L["and %d more"]:format(#r.missing - MAX_LISTED), 0.6, 0.6, 0.6)
			end
		end
	end

	GameTooltip:AddLine(" ")
	if r and #r.outdated > 0 then
		GameTooltip:AddLine(L["Click: update your bars"], 0.5, 0.5, 0.5)
	end
	GameTooltip:AddLine(L["Right-click: ignore spells that aren't on your bars"], 0.5, 0.5, 0.5)
	GameTooltip:Show()
end

--------------------------------------------------------------------------------
-- Right-click menu: ignore / stop ignoring
--------------------------------------------------------------------------------

local function OpenMenu(self)
	if not (MenuUtil and MenuUtil.CreateContextMenu) then return end
	local r = ns.last or ns.Scan()
	if not r then return end
	MenuUtil.CreateContextMenu(self, function(_, root)
		if root.SetScrollMode then pcall(root.SetScrollMode, root, MENU_HEIGHT) end
		root:CreateTitle(L["Ignore a spell that isn't on your bars:"])
		if #r.missing == 0 then
			root:CreateTitle(L["(none)"])
		end
		for _, m in ipairs(r.missing) do
			root:CreateButton(m.name, function() ns.Ignore(m.spellID) end)
		end

		local ignored = ns.IgnoredList()
		if #ignored > 0 then
			root:CreateDivider()
			local sub = root:CreateButton(L["Ignored spells (%d)"]:format(#ignored))
			sub:CreateTitle(L["Click to list it again:"])
			for _, ig in ipairs(ignored) do
				sub:CreateButton(ig.key, function() ns.Unignore(ig.key) end)
			end
		end
	end)
end

--------------------------------------------------------------------------------
-- Position: on the category title's line, at the right end of its divider
--------------------------------------------------------------------------------

local function Get(frame, method)
	if type(frame) ~= "table" or type(frame[method]) ~= "function" then return nil end
	local ok, a, b = pcall(frame[method], frame)
	if not ok then return nil end
	return a, b
end

-- the category title (header) at the top of the left page, if it's showing
local function FindTitle(view)
	local ok, children = pcall(function() return { view:GetChildren() } end)
	if not ok then return nil end
	local best, bestTop
	for _, child in ipairs(children) do
		if type(child.Text) == "table" and type(child.Border) == "table" and Get(child, "IsShown") then
			local top = Get(child, "GetTop")
			if top and (not bestTop or top > bestTop) then best, bestTop = child, top end
		end
	end
	return best, bestTop
end

-- height: the category title's line; right edge: the "next page" arrow at the
-- bottom right (Page 1/1 < >), or the end of the title's divider without it
local function MeasureTitle(view, pager)
	local viewTop, viewLeft = Get(view, "GetTop"), Get(view, "GetLeft")
	local title, top = FindTitle(view)
	if not (title and top and viewTop and viewLeft) or viewTop - top > TITLE_SLACK then return end
	local _, centerY = Get(title.Text, "GetCenter")
	local right = pager and Get(pager.NextPageButton or pager, "GetRight") or Get(title.Border, "GetRight")
	if right and centerY then
		titleOffset = { right - viewLeft, centerY - viewTop }
		ns.Debug("button lined up with the category title and the page arrows (%.0f, %.0f)", titleOffset[1], titleOffset[2])
	end
end

local function Align()
	if not button then return end
	local parent = button:GetParent()
	local paged = parent.PagedSpellsFrame
	local view = paged and paged.View1
	if not view then return end
	if not titleOffset then MeasureTitle(view, paged.PagingControls) end
	button:ClearAllPoints()
	if titleOffset then
		button:SetPoint("RIGHT", view, "TOPLEFT", titleOffset[1], titleOffset[2])
	else
		button:SetPoint("RIGHT", view, "TOPRIGHT", FALLBACK_X, FALLBACK_Y)
	end
end

--------------------------------------------------------------------------------
-- State
--------------------------------------------------------------------------------

local function Tint(color, desaturated)
	if button.Icon.SetDesaturated then button.Icon:SetDesaturated(desaturated and true or false) end
	button.Icon:SetVertexColor(color[1], color[2], color[3])
end

-- "check": nothing to do; "refresh": something to update
local function ShowSymbol(which)
	if button.symbol == which then return end
	button.symbol = which
	local icon = button.Icon
	if which == "check" then
		local hasAtlas = not (C_Texture and C_Texture.GetAtlasInfo) or C_Texture.GetAtlasInfo(ICON_CHECK_ATLAS) ~= nil
		if hasAtlas and pcall(icon.SetAtlas, icon, ICON_CHECK_ATLAS) then
			icon:SetSize(CHECK_SIZE, CHECK_SIZE)
		else
			icon:SetTexture(ICON_CHECK)
			icon:SetSize(CHECK_FILE_SIZE, CHECK_FILE_SIZE)
		end
	else
		if not pcall(icon.SetAtlas, icon, ICON_ATLAS) then icon:SetTexture(ICON_FILE) end
		icon:SetSize(ICON_SIZE, ICON_SIZE)
	end
end

function Button.Refresh()
	if not button or not ns.db then return end
	if InCombatLockdown() then
		button:Disable()
		Tint(COLOR_COMBAT, true)
	else
		button:Enable()
		local r = ns.Scan()
		local n = r and #r.outdated or 0
		if n > 0 then
			ShowSymbol("refresh")
			Tint(COLOR_TODO, false)
		else
			ShowSymbol("check")
			Tint(COLOR_PLAIN, false)
		end
		button.Count:SetText(n > 0 and tostring(n) or "")
		button.Info:SetShown(r and #r.missing > 0 or false)
	end
	if GameTooltip:IsOwned(button) then ShowTooltip(button) end
end

local function Queue()
	if button and button:IsVisible() then
		ns.Debounce("button", 0.2, Button.Refresh)
	end
end

--------------------------------------------------------------------------------
-- Creation, once the spellbook (load-on-demand) is loaded
--------------------------------------------------------------------------------

-- Blizzard's square refresh button, or a plain square with the same symbol
local function MakeButton(parent, name)
	local ok, b = pcall(CreateFrame, "Button", name, parent, "RefreshButtonTemplate")
	if ok and b and type(b.Icon) == "table" then return b end
	if ok and b then b:Hide() end

	b = CreateFrame("Button", name and (name .. "Plain"), parent)
	local bg = b:CreateTexture(nil, "BACKGROUND")
	bg:SetAllPoints()
	bg:SetColorTexture(0, 0, 0, 0.45)
	local icon = b:CreateTexture(nil, "ARTWORK")
	icon:SetPoint("CENTER")
	icon:SetSize(ICON_SIZE, ICON_SIZE)
	if not pcall(icon.SetAtlas, icon, ICON_ATLAS) then icon:SetTexture(ICON_FILE) end
	b.Icon = icon
	b:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square", "ADD")
	return b
end

local function Attach()
	if button then return end
	local parent = PlayerSpellsFrame and PlayerSpellsFrame.SpellBookFrame
	if not parent then
		ns.Debug("PlayerSpellsFrame.SpellBookFrame not found; no spellbook button")
		return
	end

	button = MakeButton(parent, "RefineButton")
	button:SetSize(SIZE, SIZE)
	button.Icon:SetSize(ICON_SIZE, ICON_SIZE)
	button:SetFrameLevel(parent:GetFrameLevel() + 50)
	button:SetMotionScriptsWhileDisabled(true)
	button:RegisterForClicks("LeftButtonUp", "RightButtonUp")

	-- how many spells can be updated, in the corner like an action button's count
	local count = button:CreateFontString(nil, "OVERLAY", "NumberFontNormal")
	count:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", -1, 2)
	button.Count = count

	-- (i): some class spells aren't on any bar (see the tooltip)
	local info = button:CreateTexture(nil, "OVERLAY")
	info:SetSize(INFO_SIZE, INFO_SIZE)
	info:SetPoint("CENTER", button, "TOPRIGHT", -2, -2)
	info:SetTexture(ICON_INFO)
	info:Hide()
	button.Info = info

	button:SetScript("OnClick", function(self, mouse)
		if mouse == "RightButton" then
			OpenMenu(self)
			return
		end
		ns.UpdateBars()
		Button.Refresh()
	end)
	button:SetScript("OnEnter", ShowTooltip)
	button:SetScript("OnLeave", function() GameTooltip:Hide() end)
	button:SetScript("OnShow", function()
		Align()
		Button.Refresh()
		-- the pages fill in as the spellbook opens: measure the title again next frame
		C_Timer.After(0, Align)
	end)

	Button.frame = button
	Align()
	Button.Refresh()
	ns.Debug("spellbook button attached")
end

if EventUtil and EventUtil.ContinueOnAddOnLoaded then
	EventUtil.ContinueOnAddOnLoaded("Blizzard_PlayerSpells", Attach)
else
	ns.On("ADDON_LOADED", function(name)
		if name == "Blizzard_PlayerSpells" then Attach() end
	end)
end

for _, event in ipairs({
	"SPELLS_CHANGED", "LEARNED_SPELL_IN_SKILL_LINE", "ACTIONBAR_SLOT_CHANGED", "UPDATE_MACROS",
	"PLAYER_REGEN_DISABLED", "PLAYER_REGEN_ENABLED",
}) do
	ns.On(event, Queue)
end
ns.Listen("CHANGED", Queue)
