
local MI_TXT_GOLD = " Gold"
local MI_TXT_SILVER = " Silver"
local MI_TXT_COPPER = " Copper"
local COPPER_PER_SILVER = 100
local COPPER_PER_GOLD = 100*100

function lootName2Copper(item)
  local i = 0
  local g,s,c = 0
  local money = 0
    
  i = string.find(item, MI_TXT_GOLD )
  if i then
    g = tonumber( string.sub(item,0,i-1) )
    item = string.sub(item,i+5,string.len(item))
    money = money + ((g or 0) * COPPER_PER_GOLD)
  end
  i = string.find(item, MI_TXT_SILVER )
  if i then
    s = tonumber( string.sub(item,0,i-1) )
    item = string.sub(item,i+7,string.len(item))
    money = money + ((s or 0) * COPPER_PER_SILVER)
  end
  i = string.find(item, MI_TXT_COPPER )
  if i then
    c = tonumber( string.sub(item,0,i-1) )
    money = money + (c or 0)
  end

  return money
end -- lootName2Copper()


function stringToCurrency(s)
  return lootName2Copper(s)
end




function getItemPrice(itemId)
  local name, link, rarity, iLvl, iMinLvl, sType, sSubType, stack,loc,tx,price = GetItemInfo(itemId)
  if price == nil then
    price=0
  end
  return price
end


--           [Unit type]-0-[server ID]-[instance ID]-[zone UID]-[ID]-[spawn UID] 
-- (Example: "Creature  -0-970         -0-            11-      31146-000136DF91")
-- https://wow.gamepedia.com/GUID                                
function findMobId(a)
    local               unitType,  srv,   inst, zone,  mobId, spawn 
      = string.match(a, "(%a+)%-0%-(%d+)%-(%d+)%-(%d+)%-(%d+)%-(%x+)")  
    --print('u:', unitType, "s:", srv, "inst:", inst, "z:", zone, "mobId:", mobId, "sp:", spawn)
    return mobId
end





local function GetLootId_forSlot( slot )
  local idNumber = 0

  local link = GetLootSlotLink( slot )
  if link then
    local _, idCode = string.match(link, "^|(%x+)|Hitem:(%d+):.*")
    idNumber = tonumber( idCode or 0 )
    if idNumber == 0 then
      local printable = gsub(link, "\124", "\124\124");
      print('cant parse ', printable)
      local a = GetItemInfo(link)
      print('after loop')
    end
    print('after idn-zero test')
  else 
    print('link broken for slot', slot)
  end
  print('after link test')

  return idNumber, link
end  





function showArgs(a,...)
  local a1,a2,a3,a4,a5,a6,a7,a8,a9 = ...
  print(self,a,a1,a2,a3,a4,a5,a6,a7,a8,a9)
end

function showArgs13(a,...)
  local a1,a2,a3,a4,a5,a6,a7,a8,a9,a10,a11,a12,a13 = ...
  print(self,a,a1,a2,a3,a4,a5,a6,a7,a8,a9,a10,a11,a12,a13)
end


