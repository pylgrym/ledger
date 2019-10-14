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


mystate = ""

local corpseName = ""
local corpseId = ""  -- short.
-- local theCorpseGuid = "" -- long (dont use unless you have to.)
local corpseName2 = ""
local latestCombatMob = ""
local droppedAnyLoot = false --local lootCount = 0


function handlers:COMBAT_LOG_EVENT_UNFILTERED(...) 
	local            ts,e,hideCaster,src_id,sname,srcFlags,sraidf,dst_id,dname,dstFlags,draidf = CombatLogGetCurrentEventInfo()

	if e == "PARTY_KILL" then 
		mystate = "01_MOB_KILLED"
		corpseName = dname
		local theCorpseGuid = dst_id
		corpseId = findMobId(theCorpseGuid)
		print("CLEU:",ts,e,hideCaster,src_id,sname,srcFlags,sraidf,dst_id,dname,dFlags,draidf)
		print("state",mystate, "with corpseId", corpseId, "corpseName:",corpseName)
    end
end 

vbs = false -- verbose

function handlers:PLAYER_TARGET_CHANGED(...) 
	-- no payload.
	local targetname = UnitName("target")
	if mystate == "01_MOB_KILLED" and not (targetname == nil) then
		-- fixme - check if target is dead.		
		mystate = "02_TARGET_CORPSE"
		droppedAnyLoot=false
		corpseName2 = targetname
		print("state 01->", state, "clearing droppedAnyLoot:", droppedAnyLoot, "corpseName2:", corpseName2)
	end

	if targetname == nil then targetname = "<nil>" end

	if vbs then print("PlayerTargetChanged ", targetname) end	
end 

function forwardRecordKill() --corpseId, corpseName)
	droppedAnyLoot = recordKill(corpseId, corpseName)
	corpseId = nil -- avoid counting a kill more than once.
	corpseName="<?>"
end

function handlers:LOOT_OPENED(...) 
	-- maybe this triggers when multiple sets?
	local autoLoot = ...  -- arg1==AutoLootBool.
	if vbs then print("Loot-Opened, auto?", autoLoot) end
	forwardRecordKill()
end


function handlers:LOOT_SLOT_CLEARED(...) 
	local lootSlot = ... 	-- arg1: lootSlot.
	if vbs then print("LootSlot-Cleared, slot:", lootSlot) end
end 


function handlers:LOOT_CLOSED(...) 
	-- no args.
	--print("Loot-Closed")--showArgs("LootClosed",...) 
	if mystate == "03_LOOT_STARTED" or mystate == "02_TARGET_CORPSE" then
		mystate = "04_LOOT_ENDED"
		print("Looted, any?", droppedAnyLoot, "for", corpseName," ", corpseId) 
		if not droppedAnyLoot then
			forwardRecordKill()
		end 
	else
		if vbs then print("(ignoring L-C)") end
	end
end 


for k, v in pairs(handlers) do
 frame:RegisterEvent(k)
end -- Register all events for which handlers have been defined

