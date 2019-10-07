print("start of src.lua")

-- (FRAME == frameType.)
local frame = CreateFrame("Frame")

local handlers = { }
local function onEvent(self, event, ...)
	-- call one of the functions above
	return handlers[event](self, ...)
	--local a1,a2,a3,a4,a5,a6,a7,a8,a9 = ...
	--print(self..event..a1..a2..a3..a4..a5..a6..a7..a8..a9)
	--print(self,event,a1,a2,a3,a4,a5,a6,a7,a8,a9)
end

frame:SetScript("OnEvent", onEvent)


-- /reload to run it again ("RELOAD!")


--frame:RegisterEvent("ADDON_LOADED") -- addonName.
function handlers:ADDON_LOADED(...)
	--showArgs("AOL", ...)
	local a1,a2,a3,a4,a5,a6,a7,a8,a9 = ...
	if not (a1 == "MyAddon") then
		return
	end 
	print("AL")
end 

--frame:RegisterEvent("PLAYER_LOGIN") -- noargs
--frame:RegisterEvent("PLAYER_ENTERING_WORLD") -- false true
--frame:RegisterEvent("SPELLS_CHANGED") -- noargs.
--frame:RegisterEvent("PLAYER_ALIVE") -- not called.
function handlers:PLAYER_LOGIN(...) print("PL") end 
function handlers:PLAYER_ENTERING_WORLD(...) print("PEW") end 
function handlers:SPELLS_CHANGED(...)	print("SC") end 
function handlers:PLAYER_ALIVE(...)	print("PA") end 

--MI2_EventHandlers["LOOT_OPENED"] = MI2_EventLootOpened
--MI2_EventHandlers["LOOT_CLOSED"] = MI2_EventLootClosed
--MI2_EventHandlers["LOOT_SLOT_CLEARED"] = MI2_EventLootSlotCleared
--MI2_EventHandlers["PLAYER_TARGET_CHANGED"] = MI2_OnTargetChanged
--MI2_EventHandlers["CHAT_MSG_COMBAT_XP_GAIN"] = MI2x_EventCreatureDiesXP
--MI2_EventHandlers["CHAT_MSG_COMBAT_HOSTILE_DEATH"] = MI2x_CreatureDiesHostile

-- /run print(GetItemInfo(12184))
-- /run for i=1,150000,1 do print(i, GetItemInfo(i)) end
-- /run print(GetItemInfo("Raptor Flesh"))
-- /run for i=1,3,1 do print(i) end

local function GetLootId( slot )
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
end -- GetLootId()

local state = ""
local corpseName = ""
local corpseName2 = ""
local theCorpseGuid = "" -- long (dont use unless you have to.)
local corpseId = ""  -- short.
local latestCombatMob = ""
local lootCount = 0

--function handlers:COMBAT_LOG_EVENT(...)
--	local ts,e = CombatLogGetCurrentEventInfo()
--	print('CLE', e)
--end

function handlers:COMBAT_LOG_EVENT_UNFILTERED(...) 
	--showArgs13("CLE", CombatLogGetCurrentEventInfo() )
	-- den her gir et PARTY_KILL
	local            ts,e,hideCaster,src_id,sname,srcFlags,sraidf,dst_id,dname,dstFlags,draidf = CombatLogGetCurrentEventInfo()
	if false then
		print('ts:',ts,
			',e:',e,',hc:',hideCaster,
			',sId:',src_id,',sN:',sname,',sF:',srcFlags,',sRF:',sraidf,
			',dId:',dst_id,',dN:',dname,',dF:',dstFlags,',dRF:',draidf)
	end

	if false then -- annoying broken mechanism for CLE, when PARTY_KILL doesn't work.
		--print(e)
		if src_id then -- should be dst_id
			local opponent = findMobId(src_id)
			latestCombatMob = opponent
			print('LCM:', latestCombatMob, src_id, e) --, 'from:'
		else
			print("src_id is bad for ", e)
		end 
	end 

	if e == "PARTY_KILL" then 
		state = "01_MOB_KILLED"
		corpseName = dname
		theCorpseGuid = dst_id
		corpseId = findMobId(theCorpseGuid)
		print("CLEU:",ts,e,hideCaster,src_id,sname,srcFlags,sraidf,dst_id,dname,dFlags,draidf)
		print("state",state, "with corpseId", corpseId, "corpseName:",corpseName)
    end
end 


function handlers:PLAYER_TARGET_CHANGED(...) 
	-- no payload.
	local tname = UnitName("target")
	if state == "01_MOB_KILLED" and not (tname == nil) then
		-- fixme - check if target is dead.		
		state = "02_TARGET_CORPSE"
		lootCount=0
		corpseName2 = tname
		print("state 01->", state, "clearing lootcount:", lootCount, "corpseName2:", corpseName2)
	end

	if tname == nil then tname = "<nil>" end
	print("PlayerTargetChanged ", tname)
	--showArgs("PlayerTargetChanged " .. tname,...) 
