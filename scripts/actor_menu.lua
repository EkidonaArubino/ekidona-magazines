--[[ ... ]]--
-- Special stuff for inventory
local FocusedItem,TimeFocused=nil,0
function on_game_start()
	RegisterScriptCallback("actor_on_first_update",actor_on_first_update)
	RegisterScriptCallback("CUIActorMenu_OnItemFocusReceive",on_item_focus)
	RegisterScriptCallback("CUIActorMenu_OnItemFocusLost",on_item_focus_lost)
	RegisterScriptCallback("actor_on_update",actor_on_update)
	RegisterScriptCallback("on_key_press",on_key_press)
	RegisterScriptCallback("actor_on_net_destroy",actor_on_net_destroy)
end
local ItemsText
function actor_on_first_update()
	local INV=ActorMenu.get_actor_menu()
	local xml=CScriptXmlInit()
	xml:ParseFile("ui_eki_mags.xml")
	ItemsText=xml:InitTextWnd("menu_extra:form:textcapc",INV)
	ItemsText:SetWndSize(vector2():set(380,25))
	ItemsText:SetWndPos(vector2():set(74,732))
	ItemsText:SetFont(GetFontDI())
	ItemsText:SetText("")
end
function on_item_focus(itm) FocusedItem=itm:id() TimeFocused=time_global() end
function actor_on_update() local function SetMenuText(str) ItemsText:SetText(str)end
	local fobj=level.object_by_id(FocusedItem)
	if(actor_menu.inventory_opened() and fobj)then
		local st,sec=ekidona_mags.GetMagazinesDB(fobj:id()),fobj:section()
		if(IsWeapon(fobj))and(system_ini():r_string_ex(sec,"class")~="WP_KNIFE" and system_ini():r_string_ex(sec,"class")~="WP_BINOC")then
			if(ekidona_mags.isMWeapon(sec))then
				if not(st)then SetMenuText(game.translate_string("st_weapon_without_magazine"))
				else local magsec,ammocnt=ekidona_mags.GetMagFromInd(st[1]),ekidona_mags.GetMagazineAmmoCount(st[2])
					maxammo=ekidona_mags.GetMagAmmoSize(magsec,(st[2][1] and st[2][1][1])or nil)
					local ammosec=(ammocnt>0 and st[2][1] and ekidona_mags.GetAmmoSecFromMag(magsec,st[2][#st[2]][1]))
					SetMenuText(ammocnt.."/"..maxammo..((ammosec and(" : "..game.translate_string(system_ini():r_string_ex(ammosec,"inv_name_short"))))or ""))
			end else local ammoname=""
				if(fobj:get_ammo_in_magazine()>0)then ammoname=(" : "..game.translate_string(system_ini():r_string_ex(ekidona_mags.SelectAmmoTypeName(fobj,fobj:get_ammo_type()),"inv_name_short")))end
				SetMenuText(fobj:get_ammo_in_magazine().."/"..system_ini():r_float_ex(sec,"ammo_mag_size")..ammoname)
			end return
		elseif(ekidona_mags.isMagazine(sec))then local ammoname=""
			if(st[1])then ammoname=(" : "..game.translate_string(system_ini():r_string_ex(ekidona_mags.GetAmmoSecFromMag(sec,st[#st][1]),"inv_name_short")))end
			SetMenuText(ekidona_mags.GetMagazineAmmoCount(st).."/"..ekidona_mags.GetMagAmmoSize(sec,st[1] and st[1][1])..ammoname) return
		elseif(ekidona_mags.isMSuit(sec))then local outary=ekidona_mags.GetMagazinesOnUnload(fobj)
			if(outary and outary[2]>0)then SetMenuText(string.format(game.translate_string("st_outfit_unload_menu"),outary[1],outary[2]))
			else SetMenuText(game.translate_string("st_outfit_unload_fail_menu"))end return
		end
	end SetMenuText("")
end
function on_item_focus_lost() if(TimeFocused~=time_global())then FocusedItem=nil end end
function on_key_press(key) local bindkey=dik_to_bind(key)
	if not(inventory_opened())or(ekidona_mags.ReturnBoolUIMenuActive())then return end
	local obj=level.object_by_id(FocusedItem) if not(obj and obj:parent())then return end local osec=obj:section()
	local indbool=(obj:parent():id()==0 or not(IsStalker(obj:parent()) and obj:parent():alive()))
	if(bindkey==key_bindings.kWPN_RELOAD)then
		if(osec:sub(1,5)=="ammo_" and obj:ammo_get_count()>1)then ekidona_mags.ammo_sort_ui(obj):ShowDialog(true)
		elseif(indbool)then
			if(ekidona_mags.isMWeapon(osec))then ekidona_mags.WeaponEjectMag(obj)
			elseif(ekidona_mags.isMagazine(osec))then ekidona_mags.ammo_trans_mag_ui(obj):ShowDialog(true)
			elseif(ekidona_mags.isMSuit(osec) and #ekidona_mags.GetMagazinesDB(FocusedItem)>0)then ekidona_mags.mag_trans_wpn_ui(obj,nil,true):ShowDialog(true)
		end end
	elseif(indbool)and(ekidona_mags.isMagazine(osec))then
		if(bindkey==key_bindings.kACCEL)then
			for k,v in pairs({db.actor:item_in_slot(7),db.actor:item_in_slot(15)})do
				if(v)and(ekidona_mags.GetMagazinesDB(v:id()))then local uvol=ekidona_mags.GetMagazinesOnUnload(v)
					if(uvol[1]+ekidona_mags.GetMagSize(osec)<=uvol[2])then
						table.insert(ekidona_mags.GetMagazinesDB(v:id()),{ekidona_mags.GetIndFromMag(osec),ekidona_mags.GetMagazinesDB(FocusedItem)or {}})
						alife():release(alife_object(FocusedItem)) xr_sound.set_sound_play(0,"inv_stack") return
			end end end
		elseif(bindkey==key_bindings.kCROUCH)and(indbool)and(ekidona_mags.isMagazine(osec))then
			for k,v in pairs({2,3,5})do local wpn=db.actor:item_in_slot(v)
				if(wpn and ekidona_mags.isMWeapon(wpn:section()))then
					if(ekidona_mags.WeaponAttemptToLoadMagazine(wpn,obj))then
						CreateTimeEvent("EkiMagsReload",wpn:id(),0,ekidona_mags.PlayReloadAnimation,wpn) return
			end end end
end end end
function actor_on_net_destroy() ItemsText:Show(false) TimeFocused=0 end