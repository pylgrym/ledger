

lootMap = {} -- not local.


function updateMobKillCount(a_corpseId, corpseName, numItems)
  print('recordKill', a_corpseId, 'num-loots:', numItems) 
  if a_corpseId == nil then
    print("no-corpse in record-kill, and no LCM :-/")
    return nil
  end

  if not lootMap[a_corpseId] then   
    lootMap[a_corpseId] = {killCount=0, drops={}, name=corpseName, mobId = a_corpseId}
    print('creating mob with corpseName', corpseName)
  end
  local mobInf = lootMap[a_corpseId]
  --mobInf.name = corpseName -- just to repair, shouldn't be part of  normal working.
  mobInf.killCount = mobInf.killCount+1
  return mobInf
end

function recordKill(corpseId, corpseName) 
-- NB! corpseId +corpseName must be cleared after this 
-- (so we can never loot the same mob multiple times.)
  local numItems = GetNumLootItems()

  local mobInf = updateMobKillCount(corpseId, corpseName, numItems)
  if mobInf == nil then 
    return (numItems>0)
  end

  if mystate == "02_TARGET_CORPSE" then
    mystate = "03_LOOT_STARTED"
    --lootCount = numItems -- maybe check if it was zero before?
    print("state 02->", mystate) --, "lootCount set to ", lootCount)
  end

  if numItems == 0 then
    local dropName = "nothing"
    local quantity = 1 -- one serving of 'nothing'
    local itemId = 0
    local noPrice = 0
    local noItem = nil
    logItem(mobInf, dropName, quantity, itemId, noPrice, noItem) 
  end

  -- jeg har forpladret denne løkke, den bør ryddes op igen.
  for slot = 1, numItems, 1 do
    recordDroppedItem(slot, mobInf, numItems, corpseId)
  end

  lootMap[corpseId] = mobInf -- shouldnt be necessary?

  printMobInf(mobInf,corpseId) 
  return (numItems>0)
end


function recordDroppedItem(slot, mobInf, numItems, corpseId_toPrint) 
    -- ### GET_ITEM_ID_AND_DROPNAME
    -- hmm, quality should be 'islocked'. also, quality may be nil.
    local texture, dropName, quantity, quality = GetLootSlotInfo( slot ) 
    local itemId, link = GetLootId_forLootSlot( slot )

    -- ### FIX_DROPNAME_LINEBREAKS
    -- Hvis dropName har line breaks for money:
    dropName = dropName:gsub('\n','§')
    local showDropName = dropName -- saving it, because 'money' will replace it.

    -- ### HANDLE_MONEY_SPECIALCASE AND_LOOKUP_PRICE
    -- ### (requires dropname and itemId)
    local price = 0
    local isMoney = not not string.match(dropName, "^%d.*")
    if isMoney then 
      print("isMoney", isMoney, dropName) 
      quantity = stringToCurrency(dropName)
      price = 1
      dropName = "money"
    else
      price = getItemPrice(itemId)
    end

    -- ### PROCURE_ITEM_DROPENTRY (requires dropname and itemId)
    if not mobInf.drops[dropName] then
      mobInf.drops[dropName] = {name=dropName, count=0, itemId=itemId, price=0}
    end
    local item = mobInf.drops[dropName]

    -- ### REFRESH_ITEM_PRICE (requires dropEntry and price)
    if not (item.price>0) then -- (As long as price isn't set yet, keep trying to look it up.)
      if price then   
        item.price = price
      end
    else
      if item.price>0 then
        price = item.price
      end
    end

    -- ### DEBUG_INFO (requires all info gathered and available.)
    print( 
      slot .. "/" .. numItems,
      ",tex:",texture,
      ",$:", price,
      ",#", quantity,
      ",qa:", quality,
      ",id:", itemId,
      ",for:", corpseId_toPrint,
      ",name:",showDropName -- dropName
      )

    -- ### update-drop-entry, is almost moot point by now, because of PROCURE and LOOKUP price.
    -- pretty much only handles 'add-amount' atm.
    logItem(mobInf, dropName, quantity, itemId, price, item)  
end


function logItem(mobInf, dropName, quantity, itemId, price, item)
  -- ### (almost-)superflous "procure-drop-entry"
  if not mobInf.drops[dropName] then
    mobInf.drops[dropName] = {name=dropName, count=0, itemId = itemId, price=0}
  end
  if item == nil then
    item = mobInf.drops[dropName]
  end 

  -- ### "real work":
  item.count = item.count + quantity

  -- another superflous, refresh-price:
  if price ~= nil and (price > 0) and (item.price == nil or item.price == 0) then 
    item.price = price
  end

  -- possibly necessary write-back, because of silly lua semantics (?)
  mobInf.drops[dropName] = item -- shouldn't be necessary?
end



function getItemPrice(itemId)
  local name, link, rarity, iLvl, iMinLvl, sType, sSubType, stack,loc,tx,price = GetItemInfo(itemId)
  if price == nil then -- does this really help?
    price=0
  end
  return price
end



function printLootMap()
  for mobId,mobInf in pairs(lootMap) do
    printMobInf(mobInf, mobId)
  end
end

function printMobInf(mobInf, mobId)
  local total=0
  for itemName,itemInfo in pairs(mobInf.drops) do
    local contribution = (itemInfo.price*itemInfo.count)
    local sPrice = itemInfo.price*0.01
    total = total + contribution
    local ratio = (itemInfo.count/mobInf.killCount)*100 -- now pct.
    local pct = round(ratio)
    print(": " .. pct .. "%", mobId, mobInf.name, "#",itemInfo.count, "/", mobInf.killCount, "$"..sPrice, itemName)
  end
  local totalAvg = total / mobInf.killCount
  print('totalAvg(s):', totalAvg*0.01)
end

function round(a)
  return math.floor(a*10+0.5)/10
end
