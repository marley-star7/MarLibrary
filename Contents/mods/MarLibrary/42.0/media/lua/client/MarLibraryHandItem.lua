MarTraits = MarTraits or {}

MarLibrary.Traits.HandWeaponModifierList = MarLibrary.Traits.HandWeaponModifierList or {}

-- Optional parameters for custom description names or titles diff from trait name, will be autofilled by default as "nameOrig" and "nameOrigDesc"
--MarLibrary.Traits.addTraitHandWeaponModifier = function(trait, items, )

local function handWeaponModifier()
    local player = getPlayer()
    if player:getPrimaryHandItem() then
        local item = player:getPrimaryHandItem()
        local itemData = item:getModData()
        local itemType = player:getPrimaryHandItem():getType()
        local itemSkillCategory = ""
        if item:IsWeapon() then
            local itemSkillCategory = ""
            if item:getCategories() then
                itemSkillCategory = tostring(item:getCategories())
                --print(itemSkillCategory)
            end
            -- Sledgehammer
            if itemType == "Sledgehammer" or itemType == "Sledgehammer2" then
                --print("sledgy")
                local sledgehammer = item
                if itemData.marTraitsState == nil then
                    itemData.origEnduranceMod = item:getEnduranceMod()
                    itemData.origBaseSpeed = item:getBaseSpeed()
                    itemData.marTraitsState = "Normal"
                end

                if player:HasTrait("Demoman") then
                    print("Player has trait Demoman and weapon data not set, changing item stats.")
                    sledgehammer:setEnduranceMod(0.8)
                    sledgehammer:setBaseSpeed(1.25)
                    itemData.marTraitsState = "Demoman"
                elseif itemData.marTraitsState ~= "Normal" then
                    print("Player weapon data different from normal, changing item stats.")
                    sledgehammer:setEnduranceMod(itemData.origEnduranceMod)
                    sledgehammer:setBaseSpeed(itemData.origBaseSpeed)
                    itemData.marTraitsState = "Normal"
                end
            end
            -- Knife
            if itemSkillCategory == "[SmallBlade]" or itemSkillCategory == "[SmallBlunt]" then
                if itemData.marTraitsState == nil then
                    itemData.origMinDamage = item:getMinDamage()
                    --itemData.origMaxDamage = item:getMaxDamage()
                    itemData.marTraitsState = "Normal"
                end

                if player:HasTrait("Butcher") then
                    print("Player has trait Butcher and weapon data not set, changing item stats.")
                    item:setMinDamage(itemData.origMinDamage * 1.5)
                    --item:setMaxDamage(itemData.origMaxDamage * 1.35)
                    itemData.marTraitsState = "Butcher"
                elseif itemData.marTraitsState ~= "Normal" then
                    print("Player weapon data different from normal, changing item stats.")
                    item:setMinDamage(itemData.origMinDamage)
                    --item:setMaxDamage(itemData.origMaxDamage)
                    itemData.marTraitsState = "Normal"
                end
            end
        end
    end
end

Events.OnEquipPrimary.Add(handWeaponModifier)
Events.OnCreatePlayer.Add(handWeaponModifier)