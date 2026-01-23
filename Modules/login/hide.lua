--[[
    hide.lua
    @author kalli666
]]

local Ui = gg.ui
local loading = Ui:WaitForChild("Loading")
local RunService = game:GetService("RunService")

task.wait()

local lockIcon = loading:FindFirstChild("LockIcon")
if lockIcon then
    lockIcon:TweenSize(UDim2.new(0, 0, 0, 0), Enum.EasingDirection.In, Enum.EasingStyle.Back, 0.2, true)
end

local tokenInputBox = loading:FindFirstChild("TokenInputBox")
local input = loading:FindFirstChild("Input")

if input then
    task.spawn(function()
        for i = input.TextTransparency, 1, 0.1 do
            task.wait()
            input.TextTransparency = i
        end
    end)
end

if tokenInputBox then
    tokenInputBox:TweenSize(UDim2.new(0, 0, 0.107, 0), Enum.EasingDirection.In, Enum.EasingStyle.Linear, 0.2, true)
end

local header = loading:FindFirstChild("Header")
if header then
    for i = header.TextTransparency, 1, 0.05 do
        RunService.RenderStepped:Wait()
        header.TextTransparency = i
    end
end

loading:TweenSize(UDim2.new(0, 0, 0, 0), Enum.EasingDirection.In, Enum.EasingStyle.Back, 0.6, true)

task.wait(0.6)
loading:Destroy()

Ui.Overlay.Visible = true

local goat = Ui.Overlay:FindFirstChild("Goat")
if goat then
    goat.Size = UDim2.new(0, 0, 0, 0)
    goat:TweenSize(UDim2.new(0.211, 0, 0.211, 0), Enum.EasingDirection.Out, Enum.EasingStyle.Back, 0.3, true)
end
