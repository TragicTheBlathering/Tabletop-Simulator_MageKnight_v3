--gameSettings == {blitz=false, volkare=false, core=true, legion=true, tesla=false, tut=false, spells=true, ultimate=true, solo=true}
function onload() end --ee7d85
local dprint = require("/_libs/debug/dPrint").dprint
local ShowDebug = false

local setupScript = {}
      setupScript.fetchTokens = require("/MageKnightV3/setUpScript/setupScript_getTokens")

local waitObjects = {}


function runSetUp(gameSettings)
------- Build Variables --------------------------------------------------------
    local setupBags = getSetupBags()
    local cardPool = getCardPool()
------- Fetch Pugs -------------------------------------------------------------
    fetchTokens(setupBags, cardPool, gameSettings)
end

function fetchTokens(setupBags, cardPool, gameSettings)
    --dprint('setupBags',setupBags)
    local drawBags = getDrawBags()
    local spawnPos = getSpawnPos(drawBags)
    local drawPos = getDrawPos(drawBags)
    local validBags = {core=gameSettings.core, legion=gameSettings.legion, tesla=gameSettings.tesla}

    local bag = {}
    bag.core = setupBags.core.takeObject({position=setupBags.core.getPosition()+Vector(0,0,5)}); bag.core.setLock(true); enableCollider(bag.core, false)
    bag.legion = setupBags.legion.takeObject({position=setupBags.legion.getPosition()+Vector(0,0,5)}); bag.legion.setLock(true); enableCollider(bag.legion, false)
    bag.tesla = setupBags.tesla.takeObject({position=setupBags.tesla.getPosition()+Vector(0,0,5)}); bag.tesla.setLock(true); enableCollider(bag.tesla, false)

    local constantsBag ={}
    constantsBag.tesla = setupBags.constant.takeObject({position=setupBags.constant.getPosition()+Vector(0,0,5)}); constantsBag.tesla.setLock(true); enableCollider(constantsBag.tesla, false)


------- Fetch Chosen Pugs ------------------------------------------------------
    Wait.frames(function()
        fetchOfficial(bag, validBags, spawnPos, drawPos, false)
        fetchOfficial(constantsBag, validBags, spawnPos, drawPos, true)
        Wait.frames(function()
            Wait.condition(function() setUpDecks(cardPool, gameSettings, {bag, constantsBag}) end, function() return isObjDestroyed_objList(waitObjects) end)
        end, 3)
    end, 3)
end

function setUpDecks(cardPool, gameSettings, removeSetUpBags)
    local deckSettings = {tut=gameSettings.tut, compeditiveSpells=gameSettings.spells, ultimate=gameSettings.ultimate}
    local drawDecks = {silver=cardPool.silver.silver,
                       gold=cardPool.gold.gold,
                       core=cardPool.aa.core,
                       spells=cardPool.spells.spells,
                       arts=cardPool.arts.arts}

    local optionalDecks = {aa=cardPool.aa.tut,
                           aaU=cardPool.aa.ultimate,
                           spells=cardPool.spells.compeditive,
                           artU=cardPool.arts.ultimate}

    local waitForAllDecks = {}
    for k, deck in pairs(drawDecks) do
        table.insert(waitForAllDecks, deck)
        local pos = deck.getPosition()
        deck.setPositionSmooth(pos+Vector(0,4,0), false, false)
        deck.setRotationSmooth(Vector(0,180,180), false, false)
        Wait.condition(function()
            local bounds = deck.getBounds().size.y/2+0.1
            deck.setPositionSmooth(pos, false, false)
        end, function() return isSmooth(deck) end)
    end

    Wait.condition(function()
        if deckSettings.tut then
            destroyObject(optionalDecks.spells)
            destroyObject(optionalDecks.aaU)
            destroyObject(optionalDecks.artU)
            destroyObject(optionalDecks.aa)
        else
            drawDecks.core.putObject(optionalDecks.aa)

            if deckSettings.compeditiveSpells then
                drawDecks.spells.putObject(optionalDecks.spells)
            else
                destroyObject(optionalDecks.spells)
            end

            if deckSettings.ultimate then
                drawDecks.core.putObject(optionalDecks.aaU)
                drawDecks.arts.putObject(optionalDecks.artU)
            else
                destroyObject(optionalDecks.aaU)
                destroyObject(optionalDecks.artU)
            end
        end
        Wait.frames(function() finiliseSetUp(gameSettings, removeSetUpBags) end, 40)
    end, function() return isSmoothMove_objList(waitForAllDecks) end)
