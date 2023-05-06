--// -----------------		Artefact Degradation for CoC	 ---------------------
--// author	: 	Nuor
--// version:	1.02
--// created:	9-01-2016
--// last edit:	1-29-2017
--//------------------------------------------------------------------------------

local belted_arts = {}
local sysini = system_ini()
local imm_mul, mul, _tmr
feature_is_active = nil
art_weight_add = 0
local function main_loop()
    local tg = time_global()
    if (_tmr and tg < _tmr) then
        return false
    end
    _tmr = tg + 2000    -- if you change this value timed artefact multipliers will need changes
 
    if not (db.actor) then
        return false
    end
    art_weight_add = 0
    local cond_loss, val = 0, 0
    for art_id,active in pairs(belted_arts) do
        if (active) then
            local arte = level.object_by_id(art_id)
            if not (arte and db.actor:is_on_belt(arte)) then
                belted_arts[art_id] = nil
            else
                cond_loss = 0
                if (db.actor.health < 1.0) then
                    val = arte:get_artefact_health()
                    if (val > 0) then
                        cond_loss = cond_loss + (val * mul["health"])
                    end
                end
                if (db.actor.radiation > 0) then
                    val = arte:get_artefact_radiation()
                    if (val < 0) then
                        cond_loss = cond_loss + (math.abs(val) * mul["radiation"])
                    end    
                end
                if (db.actor.satiety < 1.0) then
                    val = arte:get_artefact_satiety()
                    if (val > 0) then
                        cond_loss = cond_loss + (val * mul["satiety"])
                    end    
                end
                if (db.actor.power < 1.0) then
                    val =  arte:get_artefact_power()
                    if (val > 0) then
                        cond_loss = cond_loss + (val * mul["power"])
                    end
                end
                if (db.actor.bleeding > 0) then
                    val =  arte:get_artefact_bleeding()
                    if (val > 0) then
                        cond_loss = cond_loss + (val * mul["bleeding"])
                    end
                end
           
                val =  arte:get_artefact_additional_weight()
                art_weight_add = art_weight_add + val
                if (val > 0) then
                    local suit = db.actor:item_in_slot(7)
                    local diff = db.actor:get_total_weight() - db.actor:get_actor_max_walk_weight() - (suit and suit:get_additional_max_weight() or 0)
                    if diff > 0 then
                        cond_loss = cond_loss + ((diff * mul["weight"])/val)
                    end
                end
           
                if (cond_loss > 0) then
                    local degrade_rate = (cond_loss*sysini:r_float_ex(arte:section(),"degrade_rate",1))
					--printf("%s Degradation: cond_loss=%s",arte:name(),degrade_rate)
                    if (arte:condition() - degrade_rate >= 0.01) then
                        arte:set_condition(arte:condition() - degrade_rate)
                    else
                        arte:set_condition(0.01)
                    end
                end
            end
        end
    end
	
    return
end

function activate_feature()
	if (feature_is_active) then
		return 
	end
	feature_is_active = true
	
	imm_mul = imm_mul or {					-- correction factors for hit events
		["light_burn_immunity"] = 1.2,
		["burn_immunity"] = 1.2,
		["strike_immunity"] = 1.2,
		["shock_immunity"] = 1.2,
		["wound_immunity"] = 1.2,
		["radiation_immunity"] = 1.2,
		["telepatic_immunity"] = 1.2,
		["chemical_burn_immunity"] = 1.2,
		["explosion_immunity"] = 1.2,
		["fire_wound_immunity"] = 1.2,
	}

	mul = mul or {						-- correction factors for timed checks
		["health"]		= 0.2,		-- updated often while slotted so don't set too high
		["radiation"] 	= 0.2,
		["satiety"] 	= 0.2,
		["power"] 		= 0.2,		-- updated often while slotted so don't set too high
		["bleeding"] 	= 0.2,
		["psy_health"] 	= 0.2,
		["weight"]		= 0.0001, 	-- updated often while slotted so don't set too high
	}
	RegisterScriptCallback("actor_on_item_drop",actor_on_item_drop)
	RegisterScriptCallback("actor_on_before_hit",actor_on_before_hit)
	RegisterScriptCallback("actor_item_to_belt",actor_item_to_belt)
	AddUniqueCall(main_loop)
