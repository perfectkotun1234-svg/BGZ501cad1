--[[
    kopisResizer.lua (FIXED)
      
    The game detects blade resizing and reports to server!
    This version uses a PROXY PART instead of modifying actual blade.
    
    Server distance limit from CombatDamageServer.lua: 12 studs
--]]

local kopisResizer = {
    Activated = false,
    Keybind = Enum.KeyCode.B,

    Length = 7.5,
    Thickness = 1,

    Proxy = nil,
    Connection = nil,
    Connection2 = nil,
    Connection3 = nil,
    
    MaxServerDistance = 12,
}

local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")

gg.getKopisResizerData = function()
    return kopisResizer
end

function kopisResizer:On()
    local function createProxy(kopisTool)
        if not kopisTool then return end
        
        local tip = gg.kopis.getTip(kopisTool)
        if not tip then return end
        
        -- Destroy old proxy
        if kopisResizer.Proxy then
            kopisResizer.Proxy:Destroy()
            kopisResizer.Proxy = nil
        end
        
        local proxy = gg.proxyPart.new()
        
        -- Link to tip with weld
        proxy:Link(tip, true)
        
        -- Clamp to server distance
        local clampedLength = math.min(kopisResizer.Length, kopisResizer.MaxServerDistance)
        proxy:SetSize(Vector3.new(clampedLength, 0.538, kopisResizer.Thickness))
        proxy:CreateOutline()
        
        proxy:BindTouch(function(part)
            local character = part.Parent
            if not character then return end
            
            -- Find humanoid (same logic as KopisLocal.lua)
            local humanoid = character:FindFirstChild("Humanoid")
            if not humanoid and character.Parent then
                humanoid = character.Parent:FindFirstChild("Humanoid")
                if humanoid then
                    character = character.Parent
                end
            end
            
            if not humanoid then return end
            
            local targetPlayer = Players:GetPlayerFromCharacter(character)
            if not targetPlayer then return end
            if targetPlayer == gg.client then return end
            
            -- Server distance check
            local clientCharacter = gg.client.Character
            if not clientCharacter then return end
            
            local clientRoot = clientCharacter:FindFirstChild("HumanoidRootPart") or clientCharacter:FindFirstChild("Torso")
            local targetRoot = character:FindFirstChild("HumanoidRootPart") or character:FindFirstChild("Torso")
            
            if not clientRoot or not targetRoot then return end
            
            local distance = (clientRoot.Position - targetRoot.Position).Magnitude
            if distance >= kopisResizer.MaxServerDistance then
                return
            end
            
            -- Deal damage using original tip
            gg.kopis.damage(humanoid, tip)
        end)

        kopisResizer.Proxy = proxy
    end

    local function createSecondaryConnection()
        local character = gg.client.Character or gg.client.CharacterAdded:Wait()
        
        if kopisResizer.Connection2 then
            kopisResizer.Connection2:Disconnect()
            kopisResizer.Connection2 = nil
        end
        if kopisResizer.Connection3 then
            kopisResizer.Connection3:Disconnect()
            kopisResizer.Connection3 = nil
        end
        
        -- Handle kopis equip
        kopisResizer.Connection2 = character.ChildAdded:Connect(function(obj)
            if obj:IsA("Tool") and obj.Name == "Kopis" then
                if kopisResizer.Proxy then
                    kopisResizer.Proxy:Destroy()
                    kopisResizer.Proxy = nil
                end
                task.wait(0.1)
                createProxy(obj)
            end
        end)
        
        -- Handle kopis unequip
        kopisResizer.Connection3 = character.ChildRemoved:Connect(function(obj)
            if obj:IsA("Tool") and obj.Name == "Kopis" then
                if kopisResizer.Proxy then
                    kopisResizer.Proxy:Destroy()
                    kopisResizer.Proxy = nil
                end
            end
        end)
    end

    local kopis = gg.kopis.getKopis()
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
    if self.Connection3 then
        self.Connection3:Disconnect()
        self.Connection3 = nil
    end
end

-- Max length 11 (server limit 12)
local lengthSlider = gg.slider.new(gg.ui:WaitForChild("Menu").Settings.kopisResizer.LengthSlider, 0, 11, 2)

lengthSlider:Bind(function(val)
    kopisResizer.Length = val
    if kopisResizer.Activated and kopisResizer.Proxy then
        local clampedLength = math.min(kopisResizer.Length, kopisResizer.MaxServerDistance)
        kopisResizer.Proxy:SetSize(Vector3.new(clampedLength, 0.538, kopisResizer.Thickness))
    end
end)

local thicknessSlider = gg.slider.new(gg.ui:WaitForChild("Menu").Settings.kopisResizer.ThicknessSlider, 0, 2, 2)

thicknessSlider:Bind(function(val)
    kopisResizer.Thickness = val
    if kopisResizer.Activated and kopisResizer.Proxy then
        local clampedLength = math.min(kopisResizer.Length, kopisResizer.MaxServerDistance)
        kopisResizer.Proxy:SetSize(Vector3.new(clampedLength, 0.538, kopisResizer.Thickness))
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
