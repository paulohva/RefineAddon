--------------------------------------------------------------------------------
-- The ignored spells window: the class spells that aren't on any bar, each
-- with an "ignore" check box, its icon, and its tooltip on hover. Ticked spells are ignored: they don't count as
-- missing (no (i) on the button). Opened by right-clicking the spellbook button
-- or with /refine ignored, so it works even while the button is away.
--------------------------------------------------------------------------------

local _, ns = ...
local L = ns.L

local Window = {}
ns.IgnoreWindow = Window

local WIDTH, HEIGHT = 300, 420
local ROW_HEIGHT = 26
local PORTRAIT = "Interface\\AddOns\\Refine\\Media\\Portrait"   -- the logo drawn smaller: the portrait zooms in

local frame, scrollBox, emptyText

-- every class spell off the bars, ignored or not, by name
local function Items()
	local r = (not InCombatLockdown() and ns.Scan()) or ns.last
	if not r then return {} end
	local items, seen = {}, {}
	for _, m in ipairs(r.missing) do
		table.insert(items, { key = m.key, name = m.name, spellID = m.spellID, ignored = false })
		seen[m.key] = true
	end
	for _, ig in ipairs(ns.IgnoredList()) do
		if not seen[ig.key] then
			table.insert(items, { key = ig.key, name = ig.key, spellID = ig.spellID, ignored = true })
		end
	end
	table.sort(items, function(a, b) return a.name < b.name end)
	return items
end

function Window.Refresh()
	if not (frame and frame:IsShown()) then return end
	local items = Items()
	scrollBox:SetDataProvider(CreateDataProvider(items), ScrollBoxConstants and ScrollBoxConstants.RetainScrollPosition)
	emptyText:SetShown(#items == 0)
end

local function SpellIcon(spellID)
	if not spellID then return nil end
	if C_Spell and C_Spell.GetSpellTexture then return ns.Safe.Call(C_Spell.GetSpellTexture, spellID) end
	return ns.Safe.Call(GetSpellTexture, spellID)
end

-- the spell's own tooltip, to tell spells with similar names apart
local function ShowSpellTooltip(row)
	if not row.spellID then return end
	GameTooltip:SetOwner(row, "ANCHOR_RIGHT")
	if not pcall(GameTooltip.SetSpellByID, GameTooltip, row.spellID) then
		GameTooltip:SetText(row.Name:GetText() or "")
	end
	GameTooltip:Show()
end

local function InitRow(row, item)
	row.spellID = item.spellID
	row.Name:SetText(item.name)
	row.Name:SetTextColor(item.ignored and 0.6 or 1, item.ignored and 0.6 or 1, item.ignored and 0.6 or 1)
	row.Icon:SetTexture(SpellIcon(item.spellID) or "Interface\\Icons\\INV_Misc_QuestionMark")
	if row.Icon.SetDesaturated then row.Icon:SetDesaturated(item.ignored) end
	row:SetScript("OnEnter", ShowSpellTooltip)
	row:SetScript("OnLeave", function() GameTooltip:Hide() end)
	row.Check:SetChecked(item.ignored)
	row.Check:SetScript("OnClick", function(self)
		if self:GetChecked() then
			ns.Ignore(item.spellID)
		else
			ns.Unignore(item.key)
		end
		Window.Refresh()
	end)
end

local function Build()
	frame = CreateFrame("Frame", "RefineIgnoreFrame", UIParent, "ButtonFrameTemplate")
	frame:SetSize(WIDTH, HEIGHT)
	frame:SetFrameStrata("DIALOG")
	frame:SetToplevel(true)
	frame:SetClampedToScreen(true)
	frame:SetMovable(true)
	frame:EnableMouse(true)
	frame:RegisterForDrag("LeftButton")
	frame:SetScript("OnDragStart", frame.StartMoving)
	frame:SetScript("OnDragStop", function(self)
		self:StopMovingOrSizing()
		local point, _, relPoint, x, y = self:GetPoint(1)
		ns.db.ignoreWindowPosition = { point, relPoint, x, y }
	end)
	local pos = ns.db.ignoreWindowPosition
	if pos then
		frame:SetPoint(pos[1], UIParent, pos[2], pos[3], pos[4])
	else
		frame:SetPoint("CENTER", UIParent, "CENTER", 0, 40)
	end

	if frame.SetTitle then frame:SetTitle(ns.NAME)
	elseif frame.TitleText then frame.TitleText:SetText(ns.NAME) end
	if frame.SetPortraitToAsset then pcall(frame.SetPortraitToAsset, frame, PORTRAIT) end

	local help = frame:CreateFontString(nil, "ARTWORK", "GameFontNormal")
	help:SetPoint("TOPLEFT", frame, "TOPLEFT", 64, -32)
	help:SetPoint("RIGHT", frame, "RIGHT", -12, 0)
	help:SetJustifyH("LEFT")
	help:SetText(L["Spells not on your bars. Tick the ones to ignore."])

	local inset = frame.Inset or frame
	scrollBox = CreateFrame("Frame", nil, inset, "WowScrollBoxList")
	scrollBox:SetPoint("TOPLEFT", inset, "TOPLEFT", 4, -4)
	scrollBox:SetPoint("BOTTOMRIGHT", inset, "BOTTOMRIGHT", -20, 4)
	local scrollBar = CreateFrame("EventFrame", nil, inset, "MinimalScrollBar")
	scrollBar:SetPoint("TOPLEFT", scrollBox, "TOPRIGHT", 6, -2)
	scrollBar:SetPoint("BOTTOMLEFT", scrollBox, "BOTTOMRIGHT", 6, 2)

	local view = CreateScrollBoxListLinearView()
	view:SetElementExtent(ROW_HEIGHT)
	view:SetElementInitializer("RefineIgnoreRowTemplate", InitRow)
	ScrollUtil.InitScrollBoxListWithScrollBar(scrollBox, scrollBar, view)

	emptyText = inset:CreateFontString(nil, "ARTWORK", "GameFontDisable")
	emptyText:SetPoint("CENTER", inset, "CENTER", 0, 20)
	emptyText:SetWidth(WIDTH - 60)
	emptyText:SetText(L["All your class spells are on your bars."])

	frame:SetScript("OnShow", Window.Refresh)

	-- the template's close button uses HideUIPanel, protected in combat: hide directly
	local close = frame.CloseButton or _G["RefineIgnoreFrameCloseButton"]
	if close then close:SetScript("OnClick", function() frame:Hide() end) end

	tinsert(UISpecialFrames, "RefineIgnoreFrame")
	frame:Hide()
end

function Window.Toggle()
	if not ns.db then return end
	if not frame then Build() end
	frame:SetShown(not frame:IsShown())
end

-- opens it (stays open if it already is): /refine open
function Window.Show()
	if not ns.db then return end
	if not frame then Build() end
	frame:Show()
end

ns.Listen("CHANGED", function() ns.Debounce("ignoreWindow", 0.2, Window.Refresh) end)
