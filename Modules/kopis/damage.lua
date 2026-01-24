--[[
    damage.lua
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

function kopis.getKopis(searchPlayer)
    local client = gg.client
    if searchPlayer == true then
        local tip = client:FindFirstChild("Tip", true)
        if not tip or not tip.Parent:IsA("Tool") then
            return
        end
        local tool = tip.Parent
        return tool
    else
        local character = client.Character
        if not character then
            return
        end
        local tip = character:FindFirstChild("Tip", true)
        if not tip or not tip.Parent:IsA("Tool") then
            return
        end
        local tool = tip.Parent
        return tool
    end
end

function kopis.getSwingSpeed()
    local kopisTool = kopis.getKopis() or kopis.getKopis(true)
    if not kopisTool then
        return
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
                    if type(y) == "table" and rawget(y,1) == 1.5 and rawget(y,2) == 1 and rawget(y, 3) == 1.25 and rawget(y,4) == 1.25 and rawget(y, 5)== 1 then
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
    if success then
        return {
            PlaySound = events:FindFirstChild("PlaySound"),
            DealDamage = events:FindFirstChild("DealDamage")
        }
    end
    return nil
end

function kopis.damage(humanoid, part)
    if not humanoid or not humanoid:IsA("Humanoid") then
        return
    end
    
    if not part or not part.Parent or not part.Parent:IsA("Tool") then
        return
    end

    local tool = kopis.getKopis()
    if not tool then
        return
    end

    local tip = tool:FindFirstChild("Tip", true)
    if not tip or part ~= tip then
        return
    end
    if os.clock() - lastHit < swingSpeeds.cooldown then
        return
    end
    local events = kopis.getCombatEvents()
    if not events or not events.PlaySound or not events.DealDamage then return end
    pcall(function()
        events.PlaySound:FireServer(humanoid) 
    end)
    
    lastHit = os.clock()
end

local lastCrit = os.clock()

local mt = getrawmetatable(game)
local old = mt.__namecall
setreadonly(mt, false)

mt.__namecall = newcclosure(function(self, ...)
    local method = getnamecallmethod()
    local args = {...}
    if method == "FireServer" and typeof(self) == "Instance" then
        local events = kopis.getCombatEvents()
        if events and self == events.PlaySound then
            local humanoid = args[1]
            
            if humanoid and humanoid:IsA("Humanoid") then
                local player = Players:GetPlayerFromCharacter(humanoid.Parent)
                
                if player then
                    if player.Team == gg.client.Team and not kopis.teamKill then
                        return
                    end
                    if gg.getCriticalHitData and gg.getCriticalHitData().Activated then
                        local critData = gg.getCriticalHitData()
                        local chanceNum = math.random(0, 100)
                        
                        if chanceNum <= critData.Chance and os.clock() - lastCrit >= critData.Delay then
                            task.spawn(function()
                                task.wait(critData.Delay)
                                lastCrit = os.clock()
                                events.PlaySound:FireServer(humanoid)
                            end)
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