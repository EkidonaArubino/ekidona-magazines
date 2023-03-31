---------------------------------------------------------------------------------------------
--' funtions for upgrade items ----------------------------------------------------
--' Made by Distemper ----------------------------------------------------------------
--' 03.08 --------------------------------------------------------------------------------
-- Altered by Alundaio to allow npc to keep items for an amount of time
-- UPDATE by エキドナ　アルビノ | Ekidona Arubino (bugfix of original "YourPrice" and magazines... yeap)
local YourPrice = 0

cur_hint = nil
local issue_condlist = true
local char_ini = ini_file("item_upgrades.ltx")
local param_ini = ini_file("misc\\stalkers_upgrade_info.ltx")
local cur_price_percent = 2

local RepairItemList = {}
local check_items
local weapon_upgrades = {}
local effect_funct

function save_state(m_data)
	--alun_utils.debug_write("inventory_upgrades.save_state")
	m_data.RepairItemList = RepairItemList
end

function load_state(m_data)
	RepairItemList = m_data.RepairItemList or RepairItemList
	m_data.RepairItemList = nil
end

----------- Dialog Func--------------------

function lend_item_for_repair(itm,mechanic_name,rt)
	local npc = get_story_object(mechanic_name)
	if (npc) then
		if(ekidona_mags.isMWeapon(itm:section()))then ekidona_mags.WeaponEjectMag(itm)
		elseif(ekidona_mags.isMSuit(itm:section()))then local data=ekidona_mags.GetMagazinesDB(itm:id())
			for k,v in pairs(data)do local msec=ekidona_mags.GetMagFromInd(v[1]) 
				ekidona_mags.CreateMagazine(msec,db.actor:position(),db.actor:level_vertex_id(),db.actor:game_vertex_id(),0,ekidona_mags.GetAmmoSecFromMag(msec,v[2]),v[3])
		end ekidona_mags.SetMagazinesDB(itm:id(),{})end db.actor:transfer_item(itm,npc) give_info(npc:section().."_is_repairing")
		news_manager.relocate_item(db.actor,"out",itm:section(),1)

		local max_time = 0
		
		if not (RepairItemList[mechanic_name]) then
			RepairItemList[mechanic_name] = {}
		else
			for id,t in pairs(RepairItemList[mechanic_name]) do
				if (t.gt ~= nil) then
					local check_time = utils.clamp(t.rt - game.get_game_time():diffSec(t.gt),0,t.rt)
					if (max_time < check_time) then max_time = check_time end
				end
			end
			rt = rt+max_time
		end

		--printf("mechanic name = %s [sec = %s, id = %s]  repair_time = %s",mechanic_name,itm:section(),itm:id(),rt/60)
		RepairItemList[mechanic_name][itm:id()] = {gt = game.get_game_time(), rt = rt}

		local hud = get_hud()
		if (hud) then
			hud:HideActorMenu()
			--hud:UpdateActorMenu()
		end
	end
end

function has_repair_info(a,b)
	local npc = dialogs.who_is_npc(a,b)
	if (has_alife_info(npc:section().."_is_repairing")) then
		return true
	end
	return false
end

function has_repaired_items(a,b)
	local npc = dialogs.who_is_npc(a,b)
	local sec = npc:section()
	if not (RepairItemList[sec]) then
		return false
	end
	for id,t in pairs(RepairItemList[sec]) do
		if (game.get_game_time():diffSec(t.gt) >= t.rt) then
			return true
		end
	end
	return false
end

function dont_has_repaired_items(a,b)
	local npc = dialogs.who_is_npc(a,b)
	local sec = npc:section()
	if not (RepairItemList[sec]) then
		return true
	end
	for id,t in pairs(RepairItemList[sec]) do
		if (game.get_game_time():diffSec(t.gt) >= t.rt) then
			return false
		end
	end
	return true
end

function give_repaired_items(a,b)
	local npc = dialogs.who_is_npc(a,b)
	local sec = npc:section()
	if not (RepairItemList[sec]) then
		return false
	end

	local process_list = {}
	local itm
	local index = 0
	for id,t in pairs(RepairItemList[sec]) do
		index = index + 1
		if (game.get_game_time():diffSec(t.gt) >= t.rt) then
			itm = level.object_by_id(id)
			if (itm) then
				npc:transfer_item(itm,db.actor)
				news_manager.relocate_item(db.actor, "in", itm:section(), 1)
				process_list[id] = index
				table.insert(process_list,id)
			end
		end
	end

	for i=1,#process_list do
		RepairItemList[sec][process_list[i]] = nil
	end

	disable_info(npc:section().."_is_repairing")

	for k,v in pairs(RepairItemList[sec]) do
		if (k) then
			give_info(npc:section().."_is_repairing")
			break
		end
	end

	return true
