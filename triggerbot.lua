--=============================================================
--// TRIGGERBOT MODULE (Standalone)
--=============================================================

--// CONFIG TABLE (reads from shared.Rooze, falls back to defaults)
local sharedCfg = shared.Rooze or {}
local cfg       = sharedCfg['Trigger Bot'] or {}
local settings  = sharedCfg['Settings'] or {}
local kb        = (sharedCfg['Keybinds'] or {})['Trigger Bot'] or {}
local weapons   = cfg['Specific Weapons'] or {}

local CONFIG = {
    Enabled             = cfg['Enabled'] == true,
    Delay               = cfg['Delay'] or 0.05,
    Mode                = kb['Mode'] or "Hold",
    Key                 = kb['Key'] or "T",
    TeamCheck           = settings['Team Check'] ~= false,
    IgnoreKnocked       = settings['Knock Check'] ~= false,
    VisibleCheck        = settings['Visible Check'] == true,
    WeaponFilterEnabled = weapons['Enabled'] == true,
    WeaponWhitelist     = weapons['Weapons'] or {},
}

--=============================================================
--// SERVICES
--=============================================================

local Players           = game:GetService("Players")
local RunService        = game:GetService("RunService")
local UserInputService  = game:GetService("UserInputService")
local Workspace         = game:GetService("Workspace")
local Camera            = Workspace.CurrentCamera

local player = Players.LocalPlayer

--=============================================================
--// TRIGGERBOT
--=============================================================

local Trigger = (function()
    local state = CONFIG
    local lastClick = 0
    local lastFoundAt = 0
    local holdingKey = false

    local function isKnocked(plr)
        if not state.IgnoreKnocked then return false end
        local char = plr.Character
        if not char then return false end
        local be = char:FindFirstChild("BodyEffects")
        if be then
            local ko = be:FindFirstChild("K.O")
            if ko and ko.Value then return true end
            local k = be:FindFirstChild("Knocked")
            if k and k.Value then return true end
        end
        return false
    end

    local function isTeammate(plr)
        if not state.TeamCheck then return false end
        if plr.Team and player.Team then return plr.Team == player.Team end
        return false
    end

    local function hasWeaponEquipped()
        local char = player.Character
        if not char then return nil end
        local tool = char:FindFirstChildOfClass("Tool")
        if not tool then return nil end
        if state.WeaponFilterEnabled then
            local allowed = false
            for _, wName in ipairs(state.WeaponWhitelist) do
                if tool.Name == wName then allowed = true break end
            end
            if not allowed then return nil end
        end
        return tool
    end

    local function raycastVisible(targetChar, part)
        if not state.VisibleCheck then return true end
        local origin = Camera.CFrame.Position
        local dir = (part.Position - origin)
        local params = RaycastParams.new()
        params.FilterDescendantsInstances = { player.Character, targetChar }
        params.FilterType = Enum.RaycastFilterType.Exclude
        params.IgnoreWater = true
        local res = Workspace:Raycast(origin, dir, params)
        if res == nil then return true end
        return res.Instance:IsDescendantOf(targetChar)
    end

    local function isCrosshairOnTarget()
        local mousePos = UserInputService:GetMouseLocation()
        local ray = Camera:ViewportPointToRay(mousePos.X, mousePos.Y)
        local params = RaycastParams.new()
        params.FilterDescendantsInstances = { player.Character }
        params.FilterType = Enum.RaycastFilterType.Exclude
        params.IgnoreWater = true
        local res = Workspace:Raycast(ray.Origin, ray.Direction * 99999, params)
        if not res or not res.Instance then return nil, nil end

        local model = res.Instance:FindFirstAncestorOfClass("Model")
        if not model then return nil, nil end

        local plr = Players:GetPlayerFromCharacter(model)
        if not plr or plr == player then return nil, nil end
        if isTeammate(plr) then return nil, nil end
        if isKnocked(plr) then return nil, nil end
        if not raycastVisible(model, res.Instance) then return nil, nil end

        return plr, res.Instance
    end

    RunService.Heartbeat:Connect(function()
        if not state.Enabled then return end
        if state.Mode == "Hold" and not holdingKey then
            lastFoundAt = 0
            return
        end

        local plr, part = isCrosshairOnTarget()
        if not plr or not part then
            lastFoundAt = 0
            return
        end

        local now = tick()
        if lastFoundAt == 0 then
            lastFoundAt = now
            return
        end
        if now - lastFoundAt < state.Delay then return end
        if now - lastClick < math.max(state.Delay, 0.01) then return end

        local tool = hasWeaponEquipped()
        if not tool then return end

        pcall(function() tool:Activate() end)
        lastClick = now
    end)

    UserInputService.InputBegan:Connect(function(input, gp)
        if gp then return end
        if input.KeyCode == Enum.KeyCode[state.Key] then
            if state.Mode == "Toggle" then state.Enabled = not state.Enabled
            elseif state.Mode == "Hold" then holdingKey = true end
        end
    end)
    UserInputService.InputEnded:Connect(function(input, gp)
        if gp then return end
        if input.KeyCode == Enum.KeyCode[state.Key] then
            if state.Mode == "Hold" then holdingKey = false end
        end
    end)

    local api = {}
    function api.setEnabled(v) state.Enabled = v end
    function api.setDelay(v) state.Delay = v end
    function api.setMode(v) state.Mode = v end
    function api.setKey(v) state.Key = v end
    function api.setTeamCheck(v) state.TeamCheck = v end
    function api.setIgnoreKnocked(v) state.IgnoreKnocked = v end
    function api.setVisibleCheck(v) state.VisibleCheck = v end
    function api.setWeaponFilter(v) state.WeaponFilterEnabled = v end
    function api.setWeaponWhitelist(t) state.WeaponWhitelist = t end
    return api
end)()

return Trigger
