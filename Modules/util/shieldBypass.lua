--[[
    shieldBypass.lua (FIXED)
    
    Shield detection from KopisLocal.lua lines 81-93:
    - activeShield = hitHumanoid.Parent:FindFirstChild("Equipped", true)
    - if activeShield.Value then (shield is equipped)
    - hitShield = hitHumanoid.Parent.Torso.CFrame.LookVector:Dot(torso.CFrame.LookVector)
    - if hitShield > -1.01 and hitShield < -.29 then (shield is blocking)
    
    When shield blocks, game fires: eDealDamage:FireServer(2) for shield sound
--]]

local shieldBypass = {
    Activated = false,
    Keybind = Enum.KeyCode.M,
    Chance = 50,
    Connection = nil,
    Connection2 = nil,
    TouchedConnection = nil,
}

local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

gg.getShieldBypassData = function()
    return shieldBypass
end

-- Check if target has shield active and is blocking (facing attacker)
-- Matches KopisLocal.lua shield detection logic exactly
local function isShieldBlocking(targetHumanoid, attackerTorso)
    if not targetHumanoid or not targetHumanoid.Parent then
        return false
    end
    
    local targetCharacter = targetHumanoid.Parent
    local targetTorso = targetCharacter:FindFirstChild("Torso")
    
    if not targetTorso then
        return false
    end
    
    -- Check for "Equipped" BoolValue (KopisLocal.lua line 81)
    local activeShield = targetCharacter:FindFirstChild("Equipped", true)
    
    if not activeShield then
        return false
    end
    
    -- Check if shield is actually equipped (KopisLocal.lua line 83)
    if not activeShield.Value then
        return false
    end
    
    -- Dot product check (KopisLocal.lua lines 85-87)
    -- hitShield = hitHumanoid.Parent.Torso.CFrame.LookVector:Dot(torso.CFrame.LookVector)
    -- if hitShield > -1.01 and hitShield < -.29 then (shield IS blocking)
    local hitShield = targetTorso.CFrame.LookVector:Dot(attackerTorso.CFrame.LookVector)
    
    if hitShield > -1.01 and hitShield < -0.29 then
        return true  -- Shield is blocking
    end
    
    return false
end

function shieldBypass:On()
    local function bindTouch()
        local kopisTool = gg.kopis.getKopis()
        if not kopisTool then return end
        
        local tip = gg.kopis.getTip(kopisTool)
        if not tip then return end
        
        if shieldBypass.TouchedConnection then
            shieldBypass.TouchedConnection:Disconnect()
            shieldBypass.TouchedConnection = nil
        end
        
        shieldBypass.TouchedConnection = tip.Touched:Connect(function(obj)
            local client = gg.client
            local clientCharacter = client.Character
            if not clientCharacter then return end
            
            local clientTorso = clientCharacter:FindFirstChild("Torso")
            if not clientTorso then return end
            
            -- Find humanoid from hit part (same logic as KopisLocal.lua lines 76-80)
            local hitHumanoid = obj.Parent:FindFirstChild("Humanoid")
                or obj.Parent.Parent:FindFirstChild("Humanoid")
                or (obj.Parent.Parent.Parent and obj.Parent.Parent.Parent:FindFirstChild("Humanoid"))
                or (obj.Parent.Parent.Parent and obj.Parent.Parent.Parent.Parent and obj.Parent.Parent.Parent.Parent:FindFirstChild("Humanoid"))
            
            if not hitHumanoid then return end
            if hitHumanoid == clientCharacter:FindFirstChild("Humanoid") then return end
            
            -- Check if shield is blocking
            if isShieldBlocking(hitHumanoid, clientTorso) then
                -- Roll for bypass chance
                local chanceNumber = math.random(0, 100)
                if chanceNumber <= shieldBypass.Chance then
                    -- Bypass shield and deal damage
                    gg.kopis.damage(hitHumanoid, tip)
                end
            end
        end)
    end
    
    local function createSecondaryConnection()
        local character = gg.client.Character or gg.client.CharacterAdded:Wait()
        if shieldBypass.Connection2 then
            shieldBypass.Connection2:Disconnect()
            shieldBypass.Connection2 = nil
        end
        
        shieldBypass.Connection2 = character.ChildAdded:Connect(function(obj)
            if obj:IsA("Tool") and obj.Name == "Kopis" then
                task.wait(0.1)
                bindTouch()
            end
        end)
    end
    
    if gg.kopis.getKopis() then
        bindTouch()
    end
    
    createSecondaryConnection()
    shieldBypass.Connection = gg.client.CharacterAdded:Connect(function()
        createSecondaryConnection()
    end)
end

function shieldBypass:Off()
    if shieldBypass.Connection then
        shieldBypass.Connection:Disconnect()
        shieldBypass.Connection = nil
    end
    if shieldBypass.Connection2 then
        shieldBypass.Connection2:Disconnect()
        shieldBypass.Connection2 = nil
    end
    if shieldBypass.TouchedConnection then
        shieldBypass.TouchedConnection:Disconnect()
        shieldBypass.TouchedConnection = nil
    end
end

local chanceSlider = gg.slider.new(gg.ui:WaitForChild("Menu").Settings.shieldBypass.Slider, 0, 100, 0, true)

chanceSlider:Bind(function(val)
    shieldBypass.Chance = val
end)

local newKeybind = gg.keybinds.newButton(gg.ui.Menu.Settings.shieldBypass.Keybind, "Shield Bypass")

newKeybind:Bind(function(key)
    shieldBypass.Keybind = key
end)

local label

UserInputService.InputBegan:Connect(function(input)
    local TextBoxFocused = UserInputService:GetFocusedTextBox()
    if TextBoxFocused then return end
    local KeyCode = input.KeyCode
    if KeyCode == shieldBypass.Keybind then
        if shieldBypass.Activated == false then
            if label then
                label:Destroy()
                label = nil
            end
            shieldBypass:On()
            label = gg.ui.Templates.TextLabel:Clone()
            label.Text = "Shield Bypass"
            label.Parent = gg.ui.Overlay:WaitForChild("Active")
            label.Visible = true
        else
            if label then
                label:Destroy()
                label = nil
            end
            shieldBypass:Off()
        end
        shieldBypass.Activated = not shieldBypass.Activated
    end
end)

return shieldBypass
