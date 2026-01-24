--[[
    damage.lua (CLEAN - No Metahook)
    
    NO METAHOOK VERSION - Let the game handle damage normally.
    
    The metahook was breaking the game's damage system.
    Your exploit features (hitbox, resizer, etc.) will call kopis.damage() directly.
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

-- Main damage function - called by exploit features (hitbox, resizer, etc.)
function kopis.damage(humanoid, part)
    if not humanoid or not humanoid:IsA("Humanoid") then
        return
    end
    
    -- Team kill check (only for exploit damage)
    local targetCharacter = humanoid.Parent
    if targetCharacter then
        local targetPlayer = Players:GetPlayerFromCharacter(targetCharacter)
        if targetPlayer and gg.client and targetPlayer.Team == gg.client.Team and not kopis.teamKill then
            return
        end
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
    
    -- Fire damage
    pcall(function()
        events.PlaySound:FireServer(humanoid) 
    end)
    
    lastHit = os.clock()
    
    -- Critical hit (only for exploit damage)
    if gg.getCriticalHitData and gg.getCriticalHitData().Activated then
        local critData = gg.getCriticalHitData()
        local chanceNum = math.random(0, 100)
        
        if chanceNum <= critData.Chance and os.clock() - lastCrit >= critData.Delay then
            task.spawn(function()
                task.wait(critData.Delay)
                lastCrit = os.clock()
                pcall(function()
                    events.PlaySound:FireServer(humanoid)
                end)
            end)
        end
    end
end

-- NO METAHOOK - Game handles its own damage normally
-- Your exploit features call kopis.damage() for extended hitbox/resizer hits

return kopis
