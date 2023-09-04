addEventHandler("onResourceStop", resourceRoot, function()
    local vehicles = getElementsByType("vehicle")
    for _, veh in pairs(vehicles) do
        local data = getElementData(veh, "blinker")
        if data then
            removeElementData(veh, "blinker")
        end
    end
end)