local accuracy = {
    Activated = false,
    Keybind = Enum.KeyCode.L,
}

local UserInputService = game:GetService("UserInputService")
local InputConnection
local cooldown = os.clock()
local Gyro
local Current = 0

function accuracy:On()
    InputConnection = UserInputService.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            local kopis = gg.kopis.getKopis()
            if not kopis then
                return
            end
            
            Current = Current + 1
            
            local client = gg.client
            local clientCharacter = client.Character
            if not clientCharacter then
                return
            end
            
            local clientRoot = clientCharacter:FindFirstChild("HumanoidRootPart") or clientCharacter:FindFirstChild("Torso")
            if not clientRoot then
                return
            end
            
            if not Gyro then
                Gyro = Instance.new("BodyGyro")
                Gyro.Parent = clientRoot
                Gyro.D = 500
                Gyro.P = 30000
            end
            
            local target, dis = nil, math.huge
            for _,player in pairs(game:GetService("Players"):GetPlayers()) do
                if player ~= client and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
                    local humanoidRootPart = player.Character:FindFirstChild("HumanoidRootPart") or player.Character:FindFirstChild("Torso")
                    if humanoidRootPart then
                        local distance = (humanoidRootPart.Position - clientRoot.Position).Magnitude
                        if distance < dis then
                            target, dis = player, distance
                        end
                    end
                end
            end
            
            if not target then
                return
            end
            
            local targetRoot = target.Character:FindFirstChild("HumanoidRootPart") or target.Character:FindFirstChild("Torso")
            if not targetRoot then
                return
            end
            
            local targetCFrame = targetRoot.CFrame
            local inverse = targetCFrame:Inverse()
            Gyro.MaxTorque = Vector3.new(0, 20000, 0)
            Gyro.CFrame = CFrame.Angles(0, math.rad(180), 0) * inverse
            
            task.spawn(function()
                local savedCurrent = Current
                task.wait(0.3)
                if Current == savedCurrent and Gyro then
                    Gyro.MaxTorque = Vector3.new(0, 0, 0)
                end
            end)
        end
    end)
end

function accuracy:Off()
    if InputConnection then
        InputConnection:Disconnect()
        InputConnection = nil
    end
    if Gyro then
        Gyro:Destroy()
        Gyro = nil
    end
end

local newKeybind = gg.keybinds.newButton(gg.ui.Menu.Settings.accuracy.Keybind, "Accuracy")

newKeybind:Bind(function(key)
    accuracy.Keybind = key
end)

local label

UserInputService.InputBegan:Connect(function(input)
    local TextBoxFocused = UserInputService:GetFocusedTextBox()
    if TextBoxFocused then return end
    local KeyCode = input.KeyCode
    if KeyCode == accuracy.Keybind then
        if accuracy.Activated == false then
            accuracy:On()
            if label then
                label:Destroy()
                label = nil
            end
            label = gg.ui.Templates.TextLabel:Clone()
            label.Text = "Accuracy"
            label.Parent = gg.ui.Overlay:WaitForChild("Active")
            label.Visible = true
        else
            accuracy:Off()
            if label then
                label:Destroy()
                label = nil
            end
        end
        accuracy.Activated = not accuracy.Activated
    end
end)

return accuracy