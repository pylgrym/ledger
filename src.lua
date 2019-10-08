print("start of src.lua")

local frame = CreateFrame("Frame") -- (FRAME == frameType.)

local handlers = { }
local function onEvent(self, event, ...)
	return handlers[event](self, ...)
end

frame:SetScript("OnEvent", onEvent)

--function handlers:PLAYER_LOGIN(...) print("PL") end 
--function handlers:PLAYER_ENTERING_WORLD(...) print("PEW") end 
--function handlers:SPELLS_CHANGED(...)	print("SC") end 
--function handlers:PLAYER_ALIVE(...)	print("PA") end 


local state = ""
local corpseName = ""
local corpseName2 = ""
local theCorpseGuid = "" -- long (dont use unless you have to.)
local corpseId = ""  -- short.
local latestCombatMob = ""
local lootCount = 0


function handlers:COMBAT_LOG_EVENT_UNFILTERED(...) 
	local            ts,e,hideCaster,src_id,sname,srcFlags,sraidf,dst_id,dname,dstFlags,draidf = CombatLogGetCurrentEventInfo()

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
	local targetname = UnitName("target")
	if state == "01_MOB_KILLED" and not (tname == nil) then
		-- fixme - check if target is dead.		
		state = "02_TARGET_CORPSE"
		lootCount=0
		corpseName2 = targetname
		print("state 01->", state, "clearing lootcount:", lootCount, "corpseName2:", corpseName2)
	end

	if targetname == nil then targetname = "<nil>" end
	print("PlayerTargetChanged ", targetname)
end 


function handlers:LOOT_OPENED(...) 
	-- maybe this triggers when multiple sets?
	local autoLoot = ...  -- arg1==AutoLootBool.
	print("Loot-Opened, auto?", autoLoot)
	recordKill()
end


function handlers:LOOT_SLOT_CLEARED(...) 
	local lootSlot = ... 	-- arg1: lootSlot.
	print("LootSlot-Cleared, slot:", lootSlot) --showArgs("LootSlotCleared",...) 
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


for k, v in pairs(handlers) do
 frame:RegisterEvent(k)
end -- Register all events for which handlers have been defined

