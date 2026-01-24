--[[
    initialize.lua (CLEAN VERSION)
    
    Removed problematic hooks that were breaking the game.
--]]

local environment = {
    modules = {}
}

local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

-- REMOVED: hookfunction(error, warn) - This was breaking things!

if getgenv().gg then 
    return warn("Ancient Environment is already loaded")
end

getgenv().gg = environment

-- Set client reference (used by all modules)
gg.client = Players.LocalPlayer

-- Adonis Bypass (Simplified - no debug.info hook)
local function activateBypass()
    pcall(function()
        local collected = getgc(true)
        for _, item in ipairs(collected) do
            if typeof(item) == 'table' then
                local detectionMethod = rawget(item, 'Detected')
                local killMethod = rawget(item, 'Kill')
                
                if typeof(detectionMethod) == 'function' then
                    pcall(function()
                        hookfunction(detectionMethod, newcclosure(function()
                            return true
                        end))
                    end)
                end
                
                if typeof(killMethod) == 'function' and rawget(item, 'Variables') and rawget(item, 'Process') then
                    pcall(function()
                        hookfunction(killMethod, newcclosure(function()
                            return nil
                        end))
                    end)
                end
            end
        end
    end)
end

pcall(activateBypass)

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

-- Load UI
gg.ui = environment.load(4735247703)

-- Load login module
gg.modules.login = environment.load("Modules/login1")