end

function finiliseSetUp(gameSettings, removeSetUpBags)
    for k, o in pairs(removeSetUpBags) do
        for _, bag in pairs(o) do
            destroyObject(bag)
        end
    end
    local found_ShuffleList = getObjectsWithAnyTags({'Cards_PlayerCard', 'Cards_Units', 'eventID_monsterDrawBag', 'eventID_teslaTokenDrawBag'})
    local found_DrawCards = getObjectsWithAnyTags({'tool_DrawPlayerCards', 'tool_DrawOfferCards'})
    local shuffleList = {}
    --tool_DrawPlayerCards
end

------- Fetch Chosen Pugs ------------------------------------------------------
function fetchOfficial(bag, valid, spawnPos, drawPos, defaultTesla)
    local validBags = valid

    if defaultTesla then
        validBags.tesla = true
        validBags.legion = false
        validBags.core = false
    end

    local Y = {}
    local offset = Vector(0,0,0)
    for type, valid in pairs(validBags) do
        if valid then
            Wait.frames(function()
                for k, o in pairs(bag[type].getObjects()) do
                    local pug = bag[type].takeObject({})
                    pug.setRotation(Vector(0, 180, 180))
                    table.insert(waitObjects, pug)
                    for k, tag in pairs(pug.getTags()) do
                        if string.find(tag, 'pug', 1, true) and not string.find(tag, 'trashID', 1, true) then
                            if not defaultTesla then
                                if type == 'tesla' then
                                    tag = modifyTeslaTags(tag, pug)
                                end
                            end
                            offset, Y =  setOffset(Y, type, tag)
                            pug.setPosition(spawnPos[tag])
                            pug.setPositionSmooth(drawPos[tag], false, false)
                            pug.setPositionSmooth(drawPos[tag]+offset, false, false)
                            break
                        end
                    end
                end
            end, 3)
        end
    end
end

function modifyTeslaTags(tag, pug)
    -- change trashID tag to the normal trash card ID for gener pugs
    for k, t in pairs(pug.getTags()) do
        if string.lower(t):find("trashid", 1, true) and not string.lower(tag):find("item", 1, true) then
            if t:find("Tesla", 1, true) then
                local trashTag = t
                local newTag = trashTag:gsub("Tesla.", "")
                pug.removeTag(t)
                pug.addTag(newTag)
                break
            end
        end
    end

    -- Check if '_tesla_' exists in the string
    if string.lower(tag):find("_tesla_", 1, true) then
        if string.lower(tag):find("item", 1, true) then
            return tag
        else
            local newTag = tag:gsub("_tesla_.", "_")
            pug.removeTag(tag)
            pug.addTag(newTag)
            return newTag
        end
    else
        return tag -- Return unmodified string if '_tesla_' is not found
    end
end

function setOffset(Y, type, tag)
    local y = Y
    local offset = Vector(0, 1, 0)

    -- Check if y[type] exists
    if not y[type] then
        y[type] = {} -- Create y[type] if it doesn't exist
    end

    -- Check if y[type][tag] exists
    if not y[type][tag] then
        y[type][tag] = offset -- Create y[type][tag] if it doesn't exist
    else
        y[type][tag] = y[type][tag] + offset -- Increment y[type][tag] by offset
    end

    offset = y[type][tag] -- Update offset to the new value of y[type][tag]
    return offset, y
end
---*****************************************************************************
---****** Get Variable Data ****************************************************
---*****************************************************************************
function getDrawBags()
    local z = {}
    local drawBags = getObjectsWithAnyTags({'eventID_monsterDrawBag', 'eventID_teslaTokenDrawBag'})

    for k, o in pairs(drawBags) do
        for k, t in pairs(o.getTags()) do
            if string.find(t, 'pug', 1, true) then
                z[t] = o
                break
            end
        end
    end

    return z
end

function getDrawPos(drawBags)
    local z = {}

    for k, b in pairs(drawBags) do
        z[k] = b.getPosition()+Vector(0,3,0)
    end

    return z
end


