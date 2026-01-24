--[[
    damage.lua (FIXED)
    
    KopisLocal.lua:
        ePlaySound  = combatEvents.PlaySound   -- Client fires this for DAMAGE
        eDealDamage = combatEvents.DealDamage  -- Client fires this for SOUND
    
    CombatDamageServer.lua:
        eDealDamage = combatEvents.PlaySound   -- Server listens for DAMAGE here
        ePlaySound  = combatEvents.DealDamage  -- Server listens for SOUND here
    
    So: PlaySound remote = DAMAGE, DealDamage remote = SOUND
    
    KopisLocal.lua line 98: ePlaySound:FireServer(hitHumanoid) -- deals damage
    KopisLocal.lua line 92: eDealDamage:FireServer(2) -- plays shield block sound
--]]

local lastHit = os.clock()
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

local kopis = {
    authorizedHit = true,
    teamKill = false,
}

local swingSpeeds = {
    swingSpeeds = nil,
    kopis = nil,

    default = {
        1.5;
        1;
        1.25;
        1.25;
        1;
    },

    cooldown = .55
}

function kopis.setDamageCooldown(cooldown)
    swingSpeeds.cooldown = cooldown
end

function kopis.getDefaultSwingSpeeds()
    return swingSpeeds.default
end

function kopis.getKopis(searchBackpack)
    local client = gg.client
    if not client then return nil end
    
    -- First check character (equipped kopis)
    local character = client.Character
    if character then
        local kopisTool = character:FindFirstChild("Kopis")
        if kopisTool then
            return kopisTool
        end
    end
    
    -- If searchBackpack, also check backpack
    if searchBackpack then
        local backpack = client:FindFirstChild("Backpack")
        if backpack then
            local kopisTool = backpack:FindFirstChild("Kopis")
            if kopisTool then
                return kopisTool
            end
        end
    end
    
    return nil
end

-- Get the tip of the kopis blade
-- Path from KopisLocal.lua line 27: toolModel:WaitForChild("Blade"):WaitForChild("Tip")
function kopis.getTip(kopisTool)
    if not kopisTool then
        kopisTool = kopis.getKopis() or kopis.getKopis(true)
    end
    if not kopisTool then
        return nil
    end
    
    -- Path: Kopis > ToolModel > Blade > Tip (from KopisLocal.lua)
    local toolModel = kopisTool:FindFirstChild("ToolModel")
    if toolModel then
        local blade = toolModel:FindFirstChild("Blade")
        if blade then
            local tip = blade:FindFirstChild("Tip")
            if tip then
                return tip
            end
        end
    end
    
    -- Fallback: recursive search
    local tip = kopisTool:FindFirstChild("Tip", true)
    return tip
end

-- Get the blade (parent of tip)
function kopis.getBlade(kopisTool)
    local tip = kopis.getTip(kopisTool)
    if tip then
        return tip.Parent
    end
    return nil
end

function kopis.getSwingSpeed()
    local kopisTool = kopis.getKopis() or kopis.getKopis(true)
    if not kopisTool then
        return swingSpeeds.default
    end
    if kopisTool == swingSpeeds.kopis then
        return swingSpeeds.swingSpeeds
    end
    if not getgc then
        return swingSpeeds.default
    end
    
    -- Search for trackSpeeds table in game's memory
    -- From KopisLocal.lua: trackSpeeds = {1.5, 1, 1.25, 1.25, 1}
    for _,v in pairs(getgc()) do
        if type(v) == "function" then
            local success, upvalues = pcall(debug.getupvalues, v)
            if success then
                for x,y in pairs(upvalues) do
                    if type(y) == "table" and rawget(y,1) == 1.5 and rawget(y,2) == 1 and rawget(y, 3) == 1.25 and rawget(y,4) == 1.25 and rawget(y, 5) == 1 then
                        swingSpeeds.kopis, swingSpeeds.swingSpeeds = kopisTool, y
                        return y
                    end
                end
            end
        end
    end 
    return swingSpeeds.default
