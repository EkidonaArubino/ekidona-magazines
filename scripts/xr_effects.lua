
function drx_sl_meet_random_honcho( actor, npc, p )

	-- List of honchos and their surrounding factions:
	local drx_sl_honchos_table = {

		-- Loner honchos:
		{"esc_m_trader", "stalker"},  -- Cordon - Sidorovich (Loner Trader)
		{"esc_smart_terrain_5_7_loner_mechanic_stalker", "stalker"},  -- Cordon - Xenotech (Loner Mechanic)
		{"zat_a2_stalker_barmen", "stalker"},  -- Zaton - Beard (Loner Trader)
		{"zat_b18_noah", "stalker"},  -- Zaton - Noah (Loner Honcho)

		-- Duty honchos:
		{"bar_dolg_general_petrenko_stalker", "dolg"},  -- Rostok - Petrenko (Duty Trader)
		{"bar_visitors_stalker_mechanic", "dolg"},  -- Rostok - Mangun (Duty Mechanic)

		-- Freedom honchos:
		{"mil_smart_terrain_7_7_freedom_leader_stalker", "freedom"},  -- Military Warehouses - Lukash (Freedom Honcho)
		{"jup_a6_freedom_leader", "freedom", "stalker"},  -- Jupiter - Loki (Freedom Honcho)

		-- Clear Sky honchos:
		{"mar_smart_terrain_base_stalker_leader_marsh", "csky"},  -- Great Swamp - Cold (Clear Sky Honcho)
		{"mar_base_stalker_barmen", "csky"},  -- Great Swamp - Librarian (Clear Sky Trader)

		-- Mercenary honchos:
		{"cit_killers_merc_trader_stalker", "killer"},  -- Dead City - Dushman (Mercenary Trader)
		{"cit_killers_merc_mechanic_stalker", "killer"},  -- Dead City - Hog (Mercenary Mechanic)

		-- Military honchos:
		{"agr_smart_terrain_1_6_near_2_military_colonel_kovalski", "army"},  -- Agoroprom - Kuznetsov (Military Honcho)
		{"agr_smart_terrain_1_6_army_mechanic_stalker", "army"},  -- Agoroprom - Kirilov (Military Mechanic)

		-- Bandit honchos:
		{"zat_b7_bandit_boss_sultan", "bandit"},  -- Dark Valley - Sultan (Bandit Honcho)
		{"val_smart_terrain_7_4_bandit_trader_stalker", "bandit"},  -- Dark Valley - Olivius (Bandit Trader)

		-- Monolith honchos:
		{"pri_monolith_monolith_trader_stalker", "monolith"},  -- Pripyat - Rabbit (Monolith Trader)
		{"pri_monolith_monolith_mechanic_stalker", "monolith"},  -- Pripyat - Cleric (Monolith Mechanic)

	}

	-- Create list of valid honchos:
	local honcho_list = {}

	-- Examine each honcho:
	for i = 1, #drx_sl_honchos_table do

		-- Get the current honcho id:
		local honcho = drx_sl_honchos_table[i][1]

		-- Check if honcho is alive and is not current task giver:
		if ( ((xr_conditions.is_alive( nil, nil, {honcho} )) or (honcho == "esc_m_trader")) and (honcho ~= alun_utils.load_var( db.actor, "drx_sl_current_honcho", "" )) ) then

			-- Check if the honcho surrounding factions are not enemy of player:
			local is_enemy = false
			for j = 2, #drx_sl_honchos_table[i] do
				if ( relation_registry.community_relation( drx_sl_honchos_table[i][j], alife( ):actor( ):community( ) ) <= -1000 ) then
					is_enemy = true
				end
			end

			-- Add the current honcho to the list of valid honchos:
			if ( is_enemy == false ) then
				table.insert( honcho_list, honcho )
			end

		end

	end

	-- Pick next honcho:
	local next_honcho = alun_utils.load_var( db.actor, "drx_sl_current_honcho", "" )
	if ( #honcho_list > 0 ) then
		next_honcho = honcho_list[math.random( #honcho_list )]
	end
	alun_utils.save_var( db.actor, "drx_sl_current_honcho", next_honcho )

	-- Increment current task number:
	alun_utils.save_var( db.actor, "drx_sl_current_task_number", (alun_utils.load_var( db.actor, "drx_sl_current_task_number", 1 ) + 1) )
	printf( ("DRX SL task count: " .. alun_utils.load_var( db.actor, "drx_sl_current_task_number", 1 )) )

	-- Build list of available meet current honcho tasks:
	task_ltx_file = ini_file("misc\\task_manager.ltx")
	local honcho_task_list = {}
	local honcho_task_id = ""
	local i = 1
	while ( true ) do
		honcho_task_id = ("drx_sl_" .. next_honcho .. "_meet_task_" .. i)
		if ( task_ltx_file:section_exist( honcho_task_id ) ) then
			table.insert( honcho_task_list, honcho_task_id )
			i = (i + 1)
		else
			break
		end
	end

	-- Give player meet next honcho task:
	if ( #honcho_task_list > 0 ) then
		honcho_task_id = honcho_task_list[math.random( #honcho_task_list )]
		alun_utils.save_var( db.actor, "drx_sl_current_task", honcho_task_id )
		printf( ("DRX SL current storyline task: " .. honcho_task_id) )
		give_info( ("drx_sl_meet_honcho_" .. next_honcho) )  -- (\configs\gameplay\info_portions.xml)
		task_manager.get_task_manager( ):give_task( honcho_task_id )
	else
		printf( ("DRX SL no meet honcho tasks available for " .. next_honcho .. " !!") )
		return
	end

end

function drx_sl_change_factions( actor, npc, p )
	if ( p and p[1] ~= nil and p[1] ~= ("actor_" .. character_community( db.actor )) ) then
		db.actor:set_character_community( ("actor_" .. p[1]), 0, 0 )

-- 		game_relations.set_community_goodwill_for_faction( ("actor_" .. p[1]) )
		local communities = alun_utils.get_communities_list( )
		for i, community in pairs( communities ) do
			relation_registry.set_community_goodwill( community, db.actor:id( ), 0 )
		end
		
		for id, squad in pairs( axr_companions.companion_squads ) do
			if ( squad and squad.commander_id ) then
				for k in squad:squad_members( ) do
					local member = db.storage[k.id] and db.storage[k.id].object
					if ( member and member:alive( ) ) then
						member:set_character_community( p[1], 0, 0 )
						for i, community in pairs( communities ) do
							member:set_community_goodwill( community, 0 )
						end
						printf( ("DRX SL: Companion faction changed to " .. p[1]) )
					end
				end
			end
		end

		printf( ("DRX SL: Actor faction changed to " .. p[1]) )
		--news_manager.send_tip( db.actor, ("You have joined the " .. game.translate_string( p[1] ) .. " faction."), nil, "completionist", nil, nil )
	end
end


function drx_sl_money_task_payment( actor, npc, p )

	if ( p and p[1] ~= nil ) then
		local money =  tonumber( alun_utils.load_var( db.actor, p[1], 0 ) )
		db.actor:give_money( -(money) )
-- 		game_stats.money_quest_update( -(money) )
		news_manager.relocate_money( db.actor, "out", money )
	end

end

function drx_sl_find_wish_granter( actor, npc, p )

	local wish_granter_task = "drx_sl_find_wish_granter_task"
	alun_utils.save_var( db.actor, "drx_sl_current_task", wish_granter_task )
	printf( ("DRX SL current storyline task: " .. wish_granter_task) )
	give_info( "drx_sl_on_find_wish_granter" )  -- (\configs\gameplay\info_portions.xml)
	task_manager.get_task_manager( ):give_task( wish_granter_task )

end

function drx_sl_setup_assault_local( actor, npc, p )

	-- Ensure a task id was supplied:
	if not ( p[1] ) then
		return
	end

	-- List of all factions:
	local factions_list = {
		"stalker",
		"dolg",
		"freedom",
		"csky",
		"ecolog",
		"killer",
		"army",
		"bandit",
		"monolith"
	}

	-- Build list of mutual enemy factions:
	local enemy_faction_list = {}
	for i = 1, #factions_list do
		if ( game_relations.is_factions_enemies( factions_list[i], p[2] ) ) then
			table.insert( enemy_faction_list, factions_list[i] )
		end
	end

	-- Ensure an enemy faction was found:
	if ( #enemy_faction_list < 1 ) then
		printf( "DRX SL Error: drx_sl_setup_assault_local failed, no enemy factions found !!!" )
		return
	end

	-- Search each smart on current level to see if controlled by target factions:
	local target_list = {}
	for name,smart in pairs( SIMBOARD.smarts_by_names ) do
		if ( smart ) and (simulation_objects.is_on_the_linked_level(alife():actor(),smart) or simulation_objects.is_on_the_same_level(alife():actor(),smart)) then
			local smrt = SIMBOARD.smarts[smart.id]
			if (smrt) then
				for k, squad in pairs( smrt.squads ) do
					if ( squad and simulation_objects.is_on_the_same_level( squad, smart ) and squad.current_target_id and squad.current_target_id == smart.id and squad.current_action == 1 and not squad:get_script_target()) then
						for h = 1, #enemy_faction_list do
							-- If a valid target was located then add it to the target list:
							if ( squad.player_id == enemy_faction_list[h] ) then
								table.insert( target_list, smart.id )
								--printf(smart:name())
								--alun_utils.save_var( db.actor, p[1], smart.id)
								--return
							end
						end
					end
				end
			end
		end
	end

	-- Ensure a valid target was found:
	if ( #target_list < 1 ) then
		printf( "DRX SL: drx_sl_setup_assault_local failed, no valid targets located !!!" )
		return
	end

	-- Save the current task target:
	local target = target_list[math.random( #target_list )]
	alun_utils.save_var( db.actor, p[1], target)

end

function drx_sl_setup_assault_mutant( actor, npc, p )

	-- Ensure a task id was supplied:
	if not ( p[1] ) then
		return
	end

	-- Search each smart on current level to see if controlled by mutants:
	local target_id
	local target_list = {}
	
	local actor_rank = db.actor:character_rank()
	
	for name,smart in pairs( SIMBOARD.smarts_by_names ) do
		if ( (smart.online) and (smart.sim_avail == nil or xr_logic.pick_section_from_condlist( actor, smart, smart.sim_avail ) == "true") ) then
			local smrt = SIMBOARD.smarts[smart.id]
			if ( smrt ) and (simulation_objects.is_on_the_linked_level(alife():actor(),smart) or simulation_objects.is_on_the_same_level(alife():actor(),smart)) then
				for k,squad in pairs( smrt.squads ) do
					if ( squad and squad.current_target_id and squad.current_target_id == smart.id and not squad:get_script_target( ) ) then

						-- If a valid target was located then add it to the target list:
						
						if ( is_squad_monster[squad.player_id] ) and not (string.find(squad:name(),"simulation_tushkano") or string.find(squad:name(),"simulation_rat")) then
							squad.stay_time = game.get_game_time()
							alun_utils.save_var( db.actor, p[1], smart.id )
							return
							--table.insert( target_list, smart.id )
						end
					end
				end
			end
		end
	end

	
	-- Ensure a valid target was found:
	--if ( #target_list < 1 ) then
		printf( "DRX SL: drx_sl_setup_assault_mutant failed, no valid targets located !!!" )
		return
	--end

	-- Save the current task target:
	--alun_utils.save_var( db.actor, p[1], target_list[math.random( #target_list )] )

end

function drx_sl_setup_assault_zombied( actor, npc, p )

	-- Ensure a task id was supplied:
	if not ( p[1] ) then
		return
	end

	-- Search each smart on current level to see if controlled by mutants:
	local target_id
	local target_list = {}
	for name,smart in pairs( SIMBOARD.smarts_by_names ) do
		if ( (smart.online) and (smart.sim_avail == nil or xr_logic.pick_section_from_condlist( actor, smart, smart.sim_avail ) == "true") ) then
			local smrt = SIMBOARD.smarts[smart.id]
			if ( smrt ) then
				for k,squad in pairs( smrt.squads ) do
					if ( squad and squad.current_target_id and squad.current_target_id == smart.id and not squad:get_script_target( ) ) then
						-- If a valid target was located then add it to the target list:
						if (squad.player_id == "zombied") and not is_squad_monster[squad.player_id] then
						
							printf(squad:name())

						
							table.insert( target_list, smart.id )
						end
					end
				end
			end
		end
	end

	-- Ensure a valid target was found:
	if ( #target_list < 1 ) then
		printf( "DRX SL: drx_sl_setup_assault_mutant failed, no valid targets located !!!" )
		return
	end

	-- Save the current task target:
	alun_utils.save_var( db.actor, p[1], target_list[math.random( #target_list )] )

end

function drx_sl_quest_stash_bonus( actor, npc, p )

	-- List of reward items:
	local reward_items = {
		"ammo_11.43x23_fmj",		-- [29]    600
		"ammo_5.45x39_fmj",		-- [31]    650
		"ammo_5.56x45_ss190",	-- [34]    700
		"ammo_9x39_ap",				-- [35]    700
		"ammo_11.43x23_hydro",	-- [39]   1000
		"ammo_5.45x39_ap",			-- [42]   1100
		"ammo_5.56x45_ap",			-- [43]   1150
		"ammo_pkm_100",			-- [50]   2000
	}

	-- Pick random bonus item:
	return reward_items[math.random( 1, #reward_items )]

end

function drx_sl_create_quest_stash_1( actor, npc, p )

	-- Create the stash:
	local stash_id = coc_treasure_manager.drx_create_random_stash()
	if ( not stash_id ) then
		printf( "DRX SL error: Unable to create quest stash 1 !!" )
		return
	end
	
	local se_box = alife():object( stash_id )
	local se_obj = alife():create( "drx_sl_quest_item_1", se_box.position, 0, 0, stash_id )
	
	if (not se_obj) then
		printf( "DRX SL error: Unable to create quest item 1 !!" )
		return
	end

	-- Save the stash id:
	alun_utils.save_var( db.actor, "drx_sl_quest_stash_1_id", stash_id )
	alun_utils.save_var( db.actor, "drx_sl_quest_item_1_id", se_obj.id )

	printf( "DRX SL: quest item 1 created %s:%s",stash_id, se_obj.id )
	
end

function drx_sl_create_quest_stash_2( actor, npc, p )

	-- Create the stash:
	local stash_id = coc_treasure_manager.drx_create_random_stash()
	if ( not stash_id ) then
		printf( "DRX SL error: Unable to create quest stash 2 !!" )
		return
	end
	
	local se_box = alife():object( stash_id )
	local se_obj = alife():create( "drx_sl_quest_item_2", se_box.position, 0, 0, stash_id )
	
	if (not se_obj) then
		printf( "DRX SL error: Unable to create quest item 2 !!" )
		return
	end

	-- Save the stash id:
	alun_utils.save_var( db.actor, "drx_sl_quest_stash_2_id", stash_id )
	alun_utils.save_var( db.actor, "drx_sl_quest_item_2_id", se_obj.id )

	printf( "DRX SL: quest item 2 created %s:%s",stash_id, se_obj.id )
	
end

function drx_sl_create_quest_stash_3( actor, npc, p )

	-- Create the stash:
	local stash_id = coc_treasure_manager.drx_create_random_stash()
	if ( not stash_id ) then
		printf( "DRX SL error: Unable to create quest stash 3 !!" )
		return
	end
	
	local se_box = alife():object( stash_id )
	local se_obj = alife():create( "drx_sl_quest_item_3", se_box.position, 0, 0, stash_id )
	
	if (not se_obj) then
		printf( "DRX SL error: Unable to create quest item 3 !!" )
		return
	end

	-- Save the stash id:
	alun_utils.save_var( db.actor, "drx_sl_quest_stash_3_id", stash_id )
	alun_utils.save_var( db.actor, "drx_sl_quest_item_3_id", se_obj.id )

	printf( "DRX SL: quest item 3 created %s:%s",stash_id, se_obj.id )
	
end

function drx_sl_destroy_quest_stash(actor, npc, p)

	if not p[1] then
		printf( "DRX SL error: Unable to destroy quest stash!!" )
		return
	end

	local se_id = alun_utils.load_var(db.actor, p[1])
	
	local se_item = alife():object(se_id)
	
	if not se_item then 
		printf( "DRX SL error: Unable to load %s !!",p[1])
		return
	end
	
	
	alife():release(se_item,true)
	
	
	printf( "DRX SL: quest item released %s:%s",p[1], se_id)

end




function drx_sl_setup_bounty_hunt( actor, npc, p )

	-- List of all factions:
	local factions_list = {
		"stalker",
		"dolg",
		"freedom",
		"csky",
		"ecolog",
		"killer",
		"army",
		"bandit",
		"monolith"
	}

	-- Reset bounty id storage:
	axr_task_manager.bounties_by_id[p[1]] = nil

	-- Build list of mutual enemy factions:
	local enemy_faction_list = {}
	for i = 1, #factions_list do
		if ( (game_relations.is_factions_enemies( factions_list[i], p[2] )) and (relation_registry.community_relation( factions_list[i], alife( ):actor( ):community( ) ) <= -1000) ) then
			table.insert( enemy_faction_list, factions_list[i] )
		end
	end

	-- If no mutual enemies found then build list of NPC enemies:
	if ( #enemy_faction_list < 1 ) then
		for j = 1, #factions_list do
			if ( game_relations.is_factions_enemies( factions_list[j], p[2] ) ) then
				table.insert( enemy_faction_list, factions_list[j] )
			end
		end
	end

	-- If no NPC enemies found then build list of actor enemies:
	if ( #enemy_faction_list < 1 ) then
		for m = 1, #factions_list do
			if ( relation_registry.community_relation( factions_list[m], alife( ):actor( ):community( ) ) <= -1000 ) then
				table.insert( enemy_faction_list, factions_list[m] )
			end
		end
	end

	-- Ensure an enemy faction was found:
	if ( #enemy_faction_list < 1 ) then
		printf( "DRX SL Error: drx_sl_setup_bounty_hunt failed, no enemy factions found !!!" )
		return
	end

	-- Analyze all NPCs for valid target:
	local sfind = string.find
	local se_obj
	local sim = alife( )
	local valid_targets = {}
	for k = 1, 65534 do

		-- Analyze current sim stalker:
		se_obj = sim:object( k )
		if ( (se_obj and IsStalker( nil, se_obj:clsid( ) ) and se_obj:alive( ) and sfind( se_obj:section_name( ), "sim_default" ) and get_object_story_id( k ) == nil) and (se_obj.group_id == nil or se_obj.group_id == 65535 or get_object_story_id( se_obj.group_id ) == nil) ) then

			-- If sim stalker is enemy faction then add to list of valid targets:
			local current_sim_faction = alife_character_community( se_obj )
			for l = 1, #enemy_faction_list do
				if ( current_sim_faction == enemy_faction_list[l] ) then
					table.insert( valid_targets, k )
					break
				end
			end

		end

	end

	-- Ensure a valid target was found:
	if ( #valid_targets < 1 ) then
		printf( "DRX SL Error: drx_sl_setup_bounty_hunt failed, no targets !!!" )
		return
	end

	-- Pick random target from list:
	local target_id = valid_targets[math.random( #valid_targets )]
	if not( target_id ) then
		printf( "DRX SL Error: drx_sl_setup_bounty_hunt failed, target ID invalid !!!" )
		return
	end

	-- Add current target to bounty id storage:
	axr_task_manager.bounties_by_id[p[1]] = target_id
	printf( "drx_sl_setup_bounty_hunt target: %s", target_id )

end

function drx_sl_reward( actor, npc, p )

	-- Select reward item:
	local reward_item = p[math.random( 2, #p )]

	-- Give actor item reward:
	dialogs.relocate_item_section( db.actor, reward_item, "in", tonumber( p[1] ) )

end

function drx_sl_fetch_reward_money( actor, npc, p )

	-- Get fetch items:
	local sec = alun_utils.load_var( db.actor, p[1] )
	if not ( sec ) then
		return
	end
	local item = db.actor:object( sec )
	if not ( item ) then
		return
	end

	-- Get fetch item count:
	local count = alun_utils.load_var( db.actor, (p[1] .. "_count") )
	if not ( count ) then
		count = 1
	end

	-- Determine reward limits:
	local reward_base = math.floor( (item:cost( ) * (tonumber( p[2] ) or 1)) )
	local reward_delta = math.floor( (reward_base * 0.1) )
	
	local cond = 1
	if (item:condition()) then
		cond = item:condition()
	end
	
	local k = cond*cond

	-- Give actor money reward:
	degradation_get_reward( actor, npc, {((reward_base - reward_delta) * count * k), ((reward_base + reward_delta) * count * k)} )

	-- Remove fetch task items:
	remove_item( actor, npc, {sec, count} )

end

function drx_sl_setup_sim_hostage_task( actor, npc, p )

	local id = p[3] and p[3] ~= "nil" and alun_utils.load_var( db.actor,p[3] )
	local smart = id and alife( ):object( id ) or p[2] and p[2] ~= "nil" and SIMBOARD.smarts_by_names[p[2]]
	if not ( smart ) then
		return
	end

	if not ( system_ini( ):section_exist( p[1] ) ) then
		printf( "DRX SL Error - drx_sl_setup_hostage_task failed: Trying to setup companion squad with a non-existent section !!" )
		return
	end

	local sim = alife( )
	local squad = sim:create( p[1], smart.position, smart.m_level_vertex_id, smart.m_game_vertex_id )
	squad:create_npc( smart )
	squad:set_squad_relation( )

	for k in squad:squad_members( ) do
		local se_obj = k.object or k.id and sim:object( k.id )
		if ( se_obj ) then
			SIMBOARD:setup_squad_and_group( se_obj )
			utils.se_obj_save_var( se_obj.id,se_obj:name( ), "companion", true )
			utils.se_obj_save_var( se_obj.id,se_obj:name( ), "companion_cannot_dismiss", true )
			utils.se_obj_save_var( se_obj.id,se_obj:name( ), "companion_cannot_teleport", p[4] == "true" )
			xrs_kill_wounded.hostage_list[se_obj.id] = smart.id
		end
	end

	alun_utils.save_var( db.actor, "drx_sl_hostage_giver_needed", true )

end

function drx_sl_setup_fetch_mutant_meat( actor, npc, p )

	-- List of possible fetch items:
	local item_list = {
		"mutant_part_boar_chop",
		"mutant_part_dog_meat",
		"mutant_part_flesh_meat",
		"mutant_part_psevdodog_meat",
		"mutant_part_tushkano_meat",
		"mutant_part_dog_liver",
		"mutant_part_dog_heart",
	}

	-- Pick a random item from the list:
	local fetch_item = item_list[math.random( #item_list )]
	local min_count = (p[2] and tonumber( p[2] ) or 1)
	local max_count = (p[3] and tonumber( p[3] ) or min_count)

	-- Save chosen fetch item:
	dialogs._FETCH_TEXT = game.translate_string( system_ini( ):r_string_ex( fetch_item, "inv_name" ) or "" )
	alun_utils.save_var( db.actor, p[1], fetch_item )
	alun_utils.save_var( db.actor, (p[1] .. "_count"), math.random( min_count, max_count ) )

end

function drx_sl_setup_fetch_mutant_parts( actor, npc, p )
	local part = DIALOG_LAST_ID and DIALOG_LAST_ID == inventory_upgrades.victim_id and utils.load_var(db.actor,p[1])
	DIALOG_LAST_ID = inventory_upgrades.victim_id
	if (part and system_ini():section_exist(part)) then
		dialogs._FETCH_TEXT = game.translate_string(system_ini():r_string_ex(part,"inv_name") or "")
	else
		local parts = {
		"mutant_part_controller_glass",
		"mutant_part_controller_hand",
		"mutant_part_burer_hand",
		"mutant_part_pseudogigant_eye",
		"mutant_part_pseudogigant_hand",
		"mutant_part_chimera_claw",
		"mutant_part_chimera_kogot"
		}
		part = parts[math.random(#parts)]
		utils.save_var(db.actor,p[1],part)
		dialogs._FETCH_TEXT = game.translate_string(system_ini():r_string_ex(part,"inv_name") or "")
	end
end

function drx_sl_setup_fetch_artefact( actor, npc, p )
	local artefact = DIALOG_LAST_ID and DIALOG_LAST_ID == inventory_upgrades.victim_id and utils.load_var(db.actor,p[1])
	DIALOG_LAST_ID = inventory_upgrades.victim_id
	if (artefact and system_ini():section_exist(artefact)) then
		dialogs._FETCH_TEXT = game.translate_string(system_ini():r_string_ex(artefact,"inv_name") or "")
	else
	
		local arts = {}
	
		if db.actor and db.actor:character_rank() < 1500 then
			arts = {
				"af_medusa",
				"af_vyvert",
				"af_gravi",
				"af_slime",
				"af_slug",
				"af_blood",
				"af_mincer_meat",
				"af_thorn",
				"af_crystal_thorn",
				"af_electra_sparkler",
				"af_electra_flash",
				"af_drop",
				"af_cristall",
			}
		else
			arts = {
				"af_cristall",
				"af_fireball",
				"af_dummy_glassbeads",
				"af_eye",
				"af_fire",
				"af_medusa",
				"af_cristall_flower",
				"af_night_star",
				"af_vyvert",
				"af_gravi",
				"af_gold_fish",
				"af_blood",
				"af_mincer_meat",
				"af_soul",
				"af_fuzz_kolobok",
				"af_baloon",
				"af_electra_sparkler",
				"af_electra_flash",
				"af_electra_moonlight",
				"af_dummy_battery",
				"af_dummy_dummy",
				"af_ice"
			}
		end

		artefact = arts[math.random(#arts)]
		utils.save_var(db.actor,p[1],artefact)
		dialogs._FETCH_TEXT = game.translate_string(system_ini():r_string_ex(artefact,"inv_name") or "")
	end
end

function drx_sl_setup_fetch_weapon( actor, npc, p )
	local wpn = DIALOG_LAST_ID and DIALOG_LAST_ID == inventory_upgrades.victim_id and utils.load_var(db.actor,p[1])
	DIALOG_LAST_ID = inventory_upgrades.victim_id
	if (wpn and system_ini():section_exist(wpn)) then
		dialogs._FETCH_TEXT = game.translate_string(system_ini():r_string_ex(wpn,"inv_name") or "")
	else
		local itm = {
			"wpn_tt33",
			"wpn_pm",
			"wpn_fort",
			"wpn_pb",
			"wpn_mp133",
			"wpn_ak74",
			"wpn_ak74u",
			"wpn_ppsh41",
			"wpn_mp5",
			"wpn_mosin",
			"wpn_mosin_short",
			"wpn_toz34",
			"wpn_toz34_obrez",
			"wpn_bm16",
			"wpn_bm16_full",
		}
		wpn = itm[math.random(#itm)]
		dialogs._FETCH_TEXT = game.translate_string(system_ini():r_string_ex(wpn,"inv_name") or "")
		utils.save_var(db.actor,p[1],wpn)
	end
end

function drx_sl_setup_fetch_supplies( actor, npc, p )
	local itm = DIALOG_LAST_ID and DIALOG_LAST_ID == inventory_upgrades.victim_id and utils.load_var(db.actor,p[1])
	DIALOG_LAST_ID = inventory_upgrades.victim_id
	
	
	
	local faction = p[4] or " "
	
	if (itm and system_ini():section_exist(itm)) then
		dialogs._FETCH_TEXT = game.translate_string(system_ini():r_string_ex(itm,"inv_name") or "")
	else
		local itms = {}
		
		if faction == "stalker" then
			itms = {
			    "drug_charcoal_5",
			    "bandage",
			    "vodka_3",
			    "flask_3",
			    "cooking",
			    "matches",
			    "beadspread",
			    "grenade_rgd5",
			    "grenade_f1",
			    "bread",
			    "meat_flesh",
			    "meat_boar",
			    "energy_drink",
			    "bottle_metal_3",
			    "tea_3",
			    "itm_qr",
			    "itm_backpack",
			    "charcoal_3",
			    "explo_jerrycan_fuel_8",
			    "spareparts",
			    "rope",
			    "synthrope",
			    "glue_b_2",
			    "device_flashlight",
			    "sharpening_stones_4",
			    "maps_kit"
				}
		elseif faction == "bandit" then
			itms = {
			    "grenade_f1",
			    "grenade_rgd5",
			    "bandage",
			    "stimpack",
			    "morphine",
			    "meat_dog",
			    "meat_pseudodog",
			    "beer",
			    "vodka_3",
			    "drink_crow",
			    "flask_3",
			    "bottle_metal_3",
			    "joint",
			    "cooking",
			    "charcoal_2",
			    "explo_jerrycan_fuel_8",
			    "beadspread",
			    "af_ironplate",
			    "device_flashlight",
			    "harmonica_a",
			    "spareparts",
			    "cards",
			    "boots",
			    "swiss",
			    "porn",
			    "grease",
			    "steel_wool",
			    "copper_coil",
			    "textolite",
			    "transistors",
			    "capacitors",
			    "colophony",
			    "glue_b_2",
			    "armor_repair_fa_2"
				}
		elseif faction == "csky" then
			itms = {
			    "grenade_rgd5",
			    "bandage",
			    "meat_flesh",
			    "meat_boar",
			    "drink_crow",
			    "flask_3",
			    "itm_qr",
			    "itm_backpack",
			    "cooking",
			    "charcoal_3",
			    "matches",
			    "lead_box",
			    "device_flashlight",
			    "rope",
			    "synthrope",
			    "cutlery",
			    "textile_patch_m",
			    "copper_coil",
			    "glue_b_2",
			    "sharpening_stones_4"
				}
		elseif faction == "dolg" then
			itms = {
			    "wpn_hand_hammer",
			    "bandage",
			    "meat_dog",
			    "meat_pseudodog",
			    "meat_flesh",
			    "meat_boar",
			    "bread",
			    "vodka_3",
			    "drink_crow",
			    "flask_3",
			    "bottle_metal_3",
			    "cooking",
			    "charcoal_3",
			    "matches",
			    "spareparts",
			    "swiss",
			    "rope",
			    "synthrope",
			    "cutlery",
			    "textile_patch_b",
			    "textile_patch_m"
				}
		elseif faction == "freedom" then
			itms = {
			    "beer",
			    "vodka_3",
			    "drink_crow",
			    "bottle_metal_3",
			    "marijuana",
			    "joint",
			    "cigar"
				}
		elseif faction == "killer" then
			itms = {
			    "wpn_sil_9mm",
			    "grenade_rgd5",
			    "grenade_f1",
			    "mine_wire",
			    "bandage",
			    "medkit",
			    "beer",
			    "vodka_3",
			    "energy_drink",
			    "drink_crow",
			    "flask_3",
			    "bottle_metal_3",
			    "marijuana",
			    "joint",
			    "cigar1_3",
			    "cigar2_3",
			    "cigar3_3",
			    "cigarettes_russian_3",
			    "cooking",
			    "charcoal_2",
			    "explo_jerrycan_fuel_8",
			    "matches",
			    "batteries_ccell",
			    "device_flashlight",
			    "device_torch_dummy",
			    "grooming",
			    "spareparts",
			    "swiss",
			    "rope",
			    "synthrope",
			    "textile_patch_b",
			    "textile_patch_m",
			    "copper_coil",
			    "transistors",
			    "capacitors"
				}
		elseif faction == "army" then
			itms = {
			    "beer",
			    "vodka_3",
			    "bottle_metal_3",
			    "cigar1_3",
			    "cigar2_3",
			    "cigar3_3",
			    "cigarettes_russian_3"
				}
		elseif faction == "ecolog" then
			itms = {
			    "af_medusa",
			    "af_vyvert",
			    "af_slime",
			    "af_thorn",
			    "af_electra_sparkler",
			    "af_drop",
			    "mutant_part_boar_leg",
			    "mutant_part_dog_tail",
			    "mutant_part_snork_leg",
			    "mutant_part_tushkano_head",
			    "mutant_part_cat_tail",
			    "mutant_part_dog_liver",
			    "mutant_part_dog_heart",
			    "mutant_part_cat_thyroid",
			    "mutant_part_cat_claw"
				}				
		else
			itms = {
				"bandage",
				"antirad",
				"medkit",
				"medkit_army",
				"medkit_scientic",
	
				"drug_booster",
				"drug_coagulant_5",
				"drug_psy_blockade_5",
				"drug_antidot_2",
				"drug_radioprotector_2",
	
				"bread",
				"kolbasa",
				"conserva",
				"energy_drink"
			}
		end

		itm = itms[math.random(#itms)]
		
		printf("drx_sl_setup_fetch_supplies:"..faction..":"..itm)
		
		dialogs._FETCH_TEXT = game.translate_string(system_ini():r_string_ex(itm,"inv_name") or "")
		utils.save_var(db.actor,p[1],itm)
		utils.save_var(db.actor,p[1].."_count",math.random(p[2] and tonumber(p[2]) or 1,p[3] and tonumber(p[3]) or 1))
	end
end

function drx_sl_reset_stored_task( actor, npc, p )

	-- Get task giver id:
	if ( (#p < 1) or (not p[1]) ) then
		return
	end
	local tm = task_manager.get_task_manager( )
	local task_info = tm.task_info
	local giver_id = task_info[p[1]].task_giver_id

	-- Reset stored task:
	if ( giver_id ) then
		alun_utils.save_var( db.actor, ("drx_sl_npc_stored_task_" .. giver_id), nil )
	end

end

function drx_sl_unregister_task_giver( actor, npc, p )

	-- Validate input parameters:
	if ( (#p < 1) or (not p[1]) ) then
		return
	end

	printf( ("DRX SL task ended: " .. p[1]) )

	-- Get task giver id:
	local tm = task_manager.get_task_manager( )
	local task_info = tm.task_info
	local giver_id = task_info[p[1]].task_giver_id

	-- Unregister task giver:
	if ( giver_id and not string.find( "meet_task", p[1] ) ) then
		local giver_task_count = (alun_utils.load_var( db.actor, ("drx_sl_task_giver_" .. giver_id), 0 ) - 1)
		if ( giver_task_count < 0 ) then
			giver_task_count = 0
		end
		alun_utils.save_var( db.actor, ("drx_sl_task_giver_" .. giver_id), giver_task_count )
		printf( ("DRX SL: drx_sl_task_giver_" .. giver_id .. " unregistered (" .. giver_task_count .. " outstanding)") )
	end

end

function drx_sl_unregister_hostage_giver( actor, npc, p )

	-- Validate input parameters:
	if ( (#p < 1) or (not p[1]) ) then
		return
	end

	-- Get task giver id:
	local tm = task_manager.get_task_manager( )
	local task_info = tm.task_info
	local giver_id = task_info[p[1]].task_giver_id

	-- Unregister task giver:
	if ( giver_id ) then
		alun_utils.save_var( db.actor, ("drx_sl_hostage_giver_" .. giver_id), false )
		printf( ("DRX SL: drx_sl_hostage_giver_" .. giver_id .. " unregistered") )
	end

end

function drx_sl_decrease_sl_tasks_count( actor, npc, p )

	-- Get the current task count:
	local task_count = alun_utils.load_var( db.actor, "drx_sl_current_task_number", 1 )

	-- Decrement the current task count:
	task_count = (task_count - 1)
	if ( task_count < 1 ) then
		task_count = 1
	end

	-- Save the current task count:
	alun_utils.save_var( db.actor, "drx_sl_current_task_number", task_count )
	printf( "DRX SL: player failed last storyline task, decrementing drx_sl_current_task_number" )
	printf( ("DRX SL task count: " .. task_count) )

end

local DIALOG_LAST_ID = nil
---------------------------------------------------------------------------------------------------------------
-- Initialize a task to find a faction stayed at a smart anywhere on actor current level. ID of smart is tracked in pstor by a given var name
-- param 1 - var name
-- param 2+ - faction a.k.a. squad behavior/player_id
function find_smart_under_faction_control(actor,npc,p)
	if not (p[1]) then
		return
	end

	local target_id
	for name,smart in pairs(SIMBOARD.smarts_by_names) do
		if (smart.online) and (smart.sim_avail == nil or xr_logic.pick_section_from_condlist(actor, smart, smart.sim_avail) == "true") then
			local smrt = SIMBOARD.smarts[smart.id]
			if (smrt) then
				for k,squad in pairs(smrt.squads) do
					if (squad and squad.stay_time and squad.current_target_id and squad.current_target_id == smart.id and not squad:get_script_target()) then
						for i=2,#p do
							if (p[i] == "monster" and is_squad_monster[squad.player_id] or squad.player_id == p[i]) then
								utils.save_var(db.actor,p[1],smart.id)
								return
							end
						end
					end
				end
			end
		end
	end
end

-- same as above but checks connected levels
function find_smart_under_faction_control_ex(actor,npc,p)
	if not (p[1]) then
		return
	end

	local sim = alife()
	local gg = game_graph()
	local actor_level = sim:level_name(gg:vertex(sim:actor().m_game_vertex_id):level_id())

	local target_id
	for name,smart in pairs(SIMBOARD.smarts_by_names) do
		if (smart.sim_avail == nil or xr_logic.pick_section_from_condlist(actor, smart, smart.sim_avail) == "true") then
			local smrt = SIMBOARD.smarts[smart.id]
			if (smrt) then
				local smart_level = alife():level_name(game_graph():vertex(smart.m_game_vertex_id):level_id())
				if (smart.online or string.find(simulation_objects.quest_config:r_value(actor_level,"target_maps",0,""),smart_level)) then
					for k,squad in pairs(smrt.squads) do
						if (squad and squad.current_target_id and squad.current_target_id == smart.id and not squad:get_script_target()) then
							for i=2,#p do
								if (p[i] == "monster" and is_squad_monster[squad.player_id] or squad.player_id == p[i]) then
									utils.save_var(db.actor,p[1],smart.id)
									return
								end
							end
						end
					end
				end
			end
		end
	end
end

-- same as above but checks all levels
function find_smart_under_faction_control_far(actor,npc,p)
	if not (p[1]) then
		return
	end

	local sim = alife()
	local gg = game_graph()
	local actor_level = sim:level_name(gg:vertex(sim:actor().m_game_vertex_id):level_id())

	local target_id
	for name,smart in pairs(SIMBOARD.smarts_by_names) do
		if (smart.sim_avail == nil or xr_logic.pick_section_from_condlist(actor, smart, smart.sim_avail) == "true") then
			local smrt = SIMBOARD.smarts[smart.id]
			if (smrt) then
				local smart_level = alife():level_name(game_graph():vertex(smart.m_game_vertex_id):level_id())
				if not (string.find(simulation_objects.quest_config:r_value(actor_level,"target_maps",0,""),smart_level)) then
					for k,squad in pairs(smrt.squads) do
						if (squad and squad.current_target_id and squad.current_target_id == smart.id and not squad:get_script_target()) then
							for i=2,#p do
								if (p[i] == "monster" and is_squad_monster[squad.player_id] or squad.player_id == p[i]) then
									utils.save_var(db.actor,p[1],smart.id)
									return
								end
							end
						end
					end
				end
			end
		end
	end
end

-- remove a companion squad by story id
function remove_task_companion(actor,npc,p)
	local squad = p[1] and get_story_squad(p[1])
	if not (squad) then
		return
	end

	squad.scripted_target = nil
	squad.current_action = nil
	axr_companions.companion_squads[squad.id] = nil

	for k in squad:squad_members() do
		local npc = k.id and (db.storage[k.id] and db.storage[k.id].object or level.object_by_id(k.id))
		if (npc) then
			axr_logic.restore_scheme_and_logic(npc)
			npc:disable_info_portion("npcx_is_companion")
			npc:disable_info_portion("npcx_beh_cannot_dismiss")

			utils.se_obj_save_var(k.id,k.object:name(),"companion",nil)
			utils.se_obj_save_var(k.id,k.object:name(),"companion_cannot_dismiss",nil)
			utils.se_obj_save_var(k.id,k.object:name(),"companion_cannot_teleport",nil)
		end
	end
end

function add_task_companion(actor,npc,p)
	local squad = p[1] and get_story_squad(p[1])
	if not (squad) then
		return
	end
	axr_companions.companion_squads[squad.id] = squad
	for k in squad:squad_members() do
		local npc = k.id and (db.storage[k.id] and db.storage[k.id].object)
		if (npc) then
			utils.se_obj_save_var(k.id,k.object:name(),"companion",true)
			utils.se_obj_save_var(k.id,k.object:name(),"companion_cannot_dismiss",true)
			utils.se_obj_save_var(k.id,k.object:name(),"companion_cannot_teleport",nil)
			axr_companions.add_to_actor_squad(npc)
		end
	end
end

function inc_task_stage(actor,npc,p)
	local tsk = p[1] and task_manager.get_task_manager().task_info[p[1]]
	if (tsk and tsk.stage) then
		--printf("inc_task_stage=%s stage=%s",p[1],tsk.stage)
		tsk.stage = tsk.stage + 1
	end
end

function dec_task_stage(actor,npc,p)
	local tsk = p[1] and task_manager.get_task_manager().task_info[p[1]]
	if (tsk and tsk.stage) then
		tsk.stage = tsk.stage - 1
	end
end

function set_smart_faction(actor,npc,p)
	local smart = p and p[1] and SIMBOARD.smarts_by_names[p[1]]
	if not (smart) then
		return false
	end
	smart.faction = p[2]
end

--param 1 task_id
--param 2+ factions that can be targetted; can be list

--[[
function create_squad_member(actor, obj, p)
	local squad_member_sect = p[1]
	local story_id			= p[2]
	local position			= nil
	local level_vertex_id	= nil
	local game_vertex_id	= nil
	if story_id == nil then
		printf("Wrong squad identificator [NIL] in 'create_squad_member' function")
	end
	local board = SIMBOARD
	local squad = get_story_squad(story_id)
	if not (squad) then
		return
	end

	local squad_smart = squad.smart_id and board.smarts[squad.smart_id].smrt
	if not (squad_smart) then
		return
	end

	if p[3] ~= nil then
		local spawn_point
		if p[3] == "simulation_point" then
			spawn_point = system_ini():r_string_ex(squad:section_name(),"spawn_point")
			if spawn_point == "" or spawn_point == nil then
				spawn_point = xr_logic.parse_condlist(obj, "spawn_point", "spawn_point", squad_smart.spawn_point)
			else
				spawn_point = xr_logic.parse_condlist(obj, "spawn_point", "spawn_point", spawn_point)
			end
			spawn_point = xr_logic.pick_section_from_condlist(db.actor, obj, spawn_point)
		else
			spawn_point = p[3]
		end
		position 		= patrol(spawn_point):point(0)
		level_vertex_id = patrol(spawn_point):level_vertex_id(0)
		game_vertex_id 	= patrol(spawn_point):game_vertex_id(0)
	else
		local commander = alife_object(squad:commander_id())
		position		= commander.position
		level_vertex_id = commander.m_level_vertex_id
		game_vertex_id	= commander.m_game_vertex_id
	end
	local new_member_id = squad:add_squad_member(squad_member_sect, position,  level_vertex_id, game_vertex_id)

	local se_obj = new_member_id and alife_object(new_member_id)
	if (se_obj) then
		squad_smart:register_npc(se_obj)
	end

	board:setup_squad_and_group(alife():object(new_member_id))
	--squad_smart:refresh()
	squad:update()
end


--]]

function on_init_monster_hunt(actor, npc, p)
	local valid_targets_near = {}
	local valid_targets = {}
	local sim = alife()
	local board = SIMBOARD

	local boss_class
	local boss_section
	
	if (p[2] == "boar") then
		boss_class = clsid.boar_s
		boss_section = "boar_quest_big"
	elseif (p[2] == "bloodsucker") then
		boss_class = clsid.bloodsucker_s
		boss_section = "bloodsucker_quest_big"
	elseif (p[2] == "giant") then
		boss_class = clsid.gigant_s
		boss_section = "gigant_strong"
	elseif (p[2] == "chimera") then
		boss_class = clsid.chimera_s
		boss_section = "chimera_strong"
	else
		printf("monster_hunt: invalid class")
		return
	end
	
	for i=1,65534 do
		local se_obj = sim:object(i)
		if se_obj and (se_obj:clsid() == boss_class) and (se_obj:alive()) and (get_object_story_id(i) == nil) then
		
			
			table.insert(valid_targets,i)
		
			local level_name = sim:level_name(game_graph():vertex(se_obj.m_game_vertex_id):level_id())
			local linked = (utils.levels_linked(level.name(),level_name)) or (level.name() == level_name)
			if (linked) then
				table.insert(valid_targets_near,i)
			end
		end
	end
	
	local size = #valid_targets
	if (size <= 0) then
		printf("monster_hunt: no target available")
		return
	end

	local se_obj
	if (#valid_targets_near > 0) then
		se_obj = sim:object(valid_targets_near[math.random(#valid_targets_near)])
	else
		se_obj = sim:object(valid_targets[math.random(#valid_targets)])
	end
	
	if not(se_obj) then 
		printf("monster_hunt: target not exists")
		return 
	end
	
	local boss = sim:create(boss_section, se_obj.position,se_obj.m_level_vertex_id,se_obj.m_game_vertex_id)
	if (p[2] ~= "chimera") then
		alife():release(se_obj,true)
	end
	if not(boss) then 
		printf("monster_hunt: creature not created")
		return 
	end
	
	axr_task_manager.bounties_by_id[p[1]] = boss.id
end

function on_init_bounty_hunt(actor,npc,p)
	axr_task_manager.bounties_by_id[p[1]] = nil

	local valid_targets = {}
	local valid_targets_near = {}
	
	local sim = alife()
	local comm
	local sfind = string.find
	
	local actor_rank = db.actor:character_rank()
	local rank1 = 1499
	local rank2 = 4999
	
	local check_linked = true
	if ((actor_rank > rank1) and (math.random(0,1) == 0)) or (actor_rank > rank2) then 
		check_linked = false 
	end
	

	local faction_lookup = {}
	for i=2,#p do
		faction_lookup[p[i]] = true
	end

	for i=1,65534 do
		local se_obj = sim:object(i)
		-- find random sim stalker
		if (se_obj and IsStalker(nil,se_obj:clsid()) and se_obj:alive() and sfind(se_obj:section_name(),"sim_default") and get_object_story_id(i) == nil) and (se_obj.group_id == nil or se_obj.group_id == 65535 or get_object_story_id(se_obj.group_id) == nil) then
			comm = alife_character_community(se_obj)
			local linked = simulation_objects.is_on_the_linked_level(alife():actor(),se_obj)
			if (faction_lookup[comm] == true) then
				table.insert(valid_targets,i)
				if (linked or not check_linked) then
					table.insert(valid_targets_near,i)
				end
			end
		end
	end

	local size = #valid_targets
	if (size <= 0) then
		printf("on_init_bounty_hunt failed, no targets")
		return
	end
	
	local target_id
	if (#valid_targets_near > 0) then
		target_id = valid_targets_near[math.random(#valid_targets_near)]
	else
		target_id = valid_targets[math.random(#valid_targets)]
	end
		
	if not(target_id) then
		printf("no target id")
		return
	end

	axr_task_manager.bounties_by_id[p[1]] = target_id
end

function on_init_bounty_hunt_special(actor,npc,p)
	axr_task_manager.bounties_by_id[p[1]] = nil

	local valid_targets = {}
	local sim = alife()

	if not (p[1] and p[2]) then
		return
	end
	
	local target_id = nil
	
	for i=1,65534 do
		local se_obj = sim:object(i)
		if (se_obj and IsStalker(nil,se_obj:clsid()) and se_obj:alive() and string.find(se_obj:section_name(),p[2])) then
			target_id = i
			break
		end
	end

	if (target_id) then
		axr_task_manager.bounties_by_id[p[1]] = target_id
	end
	
end

function fail_task_dec_goodwill(actor,npc,p)
	local amt = tonumber(p[1]) or 50
	for i=2,#p do
		inc_faction_goodwill_to_actor(db.actor, nil, {p[i], -(amt)})
	end
end

-- param1 - amount of goodwill to increase
-- param2+ - community
function complete_task_inc_goodwill(actor,npc,p)
	local amt = tonumber(p[1]) or 50
	
	if (has_alife_info("perk_authority")) then
		amt = amt + 10
	end
	
	for i=2,#p do
		inc_faction_goodwill_to_actor(db.actor, nil, {p[i], amt})
	end
end


function task_inc_goodwill_task_giver(actor,npc,p)
	
	if not (p[1]) then
		return
	end
	local tm = task_manager.get_task_manager()
	local tsk = tm.task_info[p[1]]
	if not (tsk) then
		return
	end
	local se_obj = tsk.task_giver_id and alife_object(tsk.task_giver_id)
	if (se_obj and se_obj:community()) then

		local amt = tonumber(p[2]) or 20
		inc_faction_goodwill_to_actor(db.actor, nil, {se_obj:community(), amt})
	end
end

function task_dec_goodwill_task_giver(actor,npc,p)
	
	if not (p[1]) then
		return
	end
	local tm = task_manager.get_task_manager()
	local tsk = tm.task_info[p[1]]
	if not (tsk) then
		return
	end
	local se_obj = tsk.task_giver_id and alife_object(tsk.task_giver_id)
	if (se_obj and se_obj:community()) then

		local amt = tonumber(p[2]) or 20
		inc_faction_goodwill_to_actor(db.actor, nil, {se_obj:community(), -(amt)})
	end
end


function add_actor_relation(actor, npc, p)

	if not (p[1] and p[2] and p[3]) then
		return
	end

	local actor_faction = alife():actor():community()
	local prev_relation = relation_registry.community_relation(p[2], actor_faction)
	game_relations.change_actor_relation(p[2], prev_relation+p[3])
	local val = p[2].."-"..actor_faction..":"..prev_relation
	utils.save_var(db.actor,p[1],val)
	
	--printf("SAVE: "..val)
end

function restore_actor_relation(actor, npc, p)

	if not (p[1]) then
		return
	end

	local val = utils.load_var(db.actor,p[1])
	local sav_1 = string.sub(val,1,string.find(val,"-")-1)
	local sav_2 = string.sub(val,string.find(val,"-")+1,string.find(val,":")-1)
	local sav_3 = string.sub(val,string.find(val,":")+1,-1)
	--[[
	printf("LOAD:")
	printf(sav_1)
	printf(sav_2)
	printf(sav_3)
	--]]
	game_relations.change_actor_relation(sav_1, sav_3)
	utils.save_var(db.actor,p[1],nil)
end

function take_money(actor,npc,p)

	if not (p[1]) then
		return
	end
		
	db.actor:give_money(-(p[1]), npc)
	news_manager.relocate_money(db.actor, "out", p[1])
end


function reward_money(actor,npc,p)

	local money = tonumber(p[1] or 500)

	if IsEasyMode() then
		money = money*3
	end

	dialogs.relocate_money(db.actor,money,"in")
end

function reward_stash(actor,npc,p)
	if (p and p[1] ~= "true") or ((math.random(1,100)/100) <= 0.5) then
		local bonus
		if ((math.random(1,100)/100) <= 0.35) then
			local t = {"itm_repairkit_tier_1","itm_repairkit_tier_1","itm_repairkit_tier_1","itm_repairkit_tier_2","itm_repairkit_tier_2","itm_repairkit_tier_3"}
			bonus = {t[math.random(#t)]}
		end
		coc_treasure_manager.create_random_stash(nil,nil,bonus)
	end
end

function reward_item_cost_mult_and_remove(actor,npc,p)
	local sec = utils.load_var(db.actor,p[1])
	if not (sec) then
		return
	end
	local item = db.actor:object(sec)
	if not (item) then
		return
	end 
	
	local cond = 1
	if (item:condition()) then
		cond = item:condition()
	end
	
	local money = (tonumber(p[2]) or 1)*item:cost()*cond*cond*cond
	money = math.ceil(money/500)*500
	
	if IsEasyMode() then
		money = money*3
	end
	
	dialogs.relocate_money(db.actor, money ,"in")
	remove_item(actor, npc, {sec,p[3]})
end

function reward_random_item(actor,npc,p)
	if (#p > 0) then
		local section = p[math.random(#p)]
		if (system_ini():section_exist(section)) then
			dialogs.relocate_item_section(db.actor,section,"in")
		end
	end
end

function reward_random_money(actor,npc,p)

	local money = math.random(tonumber(p[1] or 500),tonumber(p[2] or 1000))
	
	money = math.ceil(money/100)*100
	
	if IsEasyMode() then
		money = money*3
	end
	
	dialogs.relocate_money(db.actor,money,"in")
end

function remove_special_task_squad(actor,npc,p)
	level.add_pp_effector("black.ppe", 1313, false)
	remove_squad(actor,npc,p)
end

function reset_task_target_anomaly(actor,npc,p)
	utils.save_var(db.actor,"task_target_anomaly",nil)
end

-- Spawn a squad that will become actor companion for special tasks
-- param 1 - squad section
-- param 2 - smart
-- param 3 - variable name. Will use smart_id in a pstor variable instead
-- param 4 - disable level transition for the squad
-- param 5 - is a hostage
function setup_companion_task(actor,npc,p)
	local cant_teleport = p[4]
	local is_hostage = p[5]
	
	local id = p[3] and p[3] ~= "nil" and alun_utils.load_var( db.actor,p[3] )
	local smart = id and alife( ):object( id ) or p[2] and p[2] ~= "nil" and SIMBOARD.smarts_by_names[p[2]]
	if not ( smart ) then
		return
	end
	
	if not ( system_ini( ):section_exist( p[1] ) ) then
		printf( "DRX SL Error - drx_sl_setup_hostage_task failed: Trying to setup companion squad with a non-existent section !!" )
		return
	end

	local sim = alife()
	local squad = sim:create(p[1],smart.position,smart.m_level_vertex_id,smart.m_game_vertex_id)

	squad:create_npc(smart)
	squad:set_squad_relation()

	axr_companions.companion_squads[squad.id] = squad
	for k in squad:squad_members() do
		local se_obj = k.object or k.id and sim:object(k.id)
		if (se_obj) then
			utils.se_obj_save_var(se_obj.id,se_obj:name(),"companion",true)
			utils.se_obj_save_var(se_obj.id,se_obj:name(),"companion_cannot_dismiss",true)
			utils.se_obj_save_var(se_obj.id,se_obj:name(),"companion_cannot_teleport",cant_teleport == "true")
			SIMBOARD:setup_squad_and_group(se_obj)
			if (is_hostage == "true") then
				axr_task_manager.hostages_by_id[se_obj.id] = smart.id
			end
		end
	end

	--utils.save_var(db.actor,p[3] or "task_companion_slot_1",squad.id)
	--CreateTimeEvent(0,"add_special_task_squad",5,add_special_task_squad,squad.id,p[4] == "true")
end

-- setup for special escort to anomaly task
function setup_task_target_anomaly(actor,npc,p)
	local targets = {}
	for k,v in pairs(db.anomaly_by_name) do
		table.insert(targets,k)
	end

	if (#targets <= 0) then
		return
	end
	
	local target_name = targets[math.random(#targets)]
	utils.save_var(db.actor,"task_target_anomaly",target_name)
	
	pda.open_anomaly_spot(target_name)
end

-- param1 - variable name
-- param2 - count
-- param3+ - sections
function setup_generic_fetch_task(actor,npc,p)
	if (p[1] and p[2] and p[3]) then
		local sec = utils.load_var(db.actor,p[1])
		if (sec and system_ini():section_exist(sec)) then
			dialogs._FETCH_TEXT = game.translate_string(system_ini():r_string_ex(sec,"inv_name") or "")
		else
			sec = #p > 3 and p[math.random(3,#p)] or p[3]
			if (sec and system_ini():section_exist(sec)) then
				utils.save_var(db.actor,p[1],sec)
				local count = tonumber(p[2]) or 1
				if (count > 1) then
					utils.save_var(db.actor,p[1].."_count",count)
				end
				dialogs._FETCH_TEXT = game.translate_string(system_ini():r_string_ex(sec,"inv_name") or "")
			else
				printf("ERROR: xr_effects:setup_generic_fetch_task - invalid section %s",sec)
			end
		end
	end
end

-- param1 - variable name
function setup_rare_mutant_fetch_task(actor,npc,p)
	local part = DIALOG_LAST_ID and DIALOG_LAST_ID == inventory_upgrades.victim_id and utils.load_var(db.actor,p[1])
	DIALOG_LAST_ID = inventory_upgrades.victim_id
	if (part and system_ini():section_exist(part)) then
		dialogs._FETCH_TEXT = game.translate_string(system_ini():r_string_ex(part,"inv_name") or "")
	else
		local parts = {
		"mutant_part_controller_glass",
		"mutant_part_controller_hand",
		"mutant_part_burer_hand",
		"mutant_part_pseudogigant_eye",
		"mutant_part_pseudogigant_hand",
		"mutant_part_chimera_claw",
		"mutant_part_chimera_kogot"
		}
		part = parts[math.random(#parts)]
		utils.save_var(db.actor,p[1],part)
		dialogs._FETCH_TEXT = game.translate_string(system_ini():r_string_ex(part,"inv_name") or "")
	end
end


function remove_fetch_item(actor,npc,p)
	local section = utils.load_var(db.actor,p[1])
	if (section and db.actor:object(section)) then
		local amt = p[2] or utils.load_var(db.actor,p[1].."_count") or 1
		remove_item(actor, npc, {section,amt})
	end
end

function force_talk(actor,npc,p)
	local allow_break = p[1] and p[1] == "true" or false
	db.actor:run_talk_dialog(npc, allow_break)
end

function unlock_smart(actor,npc,p)
	local id = p[1] and p[1] ~= "nil" and utils.load_var(db.actor,p[1])
	local smart = id and alife_object(id)
	if (smart) then
		smart.locked = nil
	end
end

-- ������������� �������� ������ � ��������, ���������� ����������. ���� �������� ������ � ���
function update_npc_logic(actor, object, p)
	--printf("UPDATE NPC LOGIC %s", device():time_global())
	for k,v in pairs(p) do
		local npc = get_story_object(v)
		if npc ~= nil then
			xr_motivator.update_logic(npc)

			local planner = npc:motivation_action_manager()
			planner:update()
			planner:update()
			planner:update()

			db.storage[npc:id()].state_mgr:update()
			db.storage[npc:id()].state_mgr:update()
			db.storage[npc:id()].state_mgr:update()
			db.storage[npc:id()].state_mgr:update()
			db.storage[npc:id()].state_mgr:update()
			db.storage[npc:id()].state_mgr:update()
			db.storage[npc:id()].state_mgr:update()
		end
	end
end

function update_obj_logic(actor, object, p)
	--printf("UPDATE OBJ LOGIC %s", device():time_global())
	for k,v in pairs(p) do
		local obj = get_story_object(v)
		if obj ~= nil then

			local st = db.storage[obj:id()]
			xr_logic.try_switch_to_another_section(obj, st[st.active_scheme], actor)

--			if st.active_scheme == "sr_cutscene" then
--				st[st.active_scheme].cutscene_action
--			end

		end
	end
end

local ui_active_slot = 0

function disable_ui(actor, npc, p)
	if db.actor:is_talking() then
		db.actor:stop_talk()
	end
	level.show_weapon(false)

	if not p or (p and p[1] ~= "true") then
		local slot = db.actor:active_slot()
		if(slot~=0) then
			ui_active_slot = slot
			db.actor:activate_slot(0)
		end
	end

	level.disable_input()
	--level.hide_indicators_safe()
	local hud = get_hud()
	if (hud) then
		hud:HideActorMenu()
		hud:HidePdaMenu()
	end
	disable_actor_nightvision(nil,nil)
	disable_actor_torch(nil,nil)
end

function disable_ui_only(actor, npc)
	if db.actor:is_talking() then
		db.actor:stop_talk()
	end
	level.show_weapon(false)

	if not p or (p and p[1] ~= "true") then
		local slot = db.actor:active_slot()
		if(slot~=0) then
			ui_active_slot = slot
			db.actor:activate_slot(0)
		end
	end

	level.disable_input()
	--level.hide_indicators_safe()
	local hud = get_hud()
	if (hud) then
		hud:HideActorMenu()
		hud:HidePdaMenu()
	end
	disable_actor_nightvision(nil,nil)
end

function disable_nv(actor, npc)
	if db.actor:is_talking() then
		db.actor:stop_talk()
	end
	level.show_weapon(false)

	if not p or (p and p[1] ~= "true") then
		local slot = db.actor:active_slot()
		if(slot~=0) then
			ui_active_slot = slot
			db.actor:activate_slot(0)
		end
	end

	disable_actor_nightvision(nil,nil)
	disable_actor_torch(nil,nil)
end

function disable_ui_lite_with_imput(actor, npc)
	if db.actor:is_talking() then
		db.actor:stop_talk()
	end
	level.show_weapon(false)

	if not p or (p and p[1] ~= "true") then
		local slot = db.actor:active_slot()
		if(slot~=0) then
			ui_active_slot = slot
			db.actor:activate_slot(0)
		end
	end

	level.disable_input()
	--level.hide_indicators_safe()
end

function disable_ui_lite(actor, npc)
	if db.actor:is_talking() then
		db.actor:stop_talk()
	end
	level.show_weapon(false)

	if not p or (p and p[1] ~= "true") then
		local slot = db.actor:active_slot()
		if(slot~=0) then
			ui_active_slot = slot
			db.actor:activate_slot(0)
		end
	end

	--level.hide_indicators_safe()
end

function disable_ui_inventory(actor, npc)
	if db.actor:is_talking() then
		db.actor:stop_talk()
	end
--	level.show_weapon(false)

	if not p or (p and p[1] ~= "true") then
		local slot = db.actor:active_slot()
		if(slot~=0) then
			ui_active_slot = slot
			db.actor:activate_slot(0)
		end
	end

	local hud = get_hud()
	if (hud) then
		hud:HidePdaMenu()
		hud:HideActorMenu()
	end
end

function enable_ui(actor, npc, p)
	--db.actor:restore_weapon()

	if not p or (p and p[1] ~= "true") then
		if ui_active_slot ~= 0 and db.actor:item_in_slot(ui_active_slot) ~= nil then
			db.actor:activate_slot(ui_active_slot)
		end
	end

	ui_active_slot = 0
	level.enable_input()
	level.show_weapon(true)
	--level.show_indicators()
	enable_actor_nightvision(nil,nil)
	enable_actor_torch(nil,nil)
end

function enable_ui_lite_with_imput(actor, npc, p)
	--db.actor:restore_weapon()

	if not p or (p and p[1] ~= "true") then
		if ui_active_slot ~= 0 and db.actor:item_in_slot(ui_active_slot) ~= nil then
			db.actor:activate_slot(ui_active_slot)
		end
	end

	ui_active_slot = 0
	level.enable_input()
	level.show_weapon(true)
	--level.show_indicators()
	enable_actor_nightvision(nil,nil)
	enable_actor_torch(nil,nil)
end

function enable_ui_lite(actor, npc, p)
	--db.actor:restore_weapon()

	if not p or (p and p[1] ~= "true") then
		if ui_active_slot ~= 0 and db.actor:item_in_slot(ui_active_slot) ~= nil then
			db.actor:activate_slot(ui_active_slot)
		end
	end

	ui_active_slot = 0
	level.enable_input()
	level.show_weapon(true)
	--level.show_indicators()
	enable_actor_nightvision(nil,nil)
	enable_actor_torch(nil,nil)
end

function enable_nv_and_imput(actor, npc, p)
	--db.actor:restore_weapon()

	if not p or (p and p[1] ~= "true") then
		if ui_active_slot ~= 0 and db.actor:item_in_slot(ui_active_slot) ~= nil then
			db.actor:activate_slot(ui_active_slot)
		end
	end

	level.enable_input()
	enable_actor_nightvision(nil,nil)
	enable_actor_torch(nil,nil)
end

function enable_imput(actor, npc, p)
	--db.actor:restore_weapon()

	if not p or (p and p[1] ~= "true") then
		if ui_active_slot ~= 0 and db.actor:item_in_slot(ui_active_slot) ~= nil then
			db.actor:activate_slot(ui_active_slot)
		end
	end

	level.enable_input()
end
function enable_nv(actor, npc, p)
	--db.actor:restore_weapon()

	if not p or (p and p[1] ~= "true") then
		if ui_active_slot ~= 0 and db.actor:item_in_slot(ui_active_slot) ~= nil then
			db.actor:activate_slot(ui_active_slot)
		end
	end
	enable_actor_nightvision(nil,nil)
	enable_actor_torch(nil,nil)
end

local cam_effector_playing_object_id = nil

function run_cam_effector(actor, npc, p)
	if p[1] then
		local loop, num = false, (1000 + math.random(100))
		if p[2] and type(p[2]) == "number" and p[2] > 0 then
			num = p[2]
		end
		if p[3] and p[3] == "true" then
			loop = true
		end
		--level.add_pp_effector(p[1] .. ".ppe", num, loop)
		level.add_cam_effector("camera_effects\\" .. p[1] .. ".anm", num, loop, "xr_effects.cam_effector_callback")
		cam_effector_playing_object_id = npc:id()
	end
end

function stop_cam_effector(actor, npc, p)
	if p[1] and type(p[1]) == "number" and p[1] > 0 then
		level.remove_cam_effector(p[1])
	end
end

function run_cam_effector_global(actor, npc, p)
	local num = 1000 + math.random(100)
	if p[2] and type(p[2]) == "number" and p[2] > 0 then
		 num = p[2]
	end
	local fov = device().fov
	if p[3] ~= nil and type(p[3]) == "number" then
		fov = p[3]
	end
	level.add_cam_effector2("camera_effects\\" .. p[1] .. ".anm", num, false, "xr_effects.cam_effector_callback", fov)
	cam_effector_playing_object_id = npc:id()
end

function cam_effector_callback()
	if cam_effector_playing_object_id == nil then
		printf("cam_eff:callback1!")
		return
	end
	local st   = db.storage[cam_effector_playing_object_id]
	if st == nil or st.active_scheme == nil then
		printf("cam_eff:callback2!")
		return
	end

	if st[st.active_scheme].signals == nil then
		printf("cam_eff:callback3!")
		return
	end
	st[st.active_scheme].signals["cameff_end"] = true
end

function run_postprocess(actor, npc, p)
	if (p[1]) then
		if(system_ini():section_exist(p[1])) then
			local num = 2000 + math.random(100)
			if(p[2] and type(p[2]) == "number" and p[2]>0) then
				num = p[2]
			end
			printf("adding complex effector [%s], id [%s], from [%s]", p[1], tostring(p[2]), tostring(npc:name()))
			level.add_complex_effector(p[1], num)
		else
			printf("Complex effector section is no set! [%s]", tostring(p[1]))
		end
	end
end

function stop_postprocess(actor, npc, p)
	if(p[1] and type(p[1]) == "number" and p[1]>0) then
		printf("removing complex effector id [%s] from [%s]", tostring(p[1]), tostring(npc:name()))
		level.remove_complex_effector(p[1])
	end
end

function run_tutorial(actor, npc, p)
	printf("run tutorial called")
	game.start_tutorial(p[1])
end

--[[
function run_tutorial_if_newbie(actor, npc, p)
	if has_alife_info("esc_trader_newbie") then
		game.start_tutorial(p[1])
	end
end
]]--

function open_anomaly_spot(actor, npc, p)
	if(p[1]) then
		pda.open_anomaly_spot(p[1])
	end
end


function jup_b32_place_scanner(actor, npc)
	for i = 1, 5 do
		if xr_conditions.actor_in_zone(actor, npc, {"jup_b32_sr_scanner_place_"..i})
			and not has_alife_info("jup_b32_scanner_"..i.."_placed") then
			db.actor:give_info_portion("jup_b32_scanner_"..i.."_placed")
			db.actor:give_info_portion("jup_b32_tutorial_done")
			remove_item(actor, npc, {"jup_b32_scanner_device"})
			spawn_object(actor, nil, {"jup_b32_ph_scanner","jup_b32_scanner_place_"..i})
		end
	end
end

function jup_b32_pda_check(actor, npc)

end

function pri_b306_generator_start(actor, npc)
	if xr_conditions.actor_in_zone(actor, npc, {"pri_b306_sr_generator"}) then
		give_info("pri_b306_lift_generator_used")
	end
end

function jup_b206_get_plant(actor, npc)
	if xr_conditions.actor_in_zone(actor, npc, {"jup_b206_sr_quest_line"}) then
		give_info("jup_b206_anomalous_grove_has_plant")
		give_actor(actor, npc, {"jup_b206_plant"})
		destroy_object(actor, npc, {"story", "jup_b206_plant_ph"})
	end
end

function pas_b400_switcher(actor, npc)
	if xr_conditions.actor_in_zone(actor, npc, {"pas_b400_sr_switcher"}) then
		give_info("pas_b400_switcher_use")
	end
end


function jup_b209_place_scanner(actor, npc)
	if xr_conditions.actor_in_zone(actor, npc, {"jup_b209_hypotheses"})	then
		scenario_autosave(db.actor, nil, {"st_save_jup_b209_placed_mutant_scanner"})
		db.actor:give_info_portion("jup_b209_scanner_placed")
		remove_item(actor, npc, {"jup_b209_monster_scanner"})
		spawn_object(actor, nil, {"jup_b209_ph_scanner","jup_b209_scanner_place_point"})
	end
end

function jup_b9_heli_1_searching(actor, npc)
	if xr_conditions.actor_in_zone(actor, npc, {"jup_b9_heli_1"})
		then
		db.actor:give_info_portion("jup_b9_heli_1_searching")
	end
end

function pri_a18_use_idol(actor, npc)
	if xr_conditions.actor_in_zone(actor, npc, {"pri_a18_use_idol_restrictor"})
		then
		db.actor:give_info_portion("pri_a18_run_cam")
	end
end

function jup_b8_heli_4_searching(actor, npc)
	if xr_conditions.actor_in_zone(actor, npc, {"jup_b8_heli_4"})
		then
		db.actor:give_info_portion("jup_b8_heli_4_searching")
	end
end

function jup_b10_ufo_searching(actor, npc)
	if xr_conditions.actor_in_zone(actor, npc, {"jup_b10_ufo_restrictor"})
		then
		db.actor:give_info_portion("jup_b10_ufo_memory_started")
		give_actor(db.actor,nil,{"jup_b10_ufo_memory"})
	end
end


function zat_b101_heli_5_searching(actor, npc)
	if xr_conditions.actor_in_zone(actor, npc, {"zat_b101_heli_5"})
		then
		db.actor:give_info_portion("zat_b101_heli_5_searching")
	end
end

function zat_b28_heli_3_searching(actor, npc)
	if xr_conditions.actor_in_zone(actor, npc, {"zat_b28_heli_3"})
		then
		db.actor:give_info_portion("zat_b28_heli_3_searching")
	end
end

function zat_b100_heli_2_searching(actor, npc)
	if xr_conditions.actor_in_zone(actor, npc, {"zat_b100_heli_2"})	then
		db.actor:give_info_portion("zat_b100_heli_2_searching")
	end
end

function teleport_actor(actor, npc, p)
	local point = patrol(p[1])
	if not (point) then
		printf("xr_effects.teleport_actor no patrol path %s exists!",p[1])
		return
	end

	local dir
	if p[2] ~= nil then
		local look = patrol(p[2])
		dir = -look:point(0):sub(point:point(0)):getH()
		db.actor:set_actor_direction(dir)
	end

	for k,v in pairs(db.no_weap_zones) do
		if utils.npc_in_zone(db.actor, k) then
			db.no_weap_zones[k] = true
		end
	end

	if npc and npc:name() ~= nil then
		printf("teleporting actor from [%s]", tostring(npc:name()))
	end

	db.actor:set_actor_position(point:point(0))
end


local function reset_animation(npc)
	local state_mgr = db.storage[npc:id()].state_mgr
	if state_mgr == nil then
		return
	end
	local planner = npc:motivation_action_manager()

	state_mgr.animation:set_state(nil, true)
	state_mgr.animation:set_control()
	state_mgr.animstate:set_state(nil, true)
	state_mgr.animstate:set_control()

	state_mgr:set_state("idle", nil, nil, nil, {fast_set = true})

--	planner:update()
--	planner:update()
--	planner:update()

	state_mgr:update()
	state_mgr:update()
	state_mgr:update()
	state_mgr:update()
	state_mgr:update()
	state_mgr:update()
	state_mgr:update()

	npc:set_body_state(move.standing)
	npc:set_mental_state(anim.free)

end

function teleport_npc_lvid(actor,npc,p)
	local vid = tonumber(p[1])
	if not (vid) then
		return
	end
	local position = level.vertex_position(vid)
	if (p[2]) then
		local obj = get_story_object(p[2])
		if (obj) then
			obj:set_npc_position(position)
		end
		return
	end
	npc:set_npc_position(position)
end

function teleport_npc_pos(actor,npc,p)
	for i=1,3 do
		p[i] = string.gsub(p[i],"n","-")
	end
	local pos = vector():set(tonumber(p[1]),tonumber(p[2]),tonumber(p[3]))
	if not (pos) then
		return
	end

	if (p[4]) then
		local obj = get_story_object(p[4])
		if (obj) then
			obj:set_npc_position(pos)
		end
		return
	end
	npc:set_npc_position(pos)
end

function teleport_squad_lvid(actor,npc,p)
	local vid = tonumber(p[1])
	if not (vid) then
		return
	end

	local squad = p[2] and get_story_squad(p[2]) or get_object_squad(npc)
	if not (squad) then
		return
	end

	local position = level.vertex_position(vid)
	squad:set_squad_position(position)
end

function teleport_npc(actor, npc, p)
	if not (p[1]) then
		return
	end

	local position = patrol(p[1]):point(tonumber(p[2]) or 0)
	--reset_animation(npc)

	npc:set_npc_position(position)
end

function teleport_npc_by_story_id(actor, npc, p)
	local story_id = p[1]
	local patrol_point = p[2]
	local patrol_point_index = p[3] or 0
	if story_id == nil or patrol_point == nil then
		printf("Wrong parameters in 'teleport_npc_by_story_id' function!!!")
	end
	local position = patrol(tostring(patrol_point)):point(patrol_point_index)
	local npc_id = get_story_object_id(story_id)
	if npc_id == nil then
		printf("There is no story object with id [%s]", story_id)
	end
	local cl_object = level.object_by_id(npc_id)
	if cl_object then
		reset_animation(cl_object)
		cl_object:set_npc_position(position)
	else
		alife_object(npc_id).position = position
	end
end

function teleport_squad(actor, npc, p)
	local squad = p[1] and get_story_squad(p[1])
	if not (squad) then
		printf("There is no squad with story id [%s]", p[1])
	end

	local path = patrol(p[2])
	if not (path) then
		printf("Wrong parameters in 'teleport_squad' function!!!")
		return
	end

	local idx = p[3] or 0
	TeleportSquad(squad,path:point(idx),path:level_vertex_id(idx),path:game_vertex_id(idx))
	--squad:set_squad_position(path:point(idx))
end

function jup_teleport_actor(actor, npc)
	local point_in = patrol("jup_b16_teleport_in"):point(0)
	local point_out = patrol("jup_b16_teleport_out"):point(0)
	local actor_position = actor:position()
	local out_position = vector():set(actor_position.x - point_in.x + point_out.x, actor_position.y - point_in.y + point_out.y , actor_position.z - point_in.z + point_out.z)
	db.actor:set_actor_position(out_position)
end
-----------------------------------------------------------------------------
--[[
local drop_point, drop_object = 0, 0
local function drop_object_item(item)
	drop_object:drop_item_and_teleport(item, drop_point)
end

function drop_actor_inventory(actor, npc, p)
	if p[1] then
		drop_point  = patrol(p[1]):point(0)
		drop_object = actor
		actor:inventory_for_each(drop_object_item)
	end
end


-- FIXME: drop_npc_inventory doesn't work
function drop_npc_inventory(actor, npc, p)
	if p[1] then
		drop_point  = patrol(p[1]):point(0)
		drop_object = npc
		npc:inventory_for_each(drop_object_item)
	end
end

function drop_npc_item(actor, npc, p)
	if p[1] then
		local item = npc:object(p[1])
		if item then
			npc:drop_item(item)
		end
	end
end

function drop_npc_items(actor, npc, p)
	local item = 0
	for i, v in pairs(p) do
		item = npc:object(v)
		if item then
			npc:drop_item(item)
		end
	end
end
]]--

function give_items(actor, npc, p)
	local pos, lv_id, gv_id, npc_id = npc:position(), npc:level_vertex_id(), npc:game_vertex_id(), npc:id()
	for i, v in pairs(p) do
		alife():create(v, pos, lv_id, gv_id, npc_id)
	end
end

function give_item(actor, npc, p)
	if p[2] ~= nil then
		npc_id = get_story_object_id(p[2])
	else
		npc_id = npc:id()
	end
	local se_npc = alife_object(npc_id)
	if not (se_npc) then
		return
	end
	local pos, lv_id, gv_id, npc_id = se_npc.position, se_npc.m_level_vertex_id, se_npc.m_game_vertex_id, se_npc.id
	alife():create(p[1], pos, lv_id, gv_id, npc_id)
end

function give_item_to_npc(actor, npc, p)
	local sec = p[1]
	if not (sec) then
		printf("Wrong parameters in function 'remove_item'!!!")
		return
	end
	
	db.actor:transfer_item(db.actor:object(sec), npc)
	news_manager.relocate_item(db.actor,"out",sec,removed)
end

function play_particle_on_path(actor, npc, p)
	local name = p[1]
	local path = p[2]
	local point_prob = p[3]
	if name == nil or path == nil then
		return
	end
	if point_prob == nil then
		point_prob = 100
	end

	local path = patrol(path)
	local count = path:count()
	for a = 0,count-1,1 do
		local particle = particles_object(name)
		if math.random(100) <= point_prob then
			particle:play_at_pos(path:point(a))
		end
	end
end


-----------------------------------------------------------------------------
--[[
send_tip(news_id:sender:sender_id)
		1. news_id
		2. sender*
		3. sender_id*
		* - not necessary
--]]
function send_tip(actor, npc, p)
	news_manager.send_tip(actor, p[1], nil, p[2], nil, p[3])
end

function send_tip_task(actor,npc,p)
	local tsk = p[1] and task_manager.get_task_manager().task_info[p[1]]
	if (tsk and p[2]) then
		news_manager.send_task(actor, p[2], tsk)
	end
end
--[[
���� �������� ��������� �����. �������� ���� ������� ��� � ����������.
���������: actor, npc, p[direction,bone,power,impulse,reverse=false]
		1. direction - ���� ������, �� ���������, ��� ��� ��� ���� � � �������
				������ ����� ������������ ������. ���� �� ��� �����, �� ���
				��������������� ��� story_id ��������� �� �������� ������ ��������� ���.
		2. bone - ������. ��� �����, �� ������� ��������� ����.
		3. power - ���� �����
		4. impulse - �������
		5. reverse (true/false) - ��������� ����������� �����. �� ��������� false
--]]
function hit_npc(actor, npc, p)
	local h = hit()
	local rev = p[6] and p[6] == 'true'
	h.draftsman = npc
	h.type = hit.wound
	if p[1] ~= "self" then
		local hitter = get_story_object(p[1])
		if not hitter then return end
		if rev then
			h.draftsman = hitter
			h.direction = hitter:position():sub(npc:position())
		else
			h.direction = npc:position():sub(hitter:position())
		end
	else
		if rev then
			h.draftsman = nil
			h.direction = npc:position():sub(patrol(p[2]):point(0))
		else
			h.direction = patrol(p[2]):point(0):sub(npc:position())
		end
	end
	h:bone(p[3])
	h.power = p[4]
	h.impulse = p[5]
	--printf("HIT EFFECT: (%s, %s,%d,%d) health(%s)", npc:name(), p[2], h.power, h.impulse, npc.health)
	npc:hit(h)
end

--[[
���� �������, ��������� story_id, ���.
���������: actor, npc, p[sid,bone,power,impulse,hit_src=npc:position()]
		1. sid - story_id �������, �� �������� ��������� ���.
		2. bone - ������. ��� �����, �� ������� ��������� ����.
		3. power - ���� �����
		4. impulse - �������
		5. hit_src - ���� �����, �� ��������������� ��� story_id �������, �� �������
				�������� ��������� ��� (�� �� �������� � ����������� ����), ����� ���
				����� (waypoint), �� ������� �� ������� ��������� ���.
				���� �� ������, �� ������� ������� �������, �� �������� ���� �������
				������ �������.
--]]
function hit_obj(actor, npc, p)
	local h = hit()
	local obj = get_story_object(p[1])
	local sid = nil

	if not obj then
--    printf("HIT_OBJ [%s]. Target object does not exist", npc:name())
		return
	end

	h:bone(p[2])
	h.power = p[3]
	h.impulse = p[4]

	if p[5] then
		sid = get_story_object(sid)
		if sid then
			h.direction = vector():sub(sid:position(), obj:position())
		end
		if not sid then
			h.direction = vector():sub(patrol(p[5]):point(0), obj:position())
		end
	else
		h.direction = vector():sub(npc:position(), obj:position())
	end
	h.draftsman = sid or npc
	h.type = hit.wound
	obj:hit(h)
end


function hit_obj_chemical(actor, npc, p)
	local h = hit()
	local obj = get_story_object(p[1])
	local sid = nil

	if not obj then
--    printf("HIT_OBJ [%s]. Target object does not exist", npc:name())
		return
	end

	h:bone(p[2])
	h.power = p[3]
	h.impulse = p[4]

	if p[5] then
		sid = get_story_object(sid)
		if sid then
			h.direction = vector():sub(sid:position(), obj:position())
		end
		if not sid then
			h.direction = vector():sub(patrol(p[5]):point(0), obj:position())
		end
	else
		h.direction = vector():sub(npc:position(), obj:position())
	end

	h.draftsman = sid or npc
	h.type = hit.chemical_burn
	obj:hit(h)
end

function hit_obj_fire_wound(actor, npc, p)
	local h = hit()
	local obj = get_story_object(p[1])
	local sid = nil

	if not obj then
--    printf("HIT_OBJ [%s]. Target object does not exist", npc:name())
		return
	end

	h:bone(p[2])
	h.power = p[3]
	h.impulse = p[4]

	if p[5] then
		sid = get_story_object(sid)
		if sid then
			h.direction = vector():sub(sid:position(), obj:position())
		end
		if not sid then
			h.direction = vector():sub(patrol(p[5]):point(0), obj:position())
		end
	else
		h.direction = vector():sub(npc:position(), obj:position())
	end

	h.draftsman = sid or npc
	h.type = hit.fire_wound
	obj:hit(h)
end

--[[
���� �������� ��������� ����� ����� ������. ���������� �����������, ������ ����������� ���� ������
����������� ����� ������. ������� ��������� direction ���.
���������: actor, npc, p[bone,power,impulse]
FIXME: killer:position() isn't working <-(Because you are fucking stupid)
--]]
function hit_by_killer(actor, npc, p)
	if not npc then return end
	local t = db.storage[npc:id()].death
	if not (t) then
		return false
	end

	if (t.killer == nil or t.killer == -1) then
		return false
	end

	local killer = db.storage[t.killer].object or level.object_by_id(t.killer)
	if not (killer) then
		return false
	end

	local p1, p2
	p1 = npc:position()
	p2 = killer:position()
	local h = hit()
	h.draftsman = npc
	h.type = hit.wound
	h.direction = vector():set(p1):sub(p2)
	h.bone = p[1]
	h.power = p[2]
	h.impulse = p[3]
	npc:hit(h)
end


function hit_npc_from_actor(actor, npc, p)
	local h = hit()
	local sid = nil
	h.draftsman = actor
	h.type = hit.wound

	if p and p[1] then
		sid = get_story_object(p[1])
		if sid then
			h.direction = actor:position():sub(sid:position())
		end
		if not sid then
			h.direction = actor:position():sub(npc:position())
		end
	else
		h.direction = actor:position():sub(npc:position())
		sid = npc
	end

	h:bone("bip01_spine")
	h.power = 0.001
	h.impulse = 0.001
	sid:hit(h)
end

--[[
-- ������ ��� �� ���, ���� ����� ���� �������� (����� ����), �� ��� � ����� ����� ���� ������ ��� � �������� ������� ��� �������.
-- ���� ������ 2 ����� ���� , �� ��� � 1-�� ����� ���� ������ ��� �� 2-�� ����� ����.
function hit_npc_from_npc(actor, npc, p)
	if p == nil then printf("Invalid parameter in function 'hit_npc_from_npc'!!!!") end
	local h = hit()
	local hitted_npc = npc
	h.draftsman = get_story_object(p[1])
	if p[2] ~= nil then
		hitted_npc = get_story_object(p[2])
	end
	h.type = hit.wound
	h.direction = h.draftsman:position():sub(hitted_npc:position())
	h:bone("bip01_spine")
	h.power = 0.03
	h.impulse = 0.03
	hitted_npc:hit(h)
end
]]--

function hit_actor(actor, npc, p)
	local h = hit()
	h.direction = vector():set(0,0,0)
	h.draftsman = actor
	h.type = hit.shock
	h:bone("bip01_spine")
	h.power = (p and p[1] and tonumber(p[1])) or 0.001
	h.impulse = 0.001
	actor:hit(h)
end

function restore_health_portion(actor, npc)
    local health = npc.health
    local diff = 1 - health
    if diff > 0 then
        npc.health = health + math.random(diff / 2, diff * 0.95)
    end
end
function restore_health(actor, npc)
	--printf("HEALTH RESTORE")
	npc.health = 1
end

function damage_health(actor, npc, p)
	local npc = get_story_object(p[1])
	if not (npc) then
		return
	end
	
	npc.health = -((p and p[2] and tonumber(p[2])) or 0.1)
end

function make_enemy(actor, npc, p)
	--[[
	if p == nil then printf("Invalid parameter in function 'hit_npc_from_npc'!!!!") end
	local h = hit()
	local hitted_npc = npc
	h.draftsman = get_story_object(p[1])
	if p[2] ~= nil then
		hitted_npc = get_story_object(p[2])
	end
	h.type = hit.wound
	h.direction = h.draftsman:position():sub(hitted_npc:position())
	h:bone("bip01_spine")
	h.power = 0.03
	h.impulse = 0.03
	hitted_npc:hit(h)
	--]]
	local npc1 = get_story_object(p[1])
	if not (npc1) then
		return
	end
	local npc2 = get_story_object(p[2])
	if not (npc2) then
		return
	end
	npc1:set_relation(game_object.enemy,npc2)
	npc2:set_relation(game_object.enemy,npc1)
end

function sniper_fire_mode(actor, npc, p)
	if p[1] == "true" then
		--printf("SNIPER FIRE MODE ON")
		npc:sniper_fire_mode(true)
	else
		--printf("SNIPER FIRE MODE OFF")
		npc:sniper_fire_mode(false)
	end
end

function kill_npc(actor, npc, p)
	if p and p[1] then
		npc = get_story_object(p[1])
	end
	if npc ~= nil and npc:alive() then
		npc:kill(npc)
	end
end

function remove_npc(actor, npc, p)
	if p and p[1] then
		npc_id = get_story_object_id(p[1])
	end
	if npc_id ~= nil then
		local se_obj = alife_object(npc_id)
		if (se_obj) then
			safe_release_manager.release(se_obj)
			--alife():release(se_obj, true)
		end
	end
end

-- ��������� � ���������� �������� ����� 1
function inc_counter(actor, npc, p)
	if p and p[1] then
		local inc_value = p[2] or 1
		local new_value = utils.load_var(actor, p[1], 0) + inc_value
		if npc and npc:name() then
			printf("inc_counter '%s'  to value [%s], by [%s]", p[1], tostring(new_value), tostring(npc:name()))
		end
		utils.save_var(actor, p[1], new_value)
	end
end

function dec_counter(actor, npc, p)
	if p and p[1] then
		local dec_value = p[2] or 1
		local new_value = utils.load_var(actor, p[1], 0) - dec_value
		if new_value < 0 then
			new_value = 0
		end
		utils.save_var(actor, p[1], new_value)
		if npc and npc:name() then
			printf( "dec_counter [%s] value [%s] by [%s]", p[1], utils.load_var(actor, p[1], 0), tostring(npc:name()))
		end
	end
end

function set_counter(actor, npc, p)
	if p and p[1] then
		local count = p[2] or 0
--		printf( "set_counter '%s' %s", p[1], count)
		utils.save_var(actor, p[1], count)
--		printf("counter [%s] value [%s]", p[1], utils.load_var(actor, p[1], 0))
	end
end


------------------------------------------------------------------------------------------------------------------------
-- ����������� � ������� ����� � �����
function actor_punch(npc)
	if db.actor:position():distance_to_sqr(npc:position()) > 4 then
		return
	end

	set_inactivate_input_time(30)
	level.add_cam_effector("camera_effects\\fusker.anm", 999, false, "")

	local active_slot = db.actor:active_slot()
	if active_slot ~= 2 and
		 active_slot ~= 3
	then
		return
	end

	local active_item = db.actor:active_item()
	if active_item then
		db.actor:drop_item(active_item)
	end
end

-- ��������� �����
function clearAbuse(npc)
	xr_abuse.clear_abuse(npc)
end

function turn_off_underpass_lamps(actor, npc)
	local lamps_table = {
							["pas_b400_lamp_start_flash"] = true,
							["pas_b400_lamp_start_red"] = true,
							["pas_b400_lamp_elevator_green"] = true,
							["pas_b400_lamp_elevator_flash"] = true,
							["pas_b400_lamp_elevator_green_1"] = true,
							["pas_b400_lamp_elevator_flash_1"] = true,
							["pas_b400_lamp_track_green"] = true,
							["pas_b400_lamp_track_flash"] = true,
							["pas_b400_lamp_downstairs_green"] = true,
							["pas_b400_lamp_downstairs_flash"] = true,
							["pas_b400_lamp_tunnel_green"] = true,
							["pas_b400_lamp_tunnel_flash"] = true,
							["pas_b400_lamp_tunnel_green_1"] = true,
							["pas_b400_lamp_tunnel_flash_1"] = true,
							["pas_b400_lamp_control_down_green"] = true,
							["pas_b400_lamp_control_down_flash"] = true,
							["pas_b400_lamp_control_up_green"] = true,
							["pas_b400_lamp_control_up_flash"] = true,
							["pas_b400_lamp_hall_green"] = true,
							["pas_b400_lamp_hall_flash"] = true,
							["pas_b400_lamp_way_green"] = true,
							["pas_b400_lamp_way_flash"] = true,
						}
	for k,v in pairs(lamps_table) do
		local obj = get_story_object(k)

		if obj then
			obj:get_hanging_lamp():turn_off()
		else
			printf("function 'turn_off_underpass_lamps' lamp [%s] does not exist", tostring(k))
			--printf("function 'turn_off_underpass_lamps' lamp [%s] does not exist", tostring(k))
		end
	end
end

---���������� ������������ �������� (hanging_lamp)
function turn_off(actor, npc, p)
	for k,v in pairs(p) do
		local obj = get_story_object(v)

		if not obj then
			printf("TURN_OFF. Target object with story_id [%s] does not exist", v)
			return
		end
		obj:get_hanging_lamp():turn_off()
		--printf("TURN_OFF. Target object with story_id [%s] turned off.", v)
	end
end

function turn_off_object(actor, npc)
	npc:get_hanging_lamp():turn_off()
end

---��������� ������������ �������� (hanging_lamp)
function turn_on(actor, npc, p)
	for k,v in pairs(p) do
		local obj = get_story_object(v)

		if not obj then
			printf("TURN_ON [%s]. Target object does not exist", npc:name())
			return
		end
		obj:get_hanging_lamp():turn_on()
	end
end

function enable_light_switcher(actor, npc, p)
	bind_dynamic_light.switch_light_from_table(npc:name())
end


---��������� � ������ ������������ �������� (hanging_lamp)
function turn_on_and_force(actor, npc, p)
	local obj = get_story_object(p[1])
	if not obj then
		printf("TURN_ON_AND_FORCE. Target object does not exist")
		return
	end
	if p[2] == nil then p[2] = 55 end
	if p[3] == nil then p[3] = 14000 end
	obj:set_const_force(vector():set(0,1,0), p[2], p[3])
	obj:start_particles("weapons\\light_signal", "link")
	obj:get_hanging_lamp():turn_on()
end

---���������� ������������ �������� � ��������� (hanging_lamp)
function turn_off_and_force(actor, npc, p)
	local obj = get_story_object(p[1])
	if not obj then
		printf("TURN_OFF [%s]. Target object does not exist", npc:name())
		return
	end
	obj:stop_particles("weapons\\light_signal", "link")
	obj:get_hanging_lamp():turn_off()
end


function turn_on_object(actor, npc)
	npc:get_hanging_lamp():turn_on()
end

function turn_off_object(actor, npc)
	npc:get_hanging_lamp():turn_off()
end


-- ����� ���� ������� �������� ���������� [combat] ��� ��� ���������.
-- ������������ � �������, ����� ��� ����������� ��������, ����� ��� ������������ �� ������ ������,
-- ��� ���������, � �������� ��������� �� �� ����� ��� ������ (� ������� ������ [combat] ����������� �� ������
-- �������, ����� �������� � ���, ����, �������, �� ��������� ������� ���� �������).
function disable_combat_handler(actor, npc)
	if db.storage[npc:id()].combat then
		db.storage[npc:id()].combat.enabled = false
	end

	if db.storage[npc:id()].mob_combat then
		db.storage[npc:id()].mob_combat.enabled = false
	end
end

-- ����� ���� ������� �������� ���������� [combat_ignore] ��������� ��� ��� ���������.
function disable_combat_ignore_handler(actor, npc)
	if db.storage[npc:id()].combat_ignore then
		db.storage[npc:id()].combat_ignore.enabled = false
	end
end

-------------------------------------------------------------------------------------
-- ������� ��� ������ � ����������
-------------------------------------------------------------------------------------
--[[
function heli_set_enemy_actor(actor, npc)
	local st = db.storage[npc:id()]
	if not st.combat.enemy_id and actor:alive() then
		st.combat.enemy_id = actor:id()
		heli_snd.play_snd( st, heli_snd.snd_see_enemy, 1 )
	end
end

function heli_set_enemy(actor, npc, p)
	local st  = db.storage[npc:id()]
	local obj = get_story_object( p[1] )
	if not st.combat.enemy_id and obj:alive() then
		st.combat.enemy_id = obj:id()
		heli_snd.play_snd( st, heli_snd.snd_see_enemy, 1 )
	end
end

function heli_clear_enemy(actor, npc)
	db.storage[npc:id()].combat:forget_enemy()
end
]]--

function heli_start_flame(actor, npc)
	bind_heli.heli_start_flame( npc )
end

function heli_die(actor, npc)
	bind_heli.heli_die( npc )
end


--'-----------------------------------------------------------------------------------
--' ������� ��� ������ � ��������� ���������
--'-----------------------------------------------------------------------------------

-- �������������� ��������� �������� �������
-- =set_weather(<������ ������>:true) - ��������� ������ �����, false - ����� ��������� �����
-- ����� �������������� �� ������ ���� ��� ������� � � ����� jup_b15 - ���� ����� ������ � �������
function set_weather(actor, npc, p)
	if(p[1]) then
		if(p[2]=="true") then
			level.set_weather(p[1],true)
		else
			level.set_weather(p[1],false)
		end
	end
end
--[[
function update_weather(actor, npc, p)
	if p and p[1] then
		if p[1] == "true" then
			level_weathers.get_weather_manager():select_weather(true)
		elseif p[1] == "false" then
			level_weathers.get_weather_manager():select_weather(false)
		end
	end
end

function start_small_reject(actor, npc)
	level.set_weather_fx("fx_surge_day_3")
	level.add_pp_effector("vibros_p.ppe", 1974, false)
	this.aes_earthshake(npc)
end

function start_full_reject(actor, npc)
	level.set_weather_fx("fx_surge_day_3")
	level.remove_pp_effector(1974)
	level.remove_cam_effector(1975)
	level.add_cam_effector("camera_effects\\earthquake.anm", 1975, true, "")
end

function stop_full_reject(actor, npc)
	level.remove_pp_effector(1974)
	level.remove_cam_effector(1975)
end

function run_weather_pp(actor,npc, p)
	local weather_fx = p[1]
	if weather_fx == nil then
		weather_fx = "fx_surge_day_3"
	end
	level.set_weather_fx(weather_fx)
end
]]--

function game_disconnect(actor, npc)
	get_console():execute("disconnect")
--	c:execute_deferred("main_menu off")
--	c:execute_deferred("hide")
end

function game_credits(actor, npc)
	db.gameover_credits_started = true
	game.start_tutorial("credits_seq")
end

function game_over(actor, npc)
	if db.gameover_credits_started ~= true then
		return
	end
	local c = get_console()
	printf("main_menu on console command is executed")
	c:execute("main_menu on")
end


function game_finish(actor, npc)
	get_console():execute("disconnect")
	db.gameover_credits_started = true
	game.start_tutorial("credits_seq")
end

function after_credits(actor, npc)
	get_console():execute	("main_menu on")
end

function before_credits(actor, npc)
	get_console():execute	("main_menu off")
end

function on_tutor_gameover_stop()
	local c = get_console()
	printf("main_menu on console command is executed")
	c:execute("main_menu on")
end

function on_tutor_gameover_quickload()
	local c = get_console()
	c:execute("load_last_save")
end


-- ��� ����� ������
function get_stalker_for_new_job(actor, npc, p)
	xr_gulag.find_stalker_for_job(npc,p[1])
end
function switch_to_desired_job(actor, npc, p)
	xr_gulag.switch_to_desired_job(npc)
end

--[[
function death_hit(actor, npc, p)
	 local draftsman = get_story_object (p[1])
	 local hitted_obj = (p[2] ~= nil and get_story_object (p[2])) or npc
	 if draftsman == nil or hitted_obj == nil then
		return
	 end
	 local h = hit()
	 h.power = 1000
	 h.direction = hitted_obj:direction()
	 h.draftsman = draftsman
	 h.impulse = 1
	 h.type = hit.wound
	 hitted_obj:hit(h)
end
]]--

--'-----------------------------------------------------------------------------------
--' ������� ��� ������ � ����������
--'-----------------------------------------------------------------------------------
function spawn_object(actor, obj, p)
		--' p[1] - ������ ���� ��������
		--' p[2] - ��� ����������� ���� ��� ��� �����.
	local spawn_sect = p[1]
	if spawn_sect == nil then
		printf("Wrong spawn section for 'spawn_object' function %s. For object %s", tostring(spawn_sect), obj:name())
	end

	local path_name = p[2]
	if path_name == nil then
		printf("Wrong path_name for 'spawn_object' function %s. For object %s", tostring(path_name), obj:name())
	end

	if not level.patrol_path_exists(path_name) then
		printf("Path %s doesnt exist. Function 'spawn_object' for object %s ", tostring(path_name), obj:name())
	end
	local ptr = patrol(path_name)
	local index = p[3] or 0
	local yaw = p[4] or 0

	--' printf("Spawning %s at %s, %s", tostring(p[1]), tostring(p[2]), tostring(p[3]))
	local se_obj = alife():create(spawn_sect,ptr:point(index),ptr:level_vertex_id(0),ptr:game_vertex_id(0))
	if (se_obj) then
		if IsStalker( nil, se_obj:clsid()) then
			se_obj:o_torso().yaw = yaw * math.pi / 180
		elseif se_obj:clsid() == clsid.script_phys then
			se_obj:set_yaw(yaw * math.pi / 180)
		end
	end
end

local jup_b219_position
local jup_b219_lvid
local jup_b219_gvid

function jup_b219_save_pos()
	local obj = get_story_object("jup_b219_gate_id")
	if obj and obj:position() then
		jup_b219_position = obj:position()
		jup_b219_lvid = obj:level_vertex_id()
		jup_b219_gvid = obj:game_vertex_id()
	else
		return
	end
	sobj = alife_object(obj:id())
	if sobj then
		alife():release(sobj, true)
	end
end

function jup_b219_restore_gate()
	local yaw = 0
	local spawn_sect = "jup_b219_gate"
	if jup_b219_position then
		local se_obj = alife():create(spawn_sect,vector():set(jup_b219_position),jup_b219_lvid,jup_b219_gvid)
		if (se_obj) then
			se_obj:set_yaw(yaw * math.pi / 180)
		end
	end
end

function spawn_corpse(actor, obj, p)
		--' p[1] - ������ ���� ��������
		--' p[2] - ��� ����������� ���� ��� ��������.
	local spawn_sect = p[1]
	if spawn_sect == nil then
		printf("Wrong spawn section for 'spawn_corpse' function %s. For object %s", tostring(spawn_sect), obj:name())
	end

	local path_name = p[2]
	if path_name == nil then
		printf("Wrong path_name for 'spawn_corpse' function %s. For object %s", tostring(path_name), obj:name())
	end

	if not level.patrol_path_exists(path_name) then
		printf("Path %s doesnt exist. Function 'spawn_corpse' for object %s ", tostring(path_name), obj:name())
	end
	local ptr = patrol(path_name)
	local index = p[3] or 0

	local se_obj = alife():create(spawn_sect,ptr:point(index),ptr:level_vertex_id(0),ptr:game_vertex_id(0))
	if (se_obj) then
		se_obj:kill()
	end
end


function spawn_object_in(actor, obj, p)
	--' p[1] - ������ ���� ��������
	--' p[2] - ����� ���� ������� � ������� ��������
	local spawn_sect = p[1]
	if spawn_sect == nil then
		printf("Wrong spawn section for 'spawn_object' function %s. For object %s", tostring(spawn_sect), obj:name())
	end
	if p[2] == nil then
		printf("Wrong target_name for 'spawn_object_in' function %s. For object %s", tostring(target_name), obj:name())
	end
--	local box = alife_object(target_name)
--	if(box==nil) then

	printf("xr_effects.spawn_object_in trying to find object %s", tostring(p[2]))

	local target_obj_id = get_story_object_id(p[2])
	if target_obj_id ~= nil then
		box = alife_object(target_obj_id)
		if box == nil then
			printf("xr_effects.spawn_object_in There is no such object %s", p[2])
		end
		alife():create(spawn_sect,vector(),0,0,target_obj_id)
	else
		printf("xr_effects.spawn_object_in object is nil %s", tostring(p[2]))
	end
end


function spawn_npc_in_zone(actor, obj, p)
	--' p[1] - ������ ���� ��������
	--' p[2] - ��� ���� � ������� ��������.
	local spawn_sect = p[1]
	if spawn_sect == nil then
		printf("Wrong spawn section for 'spawn_object' function %s. For object %s", tostring(spawn_sect), obj:name())
	end
	local zone_name = p[2]
	if zone_name == nil then
		printf("Wrong zone_name for 'spawn_object' function %s. For object %s", tostring(zone_name), obj:name())
	end
	if db.zone_by_name[zone_name] == nil then
		printf("Zone %s doesnt exist. Function 'spawn_object' for object %s ", tostring(zone_name), obj:name())
	end
	local zone = db.zone_by_name[zone_name]
--	printf("spawn_npc_in_zone: spawning %s at zone %s, squad %s", tostring(p[1]), tostring(p[2]), tostring(p[3]))
	local spawned_obj = alife():create( spawn_sect,
										zone:position(),
										zone:level_vertex_id(),
										zone:game_vertex_id())
	spawned_obj.sim_forced_online = true
	spawned_obj.squad = 1 or p[3]
	db.script_ids[spawned_obj.id] = zone_name
end

function destroy_object(actor, obj, p)
	local sobj
	if (p == nil or p[1] == nil) then
		sobj = alife_object(obj:id())
	elseif (p[1] == "story" and p[2] ~= nil) then
		local id = get_story_object_id(p[2])
		if not (id) then 
			printf("destroy_object %s story id doesn't exist!",p[2])
		end
		sobj = id and alife_object(id)
	end
	
	if not (sobj) then
		return
	end

	local cls = sobj:clsid()
	if (cls == clsid.online_offline_group_s or IsStalker(nil,cls) or IsMonster(nil,cls)) then
		safe_release_manager.release(sobj)
	else
		alife():release(sobj, true)
	end
end

function give_actor(actor, npc, p)
	for k,v in pairs(p) do
		alife():create(v,
				db.actor:position(),
				db.actor:level_vertex_id(),
				db.actor:game_vertex_id(),
				db.actor:id())
		news_manager.relocate_item(db.actor, "in", v)
	end
end

function activate_weapon_slot(actor, npc, p)
	db.actor:activate_slot(p[1])
end

function anim_obj_forward(actor, npc, p)
	for k,v in pairs(p) do
		if v ~= nil then
			db.anim_obj_by_name[v]:anim_forward()
		end
	end
end
function anim_obj_backward(actor, npc, p)
	if p[1] ~= nil then
		db.anim_obj_by_name[p[1]]:anim_backward()
	end
end
function anim_obj_stop(actor, npc, p)
	if p[1] ~= nil then
		db.anim_obj_by_name[p[1]]:anim_stop()
	end
end

-- ������� ��� ������ � ��������� ������.
--[[
function turn_on_fire_zone(actor, npc, p)
	bind_campfire.fire_zones_table[ p[1] ]:turn_on()
end

function turn_off_fire_zone(actor, npc, p)
	bind_campfire.fire_zones_table[ p[1] ]:turn_off()
end
]]--
--'-----------------------------------------------------------------------------------
--' ������� ��� ����������� �����
--'-----------------------------------------------------------------------------------
function play_sound_on_actor(actor,obj,p)
	local snd = sound_object(p[1])

	if (snd) then
		--snd:play_at_pos(db.actor,db.actor:position(),0,sound_object.s3d)
		snd:play(db.actor, 0, sound_object.s2d)
	end
end

function play_sound(actor, obj, p)
	local theme = p[1]
	local faction = p[2]
	local point
	if (p[3]) then
		local smart = SIMBOARD.smarts_by_names[p[3]]
		if (smart) then
			point = smart.id
		else
			point = p[3]
		end
	end

	if obj and IsStalker(obj) then
		if not obj:alive() then
			printf("Stalker [%s][%s] is dead, but you wants to say something for you: [%s]!", tostring(obj:id()), tostring(obj:name()), p[1])
		end
	end

	xr_sound.set_sound_play(obj:id(), theme, faction, point)
end

function play_sound_by_story(actor, obj, p)
	local story_obj = get_story_object_id(p[1])
	local theme = p[2]
	local faction = p[3]
	local point = SIMBOARD.smarts_by_names[p[4]]
	if point ~= nil then
		point = point.id
	elseif p[4]~=nil then
		point = p[4]
	end
	xr_sound.set_sound_play(story_obj, theme, faction, point)
end

function stop_sound(actor, npc)
	xr_sound.stop_sounds_by_id(npc:id())
end

function play_sound_looped(actor, obj, p)
	local theme = p[1]
	xr_sound.play_sound_looped(obj:id(), theme)
end

function stop_sound_looped(actor, obj)
	xr_sound.stop_sound_looped(obj:id())
end

function barrel_explode (actor , npc , p)
	local expl_obj = get_story_object (p[1])
	if expl_obj ~= nil then
		expl_obj:explode(0)
	end
end

--com
function play_inv_repair_kit_use_fast_2p8()
	xr_sound.set_sound_play(db.actor:id(),"inv_repair_kit_use_fast_2p8")
end

function play_inv_repair_kit_use_fast()
	xr_sound.set_sound_play(db.actor:id(),"inv_repair_kit_use_fast")
end

function play_inv_repair_kit_with_brushes()
	xr_sound.set_sound_play(db.actor:id(),"inv_repair_kit_with_brushes")
end

function play_inv_repair_sewing_kit()
	xr_sound.set_sound_play(db.actor:id(),"inv_repair_sewing_kit")
end

function play_inv_repair_sewing_kit_fast()
	xr_sound.set_sound_play(db.actor:id(),"inv_repair_sewing_kit_fast")
end

function play_inv_repair_spray_oil()
	xr_sound.set_sound_play(db.actor:id(),"inv_repair_spray_oil")
end

function play_inv_repair_brushes()
	xr_sound.set_sound_play(db.actor:id(),"inv_repair_brushes")
end

function play_inv_repair_kit()
	xr_sound.set_sound_play(db.actor:id(),"inv_repair_kit")
end

function play_inv_drink_flask_2()
	xr_sound.set_sound_play(db.actor:id(),"inv_drink_flask_2")
end

function play_inv_cooking()
	xr_sound.set_sound_play(db.actor:id(),"inv_cooking")
end

function play_inv_cooking_cooker()
	xr_sound.set_sound_play(db.actor:id(),"inv_cooking_cooker")
end

function play_inv_cooking_stove()
	xr_sound.set_sound_play(db.actor:id(),"inv_cooking_stove")
end

function play_inv_aam_open()
	xr_sound.set_sound_play(db.actor:id(),"inv_aam_open")
end

function play_inv_aam_close()
	xr_sound.set_sound_play(db.actor:id(),"inv_aam_close")
end

function play_inv_aac_open()
	xr_sound.set_sound_play(db.actor:id(),"inv_aac_open")
end

function play_inv_aac_close()
	xr_sound.set_sound_play(db.actor:id(),"inv_aac_close")
end

function play_inv_iam_open()
	xr_sound.set_sound_play(db.actor:id(),"inv_iam_open")
end

function play_inv_iam_close()
	xr_sound.set_sound_play(db.actor:id(),"inv_iam_close")
end

function play_inv_lead_open()
	xr_sound.set_sound_play(db.actor:id(),"inv_lead_open")
end

function play_inv_lead_close()
	xr_sound.set_sound_play(db.actor:id(),"inv_lead_close")
end

function play_inv_mask_clean()
	xr_sound.set_sound_play(db.actor:id(),"inv_mask_clean")
end

--'-----------------------------------------------------------------------------------
--' Alife support
--'-----------------------------------------------------------------------------------
--[[
function start_sim(actor, obj)
	SIMBOARD:start_sim()
end

function stop_sim(actor, obj)
	SIMBOARD:stop_sim()
end

function update_faction_brain(actor, obj, p)
	if p[1] == nil then
		printf("Wrong parameters update_faction_brain")
	end
	local board = SIMBOARD
	local player = board.players[ p[1] ]
	if player == nil then
		printf("Can't find player %s", tostring(p[1]))
	end
	player:faction_brain_update()
end
]]--

function create_squad(actor, obj, p)
	if obj ~= nil then
		printf("pl:creating_squad from obj [%s] in section [%s]", tostring(obj:name()), tostring(db.storage[obj:id()].active_section))
	end
	local squad_id = p[1]
	if squad_id == nil then
		printf("Wrong squad identificator [NIL] in create_squad function")
	end
	local smart_name = p[2]
	if smart_name == nil then
		printf("Wrong smart name [NIL] in create_squad function")
	end

	local ltx = system_ini()

	if not ltx:section_exist(squad_id) then
		printf("Wrong squad identificator [%s]. Squad descr doesnt exist.", tostring(squad_id))
	end

	local board = SIMBOARD
	local smart = board.smarts_by_names[smart_name]
	if smart == nil then
		printf("Wrong smart_name [%s] for [%s] faction in create_squad function", tostring(smart_name), tostring(player_name))
	end

	printf("Create squad %s BEFORE",squad_id)
	local squad = board:create_squad(smart, squad_id)
	if not (squad) then
		return
	end
	printf("Create squad %s AFTER",squad_id)

	--board:enter_smart(squad, smart.id)

	local sim = alife()
	for k in squad:squad_members() do
		local se_obj = k.object or k.id and sim:object(k.id)
		if (se_obj) then
			board:setup_squad_and_group(se_obj)
		end
	end

	--squad:update()
	return squad
end

function create_squad_member(actor, obj, p)
	local squad_member_sect = p[1]
	local story_id			= p[2]
	local position			= nil
	local level_vertex_id	= nil
	local game_vertex_id	= nil
	if story_id == nil then
		printf("Wrong squad identificator [NIL] in 'create_squad_member' function")
	end
	local board = SIMBOARD
	local squad = get_story_squad(story_id)
	if not (squad) then
		return
	end

	local squad_smart = squad.smart_id and board.smarts[squad.smart_id].smrt
	if not (squad_smart) then
		return
	end

	if p[3] ~= nil then
		local spawn_point
		if p[3] == "simulation_point" then
			spawn_point = system_ini():r_string_ex(squad:section_name(),"spawn_point")
			if spawn_point == "" or spawn_point == nil then
				spawn_point = xr_logic.parse_condlist(obj, "spawn_point", "spawn_point", squad_smart.spawn_point)
			else
				spawn_point = xr_logic.parse_condlist(obj, "spawn_point", "spawn_point", spawn_point)
			end
			spawn_point = xr_logic.pick_section_from_condlist(db.actor, obj, spawn_point)
		else
			spawn_point = p[3]
		end
		position 		= patrol(spawn_point):point(0)
		level_vertex_id = patrol(spawn_point):level_vertex_id(0)
		game_vertex_id 	= patrol(spawn_point):game_vertex_id(0)
	else
		local commander = alife_object(squad:commander_id())
		position		= commander.position
		level_vertex_id = commander.m_level_vertex_id
		game_vertex_id	= commander.m_game_vertex_id
	end
	local new_member_id = squad:add_squad_member(squad_member_sect, position,  level_vertex_id, game_vertex_id)

	local se_obj = new_member_id and alife_object(new_member_id)
	if (se_obj) then
		squad_smart:register_npc(se_obj)
	end

	board:setup_squad_and_group(alife():object(new_member_id))
	--squad_smart:refresh()
	squad:update()
end

function remove_squad(actor, obj, p)
	local story_id = p[1]
	if story_id == nil then
		printf("Wrong squad identificator [NIL] in remove_squad function")
	end
	local squad = get_story_squad(story_id)
	if squad == nil then
		assert("Wrong squad identificator [%s]. squad doesnt exist", tostring(story_id))
		return
	end
	SIMBOARD:remove_squad(squad)
end

function kill_squad(actor, obj, p)
	local story_id = p[1]
	if story_id == nil then
		printf("Wrong squad identificator [NIL] in kill_squad function")
	end
	local squad = get_story_squad(story_id)
	if squad == nil then
		return
	end
	local squad_npcs = {}
	for k in squad:squad_members() do
		squad_npcs[k.id] = true
	end

	for k,v in pairs(squad_npcs) do
		local cl_obj = db.storage[k] and db.storage[k].object
		if cl_obj == nil then
			alife_object(tonumber(k)):kill()
		else
			cl_obj:kill(cl_obj)
		end
	end
end

function heal_squad(actor, obj, p)
	local story_id = p[1]
	local health_mod = 1
	if p[2] and p[2] ~= nil then
		health_mod = math.ceil(p[2]/100)
	end
	if story_id == nil then
		printf("Wrong squad identificator [NIL] in heal_squad function")
	end
	local squad = get_story_squad(story_id)
	if squad == nil then
		return
	end
	for k in squad:squad_members() do
		local cl_obj = db.storage[k.id] and db.storage[k.id].object
		if cl_obj ~= nil then
			cl_obj.health = health_mod
		end
	end
end

--[[
function update_squad(actor, obj, p)
	local squad_id = p[1]
	if squad_id == nil then
		printf("Wrong squad identificator [NIL] in remove_squad function")
	end
	local board = SIMBOARD
	local squad = board.squads[squad_id]
	if squad == nil then
		assert("Wrong squad identificator [%s]. squad doesnt exist", tostring(squad_id))
		return
	end
	squad:update()
end
]]--

-- this deletes squads from a smart
function clear_smart_terrain(actor, obj, p)
	local smart_name = p[1]
	if smart_name == nil then
		printf("Wrong squad identificator [NIL] in clear_smart_terrain function")
	end

	local board = SIMBOARD
	local smart = board.smarts_by_names[smart_name]
	local smart_id = smart.id
	for k,v in pairs(board.smarts[smart_id].squads) do
		if p[2] and p[2] == "true" then
			board:remove_squad(v)
		else
			if not get_object_story_id(v.id) then
				board:remove_squad(v)
			end
		end
	end
end

-- This forces squads to leave a smart
function flush_smart_terrain(actor,obj,p)
	local smart_name = p[1]
	if smart_name == nil then
		printf("Wrong squad identificator [NIL] in clear_smart_terrain function")
	end

	local board = SIMBOARD

	local function unregister(squad)
		squad.assigned_target_id = nil
		squad.current_target_id = nil
		squad.current_action = nil
		board:assign_squad_to_smart(squad, nil)
		for k in squad:squad_members() do
			local se_obj = alife_object(k.id)
			if (se_obj) then
				local smart_id = se_obj.m_smart_terrain_id
				if (smart_id and smart_id ~= 65535) then
					local smart = alife_object(smart_id)
					if (smart) then
						smart:unregister_npc(se_obj)
					end
				end
			end
		end
	end

	local smart = board.smarts_by_names[smart_name]
	local smart_id = smart.id
	for k,v in pairs(board.smarts[smart_id].squads) do
		if p[2] and p[2] == "true" then
			unregister(v)
		else
			if not get_object_story_id(v.id) then
				unregister(v)
			end
		end
	end
end


--[[
function set_actor_faction(actor, obj, p)
	if p[1] == nil then
		printf("Wrong parameters")
	end
	SIMBOARD:set_actor_community(p[1])
end
]]--
--'-----------------------------------------------------------------------------------
--' Quest support
--'-----------------------------------------------------------------------------------
-- TODO: add param 2 for story_id which can be used to get the npc's squad id or object id for task_giver_id
function give_task(actor, obj, p)
	if p[1] == nil then
		printf("No parameter in give_task function.")
	end
	task_manager.get_task_manager():give_task(p[1])
end

function set_active_task(actor, npc, p)
	if(p[1]) then
		local t = db.actor:get_task(tostring(p[1]), true)
		if(t) then
			db.actor:set_active_task(t)
		end
	end
end

function set_task_completed(actor,npc,p)
	if (p[1]) then
		task_manager.get_task_manager():set_task_completed(p[1])
	end
end

function set_task_failed(actor,npc,p)
	if (p[1]) then
		task_manager.get_task_manager():set_task_failed(p[1])
	end
end

-- ������� ��� ������ � �����������

function actor_friend(actor, npc)
	printf("_bp: xr_effects: actor_friend(): npc='%s': time=%d", npc:name(), time_global())
	npc:force_set_goodwill( 1000, actor)
end

function actor_neutral(actor, npc)
	npc:force_set_goodwill( 0, actor)
end

function actor_enemy(actor, npc)
	npc:force_set_goodwill( -1000, actor)
end

function set_squad_neutral_to_actor(actor, npc, p)
	local story_id = p[1]
	local squad = get_story_squad(story_id)
	if squad == nil then
		printf("There is no squad with id[%s]", tostring(story_id))
		return
	end
	squad:set_squad_relation("neutral")
end

function set_squad_friend_to_actor(actor, npc, p)
	local story_id = p[1]
	local squad = get_story_squad(story_id)
	if squad == nil then
		printf("There is no squad with id[%s]", tostring(story_id))
		return
	end
	squad:set_squad_relation("friend")
end

--������� ������ ������ � ������, ���������� ��� ������
function set_squad_enemy_to_actor( actor, npc, p)
	local story_id = p[1]
	local squad = get_story_squad(story_id)
	if squad == nil then
		printf("There is no squad with id[%s]", tostring(story_id))
		return
	end
	squad:set_squad_relation("enemy")
end

function set_npc_squad_enemy_to_actor( actor, npc, p)
	local squad = get_object_squad(npc)
	if squad == nil then
		printf("There is no squad with id[%s]", tostring(story_id))
		return
	end
	squad:set_squad_relation("enemy")
end

--[[
function set_friends(actor, npc, p)
	local npc1
	for i, v in pairs(p) do
		npc1 = get_story_object(v)
		if npc1 and npc1:alive() then
			--printf("_bp: %d:set_friends(%d)", npc:id(), npc1:id())
			npc:set_relation(game_object.friend, npc1)
			npc1:set_relation(game_object.friend, npc)
		end
	end
end

function set_enemies(actor, npc, p)
	local npc1
	for i, v in pairs(p) do
		--printf("_bp: set_enemies(%d)", v)
		npc1 = get_story_object(v)
		if npc1 and npc1:alive() then
			npc:set_relation(game_object.enemy, npc1)
			npc1:set_relation(game_object.enemy, npc)
		end
	end
end

function set_gulag_relation_actor(actor, npc, p)
	if(p[1]) and (p[2]) then
		game_relations.set_gulag_relation_actor(p[1], p[2])
	end
end

function set_factions_community(actor, npc, p)
	if(p[1]~=nil) and (p[2]~=nil) and (p[3]~=nil) then
		game_relations.set_factions_community(p[1], p[2], p[3])
	end
end

function set_squad_community_goodwill(actor, npc, p)
	if(p[1]~=nil) and (p[2]~=nil) and (p[3]~=nil) then
		game_relations.set_squad_community_goodwill(p[1], p[2], p[3])
	end
end
]]--

--sets NPC relation to actor
--set_npc_sympathy(number)
--call only from npc`s logic
function set_npc_sympathy(actor, npc, p)
	if(p[1]~=nil) then
		game_relations.set_npc_sympathy(npc, p[1])
	end
end

--sets SQUAD relation to actor
--set_squad_goodwill(faction:number)
function set_squad_goodwill(actor, npc, p)
	if(p[1]~=nil) and (p[2]~=nil) then
		game_relations.set_squad_goodwill(p[1], p[2])
	end
end

function set_squad_goodwill_to_npc(actor, npc, p)
	if(p[1]~=nil) and (p[2]~=nil) then
		game_relations.set_squad_goodwill_to_npc(npc, p[1], p[2])
	end
end

function inc_faction_goodwill_to_actor(actor, npc, p)
	local community = p[1]
	local delta		= p[2]
	if delta and community then
		game_relations.change_factions_community_num(community,actor:id(), tonumber(delta))
	else
		printf("Wrong parameters in function 'inc_faction_goodwill_to_actor'")
	end
end

function dec_faction_goodwill_to_actor(actor, npc, p)
	local community = p[1]
	local delta		= p[2]
	if delta and community then
		game_relations.change_factions_community_num(community,actor:id(), -tonumber(delta))
	else
		printf("Wrong parameters in function 'dec_faction_goodwill_to_actor'")
	end
end


--[[
function add_custom_static(actor, npc, p)
	if p[1] ~= nil and p[2] ~= nil then
		get_hud():AddCustomStatic(p[1], true)
		get_hud():GetCustomStatic(p[1]):wnd():SetTextST(p[2])
	else
		printf("Invalid parameters in function add_custom_static!!!")
	end
end

function remove_custom_static(actor, npc, p)
	if p[1] ~= nil then
		get_hud():RemoveCustomStatic(p[1])
	else
		printf("Invalid parameters in function remove_custom_static!!!")
	end
end
]]--

function kill_actor(actor, npc)
	db.actor:kill(db.actor)
end

-----------------------------------------------------------------------
--  Treasures support
-----------------------------------------------------------------------
function give_treasure (actor, npc, p)

end

--[[
function change_tsg(actor, npc, p)
	npc:change_team(p[1], p[2], p[3])
end

function exit_game(actor, npc)
	get_console():execute("quit")
end
]]--

function start_surge(actor, npc, p)
	surge_manager.start_surge(p)
end

function stop_surge(actor, npc, p)
	surge_manager.stop_surge()
end

function set_surge_mess_and_task(actor, npc, p)
	if(p) then
		surge_manager.set_surge_message(p[1])
		if(p[2]) then
			surge_manager.set_surge_task(p[2])
		end
	end
end

function enable_level_changer(actor, npc, p)
	if(p[1]~=nil) then
		local obj = get_story_object(p[1])
		if(obj) then
			if db.storage[obj:id()] and db.storage[obj:id()].s_obj then
				db.storage[obj:id()].s_obj.enabled = true
				db.storage[obj:id()].s_obj.hint = "level_changer_invitation"
			else
				return
			end
			obj:enable_level_changer(true)
			level_tasks.add_lchanger_location()
			obj:set_level_changer_invitation("level_changer_invitation")
		end
	end
end

function disable_level_changer(actor, npc, p)
	if(p[1]~=nil) then
		local obj = get_story_object(p[1])
		if(obj) then
			if not(db.storage[obj:id()] and db.storage[obj:id()].s_obj) then
				return
			end
			obj:enable_level_changer(false)
			level_tasks.del_lchanger_mapspot(tonumber(p[1]))
			db.storage[obj:id()].s_obj.enabled = false
			if(p[2]==nil) then
				obj:set_level_changer_invitation("level_changer_disabled")
				db.storage[obj:id()].s_obj.hint = "level_changer_disabled"
			else
				obj:set_level_changer_invitation(p[2])
				db.storage[obj:id()].s_obj.hint = p[2]
			end
		end
	end
end

--[[
function change_actor_community(actor, npc, p)
	if(p[1]~=nil) then
		db.actor:set_character_community(p[1], 0, 0)
	end
end

function set_faction_community_to_actor(actor, npc, p)
-- run_string xr_effects.change_actor_community(nil,nil,{"actor_dolg"})
	if(p[1]~=nil) and (p[2]~=nil) then
		local rel = 0
		if(p[2]=="enemy") then
			rel = -3000
		elseif(p[2]=="friend") then
			rel = 1000
		end
		db.actor:set_community_goodwill(p[1], rel)
	end
end

function disable_collision(actor, npc)
	npc:wounded(true)
end
function enable_collision(actor, npc)
	npc:wounded(false)
end

function disable_actor_collision(actor, npc)
	actor:wounded(true)
end
function enable_actor_collision(actor, npc)
	actor:wounded(false)
end

function relocate_actor_inventory_to_box(actor, npc, p)
	local function transfer_object_item(item)
		if item:section() ~= "wpn_binoc" and item:section() ~= "wpn_knife" and item:section() ~= "device_torch" then
			db.actor:transfer_item(item, inv_box_1)
		end
	end
	inv_box_1 = get_story_object (p[1])
	actor:inventory_for_each(transfer_object_item)
end
]]--

function make_actor_visible_to_squad(actor,npc,p)
	local story_id = p and p[1]
	local squad = get_story_squad(story_id)
	if squad == nil then printf("There is no squad with id[%s]", story_id) end
	for k in squad:squad_members() do
		local obj = level.object_by_id(k.id)
		if obj ~= nil then
			obj:make_object_visible_somewhen( db.actor )
		end
	end
end

function make_actor_visible_to_npc_squad(actor,npc,p)
	local squad = get_object_squad(npc)
	if squad == nil then printf("There is no squad with id[%s]", story_id) end
	for k in squad:squad_members() do
		local obj = level.object_by_id(k.id)
		if obj ~= nil then
			obj:make_object_visible_somewhen( db.actor )
		end
	end
end

function pstor_set_ctime(actor,npc,p)
	if (p[1]) then
		utils.save_ctime(db.actor,p[1],game.get_game_time())
	end
end

function pstor_set_string(actor,npc,p)
	if (p[1] and p[2]) then
		utils.save_var(db.actor,p[1],p[2])
	end
end

function pstor_set_squad(actor,npc,p)
	p[2] = tostring(p[2])
	if (p[1] and p[2]) then
		local squad = get_story_squad(p[2])
		if (squad) then
			utils.save_var(db.actor,p[1],squad.id)
		end
	end
end

function pstor_set(actor,npc,p)
	p[2] = tonumber(p[2])
	if (p[1] and p[2]) then
		utils.save_var(db.actor,p[1],p[2])
	end
end

function pstor_reset(actor,npc,p)
	if (p[1]) then
		utils.save_var(db.actor,p[1],nil)
	end
end

function stop_sr_cutscene(actor,npc,p)
	local obj = db.storage[npc:id()]
	if(obj.active_scheme~=nil) then
		obj[obj.active_scheme].signals["cam_effector_stop"] = true
	end
end

--[[
function reset_dialog_end_signal(actor, npc, p)
	local st = db.storage[npc:id()]
	if(st.active_scheme==nil) then
		return
	end
	if(st[st.active_scheme].signals==nil) then
		return
	end
	st[st.active_scheme].signals["dialog_end"] = nil
end

function add_map_spot(actor, npc, p)
	if(p[1]==nil) then
		printf("Story id for add map spot function is not set")
	else
		local story_id = tonumber(p[1])
		local id = id_by_sid(story_id)
		if(id==nil) then
			local obj = alife_object(p[1])
			id = obj and obj.id
		end
		if(id~=nil) then
			if(p[2]==nil) then
				p[2] = "primary_task_location"
			end
			if(p[3]==nil) then
				p[3] = "default"
			end
			if level.map_has_object_spot(id, p[2]) == 0 then
				level.map_add_object_spot_ser(id, p[2], p[3])
			end
		else
			printf("Wrong story id or name [%s] for map spot function", tostring(story_id))
		end
	end
end

function remove_map_spot(actor, npc, p)
	if(p[1]==nil) then
		printf("Story id for add map spot function is not set")
	else
		local story_id = tonumber(p[1])
		local id = id_by_sid(story_id)
		if(id==nil) then
			local obj = alife_object(p[1])
			id = obj and obj.id
		end
		if(id~=nil) then
			if(p[2]==nil) then
				p[2] = "primary_task_location"
			end
			if level.map_has_object_spot(id, p[2]) ~= 0 then
				level.map_remove_object_spot(id, p[2])
			end
		else
			printf("Wrong story id or name [%s] for map spot function", tostring(story_id))
		end
	end
end
]]--

-- Anomal fields support
function enable_anomaly(actor, npc, p)
	if p[1] == nil then
		printf("Story id for enable_anomaly function is not set")
	end

	local obj = get_story_object(p[1])
	if not obj then
		printf("There is no object with story_id %s for enable_anomaly function", tostring(p[1]))
	end
	obj:enable_anomaly()
end

function disable_anomaly(actor, npc, p)
	if p[1] == nil then
		printf("Story id for disable_anomaly function is not set")
	end

	local obj = get_story_object(p[1])
	if not obj then
		printf("There is no object with story_id %s for disable_anomaly function", tostring(p[1]))
	end
	obj:disable_anomaly()
end

function launch_signal_rocket(actor, obj, p)
	if p==nil then
		printf("Signal rocket name is not set!")
	end
	if db.signal_light[p[1]] then
		db.signal_light[p[1]]:launch()
	else
		printf("No such signal rocket: [%s] on level", tostring(p[1]))
	end
end

--[[
function reset_faction_goodwill(actor, obj, p)
	if db.actor and p[1] then
		local board = SIMBOARD
		local faction = board.players[ p[1] ]
		if faction then
			db.actor:set_community_goodwill(p[1], 0)
		end
	end
end
]]--

function add_cs_text(actor, npc, p)
	if p[1] then
		local hud = get_hud()
		if (hud) then
			local cs_text = hud:GetCustomStatic("text_on_screen_center")
			if cs_text then
				hud:RemoveCustomStatic("text_on_screen_center")
			end
			hud:AddCustomStatic("text_on_screen_center", true)
			cs_text = hud:GetCustomStatic("text_on_screen_center")
			cs_text:wnd():TextControl():SetText(game.translate_string(p[1]))
		end
	end
end

function del_cs_text(actor, npc, p)
	local hud = get_hud()
	if (hud) then
		cs_text = hud:GetCustomStatic("text_on_screen_center")
		if cs_text then
			hud:RemoveCustomStatic("text_on_screen_center")
		end
	end
end

function spawn_item_to_npc(actor, npc, p)
	local new_item = p[1]
	if p[1] then
		alife():create(new_item,
		npc:position(),
		npc:level_vertex_id(),
		npc:game_vertex_id(),
		npc:id())
	end
end

function give_money_to_npc(actor, npc, p)
	local money = p[1]
	if p[1] then
		npc:give_money(money)
	end
end

function seize_money_to_npc(actor, npc, p)
	local money = p[1]
	if p[1] then
		npc:give_money(-money)
	end
end

-- �������� �������� �� ������ � ������
-- relocate_item(item_name:story_id_from:story_id_to)
function relocate_item(actor, npc, p)
	local item = p and p[1]
	local from_obj = p and get_story_object(p[2])
	local to_obj = p and get_story_object(p[3])
	if to_obj ~= nil then
		if from_obj ~= nil and from_obj:object(item) ~= nil then
			from_obj:transfer_item(from_obj:object(item), to_obj)
		else
			alife():create(item,
				to_obj:position(),
				to_obj:level_vertex_id(),
				to_obj:game_vertex_id(),
				to_obj:id())
		end
	else
		printf("Couldn't relocate item to NULL")
	end
end

-- ������� ������ �������, ���������� ��� ������ set_squads_enemies(squad_name_1:squad_name_2)
function set_squads_enemies(actor, npc, p)
	if (p[1] == nil or p[2] == nil) then
		printf("Wrong parameters in function set_squad_enemies")
		return
	end

	local squad_1 = get_story_squad(p[1])
	local squad_2 = get_story_squad(p[2])

	if squad_1 == nil then
		assert("There is no squad with id[%s]", tostring(p[1]))
		return
	end
	if squad_2 == nil then
		assert("There is no squad with id[%s]", tostring(p[2]))
		return
	end

 	for k in squad_1:squad_members() do
		local npc_obj_1 = db.storage[k.id] and db.storage[k.id].object
		if npc_obj_1 ~= nil then
			for kk in squad_2:squad_members() do
				local npc_obj_2 = db.storage[kk.id] and db.storage[kk.id].object
				if npc_obj_2 ~= nil then
					npc_obj_1:set_relation(game_object.enemy, npc_obj_2)
					npc_obj_2:set_relation(game_object.enemy, npc_obj_1)
					printf("set_squads_enemies: %d:set_enemy(%d)", npc_obj_1:id(), npc_obj_2:id())
				end
			end
		end
	end
end

local particles_table = {
[1] = {particle = particles_object("anomaly2\\teleport_out_00"), sound = sound_object("anomaly\\teleport_incoming")},
[2] = {particle = particles_object("anomaly2\\teleport_out_00"), sound = sound_object("anomaly\\teleport_incoming")},
[3] = {particle = particles_object("anomaly2\\teleport_out_00"), sound = sound_object("anomaly\\teleport_incoming")},
[4] = {particle = particles_object("anomaly2\\teleport_out_00"), sound = sound_object("anomaly\\teleport_incoming")},
}

function jup_b16_play_particle_and_sound(actor, npc, p)
	particles_table[p[1]].particle :play_at_pos(patrol(npc:name().."_particle"):point(0))
	--particles_table[p[1]].sound    :play_at_pos(actor, patrol(npc:name().."_particle"):point(0), 0, sound_object.s3d)
end
--������� ��������� ��������� ��������� ���������.
-- ��������� ����� ���������� --> story_id:visibility_state(����� �������� ������ ������) ��� visibility_state(���� ���������� �� ���������� ���������)
--  visibility_state -->
--						0 - ���������
--						1 - �����������
--						2 - ��������� �������
function set_bloodsucker_state(actor, npc, p)
	if (p and p[1]) == nil then printf("Wrong parameters in function 'set_bloodsucker_state'!!!") end
	local state = p[1]
	if p[2] ~= nil then
		state = p[2]
		npc = get_story_object(p[1])
	end
	if npc ~= nil then
		if state == "default" then
			npc:force_visibility_state(-1)
		else
			npc:force_visibility_state(tonumber(state))
		end
	end
end

--������� ������� �������� � ������������ �����, ������ ��� ����� �57
function drop_object_item_on_point(actor, npc, p)
	local drop_object = db.actor:object(p[1])
	local drop_point  = patrol(p[2]):point(0)
	db.actor:drop_item_and_teleport(drop_object, drop_point)
end

--������� ������� �������� � ������
function remove_item(actor, npc, p)
	local sec = p[1]
	if not (sec) then
		printf("Wrong parameters in function 'remove_item'!!!")
		return
	end
	local amt = p[2] and tonumber(p[2]) or 1
	local removed = 0
	local sim = alife()
	local se_item
	local function release_actor_item(temp, item)
		if (item:section() == sec and amt > 0) then
			se_item = sim:object(item:id())
			if (se_item) then
				sim:release(se_item,true)
				amt = amt - 1
				removed = removed + 1
			end
		end
	end
	db.actor:iterate_inventory(release_actor_item,nil)
	if (removed > 0) then
		news_manager.relocate_item(db.actor,"out",sec,removed)
	end
end

-- �������� ���������� � ������ ������
function scenario_autosave(actor, npc, p)
	local save_name = p[1]
	if save_name == nil then
		printf("You are trying to use scenario_autosave without save name")
	end

	-- clear excess corpses everytime player saves
	--release_body_manager.get_release_body_manager():clear()

	if IsImportantSave() then
		local prefix = axr_misery and axr_misery.ActorClass or user_name()
		local save_param = prefix.." - "..game.translate_string(save_name)

		get_console():execute("save "..save_param)
	end
end

function zat_b29_create_random_infop(actor, npc, p)
	if p[2] == nil then
		printf("Not enough parameters for zat_b29_create_random_infop!")
	end

	local amount_needed = p[1]
	local current_infop = 0
	local total_infop = 0

	if (not amount_needed or amount_needed == nil) then
		amount_needed = 1
	end

	for k,v in pairs(p) do
		if k > 1 then
			total_infop = total_infop + 1
			disable_info(v)
		end
	end

	if amount_needed > total_infop then
		amount_needed = total_infop
	end

	for i = 1, amount_needed do
		current_infop = math.random(1, total_infop)
		for k,v in pairs(p) do
			if k > 1 then
				if (k == current_infop + 1 and (not has_alife_info(v))) then
					db.actor:give_info_portion(v)
					break
				end
			end
		end
	end
end

function give_item_b29(actor, npc, p)
--	local story_object = p and get_story_object(p[1])
	local az_name
	local az_table = {
						"zat_b55_anomal_zone",
						"zat_b54_anomal_zone",
						"zat_b53_anomal_zone",
						"zat_b39_anomal_zone",
						"zaton_b56_anomal_zone",
						}

	for i = 16, 23 do
		if has_alife_info(dialogs_zaton.zat_b29_infop_bring_table[i]) then
			for k,v in pairs(az_table) do
				if has_alife_info(v) then
					az_name = v
					disable_info(az_name)
					break
				end
			end
			pick_artefact_from_anomaly(nil, nil, {p[1], az_name, dialogs_zaton.zat_b29_af_table[i]})
			break
		end
	end
end

function relocate_item_b29(actor, npc, p)
	local item
	for i = 16, 23 do
		if has_alife_info(dialogs_zaton.zat_b29_infop_bring_table[i]) then
			item = dialogs_zaton.zat_b29_af_table[i]
			break
		end
	end
	local from_obj = p and get_story_object(p[1])
	local to_obj = p and get_story_object(p[2])
	if to_obj ~= nil then
		if from_obj ~= nil and from_obj:object(item) ~= nil then
			from_obj:transfer_item(from_obj:object(item), to_obj)
		else
			alife():create(item,
				to_obj:position(),
				to_obj:level_vertex_id(),
				to_obj:game_vertex_id(),
				to_obj:id())
		end
	else
		printf("Couldn't relocate item to NULL")
	end
end

-- ������� ������� ���������� �������� ���� � ������. by peacemaker, hein, redstain
function reset_sound_npc(actor, npc, p)
	local obj_id = npc:id()
	if obj_id and xr_sound.sound_table and xr_sound.sound_table[obj_id] then
		xr_sound.sound_table[obj_id]:reset(obj_id)
	end
end

function jup_b202_inventory_box_relocate(actor, npc)
	local inv_box_out = get_story_object("jup_b202_actor_treasure")
	local inv_box_in = get_story_object("jup_b202_snag_treasure")
	local items_to_relocate = {}
	local function relocate(inv_box_out, item)
		table.insert(items_to_relocate, item)
	end
	inv_box_out:iterate_inventory_box	(relocate, inv_box_out)
	for k,v in pairs(items_to_relocate) do
		inv_box_out:transfer_item(v, inv_box_in)
	end
end

function clear_box(actor, npc, p)
	if (p and p[1]) == nil then printf("Wrong parameters in function 'clear_box'!!!") end

	local inv_box = get_story_object(p[1])

	if inv_box == nil then
		printf("There is no object with story_id [%s]", tostring(p[1]))
	end

	local items_table = {}

	local function add_items(inv_box, item)
		table.insert(items_table, item)
	end

	inv_box:iterate_inventory_box(add_items, inv_box)

	for k,v in pairs(items_table) do
		alife():release(alife_object(v:id()), true)
	end
end

function activate_weapon(actor, npc, p)
	local object = actor:object(p[1])
	if object == nil then
		assert("Actor has no such weapon! [%s]", p[1])
	end
	if object ~= nil then
		actor:make_item_active(object)
	end
end

function set_game_time(actor, npc, p)
	local real_hours = level.get_time_hours()
	local real_minutes = level.get_time_minutes()
	local hours = tonumber(p[1])
	local minutes = tonumber(p[2])
	if p[2] == nil then
		minutes = 0
	end
	local hours_to_change = hours - real_hours
	if hours_to_change <= 0 then
		hours_to_change = hours_to_change + 24
	end
	local minutes_to_change = minutes - real_minutes
	if minutes_to_change <= 0 then
		minutes_to_change = minutes_to_change + 60
		hours_to_change = hours_to_change - 1
	elseif hours == real_hours then
		hours_to_change = hours_to_change - 24
	end
	level.change_game_time(0,hours_to_change,minutes_to_change)
	level_weathers.get_weather_manager():forced_weather_change()
	surge_manager.SurgeManager.time_forwarded = true
	printf("set_game_time: time changed to [%d][%d]", hours_to_change, minutes_to_change)
end

function forward_game_time(actor, npc, p)
	if not p then
		printf("Insufficient or invalid parameters in function 'forward_game_time'!")
	end

	local hours = tonumber(p[1])
	local minutes = tonumber(p[2])

	if p[2] == nil then
		minutes = 0
	end
	level.change_game_time(0,hours,minutes)
	level_weathers.get_weather_manager():forced_weather_change()
	surge_manager.SurgeManager.time_forwarded = true
	printf("forward_game_time: time forwarded on [%d][%d]", hours, minutes)
end

function stop_tutorial()
	printf("stop tutorial called")
	game.stop_tutorial()
end

function jup_b10_spawn_drunk_dead_items(actor, npc, p)
	local items_all = {
					["wpn_ak74"] = 1,
					["ammo_5.45x39_fmj"] = 5,
					["ammo_5.45x39_ap"] = 3,
					["wpn_fort"] = 1,
					["ammo_9x18_fmj"] = 3,
					["ammo_12x70_buck"] = 5,
					["ammo_11.43x23_hydro"] = 2,
					["grenade_rgd5"] = 3,
					["grenade_f1"] = 2,
					["medkit_army"] = 2,
					["medkit"] = 4,
					["bandage"] = 4,
					["antirad"] = 2,
					["vodka"] = 3,
					["energy_drink"] = 2,
					["conserva"] = 1,
					["jup_b10_ufo_memory_2"] = 1,
					}

	local items = {
					[2] = 	{
							["wpn_sig550_nimble"] = 1,
							},
					[1] = 	{
							["ammo_5.45x39_fmj"] = 5,
							["ammo_5.45x39_ap"] = 3,
							["wpn_fort"] = 1,
							["ammo_9x18_fmj"] = 3,
							["ammo_12x70_buck"] = 5,
							["ammo_11.43x23_hydro"] = 2,
							["grenade_rgd5"] = 3,
							["grenade_f1"] = 2,
							},
					[0] = 	{
							["medkit_army"] = 2,
							["medkit"] = 4,
							["bandage"] = 4,
							["antirad"] = 2,
							["vodka"] = 3,
							["energy_drink"] = 2,
							["conserva"] = 1,
							},
					}

	if p and p[1] ~= nil then
		local cnt = utils.load_var(actor, "jup_b10_ufo_counter", 0)
		if cnt > 2 then return end
		for k,v in pairs(items[cnt]) do
			local target_obj_id = get_story_object_id(p[1])
			if target_obj_id ~= nil then
				box = alife_object(target_obj_id)
				if box == nil then
					printf("There is no such object %s", p[1])
				end
				for i = 1,v do
					alife():create(k,vector(),0,0,target_obj_id)
				end
			else
				printf("object is nil %s", tostring(p[1]))
			end
		end
	else
		for k,v in pairs(items_all) do
			for i = 1,v do
				alife():create(k,
					npc:position(),
					npc:level_vertex_id(),
					npc:game_vertex_id(),
					npc:id())
			end
		end
	end

end

function pick_artefact_from_anomaly(actor, npc, p)
	local se_obj
	local az_name = p and p[2]
	local af_name = p and p[3]
	local af_id
	local af_obj
	local anomal_zone = db.anomaly_by_name[az_name]

	if p and p[1] then
--		if p[1] == "actor" then
--			npc = db.actor
--		else
--			npc = get_story_object(p[1])
--		end

		local npc_id = get_story_object_id(p[1])
		if npc_id == nil then
			printf("Couldn't relocate item to NULL in function 'pick_artefact_from_anomaly!'")
		end
		se_obj = alife_object(npc_id)
		if se_obj and (not IsStalker(nil,se_obj:clsid()) or not se_obj:alive()) then
			printf("Couldn't relocate item to NULL (dead or not stalker) in function 'pick_artefact_from_anomaly!'")
		end
	end

	if anomal_zone == nil then
		printf("No such anomal zone in function 'pick_artefact_from_anomaly!'")
	end

	if anomal_zone.spawned_count < 1 then
		printf("No artefacts in anomal zone [%s]", az_name)
		return
	end

	for k,v in pairs(anomal_zone.artefact_ways_by_id) do
		if alife_object(tonumber(k)) and af_name == alife_object(tonumber(k)):section_name() then
			af_id = tonumber(k)
			af_obj = alife_object(tonumber(k))
			break
		end
		if af_name == nil then
			af_id = tonumber(k)
			af_obj = alife_object(tonumber(k))
			af_name = af_obj:section_name()
			break
		end
	end

	if af_id == nil then
		printf("No such artefact [%s] found in anomal zone [%s]", tostring(af_name), az_name)
		return
	end

	anomal_zone:on_artefact_take(af_obj)

	alife():release(af_obj, true)
	give_item(db.actor, se_obj, {af_name, p[1]})
--	alife():create(af_name,
--		npc.position,
--		npc.level_vertex_id,
--		npc.game_vertex_id,
--		npc.id)
end

function anomaly_turn_off (actor, npc, p)
	local anomal_zone = db.anomaly_by_name[p[1]]
	if anomal_zone == nil then
		printf("No such anomal zone in function 'anomaly_turn_off!'")
	end
	anomal_zone:turn_off()
end

function anomaly_turn_on (actor, npc, p)
	local anomal_zone = db.anomaly_by_name[p[1]]
	if anomal_zone == nil then
		printf("No such anomal zone in function 'anomaly_turn_on!'")
	end
	if p[2] then
		anomal_zone:turn_on(true)
	else
		anomal_zone:turn_on(false)
	end
end

function zat_b202_spawn_random_loot(actor, npc, p)
	local si_table = {}
	si_table[1] = {
		[1] = {item = {"bandage","bandage","bandage","bandage","bandage","medkit","medkit","medkit","conserva","conserva"}},
		[2] = {item = {"medkit","medkit","medkit","medkit","medkit","vodka","vodka","vodka","kolbasa","kolbasa"}},
		[3] = {item = {"antirad","antirad","antirad","medkit","medkit","bandage","kolbasa","kolbasa","conserva"}},
	}
	si_table[2] = {
		[1] = {item = {"grenade_f1","grenade_f1","grenade_f1"}},
		[2] = {item = {"grenade_rgd5","grenade_rgd5","grenade_rgd5","grenade_rgd5","grenade_rgd5"}}
	}
	si_table[3] = {
		[1] = {item = {"detector_elite"}},
		[2] = {item = {"detector_advanced"}}
	}
	si_table[4] = {
		[1] = {item = {"helm_hardhat"}},
		[2] = {item = {"helm_respirator"}}
	}
	si_table[5] = {
		[1] = {item = {"wpn_val","ammo_9x39_ap","ammo_9x39_ap","ammo_9x39_ap"}},
		[2] = {item = {"wpn_spas12","ammo_12x70_buck","ammo_12x70_buck","ammo_12x70_buck","ammo_12x70_buck"}},
		[3] = {item = {"wpn_desert_eagle","ammo_11.43x23_fmj","ammo_11.43x23_fmj","ammo_11.43x23_hydro","ammo_11.43x23_hydro"}},
		[4] = {item = {"wpn_abakan","ammo_5.45x39_ap","ammo_5.45x39_ap"}},
		[5] = {item = {"wpn_sig550","ammo_5.56x45_ap","ammo_5.56x45_ap"}},
		[6] = {item = {"wpn_ak74","ammo_5.45x39_fmj","ammo_5.45x39_fmj"}},
		[7] = {item = {"wpn_l85","ammo_5.56x45_ss190","ammo_5.56x45_ss190"}}
	}
	si_table[6] = {
		[1] = {item = {"specops_outfit"}},
		[2] = {item = {"stalker_outfit"}}
	}
	weight_table = {}
	weight_table[1] = 2
	weight_table[2] = 2
	weight_table[3] = 2
	weight_table[4] = 2
	weight_table[5] = 4
	weight_table[6] = 4
	local spawned_item = {}
	local max_weight = 12
	repeat
		local n = 0
		repeat
			n = math.random(1, #weight_table)
			local prap = true
			for k,v in pairs(spawned_item) do
				if v == n then
					prap = false
					break
				end
			end
		until (prap) and ((max_weight - weight_table[n]) >= 0)
		max_weight = max_weight - weight_table[n]
		table.insert(spawned_item,n)
		local item = math.random(1, #si_table[n])
		for k,v in pairs(si_table[n][item].item) do
			spawn_object_in(actor, npc, {tostring(v),"jup_b202_snag_treasure"})
		end
	until max_weight <= 0
end

function zat_a1_tutorial_end_give(actor, npc)
--	level.add_pp_effector("black.ppe", 1313, true) ---do not stop on r1 !
	db.actor:give_info_portion("zat_a1_tutorial_end")
end

function oasis_heal()
	local d_health = 0.005
	local d_power = 0.01
	local d_bleeding = 0.05
	local d_radiation = -0.05
	if(db.actor.health<1) then
		db.actor.health = d_health
	end
	if(db.actor.power<1) then
		db.actor.power = d_power
	end
	if(db.actor.radiation>0) then
		db.actor.radiation = d_radiation
	end
	if(db.actor.bleeding>0) then
		db.actor.bleeding = d_bleeding
	end
		db.actor.satiety = 0.01
end

--������� ��������� ������ ���� ��������, ������������ ��� ����� ���������� �����������. ��������� �������� [duty, freedom]
function jup_b221_play_main(actor, npc, p)
	local info_table = {}
	local main_theme
	local reply_theme
	local info_need_reply
	local reachable_theme = {}
	local theme_to_play = 0

	if (p and p[1]) == nil then
		printf("No such parameters in function 'jup_b221_play_main'")
	end
--���������� ������� ������������ ������������ ����������� ��� ��� ���� ����, ���������� �������� ����, ������ � �������, �������������� ��� ����� ��� ��� �������.
	if tostring(p[1]) == "duty" then
		info_table = {
			[1] = "jup_b25_freedom_flint_gone",
			[2] = "jup_b25_flint_blame_done_to_duty",
			[3] = "jup_b4_monolith_squad_in_duty",
			[4] = "jup_a6_duty_leader_bunker_guards_work",
			[5] = "jup_a6_duty_leader_employ_work",
			[6] = "jup_b207_duty_wins"
		}
		main_theme = "jup_b221_duty_main_"
		reply_theme = "jup_b221_duty_reply_"
		info_need_reply = "jup_b221_duty_reply"
	elseif tostring(p[1]) == "freedom" then
		info_table = {
			[1] = "jup_b207_freedom_know_about_depot",
			[2] = "jup_b46_duty_founder_pda_to_freedom",
			[3] = "jup_b4_monolith_squad_in_freedom",
			[4] = "jup_a6_freedom_leader_bunker_guards_work",
			[5] = "jup_a6_freedom_leader_employ_work",
			[6] = "jup_b207_freedom_wins"
		}
		main_theme = "jup_b221_freedom_main_"
		reply_theme = "jup_b221_freedom_reply_"
		info_need_reply = "jup_b221_freedom_reply"
	else
		printf("Wrong parameters in function 'jup_b221_play_main'")
	end
--���������� ������� ��������� ���(����� ������ ���).
	for k,v in pairs(info_table) do
		if (has_alife_info(v)) and (not has_alife_info(main_theme .. tostring(k) .. "_played")) then
			table.insert(reachable_theme,k)
--			printf("jup_b221_play_main: table reachable_theme ------------------------------> [%s]", tostring(k))
		end
	end
--���� ������� ��������� ��� ����� ������ �����. ���� �� ��� �� ����� ������ �������� ����. ���� ������ �������� ���� ������� �������� �������� ��� ���������� ���������� �������. ���� �������� �� �������.
	if #reachable_theme ~= 0 then
		disable_info(info_need_reply)
		theme_to_play = reachable_theme[math.random(1, #reachable_theme)]
--		printf("jup_b221_play_main: variable theme_to_play ------------------------------> [%s]", tostring(theme_to_play))
		utils.save_var(actor,"jup_b221_played_main_theme",tostring(theme_to_play))
		db.actor:give_info_portion(main_theme .. tostring(theme_to_play) .."_played")
		if theme_to_play ~= 0 then
			play_sound(actor, npc, {main_theme .. tostring(theme_to_play)})
		else
			printf("No such theme_to_play in function 'jup_b221_play_main'")
		end
	else
		db.actor:give_info_portion(info_need_reply)
		theme_to_play = tonumber(utils.load_var(actor,"jup_b221_played_main_theme",0))
		if theme_to_play ~= 0 then
			play_sound(actor, npc, {reply_theme..tostring(theme_to_play)})
		else
			printf("No such theme_to_play in function 'jup_b221_play_main'")
		end
		utils.save_var(actor,"jup_b221_played_main_theme","0")
	end
end

function pas_b400_play_particle(actor, npc, p)
	db.actor:start_particles("zones\\zone_acidic_idle","bip01_head")
end

function pas_b400_stop_particle(actor, npc, p)
	db.actor:stop_particles("zones\\zone_acidic_idle","bip01_head")
end

function damage_actor_items_on_start(actor, npc)
end

function damage_actor_items()

	printf("-STARTING ITEMS")

	local function damage_items(actor,itm)
		printf(itm:section())
		if IsWeapon(itm) and (itm:section() ~= "wpn_binoc_inv") then
			itm:set_condition(math.random(78,81)/100)
			items_condition.break_weapon(itm)
		elseif IsOutfit(itm) then
			itm:set_condition(math.random(86,89)/100)
		end
	end
	db.actor:iterate_inventory(damage_items,db.actor)
end

function pri_a17_hard_animation_reset(actor, npc, p)
	--db.storage[npc:id()].state_mgr:set_state("pri_a17_fall_down", nil, nil, nil, {fast_set = true})
	db.storage[npc:id()].state_mgr:set_state("pri_a17_fall_down")

	local state_mgr = db.storage[npc:id()].state_mgr
	if state_mgr ~= nil then
		state_mgr.animation:set_state(nil, true)
		state_mgr.animation:set_state("pri_a17_fall_down")
		state_mgr.animation:set_control()
	end
end

function jup_b217_hard_animation_reset(actor, npc, p)
	db.storage[npc:id()].state_mgr:set_state("jup_b217_nitro_straight")

	local state_mgr = db.storage[npc:id()].state_mgr
	if state_mgr ~= nil then
		state_mgr.animation:set_state(nil, true)
		state_mgr.animation:set_state("jup_b217_nitro_straight")
		state_mgr.animation:set_control()
	end
end




function sleep(actor, npc)
	local sleep_zones = {
						"actor_surge_hide_2",
						"agr_army_sleep",
						"agr_sr_sleep_tunnel",
						"agr_sr_sleep_wagon",
						"bar_actor_sleep_zone",
						"cit_merc_sleep",
						"ds_farmhouse_sleep",
						"esc_basement_sleep_area",
						"esc_secret_sleep",
						"gar_angar_sleep",
						"gar_dolg_sleep",
						"jup_a6_sr_sleep",
						"mar_a3_sr_sleep",
						"mil_freedom_sleep",
						"mil_smart_terran_2_4_sleep",
						"pri_a16_sr_sleep",
						"pri_monolith_sleep",
						"pri_room27_sleep",
						"rad_sleep_room",
						"ros_vagon_sleep",
						"val_abandoned_house_sleep",
						"val_vagon_sleep",
						"yan_bunker_sleep_restrictor",
						"zat_a2_sr_sleep"
					}

	for k,v in pairs(sleep_zones) do
		if utils.npc_in_zone(db.actor, v) then
			ui_sleep_dialog.sleep()
			give_info("sleep_active")
		end
	end

end



--[[
function set_tip_to_story(actor, npc, p)
	if p == nil or p[2] == nil then
		printf("Not enough parameters in 'set_tip_to_story' function!")
	end

	local obj = get_story_object(p[1])

	if not obj then
		return
	end

	local tip = p[2]

	obj:set_tip_text(tip)
end

function clear_tip_from_story(actor, npc, p)
	if p == nil or p[1] == nil then
		printf("Not enough parameters in 'clear_tip_from_story' function!")
	end

	local obj = get_story_object(p[1])

	if not obj then
		return
	end

	obj:set_tip_text("")
end
]]--

function mech_discount(actor, npc, p)
	if(p[1]) then
		inventory_upgrades.mech_discount(tonumber(p[1]) or 1)
	end
end

function polter_actor_ignore(actor, npc, p)
	if p[1] and p[1] == "true" then
				npc:poltergeist_set_actor_ignore(true)
	elseif p[1] and p[1] == "false" then
				npc:poltergeist_set_actor_ignore(false)
	end
end

function burer_force_gravi_attack(actor, npc)
	npc:burer_set_force_gravi_attack(true)
end

function burer_force_anti_aim(actor, npc)
	npc:set_force_anti_aim(true)
end

function show_freeplay_dialog(actor, npc, p)
	if p[1] and p[2] and p[2] == "true" then
		ui_freeplay_dialog.show("message_box_yes_no", p[1])
	elseif p[1] then
		ui_freeplay_dialog.show("message_box_ok", p[1])
	end
end

-- ������ ��� state_mgr
function get_best_detector(npc)
	local detectors = {"detector_craft", "detector_simple", "detector_advanced", "detector_elite", "detector_scientific" }
	for k,v in pairs(detectors) do
		local obj = npc:object(v)
		if obj ~= nil then
			obj:enable_attachable_item(true)
			return
		end
	end
end

function hide_best_detector(npc)
	local detectors = {"detector_craft", "detector_simple", "detector_advanced", "detector_elite", "detector_scientific" }
	for k,v in pairs(detectors) do
		local obj = npc:object(v)
		if obj ~= nil then
			obj:enable_attachable_item(false)
			return
		end
	end
end

-- ���������� ��� ������������� �������� ��� � ������� ����������, � ��� ������ �����
function pri_a18_radio_start(actor, npc)
	db.actor:give_info_portion("pri_a18_radio_start")
end

function pri_a17_ice_climb_end(actor, npc)
	db.actor:give_info_portion("pri_a17_ice_climb_end")
end

function jup_b219_opening(actor, npc)
	db.actor:give_info_portion("jup_b219_opening")
end

function jup_b219_entering_underpass(actor, npc)
	db.actor:give_info_portion("jup_b219_entering_underpass")
end

function pri_a17_pray_start(actor, npc)
	db.actor:give_info_portion("pri_a17_pray_start")
end

function zat_b38_open_info(actor, npc)
	db.actor:give_info_portion("zat_b38_open_info")
end

function zat_b38_switch_info(actor, npc)
	db.actor:give_info_portion("zat_b38_switch_info")
end
function zat_b38_cop_dead(actor, npc)
	db.actor:give_info_portion("zat_b38_cop_dead")
end

function jup_b15_zulus_drink_anim_info(actor, npc)
	db.actor:give_info_portion("jup_b15_zulus_drink_anim_info")
end

function pri_a17_preacher_death(actor, npc)
	db.actor:give_info_portion("pri_a17_preacher_death")
end

function zat_b3_tech_surprise_anim_end(actor, npc)
	db.actor:give_info_portion("zat_b3_tech_surprise_anim_end")
end

function zat_b3_tech_waked_up(actor, npc)
	db.actor:give_info_portion("zat_b3_tech_waked_up")
end

function zat_b3_tech_drinked_out(actor, npc)
	db.actor:give_info_portion("zat_b3_tech_drinked_out")
end

function pri_a28_kirillov_hq_online(actor, npc)
	db.actor:give_info_portion("pri_a28_kirillov_hq_online")
end

function pri_a20_radio_start(actor, npc)
	db.actor:give_info_portion("pri_a20_radio_start")
end

function pri_a22_kovalski_speak(actor, npc)
	db.actor:give_info_portion("pri_a22_kovalski_speak")
end

function zat_b38_underground_door_open(actor, npc)
	db.actor:give_info_portion("zat_b38_underground_door_open")
end

function zat_b38_jump_tonnel_info(actor, npc)
	db.actor:give_info_portion("zat_b38_jump_tonnel_info")
end

function jup_a9_cam1_actor_anim_end(actor, npc)
	db.actor:give_info_portion("jup_a9_cam1_actor_anim_end")
end

function pri_a28_talk_ssu_video_end(actor, npc)
	db.actor:give_info_portion("pri_a28_talk_ssu_video_end")
end

function set_torch_state(actor, npc, p)
 	if p == nil or p[2] == nil then
		printf("Not enough parameters in 'set_torch_state' function!")
	end

	local obj = get_story_object(p[1])

	if not obj then
		return
	end
	local torch = obj:object("device_torch")
	if torch then
		if p[2] == "on" then
			torch:enable_attachable_item(true)
		elseif p[2] == "off" then
			torch:enable_attachable_item(false)
		end
	end
end


local actor_nightvision = false
local actor_torch		= false

function disable_actor_nightvision(actor, npc)
	local nightvision = db.actor:object("device_torch")
	if not (nightvision) then
		return
	end
	if nightvision:night_vision_enabled() then
		nightvision:enable_night_vision(false)
		actor_nightvision = true
	end
end

function enable_actor_nightvision(actor, npc)
	local nightvision = db.actor:object("device_torch")
	if not (nightvision) then
		return
	end
	if not nightvision:night_vision_enabled() and actor_nightvision then
		nightvision:enable_night_vision(true)
		actor_nightvision = false
	end
end

function disable_actor_torch(actor, npc)
	local torch = db.actor:object("device_torch")
	if not (torch) then
		return
	end
	if torch:torch_enabled() then
		torch:enable_torch(false)
		actor_torch = true
	end
end

function enable_actor_torch(actor, npc)
	local torch = db.actor:object("device_torch")
	if not (torch) then
		return
	end
	if not torch:torch_enabled() and actor_torch then
		torch:enable_torch(true)
		actor_torch = false
	end
end


function create_cutscene_actor_with_weapon(actor, npc, p)
	--' p[1] - ������ ���� ��������
	--' p[2] - ��� ����������� ���� ��� ��������.
	--' p[3] - ����� ����������� ����
	--' p[4] - ������� �� ��� Y
	--' p[5] - �������������� ���� - ����� �������� ���� ��� disable_ui
	local spawn_sect = p[1]
	if spawn_sect == nil then
		printf("Wrong spawn section for 'spawn_object' function %s. For object %s", tostring(spawn_sect), obj:name())
	end

	local path_name = p[2]
	if path_name == nil then
		printf("Wrong path_name for 'spawn_object' function %s. For object %s", tostring(path_name), obj:name())
	end

	if not level.patrol_path_exists(path_name) then
		printf("Path %s doesnt exist. Function 'spawn_object' for object %s ", tostring(path_name), obj:name())
	end
	local ptr = patrol(path_name)
	local index = p[3] or 0
	local yaw = p[4] or 0

	local npc = alife():create(spawn_sect, ptr:point(index), ptr:level_vertex_id(0), ptr:game_vertex_id(0))
	if IsStalker( nil, npc:clsid()) then
		npc:o_torso().yaw = yaw * math.pi / 180
	else
		npc.angle.y = yaw * math.pi / 180
	end

	local slot_override = p[5] or 0

	local slot
	local active_item

	if slot_override == 0 then
		slot = db.actor:active_slot()
		if(slot~=2 and slot~=3) then
			return
		end
		active_item = db.actor:active_item()
	else
		if db.actor:item_in_slot(slot_override) ~= nil then
			active_item = db.actor:item_in_slot(slot_override)
		else
			if db.actor:item_in_slot(3) ~= nil then
				active_item = db.actor:item_in_slot(3)
			elseif db.actor:item_in_slot(2) ~= nil then
				active_item = db.actor:item_in_slot(2)
			else
				return
			end
		end
	end

	local actor_weapon = alife_object(active_item:id())
	local section_name = actor_weapon:section_name()

	if (active_item) then
		local new_weapon = alife():create(section_name,
													ptr:point(index),
													ptr:level_vertex_id(0),
													ptr:game_vertex_id(0),
													npc.id)
		if section_name ~= "wpn_gauss" then
			new_weapon:clone_addons(actor_weapon)
		end
	end
end

-- ��������� ������ ���������� �������� ���(� ���������)
function set_force_sleep_animation(actor, npc, p)
	local num = p[1]
	npc:force_stand_sleep_animation(tonumber(num))
end
-- ������ ���������� �������� ���(� ���������)
function release_force_sleep_animation(actor, npc)
	npc:release_stand_sleep_animation()
end

function zat_b33_pic_snag_container(actor, npc)
	if xr_conditions.actor_in_zone(actor, npc, {"zat_b33_tutor"}) then
		give_actor(actor, npc, {"zat_b33_safe_container"})
		db.actor:give_info_portion("zat_b33_find_package")
		if not has_alife_info("zat_b33_safe_container") then
			local zone = db.zone_by_name["zat_b33_tutor"]
			play_sound(actor, zone, {"pda_news"})
		end
	end
end

--���������� ����������� ���������� ��� �� ��������� ��������� ����� �� ���� ������.
--���. ������ �� ������ ���.
function set_visual_memory_enabled(actor, npc, p)
	if (p and p[1]) and (tonumber(p[1]) >= 0) and (tonumber(p[1]) <= 1) then
		local boolval = false
		if (tonumber(p[1]) == 1) then
			boolval = true
		end
		npc:set_visual_memory_enabled(boolval)
	end
end

function disable_memory_object (actor, npc)
	local best_enemy = npc:best_enemy()
	if best_enemy then
		npc:enable_memory_object(best_enemy, false)
	end
end

function zat_b202_spawn_b33_loot(actor, npc, p)
	local info_table = {
		"zat_b33_first_item_gived",
		"zat_b33_second_item_gived",
		"zat_b33_third_item_gived",
		"zat_b33_fourth_item_gived",
		"zat_b33_fifth_item_gived"
	}
	local item_table = {}
	item_table[1] = {
		"wpn_fort_snag"
	}
	item_table[2] = {
		"medkit_scientic",
		"medkit_scientic",
		"medkit_scientic",
		"antirad",
		"antirad",
		"antirad",
		"bandage",
		"bandage",
		"bandage",
		"bandage",
		"bandage"
	}
	item_table[3] = {
		"wpn_ak74u_snag"
	}
	item_table[4] = {
		"af_soul"
	}
	for k,v in pairs(info_table) do
		local obj_id
		if (k == 1) or (k == 3) then
			obj_id = "jup_b202_stalker_snag"
		else
			obj_id = "jup_b202_snag_treasure"
		end
		if not has_alife_info(tostring(v)) then
			for l,m in pairs(item_table[k]) do
--				printf("zat_b202_spawn_b33_loot: number [%s] item [%s] to [%s]", tostring(k), tostring(m), tostring(obj_id))
				spawn_object_in(actor, npc, {tostring(m),tostring(obj_id)})
			end
		end
	end
end

function set_monster_animation (actor, npc, p)
	if not (p and p[1]) then
		printf("Wrong parameters in function 'set_monster_animation'!!!")
	end
	npc:set_override_animation (p[1])
end

function clear_monster_animation (actor, npc)
	npc:clear_override_animation ()
end

local actor_position_for_restore
local actor_direction_for_restore

function save_actor_position()
	actor_position_for_restore = get_story_object("actor"):position()
	--actor_direction_for_restore = get_story_object("actor"):direction()
end

function restore_actor_position()
	--db.actor:set_actor_direction(actor_direction_for_restore)
	db.actor:set_actor_position(actor_position_for_restore)
end

function upgrade_hint(actor, npc, p)
	if(p) then
		inventory_upgrades.cur_hint = p
	end
end

function force_obj(actor, npc, p)
	local obj = get_story_object(p[1])
	if not obj then
		printf("'force_obj' Target object does not exist")
		return
	end
	if p[2] == nil then p[2] = 20 end
	if p[3] == nil then p[3] = 100 end
	obj:set_const_force(vector():set(0,1,0), p[2], p[3])
end

function pri_a28_check_zones()
	local story_obj_id
	local dist
	local index = 0

	local zones_tbl = {
						[1] = "pri_a28_sr_mono_add_1",
						[2] = "pri_a28_sr_mono_add_2",
						[3] = "pri_a28_sr_mono_add_3",
						}

	local info_tbl = {
						[1] = "pri_a28_wave_1_spawned",
						[2] = "pri_a28_wave_2_spawned",
						[3] = "pri_a28_wave_3_spawned",
						}

	local squad_tbl = {
						[1] = "pri_a28_heli_mono_add_1",
						[2] = "pri_a28_heli_mono_add_2",
						[3] = "pri_a28_heli_mono_add_3",
						}

	for k,v in pairs(zones_tbl) do
		story_obj_id = get_story_object_id(v)
		if story_obj_id then
			local se_obj = alife_object(story_obj_id)
			local curr_dist = se_obj.position:distance_to(db.actor:position())
			if index == 0 then
				dist = curr_dist
				index = k
			elseif dist < curr_dist then
				dist = curr_dist
				index = k
			end
		end
	end

	if index == 0 then
		printf("Found no distance or zones in func 'pri_a28_check_zones'")
	end

	if has_alife_info(info_tbl[index]) then
		for k,v in pairs(info_tbl) do
			if not has_alife_info(info_tbl[k]) then
				db.actor:give_info_portion(info_tbl[k])
			end
		end
	else
		db.actor:give_info_portion(info_tbl[index])
	end

	create_squad(db.actor,nil,{squad_tbl[index],"pri_a28_heli"})
end

function eat_vodka_script()
	if db.actor:object("vodka_script") ~= nil then
		db.actor:eat(db.actor:object("vodka_script"))
	end
end

local mat_table = {
					"jup_b200_material_1",
					"jup_b200_material_2",
					"jup_b200_material_3",
					"jup_b200_material_4",
					"jup_b200_material_5",
					"jup_b200_material_6",
					"jup_b200_material_7",
					"jup_b200_material_8",
					"jup_b200_material_9",
					}

function jup_b200_count_found(actor)
	local cnt = 0

	for k,v in pairs(mat_table) do
		local material_obj = get_story_object(v)
		if material_obj then
			local parent = material_obj:parent()
			if parent then
				local parent_id = parent:id()
				if parent_id ~= 65535 and parent_id == actor:id() then
					cnt = cnt + 1
				end
			end
		end
	end

	cnt = cnt + utils.load_var(actor, "jup_b200_tech_materials_brought_counter", 0)
	utils.save_var(actor, "jup_b200_tech_materials_found_counter", cnt)
end

function sr_teleport(actor,npc,p)
	ui_sr_teleport.msg_box_ui(npc,p and p[1],p and p[2])
end

function make_a_wish(actor,npc,p)


	-- ///////////////////////////////////////////////////////////////////////////////////////////////
	--
	-- End Find Wish Granter Storyline Task
	--
	--	Added by DoctorX
	--	for DoctorX Questlines 1.6
	--	October 13, 2016
	--
	-- -----------------------------------------------------------------------------------------------

	-- Remove on find wish granter infoportion:
	disable_info( "drx_sl_on_find_wish_granter" )

	-- \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\


	local action_list = {}

	action_list[1] = function()
		error(game.translate_string("st_wish_granted"),2)
		return
	end

	action_list[2] = function()
		give_info("actor_made_wish")
		give_info("actor_made_wish_for_control")
		return
	end

	action_list[3] = function()
		local sim = alife()
		local function remove_this_squad(id)
			local squad = id and sim:object(id)
			if not (squad) then
				return true
			end

			printf("DEBUG: removing squad %s from the game",squad:name())
			SIMBOARD:assign_squad_to_smart(squad, nil)
			squad:remove_squad()
			return true
		end
		local squad
		for i=1,65534 do
			squad = sim:object(i)
			if (squad and squad:clsid() == clsid.online_offline_group_s) then
				CreateTimeEvent(squad.id,"remove_this_squad",math.random(1,10),remove_this_squad,squad.id)
			end
		end
		give_info("actor_made_wish_for_peace")
		give_info("actor_made_wish")
		return
	end

	action_list[4] = function()
		local sim = alife()
		local sysini = system_ini()
--		local valid_ids = {[1] = true, [2] = true , [3] = true, [4] = true, [8] = true, [12] = true, [13] = true, [14] = true, [15] = true}
		local valid_ids = {[1] = true, [2] = true , [3] = true, [4] = true, [5] = true, [6] = true, [7] = true, [8] = true, [9] = true, [10] = true, [11] = true, [12] = true, [13] = true, [14] = true, [15] = true}
		for k,v in pairs(ui_debug_main.id_to_spawn_table) do
			if (valid_ids[k]) then
				local list = ui_debug_main.get_spawn_table(v)
				if (list) then
					for kk,vv in pairs(list) do
						if (sysini:section_exist(vv)) then
							sim:create(vv,vector(),0,0,0)
						end
					end
				end
			end
		end

		local function remove_backpack(id)
			local function itr(npc,itm)
				if (itm:section() == "itm_qr" or itm:section() == "itm_backpack") then
					local se_itm = alife_object(itm:id())
					if (se_itm) then
						alife():release(se_itm,true)
					end
					return
				end
			end
			db.actor:iterate_inventory(itr,db.actor)
		end

		CreateTimeEvent(0,"remove_backpack",1,remove_backpack,0)

		give_info("actor_made_wish_for_riches")
		give_info("actor_made_wish")
		return
	end

	action_list[5] = function()
		local se_actor = alife():actor()
		local data = stpk_utils.get_actor_data(se_actor)
		if (data) then
			data.specific_character = "actor_zombied"
			stpk_utils.set_actor_data(data,se_actor)
		end

		db.actor:set_character_community("actor_zombied", 0, 0)
		give_info("actor_made_wish_immortal")
		give_info("actor_made_wish")

--		local spawn_path = patrol("spawn_player_stalker")
--		if (spawn_path) then
--			local pos = spawn_path:point(0)
--			local lvid = spawn_path:level_vertex_id(0)
--			local gvid = spawn_path:game_vertex_id(0)
--			local gg = game_graph()
--			if (gvid and gg:valid_vertex_id(gvid)) then
--				ChangeLevel(pos,lvid,gvid,vector():set(0,0,0))
--			end
--		end

--		Teleports the player to a smashed open grave in the Great Swamp.
--		Goodwill is increased with the Monolith and Zombified faction to ensure they aren't hostile.
		inc_faction_goodwill_to_actor(db.actor, nil, {"monolith", 5000})
		inc_faction_goodwill_to_actor(db.actor, nil, {"zombied", 5000})
		ChangeLevel(vector():set(266.99, 0.00, -131.07), 310937, 181, vector():set(0,0,0))
		return
	end

	-- Hide and disable the immortality wish if actor is in Zombified or Monolith factions.
	if (character_community(db.actor) == "actor_zombied" or character_community(db.actor) == "actor_monolith") then
		action_list[5] = nil
		ui_dyn_msg_box.multi_choice(action_list,"st_wish_1","st_wish_2","st_wish_3","st_wish_4","st_wish_99")
	else
		ui_dyn_msg_box.multi_choice(action_list,"st_wish_1","st_wish_2","st_wish_3","st_wish_4","st_wish_5","st_wish_99")
	end

end

function clear_logic(actor,npc,p)
	local st = db.storage[npc:id()]
	st.ini_filename = "<customdata>"
	st.ini = xr_logic.get_customdata_or_ini_file(npc, st.ini_filename)
	st.active_section = nil
	st.active_scheme = nil
	st.section_logic = "logic"
	xr_logic.switch_to_section(npc,nil,nil)
end

function set_new_scheme_and_logic(actor,npc,p)
	local st = db.storage[npc:id()]
	st.ini_filename = ini_filename
	st.ini = ini_file(ini_filename)
	if not (st.ini) then
		printf("Error: set_new_scheme_and_logic: can't find ini %s",ini_filename)
		return
	end

	-- Set new section logic
	st.section_logic = logic

	-- Select new active section
	local new_section = section or xr_logic.determine_section_to_activate(npc, st.ini, st.section_logic)

	-- Switch to new section
	xr_logic.switch_to_section(npc, st.ini, new_section)
	st.overrides = xr_logic.cfg_get_overrides(st.ini, new_section, npc)
end

function set_script_danger(actor,npc,p)
	xr_danger.set_script_danger(npc,p and tonumber(p[1]) or 5000)
end

function spawn_npc_at_position(actor,npc,p)
	if not (p) then return end
	local pos = vector():set(tonumber(p[2]),tonumber(p[3]),tonumber(p[4]))
	alife():create(p[1],pos,p[5],p[6])
end

function kill_obj_on_job(actor,npc,p)
	local board = SIMBOARD
	local smart = p[1] and board and board.smarts_by_names[p[1]]
	local obj = smart and smart.npc_by_job_section["logic@"..p[2]]
	obj = obj and level.object_by_id(obj)
	if not obj or not obj:alive() then
		return false
	end
	local h = hit()

	h:bone("bip01_neck")
	h.power = 1
	h.impulse = 1
	h.direction = vector():sub(npc:position(), obj:position())
	h.draftsman = npc
	h.type = hit.wound
	obj:hit(h)
end

function obj_at_job_switch_section(actor,npc,p)
	local board = SIMBOARD
	local smart = p[1] and board and board.smarts_by_names[p[1]]
	local obj = smart and smart.npc_by_job_section["logic@"..p[2]]
	obj = obj and level.object_by_id(obj)
	if not obj or not obj:alive() then
		return
	end

	local st = db.storage[obj:id()]
	if not (st) then
		return
	end
	xr_logic.switch_to_section(obj, st.ini, p[3])
end

function change_visual(actor,npc,p)
	if (not axr_main) then
		return
	end
	local sobj = alife_object(npc:id())
	if not (sobj) then
		return
	end
	if (axr_main) then
		CreateTimeEvent(sobj.id,"update_visual",1,update_visual,sobj.id,p[1])
	end
end

function switch_offline(actor,npc,p)
	local se_obj = npc and alife_object(npc:id())
	if (se_obj and se_obj:can_switch_offline()) then
		se_obj:switch_offline()
	end
end

------------------- util functions
function update_visual(id,vis)
	local se_npc = id and alife_object(id)
	if not (se_npc) then
		return true
	end

	if (se_npc.online) then
		se_npc:switch_offline()
		return false
	end

	if not (vis) then
		return true
	end

	local data = stpk_utils.get_stalker_data(se_npc)
	if (data) then
		data.visual_name = vis
		stpk_utils.set_stalker_data(data,se_npc)
	end
	return true
end


function up_start()
	--up.up_objects_spawn()
	--up.up_stalkers_spawn()
end

function up_freeplay()
	--up.freeplay_clean_territory()
end

function stop_sr_cutscene(actor,npc,p)
	local obj = db.storage[npc:id()]
	if(obj.active_scheme~=nil) then
		obj[obj.active_scheme].signals["cam_effector_stop"] = true
	end
end

function update_weather(actor, npc, p)
	if p and p[1] then
		if p[1] == "true" then
			level_weathers.get_weather_manager():select_weather(true)
		elseif p[1] == "false" then
			level_weathers.get_weather_manager():select_weather(false)
		end
	end
end

function trade_job_sell_items(actor,npc,p)
	xr_sound.set_sound_play(npc:id(),"trade")
	axr_trade_manager.npc_trade_buy_sell(npc)
end

function trade_job_give_id(actor,npc,p)
	local board = SIMBOARD
	local smart = p[1] and board and board.smarts_by_names[p[1]]
	local id = smart and smart.npc_by_job_section["logic@"..p[2]]
	local npc_info = id and smart.npc_info[id]
	--printf("smart=%s id=%s npc_info=%s job=%s",smart and smart:name(),id,npc_info ~= nil,npc_info and npc_info.job and npc_info.job.section)
	if not (npc_info and npc_info.job) then
		return
	end
	npc_info.job.seller_id = npc:id()
end

--X16 machine switch off
function yan_gluk (actor, npc)

	local sound_obj_l		= xr_sound.get_safe_sound_object( [[affects\psy_blackout_l]] )
    local sound_obj_r		= xr_sound.get_safe_sound_object( [[affects\psy_blackout_r]] )

	sound_obj_l:play_no_feedback(db.actor, sound_object.s2d, 0, vector():set(-1, 0, 1), 1.0)
	sound_obj_r:play_no_feedback(db.actor, sound_object.s2d, 0, vector():set( 1, 0, 1), 1.0)
	level.add_cam_effector("camera_effects\\earthquake.anm", 1974, false, "")
end

 function yan_saharov_message(actor, npc, p)
 --[[
	if (p[1] == 1) then
		news_manager.send_tip(db.actor, "st_yan_saharov_message", nil, "saharov", 15000, nil)
		db.actor:give_info_portion("labx16_find")
	elseif (p[1] == 2) then
		news_manager.send_tip(db.actor, "st_yan_saharov_message_2", nil, "saharov", 20000, nil)
	elseif (p[1] == 3) then
		 news_manager.send_tip(db.actor, "st_yan_saharov_message_3", nil, "saharov", 15000, nil)
	elseif (p[1] == "free_upgrade") then
		 news_manager.send_tip(db.actor, "st_yan_saharov_message_free_upgrade", nil, "saharov", 15000, nil)
	end
-]]
end

--X18 dream
function x18_gluk (actor, npc)
		level.add_pp_effector ("blink.ppe", 234, false)
		local sound_obj_l		= xr_sound.get_safe_sound_object( [[affects\psy_blackout_l]] )
        local sound_obj_r		= xr_sound.get_safe_sound_object( [[affects\psy_blackout_r]] )
        local snd_obj			= xr_sound.get_safe_sound_object( [[affects\tinnitus3a]] )
		snd_obj:play_no_feedback(db.actor, sound_object.s2d, 0, vector():set(0,0,0), 1.0)
		sound_obj_l:play_no_feedback(db.actor, sound_object.s2d, 0, vector():set(-1, 0, 1), 1.0)
		sound_obj_r:play_no_feedback(db.actor, sound_object.s2d, 0, vector():set( 1, 0, 1), 1.0)
	level.add_cam_effector("camera_effects\\earthquake.anm", 1974, false, "")
end

function end_yantar_dream(actor, npc)
	db.actor:give_info_portion("yantar_find_ghost_task_start")
end

function end_x18_dream(actor, npc)
	db.actor:give_info_portion("dar_x18_dream")
end

function end_radar_dream(actor, npc)
	db.actor:give_info_portion("bun_patrol_start")
end

function end_warlab_dream(actor, npc)
	db.actor:give_info_portion("end_warlab_dream")
end

function end_final_peace(actor, npc)
	db.actor:give_info_portion("end_final_peace")
end

---------------------------------------------------------
-- Sarcofag2
---------------------------------------------------------

function aes_earthshake (npc)
	local snd_obj = xr_sound.get_safe_sound_object([[ambient\earthquake]])
	snd_obj:play_no_feedback(db.actor, sound_object.s2d, 0, vector():set(0,0,0), 1.0)
	level.add_cam_effector("camera_effects\\earthquake.anm", 1974, false, "")
    --set_postprocess ("scripts\\earthshake.ltx")
end

function oso_init_dialod ()
	-- local oso = level_object_by_sid(osoznanie)
	-- db.actor:run_talk_dialog(oso)
end

function warlab_stop_particle(actor, npc, p)
	db.actor:stop_particles("anomaly2\\control_monolit_holo", "link")
end

function play_snd_from_obj(actor, npc, p)
	if p[1] and p[2] then
		local snd_obj = xr_sound.get_safe_sound_object(p[2])
		local obj     = level_object_by_sid(p[1])
        if obj ~= nil then
           printf("can't find object with story id %s", tostring(p[1]))

--		snd_obj:play_at_pos(obj, obj:position(), sound_object.s3d)
		snd_obj:play_no_feedback(obj, sound_object.s3d, 0, obj:position(), 1.0)
		end
	end
end

function play_snd(actor, npc, p)
	if p[1] then
		local snd_obj = xr_sound.get_safe_sound_object(p[1])
		--snd_obj:play(actor, p[2] or 0, sound_object.s2d)
		snd_obj:play_no_feedback(actor, sound_object.s2d, p[2] or 0, vector():set(0,0,0), 1.0)
	end
end

function erase_pstor_ctime(actor,npc,p)
	if not (p[1]) then
		return
	end

	utils.save_ctime(db.actor,p[1],nil)
end

-- Shows progress bar health for last hit enemy with db.storage[id].show_health = true
-- param 1: Story ID
-- param 2: true or false; default is true. True will set db.storage[id].show_health = true while false will remove custom static from screen
function show_health(actor,npc,p)
	if (p[2] == "false") then
		ui_enemy_health.cs_remove()
	else
		local id = get_story_object_id(p[1])
		local st = id and db.storage[id]
		if (st) then
			st.show_health = true
		end
	end
end


function disable_monolith_zones(actor,npc,p)
	local remove_sections = {
		["zone_monolith"] = true
	}
	local sim = alife()
	for i=1,65534 do
		local se_obj = sim:object(i)
		if (se_obj and remove_sections[se_obj:section_name()]) then
			sim:release(se_obj,true)
		end
	end
end

function disable_generator_zones(actor,npc,p)
	local remove_sections = {
		["generator_torrid"] = true,
		["generator_dust"] = true,
		["generator_electra"] = true,
		["generator_dust_static"] = true
	}
	local sim = alife()
	for i=1,65534 do
		local se_obj = sim:object(i)
		if (se_obj and remove_sections[se_obj:section_name()]) then
			sim:release(se_obj,true)
		end
	end
end

--OLD ARENA
function bar_arena_hit(actor, npc)
	local h = hit()
	h.power = 0.01
	h.direction = npc:direction()
	h.draftsman = db.actor
	h.impulse = 1
	h.type = hit.wound
	npc:hit(h)
end

function bar_arena_introduce(actor, npc)
	if db.actor:has_info("bar_arena_pseudodog_choosen") then
		news_manager.send_tip(db.actor, "bar_arena_fight_pseudodog", nil, "arena", 24000, nil)
	elseif db.actor:has_info("bar_arena_snork_choosen") then
		news_manager.send_tip(db.actor, "bar_arena_fight_snork", nil, "arena", 30000, nil)
	elseif db.actor:has_info("bar_arena_bloodsucker_choosen") then
		news_manager.send_tip(db.actor, "bar_arena_fight_bloodsucker", nil, "arena", 30000, nil)
	elseif db.actor:has_info("bar_arena_burer_choosen") then
		news_manager.send_tip(db.actor, "bar_arena_fight_burer", nil, "arena", 52000, nil)
	elseif db.actor:has_info("bar_arena_savage_choosen") then
		news_manager.send_tip(db.actor, "bar_arena_fight_savage", nil, "arena", 34000, nil)
	end
end

function bar_arena_fight_begin(actor, npc)
	news_manager.send_tip(db.actor, "bar_arena_fight_begin", nil, "arena")
end

function bar_arena_fight_10(actor, npc)
	news_manager.send_tip(db.actor, "bar_arena_fight_10", nil, "arena")
end

function bar_arena_fight_20(actor, npc)
	news_manager.send_tip(db.actor, "bar_arena_fight_20", nil, "arena")
end

function bar_arena_fight_30(actor, npc)
	news_manager.send_tip(db.actor, "bar_arena_fight_30", nil, "arena")
end

function bar_arena_fight_40(actor, npc)
	news_manager.send_tip(db.actor, "bar_arena_fight_40", nil, "arena")
end

function bar_arena_fight_50(actor, npc)
	news_manager.send_tip(db.actor, "bar_arena_fight_50", nil, "arena")
end

function bar_arena_fight_60(actor, npc)
	news_manager.send_tip(db.actor, "bar_arena_fight_60", nil, "arena")
end

function bar_arena_fight_70(actor, npc)
	news_manager.send_tip(db.actor, "bar_arena_fight_70", nil, "arena")
end

function bar_arena_fight_80(actor, npc)
	news_manager.send_tip(db.actor, "bar_arena_fight_80", nil, "arena")
end

function bar_arena_fight_90(actor, npc)
	news_manager.send_tip(db.actor, "bar_arena_fight_90", nil, "arena")
end

function bar_arena_check_lose(actor, npc)
	if db.actor:has_info("bar_arena_100_p") then
		if db.actor:has_info("bar_arena_fight_30") then
			db.actor:give_info_portion("bar_arena_actor_lose")
			news_manager.send_tip(actor, "bar_arena_fight_timeout", nil, "arena")
		end
		return
	end
	if db.actor:has_info("bar_arena_50_p") then
		if db.actor:has_info("bar_arena_fight_90") then
			db.actor:give_info_portion("bar_arena_actor_lose")
			news_manager.send_tip(actor, "bar_arena_fight_timeout", nil, "arena")
		end
		return
	end
end

function bar_arena_after_fight(actor, npc)
	if db.actor:dont_has_info("bar_arena_actor_lose") then
		db.actor:give_info_portion("bar_arena_actor_victory")
		news_manager.send_tip(actor, "bar_arena_fight_victory", nil, "arena")
	else
		news_manager.send_tip(actor, "bar_arena_fight_lose", nil, "arena")
	end
	db.actor:give_info_portion("bar_arena_start_introduce")
end

function bar_arena_actor_afraid(actor, npc)
	news_manager.send_tip(db.actor, "bar_arena_actor_afraid", nil, "arena")
end

function bar_arena_actor_dead(actor, npc)
	news_manager.send_tip(db.actor, "bar_arena_fight_dead", nil, "arena")
end

--NEW ARENA
--[[script by Ekidona Arubino | 31.03.23 | 16:29 (JST)]]
local ArenaItemsSpawn={--Add outfit in the end.
	[1]={"wpn_pm","wpn_knife","novice_outfit"},
	[2]={"wpn_mp5","wpn_knife","novice_outfit",},
	[3]={"wpn_toz34","ammo_12x70_buck","wpn_knife2","stalker_outfit"},
	[4]={"wpn_ak74","wpn_knife2","stalker_outfit",{"bandage",2}},
	[5]={"wpn_abakan","wpn_knife2","svoboda_light_outfit","bandage","medkit"},
	[6]={"wpn_groza","wpn_knife2","grenade_f1","specops_outfit"},
	[7]={"wpn_knife5",{"grenade_f1",4},"bandage"},
	[8]={"wpn_g36","wpn_knife2","exo_outfit"},
}
function bar_arena_teleport(actor,npc) actor_effects.disable_effects_timer(100) get_hud():HideActorMenu()
	local box=get_story_object("bar_arena_inventory_box") if(box)then
		local function transfer_object_item(item) db.actor:transfer_item(item,box)end
		db.actor:inventory_for_each(transfer_object_item)
	end local smags={}
	for k,v in pairs(ArenaItemsSpawn)do if(has_alife_info("bar_arena_fight_"..k))then
		for k2,v2 in pairs(v)do
			if(type(v2)=="string")then local itm=alife():create(v2,db.actor:position(),db.actor:level_vertex_id(),db.actor:game_vertex_id(),0)
				if(ekidona_mags.isMWeapon(v2))then
					local ammo,magsec=alun_utils.parse_list(system_ini(),v2,"ammo_class")[1],ekidona_mags.GetMagName(v2,1,2,system_ini():r_float_ex(v2,"ammo_mag_size"))
					local ammoindex=ekidona_mags.GetAmmoIndFromMag(magsec,ammo:sub(1,string.len(ammo)-1))
					for i=1,4 do table.insert(smags,{ekidona_mags.GetIndFromMag(magsec),ammoindex,system_ini():r_float_ex(v2,"ammo_mag_size")})end
				elseif(ekidona_mags.isMSuit(v2))then 
					local slen=ekidona_mags.GetSuitMaxMags(v2) ekidona_mags.SetMagazinesDB(itm.id,{})
					for k3,v3 in pairs(smags)do if(k3<=slen)then table.insert(ekidona_mags.GetMagazinesDB(itm.id),v3)
					else local magsec=ekidona_mags.GetMagFromInd(v3[1]) local mammo=ekidona_mags.GetAmmoSecFromMag(magsec,v3[2])
					ekidona_mags.CreateMagazine(magsec,db.actor:position(),db.actor:level_vertex_id(),db.actor:game_vertex_id(),0,mammo,v3[3])
					end end
				end
			else give_object_to_actor(v2[1],v2[2])end
		end
	break end end
end

function bar_arena_weapon_slot (actor,npc,p)
	--db.actor:activate_slot(tonumber(p[1]) or 1)
end

function bar_arena_teleport_2 (actor, npc)
	actor_effects.disable_effects_timer(100)
	local hud = get_hud()
	if (hud) then
		hud:HideActorMenu()
	end

	-- remove items from actor given to him by arena
	local box = get_story_object("bar_arena_inventory_box_2")
	if (box) then
		local function transfer_object_item(item)
			db.actor:transfer_item(item, box)
		end
		db.actor:inventory_for_each(transfer_object_item)
	end

	-- purge all marked items
	xr_zones.purge_arena_items("bar_arena")

	level.add_pp_effector ("blink.ppe", 234, false)

	db.actor:set_actor_position(patrol("t_walk_2"):point(0))
	local dir = patrol("t_look_2"):point(0):sub(patrol("t_walk_2"):point(0))
	db.actor:set_actor_direction(-dir:getH())

	-- give actor back his items that were taken
	--[[
	local box = get_story_object("bar_arena_inventory_box")
	if (box) then
		local function transfer_object_item(box,item)
			box:transfer_item(item, db.actor)
		end
		box:iterate_inventory_box(transfer_object_item,box)
	end
	--]]
end

function purge_zone(actor,npc,p)
	if (p and p[1]) then
		xr_zones.purge_arena_items(p[1])
	end
end

function clear_weather(actor,npc,p)
	local wm = level_weathers.get_weather_manager()
	wm.current_state = "clear"
	--wm.next_state = "clear"
	wm:select_weather(true)
end

function actor_surge_immuned(actor,npc,p)
	utils.save_var(db.actor,"surge_immuned",p[1] == "true" or nil)
end

function force_always_online(actor,npc,p)
	local squad = p[1] and get_story_squad(p[1])
	if not (squad) then
		return
	end

	alife():set_switch_offline(squad.id,false)
	alife():set_switch_online(squad.id,true)
end


-------------------------------------------------------------------------------------------

function setup_esc_7_11_rpg_quest( actor, npc, p )
	utils.save_var(db.actor,p[1],"wpn_rpg7")
end

function degradation_get_reward(actor,npc,p)

	local week = utils.get_week_in_zone()+0.1
	--week = 7
	k = 10/week
	local money = math.random(p[1],p[2])
	
	printf("EASY REWARD: "..tostring(IsEasyMode()))
	
	if IsEasyMode() then
		money = money*3
	end
	
	local items = math.floor(money/k)
	local cash = math.ceil((money-items)/500)*500
	
	if (cash <= 0) then
		cash = 1000
	end

	dialogs.relocate_money(db.actor,cash,"in")
	degradation_reward_random_items(actor,npc,items)
end



function degradation_reward_random_items(actor, npc, money)
	local ini = system_ini()
	local reward_items = {
	
	"bandage",
	"survival_kit",
	"medkit",
	"medkit_army",
	"medkit_scientic",
	"stimpack",
	"stimpack_army",
	"stimpack_scientic",
	"rebirth",
	"glucose",
	"glucose_s",
	"antirad",
	
	"bread",
	"conserva",
	"protein",
	"tomato",
	"sausage",
	"beans",
	"corn",
	"chili",
	"chocolate",
	
	"cigarettes_3",
	"cigarettes_russian_3",
	"cigarettes_lucky_3",
	"vodka_3",
	"beer",
	"energy_drink",
	"water_drink",
	"mineral_water_3",
	
	
	"ammo_9x18_fmj",
	"ammo_12x70_buck",
	"ammo_5.45x39_fmj",
	"ammo_7.62x39_fmj",
	"grenade_f1",
	"grenade_rgd5",
	
	
	
	}
	
	repeat
		local section = reward_items[math.random(1,#reward_items)]
		local cost = ini:r_float_ex(section,"cost") or 0
		
		if (cost <= money) then
			dialogs.relocate_item_section(db.actor,section,"in")
			money = money - cost
		end
	until (money < 500)

end

function degradation_setup_quick_fetch( actor, npc, p )

	local faction = p[4] or " "

	local itm = DIALOG_LAST_ID and DIALOG_LAST_ID == inventory_upgrades.victim_id and utils.load_var(db.actor,p[1])
	DIALOG_LAST_ID = inventory_upgrades.victim_id
	if (itm and system_ini():section_exist(itm)) then
		dialogs._FETCH_TEXT = game.translate_string(system_ini():r_string_ex(itm,"inv_name") or "")
	else
		local itms = {}
		
		if faction == "stalker" then
			itms = {
					"wpn_hand_axe",
					"wpn_hand_shovel",
					"wpn_hand_crowbar",
					"wpn_hand_hammer",			
					"wpn_binoc_inv",
					"grenade_f1",
					"grenade_rgd5",
					"grenade_smoke",
					"drug_charcoal_5",
					"bandage",
					"bread",
					"conserva",
					"beer",
					"vodka_3",
					"energy_drink",
					"drink_crow",
					"flask_3",
					"bottle_metal_3",
					"cigar1_3",
					"cigar2_3",
					"cigar3_3",
					"cigarettes_russian_3",
					"itm_qr",
					"itm_backpack",
					"itm_sleepbag",
					"cooking",
					"wood_stove",
					"charcoal_3",
					"explo_jerrycan_fuel_8",
					"explo_balon_gas_8",
					"matches",
					"beadspread",
					"sleep_bag",
					"maps_kit",
					"lead_box",
					"af_iam",
					"detector_craft",
					"device_flashlight",
					"device_lighter",
					"batteries_ccell",
					"mutant_part_boar_leg",
					"mutant_part_dog_tail",
					"mutant_part_cat_tail",
					"mutant_part_dog_liver",
					"mutant_part_dog_heart",
					"mutant_part_cat_thyroid",
					"guitar_a",
					"harmonica_a",
					"grooming",
					"spareparts",
					"porn",
					"tarpaulin",
					"synthrope",
					"grease",
					"steel_wool",
					"textile_patch_e",
					"textolite",
					"transistors",
					"capacitors",
					"colophony",
					"glue_b_2",
					"sewing_kit_b_4",
					"sharpening_stones_4"
					}
		elseif faction == "bandit" then
			itms = {
					"wpn_hand_axe",
					"wpn_hand_shovel",
					"wpn_hand_crowbar",
					"wpn_hand_hammer",			
					"wpn_sil_9mm",
					"grenade_f1",
					"grenade_rgd5",
					"grenade_smoke",
					"mine_wire",
					"drug_charcoal_5",
					"bandage",
					"stimpack",
					"cocaine",
					"meat_dog",
					"meat_pseudodog",
					"meat_flesh",
					"meat_boar",
					"bread",
					"beer",
					"vodka_3",
					"drink_crow",
					"tea_3",
					"flask_3",
					"bottle_metal_3",
					"tobacco_3",
					"marijuana",
					"joint",
					"cigar1_3",
					"cigar2_3",
					"cigar3_3",
					"hand_rolling_tobacco_3",
					"cigar",
					"cigarettes_russian_3",
					"itm_backpack",
					"itm_sleepbag",
					"cooking",
					"wood_stove",
					"charcoal_3",
					"explo_jerrycan_fuel_8",
					"explo_metalcan_powder",
					"matches",
					"beadspread",
					"sleep_bag",
					"maps_kit",
					"af_ironplate",
					"device_flashlight",
					"device_lighter",
					"guitar_a",
					"harmonica_a",
					"grooming",
					"spareparts",
					"cards",
					"boots",
					"swiss",
					"porn",
					"tarpaulin",
					"rope",
					"synthrope",
					"grease",
					"steel_wool",
					"textile_patch_e",
					"copper_coil",
					"textolite",
					"transistors",
					"capacitors",
					"colophony",
					"sewing_kit_b_4",
					"itm_drugkit",
					}		
		elseif faction == "csky" then
			itms = {
					"wpn_hand_axe",
					"wpn_hand_shovel",
					"wpn_hand_crowbar",
					"wpn_hand_hammer",
					"grenade_smoke",
					"drug_charcoal_5",
					"bandage",
					"meat_flesh",
					"meat_boar",
					"bread",
					"vodka_3",
					"drink_crow",
					"flask_3",
					"bottle_metal_3",
					"cigar1_3",
					"cigar2_3",
					"cigar3_3",
					"cigarettes_russian_3",
					"cigar",
					"cigarettes_3",
					"itm_qr",
					"itm_backpack",
					"itm_sleepbag",
					"cooking",
					"wood_stove",
					"charcoal_3",
					"explo_jerrycan_fuel_8",
					"matches",
					"beadspread",
					"maps_kit",
					"lead_box",
					"af_iam",
					"geiger",
					"detector_craft",
					"detector_simple",
					"device_flashlight",
					"device_lighter",
					"batteries_ccell",
					"mutant_part_boar_leg",
					"mutant_part_dog_tail",
					"mutant_part_cat_tail",
					"mutant_part_boar_tusk",
					"mutant_part_dog_liver",
					"mutant_part_dog_heart",
					"mutant_part_cat_thyroid",
					"mutant_part_cat_claw",
					"guitar_a",
					"harmonica_a",
					"grooming",
					"spareparts",
					"swiss",
					"tarpaulin",
					"rope",
					"synthrope",
					"grease",
					"steel_wool",
					"copper_coil",
					"textolite",
					"transistors",
					"capacitors",
					"colophony",
					"glue_b_2",
					"sewing_kit_b_4",
					"sharpening_stones_4",
					}		
		elseif faction == "dolg" then
			itms = {
					"wpn_hand_axe",
					"wpn_hand_shovel",
					"wpn_hand_crowbar",
					"wpn_hand_hammer",
					"grenade_f1",
					"grenade_rgd5",
					"ied",
					"mine_wire",
					"antirad",
					"stimpack",
					"survival_kit",
					"tetanus",
					"salicidic_acid",
					"morphine",
					"meat_pseudodog",
					"meat_flesh",
					"meat_boar",
					"meat_bloodsucker",
					"bread",
					"conserva",
					"tushonka",
					"caffeine_5",
					"vodka_3",
					"energy_drink",
					"drink_crow",
					"tea_3",
					"flask_3",
					"bottle_metal_3",
					"cigarettes_russian_3",
					"cigar1_3",
					"cigar2_3",
					"cigar3_3",
					"itm_qr",
					"itm_backpack",
					"itm_sleepbag",
					"wood_stove",
					"beadspread",
					"maps_kit",
					"mili_maps",
					"geiger",
					"device_flashlight",
					"device_lighter",
					"device_torch_dummy",
					"device_kerosinka",
					"batteries_ccell",
					"guitar_a",
					"harmonica_a",
					"grooming",
					"spareparts",
					"walkie",
					"tarpaulin",
					"grease",
					"steel_wool",
					"textile_patch_e",
					"transistors",
					"capacitors",
					"colophony",
					"armor_repair_fa_2",
					"toolkit_p",
					"repairkit_p",
					"toolkit_s",
					"repairkit_s",
					}		
		elseif faction == "freedom" then
			itms = {
					"ac10632",
					"acog",
					"eot",
					"wpn_sil_9mm",
					"wpn_sil_45",
					"wpn_sil_nato",
					"wpn_sil_gemtech",
					"grenade_f1",
					"grenade_rgd5",
					"mine_wire",
					"antirad",
					"stimpack",
					"survival_kit",
					"cocaine",
					"salicidic_acid",
					"morphine",
					"meat_flesh",
					"meat_boar",
					"meat_bloodsucker",
					"bread",
					"beer",
					"vodka_3",
					"caffeine_5",
					"energy_drink",
					"drink_crow",
					"tea_3",
					"flask_3",
					"bottle_metal_3",
					"marijuana",
					"joint",
					"cigar",
					"cigarettes_3",
					"cigarettes_lucky_3",
					"itm_qr",
					"itm_backpack",
					"itm_sleepbag",
					"wood_stove",
					"kerosene_5",
					"charcoal_3",
					"explo_balon_gas_8",
					"explo_jerrycan_fuel_8",
					"beadspread",
					"maps_kit",
					"mili_maps",
					"geiger",
					"device_flashlight",
					"device_lighter",
					"device_torch_dummy",
					"device_kerosinka",
					"batteries_ccell",
					"guitar_a",
					"harmonica_a",
					"grooming",
					"spareparts",
					"walkie",
					"tarpaulin",
					"grease",
					"steel_wool",
					"textile_patch_e",
					"textolite",
					"transistors",
					"capacitors",
					"colophony",
					"armor_repair_fa_2",
					"toolkit_p",
					"repairkit_p",
					"toolkit_s",
					"repairkit_s",
					"toolkit_r",
					"repairkit_r",
					}		
		elseif faction == "killer" then
			itms = {
					"wpn_addon_scope",
					"wpn_sil_9mm",
					"grenade_f1",
					"grenade_rgd5",
					"grenade_gd-05",
					"mine",
					"mine_wire",
					"antirad",
					"stimpack",
					"survival_kit",
					"tetanus",
					"salicidic_acid",
					"morphine",
					"bread",
					"conserva",
					"tushonka",
					"caffeine_5",
					"energy_drink",
					"drink_crow",
					"flask_3",
					"cigar",
					"cigarettes_3",
					"cigarettes_lucky_3",
					"itm_qr",
					"itm_backpack",
					"itm_sleepbag",
					"kerosene_5",
					"charcoal_3",
					"wood_stove",
					"explo_balon_gas_8",
					"explo_jerrycan_fuel_8",
					"beadspread",
					"maps_kit",
					"mili_maps",
					"geiger",
					"device_flashlight",
					"device_glowstick",
					"device_lighter",
					"device_torch_dummy",
					"batteries_ccell",
					"grooming",
					"spareparts",
					"walkie",
					"cards",
					"porn",
					"tarpaulin",
					"grease",
					"steel_wool",
					"textile_patch_e",
					"textolite",
					"transistors",
					"capacitors",
					"colophony",
					"armor_repair_fa_2",
					"toolkit_p",
					"repairkit_p",
					"toolkit_s",
					"repairkit_s",
					"toolkit_r",
					"repairkit_r",
					"sewing_kit_h",
					"armor_repair_pro",
					}		
		elseif faction == "army" then
			itms = {
					"caffeine_5",
					"beer",
					"vodka_3",
					"energy_drink",
					"drink_crow",
					"tea_3",
					"bottle_metal_3",
					"joint",
					"cigar1_3",
					"cigar2_3",
					"cigar3_3",
					"cigarettes_3",
					"cigarettes_lucky_3",
					"cigarettes_russian_3",
					"device_flashlight",
					"device_lighter",
					"device_torch_dummy",
					"guitar_a",
					"harmonica_a",
					"grooming",
					"cards",
					"swiss",
					"porn",
					}		
		elseif faction == "ecolog" then
			itms = {
					"mutant_part_krovosos_jaw",
					"mutant_part_boar_leg",
					"mutant_part_dog_tail",
					"mutant_part_flesh_eye",
					"mutant_part_psevdodog_tail",
					"mutant_part_snork_leg",
					"mutant_part_pseudogigant_eye",
					"mutant_part_pseudogigant_hand",
					"mutant_part_chimera_claw",
					"mutant_part_cat_tail",
					"mutant_part_burer_hand",
					"mutant_part_controller_hand",
					"mutant_part_controller_glass",
					"mutant_part_fracture_hand",
					"mutant_part_krovosos_heart",
					"mutant_part_chimera_heart",
					"mutant_part_dog_liver",
					"mutant_part_dog_heart",
					"mutant_part_cat_thyroid",
					"mutant_part_cat_claw",
					"mutant_part_burer_brain",
					"mutant_part_psy_dog_brain",
					"hide_psy_dog",
					"hide_pseudodog",
					"hide_burer",
					"hide_controller",
					"hide_bloodsucker",
					"hide_boar",
					"hide_flesh",
					}			
		
		else
			itms = {
				"bandage",
				"medkit",
			}
		end
					
					
					
					
					
		itm = itms[math.random(#itms)]
		dialogs._FETCH_TEXT = game.translate_string(system_ini():r_string_ex(itm,"inv_name") or "")
		utils.save_var(db.actor,p[1],itm)
		utils.save_var(db.actor,p[1].."_count",math.random(p[2] and tonumber(p[2]) or 1,p[3] and tonumber(p[3]) or 1))
	end
end
