local swingSpeed = {
    Activated = false,
    Keybind = Enum.KeyCode.V,
    SwingSpeed = 1,
    HitCooldown = 0.55,
    Connection = nil,
}

local UserInputService = game:GetService("UserInputService")

function setSwingSpeed(speed)
    local currentSwingSpeed = gg.kopis.getSwingSpeed()
    if not currentSwingSpeed then
        return
    end
    
    if type(speed) == "number" then
        for i,v in pairs(currentSwingSpeed) do
            currentSwingSpeed[i] = speed
        end
    else
        for i,v in pairs(currentSwingSpeed) do
            currentSwingSpeed[i] = speed[i]
        end
    end
end

function setSwingCooldown(val)
    local currentDelay = gg.kopis.getSlashDelay()
    if currentDelay then
        currentDelay.slash = val
    end
end

function swingSpeed:On()
    setSwingSpeed(swingSpeed.SwingSpeed)
    setSwingCooldown(swingSpeed.HitCooldown)
    gg.kopis.setDamageCooldown(swingSpeed.HitCooldown)
    
    swingSpeed.Connection = gg.client.CharacterAdded:Connect(function()
        task.wait(0.5)
        setSwingSpeed(swingSpeed.SwingSpeed)
        setSwingCooldown(swingSpeed.HitCooldown)
        gg.kopis.setDamageCooldown(swingSpeed.HitCooldown)
    end)
end

function swingSpeed:Off()
    setSwingSpeed(gg.kopis.getDefaultSwingSpeeds())
    setSwingCooldown(0.55)
    gg.kopis.setDamageCooldown(0.55)
    
    if swingSpeed.Connection then
        swingSpeed.Connection:Disconnect()
        swingSpeed.Connection = nil
    end
end

local swingSlider = gg.slider.new(gg.ui:WaitForChild("Menu").Settings.swingSpeed.SwingSlider, 0, 2, 2)

swingSlider:Bind(function(val)
    swingSpeed.SwingSpeed = val
    if swingSpeed.Activated then
        setSwingSpeed(val)
    end
end)

local delaySlider = gg.slider.new(gg.ui:WaitForChild("Menu").Settings.swingSpeed.DelaySlider, 0, 1, 3)

delaySlider:Bind(function(val)
    swingSpeed.HitCooldown = val
    if swingSpeed.Activated then
        setSwingCooldown(val)
        gg.kopis.setDamageCooldown(val)
    end
end)

local newKeybind = gg.keybinds.newButton(gg.ui.Menu.Settings.swingSpeed.Keybind, "Swing Speed")

newKeybind:Bind(function(key)
    swingSpeed.Keybind = key
end)

local label

UserInputService.InputBegan:Connect(function(input)
    local TextBoxFocused = UserInputService:GetFocusedTextBox()
    if TextBoxFocused then return end
    local KeyCode = input.KeyCode
    if KeyCode == swingSpeed.Keybind then
        if swingSpeed.Activated == false then
            swingSpeed:On()
            if label then
                label:Destroy()
                label = nil
            end
            label = gg.ui.Templates.TextLabel:Clone()
            label.Text = "Swing Modifier"
            label.Parent = gg.ui.Overlay:WaitForChild("Active")
            label.Visible = true
        else
            swingSpeed:Off()
            if label then
                label:Destroy()
                label = nil
            end
        end
        swingSpeed.Activated = not swingSpeed.Activated
    end
end)

return swingSpeed