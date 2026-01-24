local lastHit = os.clock()
local playerCooldowns = {}
local lastEventFiredAt = tick() - 100
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

if not gg or not gg.client then
    warn("[DAMAGE.LUA] ERROR: gg or gg.client is not defined!")
    return kopis
end

function kopis.setDamageCooldown(cooldown)
    swingSpeeds.cooldown = cooldown
end

function kopis.getDefaultSwingSpeeds()
    return swingSpeeds.default
end

function kopis.getKopis(searchPlayer)
    local client = gg.client
    if searchPlayer == true then
        local character = client.Character
        if not character then
            return
        end
        local tool = character:FindFirstChildOfClass("Tool")
        if tool and tool.Name == "Kopis" then
            return tool
        end
        local backpack = client:FindFirstChild("Backpack")
        if backpack then
            local kopisTool = backpack:FindFirstChild("Kopis")
            if kopisTool then
                return kopisTool
            end
        end
    else
        local character = client.Character
        if not character then
            return
        end
        local tool = character:FindFirstChildOfClass("Tool")
        if tool and tool.Name == "Kopis" then
            return tool
        end
    end
    return nil
end

function kopis.getTip(tool)
    if not tool then
        tool = kopis.getKopis()
    end
    if not tool then
        return nil
    end
    
    local toolModel = tool:FindFirstChild("ToolModel")
    if toolModel then
        local blade = toolModel:FindFirstChild("Blade")
        if blade then
            local tip = blade:FindFirstChild("Tip")
            if tip then
                return tip
            end
        end
    end
    
    local tip = tool:FindFirstChild("Tip", true)
    return tip
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
    if success and events then
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
    
    if tick() - lastEventFiredAt > 0.7 then
        return
    end
    
    local player = Players:GetPlayerFromCharacter(humanoid.Parent)
    if not player then
        return
    end
    
    if player == gg.client then
        return
    end
    
    if player.Team == gg.client.Team and not kopis.teamKill then
        return
    end
    
    local playerCooldown = playerCooldowns[player.UserId] or 0
    if tick() - playerCooldown < 0.7 then
        return
    end
    
    local events = kopis.getCombatEvents()
    if not events or not events.PlaySound or not events.DealDamage then 
        return 
    end
    
    local success = pcall(function()
        events.DealDamage:FireServer(3)
        events.PlaySound:FireServer(humanoid)
    end)
    
    if success then
        playerCooldowns[player.UserId] = tick()
        
        if gg.getCriticalHitData then
            local critData = gg.getCriticalHitData()
            if critData and critData.Activated then
                local chanceNum = math.random(0, 100)
                
                if chanceNum <= critData.Chance then
                    task.spawn(function()
                        task.wait(critData.Delay)
                        pcall(function()
                            events.PlaySound:FireServer(humanoid)
                        end)
                    end)
                end
            end
        end
    end
end

local mt = getrawmetatable(game)
local old = mt.__namecall
setreadonly(mt, false)

mt.__namecall = newcclosure(function(self, ...)
    local arguments = {...}
    
    if typeof(self) == "Instance" and self.Name and (self.Name == "PlaySound" or self.Name == "DealDamage") then
        if tick() - lastEventFiredAt < 0.7 then
            return old(self, ...)
        end
        
        lastEventFiredAt = tick()
    end
    
    return old(self, ...)
end)

setreadonly(mt, true)

return kopis
