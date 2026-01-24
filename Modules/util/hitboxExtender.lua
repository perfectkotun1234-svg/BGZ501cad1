--[[
    hitboxExtender.lua (Hook GetTouchingParts Method)
    
    Hooks the blade's GetTouchingParts() function to inject
    nearby enemy body parts into the result.
    
    When game calls: blade:GetTouchingParts()
    We return: original parts + nearby enemy parts
    
    This makes the game think enemies are touching the blade!
--]]

local hitboxExtender = {
    Activated = false,
    Keybind = Enum.KeyCode.X,
    Range = 15,
    Hooked = false,
    OldNamecall = nil,
}

local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

gg.getHitboxExtenderData = function()
    return hitboxExtender
end

-- Get nearby enemy parts
local function getNearbyEnemyParts()
    local enemyParts = {}
    local character = gg.client.Character
    if not character then return enemyParts end
    
    local myHRP = character:FindFirstChild("HumanoidRootPart")
    if not myHRP then return enemyParts end
    
    for _, player in pairs(Players:GetPlayers()) do
        if player ~= gg.client and player.Character then
            local enemyCharacter = player.Character
            local enemyHRP = enemyCharacter:FindFirstChild("HumanoidRootPart")
            local enemyHumanoid = enemyCharacter:FindFirstChild("Humanoid")
            
            if enemyHRP and enemyHumanoid and enemyHumanoid.Health > 0 then
                local distance = (myHRP.Position - enemyHRP.Position).Magnitude
                
                if distance <= hitboxExtender.Range then
                    -- Add enemy body parts
                    local torso = enemyCharacter:FindFirstChild("Torso")
                    local head = enemyCharacter:FindFirstChild("Head")
                    local leftArm = enemyCharacter:FindFirstChild("Left Arm")
                    local rightArm = enemyCharacter:FindFirstChild("Right Arm")
                    
                    if torso then table.insert(enemyParts, torso) end
                    if head then table.insert(enemyParts, head) end
                    if leftArm then table.insert(enemyParts, leftArm) end
                    if rightArm then table.insert(enemyParts, rightArm) end
                end
            end
        end
    end
    
    return enemyParts
end

function hitboxExtender:SetupHook()
    if self.Hooked then return end
    
    local mt = getrawmetatable(game)
    local oldNamecall = mt.__namecall
    self.OldNamecall = oldNamecall
    
    setreadonly(mt, false)
    
    mt.__namecall = newcclosure(function(self2, ...)
        local method = getnamecallmethod()
        
        -- Check if it's GetTouchingParts on the blade tip
        if method == "GetTouchingParts" and hitboxExtender.Activated then
            -- Check if this is the blade
            if self2 and self2.Name == "Tip" then
                local parent = self2.Parent
                if parent and parent.Name == "Blade" then
                    -- This is the kopis blade!
                    local originalParts = oldNamecall(self2, ...)
                    
                    -- Add nearby enemy parts
                    local enemyParts = getNearbyEnemyParts()
                    for _, part in pairs(enemyParts) do
                        table.insert(originalParts, part)
                    end
                    
                    return originalParts
                end
            end
        end
        
        return oldNamecall(self2, ...)
    end)
    
    setreadonly(mt, true)
    self.Hooked = true
end

function hitboxExtender:RemoveHook()
    if not self.Hooked or not self.OldNamecall then return end
    
    local mt = getrawmetatable(game)
    setreadonly(mt, false)
    mt.__namecall = self.OldNamecall
    setreadonly(mt, true)
    
    self.Hooked = false
    self.OldNamecall = nil
end

function hitboxExtender:On()
    self:SetupHook()
end

function hitboxExtender:Off()
    -- Don't remove hook, just deactivate
    -- (removing hook might cause issues if other scripts use it)
end

local newKeybind = gg.keybinds.newButton(gg.ui.Menu.Settings.hitboxExtender.Keybind, "Hitbox Extender")

newKeybind:Bind(function(key)
    hitboxExtender.Keybind = key
end)

local newSlider = gg.slider.new(gg.ui:WaitForChild("Menu").Settings.hitboxExtender.Slider, 5, 25, 1)

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
