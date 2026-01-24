local shieldBypass = {
    Activated = false,
    Keybind = Enum.KeyCode.M,
    Chance = 50,
    Connection = nil,
    Connection2 = nil,
    TouchedConnection = nil,
}

local UserInputService = game:GetService("UserInputService")

gg.getShieldBypassData = function()
    return shieldBypass
end

function shieldBypass:On()
    local function bindTouch()
        local kopis = gg.kopis.getKopis()
        if not kopis then return end
        
        local tip = kopis:FindFirstChild("Tip", true)
        
        if tip then
            if shieldBypass.TouchedConnection then
                shieldBypass.TouchedConnection:Disconnect()
                shieldBypass.TouchedConnection = nil
            end
            
            shieldBypass.TouchedConnection = tip.Touched:Connect(function(obj)
                if obj.Material == Enum.Material.Metal or obj.Material == Enum.Material.DiamondPlate then
                    local character = obj.Parent and obj.Parent.Parent
                    if character then
                        local humanoid = character:FindFirstChild("Humanoid")
                        if humanoid then
                            local chanceNumber = math.random(0, 100)
                            if chanceNumber <= shieldBypass.Chance then
                                local currentTip = gg.kopis.getKopis() and gg.kopis.getKopis():FindFirstChild("Tip", true)
                                if currentTip then
                                    gg.kopis.damage(humanoid, currentTip)
                                end
                            end
                        end
                    end
                end
            end)
        end
    end
    
    local function createSecondaryConnection()
        local character = gg.client.Character or gg.client.CharacterAdded:Wait()
        if shieldBypass.Connection2 then
            shieldBypass.Connection2:Disconnect()
            shieldBypass.Connection2 = nil
        end
        
        shieldBypass.Connection2 = character.ChildAdded:Connect(function(obj)
            if obj:IsA("Tool") then
                local kopis = gg.kopis.getKopis()
                if obj == kopis then
                    task.wait(0.1)
                    bindTouch()
                end
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
