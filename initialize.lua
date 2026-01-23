--[[
    initialize.lua
    @author kalli666
--]]

local environment = {
    modules = {}
}

local RunService = game:GetService("RunService")

hookfunction(error, warn)

if getgenv().gg then return end

getgenv().gg = environment

--bypassing adonis (old)
local function checkErrorConnections()
    local Connections = getconnections(game:GetService("ScriptContext").Error)
    if #Connections > 0 then
        for ConnectionKey, Connection in pairs(Connections) do
            Connection:Disable()
        end
    else
        return false
    end
    
    return true
end

task.spawn(function()
    local errorConnections = checkErrorConnections()
    while RunService.RenderStepped:Wait() do
        if errorConnections then
            errorConnections = checkErrorConnections()
        end
    end
end)

function environment.load(path)
    if not path then
        return warn("Invalid Pathway for loading module")
    end
    
    if type(path) == "string" then
        print("Loading "..path)
        local succ, response = pcall(function()
            return game:HttpGetAsync("https://github.com/prosecutioned/ancient".. path ..".lua")
        end)
        
        if succ and response then
            local loadSuccess, result = pcall(function()
                return loadstring(response)()
            end)
            
            if loadSuccess then
                return result
            else
                warn("Error whilst executing '"..path.. "' : "..tostring(result))
                return nil
            end
        else
            warn("Error whilst loading '"..path.. "' : "..tostring(response))
            return nil
        end
    elseif type(path) == "number" then
        local success, asset = pcall(function()
            return game:GetObjects("rbxassetid://" .. path)[1]
        end)
        if success then
            return asset
        else
            warn("Error loading asset ID "..path..": "..tostring(asset))
            return nil
        end
    end
end

gg.ui = environment.load(4735247703)
gg.modules.login = environment.load("Modules")