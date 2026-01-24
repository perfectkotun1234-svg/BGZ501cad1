local slider = {}

function slider:Bind(func)
    table.insert(self.functions, func)
end

function slider:Track()
    if not self.Ui then
        return
    end
    
    local Mouse = gg.client:GetMouse()
    
    self.TrackConnection = Mouse.Move:Connect(function()
        local x,y = Mouse.X, Mouse.Y
        local Circle = self.Ui.Circle
        local bar_size = self.Ui.Total.AbsoluteSize
        local bar_start, bar_end = self.Ui.Total.AbsolutePosition,  self.Ui.Total.AbsolutePosition + bar_size
        local distance = bar_end.X - bar_start.X
        local difference_mouse = x - bar_start.X
        local percent = difference_mouse / (bar_size.X)
        percent = math.clamp(percent, 0, 1)
        
        Circle.Position = UDim2.new(percent, 0, 0.5, 0)
        self.Ui.SliderBar.Size = UDim2.new(percent, 0, 0.1, 0)
        
        if #self.functions > 0 then
            local val = self.minimum + ((self.maximum - self.minimum) * percent)
            
            for _, func in pairs(self.functions) do
                if self.Ui:FindFirstChild("Count") then
                    self.Ui.Count.Position = self.Ui.Circle.Position + UDim2.new(0, 0, 0.583, 0)
                    
                    if self.round then
                        local mult = 10 ^ (self.round or 0)
                        val = math.floor(val * mult + 0.5) / mult
                    end
                    
                    if self.percentage then
                        self.Ui.Count.Text = tostring(val).."%"
                    else
                        self.Ui.Count.Text = tostring(val)
                    end
                end
                
                func(val)
            end
        end
    end)
end

function slider.new(ui, minimum, maximum, round, percentage)
    if not ui or not maximum then
        return warn("Invalid specified UI/Maximum in slider")
    end
    
    local circle = ui:FindFirstChild("Circle")
    
    if not circle then
        warn("No Circle found in slider UI")
        return nil
    end
    
    local newSlider = setmetatable({
        Ui = ui,
        maximum = maximum,
        minimum = minimum,
        functions = {},
        round = round,
        percentage = percentage,
    }, {
        __index = function(self, index)
            if slider[index] then
                return function(self, ...)
                    slider[index](self, ...)
                end
            end
        end
    })
    
    circle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            newSlider:Track()
        end
    end)
    
    circle.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            if newSlider.TrackConnection then
                newSlider.TrackConnection:Disconnect()
                newSlider.TrackConnection = nil
            end
        end
    end)
    
    return newSlider
end

return slider