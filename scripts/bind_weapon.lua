--[[--All by エキドナ　アルビノ (Ekidona Arubino)--]]--
--23.05.23 : 16:02(JST)
--WeaponGrenadeAmmoDB,WeaponMainAmmoDB={},{}
function GetWeaponGrenadeAmmoDB(id) local mdata=alife_storage_manager.get_state()
	if not(mdata)then return(nil)end if not(mdata.WeaponGrenadeAmmoDB)then mdata.WeaponGrenadeAmmoDB={}end
	return(mdata.WeaponGrenadeAmmoDB[id])
end
function SetWeaponGrenadeAmmoDB(id,var) local mdata=alife_storage_manager.get_state()
	if not(mdata)then return end if not(mdata.WeaponGrenadeAmmoDB)then mdata.WeaponGrenadeAmmoDB={}end
	mdata.WeaponGrenadeAmmoDB[id]=var
end
function GetWeaponMainAmmoDB(id) local mdata=alife_storage_manager.get_state()
	if not(mdata)then return(nil)end if not(mdata.WeaponMainAmmoDB)then mdata.WeaponMainAmmoDB={}end
	return(mdata.WeaponMainAmmoDB[id])
end
function SetWeaponMainAmmoDB(id,var) local mdata=alife_storage_manager.get_state()
	if not(mdata)then return end if not(mdata.WeaponMainAmmoDB)then mdata.WeaponMainAmmoDB={}end
	mdata.WeaponMainAmmoDB[id]=var
