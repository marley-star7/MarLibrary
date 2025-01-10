MarLibrary = MarLibrary or {}
MarLibrary.Events = MarLibrary.Events or {}

MarLibrary.Event = {}
MarLibrary.Event.__index = MarLibrary.Event

function MarLibrary.Event.new()
    local instance = setmetatable({}, MarLibrary.Event)
    return instance
end

function MarLibrary.Event:Add(newEventName, newEvent)
    -- Loop over events to find and replace existing event by name
    for _, eventData in ipairs(self) do
        if eventData and eventData[1] == newEventName then
            eventData[2] = newEvent  -- Replace existing event function
            print("MarEvent name same, event replaced.")
            return
        end
    end
    -- No existing event, add a new one
    table.insert(self, {newEventName, newEvent})
end


--=======================--
-- CUSTOM EVENTS --
--=======================--

MarLibrary.Events.OnPlayerUpdateByDelta = MarLibrary.Event.new()

local secondsTillUpdate = 1
local function onPlayerUpdateByDelta(player)
    if secondsTillUpdate >= 1 then
        secondsTillUpdate = 0
        -- Trigger all registered functions for this event
        for _, event in ipairs(MarLibrary.Events.OnPlayerUpdateByDelta) do
            local func = event[2]
            func(player)
        end
    else
        secondsTillUpdate = secondsTillUpdate + getGameTime():getTimeDelta()
    end
end
Events.OnPlayerUpdate.Add(onPlayerUpdateByDelta)

MarLibrary.Events.OnPlayerMoveSquare = MarLibrary.Event.new()
MarLibrary.Events.OnPlayerMoveRoom = MarLibrary.Event.new()

local playerSquare = nil
local playerRoomDef = nil

local function onPlayerMoveSquareRoomUpdate(player)
    if not player:isPlayerMoving() then return end
    local newPlayerSquare = player:getSquare()
    if newPlayerSquare ~= playerSquare then

        playerSquare = newPlayerSquare
        -- Trigger all registered functions for move square event
        for _, event in ipairs(MarLibrary.Events.OnPlayerMoveSquare) do
            local func = event[2]
            func(player, playerSquare)
        end

        -- Check if room has changed inbetween squares.
        local newPlayerRoomDef = player:getCurrentRoomDef()
        if newPlayerRoomDef ~= playerRoomDef then 
            playerRoomDef = newPlayerRoomDef
            -- Trigger all registered functions for move room event
            for _, event in ipairs(MarLibrary.Events.OnPlayerMoveRoom) do
                local func = event[2]
                func(player, playerRoomDef)
            end
        end

    end
end
Events.OnPlayerUpdate.Add(onPlayerMoveSquareRoomUpdate)

MarLibrary.Events.OnPlayerMoveRoom = MarLibrary.Event.new()


MarLibrary.Events.OnZombieGrabBiteAttemptOnPlayer = MarLibrary.Event.new()

local function onZombieGrabBiteAttemptOnPlayer(player)
    if player:getHitReaction() == "" then return end
    -- Trigger all registered functions for this event
    for _, event in ipairs(MarLibrary.Events.OnZombieGrabBiteAttemptOnPlayer) do
        local func = event[2]
        func(player)
    end
end
Events.OnPlayerUpdate.Add(onZombieGrabBiteAttemptOnPlayer)