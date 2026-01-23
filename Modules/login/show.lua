--[[
    show.lua
    @author kalli666
]]

local ui = gg.ui
local loading = ui:WaitForChild("Loading")

local SETTINGS = {
    BEGINNING_DELAY = 0,
    LOADING_DELAY = 2.5,
}

ui.Parent = game:GetService("CoreGui")

loading.Visible = true
loading.Size = UDim2.new(0, 0, 0, 0)

task.wait(SETTINGS.BEGINNING_DELAY)

loading:TweenSize(UDim2.new(0, 263, 0, 263), Enum.EasingDirection.Out, Enum.EasingStyle.Back, 2, true)

task.wait(SETTINGS.LOADING_DELAY)

local goat = loading:FindFirstChild("Goat")
if goat then
    goat:TweenSize(UDim2.new(0, 0, 0, 0), Enum.EasingDirection.In, Enum.EasingStyle.Back, 0.3, true)
end

loading:TweenSize(UDim2.new(0, 321, 0, 373), Enum.EasingDirection.In, Enum.EasingStyle.Linear, 0.4, true)

local circle = loading:FindFirstChild("Circle")
if circle then
    for i = circle.ImageTransparency, 0.6, 0.1 do
        task.wait()
        circle.ImageTransparency = i
    end
end

local header = loading:FindFirstChild("Header")
if header then
    header.Visible = true
    header.TextTransparency = 1
    
    task.spawn(function()
        for i = 1, 0, -0.1 do
            task.wait()
            header.TextTransparency = i
        end
    end)
end

local tokenInputBox = loading:FindFirstChild("TokenInputBox")
if tokenInputBox then
    tokenInputBox.Size = UDim2.new(0, 0, 0.107, 0)
    tokenInputBox.Visible = true
    tokenInputBox:TweenSize(UDim2.new(0.821, 0, 0.107, 0), Enum.EasingDirection.In, Enum.EasingStyle.Linear, 0.2, true)
end

task.wait(0.2)

local lockIcon = loading:FindFirstChild("LockIcon")
if lockIcon then
    lockIcon.Size = UDim2.new(0, 0, 0, 0)
    lockIcon.Visible = true
    task.wait()
    lockIcon:TweenSize(UDim2.new(0.077, 0, 0.062, 0), Enum.EasingDirection.Out, Enum.EasingStyle.Back, 0.2, true)
end

if tokenInputBox then
    local input = tokenInputBox:FindFirstChild("Input")
    if input then
        input.Visible = true
        input.TextTransparency = 1
        
        task.spawn(function()
            for i = 1, 0, -0.1 do
                task.wait()
                input.TextTransparency = i
            end
        end)
    end
end