--[[
    kopisResizer.lua (FIXED - Uses Game's Own Detection)
    
    Creates extended blade proxy.
    When proxy touches enemy, teleports enemy to real blade
    so game's own detection registers the hit.
    
    Does NOT resize actual blade (avoids anti-cheat).
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
    CurrentTarget = nil,
}

local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

gg.getKopisResizerData = function()
    return kopisResizer
end

function kopisResizer:On()
    local function createProxy(kopisTool)
        if not kopisTool then return end
        
        local tip = gg.kopis.getTip(kopisTool)
        if not tip then return end
        
        if kopisResizer.Proxy then
            kopisResizer.Proxy:Destroy()
            kopisResizer.Proxy = nil
        end
        
        local proxy = gg.proxyPart.new()
        proxy:Link(tip, true)
        proxy:SetSize(Vector3.new(kopisResizer.Length, 0.538, kopisResizer.Thickness))
        proxy:CreateOutline()
        
        -- When proxy touches enemy, teleport them to real blade
        proxy:BindTouch(function(obj)
            if not obj or not obj.Parent then return end
            
            -- Find humanoid
            local character = obj.Parent
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
            
            -- Get target torso
            local targetTorso = character:FindFirstChild("Torso") or character:FindFirstChild("HumanoidRootPart")
            if not targetTorso then return end
            
            -- Teleport target to blade momentarily
            local originalCFrame = targetTorso.CFrame
            
            pcall(function()
                targetTorso.CFrame = tip.CFrame
                
                task.defer(function()
                    pcall(function()
                        targetTorso.CFrame = originalCFrame
                    end)
                end)
            end)
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

local lengthSlider = gg.slider.new(gg.ui:WaitForChild("Menu").Settings.kopisResizer.LengthSlider, 0, 15, 2)

lengthSlider:Bind(function(val)
    kopisResizer.Length = val
    if kopisResizer.Activated and kopisResizer.Proxy then
        kopisResizer.Proxy:SetSize(Vector3.new(kopisResizer.Length, 0.538, kopisResizer.Thickness))
    end
end)

local thicknessSlider = gg.slider.new(gg.ui:WaitForChild("Menu").Settings.kopisResizer.ThicknessSlider, 0, 2, 2)

thicknessSlider:Bind(function(val)
    kopisResizer.Thickness = val
    if kopisResizer.Activated and kopisResizer.Proxy then
        kopisResizer.Proxy:SetSize(Vector3.new(kopisResizer.Length, 0.538, kopisResizer.Thickness))
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