end

function dm_repair_not_done(a,b)
	local npc = dialogs.who_is_npc(a,b)
	local sec = npc:section()
	if not (RepairItemList[sec]) then
		return "ERROR in dm_repair_not_done [RepairItemList["..sec.."] = nil"
	end

	local lowest,itm_id,gts
	for id,t in pairs(RepairItemList[sec]) do
		gts = t.rt - game.get_game_time():diffSec(t.gt)
		if not (lowest) then
			lowest = gts
			itm_id = id
		end

		if (gts < lowest) then
			lowest = gts
			itm_id = id
		end
	end

	if (lowest and itm_id) then
		local seconds = lowest
		local minutes = seconds/60
		local hours = minutes/60

		local itm = level.object_by_id(itm_id)
		local itm_sec = itm and itm:section()

		local inv_name = game.translate_string(system_ini():r_string_ex(itm_sec,"inv_name") or "")

		-- TODO: replace with translatable strings
		local text = {}
		for i=1,9 do 
			table.insert(text,"st_inventory_upgrade_reply_"..i)
		end

		local function set_text(str,...)
			local p = {...}
			local i = 0
			local function sr(a)
				i = i + 1
				return tostring(p[i])
			end
			return string.gsub(str,"%%s",sr)
		end

		if (hours < 1) then
			local m = math.floor(minutes)
			if (m <= 1) then
				return set_text(game.translate_string(text[9]))
			end

			if (npc:section() == "zat_a2_stalker_mechanic") then
				return set_text(game.translate_string(text[math.random(3)]),inv_name,m)
			end
			return set_text(game.translate_string(text[math.random(2)]),inv_name,m)
		elseif (hours < 2) then
			local m = math.floor(minutes - 60)
			if (npc:section() == "zat_a2_stalker_mechanic") then
				return set_text(game.translate_string(text[math.random(3,#text)]),inv_name,m)
			end
			return set_text(game.translate_string(text[7]),inv_name,m)
		else
			local h = math.floor(hours)
			local m = math.floor(minutes - (60*h))
			return set_text(game.translate_string(text[8]),inv_name,h,m)
		end
	end
	return "ERROR in dm_repair_not_done no itm_id"
end
----------- End Dialog Func--------------------

function precondition_functor_a( param1, section )
	local victim = victim_id and (db.storage[victim_id] and db.storage[victim_id].object or level.object_by_id(victim_id))
	if not (victim) then 
		return 2 
	end
	
	local mechanic_name = victim:section()
	
	local ret = 0
	if(param_ini:line_exist(mechanic_name.."_upgr", section)) then
		local param = param_ini:r_string_ex(mechanic_name.."_upgr", section)
		if(param) then
			if(param=="false") then
				ret = 1
			elseif(param~="true") then
				local possibility_table = xr_logic.parse_condlist(victim, mechanic_name.."_upgr", section, param)
				local possibility = xr_logic.pick_section_from_condlist(db.actor, victim, possibility_table)
				if not(possibility) or (possibility=="false") then
					ret = 2
				end
			end
		end
	end
	
	if not (db.actor) then -- needed
		return ret 
	end

	local price = math.floor(char_ini:r_u32(section, "cost")*cur_price_percent)
	local cash = db.actor:money()
	if(cash<price) then
		ret = 2
	end

	return ret
end

function effect_functor_a( param2, section, loading ) --( string, string, int )
	if loading == 0 then
		local money = char_ini:r_u32(section, "cost")
		db.actor:give_money(math.floor(money*-1*cur_price_percent))
		effect_funct = true
	end
end

function get_upgrade_cost(section)
	if db.actor then
		local price = math.floor(char_ini:r_u32(section, "cost")*cur_price_percent)
		return game.translate_string("st_upgr_cost")..": "..price
	end
	return " "
end

function get_possibility_string(mechanic_name, possibility_table)
		local str = ""
	if(cur_hint) then
		for k,v in pairs(cur_hint) do
			str = str.."\\n - "..game.translate_string(v)
		end
	end
	if(str=="") then
		str = " - add hints for this upgrade"
	end
	return str
end

function prereq_functor_a( param3, section )
	local victim = victim_id and (db.storage[victim_id] and db.storage[victim_id].object or level.object_by_id(victim_id))
	if not (victim) then 
		return ""
	end
	
	local mechanic_name = victim:section()
	local str = ""
	if(param_ini:line_exist(mechanic_name.."_upgr", section)) then
		local param = param_ini:r_string_ex(mechanic_name.."_upgr", section)
		if(param) then
			if(param=="false") then
				return str
			else
				cur_hint = nil
				local possibility_table = xr_logic.parse_condlist(victim, mechanic_name.."_upgr", section, param)
				local possibility = xr_logic.pick_section_from_condlist(db.actor, victim, possibility_table)
				if not(possibility) or (possibility=="false") then
					str = str..get_possibility_string(mechanic_name, possibility_table)
				end
			end
		end
	end
	if(db.actor) then
		local price = math.floor(char_ini:r_u32(section, "cost")*cur_price_percent)
		local cash = db.actor:money()
		if(cash<price) then
			return str.."\\n - "..game.translate_string("st_upgr_enough_money")--.." "..price-cash.." RU"
		end
	end
	return str
end

function property_functor_a(param1, name)

	local prorerty_name = char_ini:r_string(name, "name")
	local t_prorerty_name = game.translate_string(prorerty_name)
	local section_table = utils.parse_names(param1)
	local section_table_n = #section_table
	local section = section_table[1]
	if(section_table_n==0) then
		return ""
	end
	local value = 0
	local sum = 0
	for i = 1,section_table_n do
		if not(char_ini:line_exist(section_table[i], "value")) or not(char_ini:r_string(section_table[i], "value")) then
			return t_prorerty_name
		end
		value = char_ini:r_string(section_table[i], "value")
		if(name~="prop_night_vision") then
			sum = sum + tonumber(value)
		else
			sum = tonumber(value)
		end
	end
	if(sum<0) then
		value = string.format("%g",sum)
	else
		value = "+"..string.format("%g",sum)
	end
	
	---[[

	if(name=="prop_ammo_size" or name=="prop_artefact") then
		return t_prorerty_name.." "..value
	elseif(name=="prop_restore_bleeding" or name=="prop_restore_health" or name=="prop_power") then
		if(name=="prop_power") then
			value = "+"..tonumber(value)*2
		end
--		local str = string.format("%s %4.1f", t_prorerty_name, value)
--		return str
		return t_prorerty_name.." "..value
	elseif(name=="prop_tonnage" or name=="prop_weightoutfit" or name=="prop_weight") then
			local str = string.format("%s %5.2f %s", t_prorerty_name, value, game.translate_string("st_kg"))
			return str
	elseif(name=="prop_night_vision") then
		if(tonumber(value)==1) then
			return t_prorerty_name
		else
			return game.translate_string(prorerty_name.."_"..tonumber(value))
		end
	elseif(name=="prop_no_buck" or name=="prop_autofire") then
		return t_prorerty_name
	end
	return t_prorerty_name.." "..value.."%"
	
	--]]
end

function property_functor_b( param1, name )
	return issue_property( param1, name )
end

function property_functor_c( param1, name )
	return issue_property( param1, name )
end

function issue_property( param1, name )
	local prorerty_name = char_ini:r_string_ex(name, "name")
	local t_prorerty_name = game.translate_string(prorerty_name)
	local value_table = utils.parse_names(param1)
	local section = value_table[1]
	if section then
		if not char_ini:line_exist(section, "value") or not char_ini:r_string_ex(section, "value") then
			return t_prorerty_name
		end
		local value = char_ini:r_string_ex(section, "value")
		return t_prorerty_name.." "..string.sub(value, 2, -2)
	else
		return t_prorerty_name
	end
end

local function how_much_repair( item_name, item_condition, condition_type)
	local ltx = system_ini()
	local cost = ltx:r_u32(item_name, "cost")
	local class = ltx:r_string_ex(item_name, "class")
	local factor = 1.35
	
	local cond_price = 0
	for i = 1, 31 do
		if (items_condition.have_condition_type(condition_type, i)) then
			if (items_condition.condition_tier_3[i]) then
				cond_price = cond_price + 500
			elseif (items_condition.condition_tier_1[i]) then
				cond_price = cond_price + 1500
			elseif (items_condition.condition_tier_2[i]) then
				cond_price = cond_price + 2500
			end
		end
	end
	YourPrice = math.floor(( cost * ((1 * (1-item_condition)) / (1 / (1-item_condition))) + cond_price) * factor * cur_price_percent )
	return YourPrice
end

function can_repair_item( item_name, item_condition, condition_type, mechanic ) --( string, float, string )
	if(ekidona_mags.isMagazine(item_name))then return(false)end
	local price = how_much_repair( item_name, item_condition, condition_type )
	if db.actor:money() < price then
		return false
	end
	
	local ini = ini_file("plugins\\itms_manager.ltx")
	local CanRepair = alun_utils.collect_section(ini,"can_repair",true)
	local obj = db.actor:object(item_name)
	if (obj and IsArtefact(obj) and not CanRepair[obj:section()]) then 
		return false
	end

	return true
end

function question_repair_item( item_name, item_condition, condition_type, can, mechanic ) --( string, float, bool, string )
	if(ekidona_mags.isMagazine(item_name))then return("...")end
	local price = how_much_repair( item_name, item_condition, condition_type )
	if db.actor:money() < price then
		return game.translate_string("st_upgr_cost")..": "..price.." RU\\n"..game.translate_string("ui_inv_not_enought_money")..": "..price-db.actor:money().." RU"
	end
	
	local repair_time = (1-item_condition)*9000+30
	
	--[[
	if (RepairItemList[mechanic_name])
		for id,t in pairs(RepairItemList[mechanic_name]) do
			if (t.gt ~= nil) then
				local check_time = utils.clamp(t.rt - game.get_game_time():diffSec(t.gt),0,t.rt)
				if (max_time < check_time) then max_time = check_time end
			end
		end
		rt = rt+max_time
	end
	--]]
	
	local str = game.translate_string("st_upgr_cost").." "..price.." RU. "..game.translate_string("ui_st_inv_repair").."?"
	
	if (axr_main.config:r_value("mm_options","enable_mechanic_feature",1,false) == true) then 
		str = game.translate_string("st_upgr_cost").." "..price.." RU. "..game.translate_string("Time").." "..math.ceil(repair_time/60)..game.translate_string("ui_st_mins").." "..game.translate_string("ui_st_inv_repair").."?"
	end
	
	return str
end

function effect_upgrade_item(item,upgrade_section) -- Alundaio: called from engine (UIInventoryUpgradeWnd.cpp)
	if(ekidona_mags.isMWeapon(item:section()))then ekidona_mags.WeaponEjectMag(item)end
	if (axr_main.config:r_value("mm_options","enable_mechanic_feature",1,false) ~= true) then 
		return
	end
	
	local victim = victim_id and (db.storage[victim_id] and db.storage[victim_id].object or level.object_by_id(victim_id))
	if (victim) then
		lend_item_for_repair(item,victim:section(),1800)
	end
end 

function effect_repair_item( item_name, item_condition)

	local item
	local function itr(actor,itm)
		if (itm and itm:section() == item_name and itm:condition() == item_condition) then
			item = itm
			return true
		end
		return false
	end
	db.actor:iterate_inventory(itr,db.actor)
	
	local price = YourPrice
	db.actor:give_money(-price)
	YourPrice = 0

	if (IsWeapon(item)) then
		item:set_weapon_condition_type(0)
	end
	
	if (axr_main.config:r_value("mm_options","enable_mechanic_feature",1,false) ~= true) then 
		return
	end


	if (item) then
		local victim = victim_id and (db.storage[victim_id] and db.storage[victim_id].object or level.object_by_id(victim_id))
		if (victim) then
			local condition = item:condition()
			local repair_time = (1-condition)*9000+30
			lend_item_for_repair(item,victim:section(),repair_time)
		end
	end
end

function can_upgrade_item( item_name, mechanic )
	local victim = victim_id and (db.storage[victim_id] and db.storage[victim_id].object or level.object_by_id(victim_id))
	if not (victim) then 
		return 
	end
	local mechanic_name = victim:section()
	if param_ini:line_exist(mechanic_name, "discount_condlist") then
		local condlist = param_ini:r_string_ex(mechanic_name, "discount_condlist")
		local parsed = xr_logic.parse_condlist(db.actor, nil, nil, condlist)
		xr_logic.pick_section_from_condlist(db.actor, nil, parsed)
		return true
	end
	return false
end

function mech_discount(perc)
	cur_price_percent = perc
end