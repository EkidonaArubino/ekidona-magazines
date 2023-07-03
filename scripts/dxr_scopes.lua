--[[ Original code by Darryl123 /|\ Reworked by Ekidona Arubino (31.03.23) ||| (03.07.23)--]]
local addons_table=alun_utils.collect_sections(system_ini(),{"addons_table"})
function ReturnAddons() return(addons_table)end local precached_weapon_scopes,precached_scopes={},{}
local function on_game_load() if(is_empty(precached_scopes))then for k,v in pairs(addons_table)do precached_scopes[k]={}end end
if(is_empty(precached_weapon_scopes))then system_ini():section_for_each(function(sec)
	local parent_section=system_ini():r_string_ex(sec,"parent_section") if not(parent_section and sec==parent_section)then return end
	local dict={} for k,v in pairs(alun_utils.parse_list(system_ini(),sec,"scopes"))do if(v~="none")then dict[v]=true precached_scopes[v][sec]=true end end
	if not(is_empty(dict))then precached_weapon_scopes[sec]=dict else precached_weapon_scopes[sec]=false end
end)end end
local function on_item_focus(item) local inventory=ActorMenu.get_actor_menu()
	for k,v in pairs(precached_weapon_scopes[item:section()] or {})do inventory:highlight_section_in_slot(k,EDDListType.iActorBag)end
	for k,v in pairs(precached_scopes[item:section()] or {})do inventory:highlight_section_in_slot(k,EDDListType.iActorBag)end
end
local function drag_scope(addon,weapon,from_slot,to_slot) local asec,wsec=addon:section(),weapon:section()
	if not(addons_table[asec] and IsWeapon(weapon)and from_slot==EDDListType.iActorBag and(to_slot==EDDListType.iActorSlot or to_slot==EDDListType.iActorBag))then return end
	if not(precached_weapon_scopes[wsec] and precached_weapon_scopes[wsec][asec])or(items_condition.have_condition_type(weapon:get_weapon_condition_type(),28))then return end attach_addon(addon,weapon)
end
local function on_item_use(item) local wpns=precached_scopes[item:section()]
	if not(wpns)then return end for i=2,3 do local wpn=db.actor:item_in_slot(i)
		if(wpn and wpns[wpn:section()])then attach_addon(item,wpn) return end
end end
function on_game_start()
	if not(system_ini():section_exist("addons_table"))then return end
	on_game_load() RegisterScriptCallback("on_game_load",on_game_load)
	--RegisterScriptCallback("actor_on_item_use",on_item_use)
	RegisterScriptCallback("CUIActorMenu_OnItemFocusReceive",on_item_focus)
	RegisterScriptCallback("CUIActorMenu_OnItemDropped",drag_scope)
end
function attach_addon(addon,weapon) local asec,wsec=addon:section(),weapon:section()
	if not(addons_table[asec] and IsWeapon(weapon))then return end
	local parent_section=system_ini():r_string_ex(wsec,"parent_section") if not(parent_section and wsec==parent_section)then return end
	if not(precached_weapon_scopes[wsec] and precached_weapon_scopes[wsec][asec])then return end local child_section=(parent_section.."_"..asec)
	if not(system_ini():section_exist(child_section))then printf("!ERROR! addoned weapon doesn't exitst: %s",child_section) return end
	local old_weapon=alife_object(weapon:id()) if(old_weapon)then local wslot=GetWeaponSlot(weapon:id())
		local new_weapon=alife():clone_weapon(old_weapon,child_section,old_weapon.position,old_weapon.m_level_vertex_id,old_weapon.m_game_vertex_id,old_weapon.parent_id,false)
		if(new_weapon)then local grenades=bind_weapon.GetWeaponGrenadeAmmoDB(old_weapon.id) local need1,need2
			need1=ekidona_mags.GetMagazinesDB(old_weapon.id) need2=bind_weapon.GetWeaponMainAmmoDB(old_weapon.id)
			if(grenades and old_weapon:get_addon_flags():is(cse_alife_item_weapon.eWeaponAddonGrenadeLauncher))then
				create_ammo(system_ini():r_string_ex(wsec,"grenade_class"),db.actor:position(),db.actor:level_vertex_id(),db.actor:game_vertex_id(),0,1)
			end local addon_object=alife_object(addon:id()) alife():release(addon_object,true) alife():release(old_weapon,true)
			alife():register(new_weapon) bind_weapon.SetWeaponGrenadeAmmoDB(new_weapon.id,false)
			ekidona_mags.SetMagazinesDB(new_weapon.id,need1) bind_weapon.SetWeaponMainAmmoDB(new_weapon.id,need2)
			if(wslot)then TransWPNToSlot(new_weapon.id,wslot)end
		end
	end
