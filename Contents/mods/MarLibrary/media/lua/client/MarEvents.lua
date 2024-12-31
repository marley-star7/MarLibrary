--=======================--
-- CUSTOM EVENTS (sorta) --
--=======================--
-- Yes I know i'm copy pasting and this whole thing is probably more effort than it's worth but I'm tired oaky?

MarEvents = MarEvents or {}

-- God I do NOT feel like I know what I'm doing anymore lol.
MarEvent = {}
MarEvent.__index = MarEvent

function MarEvent.new()
    local instance = setmetatable({}, MarEvent)
    return instance
end

function MarEvent:Add(newEventName, newEvent)
    local size = #self
    for i=0, size do
        local eventData = self[i]
        if eventData and eventData[1] == newEventName then -- 1 is the event name
            self[i] = {newEventName, newEvent}
            print("MarEvent name same, event replaced.")
            return
        end
    end
   self[size + 1] = {newEventName, newEvent}
end

MarEvents.OnPlayerUpdateByDelta = MarEvent.new()

local secondsTillUpdate = 1
local function onPlayerUpdateByDelta(player)
    if secondsTillUpdate >= 1 then
        secondsTillUpdate = 0
        -- TODO: Table thing instead of this
        local size = #MarEvents.OnPlayerUpdateByDelta
        for i=0, size, 1 do 
            local event = MarEvents.OnPlayerUpdateByDelta[i]
            if event then
                local func = event[2]
                func(player)
            end
        end
    else
        secondsTillUpdate = secondsTillUpdate + getGameTime():getTimeDelta()
        return
    end

end
Events.OnPlayerUpdate.Add(onPlayerUpdateByDelta)

MarEvents.OnPlayerMoveSquare = MarEvent.new()

local IsoGridSquare playerSquare = nil
local function onPlayerMoveSquare(player)
    if not player:isPlayerMoving() then return end -- Pretty sure THIS actually does run on any movement.
    local newPlayerSquare = player:getSquare()
    if newPlayerSquare == playerSquare then
        return -- Hasn't moved a square yet RETURN
    else
        playerSquare = newPlayerSquare
        local size = #MarEvents.OnPlayerMoveSquare
        for i=0, size, 1 do 
            local event = MarEvents.OnPlayerMoveSquare[i]
            if event then
                local func = event[2]
                func(player, playerSquare)
            end
        end
    end
end
Events.OnPlayerUpdate.Add(onPlayerMoveSquare) -- We do this instead on player update instead of on player move, because the player can move in other ways besides walking. Which is what the source code does.