--[[
    keybinds.lua
    @author kalli666
--]]

local UserInputService = game:GetService("UserInputService")

local keybinds = {
    binds = {},
    functionNames = {}
}

local Button = {}
local bindingKey = nil

function Button:Bind(func)
    table.insert(self.Bindings, func)
end

function keybinds.newButton(ui, value)
    if not ui then
        warn("Invalid UI for keybind button")
        return nil
    end
    
    local keybindButton = ui:FindFirstChild("Keybind")
    if not keybindButton then
        warn("No Keybind button found in UI")
        return nil
    end
    
    local newButton = setmetatable({
        Function = nil,
        Bindings = {}
    }, {
        __index = Button
    })
    
    newButton.Function = keybindButton.MouseButton1Down:Connect(function()
        local alert = gg.ui.Menu:FindFirstChild("Alert")
        if alert then
            alert.Text = "Press any key to bind ".. value .."."
            alert.Visible = true
        end
        
        bindingKey = {ui, newButton}
    end)
    
    return newButton
end

UserInputService.InputBegan:Connect(function(input)
    local TextBoxFocused = UserInputService:GetFocusedTextBox()
    if TextBoxFocused then return end
    
    local keyCode = input.KeyCode
    
    if keyCode and bindingKey and keyCode ~= Enum.KeyCode.Unknown then
        local ui = bindingKey[1]
        local meta = bindingKey[2]
        
        if ui then
            local alert = gg.ui.Menu:FindFirstChild("Alert")
            if alert and alert.Visible == true then
                alert.Visible = false
            end
            
            local keybindButton = ui:FindFirstChild("Keybind")
            if keybindButton then
                keybindButton.Text = UserInputService:GetStringForKeyCode(keyCode)
            end
            
            bindingKey = nil
            
            if meta then
                for _, func in pairs(meta.Bindings) do
                    func(keyCode)
                end
            end
        end
    elseif keyCode then
        local funcs = keybinds.binds[keyCode]
        if funcs then
            for _, func in pairs(funcs) do
                func()
            end
        end
    end
end)

function keybinds:Bind(key, func, functionName)
    if not key or not func then
        return warn("Invalid keybind binding")
    end
    
    if functionName and not self.functionNames[functionName] then
        self.functionNames[functionName] = key
    end
    
    if not self.binds[key] then
        self.binds[key] = {}
    end
    
    table.insert(self.binds[key], func)
end

return keybinds