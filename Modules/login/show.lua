local ui = gg.ui

local loading = ui:WaitForChild("Loading")
loading.Visible = true

local SETTINGS = {
    BEGINNING_DELAY = 0,
    LOADING_DELAY = 2.5,
}

ui.Parent = game:GetService("CoreGui")
loading.Size = UDim2.new(0, 0, 0, 0)

wait(SETTINGS.BEGINNING_DELAY)

loading:TweenSize(UDim2.new(0, 263, 0, 263), "Out", "Back", 2, true)

wait(SETTINGS.LOADING_DELAY)

loading.Goat:TweenSize(UDim2.new(0, 0, 0, 0), "In", "Back", 0.3, true)

loading:TweenSize(UDim2.new(0, 321, 0, 373), "In", "Linear", 0.4, true)

for i = loading.Circle.SliceScale, 0.4, -.1 do
    wait()
    loading.Circle.SliceScale = i
end

loading.Header.Visible = true
loading.Header.TextTransparency = 1

spawn(function()
    for i = loading.Header.TextTransparency, 0, -.1 do
        wait()
        loading.Header.TextTransparency = i
    end
end)

loading.TokenInputBox.Size = UDim2.new(0, 0, 0.107, 0)
loading.TokenInputBox.Visible = true

loading.TokenInputBox:TweenSize(UDim2.new(.821, 0, .107, 0), "In", "Linear", 0.2, true)

wait(.2)

loading.LockIcon.Size = UDim2.new(0, 0, 0, 0)
loading.LockIcon.Visible = true

wait()
loading.LockIcon:TweenSize(UDim2.new(.077, 0, .062, 0), "Out", "Back", 0.2, true)

loading.Input.Visible = true
loading.Input.TextTransparency = 1

spawn(function()
    for i = loading.Input.TextTransparency, 0, -.1 do
        wait()
        loading.Input.TextTransparency = i
    end
end)