function getSpawnPos(drawBags)
    local z = {}

    local discardBags = getObjectsWithAnyTags({'eventID_MonsterDiscardPile', 'eventID_teslaTokenDiscardPile'})
    for k, o in pairs(discardBags) do
        for k, t in pairs(o.getTags()) do
            if string.find(t, 'pug', 1, true) then
                z[t] = o.getPosition()+Vector(0,5,0)
                break
            end
        end
    end

    return z
end

function getCardPool()
    local silver = getObjectsWithTag('Cards_UnitSilver')
    local tmpTable = {}
    for k, o in pairs(silver) do
        tmpTable.pos = o.getPosition()
        tmpTable.silver = o
    end
    silver = tmpTable
    local gold = getObjectsWithTag('Cards_UnitGold')
    local tmpTable = {}
    for k, o in pairs(gold) do
        tmpTable.pos = o.getPosition()
        tmpTable.gold = o
    end
    gold = tmpTable

    local aaCards = getObjectsWithTag('Cards_AAcards')
    tmpTable = {}
    for k, o in pairs(aaCards) do
        if o.getName() == 'Ultimate AA Cards' then
            tmpTable.ultimate = o
        elseif o.getName() == 'Advanced Action Cards' then
            tmpTable.core = o
            tmpTable.pos = o.getPosition()
        elseif o.getName() == 'Removed for First Reconnaissance' then
            tmpTable.tut = o
        end
    end
    aaCards = tmpTable

    local spells = getObjectsWithTag('Cards_Spells')
    tmpTable = {}
        for k, o in pairs(spells) do
            if o.getName() == 'Spells' then
                tmpTable.spells = o
                tmpTable.pos = o.getPosition()
            elseif o.getName() == 'Compeditive Spells' then
                tmpTable.compeditive = o
            end
        end
    spells = tmpTable

    local arts = getObjectsWithTag('Cards_Artefact')
    tmpTable = {}
        for k, o in pairs(arts) do
            if o.getName() == 'Artifacts' then
                tmpTable.arts = o
                tmpTable.pos = o.getPosition()
            elseif o.getName() == 'Mysterious Box (Artefact)' then
                tmpTable.ultimate = o
            end
        end
    arts = tmpTable

    return {silver=silver, gold=gold, aa=aaCards, spells=spells, arts=arts}
end

function getSetupBags()
    local bags = {}
        bags.core   = getObjectsWithTag('setupBag_Monsters_Core')
        bags.legion = getObjectsWithTag('setupBag_Monsters_Legion')
        bags.tesla  = getObjectsWithTag('setupBag_Monsters_Tesla')
        bags.constant = getObjectsWithTag('setupBag_Constant')
        for k, o in pairs(bags) do
            if o[1] then
                bags[k] = o[1]
            end
        end

    return bags
end
--******************************************************************************
--***** Tools ******************************************************************
--******************************************************************************
function isObjDestroyed_objList(objList)
    for k, obj in pairs(objList) do
        --print(obj.getVelocity():magnitude())
        if obj then
            if not obj.isDestroyed() then
                --print(obj.isDestroyed())
                return false
            end
        end
    end
    return true
end

function isSmoothMove_objList(objList)
    for k, obj in pairs(objList) do
        if obj then
            if not isSmooth(obj) then return false end  -- Return false immediately if any value is false
        end
    end
    return true
end

function isSmooth(obj)
    if obj == nil then
        return true
    elseif not obj.isSmoothMoving() then
        return true
    end
    return false
end

function enableCollider(obj, enableCollider)
    local debug = ShowDebug or false
    if enableCollider == nil then enableCollider=true end

    if debug then
        --print('Debug Enabled : enableCollider(obj, enableCollider)')
    else
        if enableCollider then
            --print('enable')
            if obj.getComponent("Rigidbody") then
                obj.getComponent("Rigidbody").set("detectCollisions", true)
            end
            if obj.getComponent("BoxCollider") then
                obj.getComponent("BoxCollider").set("enabled", true)
            end
        else
            --print('disable')
            if obj.getComponent("Rigidbody") then
                obj.getComponent("Rigidbody").set("detectCollisions", false)
            end
            if obj.getComponent("BoxCollider") then
                obj.getComponent("BoxCollider").set("enabled", false)
            end
        end
    end

end
