MarLibrary = MarLibrary or {}
MarLibrary.Traits = MarLibrary.Traits or {}

-- TODO: this could probably be more efficiently made, 
-- especially the custom parameter for the speed stuff, since the function usually replaces whatever speed modifier sent before it in the table anyways.

--============================--
-- TRAIT AND PROFESSION STUFF --
--============================--

-- These exists to shorten the long ass thing, and to make the whole naming convention easier
local function getTraitDescription(traitName)
	local traitDesc = getText("UI_trait_" .. traitName .. "Desc")
	if getActivatedMods():contains("DetailedDescriptionsForOccupationsAndTraits") then
		local traitDescExplicit = getText("UI_trait_" .. traitName .. "Desc_explicit")
        -- The default for empty text is simply the string that was sent for get, so if it is set to that then there is no explicit text to set to, so we don't.
		if traitDescExplicit ~= ("UI_trait_" .. traitName .. "Desc_explicit") then
			traitDesc = traitDesc .. traitDescExplicit
		end
	end
	return traitDesc
end

-- Adds a new trait according to naming schema automatically, if no cost parameter is set defaults to 0 (profession trait)
MarLibrary.Traits.addTrait = function(name, cost, singlePlayerOnly)
    return TraitFactory.addTrait(name, getText("UI_trait_" .. name), cost or 0, getTraitDescription(name), singlePlayerOnly or false)
end

MarLibrary.Traits.addProfession = function(name, cost)
	local prof = ProfessionFactory.addProfession(name, getText("UI_prof_" .. name), getText("icon_prof_" .. name), cost)
	return prof
end
MarLibrary.Traits.TraitCopiesToSwap = MarLibrary.Traits.TraitCopiesToSwap or {}

local function setupTraitCopy(copyTraitName, nameOrig)
	-- Make mutually exclusive with original trait
	TraitFactory.setMutualExclusive(copyTraitName, nameOrig)
	-- Copy all mutual exclusives of the original trait into this one as well
	local mutualExclusives = TraitFactory.getTrait(nameOrig):getMutuallyExclusiveTraits()
	for i = 0, mutualExclusives:size() - 1 do
		TraitFactory.setMutualExclusive(copyTraitName, mutualExclusives:get(i))
	end
	
	-- Just a safety measure in case you try to add a trait twice for some reason.
	for _, traitNameInfo in pairs(MarLibrary.Traits.TraitCopiesToSwap) do
		if copyTraitName == traitNameInfo[1] then
			return
		end
	end
	
	-- Add it to the list of traits to be swapped at start.
	MarLibrary.Traits.TraitCopiesToSwap[#MarLibrary.Traits.TraitCopiesToSwap + 1] = {
		copyTraitName,
		nameOrig,
	}
end

-- Optional parameters for custom description names or titles diff from trait name, will be autofilled by default as "nameOrig" and "nameOrigDesc"
-- Copies a normal trait to be used in professions.
MarLibrary.Traits.addTraitCopy = function(nameOrig, cost, customTitleName, customDescName)
	local copyTraitName = nameOrig .. "_copy"
	-- Optional names
	local titleName = customTitleName or nameOrig
	local descName = customDescName or titleName .. "Desc" -- Default if no input
	TraitFactory.addTrait(copyTraitName, getText("UI_trait_" .. titleName), cost or 0, getText("UI_trait_" .. descName), true, TraitFactory.getTrait(nameOrig):isRemoveInMP())

	setupTraitCopy(copyTraitName, nameOrig)
	return copyTraitName
end

local function doNewCharacterTraitSwaps(playernum, player)
	for _, traitSwapData in pairs(MarLibrary.Traits.TraitCopiesToSwap) do
		if player:HasTrait(traitSwapData[1]) then
			player:getTraits():remove(traitSwapData[1])
			player:getTraits():add(traitSwapData[2])
		end
	end
end

Events.OnCreatePlayer.Add(doNewCharacterTraitSwaps)

--===================================--
-- TIMED ACTION SPEED MODIFIER STUFF --
--===================================--

MarLibrary.Traits.TimedActionSpeedModifierList = MarLibrary.Traits.TimedActionSpeedModifierList or {}

-- Adds speed value actions for only those in the list
function MarLibrary.Traits.addTraitTimedActionSpeedModifierList(traitName, actions)
	-- If we find already exists in the array, replace those modifiers for that trait instead of make new one.
	local size = #MarLibrary.Traits.TimedActionSpeedModifierList
	for i = 1, size do
		local traitData = MarLibrary.Traits.TimedActionSpeedModifierList[i]
		if traitData and traitData[1] == traitName then
			MarLibrary.Traits.TimedActionSpeedModifierList[i] = {traitName, actions}
			print("Trait specific timed action speed list the same, speed changed.")
			return
		end
	end
	-- Add them as new if not replaced before.
	MarLibrary.Traits.TimedActionSpeedModifierList[size + 1] = {traitName, actions}
