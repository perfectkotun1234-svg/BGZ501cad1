--[[
    damage.lua (FIXED - Game Bug Workaround)
    
    The game has a bug where it calls GetPlayerFromCharacter on a RemoteEvent.
    We fix this by adding GetPlayerFromCharacter to the RemoteEvent.
--]]

local lastHit = os.clock()
local lastCrit = os.clock()
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

-- FIX GAME BUG: Add GetPlayerFromCharacter to RemoteEvents
-- The game's KopisLocal.lua line 118 calls PlaySound:GetPlayerFromCharacter() which is wrong
-- We add this method to RemoteEvents so it doesn't error
pcall(function()
    local CombatEvents = game:GetService("ReplicatedStorage"):WaitForChild("CombatEvents", 5)
    if CombatEvents then
        local PlaySound = CombatEvents:FindFirstChild("PlaySound")
        local DealDamage = CombatEvents:FindFirstChild("DealDamage")
        
        -- Add fake GetPlayerFromCharacter that redirects to Players service
        if PlaySound then
            PlaySound.GetPlayerFromCharacter = function(self, character)
                return Players:GetPlayerFromCharacter(character)
            end
        end
        if DealDamage then
            DealDamage.GetPlayerFromCharacter = function(self, character)
                return Players:GetPlayerFromCharacter(character)
            end
        end
    end
end)

function kopis.setDamageCooldown(cooldown)
    swingSpeeds.cooldown = cooldown
end

function kopis.getDefaultSwingSpeeds()
    return swingSpeeds.default
end

function kopis.getKopis(searchBackpack)
    local client = gg.client
    if not client then return nil end
    
    local character = client.Character
    if character then
        local kopisTool = character:FindFirstChild("Kopis")
        if kopisTool then
            return kopisTool
        end
    end
    
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

function kopis.getTip(kopisTool)
    if not kopisTool then
        kopisTool = kopis.getKopis() or kopis.getKopis(true)
    end
    if not kopisTool then
        return nil
    end
    
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
    
    local tip = kopisTool:FindFirstChild("Tip", true)
    return tip
end

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
        return {
            PlaySound = events:FindFirstChild("PlaySound"),
            DealDamage = events:FindFirstChild("DealDamage"),
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
    
    if part and part ~= tip then
        return
    end
    
    if os.clock() - lastHit < swingSpeeds.cooldown then
        return
    end
    
    local events = kopis.getCombatEvents()
    if not events or not events.PlaySound then 
        return 
    end
    
    pcall(function()
        events.PlaySound:FireServer(humanoid) 
    end)
    
    lastHit = os.clock()
end

-- METAHOOK: Intercepts all damage calls for team kill check and critical hits
local mt = getrawmetatable(game)
local old = mt.__namecall
setreadonly(mt, false)

mt.__namecall = newcclosure(function(self, ...)
    local method = getnamecallmethod()
    local args = {...}
    
    if method == "FireServer" and typeof(self) == "Instance" then
        local events = kopis.getCombatEvents()
        
        if events and self == events.PlaySound then
            local firstArg = args[1]
            
            -- Skip os.clock() calls (game sends this on load)
            if typeof(firstArg) == "number" then
                return old(self, ...)
            end
            
            -- Process humanoid (damage call)
            if firstArg and typeof(firstArg) == "Instance" and firstArg:IsA("Humanoid") then
                local humanoid = firstArg
                local targetCharacter = humanoid.Parent
                
                if targetCharacter then
                    local player = Players:GetPlayerFromCharacter(targetCharacter)
                    
                    if player then
                        -- Team kill prevention
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
