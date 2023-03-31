--'******************************************************
--'*  Биндер объекта артефакт .
--'******************************************************
function bind(obj)
	obj:bind_object(artefact_binder(obj))
end

class "artefact_binder" (object_binder)
function artefact_binder:__init(obj) super(obj)
	db.storage[self.object:id()] = { }
end
function artefact_binder:net_spawn(server_object)
	
	if not object_binder.net_spawn(self, server_object) then
		return false
	end
	db.add_obj(self.object)
	local artefact = self.object:get_artefact()
	local id = self.object:id()
	if bind_anomaly_zone.artefact_ways_by_id[id] ~= nil then
		local anomal_zone = bind_anomaly_zone.parent_zones_by_artefact_id[id]
		local force_xz	= anomal_zone.applying_force_xz
		local force_y	= anomal_zone.applying_force_y
		artefact:FollowByPath(bind_anomaly_zone.artefact_ways_by_id[id],bind_anomaly_zone.artefact_points_by_id[id],vector():set(force_xz,force_y,force_xz))
--		artefact:FollowByPath(bind_anomaly_zone.artefact_ways_by_id[id],0,vector():set(force_xz,force_y,force_xz))
	end local mdata,section=alife_storage_manager.get_state(),self.object:section()
	if(ekidona_mags.GetMagazinesDB(id)==nil)and(ekidona_mags.isMSuit(section))then ekidona_mags.SetMagazinesDB(id,{})end
	self.first_call = true
		
	return true
end

function artefact_binder:update(delta)
	object_binder.update(self, delta)
	
	local ini = ini_file("plugins\\itms_manager.ltx")
	local NotArtefact = alun_utils.collect_section(ini,"not_artefact",true)
	
    if self.first_call == true then
		local ini = ini_file("plugins\\itms_manager.ltx")
		local se_obj = alife():object(self.object:id())
		
		if (se_obj) then
			self.object:set_condition(se_obj.offline_condition or 0.9999999)
			
			if NotArtefact[self.object:section()] then
				self.first_call = false
				return
			end
			
			local antirad = system_ini():r_string_ex(self.object:section(),"antirad") or 0
				
			local rad_res = (se_obj.radiation_restore_speed or 0)+antirad
			rad_res = utils.clamp(rad_res,0,1)
			self.object:set_artefact_radiation(rad_res)
			
			self.object:set_artefact_weight(se_obj.weight or 0)
			self.object:set_artefact_health(se_obj.health_restore_speed or 0)
			self.object:set_artefact_satiety(se_obj.satiety_restore_speed or 0)
			self.object:set_artefact_power(se_obj.power_restore_speed or 0)
			self.object:set_artefact_bleeding(se_obj.bleeding_restore_speed or 0)
			self.object:set_artefact_additional_weight(se_obj.additional_inventory_weight or 0)
			self.object:set_artefact_burn_immunity(se_obj.burn_immunity or 0)
			self.object:set_artefact_strike_immunity(se_obj.strike_immunity or 0)
			self.object:set_artefact_shock_immunity(se_obj.shock_immunity or 0)
			self.object:set_artefact_wound_immunity(se_obj.wound_immunity or 0)
			self.object:set_artefact_radiation_immunity(se_obj.radiation_immunity or 0)
			self.object:set_artefact_telepatic_immunity(se_obj.telepatic_immunity or 0)
			self.object:set_artefact_chemical_burn_immunity(se_obj.chemical_burn_immunity or 0)
			self.object:set_artefact_explosion_immunity(se_obj.explosion_immunity or 0)
			self.object:set_artefact_fire_wound_immunity(se_obj.fire_wound_immunity or 0)
		end
		
		local ini = self.object:spawn_ini()
		if not (ini and ini:section_exist("fixed_bone")) then
			self.first_call = false
			return
		end
		local bone_name = ini:r_string_ex("fixed_bone", "name")

		local ph_shell = self.object:get_physics_shell()
		if not ph_shell then
			return
		end
		
		local ph_element = ph_shell:get_element_by_bone_name(bone_name)

		if ph_element:is_fixed() then
		else
			ph_element:fix()
		end
		
		self.first_call = false
    elseif(ekidona_mags.isMSuit(self.object:section()))then local id,obj=self.object:id(),self.object
		if not(ekidona_mags.GetMagazinesDB(id))then return end local udata,tremove,addsize=ekidona_mags.GetMagazinesOnUnload(obj),{},0
		local amass=(system_ini():r_float_ex(obj:section(),"inv_weight")*math.min(1,obj:condition()/0.75))
		for k,v in pairs(ekidona_mags.GetMagazinesDB(id))do local magsec=ekidona_mags.GetMagFromInd(v[1])
			local ammosec=ekidona_mags.GetAmmoSecFromMag(magsec,v[2]) addsize=(addsize+ekidona_mags.GetMagSize(magsec))
			if(addsize>udata[2])then table.insert(tremove,k) local parent=obj:parent()
				if(parent)then ekidona_mags.CreateMagazine(magsec,obj:position(),obj:level_vertex_id(),obj:game_vertex_id(),parent:id(),ammosec,v[3])
				else ekidona_mags.CreateMagazine(magsec,obj:position(),obj:level_vertex_id(),obj:game_vertex_id(),nil,ammosec,v[3])end--meh
			else amass=(amass+system_ini():r_float_ex(magsec,"inv_weight")+((system_ini():r_float_ex(ammosec,"inv_weight")/system_ini():r_float_ex(ammosec,"box_size"))*v[3]))
		end end for i=1,#tremove do table.remove(ekidona_mags.GetMagazinesDB(id),tremove[i]-(i-1))end obj:set_weight(amass)
	end	
end


function artefact_binder:net_destroy(server_object)
	db.del_obj(self.object)
	object_binder.net_destroy(self)
end