--[[...]]--
-- time
function cmd.time(me,txt,owner,p)
	--[[...]]--
	if (t) then local cntrs={tonumber(t[1]),tonumber(t[2]),tonumber(t[3])}
		--set_current_time(tonumber(t[1]),tonumber(t[2]),tonumber(t[3]))
		inventory_weigth_patch.IncreaseBoostDelta(((cntrs[1]*3600*24)+(cntrs[2]*3600)+cntrs[3])*(1000/level.get_time_factor()))
		--[[...]]--
	end
end