end 

function handlers:LOOT_OPENED(...) 
	-- arg1==AutoLootBool.
	-- maybe this triggers when multiple sets?
	--showArgs("Loot-Opened", ...) 
	local autoLoot = ...
	print("Loot-Opened", autoLoot)
	recordKill()
end



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


lootMap = {} -- not local.

function recordKill()	
	print('recordKill', corpseId) --, ', ', latestCombatMob, '.')
	--local inf = (lootMap[corpseId] and lootMap[corpseId] or {killCount=0, drops={})
	if corpseId == nil then
		if false then --latestCombatMob then
			print("(record-kill NOC) - latestCombatMob instead: ", latestCombatMob)
			corpseId = latestCombatMob
			latestCombatMob = nil
		else
			print("no-corpse in record-kill, and no LCM :-/")
			return
		end 
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
		lootCount = numItems -- maybe check if it was zero before?
		print("state 02->", state, "lootCount set to ", lootCount)
	end

	if numItems == 0 then
		local dropName = "nothing"
		local amount = 1 -- one serving of 'nothing'
		local itemID = 0
		logItem(inf, dropName, amount, itemID) -- danger - pass-by-value?
	end

	for slot = 1, numItems, 1 do
		print('slot', slot, 'of', numItems)
		local texture, iName, quantity, quality = GetLootSlotInfo( slot )
		-- hmm, quality should be 'islocked'

		local itemID, link = GetLootId( slot )
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

	printMobInf(inf,corpseId) --mobInf, mobId)

	corpseId = nil -- avoid counting a kill more than once.
	corpseName="<?>"
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

function handlers:LOOT_SLOT_CLEARED(...) 
	-- arg1: lootSlot.
	local lootSlot = ...
	print("LootSlot-Cleared, slot:", lootSlot) --showArgs("LootSlotCleared",...) 
	--state = "0x_LOOT_TAKEN"
	-- mon ikke vi er ligeglade med den?
end 

function handlers:LOOT_CLOSED(...) 
	-- no args.
	--print("Loot-Closed")--showArgs("LootClosed",...) 
	if state == "03_LOOT_STARTED" or state == "02_TARGET_CORPSE" then
		state = "04_LOOT_ENDED"
		print("Looted ".. lootCount .. " for " .. corpseName," ", mobId, corpseId) --corpseGuid
		if lootCount == 0 then
			recordKill()
		end 
	else
		print("(ignoring L-C)")
	end
end 



--function handlers:CHAT_MSG_COMBAT_XP_GAIN(...) 
	--local a1,a2,a3,a4,a5,a6,a7,a8,a9,a10,a11,a12,a13,a14,a15,a16,a17 = ...
	--print("CMCXG",a1,';',a2,';',a3,';',a4,';',a5,';',a6,';',a7,';',a8,';',a9,';',a10,';',a11,';',a12,';',a13,';',a14,';',a15,';',a16,';',a17, '!')
	-- self becomes a table here - the 'handlers' is a table.
	--showArgs("CMCXG", CombatLogGetCurrentEventInfo() ) 
	-- FIXME - I need some args or info for this, it's useless?
	-- Also - does gray-mob-level switch between CMCXG and PARTY_KILL?
--end 
--function handlers:CHAT_MSG_COMBAT_HOSTILE_DEATH(...) showArgs("CMCHD",...) end 


function showArgs(a,...)
	local a1,a2,a3,a4,a5,a6,a7,a8,a9 = ...
	print(self,a,a1,a2,a3,a4,a5,a6,a7,a8,a9)
end

function showArgs13(a,...)
	local a1,a2,a3,a4,a5,a6,a7,a8,a9,a10,a11,a12,a13 = ...
	print(self,a,a1,a2,a3,a4,a5,a6,a7,a8,a9,a10,a11,a12,a13)
end


for k, v in pairs(handlers) do
 frame:RegisterEvent(k)
end -- Register all events for which handlers have been defined


--           [Unit type]-0-[server ID]-[instance ID]-[zone UID]-[ID]-[spawn UID] 
-- (Example: "Creature  -0-970         -0-            11-      31146-000136DF91")
-- https://wow.gamepedia.com/GUID                                
function findMobId(a)
		--print('Z'..a..'Z')
		local               unitType,  srv,   inst, zone,  mobId, spawn 
		  = string.match(a, "(%a+)%-0%-(%d+)%-(%d+)%-(%d+)%-(%d+)%-(%x+)")	
		--print('u:', unitType, "s:", srv, "inst:", inst, "z:", zone, "mobId:", mobId, "sp:", spawn)
		return mobId
end