--[[...]]--
-- Attaches a sight to the weapon.
function attach_sight(item, weapon)
	--[[...]]--
	-- Create objects for the 'before' and 'after' attachment weapons.
	local old_weapon = alife_object(weapon:id())
	if (old_weapon) then
		local new_weapon = alife():clone_weapon(old_weapon, child_section, old_weapon.position, old_weapon.m_level_vertex_id, old_weapon.m_game_vertex_id, old_weapon.parent_id, false)
		if (new_weapon) then local grenades=bind_weapon.GetWeaponGrenadeAmmoDB(old_weapon.id) local need1,need2
			need1=ekidona_mags.GetMagazinesDB(old_weapon.id) need2=bind_weapon.GetWeaponMainAmmoDB(old_weapon.id)
			if(grenades and old_weapon:get_addon_flags():is(cse_alife_item_weapon.eWeaponAddonGrenadeLauncher))then
				create_ammo(system_ini():r_string_ex(wsec,"grenade_class"),db.actor:position(),db.actor:level_vertex_id(),db.actor:game_vertex_id(),0,1)
			end-- Release the sight and old unmodified weapon.
			local sight_object = alife_object(item:id())
			alife():release(sight_object, true)
			alife():release(old_weapon, true)
			
			-- Register the new modified weapon.
			alife():register(new_weapon) bind_weapon.SetWeaponGrenadeAmmoDB(new_weapon.id,false)
			ekidona_mags.SetMagazinesDB(new_weapon.id,need1) bind_weapon.SetWeaponMainAmmoDB(new_weapon.id,need2)
		end
	end
end
-- Detaches a sight from the weapon.
function detach_sight(weapon)
	--[[...]]--
	-- Create objects for the 'before' and 'after' detachment weapons.
	local old_weapon = alife_object(weapon:id())
	if (old_weapon) then
		local new_weapon = alife():clone_weapon(old_weapon, parent_section, old_weapon.position, old_weapon.m_level_vertex_id, old_weapon.m_game_vertex_id, old_weapon.parent_id, false)
		if (new_weapon) then local grenades=bind_weapon.GetWeaponGrenadeAmmoDB(old_weapon.id) local need1,need2
			need1=ekidona_mags.GetMagazinesDB(old_weapon.id) need2=bind_weapon.GetWeaponMainAmmoDB(old_weapon.id)
			if(grenades and old_weapon:get_addon_flags():is(cse_alife_item_weapon.eWeaponAddonGrenadeLauncher))then
				create_ammo(system_ini():r_string_ex(wsec,"grenade_class"),db.actor:position(),db.actor:level_vertex_id(),db.actor:game_vertex_id(),0,1)
			end-- Release the old modified weapon.
			alife():release(old_weapon, true)
			
			-- Register the new unmodified weapon.
			alife():register(new_weapon) bind_weapon.SetWeaponGrenadeAmmoDB(new_weapon.id,false)
			ekidona_mags.SetMagazinesDB(new_weapon.id,need1) bind_weapon.SetWeaponMainAmmoDB(new_weapon.id,need2)
		end
	end
end