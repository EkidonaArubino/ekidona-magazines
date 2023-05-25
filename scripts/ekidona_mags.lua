--[[--All by エキドナ　アルビノ (Ekidona Arubino)--]]--
--24.05.23 : 19:43 (JST)
--WaMArray,flag_weapon_jammed={},{} [meh]
local UIMenuActive,precahced_wmdata,precahced_magstowpn,precached_nonmagst=false,{},{},{}
function ReturnBoolUIMenuActive() return(UIMenuActive)end
function GetMagazinesDB(id) local mdata=alife_storage_manager.get_state()
	if not(mdata)then return(nil)end if not(mdata.MagazinesDB)then mdata.MagazinesDB={}end
	return(mdata.MagazinesDB[id])
end
function SetMagazinesDB(id,var) local mdata=alife_storage_manager.get_state()
	if not(mdata)then return end if not(mdata.MagazinesDB)then mdata.MagazinesDB={}end
	mdata.MagazinesDB[id]=var
end
function GetJammedDB(id) local mdata=alife_storage_manager.get_state()
	if not(mdata)then return(nil)end if not(mdata.JammedDB)then mdata.JammedDB={}end
	return(mdata.JammedDB[id])
end
function SetJammedDB(id,var) local mdata=alife_storage_manager.get_state()
	if not(mdata)then return end if not(mdata.JammedDB)then mdata.JammedDB={}end
	mdata.JammedDB[id]=var
end
-- Registration
function on_game_start() on_game_load()
	RegisterScriptCallback("on_game_load",on_game_load)
	RegisterScriptCallback("actor_on_net_destroy",actor_on_net_destroy)
	RegisterScriptCallback("on_key_release",on_key_release)
	RegisterScriptCallback("CUIActorMenu_OnItemDropped",drag_item)
	RegisterScriptCallback("CUIActorMenu_OnItemFocusReceive",on_item_focus)
	RegisterScriptCallback("actor_on_weapon_jammed",weapon_jammed)
	RegisterScriptCallback("actor_on_hud_animation_end",animation_end)
	RegisterScriptCallback("actor_on_trade",actor_on_trade)
end local sini=system_ini()
function on_game_load() UIMenuActive=false
	local function TableAlready(tbl) for k,v in pairs(tbl)do return(true)end return(false)end
	if not(TableAlready(precahced_wmdata))then local magscnt=0
	sini:section_for_each(function(sec) local etype=((sini:r_string_ex(sec,"mags_use")~=nil and 1)or(sini:r_bool_ex(sec,"is_mag")and 2)or((sini:r_float_ex(sec,"slots_for_magazines")or 0)>0 and 3))
		if not(etype)then local class=sini:r_string_ex(sec,"class")
			if(class and class:sub(1,3)=="WP_" and class~="WP_KNIFE" and class~="WP_BINOC")then
				local ammos=sini:r_string_ex(sec,"ammo_class")
				if(ammos)then precached_nonmagst[sec]={}
					for k,v in pairs(alun_utils.str_explode(ammos,","))do precached_nonmagst[sec][k-1]=v end
				end
			end return
		end precahced_wmdata[sec]={etype}
		if(etype==1)then precahced_wmdata[sec][2]={} precahced_wmdata[sec][5]={}
			for k,v in pairs(alun_utils.str_explode(sini:r_string_ex(sec,"mags_use"),","))do precahced_wmdata[sec][5][k]=v
				precahced_wmdata[sec][2][v]=true if not(precahced_magstowpn[v])then precahced_magstowpn[v]={}end precahced_magstowpn[v][sec]=true
			end precahced_wmdata[sec][3]={}
			for k,v in pairs(alun_utils.str_explode(sini:r_string_ex(sec,"ammo_class"),","))do precahced_wmdata[sec][3][k-1]=v:sub(1,-2)end
		elseif(etype==2)then precahced_wmdata[sec][2]={} magscnt=(magscnt+1) precahced_wmdata[sec][0]=magscnt precahced_wmdata[magscnt]=sec
			precahced_wmdata[sec][3]=alun_utils.str_explode(sini:r_string_ex(sec,"ammo_class"),",") precahced_wmdata[sec][4]=(sini:r_float_ex(sec,"unload_mag_size")or 1)
			for i=5,6 do precahced_wmdata[sec][i]={}end
			for k,v in pairs(precahced_wmdata[sec][3])do precahced_wmdata[sec][2][v]=k local msize=sini:r_float_ex(sec,"ammo_sizer_"..k)
				if(msize)then precahced_wmdata[sec][5][k]=math.max(math.floor(msize*sini:r_float_ex(sec,"max_mag_size")),1)end
				precahced_wmdata[sec][6][k]=sini:r_float_ex(sec,"ammo_sindex_"..k) -- meh
			end
		else precahced_wmdata[sec][2]=sini:r_float_ex(sec,"slots_for_magazines")end
	end) --[[local mfile,osecs=io.open("text_mags_gen.txt","a+"),{}
		for sec,v in pairs(precahced_wmdata)do if(v[1]==1)then
			osecs[(sini:r_string_ex(sec,"parent_section")or sec)]=true
		end end for sec,v in pairs(precahced_magstowpn)do local osec,usecs=sec:sub(5,-1)
			mfile:write(string.format('<string id="st_%s_name">\n    <text>%s</text>\n</string>\n',sec,
			string.format(game.translate_string("st_test_mag_gen_name"),(sini:section_exist(osec) and alun_utils.get_inv_name(osec))or "")))
			for wsec,v2 in pairs(v)do if(osecs[wsec])then
				if(usecs)then usecs=(usecs..", ")end usecs=((usecs or "")..alun_utils.get_inv_name(wsec))
			end end mfile:write(string.format('<string id="st_%s_descr">\n    <text>%s</text>\n</string>\n',sec,
			string.format(game.translate_string("st_test_mag_gen_descr"),usecs,tostring(sini:r_float_ex(sec,"max_mag_size")))))
		end mfile:close()]] end
