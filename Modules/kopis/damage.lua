local lastHit = os.clock()
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

print("[DAMAGE.LUA] Starting load...")

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

print("[DAMAGE.LUA] gg.client found:", gg.client.Name)

function kopis.setDamageCooldown(cooldown)
    swingSpeeds.cooldown = cooldown
    print("[DAMAGE.LUA] Set cooldown to:", cooldown)
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
    if success and events then
        return {
            PlaySound = events:FindFirstChild("PlaySound"),
            DealDamage = events:FindFirstChild("DealDamage")
        }
    end
    return nil
end

function kopis.damage(humanoid, part)
    print("[DAMAGE.LUA] damage() called")
    
    if not humanoid or not humanoid:IsA("Humanoid") then
        print("[DAMAGE.LUA] Invalid humanoid")
        return
    end
    
    if not part or not part.Parent or not part.Parent:IsA("Tool") then
        print("[DAMAGE.LUA] Invalid part")
        return
    end

    local tool = kopis.getKopis()
    if not tool then
        print("[DAMAGE.LUA] No kopis found")
        return
    end

    local tip = tool:FindFirstChild("Tip", true)
    if not tip or part ~= tip then
        print("[DAMAGE.LUA] Part is not tip")
        return
    end
    
    if os.clock() - lastHit < swingSpeeds.cooldown then
        print("[DAMAGE.LUA] Cooldown active")
        return
    end
    
    local player = Players:GetPlayerFromCharacter(humanoid.Parent)
    if player and player.Team == gg.client.Team and not kopis.teamKill then
        print("[DAMAGE.LUA] Blocked team kill")
        return
    end
    
    local events = kopis.getCombatEvents()
    if not events or not events.PlaySound or not events.DealDamage then 
        print("[DAMAGE.LUA] Events not found")
        return 
    end
    
    print("[DAMAGE.LUA] Firing PlaySound for:", humanoid.Parent.Name)
    pcall(function()
        events.PlaySound:FireServer(humanoid) 
    end)
    
    lastHit = os.clock()
    
    if gg.getCriticalHitData then
        local critData = gg.getCriticalHitData()
        if critData and critData.Activated and player then
            local chanceNum = math.random(0, 100)
            
            if chanceNum <= critData.Chance then
                print("[DAMAGE.LUA] Critical hit triggered!")
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

print("[DAMAGE.LUA] Loaded successfully!")
print("[DAMAGE.LUA] Team Kill enabled:", kopis.teamKill)

return kopis
