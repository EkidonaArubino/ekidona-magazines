--[[--All by エキドナ　アルビノ (Ekidona Arubino)--]]--
--31.03.23 : 16:10(JST)
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
	if(IsWeapon(obj))and not(IsKnife(obj))then SetWeaponGrenadeAmmoDB(obj:id(),(ekidona_mags.GetWeaponGrenadeLauncher(obj) and obj:get_ammo_in_magazine()>0)or GetWeaponGrenadeAmmoDB(obj:id()))
		if(obj:weapon_grenadelauncher_status()>0)and not(ekidona_mags.GetWeaponGrenadeLauncher(obj))then SetWeaponMainAmmoDB(obj:id(),{obj:get_ammo_type(),obj:get_ammo_in_magazine()})end
	end local function GetAmmoMass() local adata=GetWeaponMainAmmoDB(obj:id())
		--if not(adata or ekidona_mags.GetWeaponGrenadeLauncher(obj))then adata={obj:get_ammo_type(),obj:get_ammo_in_magazine()}end
		return((adata and adata[2]>0 and(system_ini():r_float_ex(ekidona_mags.SelectAmmoTypeName(obj,adata[1]),"inv_weight")*(adata[2]/system_ini():r_float_ex(ekidona_mags.SelectAmmoTypeName(obj,adata[1]),"box_size"))))or 0)
	end
	if(self.first_call)then
		if(ekidona_mags.isMagazine(sec)or ekidona_mags.isMSuit(sec))and(obj:parent())and(IsTrader(obj:parent()))then--IsTrader is not prepared for working
			if(ekidona_mags.isMagazine(sec))then ekidona_mags.SetMagazinesDB(obj:id(),{nil,0}) else ekidona_mags.SetMagazinesDB(obj:id(),{})end
		end self.first_call=nil return
	end if(ekidona_mags.isMagazine(sec))then if not(st)then return end
		local ammowgt,ammosec=0,(st[1] and ekidona_mags.GetAmmoSecFromMag(sec,st[1]))
		if(ammosec)then ammowgt=((system_ini():r_float_ex(ammosec,"inv_weight")/system_ini():r_float_ex(ammosec,"box_size"))*st[2])end
		obj:set_weight(system_ini():r_float_ex(sec,"inv_weight")+ammowgt)
		if(db.actor:has_info("trade_wnd_open"))then obj:set_condition(1)
		elseif(st[1])then obj:set_condition((st[2] or 0)/ekidona_mags.GetMagAmmoSize(sec,st[1]))
		else obj:set_condition(0)end
	elseif(ekidona_mags.isMWeapon(sec))then
		if(st==nil)then ekidona_mags.SetMagazinesDB(obj:id(),false)end if not(ekidona_mags.GetMagazinesDB(obj:id()))and(obj:get_ammo_in_magazine()>0)then
			ekidona_mags.SetMagazinesDB(obj:id(),ekidona_mags.GetMagName(sec,1,1,obj:get_ammo_in_magazine(),ekidona_mags.SelectAmmoTypeName(obj,obj:get_ammo_type())))
			if(ekidona_mags.GetMagazinesDB(obj:id())==nil)then SetWeaponToMag(obj)end
		end st=ekidona_mags.GetMagazinesDB(obj:id()) local amass=system_ini():r_float_ex(sec,"inv_weight")
		if(st)then amass=amass+system_ini():r_float_ex(ekidona_mags.GetMagFromInd(st),"inv_weight")end
		if(ekidona_mags.GetWeaponGrenadeLauncher(obj))then amass=(amass+GetAmmoMass())end obj:set_weight(amass)
	elseif(ekidona_mags.isMSuit(sec))then if not(st)then return end local udata,tremove,addsize=ekidona_mags.GetMagazinesOnUnload(obj),{},0
		local amass=(system_ini():r_float_ex(sec,"inv_weight")*math.min(1,obj:condition()/0.75))
		for k,v in pairs(ekidona_mags.GetMagazinesDB(obj:id()))do local magsec=ekidona_mags.GetMagFromInd(v[1])
			local ammosec=ekidona_mags.GetAmmoSecFromMag(magsec,v[2]) addsize=(addsize+ekidona_mags.GetMagSize(magsec))
			if(addsize>udata[2])then table.insert(tremove,k) local parent=obj:parent()
				if(parent)then ekidona_mags.CreateMagazine(magsec,obj:position(),obj:level_vertex_id(),obj:game_vertex_id(),parent:id(),ammosec,v[3])
				else ekidona_mags.CreateMagazine(magsec,obj:position(),obj:level_vertex_id(),obj:game_vertex_id(),nil,ammosec,v[3])end--meh
			else amass=(amass+system_ini():r_float_ex(magsec,"inv_weight")+((system_ini():r_float_ex(ammosec,"inv_weight")/system_ini():r_float_ex(ammosec,"box_size"))*v[3]))
		end end for i=1,#tremove do table.remove(ekidona_mags.GetMagazinesDB(obj:id()),tremove[i]-(i-1))end obj:set_weight(amass)
	elseif(IsWeapon(obj))and not(IsKnife(obj))and(ekidona_mags.GetWeaponGrenadeLauncher(obj))then obj:set_weight(system_ini():r_float_ex(sec,"inv_weight")+GetAmmoMass())end