end
function actor_on_net_destroy() UIMenuActive=false end
function isMWeapon(sec) return(precahced_wmdata[sec] and precahced_wmdata[sec][1]==1)end
function isMagazine(sec) return(precahced_wmdata[sec] and precahced_wmdata[sec][1]==2)end
function isMSuit(sec) return(precahced_wmdata[sec] and precahced_wmdata[sec][1]==3)end
function GetMagFromInd(ind) return(precahced_wmdata[ind])end
function GetIndFromMag(sec) return(precahced_wmdata[sec] and precahced_wmdata[sec][0])end
function GetAmmoIndFromMag(mag,asec) return(precahced_wmdata[mag][2][asec])end
function GetAmmoSecFromMag(mag,aind) return(precahced_wmdata[mag][3][aind])end
function GetMagSize(mag) return(precahced_wmdata[mag][4])end
function GetMagAmmoSize(mag,ammoind) return((ammoind and precahced_wmdata[mag][5][ammoind])or sini:r_float_ex(mag,"max_mag_size"))end
function GetMagAmmoSizeInd(mag,ammoind) return((ammoind and precahced_wmdata[mag][6][ammoind])or 1)end
function GetSuitMaxMags(sec) return(precahced_wmdata[sec][2])end
function GetSuitItemMaxMags(item) local mstat=GetSuitMaxMags(item:section())
	item:iterate_installed_upgrades(function(usec) local upset=system_ini():r_string_ex(usec,"section")
		mstat=(mstat+(system_ini():r_float_ex(upset,"add_slots_for_magazines")or 0))
	end) return(mstat)
end
function GetSuitUnloadCond(item,cond) local smax,addslots=GetSuitItemMaxMags(item),0
	if(db.actor:item_in_slot(7) and item:id()==db.actor:item_in_slot(7):id())then db.actor:iterate_inventory(function(temp,itm)
		if(db.actor:is_on_belt(itm))then addslots=(addslots+utils.round((system_ini():r_float_ex(itm:section(),"add_slots_for_magazines")or 0)*utils.clamp((itm:condition()-0.35)/0.25,0,1)))end
	end)end return(math.min(utils.round(smax*((cond or item:condition())/0.9)),smax)+addslots)
end
function GetMagazinesOnUnload(itm) if not(itm and isMSuit(itm:section()))then return end local magcnt=0 -- local outfit=(itm or db.actor:item_in_slot(7) or db.actor:item_in_slot(15))
	for k,v in pairs(GetMagazinesDB(itm:id()) or {})do magcnt=(magcnt+precahced_wmdata[precahced_wmdata[v[1]]][4])end
	return({magcnt,GetSuitUnloadCond(itm)})
end
function GetMagazineAmmoCount(data) local cnter=0
	for k,v in pairs(data or {})do cnter=(cnter+v[2])end return(cnter)
end
function IsAppropriateMagazine(wpn,mag) return(precahced_wmdata[wpn][2][mag])end
function weapon_jammed() SetJammedDB(db.actor:active_item():id(),true)end
function GetWeaponGrenadeLauncher(weapon) local grndtype=weapon:weapon_grenadelauncher_status()
	if(grndtype==0)then return(false) elseif(grndtype>=1)then return(weapon:weapon_in_grenade_mode())end
end
-- Menu functions
function unload_mag_functor(item) if(UIMenuActive)then return end local mdb=GetMagazinesDB(item:id())
	if(isMagazine(item:section()))then return(game.translate_string("st_unload_mag"))
	elseif(isMWeapon(item:section())and not(GetWeaponGrenadeLauncher(item))and(mdb or(item:get_ammo_in_magazine()>0)))then return(game.translate_string("st_eject_mag"))end return
end
function unload_mag_action_functor(item)
	if(isMagazine(item:section()))then ammo_trans_mag_ui(item):ShowDialog(true) else WeaponEjectMag(item)end
