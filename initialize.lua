--[[
    initialize.lua (FIXED)
    
    Sets up the global environment and loads modules.
    
    Key references needed by other modules:
    - gg.client = LocalPlayer
    - gg.kopis = damage module (with getKopis, getTip, damage, etc.)
    - gg.proxyPart = proxy module
--]]

local environment = {
    modules = {}
}

local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

hookfunction(error, warn)

if getgenv().gg then 
    return warn("Ancient Environment is already loaded")
end

getgenv().gg = environment

-- Set client reference (used by all modules)
gg.client = Players.LocalPlayer

-- Adonis Bypass (New)
local BypassManager = {
    Hooks = {},
    FlagFunction = nil,
    TerminateFunction = nil,
    IsVerbose = true,
}
local StatusTracker = {
    DetectionDisabled = true,
    KillBlocked = true,
    DebugInfoIntercepted = true,
}
local function wrapFunction(target, handler)
    local success, result = pcall(function()
        return hookfunction(target, newcclosure(handler))
    end)
    return success and result
end
local function activateBypass()
    local currentThread = 2
    setthreadidentity(currentThread)
    local collected = getgc(true)
    for _, item in ipairs(collected) do
        if typeof(item) == 'table' then
            local detectionMethod = rawget(item, 'Detected')
            local killMethod = rawget(item, 'Kill')
            if
                typeof(detectionMethod) == 'function'
                and not BypassManager.FlagFunction
            then
                BypassManager.FlagFunction = detectionMethod
                wrapFunction(
                    detectionMethod,
                    function(trigger, details, preventCrash)
                        if trigger ~= '_' and BypassManager.IsVerbose then
                            warn(
                                'Adonis Detected',
                                trigger,
                                'Details::',
                                details
                            )
                        end
                        return true
                    end
                )
                table.insert(BypassManager.Hooks, detectionMethod)
                StatusTracker.DetectionDisabled = true
            end
            if
                typeof(killMethod) == 'function'
                and rawget(item, 'Variables')
                and rawget(item, 'Process')
                and not BypassManager.TerminateFunction
            then
                BypassManager.TerminateFunction = killMethod
                wrapFunction(killMethod, function(cause)
                    if BypassManager.IsVerbose then
                        warn('1)', cause)
                    end
                    return nil
                end)
                table.insert(BypassManager.Hooks, killMethod)
                StatusTracker.KillBlocked = true
            end
        end
    end
    local Returned
    Returned = hookfunction(
        getrenv().debug.info,
        newcclosure(function(...)
            local LevelOrFunc, Info = ...
            if
                BypassManager.FlagFunction
                and LevelOrFunc == BypassManager.FlagFunction
            then
                if BypassManager.IsVerbose then
                    warn('2')
                end
                return coroutine.yield(coroutine.running())
            end
            return Returned(...)
        end)
    )
    StatusTracker.DebugInfoIntercepted = true
    local resetThread = 7
    setthreadidentity(resetThread)
end
activateBypass()
print(
    string.format(
        '1',
        tostring(StatusTracker.DetectionDisabled),
        tostring(StatusTracker.KillBlocked),
        tostring(StatusTracker.DebugInfoIntercepted)
    )
)

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
