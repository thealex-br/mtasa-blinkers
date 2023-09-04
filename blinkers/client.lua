local blinkerConfigs = {
    ["0"] = {"light_front_main", "light_rear_main"},
    ["1"] = {"light_front_main", "light_rear_main"},
    ["2"] = {"light_front_main", "light_rear_main"}
}

local vehicleBlinkers = {}
local vehicleBlinkerTimers = {}

function toggleVehicleBlinkers(vehicle)
    for _, blinker in pairs(vehicleBlinkers[vehicle]) do
        local r, g, b, a = getMarkerColor(blinker)
        if a ~= 0 then
            setMarkerColor(blinker, 255, 255, 0, 0)
            playBlinkerSound(vehicle, "audio/pisca-grave.mp3")
        else
            setMarkerColor(blinker, 255, 255, 0, 150)
            playBlinkerSound(vehicle, "audio/pisca-agudo.mp3")
        end
    end
end

function createVehicleBlinkers(vehicle, blinkerConfig)
    vehicleBlinkers[vehicle] = {}

    local dummies = blinkerConfigs[tostring(blinkerConfig)]
    if not dummies then return end
    for _, dummy in pairs(dummies) do
        local x, y, z = getVehicleDummyPosition(vehicle, dummy)
        local side = blinkerConfig == 0 and {-1, 1} or {1}

        for _, s in pairs(side) do
            if blinkerConfig == 2 then x = -1 * x end
            local light = createMarker(Vector3(0 ,0 ,0), "corona", 0.15, 255, 255, 0, 150)
            attachElements(light, vehicle, s * x, y, z)
            table.insert(vehicleBlinkers[vehicle], light)
        end
    end

    if isTimer(vehicleBlinkerTimers[vehicle]) then
        killTimer(vehicleBlinkerTimers[vehicle])
        vehicleBlinkerTimers[vehicle] = nil
    end

    vehicleBlinkerTimers[vehicle] = setTimer(toggleVehicleBlinkers, 350, 0, vehicle)
end

function destroyVehicleBlinkers(vehicle)
    if not vehicleBlinkers[vehicle] then
        return
    end
    for _, blinker in pairs(vehicleBlinkers[vehicle]) do
        if isElement(blinker) then
            destroyElement(blinker)
        end
    end
    vehicleBlinkers[vehicle] = {}
    if vehicleBlinkerTimers[vehicle] then
        killTimer(vehicleBlinkerTimers[vehicle])
        vehicleBlinkerTimers[vehicle] = nil
    end
end

function playBlinkerSound(vehicle, soundFile)
    local x, y, z = getElementPosition(vehicle)
    local sound = playSound3D(soundFile, x, y, z)
    attachElements(sound, vehicle)
    setSoundVolume(sound, 0.35)
    setElementDimension(sound, getElementDimension(vehicle))
    setElementInterior(sound, getElementInterior(vehicle))
    setSoundMaxDistance(sound, 20)
    setSoundMinDistance(sound, 8.0)
end

local function onVehicleStreamIn()
    if getElementType(source) ~= "vehicle" then return end
    destroyVehicleBlinkers(source)
    local blinkerValue = getElementData(source, "blinker")
    if blinkerValue then
        createVehicleBlinkers(source, blinkerValue)
    end
end
addEventHandler("onClientElementStreamIn", root, onVehicleStreamIn)

addEventHandler("onClientElementStreamOut", root, function()
    if getElementType(source) ~= "vehicle" then return end
    destroyVehicleBlinkers(source)
end)

addEventHandler("onClientElementDestroy", root, function()
    if getElementType(source) ~= "vehicle" then return end
    destroyVehicleBlinkers(source)
end)

addEventHandler("onClientVehicleExplode", root, function()
    if getElementType(source) ~= "vehicle" then return end
    destroyVehicleBlinkers(source)
end)

function onElementDataChange(key, oldValue, newValue)
    if key ~= "blinker" or not isElement(source) or not isElementStreamedIn(source) then return end
    if not newValue or newValue == "off" then
        destroyVehicleBlinkers(source)
    end
    if newValue ~= oldValue then
        destroyVehicleBlinkers(source)
        createVehicleBlinkers(source, newValue)
    end
end
addEventHandler("onClientElementDataChange", root, onElementDataChange)

bindKey(",", "down", function()
    local veh = getPedOccupiedVehicle(localPlayer)
    if veh and getVehicleController(veh) ~= localPlayer then return end
    local blinker = getElementData(veh, "blinker")
    if blinker == 2 then
        setElementData(veh, "blinker", "off")
    else
        setElementData(veh, "blinker", 2)
    end
end)

bindKey(".", "down", function()
    local veh = getPedOccupiedVehicle(localPlayer)
    if veh and getVehicleController(veh) ~= localPlayer then return end
    local blinker = getElementData(veh, "blinker")
    if blinker == 1 then
        setElementData(veh, "blinker", "off")
    else
        setElementData(veh, "blinker", 1)
    end
end)

bindKey("m", "down", function()
    local veh = getPedOccupiedVehicle(localPlayer)
    if veh and getVehicleController(veh) ~= localPlayer then return end
    local blinker = getElementData(veh, "blinker")
    if blinker == 0 then
        setElementData(veh, "blinker", "off")
    else
        setElementData(veh, "blinker", 0)
    end
end)