--[[
    menu.lua
    @author kalli666 
--]]

local menu = {
    ui = gg.ui:WaitForChild("Menu"),
    Modules = {},
    loadedButtons = {}
}

local loaded = false

function bindButtons()
    local side = menu.ui.Side
    local combatButtons = side.Combat
    
    for _,button in pairs(combatButtons:GetChildren()) do
        if button:IsA("TextButton") then
            if not menu.loadedButtons[button] then
                local succ = gg.load("Modules/util/"..tostring(button.Name))
                
                if succ then
                    print("Binding Selection Button : "..button.Name )
                    local settings = menu.ui.Settings
                    
                    button.MouseButton1Down:Connect(function()
                        if settings:FindFirstChild(button.Name) then
                            for _,v in pairs(settings:GetChildren()) do
                                if v:IsA("Frame") then
                                    v.Visible = false
                                end
                            end
                            
                            settings:FindFirstChild(button.Name).Visible = true
                            
                            for i,v in pairs(menu.ui.Side.Combat:GetChildren()) do
                                if v:IsA("TextButton") then
                                    v.Font = Enum.Font.SourceSansLight
                                end
                            end
                            
                            local sideCombatButton = menu.ui.Side.Combat:FindFirstChild(button.Name)
                            if sideCombatButton then
                                sideCombatButton.Font = Enum.Font.SourceSans
                                local currentSidePosition = menu.ui.Side.SideSelection.Position
                                menu.ui.Side.SideSelection:TweenPosition(
                                    UDim2.new(0.986, 0, sideCombatButton.Position.Y.Scale, 0),
                                    Enum.EasingDirection.Out,
                                    Enum.EasingStyle.Quad,
                                    0.2,
                                    true
                                )
                            end
                        end
                    end)
                    
                    menu.loadedButtons[button] = true
                end
            end
        end
    end
end

gg.keybinds:Bind(Enum.KeyCode.E, function()
    menu.ui.Visible = not menu.ui.Visible
    
    if loaded == false then
        gg.kopis = gg.load("Modules/kopis/damage")
        bindButtons()
    end
    
    loaded = true
end)

return menu