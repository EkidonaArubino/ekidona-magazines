-- actor_menu_mode -----

-- int mode:
-- 0 = 	Undefined = закрыто
-- 1 = 	Inventory
-- 2 = 	Trade
-- 3 = 	Upgrade
-- 4 = 	DeadBodySearch
-- 10 =  Talk dialog  show
-- 11 =  Talk dialog  hide
local last_mode = 0
xr_meet_dialog_closed = false
xr_meet_trade_closed = false
xr_meet_upgrade_closed = false
dead_body_searching = false
function get_mode()
	return last_mode
end
function actor_menu_mode(mode)
	if(mode==0) then
		if(last_mode==1) then
			inventory_wnd_closed()
		elseif(last_mode==2) then
			trade_wnd_closed()
		elseif(last_mode==3) then
			upgrade_wnd_closed()
		elseif(last_mode==4) then
			dead_body_search_wnd_closed()
		end
		last_mode = 0
	elseif(mode==1) then
		last_mode = 1
		inventory_wnd_opened()
	elseif(mode==2) then
		last_mode = 2
		trade_wnd_opened()
	elseif(mode==3) then
		last_mode = 3
		upgrade_wnd_opened()
	elseif(mode==4) then
		last_mode = 4
		dead_body_search_wnd_opened()
	elseif(mode==10) then
        dialog_wnd_showed()
	elseif(mode==11) then
        dialog_wnd_closed()
	end
end
function inventory_wnd_opened()
	--printf("---:>Inventory opened")
	give_info("inventory_wnd_open")
	db.actor:hide_weapon()
	db.actor:activate_slot(0)
end

function inventory_wnd_closed()
	--printf("---:>Inventory closed")
	disable_info("inventory_wnd_open")
	db.actor:restore_weapon()
	FocusedItem=nil
end

function trade_wnd_opened()
	SendScriptCallback("TrdWndOpened")
	xr_meet_dialog_closed = false
	--printf("---:>Trade opened")
	give_info("trade_wnd_open")
	db.actor:hide_weapon()
	db.actor:activate_slot(0)
end

function trade_wnd_closed()
	--printf("---:>Trade closed")
	SendScriptCallback("TrdWndClosed")
	xr_meet_trade_closed = true
	disable_info("trade_wnd_open")
	db.actor:restore_weapon()
end

function upgrade_wnd_opened()
	xr_meet_dialog_closed = false
	--printf("---:>Upgrade opened")
	give_info("upgrade_wnd_open")
	db.actor:hide_weapon()
	db.actor:activate_slot(0)
end

function upgrade_wnd_closed()
	--printf("---:>Upgrade closed")
	xr_meet_upgrade_closed = true
	disable_info("upgrade_wnd_open")
	db.actor:restore_weapon()
end

function dead_body_search_wnd_opened()
	--printf("---:>DeadBodySearch opened")
	dead_body_searching = true
	give_info("body_search_wnd_open")
	db.actor:hide_weapon()
	db.actor:activate_slot(0)
end

function dead_body_search_wnd_closed()
	--printf("---:>DeadBodySearch closed")
	dead_body_searching = false
	disable_info("body_search_wnd_open")
	bind_container.curBoxID = nil
	db.actor:restore_weapon()
end

function dialog_wnd_showed()
	--printf("---:>Talk Dialog show")
	give_info("dialog_wnd_open")
	db.actor:hide_weapon()
	db.actor:activate_slot(0)
end

function dialog_wnd_closed()
	--printf("---:>Talk Dialog hide")
	xr_meet_dialog_closed = true
	disable_info("dialog_wnd_open")
	--inventory_upgrades.victim_id = nil
	db.actor:restore_weapon()
end

function inventory_opened()
	if (db.actor:has_info("inventory_wnd_open") or
	db.actor:has_info("trade_wnd_open") or
	db.actor:has_info("upgrade_wnd_open") or
	db.actor:has_info("body_search_wnd_open") or
	db.actor:has_info("dialog_wnd_open")) then
		return true
	else
		return false
	end
end
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
				if not(st)then SetMenuText(game.translate_string("st_weapon_without_magazine")) return
				elseif(ekidona_mags.GetWeaponGrenadeLauncher(fobj))then SetMenuText("") return end
			end local ammoname,maxammo="",0
			if(fobj:get_ammo_in_magazine()>0)then ammoname=(" : "..game.translate_string(system_ini():r_string_ex(ekidona_mags.SelectAmmoTypeName(fobj,fobj:get_ammo_type()),"inv_name")))end
			if(ekidona_mags.isMWeapon(sec))then local magsec=ekidona_mags.GetMagFromInd(st)
				maxammo=ekidona_mags.GetMagAmmoSize(magsec,fobj:get_ammo_in_magazine()>0 and ekidona_mags.GetAmmoIndFromMag(magsec,ekidona_mags.SelectAmmoTypeName(fobj,fobj:get_ammo_type())))
			else maxammo=system_ini():r_float_ex(sec,"ammo_mag_size")end SetMenuText(fobj:get_ammo_in_magazine().."/"..maxammo..ammoname) return
		elseif(ekidona_mags.isMagazine(sec))then local ammoname=""
			if(st[1])then ammoname=(" : "..game.translate_string(system_ini():r_string_ex(ekidona_mags.GetAmmoSecFromMag(sec,st[1]),"inv_name")))end
			SetMenuText(st[2].."/"..ekidona_mags.GetMagAmmoSize(sec,st[1] and st[2]>0 and st[1])..ammoname) return
		elseif(ekidona_mags.isMSuit(sec))then local outary=ekidona_mags.GetMagazinesOnUnload(fobj)
			if(outary and outary[2]>0)then SetMenuText(string.format(game.translate_string("st_outfit_unload_menu"),outary[1],outary[2]))
			else SetMenuText(game.translate_string("st_outfit_unload_fail_menu"))end return
		end
	end SetMenuText("")
end
function on_item_focus_lost() if(TimeFocused~=time_global())then FocusedItem=nil end end
function on_key_press(key) if not(actor_menu.inventory_opened() and dik_to_bind(key)==key_bindings.kWPN_RELOAD)or(ekidona_mags.ReturnBoolUIMenuActive())then return end local obj=level.object_by_id(FocusedItem)
	if(obj)then local osec,parentid=obj:section(),obj:parent():id()
		if(utils.is_ammo(osec) and obj:ammo_get_count()>1)then ekidona_mags.ammo_sort_ui(obj):ShowDialog(true)
		elseif(parentid==0)then
			if(ekidona_mags.isMWeapon(osec))then ekidona_mags.WeaponEjectMag(obj)
			elseif(ekidona_mags.isMagazine(osec))then ekidona_mags.MagEjectAmmo(obj)
			elseif(ekidona_mags.isMSuit(osec) and #ekidona_mags.GetMagazinesDB(FocusedItem)>0)then ekidona_mags.mag_trans_wpn_ui(obj,nil,true):ShowDialog(true)end
end end end
function actor_on_net_destroy() ItemsText:Show(false) TimeFocused=0 end