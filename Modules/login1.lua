--[[
    login.lua
    @author kalli666 
--]]

local ui = gg.ui

if not ui then
    return warn("Failure whilst loading Battleground Zero UI")
end

gg.load("Modules/login/show")

local loading = gg.ui:WaitForChild("Loading")

function loadModules()
    gg.keybinds = gg.load("Modules/keybinds")
    gg.client = game:GetService("Players").LocalPlayer
    gg.slider = gg.load("Modules/slider")
    gg.proxyPart = gg.load("Modules/kopis/proxy")
    gg.load("Modules/menu")
end

local tokenInputBox = loading:WaitForChild("TokenInputBox")
local inputBox = loading:WaitForChild("Input")

loading.Input.FocusLost:connect(function()
    local response = loading.Input.Text
    if response == "kalli67" then
        loadModules()
        gg.load("Modules/login/hide")
    end
end)
