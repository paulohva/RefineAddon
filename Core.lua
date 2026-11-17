--------------------------------------------------------------------------------
-- SpellbookRefresh: core (namespace, secret-safe helpers, events, saved data)
--------------------------------------------------------------------------------

local ADDON, ns = ...

ns.NAME = "SpellbookRefresh"
ns.ACCENT = "ffd100"   -- Blizzard gold

local DB_VERSION = 1

--------------------------------------------------------------------------------
-- Printing
--------------------------------------------------------------------------------

function ns.Print(fmt, ...)
	local msg = select("#", ...) > 0 and fmt:format(...) or tostring(fmt)
	DEFAULT_CHAT_FRAME:AddMessage("|cff" .. ns.ACCENT .. ns.NAME .. "|r: " .. msg)
end

function ns.Debug(fmt, ...)
	if not (ns.db and ns.db.debug) then return end
	local msg = select("#", ...) > 0 and fmt:format(...) or tostring(fmt)
	DEFAULT_CHAT_FRAME:AddMessage("|cff888888[SBR]|r " .. msg)
end

-- a short red line at the top of the screen (not in the chat)
function ns.ScreenError(msg)
	if not UIErrorsFrame then return end
	if UIErrorsFrame.AddExternalErrorMessage then
		UIErrorsFrame:AddExternalErrorMessage(msg)
	else
		UIErrorsFrame:AddMessage(msg, 1, 0.1, 0.1)
	end
end

--------------------------------------------------------------------------------
-- Secret-safe reads (Forever runs Midnight's addon restrictions: some values
-- are "secret" and can't be compared or stored; treat those as unknown)
--------------------------------------------------------------------------------

local Safe = {}
ns.Safe = Safe

function Safe.Value(v)
	if issecretvalue and issecretvalue(v) then return nil end
	return v
end

-- calls fn(...) and returns its first result when plain, else nil
function Safe.Call(fn, ...)
	if type(fn) ~= "function" then return nil end
	local ok, v = pcall(fn, ...)
	if not ok then return nil end
	return Safe.Value(v)
end

local function SafeResults(ok, ...)
	if not ok then return end
	local n = select("#", ...)
	local out = { ... }
	for i = 1, n do out[i] = Safe.Value(out[i]) end
	return unpack(out, 1, n)
end

-- calls fn(...) and returns all its results (each made safe), or nothing on error
function Safe.CallAll(fn, ...)
	if type(fn) ~= "function" then return end
	return SafeResults(pcall(fn, ...))
end

-- a table field read that survives secret tables / values
function Safe.Field(t, key)
	if type(t) ~= "table" then return nil end
	local ok, v = pcall(function() return t[key] end)
	if not ok then return nil end
	return Safe.Value(v)
end

--------------------------------------------------------------------------------
-- Events: any number of handlers per event. Events this client doesn't know
-- are skipped instead of raising an error.
--------------------------------------------------------------------------------

local eventFrame = CreateFrame("Frame")
local handlers = {}

function ns.IsEventValid(event)
	if C_EventUtils and C_EventUtils.IsEventValid then
		return C_EventUtils.IsEventValid(event) and true or false
	end
	return true
end

function ns.On(event, fn)
	if not handlers[event] then
		if not ns.IsEventValid(event) or not pcall(eventFrame.RegisterEvent, eventFrame, event) then
			return false
		end
		handlers[event] = {}
	end
	table.insert(handlers[event], fn)
	return true
end

eventFrame:SetScript("OnEvent", function(_, event, ...)
	for _, fn in ipairs(handlers[event]) do
		local ok, err = pcall(fn, ...)
		if not ok then geterrorhandler()(err) end
	end
end)

-- internal callbacks (ns.Fire("CHANGED") etc.)
local callbacks = {}

function ns.Listen(name, fn)
	callbacks[name] = callbacks[name] or {}
	table.insert(callbacks[name], fn)
end

function ns.Fire(name, ...)
	for _, fn in ipairs(callbacks[name] or {}) do
		local ok, err = pcall(fn, ...)
		if not ok then geterrorhandler()(err) end
	end
end

-- runs fn once, `delay` seconds from now; later calls with the same key while
-- one is pending are dropped (coalesces bursts of ACTIONBAR_SLOT_CHANGED etc.)
local pending = {}
function ns.Debounce(key, delay, fn)
	if pending[key] then return end
	pending[key] = true
	C_Timer.After(delay, function()
		pending[key] = nil
		local ok, err = pcall(fn)
		if not ok then geterrorhandler()(err) end
	end)
end

--------------------------------------------------------------------------------
-- Saved data
--   SpellbookRefreshDB = {
--     version,
--     debug,
--     trainerNote,                                  -- chat line after the trainer
--     chars = { [name] = { ignored = { [spellID] = true } } },
--   }
-- Ignored spells are kept by spell ID and matched by the spell's current name,
-- so they survive a change of the game's language.
--------------------------------------------------------------------------------

function ns.CharKey()
	return Safe.Call(UnitName, "player") or "?"
end

local function InitDB()
	local db = SpellbookRefreshDB
	if type(db) ~= "table" then db = {} end
	db.version = DB_VERSION
	if db.trainerNote == nil then db.trainerNote = true end
	db.chars = db.chars or {}
	SpellbookRefreshDB = db
	ns.db = db
end

function ns.Char()
	local key = ns.CharKey()
	local c = ns.db.chars[key]
	if not c then
		c = {}
		ns.db.chars[key] = c
	end
	c.ignored = c.ignored or {}
	return c
end

local readyFns = {}
function ns.OnReady(fn) table.insert(readyFns, fn) end

ns.On("ADDON_LOADED", function(name)
	if name ~= ADDON then return end
	InitDB()
end)

ns.On("PLAYER_LOGIN", function()
	if not ns.db then InitDB() end
	for _, fn in ipairs(readyFns) do
		local ok, err = pcall(fn)
		if not ok then geterrorhandler()(err) end
	end
end)