end

function kopis.getSlashDelay()
    if not getgc then
        return nil
    end
    -- Search for SLASH_COOLDOWN variable
    for _,v in pairs(getgc()) do
        if type(v) == "function" then
            local success, upvalues = pcall(debug.getupvalues, v)
            if success then
                for _,y in pairs(upvalues) do
                    if type(y) == "table" then 
                        if rawget(y, "slash") then 
                            return y
                        end
                    end
                end
            end
        end
    end
end

function kopis.getCombatEvents()
    local success, events = pcall(function()
        return game:GetService("ReplicatedStorage").CombatEvents
    end)
    if success and events then
        --[[
            Return the ACTUAL remote names as they appear in game.
            PlaySound = used for dealing damage (server's eDealDamage listens here)
            DealDamage = used for playing sounds (server's ePlaySound listens here)
        --]]
        return {
            PlaySound = events:FindFirstChild("PlaySound"),   -- Fire this to deal damage
            DealDamage = events:FindFirstChild("DealDamage"), -- Fire this to play sound
            StudCount = events:FindFirstChild("StudCount")
        }
    end
    return nil
end

function kopis.damage(humanoid, part)
    if not humanoid or not humanoid:IsA("Humanoid") then
        return
    end
    
    local kopisTool = kopis.getKopis()
    if not kopisTool then
        return
    end

    local tip = kopis.getTip(kopisTool)
    if not tip then
        return
    end
    
    -- If part is provided, verify it's the tip
    if part and part ~= tip then
        return
    end
    
    -- Cooldown check (matches SLASH_COOLDOWN = 0.55 from KopisLocal.lua)
    if os.clock() - lastHit < swingSpeeds.cooldown then
        return
    end
    
    local events = kopis.getCombatEvents()
    if not events or not events.PlaySound then 
        return 
    end
    
    -- Fire PlaySound to deal damage (like KopisLocal.lua line 98)
    pcall(function()
        events.PlaySound:FireServer(humanoid) 
    end)
    
    lastHit = os.clock()
end

local lastCrit = os.clock()

-- Hook to intercept damage calls for team kill check and critical hits
local mt = getrawmetatable(game)
local old = mt.__namecall
setreadonly(mt, false)

mt.__namecall = newcclosure(function(self, ...)
    local method = getnamecallmethod()
    local args = {...}
    
    if method == "FireServer" and typeof(self) == "Instance" then
        local events = kopis.getCombatEvents()
        
        -- Check if this is the damage remote (PlaySound)
        if events and self == events.PlaySound then
            local firstArg = args[1]
            
            -- Skip if it's os.clock() call (number) - game does this on load
            if typeof(firstArg) == "number" then
                return old(self, ...)
            end
            
            -- Only process if it's a Humanoid (damage call)
            if firstArg and typeof(firstArg) == "Instance" and firstArg:IsA("Humanoid") then
                local humanoid = firstArg
                local targetCharacter = humanoid.Parent
                
                if targetCharacter then
                    local player = Players:GetPlayerFromCharacter(targetCharacter)
                    
                    if player then
                        -- Team kill prevention (unless enabled)
                        if player.Team == gg.client.Team and not kopis.teamKill then
                            return
                        end
                        
                        -- Critical hit system
                        if gg.getCriticalHitData and gg.getCriticalHitData().Activated then
                            local critData = gg.getCriticalHitData()
                            local chanceNum = math.random(0, 100)
                            
                            if chanceNum <= critData.Chance and os.clock() - lastCrit >= critData.Delay then
                                task.spawn(function()
                                    task.wait(critData.Delay)
                                    lastCrit = os.clock()
                                    old(self, humanoid)
                                end)
                            end
                        end
                    end
                end
            end
        end
    end
    
    return old(self, ...)
end)

setreadonly(mt, true)

return kopis