end 

function deactivate_feature()
	if not (feature_is_active) then
		return 
	end
	feature_is_active = false
	
	RemoveUniqueCall(main_loop)
	UnregisterScriptCallback("actor_on_item_drop",actor_on_item_drop)
	UnregisterScriptCallback("actor_on_before_hit",actor_on_before_hit)
	UnregisterScriptCallback("actor_item_to_belt",actor_item_to_belt)	
end

function on_game_start()
	--if (axr_main.config:r_value("mm_options","enable_art_degrade",1,false)) then
		activate_feature()
	--end
end

--------------------------------------------------------------------------
-- Callbacks
--------------------------------------------------------------------------
function actor_on_item_drop(art)
	if not IsArtefact(art) then
		return
	end
	local art_id = art:id()
	for k,v in pairs(belted_arts) do
		if k == art_id then
			belted_arts[k] = nil
			return
		end
	end
end

function actor_item_to_belt(item)
	if IsArtefact(item) then
		belted_arts[item:id()] = true
	end
end
--//-----------		On hit immunities checks
local hit_to_section = {
	[hit.light_burn] = "light_burn_immunity",
	[hit.burn] = "burn_immunity",
	[hit.strike] = "strike_immunity",
	[hit.shock] = "shock_immunity",
	[hit.wound] = "wound_immunity",
	[hit.radiation] = "radiation_immunity",
	[hit.telepatic] = "telepatic_immunity",
	[hit.chemical_burn] = "chemical_burn_immunity",
	[hit.explosion] = "explosion_immunity",
	[hit.fire_wound] = "fire_wound_immunity",
}

local equipement_damaging = {
	["light_burn_immunity"] = true,
	["burn_immunity"] = true,
	["strike_immunity"] = true,
	["wound_immunity"] = true,
	["chemical_burn_immunity"] = true,
	["explosion_immunity"] = true,
	["fire_wound_immunity"] = true,
}


function get_artefact_adsorbation(arte,hit_type)
	
	if (hit_type == "light_burn_immunity") or (hit_type == "burn_immunity") then
		return arte:get_artefact_burn_immunity()
	elseif (hit_type == "strike_immunity") then
		return arte:get_artefact_strike_immunity()
	elseif (hit_type == "shock_immunity") then
		return arte:get_artefact_shock_immunity()
	elseif (hit_type == "wound_immunity") then
		return arte:get_artefact_wound_immunity()
	elseif (hit_type == "radiation_immunity") then
		return arte:get_artefact_radiation_immunity()
	elseif (hit_type == "telepatic_immunity") then
		return arte:get_artefact_telepatic_immunity()
	elseif (hit_type == "chemical_burn_immunity") then
		return arte:get_artefact_chemical_burn_immunity()
	elseif (hit_type == "explosion_immunity") then
		return arte:get_artefact_explosion_immunity()
	elseif (hit_type == "fire_wound_immunity") then
		return arte:get_artefact_fire_wound_immunity()
	end

	return 0
end


