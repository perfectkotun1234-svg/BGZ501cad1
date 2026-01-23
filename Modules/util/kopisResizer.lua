local kopisResizer = {
    Activated = false,
    Keybind = Enum.KeyCode.B,

    Length = 7.5,
    Thickness = 1,

    Proxy = nil,
    Connection = nil,
    Connection2 = nil,
}

local UserInputService = game:GetService("UserInputService")

function kopisResizer:On()
    local kopis = gg.kopis.getKopis()

    local function createProxy(kopis)
        if not kopis then return end
        
        local tip = kopis:FindFirstChild("Tip", true)
        if not tip then return end
        
        local proxy = gg.proxyPart.new()
        proxy:Link(tip, true, kopisResizer.Length)
        proxy:SetSize(Vector3.new(kopisResizer.Length, 0.538, kopisResizer.Thickness), kopisResizer.Length)
        proxy:CreateOutline()
        proxy:BindTouch(function(part)
            local character = part.Parent
            if not character then return end
            
            local humanoid = character:FindFirstChild("Humanoid")
            if humanoid and game:GetService("Players"):GetPlayerFromCharacter(character) then
                if gg.kopis.getKopis() then
                    local currentTip = gg.kopis.getKopis():FindFirstChild("Tip", true)
                    if currentTip then
                        gg.kopis.damage(humanoid, currentTip)
                    end
                end
            end
        end)

        kopisResizer.Proxy = proxy
    end

    local function createSecondaryConnection()
        local character = gg.client.Character or gg.client.CharacterAdded:Wait()
        if kopisResizer.Connection2 then
            kopisResizer.Connection2:Disconnect()
            kopisResizer.Connection2 = nil
        end
        kopisResizer.Connection2 = character.ChildAdded:Connect(function(obj)
            if obj:IsA("Tool") then
                local kopisTool = gg.kopis.getKopis()
                if obj == kopisTool then
                    if kopisResizer.Proxy then
                        kopisResizer.Proxy:Destroy()
                        kopisResizer.Proxy = nil
                    end
                    task.wait(0.1)
                    createProxy(kopisTool)
                end
            end
        end)
    end

    if kopis then
        createProxy(kopis)
    end

    createSecondaryConnection()
    kopisResizer.Connection = gg.client.CharacterAdded:Connect(function()
        createSecondaryConnection()
    end)
end

function kopisResizer:Off()
    if self.Proxy then
        self.Proxy:Destroy()
        self.Proxy = nil
    end
    if self.Connection then
        self.Connection:Disconnect()
        self.Connection = nil
    end
    if self.Connection2 then
        self.Connection2:Disconnect()
        self.Connection2 = nil
    end
end

local lengthSlider = gg.slider.new(gg.ui:WaitForChild("Menu").Settings.kopisResizer.LengthSlider, 0, 15, 2)

lengthSlider:Bind(function(val)
    kopisResizer.Length = val
    if kopisResizer.Activated and kopisResizer.Proxy then
        kopisResizer.Proxy:SetSize(Vector3.new(kopisResizer.Length, 0.538, kopisResizer.Thickness), kopisResizer.Length)
    end
end)

local thicknessSlider = gg.slider.new(gg.ui:WaitForChild("Menu").Settings.kopisResizer.ThicknessSlider, 0, 2, 2)

thicknessSlider:Bind(function(val)
    kopisResizer.Thickness = val
    if kopisResizer.Activated and kopisResizer.Proxy then
        kopisResizer.Proxy:SetSize(Vector3.new(kopisResizer.Length, 0.538, kopisResizer.Thickness), kopisResizer.Length)
    end
end)

local newKeybind = gg.keybinds.newButton(gg.ui.Menu.Settings.kopisResizer.Keybind, "Kopis Resizer")

newKeybind:Bind(function(key)
    kopisResizer.Keybind = key
end)

local label

UserInputService.InputBegan:Connect(function(input)
    local TextBoxFocused = UserInputService:GetFocusedTextBox()
    if TextBoxFocused then return end
    local KeyCode = input.KeyCode
    if KeyCode == kopisResizer.Keybind then
        if kopisResizer.Activated == false then
            kopisResizer:On()

            if label then
                label:Destroy()
                label = nil
            end

            label = gg.ui.Templates.TextLabel:Clone()
            label.Text = "Kopis Resizer"
            label.Parent = gg.ui.Overlay:WaitForChild("Active")
            label.Visible = true
        else
            kopisResizer:Off()

            if label then
                label:Destroy()
                label = nil
            end
        end
        kopisResizer.Activated = not kopisResizer.Activated
    end
end)

return kopisResizer