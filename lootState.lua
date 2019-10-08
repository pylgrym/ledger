

lootMap = {} -- not local.

function recordKill(corpseId, corpseName) 
  print('recordKill', corpseId) --, ', ', latestCombatMob, '.')
  if corpseId == nil then
    print("no-corpse in record-kill, and no LCM :-/")
    return
  end

  if not lootMap[corpseId] then   
    lootMap[corpseId] = {killCount=0, drops={}, name=corpseName}
    print('creating mob with corpseName', corpseName)
  end
  local inf = lootMap[corpseId]
  inf.name = corpseName -- just to repair.
  inf.killCount = inf.killCount+1

  local numItems = GetNumLootItems()

  if state == "02_TARGET_CORPSE" then
    state = "03_LOOT_STARTED"
    --lootCount = numItems -- maybe check if it was zero before?
    print("state 02->", state, "lootCount set to ", lootCount)
  end

  if numItems == 0 then
    local dropName = "nothing"
    local amount = 1 -- one serving of 'nothing'
    local itemID = 0
    logItem(inf, dropName, amount, itemID) -- danger - pass-by-value?
  end

  for slot = 1, numItems, 1 do
    local texture, iName, quantity, quality = GetLootSlotInfo( slot )
    print('slot', slot, 'of', numItems) --,',', iName, quantity,quality,texture)
    -- hmm, quality should be 'islocked'. also, quality may be nil.

    --print('A')
    local itemID, link = GetLootId_forLootSlot( slot )
    print("slot:",slot,
      ", tex:",texture,
      ", iname:",iName,
      ", qty:",quantity,
      ", qa:", quality,
      ", id:", itemID,
      ", lnk:", link,
      ", for:", corpseId)

    local dropName = iName
    local amount = 1
    local isMoney = not not string.match(dropName, "^%d")
    print("isMoney", isMoney, dropName)
    if isMoney then     
      amount = stringToCurrency(dropName)
      dropName="money"
    end

    logItem(inf, dropName, amount, itemID) -- danger - pass-by-value?
  end
  print('after-loop')
  lootMap[corpseId] = inf -- shouldnt be necessary?

  printMobInf(inf,corpseId) 
  -- NB! corpseId +corpseName must be cleared after this 
  -- (so we can never loot the same mob multiple times.)
  return (numItems>0)
end


function logItem(inf, dropName, amount, itemId)
  if not inf.drops[dropName] then
    inf.drops[dropName] = {name=dropName, count=0, itemId = itemId, price=0}
  end
  local item = inf.drops[dropName]
  item.count = item.count + amount

  print('itemPrice:', item.price, itemId, dropName)
  if not (item.price>0) then -- (As long as price isn't set yet, keep trying to look it up.)
    local price = getItemPrice(itemId)
    if price then   
      item.price = price
    end
  else
    print('so ', item.price, 'is good enough')
  end

  inf.drops[dropName] = item -- shouldn't be necessary?
  return inf -- could this help?
end



function getItemPrice(itemId)
  local name, link, rarity, iLvl, iMinLvl, sType, sSubType, stack,loc,tx,price = GetItemInfo(itemId)
  if price == nil then
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
    print(":", mobId, mobInf.name, "#",itemInfo.count, "/", mobInf.killCount, "$"..sPrice, itemName)
  end
  local totalAvg = total / mobInf.killCount
  print('totalAvg(s):', totalAvg*0.01)
end

