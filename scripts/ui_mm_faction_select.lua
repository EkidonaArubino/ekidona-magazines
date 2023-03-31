-- Faction Select for Call of Chernobyl
-- alundaio

local loadout_cost =
{
	30, --1
	50, --2
	20, --3
	40, --4
	30, --5
	60, --6
	40, --7
	--perks
	20, --8
	20, --9
	20, --10
	20, --11
	30, --12	
	30, --13
	30, --14
	30, --15
	30, --16
	
}

local function create_mags(wsec,pos,lvid,gvid) local ammo=alun_utils.parse_list(system_ini(),wsec,"ammo_class")[1]:sub(1,-2)
	local mags=ekidona_mags.GetMagName(wsec,2,2,system_ini():r_float_ex(wsec,"ammo_elapsed"),ammo)
	ekidona_mags.CreateMagazine(mags[1],pos,lvid,gvid,0,ammo,system_ini():r_float_ex(wsec,"ammo_elapsed"))
end
local function create_loadout(number)

	if (number == 1) then
	
		if (math.random(100) > 50) then
			alife():create("wpn_toz34_obrez",db.actor:position(),db.actor:level_vertex_id(),db.actor:game_vertex_id(),0)
		else
			alife():create("wpn_bm16",db.actor:position(),db.actor:level_vertex_id(),db.actor:game_vertex_id(),0)
		end
		alife():create("ammo_12x70_buck",db.actor:position(),db.actor:level_vertex_id(),db.actor:game_vertex_id(),0)
		alife():create("novice_outfit",db.actor:position(),db.actor:level_vertex_id(),db.actor:game_vertex_id(),0)
		alife():create("helm_cloth_mask",db.actor:position(),db.actor:level_vertex_id(),db.actor:game_vertex_id(),0)
		alife():create("device_flashlight",db.actor:position(),db.actor:level_vertex_id(),db.actor:game_vertex_id(),0)
		alife():create("cigarettes_russian_2",db.actor:position(),db.actor:level_vertex_id(),db.actor:game_vertex_id(),0)
	elseif (number == 2) then
		alife():create("wpn_knife3",db.actor:position(),db.actor:level_vertex_id(),db.actor:game_vertex_id(),0)
		local wpn=alife():create("wpn_ak74u",db.actor:position(),db.actor:level_vertex_id(),db.actor:game_vertex_id(),0)
		for i=1,4 do create_mags("wpn_ak74u",db.actor:position(),db.actor:level_vertex_id(),db.actor:game_vertex_id())end
		ekidona_mags.WaMArray[wpn.id]=ekidona_mags.GetMagName("wpn_ak74u",2,1,system_ini():r_float_ex("wpn_ak74u","ammo_elapsed"),alun_utils.parse_list(system_ini(),"wpn_ak74u","ammo_class")[1]:sub(1,-2))[1]
		--[[alife():create("ammo_5.45x39_ap",db.actor:position(),db.actor:level_vertex_id(),db.actor:game_vertex_id(),0)
		alife():create("ammo_5.45x39_ap",db.actor:position(),db.actor:level_vertex_id(),db.actor:game_vertex_id(),0)]]
		alife():create("grenade_f1",db.actor:position(),db.actor:level_vertex_id(),db.actor:game_vertex_id(),0)
		alife():create("grenade_f1",db.actor:position(),db.actor:level_vertex_id(),db.actor:game_vertex_id(),0)
		alife():create("grenade_f1",db.actor:position(),db.actor:level_vertex_id(),db.actor:game_vertex_id(),0)
	elseif (number == 3) then
		alife():create("tushonka",db.actor:position(),db.actor:level_vertex_id(),db.actor:game_vertex_id(),0)
		alife():create("tushonka",db.actor:position(),db.actor:level_vertex_id(),db.actor:game_vertex_id(),0)
		alife():create("medkit",db.actor:position(),db.actor:level_vertex_id(),db.actor:game_vertex_id(),0)
		alife():create("bandage",db.actor:position(),db.actor:level_vertex_id(),db.actor:game_vertex_id(),0)
		alife():create("bandage",db.actor:position(),db.actor:level_vertex_id(),db.actor:game_vertex_id(),0)
		alife():create("bandage",db.actor:position(),db.actor:level_vertex_id(),db.actor:game_vertex_id(),0)
		alife():create("antirad",db.actor:position(),db.actor:level_vertex_id(),db.actor:game_vertex_id(),0)
		alife():create("drug_charcoal_5",db.actor:position(),db.actor:level_vertex_id(),db.actor:game_vertex_id(),0)
		alife():create("bottle_metal_3",db.actor:position(),db.actor:level_vertex_id(),db.actor:game_vertex_id(),0)
	elseif (number == 4) then
		alife():create("helm_respirator",db.actor:position(),db.actor:level_vertex_id(),db.actor:game_vertex_id(),0)
		alife():create("geiger",db.actor:position(),db.actor:level_vertex_id(),db.actor:game_vertex_id(),0)
		alife():create("detector_simple",db.actor:position(),db.actor:level_vertex_id(),db.actor:game_vertex_id(),0)
		alife():create("lead_box",db.actor:position(),db.actor:level_vertex_id(),db.actor:game_vertex_id(),0)
		alife():create("backpack_heavy",db.actor:position(),db.actor:level_vertex_id(),db.actor:game_vertex_id(),0)
	elseif (number == 5) then
		alife():create("itm_repairkit_tier_1",db.actor:position(),db.actor:level_vertex_id(),db.actor:game_vertex_id(),0)
		alife():create("tarpaulin",db.actor:position(),db.actor:level_vertex_id(),db.actor:game_vertex_id(),0)
		alife():create("textolite",db.actor:position(),db.actor:level_vertex_id(),db.actor:game_vertex_id(),0)
		alife():create("capacitors",db.actor:position(),db.actor:level_vertex_id(),db.actor:game_vertex_id(),0)
		alife():create("transistors",db.actor:position(),db.actor:level_vertex_id(),db.actor:game_vertex_id(),0)
		alife():create("colophony",db.actor:position(),db.actor:level_vertex_id(),db.actor:game_vertex_id(),0)
		alife():create("copper_coil",db.actor:position(),db.actor:level_vertex_id(),db.actor:game_vertex_id(),0)
		alife():create("rope",db.actor:position(),db.actor:level_vertex_id(),db.actor:game_vertex_id(),0)
		alife():create("swiss",db.actor:position(),db.actor:level_vertex_id(),db.actor:game_vertex_id(),0)
		alife():create("textile_patch_b",db.actor:position(),db.actor:level_vertex_id(),db.actor:game_vertex_id(),0)
		alife():create("wpn_hand_hammer",db.actor:position(),db.actor:level_vertex_id(),db.actor:game_vertex_id(),0)
		alife():create("wpn_addon_scope_pu",db.actor:position(),db.actor:level_vertex_id(),db.actor:game_vertex_id(),0)
	elseif (number == 6) then
		alife():create("stalker_outfit",db.actor:position(),db.actor:level_vertex_id(),db.actor:game_vertex_id(),0)
		alife():create("device_torch_dummy",db.actor:position(),db.actor:level_vertex_id(),db.actor:game_vertex_id(),0)
	elseif (number == 7) then
		alife():create("merc_outfit",db.actor:position(),db.actor:level_vertex_id(),db.actor:game_vertex_id(),0)
		alife():create("device_lighter",db.actor:position(),db.actor:level_vertex_id(),db.actor:game_vertex_id(),0)
		alife():create("wpn_sil_9mm",db.actor:position(),db.actor:level_vertex_id(),db.actor:game_vertex_id(),0)
		alife():create("batteries_dead",db.actor:position(),db.actor:level_vertex_id(),db.actor:game_vertex_id(),0)
		alife():create("grooming",db.actor:position(),db.actor:level_vertex_id(),db.actor:game_vertex_id(),0)
		alife():create("picture_woman",db.actor:position(),db.actor:level_vertex_id(),db.actor:game_vertex_id(),0)
		alife():create("cards",db.actor:position(),db.actor:level_vertex_id(),db.actor:game_vertex_id(),0)
		alife():create("flashlight_broken",db.actor:position(),db.actor:level_vertex_id(),db.actor:game_vertex_id(),0)
		alife():create("mirror",db.actor:position(),db.actor:level_vertex_id(),db.actor:game_vertex_id(),0)
	
	elseif (number == 8) then
		give_info("perk_knife_master")
	elseif (number == 9) then
		give_info("perk_craft")
	elseif (number == 10) then
		give_info("perk_strong_stomach")
	elseif (number == 11) then
		give_info("perk_lead_backpack")
	elseif (number == 12) then
		give_info("perk_steady_hands")
	elseif (number == 13) then
		give_info("perk_butcher")
	elseif (number == 14) then
		give_info("perk_authority")
	elseif (number == 15) then
		give_info("perk_thoroughness")
	elseif (number == 16) then
		give_info("perk_geologist")
	end
	
