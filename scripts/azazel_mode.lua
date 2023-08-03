--[[...]]--
function actor_on_before_death(whoID,flags)
	--[[...]]--
	-- cancel all tasks
	--[[...]]--
	if not(xr_motivator.GetNPCPrecSpawn(se_obj.id))then xr_motivator.CreateMagsToSomebody(db.actor)end
	-- initiate transitition and removal of victim
	--[[...]]--
end