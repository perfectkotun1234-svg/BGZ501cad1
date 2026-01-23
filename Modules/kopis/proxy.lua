--[[
    proxy.lua
    @author kalli666
--]]

local proxyPart = {}
local RunService = game:GetService("RunService")
local links = {}
local camera = workspace.CurrentCamera

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

function proxyPart:Destroy()
    if links[self.Part] then
        links[self.Part] = nil
    end
    
    if self.TouchedConnection then
        self.TouchedConnection:Disconnect()
        self.TouchedConnection = nil
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
    
    self.Part.Parent = game:GetService("Workspace")
    self.Part.Transparency = 1
    self.Part.CanCollide = false
    
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
    newPart.Name = "ProxyPart"
    
    return setmetatable({
        Part = newPart,
        TouchedBindings = {},
        TouchedConnection = nil,
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