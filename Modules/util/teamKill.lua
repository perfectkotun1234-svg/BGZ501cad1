local teamKill = {
    Activated = false,
    Keybind = Enum.KeyCode.C,
}

local UserInputService = game:GetService("UserInputService")

function teamKill:On()
    gg.kopis.teamKill = true
end

function teamKill:Off()
    gg.kopis.teamKill = false
end

local newKeybind = gg.keybinds.newButton(gg.ui.Menu.Settings.teamKill.Keybind, "Team Kill")

newKeybind:Bind(function(key)
    teamKill.Keybind = key
end)

local label

UserInputService.InputBegan:Connect(function(input)
    local TextBoxFocused = UserInputService:GetFocusedTextBox()
    if TextBoxFocused then return end
    local KeyCode = input.KeyCode
    if KeyCode == teamKill.Keybind then
        if teamKill.Activated == false then
            teamKill:On()
            if label then
                label:Destroy()
                label = nil
            end
            label = gg.ui.Templates.TextLabel:Clone()
            label.Text = "Team Kill"
            label.Parent = gg.ui.Overlay:WaitForChild("Active")
            label.Visible = true
        else
            teamKill:Off()
            if label then
                label:Destroy()
                label = nil
            end
        end
        teamKill.Activated = not teamKill.Activated
    end
end)

return teamKill