end
------------------
-- on_game_load()
------------------
local spawn_path, start_pos
local function on_game_load(binder)
	local config = axr_main.config
	if not (config) then
		return
	end

	local se_actor = alife():actor()
	local need_save

	-- IRONMAN MODE
	if (USE_MARSHAL) then
		if (config:r_value("character_creation","new_game_hardcore_mode",1) == true) then
			-- shitty way to make a uuid but should be good enough to track the same saves
			alife_storage_manager.get_state().uuid = GAME_VERSION .. "_" .. tostring(math.random(100)) .. tostring(math.random()) .. tostring(math.random(1000))
			config:w_value("character_creation","new_game_hardcore_mode")
			need_save = true
		end
		if (config:r_value("character_creation","new_game_survival_mode",1) == true) then
			alife_storage_manager.get_state().enable_survival_mode = true
			config:w_value("character_creation","new_game_survival_mode")
			need_save = true
		end
		if (config:r_value("character_creation","new_game_laststand_mode",1) == true) then
			alife_storage_manager.get_state().enable_laststand_mode = true
			config:w_value("character_creation","new_game_laststand_mode")
			need_save = true
		end
		if (config:r_value("character_creation","new_game_azazel_mode",1) == true) then
			alife_storage_manager.get_state().enable_azazel_mode = true
			config:w_value("character_creation","new_game_azazel_mode")
			need_save = true
		end
		if (config:r_value("character_creation","new_game_easy_mode",1) == true) then
			alife_storage_manager.get_state().enable_easy_mode = true
			config:w_value("character_creation","new_game_easy_mode")
			need_save = true
		end
		if (config:r_value("character_creation","new_game_good_wpn",1) == true) then
			alife_storage_manager.get_state().enable_good_wpn = true
			config:w_value("character_creation","new_game_good_wpn")
			need_save = true
		end
		if (config:r_value("character_creation","new_game_good_loot",1) == true) then
			alife_storage_manager.get_state().enable_good_loot = true
			config:w_value("character_creation","new_game_good_loot")
			need_save = true
		end
	end

	-- NEW CHARACTER NAME
	local new_character_name = config:r_value("character_creation","new_game_character_name",3) or ""
	if (new_character_name and new_character_name ~= "") then
		config:w_value("character_creation","old_game_character_name",new_character_name)
		config:w_value("character_creation","new_game_character_name")
		need_save = true

		new_character_name = new_character_name:gsub("_"," ")

		se_actor:set_character_name(new_character_name)
	end


	db.actor_binder.character_icon = "ui_inGame2_neutral_1"
	
	local faction = config:r_value("character_creation","new_game_faction",3) or ""
	
	if (faction and faction ~= "") then
		config:w_value("character_creation","new_game_faction")
		need_save = true
		
		-- Faction Spawn Position
		local start_location = config:r_value("character_creation","new_game_faction_position")
		config:w_value("character_creation","new_game_faction_position")

		if start_location and start_location ~= "" then
			local loc_ini = ini_file("plugins\\faction_start_locations.ltx")

			start_pos = {}
			table.insert(start_pos,loc_ini:r_float_ex(start_location, "lvid"))
			table.insert(start_pos,loc_ini:r_float_ex(start_location, "gvid"))
			table.insert(start_pos,vector():set(loc_ini:r_float_ex(start_location,"x"),loc_ini:r_float_ex(start_location,"y"),loc_ini:r_float_ex(start_location,"z")))
		else
			spawn_path = patrol("spawn_player_"..faction)
		end
		
		config:w_value("character_creation","new_game_story_mode") -- clear value
		-- Unlock the encyclopedia at the beginning of the game if toggled.
		if (config:r_value("character_creation", "new_game_unlocked_guide", 1) == true) then
			give_info("guide_cheated")
		end
		config:w_value("character_creation","new_game_unlocked_guide") -- clear value
		
		db.actor:set_character_community("actor_"..faction, 0, 0)

		local communities = alun_utils.get_communities_list( )
		for i, community in pairs( communities ) do
			relation_registry.set_community_goodwill( community, 0, 0 )
		end

		-- money and loadout
		local money_max
		local loadout = config:r_value("character_creation","new_game_loadout",3)
		if (loadout and loadout ~= "") then
			config:w_value("character_creation","new_game_loadout")
			need_save = true
			db.actor_binder.character_icon = new_character_icon
			local ini = system_ini()
			local sim = alife()
			local t = alun_utils.str_explode(loadout,",")
			for i=1,#t do
				local kv_pair = alun_utils.str_explode(t[i],"=")
				if (kv_pair[1]) then
					kv_pair[2] = tonumber(kv_pair[2]) or 1
					if (kv_pair[1] == "money") then
						money_max = kv_pair[2]
					elseif (ini:section_exist(kv_pair[1])) then
						for ii=1,kv_pair[2] do
							sim:create(kv_pair[1],db.actor:position(),db.actor:level_vertex_id(),db.actor:game_vertex_id(),0)
						end
					end
				end
			end
		end
		
		local loadout_code = tonumber(config:r_value("character_creation","new_game_loadout_code",3) or "0")		
		for index = 1, #loadout_cost do
			if (bit_and(loadout_code,math.pow(2,index)) ~= 0) then
				create_loadout(index)
			end
		end
		config:w_value("character_creation","new_game_loadout_code")
		
		se_actor:set_profile_name("actor_"..faction)
		
		if (money_max) then
			db.actor:give_money(-db.actor:money()+money_max)
		end
	end

	if (need_save) then
		config:save()
	end
