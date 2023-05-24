--[[ ... ]]--
function artefact_binder:update(delta)
	--[[ ... ]]--
    if self.first_call == true then
		--[[ ... ]]--
	elseif(ekidona_mags.isMSuit(self.object:section()))then
		if not(ekidona_mags.GetMagazinesDB(self.object:id()))then return end local obj=self.object
		local udata,tremove,addsize=ekidona_mags.GetMagazinesOnUnload(obj),{},0
		local amass=(system_ini():r_float_ex(self.object:section(),"inv_weight")*math.min(1,obj:condition()/0.75))
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