function GetNPCPrecSpawn(id) local mdata=alife_storage_manager.get_state()
	if not(mdata)then return(nil)end if not(mdata.NPCPrecSpawn)then mdata.NPCPrecSpawn={}end
	if(mdata and mdata.NPCPrecSpawn)then return(mdata.NPCPrecSpawn[id])end
end
function SetNPCPrecSpawn(id,var) local mdata=alife_storage_manager.get_state()
	if not(mdata)then return end if not(mdata.NPCPrecSpawn)then mdata.NPCPrecSpawn={}end
	if(mdata and mdata.NPCPrecSpawn)then mdata.NPCPrecSpawn[id]=var end
end
--[[ ... ]]--
function motivator_binder:update(delta)
	object_binder.update(self, delta)
	--alun_utils.debug_write(strformat("motivator_bind:update %s START",self.object and self.object:name()))

	local object = self.object
	local id = object:id()
	if not(GetNPCPrecSpawn(id))then CreateMagsToSomebody(object) SetNPCPrecSpawn(id,true)end
	--[[ ... ]]--
end
--[[ ... ]]--
function CreateMagsToSomebody(who) local mkoeff=(math.max(1,who:rank())/(character_community(who)=="zombied" and 3 or 1)/3000)
	local mcnt=math.random(utils.round(mkoeff/2),utils.round(mkoeff)) if(mcnt<=0)then return end local wpns={}
	local function GetWeapons(temp,item)if(ekidona_mags.isMWeapon(item:section()))then table.insert(wpns,item)end end who:iterate_inventory(GetWeapons)
	for i=1,#wpns do if(mcnt==0)then break end local cnt=math.random((i==#wpns and mcnt)or 0,mcnt) mcnt=(mcnt-cnt) local sec=wpns[i]:section() local ammos
		wpns[i]:iterate_installed_upgrades(function(usec) local upset=system_ini():r_string_ex(usec,"section")
			ammos=(ammos or alun_utils.parse_list(system_ini(),usec,"ammo_class"))
		end) ammos=(ammos or alun_utils.parse_list(system_ini(),sec,"ammo_class"))
		for p=1,cnt do ekidona_mags.CreateMagazine(sec,who:position(),who:level_vertex_id(),who:game_vertex_id(),who:id(),{{ammos[math.random(1,#ammos)],math.random(0,system_ini():r_float_ex(sec,"ammo_mag_size"))}},mkoeff/math.random(5,10))end
	end
end