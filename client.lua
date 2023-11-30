--[[ Warning
    to disable blinkers, change the value to nil ( setElementData(vehicle, data.key, nil) )

    Changelog:
    + small code cleanup
    + fixed blinkers not working ouside dimension/interior 0
    + changed elementdata values to easier comprehension/implementation

    Bugs:
    + due to the way markers are rendered by the game, you can sometimes see them through the vehicle
    + bad behavior on bikes ( blinkers dont lean https://prnt.sc/1gSaZoiYcA_a )
]]

-- General Configurations
local data = {
    key = "blinker",
    left = "left",
    right = "right",
    alert = "alert"
} -- element data

local keys = {
    left = ",", 
    right = ".", 
    alert = "m"
} -- default keys

local config = {
    volume = 0.35,
    distance = 20,
    size = 0.3,
}

local blinkerConfigs = {
    alert = {"light_front_main", "light_rear_main"},
    left = {"light_front_main", "light_rear_main"},
    right = {"light_front_main", "light_rear_main"}
}

local vehicleData = {}

local function isDriver(player)
    local vehicle = getPedOccupiedVehicle(player)
    if vehicle and getVehicleController(vehicle) == player then
        return vehicle
    end
    return false
end

local function playBlinkerSound(vehicle, soundFile)
    local x, y, z = getElementPosition(vehicle)
    local sound = playSound3D(soundFile, x, y, z)
    attachElements(sound, vehicle)
    setSoundVolume(sound, config.volume)
    setElementDimension(sound, getElementDimension(vehicle))
    setElementInterior(sound, getElementInterior(vehicle))
    setSoundMaxDistance(sound, config.distance)
    setSoundMinDistance(sound, config.distance/15)
end

local function toggleVehicleBlinkers(vehicle)
    local markers = vehicleData[vehicle].markers
    for _, blinker in pairs(markers) do
        local r, g, b, a = getMarkerColor(blinker)
        if a ~= 0 then
            setMarkerColor(blinker, 255, 255, 0, 0)
        else
            setMarkerColor(blinker, 255, 255, 0, 150)
        end
    end
    local r, g, b, a = getMarkerColor(markers[1])
    if a ~= 0 then
        playBlinkerSound(vehicle, "audio/pisca-agudo.mp3")
    else
        playBlinkerSound(vehicle, "audio/pisca-grave.mp3")
    end
end

local function createVehicleBlinkers(vehicle, side)
    local dummies = blinkerConfigs[side]
    if not dummies then return end

    vehicleData[vehicle] = {markers = {}, timer = nil}

    for _, dummy in pairs(dummies) do
        local x, y, z = getVehicleDummyPosition(vehicle, dummy)
        for _, side in pairs( (side == data.alert) and {-1, 1} or (side == data.right) and {1} or (side == data.left) and {-1} ) do
            local blinker = createMarker(0, 0, 0, "corona", config.size, 255, 255, 0, 150)
            setElementDimension(blinker, getElementDimension(vehicle))
            setElementInterior(blinker, getElementInterior(vehicle))

            local bikesWorkAround = (getVehicleType(vehicle) == "Bike" or getVehicleType(vehicle) == "Quad") and 0.2*side or 0

            attachElements(blinker, vehicle, side * x + bikesWorkAround, y, z)
            table.insert(vehicleData[vehicle].markers, blinker)
        end
    end

    if isTimer(vehicleData[vehicle].timer) then
        killTimer(vehicleData[vehicle].timer)
    end
    vehicleData[vehicle].timer = setTimer(toggleVehicleBlinkers, 350, 0, vehicle)
end

local function destroyVehicleBlinkers(vehicle)
    local data = vehicleData[vehicle]
    if data then
        for _, blinker in pairs(data.markers) do
            if isElement(blinker) then
                destroyElement(blinker)
            end
        end
        if isTimer(data.timer) then
            killTimer(data.timer)
        end
        data = nil
    end
end

local function prepareData()
    if getElementType(source) == "vehicle" then
        destroyVehicleBlinkers(source)
        local blinker = getElementData(source, data.key)
        if blinker then
            createVehicleBlinkers(source, blinker)
        end
    end
end
addEventHandler("onClientElementStreamIn", root, prepareData)

local function removeData()
    if getElementType(source) == "vehicle" then
        destroyVehicleBlinkers(source)
    end
end
addEventHandler("onClientVehicleExplode", root, removeData)
addEventHandler("onClientElementDestroy", root, removeData)
addEventHandler("onClientElementStreamOut", root, removeData)

local function onResourceStart()
    local vehicles = getElementsByType("vehicle", root, true)
    for _, vehicle in pairs(vehicles) do
        local blinker = getElementData(vehicle, data.key)
        if blinker then
            createVehicleBlinkers(vehicle, blinker)
        end
    end
end
addEventHandler("onClientResourceStart", resourceRoot, onResourceStart)

local function onBlinkerUpdate(key, oldValue, newValue)
    if not (key == data.key and isElement(source) and isElementStreamedIn(source)) then return end
    if not newValue then
        destroyVehicleBlinkers(source)
    end
    if newValue ~= oldValue then
        destroyVehicleBlinkers(source)
        createVehicleBlinkers(source, newValue)
    end
end
addEventHandler("onClientElementDataChange", root, onBlinkerUpdate)

local function updateBlinker(blinker)
    local vehicle = isDriver(localPlayer)
    if vehicle and not isCursorShowing() then
        local currentBlinker = getElementData(vehicle, data.key)
        if currentBlinker == blinker then
            setElementData(vehicle, data.key, nil)
        else
            setElementData(vehicle, data.key, blinker)
        end
    end
end
bindKey(keys.right, "down", function() updateBlinker(data.right) end)
bindKey(keys.left, "down", function() updateBlinker(data.left) end)
bindKey(keys.alert, "down", function() updateBlinker(data.alert) end)