end
function detach_addon(weapon) if not(weapon and IsWeapon(weapon))then return end local wsec,addonsec=weapon:section()
	local parent_section=system_ini():r_string_ex(wsec,"parent_section") if not(parent_section and wsec~=parent_section)then return end
	addonsec=wsec:sub(string.len(parent_section)+2,-1) if not(system_ini():section_exist(addonsec))then printf("!ERROR! addon section doesn't exitst: %s",addonsec) return end
	local old_weapon=alife_object(weapon:id()) if(old_weapon)then give_object_to_actor(addonsec) local wslot=GetWeaponSlot(weapon:id())
		local new_weapon=alife():clone_weapon(old_weapon,parent_section,old_weapon.position,old_weapon.m_level_vertex_id,old_weapon.m_game_vertex_id,old_weapon.parent_id,false)
		if(new_weapon)then local grenades=bind_weapon.GetWeaponGrenadeAmmoDB(old_weapon.id) local need1,need2
			need1=ekidona_mags.GetMagazinesDB(old_weapon.id) need2=bind_weapon.GetWeaponMainAmmoDB(old_weapon.id)
			if(grenades and old_weapon:get_addon_flags():is(cse_alife_item_weapon.eWeaponAddonGrenadeLauncher))then
				create_ammo(system_ini():r_string_ex(wsec,"grenade_class"),db.actor:position(),db.actor:level_vertex_id(),db.actor:game_vertex_id(),0,1)
			end alife():release(old_weapon,true) alife():register(new_weapon) bind_weapon.SetWeaponGrenadeAmmoDB(new_weapon.id,false)
			ekidona_mags.SetMagazinesDB(new_weapon.id,need1) bind_weapon.SetWeaponMainAmmoDB(new_weapon.id,need2)
			if(wslot)then TransWPNToSlot(new_weapon.id,wslot)end
	end end
end
function context_functor(weapon) if not(weapon:parent() and weapon:parent():id()==0)then return end
	if not(weapon)then return end local wsec,addonsec=weapon:section()
	local parent_section=system_ini():r_string_ex(wsec,"parent_section") if not(parent_section and wsec~=parent_section)then return end
	addonsec=wsec:sub(string.len(parent_section)+2,-1) if not(system_ini():section_exist(addonsec))then printf("!ERROR! addon section doesn't exitst: %s",addonsec) return end
	--local name=alun_utils.get_inv_name(addonsec) local nname=(string.lower(name:sub(1,1))..name:sub(2,-1)) return(game.translate_string("st_detach_addon").." "..nname)
	return(string.format(game.translate_string("st_detach_addon"),alun_utils.get_inv_name(addonsec)))
end
function GetWeaponSlot(wpnid) for i=1,5 do local swpn=db.actor:item_in_slot(i)
	if(swpn and swpn:id()==wpnid)then return(i)end
end end
function TransWPNToSlot(wpnid,wslot)
	CreateTimeEvent("TransWPNToSlot",wpnid,0,function(wid,sslot) local obj,inv=level.object_by_id(wid),ActorMenu.get_actor_menu()
		if(obj)then inv:ToSlot(obj,true,sslot) return(true)else return(false)end
	end,wpnid,wslot)
end function context_action_functor(item) detach_addon(item)end--MEH