end

local function actor_on_first_update(binder,delta)
	if (spawn_path) then
		start_pos = {}
		start_pos[1] = spawn_path:level_vertex_id(0)
		start_pos[2] = spawn_path:game_vertex_id(0)
		start_pos[3] = spawn_path:point(0)
	end

	-- Survival mode
	if (IsSurvivalMode()) then
		game_relations.change_factions_community_num("zombied",0,-5000)
		game_relations.change_factions_community_num("monolith",0,-5000)
		--[[ Survival squad
		local faction = character_community(db.actor):sub(7)
		if (system_ini():section_exist("survival_squad_"..faction) and start_pos) then
			local sim = alife()
			local squad = sim:create("survival_squad_"..faction,start_pos[3],start_pos[1],start_pos[2])
			if (squad) then
				axr_companions.companion_squads[squad.id] = squad
				squad:create_npc(nil,start_pos[3],start_pos[1],start_pos[2])
				local as
				for k in squad:squad_members() do
					local se_obj = k.object or k.id and sim:object(k.id)
					if (se_obj) then
						game_relations.change_factions_community_num("zombied",k.id,-5000)
						SIMBOARD:setup_squad_and_group(se_obj)

						utils.se_obj_save_var(se_obj.id,se_obj:name(),"companion",true)
						utils.se_obj_save_var(se_obj.id,se_obj:name(),"companion_cannot_dismiss",true)
					end
				end
			end
		end
		--]]
	end

	
	if (start_pos and #start_pos == 3) then		
		if (start_pos[2] ~= 5303) then
			ChangeLevel(start_pos[3],start_pos[1],start_pos[2],vector():set(0,0,0))
		end
	end
end

local function actor_on_update()
	if (not xr_actor.first_update_time) or (xr_actor.first_update_time+500 > time_global()) then
		return
	end
	actor_on_first_update()
end

local function actor_on_before_death()
	if not (USE_MARSHAL) then
		return
	end

	local uuid = alife_storage_manager.get_state().uuid
	if not (uuid) then
		return -- not in hardcore mode
	end

	local fs = getFS()
	local flist = fs:file_list_open_ex("$game_saves$",bit_or(FS.FS_ListFiles,FS.FS_RootOnly),"*.scoc")
	local f_cnt = flist:Size()

	for	it=0, f_cnt-1 	do
		local file = flist:GetAt(it)
		local file_name = string.sub(file:NameFull(), 0, (string.len(file:NameFull()) - string.len(".scoc")))

		--printf("file_name = %s",file_name)
		local f = io.open(fs:update_path('$game_saves$', '')..file_name..".scoc","rb")
		if (f) then
			local data = f:read("*all")
			f:close()
			if (data) then
				local decoded = alife_storage_manager.decode(data)
				if (decoded and decoded.uuid == uuid) then
					printf("deleting saves with uuid = %s",uuid)
					ui_load_dialog.delete_save_game(file_name)
				end
			end
		end
	end
end

------------------
-- on_game_start()
------------------
function on_game_start()
	RegisterScriptCallback("on_game_load",on_game_load)
	RegisterScriptCallback("actor_on_before_death",actor_on_before_death)
	--RegisterScriptCallback("actor_on_first_update",actor_on_first_update)
	RegisterScriptCallback("actor_on_update",actor_on_update)
end

--------------------------------------------------------------
-- faction_ui
--------------------------------------------------------------

class "faction_ui" (CUIScriptWnd)
function faction_ui:__init(owner) super()
	self.owner = owner

	self.ini = ini_file("plugins\\faction_loadouts.ltx")
	
	if (axr_main.config:r_value("mm_options","enable_debug_hud",1,false) == true) then
		self.ini = ini_file("plugins\\faction_loadouts_debug.ltx")
	end
	
	self.selected_faction = nil
	self.f = {"stalker","bandit","csky","dolg","freedom","killer","army","ecolog","monolith"}

	self:InitControls(self.f)
	self:InitCallBacks(self.f)
end

function faction_ui:__finalize()
end

function faction_ui:InitControls(f)
	self:SetWndRect				(Frect():set(0,0,1024,768))
	self:Enable					(true)

	local xml					= CScriptXmlInit()
	xml:ParseFile				("ui_mm_faction_select.xml")

	xml:InitStatic				("background", self)
	self.dialog					= xml:InitStatic("main_dialog:dialog", self)
	
	-- Menu Quit
	local btn = xml:Init3tButton("main_dialog:btn_back", self.dialog)
	self:Register(btn,"btn_back")

	-- Menu Start Game
	btn = xml:Init3tButton("main_dialog:btn_submit", self.dialog)
	self:Register(btn,"btn_submit")

	-- character_name edit box
	xml:InitStatic("main_dialog:cap_character_name", self.dialog)
	self.character_name = xml:InitEditBox("main_dialog:input_character_name",self.dialog)
	self:Register(self.character_name,"input_character_name")
	-- Set Default Name
	local old_character_name = axr_main.config:r_value("character_creation","old_game_character_name",3) or game.translate_string("pri_b305_strelok_name")
	old_character_name = old_character_name:gsub("_"," ")
	self.character_name:SetText(old_character_name)

	
	-- Faction select menu

	--xml:InitStatic("main_dialog:cap_faction_name", self.dialog)
	--self.disp_faction_name = xml:InitTextWnd("main_dialog:disp_faction_name", self.dialog)

	--local pw
	--for i=1,#f do
	--	self["btn_"..self.f[i]] = xml:Init3tButton("main_dialog:faction_"..f[i],self.dialog)
	--	self["btn_"..f[i].."_inactive"] = xml:Init3tButton("main_dialog:faction_"..f[i].."_inactive", self.dialog)
	--	self:Register(self["btn_"..f[i].."_inactive"],"btn_"..f[i].."_inactive_select")
	--end
	
	self:OnFaction_stalker()

	self.start_list = xml:InitComboBox("main_dialog:list_starts", self.dialog)
	self.start_list:SetAutoDelete(true)
	self:Register(self.start_list, "list_starts")
	
	if not (DEV_DEBUG_DEV) then
		self.start_list:Show(false)
	end
	
	self:load_start_positions()

	if (USE_MARSHAL) then
		--[[
		xml:InitStatic("main_dialog:cap_check_story",self.dialog)
		self.ck_story = xml:InitCheck("main_dialog:check_story",	self.dialog)
		self:Register(self.ck_story,"check_story")
		--]]
		
		xml:InitStatic("main_dialog:cap_check_hardcore",self.dialog)
		self.ck_hardcore = xml:InitCheck("main_dialog:check_hardcore",	self.dialog)
		self:Register(self.ck_hardcore,"check_hardcore")
		--[[
		xml:InitStatic("main_dialog:cap_check_azazel_mode",self.dialog)
		self.ck_azazel_mode = xml:InitCheck("main_dialog:check_azazel_mode",	self.dialog)
		self:Register(self.ck_azazel_mode,"check_azazel_mode")
		--]]
		xml:InitStatic("main_dialog:cap_check_survival",self.dialog)
		self.ck_survival = xml:InitCheck("main_dialog:check_survival",	self.dialog)
		self:Register(self.ck_survival,"check_survival")
		
		xml:InitStatic("main_dialog:cap_check_laststand_mode",self.dialog)
		self.ck_laststand = xml:InitCheck("main_dialog:check_laststand_mode",	self.dialog)
		self:Register(self.ck_laststand,"check_laststand_mode")
		
		xml:InitStatic("main_dialog:cap_check_easy_mode",self.dialog)
		self.ck_easy = xml:InitCheck("main_dialog:check_easy_mode",	self.dialog)
		self:Register(self.ck_easy,"check_easy_mode")
		
		xml:InitStatic("main_dialog:cap_check_good_wpn",self.dialog)
		self.ck_good_wpn = xml:InitCheck("main_dialog:check_good_wpn",	self.dialog)
		self:Register(self.ck_good_wpn,"check_good_wpn")
		
		xml:InitStatic("main_dialog:cap_check_good_loot",self.dialog)
		self.ck_good_loot = xml:InitCheck("main_dialog:check_good_loot",	self.dialog)
		self:Register(self.ck_good_loot,"check_good_loot")
		
		--]]
		self.ck_states = { 	["ck_survival"] = false,
							["ck_laststand"] = false,
							["ck_hardcore"] = false,
							["ck_azazel_mode"] = false,
							["ck_easy"] = false,
							["ck_good_wpn"] = false,
							["ck_good_loot"] = false,
		}
	end
	
	
	--xml:InitFrame				("main_dialog:frame_main", self.dialog)
	xml:InitFrame				("main_dialog:frame_buttons", self.dialog)
	
	-- Hint Window
	self.hint_wnd = xml:InitFrame("hint_wnd:background",self)
	self.hint_wnd:SetAutoDelete(false)
	self.hint_wnd_text = xml:InitTextWnd("hint_wnd:text",self.hint_wnd)
	self.hint_wnd:Show(false)
	
	-- Message Window 
	self.msg_wnd = xml:InitFrame("hint_wnd:background",self)
	self.msg_wnd:SetAutoDelete(false)
	self.msg_wnd_text = xml:InitTextWnd("hint_wnd:text",self.msg_wnd)
	self.msg_wnd_text:SetTextAlignment(2)
	
	self.msg_wnd:Show(false)
	self.msg_wnd:SetColor(GetARGB(255,0,0,0))
	
	
	-- Loadout
		
	--xml:InitStatic("main_dialog:loadout1:background", self.dialog)
	xml:InitFrame("main_dialog:loadout1:frame",self.dialog)
	self.caption_loadout1 = xml:InitTextWnd("main_dialog:loadout1:caption",self.dialog)
	self.list_loadout_1 = xml:InitListBox("main_dialog:loadout1:list",self.dialog)
	self.list_loadout_1:ShowSelectedItem(true)
	self.list_loadout_1:Show(true)
	self:Register(self.list_loadout_1, "list_loadout_1")
		
	--xml:InitStatic("main_dialog:loadout2:background", self.dialog)
	xml:InitFrame("main_dialog:loadout2:frame",self.dialog)
	self.caption_loadout2 = xml:InitTextWnd("main_dialog:loadout2:caption",self.dialog)
	self.list_loadout_2 = xml:InitListBox("main_dialog:loadout2:list",self.dialog)
	self.list_loadout_2:ShowSelectedItem(true)
	self.list_loadout_2:Show(true)
	self:Register(self.list_loadout_2, "list_loadout_2")
		
	for i = 1, #loadout_cost do
		local _itm = set_list_text(i,loadout_cost[i])
		self.list_loadout_2:AddExistingItem(_itm)
	end
	
		
	-- Loadout description window
	--xml:InitStatic("main_dialog:loadout_description:background", self.dialog)
	xml:InitFrame("main_dialog:loadout_description:list_frame",self.dialog)
	self.loadout_scroll_v = xml:InitScrollView("main_dialog:loadout_description:scroll_v", self.dialog)
	self.loadout_desc_text = xml:InitTextWnd("main_dialog:loadout_description:desc_win", nil)
	self.loadout_scroll_v:AddWindow(self.loadout_desc_text, true)
	self.loadout_desc_text:SetAutoDelete(false)
	self.loadout_points = 100
	
	self.caption_loadout1:SetText(game.translate_string("st_loadout1_caption").." "..100-self.loadout_points)
	self.caption_loadout2:SetText(game.translate_string("st_loadout2_caption").." "..self.loadout_points)

