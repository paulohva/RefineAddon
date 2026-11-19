--------------------------------------------------------------------------------
-- The ignored spells window: the class spells that aren't on any bar, each
-- with an "ignore" check box. Ticked spells are ignored: they don't count as
-- missing (no (i) on the button). Opened by right-clicking the spellbook button
-- or with /refine ignored, so it works even while the button is away.
--------------------------------------------------------------------------------

local _, ns = ...
local L = ns.L

local Window = {}
ns.IgnoreWindow = Window

local WIDTH, HEIGHT = 300, 420
local ROW_HEIGHT = 26
local ICON = "Interface\\AddOns\\Refine\\Media\\Icon"

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

local function InitRow(row, item)
	row.Name:SetText(item.name)
	row.Name:SetTextColor(item.ignored and 0.6 or 1, item.ignored and 0.6 or 1, item.ignored and 0.6 or 1)
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
	if frame.SetPortraitToAsset then pcall(frame.SetPortraitToAsset, frame, ICON) end

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

ns.Listen("CHANGED", function() ns.Debounce("ignoreWindow", 0.2, Window.Refresh) end)
