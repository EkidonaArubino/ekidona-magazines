local tm,typetrd={},{"buy_condition","sell_condition"}
function trade_init(npc, cfg) --[[ Scripted by Ekidona Arubino || 02:12:22 || 21:24(JST)
	This script (more precisely, its improvement for autonomy) was completely written back in the winter of 2022 for "Dead Air - Sediment".
	Its essence is quite simple: instead of writing certain configurations to merchants manually, you can use the "generation" of the configurator and integrate / change anything you like in it.
	In "Ekidona magazines" I use it to make "fake ammos" priced like their originals. And yes - if you have updated the merchant config, then remove "ini_temp".]]
	if not (db.actor) then 
		return 
	end 
	-- no use having trade for enemies or zombied (no dialogs)
	if (npc:relation(db.actor) == game_object.enemy or npc:character_community() == "zombied") then 
		return 
	end
	
	local id = npc:id()
	--[[if (tm[id] and tm[id].cfg_ltx == cfg) then
		tm[id].config = ini_file(cfg)
		return 
	end--]]
	
	tm[id] = empty_table(tm[id])
	local tempstr=(getFS():update_path('$game_config$','').."ini_temp\\"..cfg)
	tm[id].cfg_ltx = ("ini_temp\\"..cfg)
	tm[id].config = ini_file_ex(cfg)
	--local temp=io.open(tempstr)
	if not(tm[id].config.ini)then tm[id] = nil
	--elseif not(temp)then
	else local temp=io.open(tempstr)
		if not(temp)then tm[id].config.ini:save_as(tempstr)else io.close(temp)end
		local ini,arts=alun_utils.file_to_table(tempstr),{} tm[id].config=ini_file_ex("ini_temp\\"..cfg,true)
		for _,ttype in pairs(typetrd)do local typer=tm[id].config:r_string_ex("trader",ttype)
			for sec,value in pairs(ini[typer])do tm[id].config:w_value(typer,sec,value) local fammo=(sec.."f")
				if(system_ini():section_exist(fammo) and ekidona_mags.IsFakeAmmo(fammo))then tm[id].config:w_value(typer,fammo,value)end
			end
		end tm[id].config:save()
	end--else tm[id].config=ini_file_ex("ini_temp\\"..cfg) io.close(temp)end
end
function GetTraderIsReal(nid) return(tm[nid] and not(string.find(tm[nid].cfg_ltx,"misc\\trade\\trade_generic.ltx")))end
function setup_buy_sell_conditions(npc,id)
	
	local condlist = xr_logic.parse_condlist(npc, "trader", "buy_condition", tm[id].config:r_string_ex("trader", "buy_condition") or "")
	local str = condlist and xr_logic.pick_section_from_condlist(db.actor, npc, condlist)
	if (str == nil or str == "" or str == "nil") then
		printf("Wrong section in buy_condition condlist for npc [%s]!", npc:name())
		return
	end
	
	npc:buy_condition(tm[id].config.ini, str)
	tm[id].current_buy_condition = str

	condlist = xr_logic.parse_condlist(npc, "trader", "sell_condition", tm[id].config:r_string_ex("trader", "sell_condition") or "")
	str = condlist and xr_logic.pick_section_from_condlist(db.actor, npc, condlist)
	if(str == nil or str == "" or str == "nil") then
		printf("Wrong section in sell_condition condlist for npc [%s]!", npc:name())
		return
	end

	npc:sell_condition(tm[id].config.ini, str)
	tm[id].current_sell_condition = str

	condlist = xr_logic.parse_condlist(npc, "trader", "buy_item_condition_factor", tm[id].config:r_string_ex("trader", "buy_item_condition_factor") or "0.7")
	str = condlist and xr_logic.pick_section_from_condlist(db.actor, npc, condlist)
	if (str == nil or str == "") then
		printf("Wrong section in buy_item_condition_factor condlist for npc [%s]!", npc:name())
		return 
	end
	
	str = tonumber(str) or 0.7
	npc:buy_item_condition_factor(str)
	tm[id].current_buy_item_condition_factor = str
