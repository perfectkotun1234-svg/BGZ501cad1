--[[
    hitboxExtender.lua 
    
    From KopisLocal.lua analysis:
    - Game uses blade:GetTouchingParts() to detect hits
    - Game checks if enemy body parts are within 3 studs of HumanoidRootPart
    
    Solution: When swinging, briefly teleport nearby enemies TO your blade
    so the game's own detection registers them. Don't modify enemy parts.
--]]

local hitboxExtender = {
    Activated = false,
    Keybind = Enum.KeyCode.X,
    Range = 15,  -- How far to pull enemies from
    Connection = nil,
    SwingConnection = nil,
}

local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

gg.getHitboxExtenderData = function()
    return hitboxExtender
end

local lastPull = 0
local PULL_COOLDOWN = 0.5  -- Match game's SLASH_COOLDOWN

function hitboxExtender:Off()
    if self.Connection then
        self.Connection:Disconnect()
        self.Connection = nil
    end
    if self.SwingConnection then
        self.SwingConnection:Disconnect()
        self.SwingConnection = nil
    end
end

function hitboxExtender:On()
    local function pullEnemiesToBlade()
        -- Check cooldown
        if tick() - lastPull < PULL_COOLDOWN then
            return
        end
        
        local character = gg.client.Character
        if not character then return end
        
        local kopis = character:FindFirstChild("Kopis")
        if not kopis then return end
        
        local tip = gg.kopis.getTip(kopis)
        if not tip then return end
        
        local myHRP = character:FindFirstChild("HumanoidRootPart")
        if not myHRP then return end
        
        -- Find nearby enemies
        for _, player in pairs(Players:GetPlayers()) do
            if player ~= gg.client and player.Character then
                local enemyCharacter = player.Character
                local enemyHRP = enemyCharacter:FindFirstChild("HumanoidRootPart")
                local enemyHumanoid = enemyCharacter:FindFirstChild("Humanoid")
                local enemyTorso = enemyCharacter:FindFirstChild("Torso")
                
                if enemyHRP and enemyHumanoid and enemyTorso and enemyHumanoid.Health > 0 then
                    local distance = (myHRP.Position - enemyHRP.Position).Magnitude
                    
                    -- If enemy is within range but outside normal blade reach
                    if distance <= hitboxExtender.Range and distance > 5 then
                        -- Save original position
                        local originalCFrame = enemyHRP.CFrame
                        
                        -- Briefly teleport enemy's HumanoidRootPart to touch blade
                        -- This makes blade:GetTouchingParts() detect them
                        pcall(function()
                            -- Move enemy torso to blade position
                            enemyTorso.CFrame = tip.CFrame
                            
                            -- Immediately restore (next frame)
                            task.defer(function()
                                pcall(function()
                                    enemyTorso.CFrame = originalCFrame * CFrame.new(0, -3, 0) + (originalCFrame.Position - enemyTorso.Position)
                                end)
                            end)
                        end)
                        
                        lastPull = tick()
                        break  -- Only one enemy per swing
                    end
                end
            end
        end
    end
    
    -- Monitor for mouse clicks (swings)
    self.SwingConnection = UserInputService.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            -- Small delay to let swing animation start
            task.delay(0.05, pullEnemiesToBlade)
            task.delay(0.15, pullEnemiesToBlade)
            task.delay(0.25, pullEnemiesToBlade)
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