end

function faction_ui:InitCallBacks(f)
	self:AddCallback("btn_back", ui_events.BUTTON_CLICKED, self.OnQuit, self)
	self:AddCallback("btn_submit", ui_events.BUTTON_CLICKED, self.OnStartGame, self)
	self:AddCallback("list_factions", ui_events.LIST_ITEM_SELECT, self.OnSelectFactionList,	self)

	self:AddCallback("list_starts", ui_events.LIST_ITEM_SELECT, self.OnSelectStartLocation, self)
	
	self:AddCallback("list_loadout_1", ui_events.LIST_ITEM_CLICKED,			self.OnLoadout1Clicked,		self)
	self:AddCallback("list_loadout_1", ui_events.WINDOW_LBUTTON_DB_CLICK,	self.OnLoadout1DbClicked,	self)
	self:AddCallback("list_loadout_2", ui_events.LIST_ITEM_CLICKED,			self.OnLoadout2Clicked,		self)
	self:AddCallback("list_loadout_2", ui_events.WINDOW_LBUTTON_DB_CLICK,	self.OnLoadout2DbClicked,	self)
	
	
end

function faction_ui:Update()
	CUIScriptWnd.Update(self)
	-- Warning messages timer
	if (self.msg_wnd_timer and time_global() > self.msg_wnd_timer) then
		self.msg_wnd_timer = nil
		self.msg_wnd:Show(false)
	end
	
	for ck_name,v in pairs(self.ck_states) do
		if (self[ck_name] and self[ck_name]:IsCursorOverWindow()) then
			self:SetHint(game.translate_string("st_mm_"..ck_name.."_desc"))
			return
		end
	end
	self.hint_wnd:Show(false)