end 

function update(npc)
	local id = npc and npc:id()
	if not (id) then 
		return 
	end
	
	if (tm[id] == nil or tm[id].config == nil) then
		--printf("TRADE [%s]:  trade_manager is nil", npc:name())
		return
	end
	
	setup_buy_sell_conditions(npc,id)
	
	local tg = time_global()
	if (tm[id].resupply_time and game.get_game_time():diffSec(tm[id].resupply_time) < 86400)  then
		return
	end
	tm[id].resupply_time = game.get_game_time()
	
	local str = tm[id].config:r_string_ex("trader", "buy_supplies")
	if not (str) then 
		return -- no buy_supplies this is normal
	end

	local condlist = xr_logic.parse_condlist(npc, "trader", "buy_supplies", str)
	str = condlist and xr_logic.pick_section_from_condlist(db.actor, npc, condlist)
	if(str=="" or str==nil) then
		printf("Wrong section in buy_supplies condlist for npc [%s]!", npc:name())
		return
	end
	if (tm[id].current_buy_supplies == nil or tm[id].current_buy_supplies ~= str) then
		npc:buy_supplies(tm[id].config.ini, str)
		tm[id].current_buy_supplies = str
	end	
end

function on_npc_death(npc)
	if (npc) then
		tm[npc:id()] = nil
	end
end

function save_state(id,m_data)
	if not (id and tm[id] and tm[id].cfg_ltx) then
		return
	end
	if not (utils.valid_pathname(tm[id].cfg_ltx)) then 
		printf("ERROR: trade_manager: Invalid pathname %s.",tm[id].cfg_ltx)
		return
	end
	m_data.trade_manager = empty_table(m_data.trade_manager)
	m_data.trade_manager.cfg_ltx = tm[id].cfg_ltx
	m_data.trade_manager.current_buy_condition = tm[id].current_buy_condition
	m_data.trade_manager.current_sell_condition = tm[id].current_sell_condition
	m_data.trade_manager.current_buy_supplies = tm[id].current_buy_supplies
	m_data.trade_manager.resupply_time = tm[id].resupply_time
end 

function load_state(id,m_data)
	if not (id and m_data.trade_manager and m_data.trade_manager.cfg_ltx) then
		m_data.trade_manager = nil
		return
	end
	local npc = db.storage[id] and db.storage[id].object
	if not (npc and npc:alive()) then 
		return 
	end
	
	if (npc:character_community() == "zombied") then 
		return 
	end 

	tm[id] = tm[id] or {}
	tm[id].cfg_ltx = m_data.trade_manager.cfg_ltx
	tm[id].config = ini_file_ex(tm[id].cfg_ltx,true)
	if not (tm[id].config and tm[id].config.ini) then 
		printf("ERROR: trade_manager: Invalid pathname %s.",tm[id].cfg_ltx)
		return
	end
	tm[id].current_buy_condition = m_data.trade_manager.current_buy_condition
	tm[id].current_sell_condition = m_data.trade_manager.current_sell_condition
	tm[id].current_buy_supplies = m_data.trade_manager.current_buy_supplies
	tm[id].resupply_time = m_data.trade_manager.resupply_time or game.get_game_time()

	m_data.trade_manager = nil
end 


