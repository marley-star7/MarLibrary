MarLibrary = MarLibrary or {}

-- TODO: Pretty sure that "EveryOneMinute" event breaks timing on time scale changing sooooooo, we do this instead, but find that out yeh?

-- Thanks MoreTraits for this function below lol, helped a previous newbie like me.
MarLibrary.tableContains = function(table, checkContain)
    for _, value in pairs(table) do
        if value == checkContain then
            return true
        end
    end
    return false
end

MarLibrary.delayFunc = function(func, delay)

    delay = delay or 1
    local ticks = 0
    local canceled = false

    local function onTick()

        if not canceled and ticks < delay then
            ticks = ticks + 1
            return
        end

        Events.OnTick.Remove(onTick)
        if not canceled then func() end
    end

    Events.OnTick.Add(onTick)
    return function()
        canceled = true
    end
end

MarLibrary.delayFuncByDelta = function(func, delay)

    delay = delay or 1
    local time = 0
    local canceled = false

    local function onTick()
        
        if not canceled and time < delay then
            time = time + getGameTime():getTimeDelta()
            return
        end

        Events.OnTick.Remove(onTick)
        if not canceled then func() end
    end

    Events.OnTick.Add(onTick)
    return function()
        canceled = true
    end
end

MarLibrary.chance = function(percentage)
    if percentage >= ZombRand(1,100) then
        return true
    else
        return false
    end
end

-- TODO: This "fix" only works for moving up and down and honestly? I have NO idea how its even breaking to know how to properly fix it.
-- Bug where move direction returns a wrong value when aiming which seems to be left from the correct direction when aiming so we fix it here with this
MarLibrary.getCorrectPlayerMoveIsoDir = function(player)
    if player:isAiming() then
        return IsoDirections.reverse(IsoDirections.RotRight(IsoDirections.fromAngle(player:getPlayerMoveDir())))
    else
        return IsoDirections.fromAngle(player:getPlayerMoveDir())
    end
end

--============================--
-- TRAIT AND PROFESSION STUFF --
--============================--

-- These exists to shorten the long ass thing, and to make the whole naming convention easier
local boolean VloatDescriptionFunBlurbsEnabled = false
local function getTraitDescription(traitName)
	local traitDesc = getText("UI_trait_" .. traitName .. "Desc")
	if getActivatedMods():contains("MoreDescriptionForTraits4166") then
		local traitDescExplicit = getText("UI_trait_" .. traitName .. "Desc_explicit")
		if traitDescExplicit ~= ("UI_trait_" .. traitName .. "Desc_explicit") then
			traitDesc = traitDesc .. traitDescExplicit
		end
	end
	if VloatDescriptionFunBlurbsEnabled then
        local traitDescFun = getText("UI_trait_" .. traitName .. "Desc_explicit")
        if traitDescFun ~= ("UI_trait_" .. traitName .. "Desc_fun") then
			traitDesc = traitDesc .. traitDescFun
		end
	end
	return traitDesc
end

MarLibrary.addTrait = function(name, cost)
    return TraitFactory.addTrait(name, getText("UI_trait_" .. name), cost, getTraitDescription(name), false)
end

MarLibrary.addProfessionTrait = function(name)
    return TraitFactory.addTrait(name, getText("UI_trait_" .. name), 0, getTraitDescription(name), true)
end

MarLibrary.addTraitSinglePlayerOnly = function(name, cost)
    return TraitFactory.addTrait(name, getText("UI_trait_" .. name), cost, getTraitDescription(name), false, true)
end

-- TODO: Shhh, this is for later.
--[[
MarLibrary.addTraitMultiplayerOnly = function(name, cost)
end
]]--

--===================--
-- JACKASS FUNCTIONS --
--===================--

MarLibrary.bump = function(player)
    if MarLibrary.chance(50) then bumpType = 'left' else bumpType = 'right' end
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
    player:helmetFall(MarLibrary.chance(10))
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
    player:helmetFall(MarLibrary.chance(10))
end

MarLibrary.trip = function(player)
    if ZombRand(1) == 0 then
        bumpType = 'left'
    else
        bumpType = 'right'
    end
    if MarLibrary.chance(15) then player:dropHandItems() end
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