end
function outfit_unloading_menu(item) if(UIMenuActive)then return end
	if(#GetMagazinesDB(item:id())>0)then return(game.translate_string("st_unload_outfit"))end return
end
function outfit_unloading(item) mag_trans_wpn_ui(item,nil,true):ShowDialog(true)end
-- Mags and weapons procedures
function CreateMagazine(sec,pos,lvid,gvid,aid,ammo,rkoeff) local dbarray={}
	for k,v in pairs(ammo or {})do if(v[2]>0)then table.insert(dbarray,{GetRealAmmo(v[1]),v[2]})end end
	if(isMWeapon(sec))then sec=GetMagName(sec,1,2,GetMagazineAmmoCount(ammo)or 0,((dbarray[1] and dbarray[1][1])or nil),rkoeff)end
	for k,v in pairs(dbarray)do dbarray[k][1]=GetAmmoIndFromMag(sec,v[1])end
	local mag=alife():create(sec,pos,lvid,gvid,aid) SetMagazinesDB(mag.id,dbarray)
end
function BackAllINeed(item,prnt) prnt=(prnt or item:parent() or db.actor)
	if(isMWeapon(item:section()))then WeaponEjectMag(item)
	elseif(isMagazine(item:section()))then MagEjectAmmo(item)
	elseif(isMSuit(item:section()))then for k,v in pairs(GetMagazinesDB(item:id()))do local msec=GetMagFromInd(v[1]) 
		CreateMagazine(msec,prnt:position(),prnt:level_vertex_id(),prnt:game_vertex_id(),prnt:id(),GetAmmoArrayFromMag(msec,v[2]))
	end SetMagazinesDB(item:id(),{})end
end
-- Specialy for weapon mags
function SetWeaponAmmoParams(wpn,ammotype,ammocnt) wpn:unload_magazine() -- meh
	wpn:set_ammo_type(ammotype)wpn:set_ammo_elapsed(ammocnt)wpn:set_ammo_type(ammotype) --Don't ask me why i'm duplicated set_ammo_type().
end
local random_magazines={}
function GetMagName(sec,rtype,rres,ammoneed,ammosec,rkoef) rtype,rres=(rtype or 1),(rres or 1)
	if not(random_magazines[sec])then random_magazines[sec]={[1]={},[2]={}}
		for k,v in pairs(precahced_wmdata[sec][5])do table.insert(random_magazines[sec][1],precahced_wmdata[v][0]) table.insert(random_magazines[sec][2],v)end
	end local magazines,mocster,tcoster={},{},0
	for k,v in pairs(random_magazines[sec][2])do
		if not(ammoneed)or(GetMagAmmoSize(v,ammosec and GetAmmoIndFromMag(v,ammosec))>=ammoneed)then --XOR in action, meh
			if not(ammosec)or(GetAmmoIndFromMag(v,ammosec))then table.insert(magazines,random_magazines[sec][rres][k])
				if(rtype==1)then local cost=system_ini():r_float_ex(random_magazines[sec][2][k],"cost") table.insert(mocster,cost) tcoster=(tcoster+cost)end
	end end end if(rtype==2)then return(magazines)else local scost,pcost=math.max(0,math.min(tcoster*(rkoef or math.random()),tcoster)),0 table.sort(mocster,function(a,b) return(a>b)end)--yeap
		for k,v in pairs(mocster)do if(scost<=(v+pcost))then return(magazines[k])else pcost=(pcost+v)end end return(magazines[1])--meh
	end
end
function GetAmmoArrayFromMag(sec,array) local ammoarray={}
	for k,v in pairs(array)do ammoarray[k]={GetAmmoSecFromMag(sec,v[1]),v[2]}end return(ammoarray)
end
function WeaponEjectMag(weapon) local wmag=GetMagazinesDB(weapon:id())
	if not(wmag)then local ammoneed=weapon:get_ammo_in_magazine()
		if(ammoneed>0)then local ammosec=SelectAmmoTypeName(weapon,weapon:get_ammo_type())
			local magind=GetMagName(weapon:section(),nil,nil,ammoneed,ammosec)
			wmag={magind,{{GetAmmoIndFromMag(precahced_wmdata[magind],ammosec),ammoneed}}}
		else return end -- for "g_unlimitedammo"
	end local magsec=precahced_wmdata[wmag[1]] bind_weapon.SetWeaponMainAmmoDB(weapon:id(),nil)
	CreateMagazine(magsec,weapon:position(),weapon:level_vertex_id(),weapon:game_vertex_id(),weapon:parent():id(),GetAmmoArrayFromMag(magsec,wmag[2]))
	weapon:set_ammo_elapsed(0) SetMagazinesDB(weapon:id(),false)
end
function MagEjectAmmo(mag,cnt) local st=GetMagazinesDB(mag:id()) local msize=GetMagazineAmmoCount(st)
	if(msize<=0)then return elseif not(cnt and cnt>0)then cnt=msize end local ammodict,remover,msec={},{},mag:section()
	for i=#st,1,-1 do local useammo=math.min(cnt,st[i][2]) cnt=(cnt-useammo)
		ammodict[GetAmmoSecFromMag(msec,st[i][1])]=((ammodict[GetAmmoSecFromMag(msec,st[i][1])] or 0)+useammo)
		if(useammo==st[i][2])then table.insert(remover,i)end if(cnt<=0)then break end
	end if(#remover>0)then for i=#remover,1,-1 do table.remove(st,remover[i]-(#remover-i))end end xr_sound.set_sound_play(0,"inv_stack")
	for k,v in pairs(ammodict)do create_ammo(k,mag:position(),mag:level_vertex_id(),mag:game_vertex_id(),mag:parent():id(),v)end
end
-- Reload and other stuff
local reloadtb={0,0,0}-- I think it might save the mag before saving/loading the game and other annoying things.
function SetReloadArray(ary) reloadtb=(ary or {0,0,0})end
function on_key_release(key) if(UIMenuActive)then return end local weapon=db.actor:active_item()
	if(dik_to_bind(key)~=key_bindings.kWPN_RELOAD)or not(weapon)or(get_console():get_bool("g_unlimitedammo"))then return end
	if not(weapon and IsWeapon(weapon) and isMWeapon(weapon:section()) and not(GetWeaponGrenadeLauncher(weapon)))or(GetJammedDB(weapon:id()))or(weapon:get_state()==7)then return end
	local unloads={db.actor:item_in_slot(7),db.actor:item_in_slot(15)}
	for k,v in pairs(unloads)do if(v and isMSuit(v:section()) and #GetMagazinesDB(v:id())>0)then local switcher=unloads[math.abs(k-3)]
		mag_trans_wpn_ui(v,weapon,nil,(switcher and isMSuit(switcher:section()))and switcher):ShowDialog(true) return
	end end
end
function PlayReloadAnimation(weapon) local bool=false
	for k,v in pairs({2,3,5})do local itm=db.actor:item_in_slot(v)
		if(itm and itm:id()==weapon:id())then db.actor:activate_slot(v) bool=true break end
	end if not(bool)then local aslots,sslot=((system_ini():r_float_ex(weapon:section(),"slot")<4 and {2,3})or {5})
		for k,v in pairs(aslots)do if not(db.actor:item_in_slot(v))then sslot=v break end end
		ActorMenu.get_actor_menu():ToSlot(weapon,true,(sslot or aslots[math.random(1,#aslots)])) get_hud():HideActorMenu() return(false)
	end if(ActorMenu.get_actor_menu():IsShown())then get_hud():HideActorMenu() return(false)end weapon:switch_state(7) return(true)
end
function animation_end(item,section,motion,state,slot)-- printf("%s: %s; %s",section,state,slot)
	if(state==7)and(GetJammedDB(item:id()))then SetJammedDB(item:id(),nil)end
	if(not(reloadtb[5])or(reloadtb[5]~=item:id()))then if(state~=2)then reloadtb={0,0,0}end return end
	if(state==7)then
		SetWeaponAmmoParams(item,reloadtb[3],reloadtb[1]) if(reloadtb[7])then
			SetMagazinesDB(item:id(),{(reloadtb[4] and precahced_wmdata[reloadtb[4]][0]),reloadtb[7]})
		end if(reloadtb[6])then if(reloadtb[6][1])then table.remove(GetMagazinesDB(reloadtb[6][2]),reloadtb[2])
			else local ammo=level.object_by_id(reloadtb[6][2])
				if(ammo:ammo_get_count()==reloadtb[2])then alife():release(alife_object(reloadtb[6][2]))
				else ammo:ammo_set_count(ammo:ammo_get_count()-reloadtb[2])end
			end
		else alife():release(alife_object(reloadtb[2]),true)end reloadtb={0,0,0}
	elseif(state==1)then item:switch_state(7) else reloadtb={0,0,0} end
end
-- Mag to weapon
function IsFakeAmmo(sec) return(sini:r_string_ex(sec,"script_binding")=="bind_weapon.fammo_bind")end
function GetRealAmmo(sec) return((IsFakeAmmo(sec) and sec:sub(1,-2))or sec)end
local weapon_upgrades={}
function GenerateWpnUpg(upgrade,ammovar) local upgrade_sect=sini:r_string_ex(upgrade,"section")
	if(weapon_upgrades[upgrade_sect]==nil)then
		if(sini:r_string_ex(upgrade_sect,"ammo_class"))then weapon_upgrades[upgrade_sect]={}
			for k,v in pairs(alun_utils.parse_list(sini,upgrade_sect,"ammo_class"))do local sec=GetRealAmmo(v)
				weapon_upgrades[upgrade_sect][k-1]=sec weapon_upgrades[upgrade_sect][sec]=(k-1)
			end
		else weapon_upgrades[upgrade_sect]=false end
	end if(weapon_upgrades[upgrade_sect])then
		if(ammovar)then return(weapon_upgrades[upgrade_sect][ammovar])else return(weapon_upgrades[upgrade_sect])end
	end
end
function SelectAmmoTypeName(weapon,ammotype) local sec=weapon:section()--(you can use ":get_ammo_name()", but "SelectAmmoType"... don't forget about fake ammo!)
	if not(precahced_wmdata[sec])then return(precached_nonmagst[sec][ammotype])end
	local wdata,dontuse=stpk_utils.get_weapon_data(alife_object(weapon:id())),false
	for k,v in pairs((wdata and wdata.upgrades)or {})do local selected=GenerateWpnUpg(v,ammotype)
		if(selected)then return(selected)end dontuse=((GenerateWpnUpg(v)~=nil)or dontuse)
	end if not(dontuse)then return(precahced_wmdata[sec][3][ammotype])end
end
local ammotype_to_ind={}
function SelectAmmoType(weapon,atype) if not(atype)then return(nil)end
	local wdata,dontuse=stpk_utils.get_weapon_data(alife_object(weapon:id())),false
	for k,v in pairs((wdata and wdata.upgrades)or {})do local selected=GenerateWpnUpg(v,atype)
		if(selected)then return(selected)end dontuse=((GenerateWpnUpg(v)~=nil)or dontuse)
	end if(dontuse)then return(nil)end local sec=weapon:section()
	if not(ammotype_to_ind[sec])then ammotype_to_ind[sec]={}
		for k,v in pairs((precahced_wmdata[sec] and precahced_wmdata[sec][3])or precached_nonmagst[sec])do ammotype_to_ind[sec][v]=k end
	end return(ammotype_to_ind[sec][atype])
end
function WeaponAttemptToLoadMagazine(weapon,item) local wsec,msec=weapon:section(),item:section()
	if not(IsAppropriateMagazine(wsec,msec) and weapon:get_state()~=7)then return(false)end --if(#mst==0)then return(false)end 
	local mst=GetMagazinesDB(item:id()) local ammotype=((#mst>0 and SelectAmmoType(weapon,precahced_wmdata[msec][3][mst[#mst][1]]))or 0)
	if not(ammotype)then return(false)end reloadtb={GetMagazineAmmoCount(mst),item:id(),ammotype,item:section(),weapon:id(),nil,mst}
	WeaponEjectMag(weapon) return(true)
end
-- Item focus
function on_item_focus(item) local inventory=ActorMenu.get_actor_menu()
	if not(inventory and inventory:IsShown())then return end local sec=item:section()
	if(isMWeapon(sec))then for k,v in pairs(precahced_wmdata[sec][2])do inventory:highlight_section_in_slot(k,EDDListType.iActorBag)end
	elseif(isMagazine(sec))then for k,v in pairs(precahced_magstowpn[sec])do inventory:highlight_section_in_slot(k,EDDListType.iActorBag)end end
end
-- Drag-and-drop. here
function drag_item(item,item2,from_slot,to_slot)
	if(IsInvbox(item2:parent())or IsInvbox(item:parent()))
	or(not(from_slot>=1 and from_slot<=3)or not(to_slot>=1 and to_slot<=3))
	or(item:id()==item2:id())then return end local st=GetMagazinesDB(item2:id())
	if(isMagazine(item:section()))and(isMWeapon(item2:section())and not(GetWeaponGrenadeLauncher(item2)))then local loading_state=WeaponAttemptToLoadMagazine(item2,item)
		if(loading_state)then CreateTimeEvent("EkiMagsReload",item2:id(),0,PlayReloadAnimation,item2)end
	elseif(isMagazine(item:section()))and(isMSuit(item2:section()))then local st,pdata=GetMagazinesDB(item:id()),GetMagazinesOnUnload(item2)
		if(pdata[1]+GetMagSize(item:section())>pdata[2])then return end table.insert(GetMagazinesDB(item2:id()),{precahced_wmdata[item:section()][0],st})
		alife():release(alife_object(item:id()),true) xr_sound.set_sound_play(0,"inv_stack")
	end
end
-- Trading/Barter
function actor_on_trade(obj,sell_bye,money)
	local sec,parent=obj:section(),((sell_bye and db.actor)or level.object_by_id(inventory_upgrades.victim_id))
	if(isMagazine(sec))then MagEjectAmmo(obj) elseif(isMWeapon(sec))then
		if(parent:id()~=0 and IsTrader(parent))then give_object_to_actor(GetMagName(sec,2,2,nil,SelectAmmoTypeName(obj,obj:get_ammo_type()))[1],2)else WeaponEjectMag(obj)end
	elseif(isMSuit(sec))then for k,v in pairs(GetMagazinesDB(obj:id()))do local msec=GetMagFromInd(v[1]) 
			CreateMagazine(msec,parent:position(),parent:level_vertex_id(),parent:game_vertex_id(),parent:id(),GetAmmoArrayFromMag(msec,v[2]))
		end SetMagazinesDB(obj:id(),{})
	end
end
-- Ammo sort
function ammo_sorter_menu(obj) return(obj:ammo_get_count()>1 and game.translate_string("st_sort_ammo"))end
function ammo_sorter(obj) ammo_sort_ui(obj):ShowDialog(true)end
--UI menus
function GetTFrectFromSec(sec)
	local frec={sini:r_float_ex(sec,"inv_grid_x")*50,sini:r_float_ex(sec,"inv_grid_y")*50}
	frec[3]=frec[1]+(sini:r_float_ex(sec,"inv_grid_width")*50) frec[4]=frec[2]+(sini:r_float_ex(sec,"inv_grid_height")*50)
	return frec
end
class "ammo_sort_ui" (CUIScriptWnd)
function ammo_sort_ui:__init(obj) super() UIMenuActive=true
	self.section,self.obj,self.ammo_use=obj:section(),obj,1 self:InitControls()
	RegisterScriptCallback("actor_on_before_death",self) RegisterScriptCallback("actor_on_update",self)
end
function ammo_sort_ui:__finalize()end
function ammo_sort_ui:InitControls() self:SetWndRect(Frect():set(0,0,1024,768)) self:SetWndPos(vector2():set(0,0)) self:SetAutoDelete(true) local xml=CScriptXmlInit() xml:ParseFile("ui_eki_mags.xml")
	local ammo_icon=GetTFrectFromSec(self.section) local ammowsize={ammo_icon[3]-ammo_icon[1],ammo_icon[4]-ammo_icon[2]} self.form=xml:InitStatic("menu_extra:form",self)
	local fsize={10+ammowsize[1]+85,10+ammowsize[2]+10} self.form:SetWndSize(vector2():set(unpack(fsize))) self.form:SetWndPos(vector2():set(512-(fsize[1]/2),384-(fsize[2]/2)))
	for i=1,(math.floor(ammowsize[2]/50))do for p=1,math.floor(ammowsize[1]/50)do
		local form=xml:InitStatic("menu_extra:form:slot",self.form) form:SetWndPos(vector2():set(10+(50*(p-1)),10+(50*(i-1))))
	end end local form=xml:InitStatic("menu_extra:form:icon",self.form) form:InitTexture("ui\\ui_icon_equipment")
	form:SetTextureRect(Frect():set(unpack(ammo_icon))) form:SetWndPos(vector2():set(10,10)) form:SetWndSize(vector2():set(unpack(ammowsize)))
	local ctrl=xml:InitTextWnd("menu_extra:form:textcapc",self.form) ctrl:SetWndSize(vector2():set(25,25))
	ctrl:SetWndPos(vector2():set(10+ammowsize[1]-25,10+ammowsize[2]-25)) ctrl:SetText(self.obj:ammo_get_count())
	ctrl=xml:Init3tButton("menu_extra:form:button2",self.form) ctrl:SetWndPos(vector2():set(10+ammowsize[1],10)) ctrl:TextControl():SetText("+") self:Register(ctrl,"button_plus")
	ctrl=xml:Init3tButton("menu_extra:form:button2",self.form) ctrl:SetWndPos(vector2():set(10+ammowsize[1],10+ammowsize[2]-25)) ctrl:TextControl():SetText("-") self:Register(ctrl,"button_minus")
	ctrl=xml:InitStatic("menu_extra:form:slot",self.form) ctrl:SetWndPos(vector2():set(10+ammowsize[1]+25,10+(ammowsize[2]/2)-25))
	self.ammouse=xml:InitTextWnd("menu_extra:form:textcapc",ctrl) self.ammouse:SetText(self.ammo_use) self:AddCallback("button_cancel",ui_events.BUTTON_CLICKED,self.ExitMenu,self)
	self:AddCallback("button_sort",ui_events.BUTTON_CLICKED,self.OnButton_sort,self) self:AddCallback("button_plus",ui_events.BUTTON_CLICKED,self.OnButton_plus,self)
	self:AddCallback("button_minus",ui_events.BUTTON_CLICKED,self.OnButton_minus,self)
end
function ammo_sort_ui:OnButton_plus() self.ammo_use=math.min(self.ammo_use+1,self.obj:ammo_get_count()-1) self.ammouse:SetText(self.ammo_use)end
function ammo_sort_ui:OnButton_minus() self.ammo_use=math.max(self.ammo_use-1,1) self.ammouse:SetText(self.ammo_use)end
function ammo_sort_ui:OnButton_sort() self.obj:ammo_set_count(self.obj:ammo_get_count()-self.ammo_use) local parent=self.obj:parent()
	create_ammo(self.section,parent:position(),parent:level_vertex_id(),parent:game_vertex_id(),parent:id(),self.ammo_use)
	xr_sound.set_sound_play(0,"inv_stack") self:ExitMenu()
end function ammo_sort_ui:OnKeyboard(dik,keyboard_action) CUIScriptWnd.OnKeyboard(self,dik,keyboard_action)
	if(keyboard_action==ui_events.WINDOW_KEY_PRESSED)then local bind=dik_to_bind(dik)
		if(dik==DIK_keys.DIK_RETURN or bind==key_bindings.kUSE)then self:OnButton_sort()
		elseif(dik==DIK_keys.DIK_ESCAPE)then self:ExitMenu()
		elseif(dik==DIK_keys.DIK_UP or dik==DIK_keys.DIK_NUMPAD8 or bind==key_bindings.kFWD)then self:OnButton_plus()
		elseif(dik==DIK_keys.DIK_DOWN or dik==DIK_keys.DIK_NUMPAD2 or bind==key_bindings.kBACK)then self:OnButton_minus()end
	end return(true)
end
function ammo_sort_ui:actor_on_update() if(self)then
	if(self.health and self.health-db.actor.health>=0.02)then self:ExitMenu() else self.health=db.actor.health end
end end
function ammo_sort_ui:actor_on_before_death() if(self)then self:ExitMenu()end end
function ammo_sort_ui:ExitMenu() UIMenuActive=false UnregisterScriptCallback("actor_on_before_death",self) UnregisterScriptCallback("actor_on_update",self) self:HideDialog()end
local function GetAmmoCnt(sec) local cnt=0
	db.actor:iterate_inventory(function(temp,item)
		if(item:section()==sec)then cnt=(cnt+item:ammo_get_count())end
	end) return(cnt)
end local function AddAmmoToActor(sec) local used=false
	db.actor:iterate_inventory(function(temp,item) if(used)then return end
		if(item:section()==sec and item:ammo_get_count()<item:ammo_box_size())then
			item:ammo_set_count(item:ammo_get_count()+1) used=true
	end end) if not(used)then create_ammo(sec,db.actor:position(),db.actor:level_vertex_id(),db.actor:game_vertex_id(),0,1)end
end local function RemoveAmmoFromActor(sec) local used=false
	db.actor:iterate_inventory(function(temp,item) if(used)then return end
		if(item:section()==sec)then if(item:ammo_get_count()==1)then alife():release(alife_object(item:id()),true)
		else item:ammo_set_count(item:ammo_get_count()-1)end used=true
	end end) return(used)
end local atmbtntbl={{"<","button_in",-25,-12.5},{">","button_out",0,-12.5},{"U","button_up",-12.5,-37.5},{"D","button_down",-12.5,12.5}}
class "ammo_trans_mag_ui" (CUIScriptWnd)
function ammo_trans_mag_ui:__init(mag) super() UIMenuActive=true self.mag=mag
	RegisterScriptCallback("actor_on_before_death",self) RegisterScriptCallback("actor_on_update",self)
	self:SetWndRect(Frect():set(0,0,1024,768)) self:SetWndPos(vector2():set(0,0))
	self:SetAutoDelete(true) self.xml=CScriptXmlInit() self.xml:ParseFile("ui_eki_mags.xml") self.form=self.xml:InitStatic("menu_extra:form",self)
	local mag_icon=GetTFrectFromSec(mag:section()) local mag_size={mag_icon[3]-mag_icon[1],mag_icon[4]-mag_icon[2]} self.ammo={} local asizes={100,mag_size[2]}
	for ammoind,ammosec in pairs(precahced_wmdata[mag:section()][3])do self.ammo[ammoind]={}
		self.ammo[ammoind][1]=self.xml:InitStatic("menu_extra:form:icon",self.form) local ammo_icon=GetTFrectFromSec(ammosec)
		self.ammo[ammoind][1]:InitTexture("ui\\ui_icon_equipment") self.ammo[ammoind][1]:SetTextureRect(Frect():set(unpack(ammo_icon)))
		local sizer={ammo_icon[3]-ammo_icon[1],ammo_icon[4]-ammo_icon[2]} self.ammo[ammoind][1]:SetWndSize(vector2():set(unpack(sizer)))
		for k,v in pairs(asizes)do asizes[k]=math.max(v,sizer[k])end self.ammo[ammoind][2]=self.xml:InitTextWnd("menu_extra:form:textcapc",self.form)
		self.ammo[ammoind][2]:SetWndSize(vector2():set(math.max(sizer[1],100),20)) self.ammo[ammoind][2]:SetTextColor(GetARGB(255,0,255,0))
		for k,v in pairs(self.ammo[ammoind])do v:Show(false)end
	end local cform=self.xml:InitStatic("menu_extra:form:icon",self.form) cform:InitTexture("ui\\ui_icon_equipment") cform:SetTextureRect(Frect():set(unpack(mag_icon)))
	cform:SetWndSize(vector2():set(unpack(mag_size))) cform:SetWndPos(vector2():set(20+((asizes[1]/2)-(mag_size[1]/2)),20+((asizes[2]/2)-(mag_size[2]/2))))
	self.magammo=self.xml:InitTextWnd("menu_extra:form:textcapc",self.form) self.magammo:SetWndSize(vector2():set(100,20))
	self.magammo:SetWndPos(vector2():set(20+((asizes[1]/2)-50),cform:GetWndPos().y+mag_size[2])) self.magammo:SetTextColor(GetARGB(255,0,255,0))
	self:UpdateMagTxt() local maxs,amaxx={20+asizes[1]+25,20+(asizes[2]/2)},(20+asizes[1]+50)
	for k,v in pairs(atmbtntbl)do local buttonf=self.xml:Init3tButton("menu_extra:form:button2",self.form)
		buttonf:TextControl():SetText(v[1]) self:Register(buttonf,v[2]) buttonf:SetWndPos(vector2():set(maxs[1]+v[3],maxs[2]+v[4]))
	end for k,v in pairs(self.ammo)do v[1]:SetWndPos(vector2():set(amaxx+((asizes[1]/2)-(v[1]:GetWidth()/2)),20+((asizes[2]/2)-(v[1]:GetHeight()/2))))
		v[2]:SetWndPos(vector2():set(amaxx+((asizes[1]/2)-(v[2]:GetWidth()/2)),v[1]:GetWndPos().y+v[1]:GetHeight()))
	end self:GetAmmoLocal(1) self:AddCallback("button_out",ui_events.BUTTON_CLICKED,self.OnButton_out,self) self:AddCallback("button_in",ui_events.BUTTON_CLICKED,self.OnButton_in,self)
	self:AddCallback("button_up",ui_events.BUTTON_CLICKED,self.OnButton_up,self) self:AddCallback("button_down",ui_events.BUTTON_CLICKED,self.OnButton_down,self) self.timeg=time_global()
	self.form:SetWndSize(vector2():set((asizes[1]*2)+90,55+asizes[2])) self.form:SetWndPos(vector2():set(512-(self.form:GetWidth()/2),384-(self.form:GetHeight()/2)))
end
function ammo_trans_mag_ui:ICheckTimeUpdate() local tg=time_global()
	if(tg~=self.timeg)then self.timeg=tg return(false)end return(true)--meh
end
function ammo_trans_mag_ui:UpdateMagTxt() local st=GetMagazinesDB(self.mag:id()) local ammocnt=GetMagazineAmmoCount(st)
	if(ammocnt>0)then self.magammo:SetText("("..ammocnt..") "..game.translate_string(system_ini():r_string_ex(GetAmmoSecFromMag(self.mag:section(),st[#st][1]),"inv_name_short")))
	else self.magammo:SetText("......")end
end
function ammo_trans_mag_ui:GetAmmoLocal(ind) self.aind=ind
	for k,v in pairs(self.ammo)do for k2,v2 in pairs(v)do v2:Show(k==ind)end
		if(k==ind)then local ammosec=GetAmmoSecFromMag(self.mag:section(),k)
			v[2]:SetText(game.translate_string(system_ini():r_string_ex(ammosec,"inv_name_short")).." ("..GetAmmoCnt(ammosec)..")")
end end end
function ammo_trans_mag_ui:OnButton_out() if(self:ICheckTimeUpdate())then return end local st=GetMagazinesDB(self.mag:id())
	if(GetMagazineAmmoCount(st)<=0)then return end AddAmmoToActor(GetAmmoSecFromMag(self.mag:section(),st[#st][1]))
	if(st[#st][2]==1)then table.remove(st,#st)else st[#st][2]=(st[#st][2]-1)end self.updateme=true
end
function ammo_trans_mag_ui:OnButton_in() if(self:ICheckTimeUpdate())then return end local st=GetMagazinesDB(self.mag:id())
	if(GetMagazineAmmoCount(st)>=GetMagAmmoSize(self.mag:section(),st[1] and st[1][1]))
	or(GetMagAmmoSizeInd(self.mag:section(),self.aind)~=GetMagAmmoSizeInd(self.mag:section(),st[1] and st[1][1]))then return end
	if not(RemoveAmmoFromActor(GetAmmoSecFromMag(self.mag:section(),self.aind)))then return end self.updateme=true
	if(st[1] and st[#st][1]==self.aind)then st[#st][2]=(st[#st][2]+1)else table.insert(st,{self.aind,1})end
end
function ammo_trans_mag_ui:OnButton_up()
	if(self:ICheckTimeUpdate())or(self.aind<=1)then return end
	self.aind=(self.aind-1) self.updateme=true
end function ammo_trans_mag_ui:OnButton_down()
	if(self:ICheckTimeUpdate())or(self.aind>=#precahced_wmdata[self.mag:section()][3])then return end
	self.aind=(self.aind+1) self.updateme=true
end
function ammo_trans_mag_ui:actor_on_update() if(self)then
	if(self.updateme)then self:GetAmmoLocal(self.aind) self:UpdateMagTxt() self.updateme=false end --meh
	if(self.health and self.health-db.actor.health>=0.02)then self:CloseMenu() else self.health=db.actor.health end
end end
function ammo_trans_mag_ui:actor_on_before_death() if(self)then self:CloseMenu()end end
function ammo_trans_mag_ui:CloseMenu()
	UnregisterScriptCallback("actor_on_before_death",self) UnregisterScriptCallback("actor_on_update",self) UIMenuActive=false self:HideDialog()
end
function ammo_trans_mag_ui:OnKeyboard(dik,keyboard_action) local bind=dik_to_bind(dik)
	CUIScriptWnd.OnKeyboard(self,dik,keyboard_action)
	if(keyboard_action==ui_events.WINDOW_KEY_PRESSED)then
		if(dik==DIK_keys.DIK_ESCAPE)then self:CloseMenu()
		elseif(dik==DIK_keys.DIK_RETURN or bind==key_bindings.kUSE)then MagEjectAmmo(self.mag) self:CloseMenu()
		elseif(bind==key_bindings.kL_STRAFE or dik==DIK_keys.DIK_LEFT or dik==DIK_keys.DIK_NUMPAD4)then self:OnButton_in()
		elseif(bind==key_bindings.kR_STRAFE or dik==DIK_keys.DIK_RIGHT or dik==DIK_keys.DIK_NUMPAD6)then self:OnButton_out()
		elseif(bind==key_bindings.kFWD or dik==DIK_keys.DIK_NUMPAD8 or dik==DIK_keys.DIK_UP)then self:OnButton_up()
		elseif(bind==key_bindings.kBACK or dik==DIK_keys.DIK_NUMPAD2 or dik==DIK_keys.DIK_DOWN)then self:OnButton_down()end
	end return(true)
end
class "set_mag_list_item" (CUIStatic) local uisseter={{-25,"U"},{0,"D"}}
function set_mag_list_item:__init(msec,mdb,sort) super() local xml=CScriptXmlInit() xml:ParseFile("ui_eki_mags.xml")
	self:InitTexture("ui_ekidona_magazines_back_1") self:SetStretchTexture(true)
	self.icon=xml:InitStatic("menu_extra:form:icon",self) self.icon:InitTexture("ui\\ui_icon_equipment")
	self.text=xml:InitTextWnd("menu_extra:form:textcapc",self) self.sortcaps={xml:InitTextWnd("menu_extra:form:textcapc",self),xml:InitTextWnd("menu_extra:form:textcapc",self)}
	for k,v in pairs(self.sortcaps)do v:SetText(uisseter[k][2]) v:SetWndSize(vector2():set(25,25)) v:Show(false)end
	self.button=xml:Init3tButton("menu_extra:form:icon",self) self:Rename(msec,mdb,sort)
end function set_mag_list_item:Rename(msec,mdb,sort) local _frect=GetTFrectFromSec(msec)
	local _size={_frect[3]-_frect[1],_frect[4]-_frect[2]} self.icon:SetTextureRect(Frect():set(unpack(_frect))) local text=(alun_utils.get_inv_name(msec)..": ")
	self.icon:SetWndSize(vector2():set(_size[1],_size[2])) self.text:SetWndSize(vector2():set(((sort and sort>0 and 210)or 244)-_size[1],_size[2])) self.text:SetWndPos(vector2():set(_size[1],0))
	if(mdb and mdb[1])then text=(text..string.format(game.translate_string("st_magazine_contain"),GetMagazineAmmoCount(mdb)))
		text=(text.." "..game.translate_string(system_ini():r_string_ex(GetAmmoSecFromMag(msec,mdb[#mdb][1]),"inv_name_short")))
	else text=(text..game.translate_string("st_magazine_is_empty"))end self.text:SetText(text)
	for k,v in pairs(self.sortcaps)do
		if(sort and bit_and(k,sort)>0)then v:Show(true) v:SetWndPos(vector2():set(220,(_size[2]/2)+uisseter[k][1]))else v:Show(false)end
	end self.button:SetWndSize(vector2():set(242,_size[2])) self:SetWndSize(vector2():set(244,_size[2]))
end
class "mag_trans_wpn_ui" (CUIScriptWnd)
function mag_trans_wpn_ui:__init(outfit,weapon,onlyunload,switchobj) super() UIMenuActive=true
	self.outfit,self.weapon,self.onlyunload,self.switchobj=outfit,weapon,onlyunload,switchobj self:InitControls()
	RegisterScriptCallback("actor_on_before_death",self) RegisterScriptCallback("actor_on_update",self)
end
function mag_trans_wpn_ui:GenerateMagsUI() local ly=0--self.list:RemoveAll()
	for k,v in pairs(GetMagazinesDB(self.outfit:id()))do local msec=precahced_wmdata[v[1]]
		if(self.mforms[k])then self.mforms[k]:Rename(msec,v[2],(self.onlyunload and #GetMagazinesDB(self.outfit:id())>1 and((k==1 and 2)or(k==#GetMagazinesDB(self.outfit:id()) and 1)or 3)))else
		self.mforms[k]=set_mag_list_item(msec,v[2],(self.onlyunload and #GetMagazinesDB(self.outfit:id())>1 and((k==1 and 2)or(k==#GetMagazinesDB(self.outfit:id()) and 1)or 3)))
		self:Register(self.mforms[k].button,"bmag") self:AddCallback("bmag",ui_events.BUTTON_CLICKED,self.OnButton_click,self) self.list:AddWindow(self.mforms[k])end
		self.mforms[k]:SetWndPos(vector2():set(0,ly)) ly=(ly+self.mforms[k]:GetHeight())
	end
end
function mag_trans_wpn_ui:InitControls()
	self:SetWndRect(Frect():set(0,0,1024,768)) self:SetWndPos(vector2():set(0,0))
	self:SetAutoDelete(true) self.xml=CScriptXmlInit() self.xml:ParseFile("ui_eki_mags.xml")
	self.form=self.xml:InitStatic("menu_extra:form",self) self.form:SetWndSize(vector2():set(266,384))
	self.form:InitTexture("ui_ekidona_magazines_back_2") local vecpos=vector2()
	if(self.onlyunload)then vecpos:set(379,192)else vecpos:set(2,368)end self.form:SetWndPos(vecpos) self.mforms={} local lx,ly=0,0
	self.list=self.xml:InitListBox("menu_extra:form:magazines_list"..((self.switchobj and "_2")or ""),self.form) self:GenerateMagsUI()
	if(self.switchobj)then local form=self.xml:InitTextWnd("menu_extra:form:textcapc",self.form) form:SetWndPos(vector2():set(8,8))
		form:SetWndSize(vector2():set(254,24)) form:SetText(alun_utils.get_inv_name(self.switchobj:section())) form=self.xml:Init3tButton("menu_extra:form:icon",self.form)
		form:SetWndPos(vector2():set(8,8)) form:SetWndSize(vector2():set(254,24)) self:Register(form,"switch") self:AddCallback("switch",ui_events.BUTTON_CLICKED,self.OnButton_switch,self)
	end
end
function mag_trans_wpn_ui:SortThatMag(ind,sort) local st=GetMagazinesDB(self.outfit:id()) local nst={} if not(st[ind])then return end
	if(sort==1)then for i=1,(ind-2)do nst[i]=st[i]end nst[ind-1],nst[ind]=st[ind],st[ind-1] for i=1,(#st-ind)do nst[ind+i]=st[ind+i]end
	else for i=1,(ind-1)do nst[i]=st[i]end nst[ind],nst[ind+1]=st[ind+1],st[ind] for i=1,(#st-(ind+1))do nst[ind+i+1]=st[ind+i+1]end end
	SetMagazinesDB(self.outfit:id(),nst) self:GenerateMagsUI() xr_sound.set_sound_play(0,"inv_stack")
end
function mag_trans_wpn_ui:AttachThatMag(ind) local st=(GetMagazinesDB(self.outfit:id())and GetMagazinesDB(self.outfit:id())[ind])
	if not(self.onlyunload)and(st and st[1])then local ammocnt=GetMagazineAmmoCount(st[2])
		if not(IsAppropriateMagazine(self.weapon:section(),precahced_wmdata[st[1]]) and self.weapon:get_state()~=7 and ammocnt>0)then return(false)end
		local ammotype=((#st[2]>0 and SelectAmmoType(self.weapon,precahced_wmdata[precahced_wmdata[st[1]]][3][st[2][#st[2]][1]]))or 0)
		reloadtb={ammocnt,ind,ammotype,precahced_wmdata[st[1]],self.weapon:id(),{true,self.outfit:id()},st[2]}
		local pmag=GetMagazinesDB(self.weapon:id()) if(pmag)then local uused=false
			for k,v in pairs({self.outfit,self.switchobj})do if(v)then local pdata=GetMagazinesOnUnload(v)
				if((pdata[2]-pdata[1])>=GetMagSize(GetMagFromInd(pmag[1])))then table.insert(GetMagazinesDB(v:id()),pmag)
					bind_weapon.SetWeaponMainAmmoDB(self.weapon:id(),nil) SetMagazinesDB(self.weapon:id(),false)
					self.weapon:set_ammo_elapsed(0) uused=true break
				end
			end end if not(uused)then WeaponEjectMag(self.weapon)end
		end xr_sound.set_sound_play(0,"inv_stack") -- get_hud():HideActorMenu() 
		CreateTimeEvent("EkiMagsReload",self.weapon:id(),0,PlayReloadAnimation,self.weapon) self:ExitMenu() -- 0.1
	elseif(st)then local msec=precahced_wmdata[st[1]] xr_sound.set_sound_play(0,"inv_stack")
		CreateMagazine(msec,db.actor:position(),db.actor:level_vertex_id(),db.actor:game_vertex_id(),0,GetAmmoArrayFromMag(msec,st[2]))
		table.remove(GetMagazinesDB(self.outfit:id()),ind) self.list:RemoveWindow(self.mforms[ind]) table.remove(self.mforms,ind) self:GenerateMagsUI()
	end
end
function mag_trans_wpn_ui:OnKeyboard(dik,keyboard_action)
	local bind=dik_to_bind(dik)
	CUIScriptWnd.OnKeyboard(self,dik,keyboard_action)
	if(keyboard_action==ui_events.WINDOW_KEY_PRESSED)then
		if(dik==DIK_keys.DIK_ESCAPE)then self:ExitMenu()
		elseif(dik>=2 and dik<=11)then self:AttachThatMag(dik-1)
		elseif(bind==key_bindings.kLEFT or bind==key_bindings.kUSE or bind==key_bindings.kRIGHT or
		bind==key_bindings.kL_STRAFE or bind==key_bindings.kR_STRAFE or dik==DIK_keys.DIK_RIGHT or dik==DIK_keys.DIK_NUMPAD6
		or dik==DIK_keys.DIK_LEFT or dik==DIK_keys.DIK_NUMPAD4 or dik==DIK_keys.DIK_RETURN or bind==key_bindings.kUSE)and(self.switchobj)then self:OnButton_switch()
		elseif(#GetMagazinesDB(self.outfit:id())>1)and(self.onlyunload)then
			if(bind==key_bindings.kFWD or dik==DIK_keys.DIK_NUMPAD8 or dik==DIK_keys.DIK_UP)then
				for k,v in pairs(self.mforms)do if(v.button:IsCursorOverWindow())then if(k>1)then self:SortThatMag(k,1)end return(true)end end
			elseif(bind==key_bindings.kBACK or dik==DIK_keys.DIK_NUMPAD2 or dik==DIK_keys.DIK_DOWN)then 
				for k,v in pairs(self.mforms)do if(v.button:IsCursorOverWindow())then if(k<#GetMagazinesDB(self.outfit:id()))then self:SortThatMag(k,2)end return(true)end end
	end end end return(true)
end
function mag_trans_wpn_ui:OnButton_click()
	for k,v in pairs(self.mforms)do if(v.button:IsCursorOverWindow())then
		for k2,v2 in pairs(v.sortcaps or {})do if(v2 and v2:IsCursorOverWindow())then self:SortThatMag(k,k2) return end end self:AttachThatMag(k) return
end end end
function mag_trans_wpn_ui:OnButton_switch() mag_trans_wpn_ui(self.switchobj,self.weapon,self.onlyunload,self.outfit):ShowDialog(true) self:ExitMenu()end
function mag_trans_wpn_ui:ExitMenu() UIMenuActive=false UnregisterScriptCallback("actor_on_before_death",self) UnregisterScriptCallback("actor_on_update",self) self:HideDialog()end
function mag_trans_wpn_ui:actor_on_before_death() if(self)then self:ExitMenu()end end
function mag_trans_wpn_ui:actor_on_update() if(self)then
	if(self.health and self.health-db.actor.health>=0.02)then self:ExitMenu() else self.health=db.actor.health end
end end
