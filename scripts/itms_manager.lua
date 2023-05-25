--[[ ... ]]--
function on_ammo_drag_dropped(itm1,itm2,from_slot,to_slot)
	--[[ ... ]]--
	if (IsAmmo(itm1) and IsAmmo(itm2)) and (sec1 == sec2) then
		--[[ ... ]]--
	end --local fgren=system_ini():r_string_ex(sec1,"fake_grenade_name")
	if(utils.is_ammo(sec1) and IsWeapon(itm2))then --local in_slot=false -- or(fgren and fgren~="")
		for i=1,14 do if(db.actor:item_in_slot(i) and db.actor:item_in_slot(i):id()==itm2:id())then
			in_slot=true break -- Scripted by Ekidona Arubino || 02.12.22 || 20:17(JST)
		end end --[[if not(in_slot)then return end]] local ammotype=ekidona_mags.SelectAmmoType(itm2,sec1)
		if not(ammotype)or(ekidona_mags.isMWeapon(sec2))then return
			--[[if(ekidona_mags.GetWeaponGrenadeLauncher(itm2))then if(sec1~=system_ini():r_string_ex(sec2,"grenade_class"))then return end
				ekidona_mags.SetReloadArray({1,nil,0,nil,itm2:id(),{false,itm1:id()}}) --get_hud():HideActorMenu()
				CreateTimeEvent("EkiMagsReload",itm2:id(),0,ekidona_mags.PlayReloadAnimation,itm2)
			else return end]]
		else local curammo={ekidona_mags.SelectAmmoTypeName(itm2,itm2:get_ammo_type()),itm2:get_ammo_in_magazine(),system_ini():r_float_ex(sec2,"ammo_mag_size")}
			--[[itm2:iterate_installed_upgrades(function(usec) local upset=system_ini():r_string_ex(usec,"section")
				curammo[3]=(system_ini():r_float_ex(upset,"ammo_mag_size") or curammo[3])
			end) meh]]
			if(curammo[1]==sec1 and curammo[2]==curammo[3])then return end local ammoneed=0
			if(curammo[1]~=sec1 and curammo[2]>0)then create_ammo(curammo[1],db.actor:position(),db.actor:level_vertex_id(),db.actor:game_vertex_id(),0,curammo[2]) curammo[2]=0 end
			if(system_ini():r_string_ex(sec2,"tri_state_reload")=="on")or(system_ini():r_string_ex(sec2,"class")=="WP_BM16")then xr_sound.set_sound_play(db.actor:id(),"reload_shell")
				ekidona_mags.SetWeaponAmmoParams(itm2,ammotype,curammo[2]+1) if(itm1:ammo_get_count()==1)then alife():release(alife_object(itm1:id()))
				else itm1:ammo_set_count(itm1:ammo_get_count()-1)end return
			else ammoneed=math.min(itm1:ammo_get_count(),curammo[3]-curammo[2])end
			--if(itm1:ammo_get_count()-ammoneed<=0)then alife():release(alife_object(itm1:id()))else itm1:ammo_set_count(itm1:ammo_get_count()-ammoneed)end
			ekidona_mags.SetReloadArray({curammo[2]+ammoneed,ammoneed,ammotype,nil,itm2:id(),{false,itm1:id()}}) --get_hud():HideActorMenu()
			CreateTimeEvent("EkiMagsReload",itm2:id(),0,ekidona_mags.PlayReloadAnimation,itm2)
		end
	end
end 
--[[ ... ]]--