function save(obj, packet)
	local id = obj:id()
	if (tm[id] == nil or not obj:alive()) then
		packet:w_bool(false)
		return
	end 
	if not (utils.valid_pathname(tm[id].cfg_ltx)) then 
		printf("ERROR: trade_manager: Invalid pathname %s.",tm[id].cfg_ltx)
		packet:w_bool(false)
		return
	else 
		packet:w_bool(true)
	end
	
	set_save_marker(packet, "save", false, "trade_manager")
		
	packet:w_stringZ(tm[id].cfg_ltx)
	packet:w_stringZ(tm[id].current_buy_condition or "")
	packet:w_stringZ(tm[id].current_sell_condition or "")
	packet:w_stringZ(tm[id].current_buy_supplies or "")

	local cur_tm = time_global()
	if tm[id].update_time == nil then
		packet:w_s32(-1)
	else
	 	packet:w_s32(tm[id].update_time - cur_tm)
	end

	if tm[id].resupply_time == nil then
		packet:w_s32(-1)
	else
	 	packet:w_s32(tm[id].resupply_time - cur_tm)
	end
	set_save_marker(packet, "save", true, "trade_manager")
end

function load(obj, packet)
	local a = packet:r_bool()
	if a == false then
		return
	end

	set_save_marker(packet, "load", false, "trade_manager")
	
	local id = obj:id()
	tm[id] = {}

	tm[id].cfg_ltx = packet:r_stringZ()
	if not (utils.valid_pathname(tm[id].cfg_ltx)) then 
		-- save most likely corrupt
		tm[obj:id()] = nil
		set_save_marker(packet, "load", true, "trade_manager")
		return
	end 
	
	tm[id].config = ini_file_ex(tm[id].cfg_ltx,true)
	--printf("TRADE LOAD [%s]: cfg_ltx = %s", obj:name(), tostring(tm[id].cfg_ltx))

	a = packet:r_stringZ()
	--printf("TRADE LOAD [%s]: current_buy_condition = %s", obj:name(), tostring(a))
	if a ~= "" then
		tm[id].current_buy_condition = a
		obj:buy_condition(tm[id].config.ini, a)
	end

	a = packet:r_stringZ()
	--printf("TRADE LOAD [%s]: current_sell_condition = %s", obj:name(), tostring(a))
	if a ~= "" then
		tm[id].current_sell_condition = a
		obj:sell_condition(tm[id].config.ini, a)
	end

	a = packet:r_stringZ()
	--printf("TRADE LOAD [%s]: current_buy_supplies = %s", obj:name(), tostring(a))
	if a ~= "" then
		tm[id].current_buy_supplies = a
	end

	local cur_tm = time_global()

	a = packet:r_s32()
	if a ~= -1 then
		tm[id].update_time = cur_tm + a
	end

	a = packet:r_s32()
	if a ~= -1 then
		tm[id].resupply_time = cur_tm + a
	end
	
	if not (obj:alive()) then 
		tm[id] = nil
	end
	set_save_marker(packet, "load", true, "trade_manager")
end
----------- NOT TO DELETE!!!!!!!!! called from engine
function get_buy_discount(npc_id)
	--alun_utils.debug_write("get_buy_discount")
	if not (tm[npc_id]) then
		return 1
	end

	if not (tm[npc_id].config) then 
		return 1 
	end 
	
	local str = tm[npc_id].config:r_string_ex("trader","discounts")
	if(str == nil or str=="") then
		return 1
	end

	local sect = xr_logic.pick_section_from_condlist(db.actor, nil, xr_logic.parse_condlist(db.actor, "trader", "discounts", str))
	if (sect == nil or sect == "") then 
		return 1 
	end

	return tm[npc_id].config:r_float_ex(sect,"buy") or 1
end
----------- NOT TO DELETE!!!!!!!!! called from engine
function get_sell_discount(npc_id)
	--alun_utils.debug_write("get_sell_discount")
	if not (tm[npc_id]) then
		return 1
	end

	if not (tm[npc_id].config) then 
		return 1 
	end 
	
	local str = tm[npc_id].config:r_string_ex("trader","discounts")
	if(str == nil or str=="") then
		return 1
	end

	local sect = xr_logic.pick_section_from_condlist(db.actor, nil, xr_logic.parse_condlist(npc, "trade_manager", "discounts", str))
	if (sect == nil or sect == "") then 
		return 1 
	end
	
	return tm[npc_id].config:r_float_ex(sect,"sell") or 1
end
