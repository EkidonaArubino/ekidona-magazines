--[[...]]--
function IsKnife(o,c)
	if not (c) then
		c = o and o:clsid()
	end
	local knife = {
		[clsid.wpn_knife] = true,
		[clsid.wpn_knife_s] = true,
	}
	return c and knife[c] or false
end
--[[...]]--
-- called in CSE_ALifeDynamicObject::on_unregister()
-- good place to remove ids from persistent tables
function CSE_ALifeDynamicObject_on_unregister(id) local m_data=alife_storage_manager.get_state()
	if(m_data)then if(m_data.companion_borrow_item)then m_data.companion_borrow_item[id]=nil end
		if(m_data.NPCPrecSpawn)then m_data.NPCPrecSpawn[id]=nil end
		if(m_data.MagazinesDB)then m_data.MagazinesDB[id]=nil end
		if(m_data.JammedDB)then m_data.JammedDB[id]=nil end
		if(m_data.WeaponGrenadeAmmoDB)then m_data.WeaponGrenadeAmmoDB[id]=nil end
		if(m_data.WeaponMainAmmoDB)then m_data.WeaponMainAmmoDB[id]=nil end
	end
end