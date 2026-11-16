--[[
    ev0.wtf | Hub Loader
    ------------------------------------------------------------------
    One public loader. Detects the current game and loads the matching
    protected (LuaProtect) script for it.

    This is the ONLY link you share:
        loadstring(game:HttpGet("<your hub url>"))()

    Each GAME script is protected separately on luaprotect.dev and gets
    its own loadstring URL. You just paste that URL into GAMES below.
    Add a new supported game = add one line here. Nothing else changes.
]]

--------------------------------------------------------------------
-- KEY: the person running the hub pastes their LuaProtect key here
-- (the one from your key link). It carries through to every game
-- script the hub loads. If they set `script_key` globally before the
-- hub instead, that's respected too.
--------------------------------------------------------------------
local USER_KEY = ""   -- e.g. "ev0-XXXXXXXXXXXX"

if getgenv and getgenv().ev0_hub then
    return
end
if getgenv then getgenv().ev0_hub = true end

-- keep any key the user already set globally; otherwise use USER_KEY
if getgenv then
    getgenv().script_key = getgenv().script_key or (USER_KEY ~= "" and USER_KEY or nil)
end

--==================================================================
-- Game registry  ->  key by PlaceId (specific place) or GameId (whole
-- experience / all its places & VIP servers). PlaceId is checked first,
-- then GameId, so you can special-case one place inside an experience.
--==================================================================
local GAMES = {
    PlaceId = {
        -- [PlaceId] = "https://api.luaprotect.dev/.../your-script"
        [120219252362013] = "https://cdn.luaprotect.dev/u/954f3d/CwKIPOYEgCDqwvi1",   -- animal-garden tycoon (the one you built)
    },

    GameId = {
        -- [GameId] = "https://api.luaprotect.dev/.../your-script"
        -- (fallback that covers every place inside an experience)
    },
}

--==================================================================
-- Loader
--==================================================================
local function toast(msg)
    pcall(function()
        game.StarterGui:SetCore("SendNotification", { Title = "ev0.wtf", Text = msg, Duration = 6 })
    end)
    warn("[ev0.wtf] " .. msg)
end

-- An entry may be a plain URL string, or { url = "...", key = "..." } when
-- a game lives in a separate LuaProtect project with its own key.
local function run(entry)
    local url, key = entry, nil
    if type(entry) == "table" then url, key = entry.url, entry.key end
    if key and getgenv then
        getgenv().script_key = key            -- per-game key overrides the global
    end
    local okFetch, src = pcall(function() return game:HttpGet(url) end)
    if not okFetch or type(src) ~= "string" or #src == 0 then
        return false, "download failed"
    end
    local fn, compileErr = loadstring(src)
    if not fn then
        return false, "compile error: " .. tostring(compileErr)
    end
    local okRun, runErr = pcall(fn)
    if not okRun then
        return false, "runtime error: " .. tostring(runErr)
    end
    return true
end

local function usable(entry)
    local url = type(entry) == "table" and entry.url or entry
    return type(url) == "string" and url ~= "" and not url:find("PASTE_")
end

local function resolve()
    local byPlace = GAMES.PlaceId[game.PlaceId]
    if usable(byPlace) then return byPlace end
    local byGame = GAMES.GameId[game.GameId]
    if usable(byGame) then return byGame end
    return nil
end

--==================================================================
-- Go
--==================================================================
local entry = resolve()
if not entry then
    toast("This game isn't supported yet. (PlaceId " .. tostring(game.PlaceId) .. ")")
    return
end

local ok, err = run(entry)
if ok then
    toast("Loaded script for this game.")
else
    if getgenv then getgenv().ev0_hub = nil end   -- allow a retry after a failed load
    toast("Failed to load: " .. tostring(err))
end