function actor_on_before_hit(s_hit,bone_id)

	if (s_hit.power <= 0) then 
		return 
	end
	
	local cond_loss = 0
	local unloads={}
	for art_id,active in pairs(belted_arts) do
		if (active) then
			local arte = level.object_by_id(art_id)
			if not (arte and db.actor:is_on_belt(arte)) then
				belted_arts[art_id] = nil
			elseif(arte:section()=="unloading_bag")and(equipement_damaging[hit_to_section[s_hit.type]])then
				table.insert(unloads,arte)
			else local imm_sect = hit_to_section[s_hit.type]
				cond_loss = get_artefact_adsorbation(arte,imm_sect)
				if (cond_loss > 0) then
					cond_loss = (s_hit.power * imm_mul[imm_sect] * 0.01 ) --* cond_loss
					--printf("%s Degradation: hit_power=%s cond_loss=%s",arte:name(),s_hit.power,cond_loss)
					
					local temp_cond = arte:condition() - (cond_loss*sysini:r_float_ex(arte:section(),"degrade_rate",1))
					temp_cond = temp_cond > 0.01 and temp_cond or 0.01
					arte:set_condition(temp_cond)
				end
			end
		end
	end local usedcond=0
	for k,v in pairs(unloads)do if(usedcond>=1)then break end -- designed by Ekidona Arubino (30:12:22)
		local damcond=math.random(math.floor(1000000*(((s_hit.power/4)-usedcond)-k+1)),math.min(10000,math.floor(((s_hit.power/4)-usedcond)*1000000)))
		usedcond=(usedcond+(damcond/1000000)) local conds=math.max(0,v:condition()-(damcond/1000000))
		if(conds==0)then alife():release(alife_object(v:id()))else v:set_condition(conds)end
	end local backpack = db.actor:item_in_slot(15)	
	if (backpack and backpack:section() == "airtank") then
		local imm_sect = hit_to_section[s_hit.type]
		cond_loss = get_artefact_adsorbation(backpack,imm_sect) or 0
		if (cond_loss > 0) then
			cond_loss = (s_hit.power * imm_mul[imm_sect] * cond_loss)
			--printf("%s Degradation: hit_power=%s cond_loss=%s",backpack:name(),s_hit.power,cond_loss)
			local temp_cond = backpack:condition() - (cond_loss*sysini:r_float_ex(backpack:section(),"degrade_rate",1))
			temp_cond = temp_cond > 0.01 and temp_cond or 0.01
			backpack:set_condition(temp_cond)
		end
	elseif (backpack) and (backpack:section() == "backpack_heavy") then
		cond_loss = 0
		hit_absorbation_sect = sysini:r_string_ex("ecolog_guard_outfit","immunities_sect")
		if (hit_absorbation_sect) and (equipement_damaging[hit_to_section[s_hit.type]]) then
			imm_sect = hit_to_section[s_hit.type]
			cond_loss = imm_sect and sysini:r_float_ex(hit_absorbation_sect,imm_sect)*0.5 or 0
			cond_loss = cond_loss * s_hit.power
			if (cond_loss > 0) then
				--printf("%s Degradation: hit_power=%s cond_loss=%s",backpack:name(),s_hit.power,cond_loss)
				local temp_cond = backpack:condition() - (cond_loss*sysini:r_float_ex(backpack:section(),"degrade_rate",1))
				temp_cond = temp_cond > 0.01 and temp_cond or 0.01
				backpack:set_condition(temp_cond)
			end
		end
	elseif (backpack) and (( backpack:section() == "backpack_light") or ( backpack:section() == "kit_hunt") or backpack:section()=="backpack_unloading") then
		cond_loss = 0
		hit_absorbation_sect = sysini:r_string_ex("stalker_outfit","immunities_sect")
		if (hit_absorbation_sect) and (equipement_damaging[hit_to_section[s_hit.type]]) then
			imm_sect = hit_to_section[s_hit.type]
			cond_loss = imm_sect and sysini:r_float_ex(hit_absorbation_sect,imm_sect)*0.5 or 0
			cond_loss = cond_loss * s_hit.power
			if (cond_loss > 0) then
				--printf("%s Degradation: hit_power=%s cond_loss=%s",backpack:name(),s_hit.power,cond_loss)
				local temp_cond = backpack:condition() - (cond_loss*sysini:r_float_ex(backpack:section(),"degrade_rate",1))
				temp_cond = temp_cond > 0.01 and temp_cond or 0.01
				backpack:set_condition(temp_cond)
			end
		end
	elseif (backpack) and ( backpack:section() == "exobackpack") then
		cond_loss = 0
		hit_absorbation_sect = sysini:r_string_ex("exo_outfit","immunities_sect")
		if (hit_absorbation_sect) and (equipement_damaging[hit_to_section[s_hit.type]]) then
			imm_sect = hit_to_section[s_hit.type]
			cond_loss = imm_sect and sysini:r_float_ex(hit_absorbation_sect,imm_sect)*0.05 or 0
			cond_loss = cond_loss * s_hit.power
			if (cond_loss > 0) then
				--printf("%s Degradation: hit_power=%s cond_loss=%s",backpack:name(),s_hit.power,cond_loss)
				local temp_cond = backpack:condition() - (cond_loss*sysini:r_float_ex(backpack:section(),"degrade_rate",1))
				temp_cond = temp_cond > 0.01 and temp_cond or 0.01
				backpack:set_condition(temp_cond)
			end
		end
	end
end

