--------------------------------------------------------------------------------
-- The button in the spellbook: green when every spell on the bars is at its
-- highest rank, orange (with a count) when some can be updated. Its tooltip
-- lists what will change and the class spells that aren't on any bar; the
-- right-click menu ignores those.
--
-- It is our own frame, parented to the spellbook and anchored to it; nothing of
-- Blizzard's spellbook code or frames is hooked or changed.
--------------------------------------------------------------------------------

local _, ns = ...
local L = ns.L

local Button = {}
ns.Button = Button

local COLOR_OK = { 0.25, 1, 0.25 }
local COLOR_TODO = { 1, 0.55, 0.1 }
local ICON_OK = "Interface\\RaidFrame\\ReadyCheck-Ready"
local ICON_TODO = "Interface\\DialogFrame\\UI-Dialog-Icon-AlertNew"
local ICON_SIZE = 16
local HEIGHT = 24
local PADDING = 22          -- room around the icon and the text
local OFFSET_X, OFFSET_Y = 70, 38   -- from the spellbook's bottom left corner
local MENU_HEIGHT = 400     -- the right-click menu scrolls past this
local MAX_LISTED = 15       -- spells listed in the tooltip

local button, fontOK, fontTodo

local function MakeFont(name, color)
	local font = CreateFont(name)
	font:CopyFontObject(GameFontNormal)
	font:SetTextColor(color[1], color[2], color[3])
	return font
end

--------------------------------------------------------------------------------
-- Tooltip
--------------------------------------------------------------------------------

local function ShowTooltip(self)
	local r = ns.last
	GameTooltip:SetOwner(self, "ANCHOR_TOP")
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
-- State
--------------------------------------------------------------------------------

local function SetLook(text, font, icon)
	button:SetNormalFontObject(font)
	button:SetHighlightFontObject(font)
	button:SetText(text)
	button.Icon:SetTexture(icon)
	button:SetWidth(button:GetFontString():GetStringWidth() + ICON_SIZE + PADDING * 2)
end

function Button.Refresh()
	if not button or not ns.db then return end
	if InCombatLockdown() then
		button:Disable()
	else
		button:Enable()
		local r = ns.Scan()
		local n = r and #r.outdated or 0
		if n > 0 then
			SetLook(L["Update bars (%d)"]:format(n), fontTodo, ICON_TODO)
		else
			SetLook(L["Bars up to date"], fontOK, ICON_OK)
		end
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

local function Attach()
	if button then return end
	local parent = PlayerSpellsFrame and PlayerSpellsFrame.SpellBookFrame
	if not parent then
		ns.Debug("PlayerSpellsFrame.SpellBookFrame not found; no spellbook button")
		return
	end

	fontOK = MakeFont("SpellbookRefreshFontOK", COLOR_OK)
	fontTodo = MakeFont("SpellbookRefreshFontTodo", COLOR_TODO)

	button = CreateFrame("Button", "SpellbookRefreshButton", parent, "UIPanelButtonTemplate")
	button:SetSize(180, HEIGHT)
	button:SetPoint("BOTTOMLEFT", parent, "BOTTOMLEFT", OFFSET_X, OFFSET_Y)
	button:SetFrameLevel(parent:GetFrameLevel() + 50)
	button:SetMotionScriptsWhileDisabled(true)
	button:RegisterForClicks("LeftButtonUp", "RightButtonUp")

	local icon = button:CreateTexture(nil, "OVERLAY")
	icon:SetSize(ICON_SIZE, ICON_SIZE)
	icon:SetPoint("LEFT", button, "LEFT", PADDING - 6, 0)
	button.Icon = icon

	local text = button:GetFontString()
	text:ClearAllPoints()
	text:SetPoint("LEFT", icon, "RIGHT", 4, 0)

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
	button:SetScript("OnShow", Button.Refresh)

	Button.frame = button
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