end
function fakebind(obj) return end
function bind(obj) obj:bind_object(weapon_binder(obj))end
class "weapon_binder" (object_binder)
function weapon_binder:__init(obj) super(obj)end
-- Class update
function weapon_binder:update(delta)
    object_binder.update(self,delta)
	local obj=self.object local sec,st=obj:section(),ekidona_mags.GetMagazinesDB(obj:id())
	if(IsWeapon(obj))and not(IsKnife(obj) or IsGrenade(obj))then
		SetWeaponGrenadeAmmoDB(obj:id(),(ekidona_mags.GetWeaponGrenadeLauncher(obj) and obj:get_ammo_in_magazine()>0)or GetWeaponGrenadeAmmoDB(obj:id()))
	end
	if(self.first_call)then
		if(ekidona_mags.isMagazine(sec)or ekidona_mags.isMSuit(sec))and(obj:parent())and(IsTrader(obj:parent()))then--IsTrader is not prepared for working
			ekidona_mags.SetMagazinesDB(obj:id(),{})
		end self.first_call=nil return
	end if(ekidona_mags.isMagazine(sec))then local ammomass=0
		for k,v in pairs(st or {})do local ammosec=(v[1] and ekidona_mags.GetAmmoSecFromMag(sec,v[1]))
			if(ammosec)then ammomass=(ammomass+((system_ini():r_float_ex(ammosec,"inv_weight")/system_ini():r_float_ex(ammosec,"box_size"))*v[2]))
		end end obj:set_weight(system_ini():r_float_ex(sec,"inv_weight")+ammomass)
		if(db.actor:has_info("trade_wnd_open"))then obj:set_condition(1)
		else obj:set_condition(ekidona_mags.GetMagazineAmmoCount(st)/ekidona_mags.GetMagAmmoSize(sec,st and st[1] and st[1][1]))end
	elseif(ekidona_mags.isMWeapon(sec))then local ammocnt=obj:get_ammo_in_magazine()
		if(st==nil)then ekidona_mags.SetMagazinesDB(obj:id(),false)end if not(ekidona_mags.GetMagazinesDB(obj:id()))and(ammocnt>0)then
			local ammosec=ekidona_mags.SelectAmmoTypeName(obj,obj:get_ammo_type()) local magsec=ekidona_mags.GetMagName(sec,1,2,ammocnt,ammosec)
			if(magsec==nil)then SetWeaponToMag(obj) else ekidona_mags.SetMagazinesDB(obj:id(),{ekidona_mags.GetIndFromMag(magsec),{{ekidona_mags.GetAmmoIndFromMag(magsec,ammosec),ammocnt}}})end
		end st=ekidona_mags.GetMagazinesDB(obj:id()) local amass,parent=(system_ini():r_float_ex(sec,"inv_weight")*utils.clamp(obj:condition()/0.9,0.25,1)),obj:parent()
		local function GetActiveWeapon() return(parent and IsStalker(parent)and parent:alive() and parent:active_item() and parent:active_item():id()==obj:id())end
		if(st)then local magsec,ammomass,lastammo=ekidona_mags.GetMagFromInd(st[1]),0 amass=(amass+system_ini():r_float_ex(magsec,"inv_weight"))
			for k,v in pairs(st[2] or {})do lastammo=ekidona_mags.GetAmmoSecFromMag(magsec,v[1])
				ammomass=(ammomass+((system_ini():r_float_ex(lastammo,"inv_weight")/system_ini():r_float_ex(lastammo,"box_size"))*v[2]))
			end local needtype=(ekidona_mags.SelectAmmoType(obj,lastammo)or obj:get_ammo_type())
			--local partner=(actor_menu.inventory_opened() and ActorMenu.get_actor_menu():GetPartner()) -- meh
			if(ekidona_mags.GetWeaponGrenadeLauncher(obj))then amass=(amass+ammomass) --yeap
			elseif(actor_menu.inventory_opened() and parent and(not(IsStalker(parent)and parent:alive())or parent:id()==0 or parent:id()==inventory_upgrades.victim_id))then amass=(amass+ammomass)
				if(ammocnt>0)then SetWeaponMainAmmoDB(obj:id(),{needtype,ekidona_mags.GetMagazineAmmoCount(st[2])}) ekidona_mags.SetWeaponAmmoParams(obj,needtype,0)end
			elseif(GetActiveWeapon())then --meh
				if(GetWeaponMainAmmoDB(obj:id()))then local adb=GetWeaponMainAmmoDB(obj:id()) ekidona_mags.SetWeaponAmmoParams(obj,adb[1],adb[2]) SetWeaponMainAmmoDB(obj:id(),nil)
				else local ammocur=ekidona_mags.GetMagazineAmmoCount(st[2]) local diff,remover,curtype=(ammocur-ammocnt),{},((st[2][1] and st[2][#st[2]][1])or nil)
					if(diff>0)then for i=#st[2],1,-1 do local ammohere=math.max(0,st[2][i][2]-diff) diff=math.max(0,diff-st[2][i][2])
							if(ammohere==0)then table.insert(remover,i) else st[2][i][2]=ammohere end if(diff==0)then break end
						end if(#remover>0)then for i=#remover,1,-1 do table.remove(st[2],remover[i]-(#remover-i))end end curtype=((st[2][1] and st[2][#st[2]][1])or nil)
					elseif(diff<0)then local ammoind=ekidona_mags.GetAmmoIndFromMag(magsec,ekidona_mags.SelectAmmoTypeName(obj,obj:get_ammo_type()))
						if(st[2][1] and st[2][#st[2]][1]==ammoind)then st[2][#st[2]][2]=(st[2][#st[2]][2]+math.abs(diff))
						else table.insert(st[2],{ammoind,math.abs(diff)})end -- for "g_unlimitedammo" : CTD sometimes... meh.
					end local ammosec=((curtype and ekidona_mags.GetAmmoSecFromMag(magsec,curtype))or ekidona_mags.SelectAmmoTypeName(obj,obj:get_ammo_type()))
					local wpnammotype=ekidona_mags.SelectAmmoType(obj,ammosec)
					if(wpnammotype~=obj:get_ammo_type())then --printf("Weapon %s have incorect ammo type: %s | %s",obj:name(),obj:get_ammo_type(),wpnammotype)
						ekidona_mags.SetWeaponAmmoParams(obj,wpnammotype,ammocnt)
					end amass=(amass+(ammomass-((system_ini():r_float_ex(ammosec,"inv_weight")/system_ini():r_float_ex(ammosec,"box_size"))*ammocnt)))--meh
			end end
		end obj:set_weight(amass)
	elseif(ekidona_mags.isMSuit(sec))then if not(st)then return end local udata,tremove,addsize=ekidona_mags.GetMagazinesOnUnload(obj),{},0
		local amass=(system_ini():r_float_ex(sec,"inv_weight")*math.min(1,obj:condition()/0.75))
		for k,v in pairs(ekidona_mags.GetMagazinesDB(obj:id()))do
			local magsec=ekidona_mags.GetMagFromInd(v[1]) addsize=(addsize+ekidona_mags.GetMagSize(magsec))
			if(addsize>udata[2])then table.insert(tremove,k) local parent=obj:parent()
				if(parent)then ekidona_mags.CreateMagazine(magsec,obj:position(),obj:level_vertex_id(),obj:game_vertex_id(),parent:id(),v[2])
				else ekidona_mags.CreateMagazine(magsec,obj:position(),obj:level_vertex_id(),obj:game_vertex_id(),nil,v[2])end--meh
			else amass=(amass+system_ini():r_float_ex(magsec,"inv_weight"))
				for k2,v2 in pairs(v[2])do local ammosec=ekidona_mags.GetAmmoSecFromMag(magsec,v2[1])
					amass=(amass+((system_ini():r_float_ex(ammosec,"inv_weight")/system_ini():r_float_ex(ammosec,"box_size"))*v2[2]))
		end end end for i=1,#tremove do table.remove(ekidona_mags.GetMagazinesDB(obj:id()),tremove[i]-(i-1))end obj:set_weight(amass)
	end
end
function weapon_binder:reload(section) object_binder.reload(self,section)end
function weapon_binder:reinit() object_binder.reinit(self)end
function weapon_binder:net_spawn(se_abstract)
    if not(object_binder.net_spawn(self,se_abstract))then return false end
	local mdata,id,section=alife_storage_manager.get_state(),self.object:id(),self.object:section()
	if not(mdata.WeaponGrenadeAmmoDB)then mdata.WeaponGrenadeAmmoDB={}end mdata.WeaponGrenadeAmmoDB[id]=(mdata.WeaponGrenadeAmmoDB[id] or false)
	if not(mdata.WeaponMainAmmoDB)then mdata.WeaponMainAmmoDB={}end mdata.WeaponMainAmmoDB[id]=(mdata.WeaponMainAmmoDB[id] or false)
	if(ekidona_mags.GetMagazinesDB(id)==nil)then
		if(ekidona_mags.isMagazine(section) or ekidona_mags.isMSuit(section))then ekidona_mags.SetMagazinesDB(id,{})
		elseif(ekidona_mags.isMWeapon(section))then local ammo_have=self.object:get_ammo_in_magazine()
			if(ammo_have>0)or(math.random()>=0.75)then local ammosec=ekidona_mags.SelectAmmoTypeName(self.object,self.object:get_ammo_type())
				local magind=ekidona_mags.GetMagName(section,1,1,ammo_have,ammosec)
				if(magind==nil)then SetWeaponToMag(self.object) else ekidona_mags.SetMagazinesDB(id,{magind,{{ekidona_mags.GetAmmoIndFromMag(ekidona_mags.GetMagFromInd(magind),ammosec),ammo_have}}})end
			else ekidona_mags.SetMagazinesDB(id,false)end
		end
	end self.first_call=true return(true)
end
function weapon_binder:net_destroy() object_binder.net_destroy(self)end
-- Fake ammo
function fammo_bind(obj) obj:bind_object(fammo_binder(obj))end
class "fammo_binder" (object_binder)
-- Class constructor
function fammo_binder:__init(obj)super(obj)end
function fammo_binder:net_spawn(se_abstract)if not(object_binder.net_spawn(self,se_abstract))then return false end return true end
function fammo_binder:update(delta)
	object_binder.update(self,delta) local obj=self.object local sec=obj:section()
	if(obj:parent())then if(obj:parent():id()~=0 and IsStalker(obj:parent()) and obj:parent():alive())then return end
		create_ammo(sec:sub(1,string.len(sec)-1),obj:position(),obj:level_vertex_id(),obj:game_vertex_id(),obj:parent():id(),obj:ammo_get_count())
	else create_ammo(sec:sub(1,string.len(sec)-1),obj:position(),obj:level_vertex_id(),obj:game_vertex_id(),nil,obj:ammo_get_count())end--meh
	alife():release(alife_object(obj:id()))
end
-- Well, sometimes...
function SetWeaponToMag(wpn) local ammo_name,id=ekidona_mags.SelectAmmoTypeName(wpn,wpn:get_ammo_type()),wpn:id()
	local magsec=ekidona_mags.GetMagName(wpn:section(),1,1,nil,ammo_name) local ammoind=ekidona_mags.GetAmmoIndFromMag(magsec,ammo_name)
	ekidona_mags.SetMagazinesDB(id,{ekidona_mags.GetIndFromMag(magsec),{{ammoind,ekidona_mags.GetMagAmmoSize(magsec,ammoind)}}})
	ekidona_mags.SetWeaponAmmoParams(wpn,wpn:get_ammo_type(),ekidona_mags.GetMagAmmoSize(magsec,ammoind))
end