end
function weapon_binder:reload(section) object_binder.reload(self,section)end
function weapon_binder:reinit() object_binder.reinit(self)end
function weapon_binder:net_spawn(se_abstract)
    if not(object_binder.net_spawn(self,se_abstract))then return false end
	local mdata,id,section=alife_storage_manager.get_state(),self.object:id(),self.object:section()
	if not(mdata.WeaponGrenadeAmmoDB)then mdata.WeaponGrenadeAmmoDB={}end mdata.WeaponGrenadeAmmoDB[id]=(mdata.WeaponGrenadeAmmoDB[id] or false)
	if not(mdata.WeaponMainAmmoDB)then mdata.WeaponMainAmmoDB={}end mdata.WeaponMainAmmoDB[id]=(mdata.WeaponMainAmmoDB[id] or false)
	if(ekidona_mags.GetMagazinesDB(id)==nil)then
		if(ekidona_mags.isMagazine(section))then ekidona_mags.SetMagazinesDB(id,{nil,0})
		elseif(ekidona_mags.isMWeapon(section))then local ammo_have=self.object:get_ammo_in_magazine()
			if(ammo_have>0)or(math.random()>=0.75)then ekidona_mags.SetMagazinesDB(id,ekidona_mags.GetMagName(section,1,1,ammo_have,ekidona_mags.SelectAmmoTypeName(self.object,self.object:get_ammo_type())))
				if(ekidona_mags.GetMagazinesDB(id)==nil)then SetWeaponToMag(self.object)end
			else ekidona_mags.SetMagazinesDB(id,false)end
		elseif(ekidona_mags.isMSuit(section))then ekidona_mags.SetMagazinesDB(id,{})end
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
	if(obj:parent())then if(obj:parent():id()~=0)then return end
		create_ammo(sec:sub(1,string.len(sec)-1),obj:position(),obj:level_vertex_id(),obj:game_vertex_id(),obj:parent():id(),obj:ammo_get_count())
	else create_ammo(sec:sub(1,string.len(sec)-1),obj:position(),obj:level_vertex_id(),obj:game_vertex_id(),nil,obj:ammo_get_count())end--meh
	alife():release(alife_object(obj:id()))
end
-- Well, sometimes...
function SetWeaponToMag(wpn) local ammo_name,id=ekidona_mags.SelectAmmoTypeName(wpn,wpn:get_ammo_type()),wpn:id()
	ekidona_mags.SetMagazinesDB(id,ekidona_mags.GetMagName(wpn:section(),1,1,nil,ammo_name)) local mags=ekidona_mags.GetMagFromInd(ekidona_mags.GetMagazinesDB(id))
	ekidona_mags.SetWeaponAmmoParams(wpn,wpn:get_ammo_type(),ekidona_mags.GetMagAmmoSize(mags,ekidona_mags.GetAmmoIndFromMag(mags,ammo_name)))
end