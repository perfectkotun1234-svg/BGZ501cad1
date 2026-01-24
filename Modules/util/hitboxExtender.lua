local hitboxExtender = {
    Activated = false,
    Keybind = Enum.KeyCode.X,
    Parts = {},
    DiedBinds = {},
    Size = 10,
    Cooldown = os.clock(),
    CharacterAdded = {}
}

local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

function hitboxExtender:Off()
    if hitboxExtender.PlayerAdded then
        hitboxExtender.PlayerAdded:Disconnect()
        hitboxExtender.PlayerAdded = nil
    end
    for _, added in pairs(hitboxExtender.CharacterAdded) do
        if added and added.Connected then
            added:Disconnect()
        end
    end
    for _,func in pairs(hitboxExtender.DiedBinds) do
        if func and func.Connected then
            func:Disconnect()
        end
    end
    for _, proxy in pairs(hitboxExtender.Parts) do
        if proxy then
            proxy:Destroy()
        end
    end
    hitboxExtender.Parts = {}
    hitboxExtender.DiedBinds = {}
    hitboxExtender.CharacterAdded = {}
end

function hitboxExtender:On()
    local function createHitbox(player)
        if player == gg.client then
            return
        end
        
        local character = player.Character
        if not character then return end
        
        local humanoidRootPart = character:FindFirstChild("HumanoidRootPart") or character:FindFirstChild("Torso")
        local humanoid = character:FindFirstChild("Humanoid")
        
        if not humanoidRootPart or not humanoid then return end
        
        local proxy = gg.proxyPart.new()
        proxy:Link(humanoidRootPart)
        proxy:SetSize(Vector3.new(self.Size, self.Size, self.Size))
        proxy:CreateOutline()
        proxy:BindTouch(function(part)
            if part.Parent and part.Parent:IsA("Tool") then
                local tip = part.Parent:FindFirstChild("Tip", true)
                if tip and part == tip then
                    gg.kopis.damage(humanoid, part)
                end
            end
        end)
        
        local deathBind = humanoid.Died:Connect(function()
            proxy:Destroy()
        end)
        
        table.insert(hitboxExtender.DiedBinds, deathBind)
        table.insert(hitboxExtender.Parts, proxy)
    end
    
    for _, player in pairs(Players:GetPlayers()) do
        if player ~= gg.client then
            createHitbox(player)
            local added = player.CharacterAdded:Connect(function()
                task.wait(0.5)
                createHitbox(player)
            end)
            table.insert(hitboxExtender.CharacterAdded, added)
        end
    end
    
    hitboxExtender.PlayerAdded = Players.PlayerAdded:Connect(function(player)
        if player ~= gg.client then
            player.CharacterAdded:Wait()
            task.wait(0.5)
            createHitbox(player)
            local added = player.CharacterAdded:Connect(function()
                task.wait(0.5)
                createHitbox(player)
            end)
            table.insert(hitboxExtender.CharacterAdded, added)
        end
    end)
end

local newKeybind = gg.keybinds.newButton(gg.ui.Menu.Settings.hitboxExtender.Keybind, "Hitbox Extender")

newKeybind:Bind(function(key)
    hitboxExtender.Keybind = key
end)

local newSlider = gg.slider.new(gg.ui:WaitForChild("Menu").Settings.hitboxExtender.Slider, 5, 15, 1)

newSlider:Bind(function(val)
    hitboxExtender.Size = val
    for _,proxy in pairs(hitboxExtender.Parts) do
        if proxy then
            proxy:SetSize(Vector3.new(hitboxExtender.Size, hitboxExtender.Size, hitboxExtender.Size))
        end
    end
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