end 

function faction_ui:SetMsg(text,tmr)
	if (text == "") then 
		return 
	end
	self.msg_wnd:Show(true)
	self.msg_wnd_text:SetText(text)
	self.msg_wnd_text:AdjustHeightToText()
	self.msg_wnd_text:SetWndSize(vector2():set(820,self.msg_wnd_text:GetHeight()+10))
	self.msg_wnd_text:SetWndPos(vector2():set(0,20))
	
	self.msg_wnd:SetWndSize(vector2():set(820,self.msg_wnd_text:GetHeight()+44))
	self.msg_wnd:SetWndPos(vector2():set(0,80))

	self.msg_wnd_timer = time_global() + 1000*tmr
end

function faction_ui:SetHint(text,pos)
	if (text == "") then
		return
	end
	self.hint_wnd:Show(true)
	self.hint_wnd_text:SetText(text)
	self.hint_wnd_text:AdjustHeightToText()
	self.hint_wnd:SetWndSize(vector2():set(self.hint_wnd:GetWidth(),self.hint_wnd_text:GetHeight()+44))
	
	pos = pos or GetCursorPosition()
	pos.y = pos.y - self.hint_wnd:GetHeight()
	pos.x = pos.x - self.hint_wnd:GetWidth()
	self.hint_wnd:SetWndPos(pos)
	
	FitInRect(self.hint_wnd,Frect():set(0,0,1024,768),0,100)
