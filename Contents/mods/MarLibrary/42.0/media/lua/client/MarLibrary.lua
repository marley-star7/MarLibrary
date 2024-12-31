MarLibrary = MarLibrary or {}

-- TODO: This "fix" only works for moving up and down and honestly? I have NO idea how its even breaking to know how to properly fix it.
-- Bug where move direction returns a wrong value when aiming which seems to be left from the correct direction when aiming so we fix it here with this
MarLibrary.getCorrectPlayerMoveIsoDir = function(player)
    if player:isAiming() then
        return IsoDirections.reverse(IsoDirections.RotRight(IsoDirections.fromAngle(player:getPlayerMoveDir())))
    else
        return IsoDirections.fromAngle(player:getPlayerMoveDir())
    end
end

-- TODO: Pretty sure that "EveryOneMinute" event breaks timing on time scale changing sooooooo, we do this instead, but find that out yeh?

MarLibrary.tableContains = function(table, checkContain)
    for _, value in pairs(table) do
        if value == checkContain then
            return true
        end
    end
    return false
end

MarLibrary.delayFunc = function(func, delay, ...)
    -- delay is default to 1 if not provided
    delay = delay or 1
    
    local params = {...}
    if ... ~= nil then 
        params = {...}
    end
    
    local ticks = 0
    local canceled = false

    -- The function that gets called on every tick
    local function onTick()

        if not canceled and ticks < delay then
            ticks = ticks + 1
            return
        end

        -- Remove this handler from the OnTick event
        Events.OnTick.Remove(onTick)
        
        if not canceled then
            -- Call the function with the captured parameters
            if params then
                func(unpack(params))
            else
                func()
            end
        end
    end

    -- Add the onTick function to the OnTick event
    Events.OnTick.Add(onTick)
    
    -- Return the cancel function
    return function()
        canceled = true
    end
end

MarLibrary.delayFuncByDelta = function(func, delay, ...)
    -- delay is default to 1 if not provided
    delay = delay or 1
    
    -- Capture the custom parameters passed to func
    local params 
    if ... ~= nil then 
        params = {...}
    end
    
    local time = 0
    local canceled = false

    -- The function that gets called on every tick
    local function onTick()
        
        if not canceled and time < delay then
            time = time + getGameTime():getTimeDelta()  -- Increment time by delta
            return
        end

        -- Remove this handler from the OnTick event
        Events.OnTick.Remove(onTick)

        if not canceled then
            -- Call the function with the captured parameters
            if params then
                func(unpack(params))
            else
                func()
            end
        end
    end

    -- Add the onTick function to the OnTick event
    Events.OnTick.Add(onTick)
    
    -- Return the cancel function
    return function()
        canceled = true
    end
end

--===================--
-- JACKASS FUNCTIONS --
--===================--

local function chance(percentage)
    if percentage >= ZombRand(1,100) then
        return true
    else
        return false
    end
end

MarLibrary.bump = function(player)
    if chance(50) then bumpType = 'left' else bumpType = 'right' end
    player:setBumpFallType('FallForward')
    player:setBumpType(bumpType)
    player:setBumpDone(false)
    player:setBumpFall(false)
    player:reportEvent('wasBumped')
end

MarLibrary.fallOnKneesOrBack = function(player)
    player:setBumpDone(false)
    player:setSprinting(false)
    player:setKnockedDown(true)
    player:helmetFall(chance(10))
    -- If the player is looking away from the tripped object they fall backwards
    playerSquare = player:getSquare()
    playerLookAngleVector2 = player:getLastAngle()
    playerDirToCenterOfSquare = Vector2.new(player:getX() - playerSquare:getX() - .5, player:getY() - playerSquare:getY() - .5)
    if (playerLookAngleVector2:dot(playerDirToCenterOfSquare)) > 0 then
        player:setVariable('FromBehind', false)
    else
        player:setVariable('FromBehind', true)
    end
end

MarLibrary.bumpFallBackwards = function(player)
    player:setSprinting(true);
    player:setBumpType("stagger");
    player:setVariable("BumpDone", false);
    player:setVariable("BumpFall", true);
    player:setVariable("BumpFallType", "pushedFront");
    player:helmetFall(chance(10))
end

MarLibrary.trip = function(player)
    if ZombRand(1) == 0 then
        bumpType = 'left'
    else
        bumpType = 'right'
    end
    if chance(15) then player:dropHandItems() end
    player:setBumpType(bumpType)
    player:setBumpFallType('FallForward')
    player:setBumpDone(false)
    player:setBumpFall(true)
    player:reportEvent('wasBumped')
end

MarLibrary.tripRollIntense = function(player)
    player:setSprinting(true)
    player:climbOverFence(MarLibrary.getCorrectPlayerMoveIsoDir(player))
    MarLibrary.delayFunc(function()
        player:getVariable("ClimbFenceOutcome")
        player:setVariable("ClimbFenceOutcome", "fall")
    end, 1)
end

-- This is to solve a bug where the player still trips on other peoples screen despite the trip being canceled.
MarLibrary.cancelBumpFallClient = function(player)
    player:setBumpFall(false)
end

MarLibrary.cancelBumpFall = function(player)
    player:setBumpFall(false)
    -- Cancel the bump on other players screens.
    sendClientCommand(player,"MarLibrary", "MarLibrary.cancelBumpFallClient", {player})
end

MarLibrary.cancelBumpFallClient = function(player)
    player:setBumpFall(false)
end

MarLibrary.cancelBumpFall = function(player)
    player:setBumpFall(false)
    -- Cancel the bump on other players screens.
    sendClientCommand(player, "MarLibrary", "MarLibrary.cancelBumpFallClient", {player})
end

MarLibrary.playerSayClient = function(player, text)
    player:Say(text)
end

MarLibrary.playerSayServer  = function(player, text)
    player:Say(text)
    -- Show the player saying the text to everyone.
    sendClientCommand(player, "MarLibrary", "MarLibrary.playerSayClient", {player, text})
end