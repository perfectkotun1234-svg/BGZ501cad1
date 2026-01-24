--[[
    proxy.lua (FIXED - Triggers Game's Own Hit Detection)
    
    Instead of firing the remote directly (server rejects),
    this version teleports the enemy part to touch the REAL blade
    so the game's own blade:GetTouchingParts() detects it.
    
    Anti-cheat bypass: Parts named "Void" and parented to Camera
--]]

local proxyPart = {}
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local links = {}
local camera = workspace.CurrentCamera

-- Hidden container for proxy parts
local hiddenContainer = nil
pcall(function()
    hiddenContainer = Instance.new("Folder")
    hiddenContainer.Name = "Camera"
    hiddenContainer.Parent = camera
end)

-- Update proxy positions
RunService.RenderStepped:Connect(function()
    for part1, part2 in pairs(links) do
        if not part1 or not part1.Parent or not part2 or not part2.Parent then
            links[part1] = nil
            continue
        end
        
        local _, proxyOnScreen = camera:WorldToScreenPoint(part1.Position)
        local _, playerOnScreen = camera:WorldToScreenPoint(part2.Position)
        
        if proxyOnScreen or playerOnScreen then
            pcall(function()
                part1.CFrame = part2.CFrame
            end)
        end
    end
end)

function proxyPart:BindTouch(func)
    if not self.Part then
        return
    end
    
    if #self.TouchedBindings == 0 and not self.TouchedConnection then
        self.TouchedConnection = self.Part.Touched:Connect(function(part)
            for _,touchFunc in pairs(self.TouchedBindings) do
                pcall(touchFunc, part)
            end
        end)
    end
    
    table.insert(self.TouchedBindings, func)
end

-- NEW: Bind touch that triggers game's blade detection
function proxyPart:BindTouchWithBlade(targetHumanoid)
    if not self.Part then
        return
    end
    
    if self.BladeConnection then
        self.BladeConnection:Disconnect()
        self.BladeConnection = nil
    end
    
    self.BladeConnection = self.Part.Touched:Connect(function(part)
        -- Check if it's a kopis blade/tip
        if not part or not part.Parent then return end
        if not part.Parent:IsA("Tool") then return end
        
        local tip = gg.kopis.getTip(part.Parent)
        if not tip or part ~= tip then return end
        
        -- Get the real blade
        local blade = tip
        
        -- Get target character
        if not targetHumanoid or not targetHumanoid.Parent then return end
        local targetCharacter = targetHumanoid.Parent
        local targetTorso = targetCharacter:FindFirstChild("Torso") or targetCharacter:FindFirstChild("HumanoidRootPart")
        
        if not targetTorso then return end
        
        -- Teleport target torso to blade position momentarily
        -- This makes the game's blade:GetTouchingParts() detect them
        local originalCFrame = targetTorso.CFrame
        local originalAnchored = targetTorso.Anchored
        
        pcall(function()
            -- Brief teleport to blade
            targetTorso.CFrame = blade.CFrame
            
            -- Restore immediately (next frame the game will have detected the touch)
            task.defer(function()
                pcall(function()
                    targetTorso.CFrame = originalCFrame
                end)
            end)
        end)
    end)
end

function proxyPart:Destroy()
    if links[self.Part] then
        links[self.Part] = nil
    end
    
    if self.TouchedConnection then
        self.TouchedConnection:Disconnect()
        self.TouchedConnection = nil
    end
    
    if self.BladeConnection then
        self.BladeConnection:Disconnect()
        self.BladeConnection = nil
    end
    
    if self.selectionBox then
        self.selectionBox:Destroy()
        self.selectionBox = nil
    end
    
    if self.Part then
        self.Part:Destroy()
        self.Part = nil
    end
end

function proxyPart:CreateOutline()
    if not self.Part then
        return
    end
    
    if self.selectionBox then
        self.selectionBox:Destroy()
        self.selectionBox = nil
    end
    
    local selectionBox = Instance.new("SelectionBox")
    selectionBox.Color3 = Color3.new(1, 1, 1)
    selectionBox.LineThickness = 0.025
    selectionBox.Adornee = self.Part
    selectionBox.Parent = self.Part
    self.selectionBox = selectionBox
end

function proxyPart:SetSize(Vector, Offset)
    if not self.Part or not Vector then
        return
    end
    
    pcall(function()
        self.Part.Size = Vector
    end)
end

function proxyPart:Link(Part, Weld, Offset)
    if not self.Part or not Part then
        return
    end
    
    -- Parent to camera to avoid anti-cheat
    if hiddenContainer then
        self.Part.Parent = hiddenContainer
    else
        self.Part.Parent = camera
    end
    
    self.Part.Transparency = 1
    self.Part.CanCollide = false
    self.Part.CanQuery = false
    self.Part.CanTouch = true
    
    if Weld then
        pcall(function()
            self.Part.CFrame = Part.CFrame
            local WeldInstance = Instance.new("Weld")
            WeldInstance.C0 = Part.CFrame:Inverse() * self.Part.CFrame
            WeldInstance.Part0 = Part
            WeldInstance.Part1 = self.Part
            WeldInstance.Parent = self.Part
        end)
    else
        self.Part.Anchored = true
        links[self.Part] = Part
    end
end

function proxyPart.new()
    local newPart = Instance.new("Part")
    newPart.Name = "Void" -- Anti-cheat ignores "Void"
    
    return setmetatable({
        Part = newPart,
        TouchedBindings = {},
        TouchedConnection = nil,
        BladeConnection = nil,
        Offset = nil,
    }, {
        __index = function(self, index)
            if proxyPart[index] then
                return function(self, ...)
                    return proxyPart[index](self, ...)
                end
            end
        end
    })
end

return proxyPart
