--[[
    hitboxExtender.lua (Using firetouchinterest)
    
    Uses firetouchinterest() to fake blade touching enemies.
    This makes blade:GetTouchingParts() return the enemy parts!
    
    firetouchinterest(Part, Transmitter, Toggle)
    - Part = enemy body part
    - Transmitter = your blade
    - Toggle = 1 (begin touch) or 0 (end touch)
--]]

local hitboxExtender = {
    Activated = false,
    Keybind = Enum.KeyCode.X,
    Range = 15,
    Connection = nil,
}

local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

gg.getHitboxExtenderData = function()
    return hitboxExtender
end

function hitboxExtender:Off()
    if self.Connection then
        self.Connection:Disconnect()
        self.Connection = nil
    end
end

function hitboxExtender:On()
    -- Run every frame while swinging
    self.Connection = RunService.Heartbeat:Connect(function()
        local character = gg.client.Character
        if not character then return end
        
        local kopis = character:FindFirstChild("Kopis")
        if not kopis then return end
        
        local tip = gg.kopis.getTip(kopis)
        if not tip then return end
        
        local myHRP = character:FindFirstChild("HumanoidRootPart")
        if not myHRP then return end
        
        -- Find nearby enemies and fire touch interest
        for _, player in pairs(Players:GetPlayers()) do
            if player ~= gg.client and player.Character then
                local enemyCharacter = player.Character
                local enemyHRP = enemyCharacter:FindFirstChild("HumanoidRootPart")
                local enemyHumanoid = enemyCharacter:FindFirstChild("Humanoid")
                local enemyTorso = enemyCharacter:FindFirstChild("Torso")
                
                if enemyHRP and enemyHumanoid and enemyTorso and enemyHumanoid.Health > 0 then
                    local distance = (myHRP.Position - enemyHRP.Position).Magnitude
                    
                    -- If enemy is within range
                    if distance <= hitboxExtender.Range then
                        -- Fire touch interest - makes blade:GetTouchingParts() detect enemy
                        pcall(function()
                            firetouchinterest(enemyTorso, tip, 1)  -- Begin touch
                            task.defer(function()
                                pcall(function()
                                    firetouchinterest(enemyTorso, tip, 0)  -- End touch
                                end)
                            end)
                        end)
                    end
                end
            end
        end
    end)
end

local newKeybind = gg.keybinds.newButton(gg.ui.Menu.Settings.hitboxExtender.Keybind, "Hitbox Extender")

newKeybind:Bind(function(key)
    hitboxExtender.Keybind = key
end)

local newSlider = gg.slider.new(gg.ui:WaitForChild("Menu").Settings.hitboxExtender.Slider, 5, 20, 1)

newSlider:Bind(function(val)
    hitboxExtender.Range = val
end)

local label

UserInputService.InputBegan:Connect(function(input)
    local TextBoxFocused = UserInputService:GetFocusedTextBox()
    if TextBoxFocused then return end
    local KeyCode = input.KeyCode
    if KeyCode == hitboxExtender.Keybind then
        if hitboxExtender.Activated == false then
            hitboxExtender:On()
            if label then
                label:Destroy()
                label = nil
            end
            label = gg.ui.Templates.TextLabel:Clone()
            label.Text = "Hitbox Extender"
            label.Parent = gg.ui.Overlay:WaitForChild("Active")
            label.Visible = true
        else
            hitboxExtender:Off()
            if label then
                label:Destroy()
                label = nil
            end
        end
        hitboxExtender.Activated = not hitboxExtender.Activated
    end
end)

return hitboxExtender
