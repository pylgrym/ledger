


--function handlers:CHAT_MSG_COMBAT_XP_GAIN(...) 
  --local a1,a2,a3,a4,a5,a6,a7,a8,a9,a10,a11,a12,a13,a14,a15,a16,a17 = ...
  --print("CMCXG",a1,';',a2,';',a3,';',a4,';',a5,';',a6,';',a7,';',a8,';',a9,';',a10,';',a11,';',a12,';',a13,';',a14,';',a15,';',a16,';',a17, '!')
  -- self becomes a table here - the 'handlers' is a table.
  --showArgs("CMCXG", CombatLogGetCurrentEventInfo() ) 
  -- FIXME - I need some args or info for this, it's useless?
  -- Also - does gray-mob-level switch between CMCXG and PARTY_KILL?
--end 
--function handlers:CHAT_MSG_COMBAT_HOSTILE_DEATH(...) showArgs("CMCHD",...) end 