end

function faction_ui:OnCheckSetStory()
end

function faction_ui:OnCheckSetAzazel()
end

function faction_ui:OnCheckSetSurvival()
end

function faction_ui:OnSelectStartLocation()
	self.start_location = self.start_table[self.start_list:CurrentID()]
end

function faction_ui:OnSelectPortrait()
	--self.char_icon:InitTexture(self.icon_list:GetText())
end

function faction_ui:load_start_positions()
	self.start_list:ClearList()
	self.start_table = {}

	local loc_ini = ini_file("plugins\\faction_start_locations.ltx")

	local n = loc_ini:line_count(self.selected_faction.."_start_locations") or 0
	for i=0, n-1 do
		local result, id, value = loc_ini:r_line(self.selected_faction.."_start_locations",i,"","" )
		table.insert(self.start_table,id)
	end
	self.start_location = self.start_table[1]
	for i=1,#self.start_table do
		self.start_list:AddItem(game.translate_string("ui_st_"..self.start_table[i]),i)
	end
	self.start_list:SetText(game.translate_string("ui_st_"..self.start_table[1]))
end

function faction_ui:OnFactionSelect(faction)
	local gs = game.translate_string
	local desc = gs("st_faction_"..faction.."_desc") .. "\\n \\n"

	desc = desc .. "%c[0,245,245,220]st_mm_faction_relations:\\n"

	local t = {"stalker","bandit","csky","ecolog","army","monolith","dolg","freedom","killer"}
	for i=1,#t do
		if not (t[i] == faction) then
			local v = relation_registry.community_relation("actor_"..faction, t[i])
			if (v >= 1000) then
				desc = desc .. "   %c[0,51,255,51]".. gs("st_faction_"..t[i]) .. "\\n"
			elseif (v <= -1000) then
				desc = desc .. "   %c[0,255,0,0]" .. gs("st_faction_"..t[i]) .. "\\n"
			else
				desc = desc .. "   %c[0,255,255,51]" .. gs("st_faction_"..t[i]) .. "\\n"
			end
		end
	end

	local sys_ini = system_ini()

	desc = desc .. "\\n \\n"
	if axr_main.config:r_value("character_creation","custom_loadout",1) then
		self.default_loadout = alun_utils.collect_sections(self.ini,{"custom"})
		local weapons = alun_utils.str_explode(self.default_loadout["weapons"],",")
		for _, w in ipairs(weapons) do
			if sys_ini:section_exist(w) then
				self.default_loadout[w] = 1
				local ammo = sys_ini:r_string_ex(w,"ammo_class")
				ammo = alun_utils.str_explode(ammo,",")
				ammo = ammo[1] --ammo[math.random(#ammo)]
				self.default_loadout[ammo] = 2
			end
		end
	else	
		self.default_loadout = alun_utils.collect_sections(self.ini,{faction,math.random(1,5)})
		--[[local weapon = alun_utils.collect_section(self.ini,"choose_only_one")
		weapon = weapon[math.random(#weapon)]

		local ammo = sys_ini:r_string_ex(weapon,"ammo_class")
		ammo = alun_utils.str_explode(ammo,",")
		ammo = ammo[math.random(#ammo)]

		self.default_loadout[weapon] = 1
		self.default_loadout[ammo] = 2--]]
	end

	local money = alun_utils.str_explode(self.default_loadout["money"],",")
	money = money[math.random(#money)]
	self.default_loadout["money"] = money

	desc = desc .. "%c[0,245,245,220]st_mm_faction_money: %c[0,188,210,238]".. self.default_loadout["money"] .. " RU\\n \\n"
	desc = desc .. "%c[0,245,245,220]st_mm_faction_equipment:\\n"

	self.loadout_str = strformat("money = %s,",self.default_loadout["money"])

	for section, amt in pairs(self.default_loadout) do
		if (section ~= "weapons" and section ~= "money" and sys_ini:section_exist(section)) then
			local itm_name = gs(sys_ini:r_string_ex(section,"inv_name") or "")
			amt = amt == "" and {1} or alun_utils.str_explode(amt,",")
			amt = tonumber(amt[math.random(#amt)]) or 0
			if (amt > 0) then
				if (amt > 1) then
					if (utils.is_ammo(section)) then
						local box_size = (sys_ini:r_float_ex(section, "box_size") or 1) * amt
						desc = desc .. "   %c[0,188,210,238]".. itm_name .. " %c[0,245,245,220]x"..tostring(box_size).."\\n"
					else
						desc = desc .. "   %c[0,188,210,238]".. itm_name .. " %c[0,245,245,220]x"..tostring(amt).."\\n"
					end
					self.loadout_str = strformat("%s %s = %s,",self.loadout_str,section,amt)
				else
					if (utils.is_ammo(section)) then
						local box_size = (sys_ini:r_float_ex(section, "box_size") or 1) * amt
						desc = desc .. "   %c[0,188,210,238]".. itm_name .. " %c[0,245,245,220]x"..tostring(box_size).."\\n"
					else
						desc = desc .. "   %c[0,188,210,238]".. itm_name .."\\n"
					end
					self.loadout_str = strformat("%s %s = %s,",self.loadout_str,section,amt)
				end
			end
		end
	end
	
	for s in string.gmatch(desc,"(st_mm_faction_[%w%d_]*)") do
		desc = string.gsub(desc,s,game.translate_string(s))
	end

	self.selected_faction = faction

	
	--for i=1,#self.f do
	--	self["btn_"..self.f[i]]:Show(false)
	--	self["btn_"..self.f[i].."_inactive"]:Show(true)
	--end

	--if (self["btn_".. faction]) then
	--	self["btn_"..faction]:Show(true)
	--	self["btn_"..faction.."_inactive"]:Show(false)
	--end
	--self.disp_faction_name:SetText(gs("st_faction_"..faction))
		
	if self.start_list then
		self:load_start_positions()
	end
end

function faction_ui:OnFaction_stalker()
	self:OnFactionSelect("stalker")
end
function faction_ui:OnFaction_bandit()
	self:OnFactionSelect("bandit")
end
function faction_ui:OnFaction_csky()
	self:OnFactionSelect("csky")
end
function faction_ui:OnFaction_dolg()
	self:OnFactionSelect("dolg")
end
function faction_ui:OnFaction_freedom()
	self:OnFactionSelect("freedom")
end
function faction_ui:OnFaction_killer()
	self:OnFactionSelect("killer")
end
function faction_ui:OnFaction_army()
	self:OnFactionSelect("army")
end
function faction_ui:OnFaction_ecolog()
	self:OnFactionSelect("ecolog")
end
function faction_ui:OnFaction_monolith()
	self:OnFactionSelect("monolith")
end
function faction_ui:OnFaction_zombied()
	self:OnFactionSelect("zombied")
end

function faction_ui:OnLoadout1Clicked()
	local item = self.list_loadout_1:GetSelectedItem()
	if not (item) then return end
	
	self.loadout_desc_text:SetText(game.translate_string("st_loadout_points").." "..item.points.."\n \n"..game.translate_string("st_"..item.string.."_descr"))
	self.loadout_desc_text:AdjustHeightToText()
	self.loadout_desc_text:SetWndSize(vector2():set(self.loadout_desc_text:GetWidth(),self.loadout_desc_text:GetHeight()))
	self.loadout_scroll_v:Clear()
	self.loadout_scroll_v:AddWindow(self.loadout_desc_text, true)
	self.loadout_desc_text:SetAutoDelete(false)
end

function faction_ui:OnLoadout1DbClicked()
	local item = self.list_loadout_1:GetSelectedItem()
	if not (item) then return end
	
	
	local points = item.points
	self.loadout_points = self.loadout_points+points
	self.caption_loadout2:SetText(game.translate_string("st_loadout2_caption").." "..self.loadout_points)
	self.caption_loadout1:SetText(game.translate_string("st_loadout1_caption").." "..100-self.loadout_points)
	
	local _itm = set_list_text(item.idx,item.points)
	self.list_loadout_2:AddExistingItem(_itm)
	self.list_loadout_1:RemoveItem(item)
	self.loadout_desc_text:SetText("")
end

function faction_ui:OnLoadout2Clicked()
	local item = self.list_loadout_2:GetSelectedItem()
	if not (item) then return end
	
	self.loadout_desc_text:SetText(game.translate_string("st_loadout_points").." "..item.points.."\n \n"..game.translate_string("st_"..item.string.."_descr"))
	self.loadout_desc_text:AdjustHeightToText()
	self.loadout_desc_text:SetWndSize(vector2():set(self.loadout_desc_text:GetWidth(),self.loadout_desc_text:GetHeight()))
	self.loadout_scroll_v:Clear()
	self.loadout_scroll_v:AddWindow(self.loadout_desc_text, true)
	self.loadout_desc_text:SetAutoDelete(false)
end

function faction_ui:OnLoadout2DbClicked()
	local item = self.list_loadout_2:GetSelectedItem()
	if not (item) then return end
	
	local points = item.points
	
	if (points > self.loadout_points) then
		return
	end
	
	self.loadout_points = self.loadout_points-points
	self.caption_loadout2:SetText(game.translate_string("st_loadout2_caption").." "..self.loadout_points)
	self.caption_loadout1:SetText(game.translate_string("st_loadout1_caption").." "..100-self.loadout_points)
	
	local _itm = set_list_text(item.idx,item.points)
	self.list_loadout_1:AddExistingItem(_itm)
	self.list_loadout_2:RemoveItem(item)
	self.loadout_desc_text:SetText("")
end

function faction_ui:OnKeyboard(dik, keyboard_action)
	local res = CUIScriptWnd.OnKeyboard(self,dik,keyboard_action)
	if res==false then
		local bind = dik_to_bind(dik)
		if keyboard_action == ui_events.WINDOW_KEY_PRESSED then
			if dik == DIK_keys.DIK_ESCAPE then
				self:OnQuit()
			elseif (dik == DIK_keys.DIK_Z) then
				--self:OnFaction_zombied()
			end
		end
	end
	return res
end

function faction_ui:OnQuit()
	self.owner:ShowDialog(true)
	self.owner:Show(true)
	if (self:IsShown()) then
		self:HideDialog()
	end
	self:Show(false)
end

function faction_ui:OnStartGame()
	-- start game anyway if no config or axr_main script
	if not (axr_main and axr_main.config) then
		self.owner:StartGame()
		return
	end

	local character_name = self.character_name:GetText()
	if (character_name == "") then
		-- Require a name to be entered.
		return
	end

	if (self.start_list:CurrentID() <= 0) then
		self.start_location = self.start_table[1]
		self.start_list:SetText(game.translate_string("ui_st_"..self.start_table[1]))
	end
	
	if not DEV_DEBUG_DEV then
		if (self.ck_laststand and self.ck_laststand:GetCheck() and true or nil) then
			self.start_location = "military_base"
			self.start_list:SetText(game.translate_string("ui_st_military_base"))
			self.selected_faction = "freedom"
		else
			self.start_location = "_rookie_village"
			self.start_list:SetText(game.translate_string("ui_st_rookie_village"))	
		end
	end

	axr_main.config:w_value("character_creation","new_game_hardcore_mode",self.ck_hardcore and self.ck_hardcore:GetCheck() and true or nil)
	axr_main.config:w_value("character_creation","new_game_azazel_mode",self.ck_azazel_mode and self.ck_azazel_mode:GetCheck() and true or nil)
	axr_main.config:w_value("character_creation","new_game_survival_mode",self.ck_survival and self.ck_survival:GetCheck() and true or nil)
	axr_main.config:w_value("character_creation","new_game_laststand_mode",self.ck_laststand and self.ck_laststand:GetCheck() and true or nil)
	axr_main.config:w_value("character_creation","new_game_faction",self.selected_faction or nil)
	axr_main.config:w_value("character_creation","new_game_faction_position",self.start_location or nil)
	axr_main.config:w_value("character_creation","new_game_loadout",self.loadout_str or nil)
	
	
	axr_main.config:w_value("character_creation","new_game_easy_mode",self.ck_easy and self.ck_easy:GetCheck() and true or nil)
	axr_main.config:w_value("character_creation","new_game_good_wpn",self.ck_easy and self.ck_good_wpn:GetCheck() and true or nil)
	axr_main.config:w_value("character_creation","new_game_good_loot",self.ck_easy and self.ck_good_loot:GetCheck() and true or nil)
	
	local loadout_code = 0
	for index = 0, self.list_loadout_1:GetSize()-1 do
		local item = self.list_loadout_1:GetItemByIndex(index)
		loadout_code = bit_or(loadout_code,math.pow(2,item.idx))		
	end
	axr_main.config:w_value("character_creation","new_game_loadout_code",loadout_code)

	-- Store info in temp config so it can be read on next game load
	axr_main.config:w_value("character_creation","new_game_character_name", character_name:gsub(" ","_") )
	axr_main.config:save()
	
	-- Start the game
	self.owner:StartGame()
end

class "set_list_text" (CUIListBoxItem)
function set_list_text:__init(idx, points) super(idx, points)
	self.idx					= idx
	self.points					= points
	self.string 				= "loadout_"..idx
	self.text					= self:GetTextItem()
	self.text:SetWndRect		(Frect():set(0,0,300,22))
	self:SetTextColor			(GetARGB(255, 130, 128, 120))
	self.text:SetFont			(GetFontLetterica16Russian())
	self.text:SetWndSize		(vector2():set(400,22))
	self.text:SetEllipsis		(true)
	self.text:SetText			(game.translate_string("st_loadout_"..idx))
end