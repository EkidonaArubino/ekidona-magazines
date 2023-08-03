--[[...]]--
local function map_spot_menu_property_clicked(property_ui,id,level_name,prop)
	if (prop == game.translate_string("st_pda_fast_travel")) then 
		--[[...]]--
		local dist = se_obj.online and db.actor:position():distance_to(se_obj.position) or 1000
		if (dist <= 50) then 
			--[[...]]--
		end local cntrs={math.floor(dist/1000)+math.random(0,2),math.random(1,59)}
		inventory_weigth_patch.IncreaseBoostDelta(((cntrs[1]*3600)+cntrs[2])*(1000/level.get_time_factor()))
		--[[...]]--
	end
end