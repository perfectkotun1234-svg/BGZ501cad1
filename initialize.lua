--[[
    initialize.lua
--]]

local environment = {
    modules = {}
}

local RunService = game:GetService("RunService")

hookfunction(error, warn)

if getgenv().gg then 
    return warn("Ancient Environment is already loaded")
end

getgenv().gg = environment

-- Bypassing adonis (old)
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
        local url = "https://raw.githubusercontent.com/perfectkotun1234-svg/BGZ501cad1/main/".. path ..".lua"
        
        local succ, response = pcall(function()
            return game:HttpGetAsync(url)
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
gg.modules.login = environment.load("Modules/login1")