end

MarLibrary.Traits.BaseTimedActionSpeedModifierList = MarLibrary.Traits.BaseTimedActionSpeedModifierList or {}
MarLibrary.Traits.BaseTimedActionSpeedModifierExclusionsList = MarLibrary.Traits.BaseTimedActionSpeedModifierExclusionsList or {}

-- Adds the speed value for everything but the excluded list.
function MarLibrary.Traits.addTraitBaseTimedActionSpeedModifierWithExclusionsList(traitName, baseSpeedModifier, excludedActions)
    -- Check the current size of the lists
    local size = #MarLibrary.Traits.BaseTimedActionSpeedModifierList

    -- Iterate through the existing lists to find a matching trait and replace if found
    for i = 1, size do
        -- Check for the existing trait in the speed modifier list
        local traitSpeedData = MarLibrary.Traits.BaseTimedActionSpeedModifierList[i]
        if traitSpeedData and traitSpeedData[1] == traitName then
            -- If the trait exists, replace the speed modifier
            MarLibrary.Traits.BaseTimedActionSpeedModifierList[i] = {traitName, baseSpeedModifier}
        end

        -- Check for the existing trait in the exclusion list
        local traitExclusionData = MarLibrary.Traits.BaseTimedActionSpeedModifierExclusionsList[i]
        if traitExclusionData and traitExclusionData[1] == traitName then
            -- If the trait exists, replace the exclusions
            MarLibrary.Traits.BaseTimedActionSpeedModifierExclusionsList[i] = {traitName, excludedActions}
            return  -- Return early once the update is made
        end
    end

    -- If the trait wasn't found, add new entries to both lists
    MarLibrary.Traits.BaseTimedActionSpeedModifierList[size + 1] = {traitName, baseSpeedModifier}
    MarLibrary.Traits.BaseTimedActionSpeedModifierExclusionsList[size + 1] = {traitName, excludedActions}
end

--================--
-- INNER WORKINGS --
--================--

local function checkPlayerTimedActionForBaseSpeedModWithExclusions(player, actionType)
    local speedMod = 0
    -- Iterate over the BaseTimedActionSpeedModifierList correctly
    for _, timedActionSpeedModifier in pairs(MarLibrary.Traits.BaseTimedActionSpeedModifierList) do
        if player:HasTrait(timedActionSpeedModifier[1]) then -- traitData 1 is trait name.
            -- Look for excluded actions
            local isExcluded = false
            for _, excludedAction in pairs(MarLibrary.Traits.BaseTimedActionSpeedModifierExclusionsList) do
                if excludedAction[1] == actionType then
                    isExcluded = true
                    break  -- No need to continue checking further exclusions
                end
            end
            
            if not isExcluded then
                speedMod = speedMod + timedActionSpeedModifier[2] -- Add speed mod if not excluded
            end
        end
    end
    
    return speedMod
end

-- Specific Timed Actions
local function checkPlayerTimedActionSpecificSpeedMods(player, actionType)
	local speedMod = 0
	for _, traitData in pairs(MarLibrary.Traits.TimedActionSpeedModifierList) do
		if player:HasTrait(traitData[1]) then -- traitData 1 is trait name.
			for _, action in pairs(traitData[2]) do
				if action[1] == actionType then

					-- function to have conditions to the speed.
					if action[3] then
						local testFunc = action[3]
						speedMod = speedMod + testFunc(player)
					else
						speedMod = speedMod + action[2]
					end
				end
			end
		end
	end
	return speedMod
end

local function timedActionSpeedUpdate(player, action)
	if player:hasTimedActions() then

		local type = action:getMetaType()
		--print("Current action name is (" .. type .. ")")
		local delta = action:getJobDelta()
		local multiplier = getGameTime():getMultiplier()
		local modifier = 1;
		
		modifier = modifier + checkPlayerTimedActionForBaseSpeedModWithExclusions(player, type)
		modifier = modifier + checkPlayerTimedActionSpecificSpeedMods(player, type)
		--Don't overshoot it?
		if delta < 0.99 - (modifier * 0.01) then
			action:setCurrentTime((action:getCurrentTime() + (modifier * multiplier)))
		end
	end
end

MarLibrary.Events.OnPlayerDoTimedAction:Add("timedActionSpeedUpdate", timedActionSpeedUpdate)