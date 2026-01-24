--[[
    damage.lua (FIXED)
    
    Fixes:
    - Swapped PlaySound/DealDamage remotes to match game
    - Added getTip() function
    - Fixed blade path: ToolModel > Blade > Tip
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
        -- Search in player's backpack
        local backpack = client:FindFirstChild("Backpack")
        if backpack then
            local kopisTool = backpack:FindFirstChild("Kopis")
            if kopisTool then
                return kopisTool
            end
        end
        -- Search in character
        local character = client.Character
        if character then
            local kopisTool = character:FindFirstChild("Kopis")
            if kopisTool then
                return kopisTool
            end
        end
        return nil
    else
        local character = client.Character
        if not character then
            return nil
        end
        local kopisTool = character:FindFirstChild("Kopis")
        if kopisTool then
            return kopisTool
        end
        return nil
    end
end

-- NEW: Get the tip of the kopis blade
function kopis.getTip(kopisTool)
    if not kopisTool then
        kopisTool = kopis.getKopis() or kopis.getKopis(true)
    end
    if not kopisTool then
        return nil
    end
    
    -- Path: Kopis > ToolModel > Blade > Tip (based on KopisLocal.lua)
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
        --[[
            FIXED: The game has these SWAPPED in CombatDamageServer.lua:
            eDealDamage = combatEvents.PlaySound  (PlaySound actually deals damage)
            ePlaySound  = combatEvents.DealDamage (DealDamage actually plays sound)
            
            So we swap them here to match:
        --]]
        return {
            DealDamage = events:FindFirstChild("PlaySound"),  -- SWAPPED
            PlaySound = events:FindFirstChild("DealDamage")   -- SWAPPED
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
    
    if os.clock() - lastHit < swingSpeeds.cooldown then
        return
    end
    
    local events = kopis.getCombatEvents()
    if not events or not events.DealDamage then 
        return 
    end
    
    pcall(function()
        events.DealDamage:FireServer(humanoid) 
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
        
        -- Check if this is a damage event (remember: DealDamage = PlaySound remote)
        if events and self == events.DealDamage then
            local humanoid = args[1]
            
            if humanoid and humanoid:IsA("Humanoid") then
                local player = Players:GetPlayerFromCharacter(humanoid.Parent)
                
                if player then
                    -- Team kill check
                    if player.Team == gg.client.Team and not kopis.teamKill then
                        return
                    end
                    
                    -- Critical hit check
                    if gg.getCriticalHitData and gg.getCriticalHitData().Activated then
                        local critData = gg.getCriticalHitData()
                        local chanceNum = math.random(0, 100)
                        
                        if chanceNum <= critData.Chance and os.clock() - lastCrit >= critData.Delay then
                            task.spawn(function()
                                task.wait(critData.Delay)
                                lastCrit = os.clock()
                                events.DealDamage:FireServer(humanoid)
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
