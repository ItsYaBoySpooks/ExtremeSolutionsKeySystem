--[[
    Extreme Solutions — Key System Integration
    Drop this into your script hub to handle key validation.
    
    Replace API_URL with your Railway URL.
]]

local HttpService = game:GetService("HttpService")

local KeySystem = {}

-- ═══════════════════════════════════════════
-- CONFIG — Update this with your Railway URL
-- ═══════════════════════════════════════════
local API_URL = "https://extremesolutionskeysystem-production.up.railway.app"

-- ═══════════════════════════════════════════
-- Get a unique hardware ID for HWID locking
-- ═══════════════════════════════════════════
function KeySystem.GetHWID()
    local hwid = nil

    -- Try common executor HWID methods
    local success, result = pcall(function()
        return game:GetService("RbxAnalyticsService"):GetClientId()
    end)
    if success and result then
        hwid = result
    end

    -- Fallback: some executors provide their own HWID function
    if not hwid then
        local s, r = pcall(function()
            if gethwid then return gethwid() end
            if getexecutorname then return getexecutorname() .. "_" .. game.Players.LocalPlayer.UserId end
        end)
        if s and r then hwid = r end
    end

    -- Last resort fallback
    if not hwid then
        hwid = "PLAYER_" .. tostring(game.Players.LocalPlayer.UserId)
    end

    return hwid
end

-- ═══════════════════════════════════════════
-- Validate a key against the API
-- Returns: { success: bool, message: string, tier: string?, expires_at: string? }
-- ═══════════════════════════════════════════
function KeySystem.Validate(key)
    local url = API_URL .. "/api/validate"
    local hwid = KeySystem.GetHWID()

    local payload = HttpService:JSONEncode({
        key = key,
        hwid = hwid
    })

    local success, response = pcall(function()
        return request({
            Url = url,
            Method = "POST",
            Headers = {
                ["Content-Type"] = "application/json"
            },
            Body = payload
        })
    end)

    -- If the HTTP request itself failed
    if not success then
        return {
            success = false,
            message = "Failed to connect to key server. Check your internet."
        }
    end

    -- Parse the JSON response
    local ok, data = pcall(function()
        return HttpService:JSONDecode(response.Body)
    end)

    if not ok or not data then
        return {
            success = false,
            message = "Invalid response from key server."
        }
    end

    return data
end

-- ═══════════════════════════════════════════
-- Reset HWID for a key
-- ═══════════════════════════════════════════
function KeySystem.ResetHWID(key)
    local url = API_URL .. "/api/reset-hwid"

    local payload = HttpService:JSONEncode({
        key = key
    })

    local success, response = pcall(function()
        return request({
            Url = url,
            Method = "POST",
            Headers = {
                ["Content-Type"] = "application/json"
            },
            Body = payload
        })
    end)

    if not success then
        return { success = false, message = "Failed to connect." }
    end

    local ok, data = pcall(function()
        return HttpService:JSONDecode(response.Body)
    end)

    if not ok then
        return { success = false, message = "Invalid response." }
    end

    return data
end

-- ═══════════════════════════════════════════
-- Save/Load key locally so user doesn't re-enter every time
-- Uses executor filesystem (writefile/readfile)
-- ═══════════════════════════════════════════
local KEY_FILE = "extreme_solutions_key.txt"

function KeySystem.SaveKey(key)
    pcall(function()
        writefile(KEY_FILE, key)
    end)
end

function KeySystem.LoadSavedKey()
    local success, content = pcall(function()
        if isfile(KEY_FILE) then
            return readfile(KEY_FILE)
        end
        return nil
    end)

    if success and content and content ~= "" then
        return content
    end
    return nil
end

function KeySystem.ClearSavedKey()
    pcall(function()
        if isfile(KEY_FILE) then
            delfile(KEY_FILE)
        end
    end)
end

return KeySystem
