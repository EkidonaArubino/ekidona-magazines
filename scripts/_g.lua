--[[ 	General Scripting TIPS

	1. 	NEVER keep userdata (ie. engine classes) in global scope, instead keep track of game object id, and grab object in the scope you need it in by using level.object_by_id or db.storage table. 
		Otherwise object can't deconstruct and you will end up with instances were script binder exists but object doesn't or level object exists but server object doesn't. This is because variables in lua are all references.
			Ex. _G.npc = level.object_by_id(2342) 
				alife():release(alife_object(2342))
		Above, 'npc' will not be nil but se_obj will be! scripts will blow up. Pure Virtual Function calls may occur! Or quite possibly silent errors like for example when player goes to talk to npc game crashes because self.object is nil
		Such thing is 'okay' in db.storage, but that is because on net_destroy db.storage[id] is set nil. So if you are keeping track of objects directly in a table, instead of ID 
		then you absolutely must rid of every single reference to the userdata so that it can be destroy and garbage collected. Otherwise you end up with undetectable issues.
--]]
if (jit == nil) then
	profiler.setup_hook	()
end

GAME_VERSION = "1.4.22"

STATIC_LIGHT = 'renderer_r1'
RENDERER = STATIC_LIGHT

if string.find(command_line(), "-dbg") then
	DEV_DEBUG = true
	if string.find(command_line(), "-dbgdev") then -- because users all using dbg, need to hide OP features
		DEV_DEBUG_DEV = true
	end
end

USE_INI_MEMOIZE = true

-- Improves performance if true, by disabling update methods for squads and smart terrains on levels not linked in configs\ai_tweaks\simulation_objects.ltx
-- But this means simulation will only be active on actor level and linked levels everything else will remain in an idle state
DEACTIVATE_SIM_ON_NON_LINKED_LEVELS = false

-------------------------------------------------------------------------------------------------
-- Use marshal library for saving persistent data (like xr_logic pstor)
-- marshal library can encode tables, functions, strings and numbers to easily allow persistent data storage to file
-- This is used for db.storage[id].pstor, surge_manager, mines, and coc_treasure_manager.script if enabled
-- See alife_storage_manager.script for implementation
require("lua_extensions")
marshal = require "marshal"
USE_MARSHAL = marshal ~= nil

----------------------------------------------------------------------
mus_vol = 0
amb_vol = 0
b_discard_settings_shown = false
----------------------------------------------------------------------

function start_game_callback()
	math.randomseed(os.time())
	printf("Call of Chernobyl version %s",GAME_VERSION)
	if (USE_MARSHAL) then
		printf("using marshal library")
	end
	
	sound_theme.load_sound()
		
	-- Alundaio
	if (axr_main) then axr_main.on_game_start() end
	-- End Alundaio

	SIMBOARD = nil
	sim_board.get_sim_board()

	smart_names.init_smart_names_table()
	task_manager.clear_task_manager()
	--xr_sound.start_game_callback()
	dialog_manager.fill_phrase_table()

	sim_objects.clear()
	sr_light.clean_up ()
	pda.add_quick_slot_items_on_game_start()
	
	
	RENDERER = get_console():get_string("renderer")
end

function alife_object(id)
	if (id == nil or id >= 65535) then
		callstack()
		printf("ALIFE OBJECT ID IS %s!",id)
		return
	end
	return alife():object(id)
end
-------------------------------------------------------------------------------------------------------
-- 											SCRIPTED CALLBACKS
-------------------------------------------------------------------------------------------------------
function RegisterScriptCallback(name,func_or_userdata)
	axr_main.callback_set(name,func_or_userdata)
end

function UnregisterScriptCallback(name,func_or_userdata)
	axr_main.callback_unset(name,func_or_userdata)
end

-- Call this from a script to create a new callback to functions that register for it with RegisterScriptCallback
-- Every time this function is executed it will callback to all registered members
-- If axr_main.script has a function by this name, it will automatically trigger it!
function SendScriptCallback(name,...)
	--alun_utils.debug_write(strformat("BEFORE SendScriptCallback %s",name))
	-- callback to all registered functions
	axr_main.make_callback(name,...)
		--alun_utils.debug_write(strformat("AFTER SendScriptCallback %s",name))
		-- check if axr_main has it's own function to execute
	if (axr_main[name]) then
		axr_main[name](...)
	end
end
--------------------------------------------
-- Displays message on middle-top of screen for n amount of milliseconds
-- Overwritten with each use!
-- param 1 - Message as string
-- param 2 - Milliseconds as number
--------------------------------------------
function SetHudMsg(msg,n)
	msg = tostring(msg)
	local hud = get_hud()
	if (hud) then
		hud:AddCustomStatic("not_enough_money_mine", true)
		hud:GetCustomStatic("not_enough_money_mine"):wnd():TextControl():SetTextST(msg)
	end
	bind_stalker_ext.ShowMessageTime = time_global() + n*1000
end

--------------------------------------------------------------------------------------------
-- 								Delayed Event Queue
--
-- Events must have a unique id. Such as object id or another identifier unique to the occasion.
-- Action id must be unique to the specific Event. This allows a single event to have many queued
-- actions waiting to happen.
--
-- Returning true will remove the queued action. Returning false will execute the action continuously.
-- This allows for events to wait for a specific occurrence, such as triggering after a certain amount of
-- time only when object is offline
--
-- param 1 - Event ID as type<any>
-- param 2 - Action ID as type<any>
-- param 3 - Timer in seconds as type<number>
-- param 4 - Function to execute as type<function>
-- extra params are passed to executing function as table as param 1

-- see on_game_load or state_mgr_animation.script for example uses
-- This does not persists through saves! So only use for non-important things.
-- For example, do not try to destroy npcs unless you do not care that it can fail before player saved then loaded.
----------------------------------------------------------------------------------------------
local ev_queue = {}
function CreateTimeEvent(ev_id,act_id,timer,f,...)
	if not (ev_queue[ev_id]) then
		ev_queue[ev_id] = {}
		ev_queue[ev_id].__size = 0
	end

	if not (ev_queue[ev_id][act_id]) then
		ev_queue[ev_id][act_id] = {}
		ev_queue[ev_id][act_id].timer = time_global() + timer*1000
		ev_queue[ev_id][act_id].f = f
		ev_queue[ev_id][act_id].p = {...}
		ev_queue[ev_id].__size = ev_queue[ev_id].__size + 1
	end
end
function RemoveTimeEvent(ev_id,act_id)
	if (ev_queue[ev_id] and ev_queue[ev_id][act_id]) then
		ev_queue[ev_id][act_id] = nil
		ev_queue[ev_id].__size = ev_queue[ev_id].__size - 1
	end
end

function ResetTimeEvent(ev_id,act_id,timer)
	if (ev_queue[ev_id] and ev_queue[ev_id][act_id]) then
		ev_queue[ev_id][act_id].timer = time_global() + timer*1000
	end
end

function ProcessEventQueue(force)
	-- if (has_alife_info("sleep_active")) then
		-- return false
	-- end
	
	for event_id,actions in pairs(ev_queue) do
		for action_id,act in pairs(actions) do
			--alun_utils.debug_write(strformat("event_queue: event_id=%s action_id=%s",event_id,action_id))
			if (action_id ~= "__size") then
				if (force) or (time_global() >= act.timer) then
					if (act.f(unpack(act.p)) == true) then
						ev_queue[event_id][action_id] = nil
						ev_queue[event_id].__size = ev_queue[event_id].__size - 1
					end
				end
			end
		end

		if (ev_queue[event_id].__size == 0) then
			ev_queue[event_id] = nil
		end
	end
	
	return false
end
function ProcessEventQueueState(m_data,save)
	if (save) then
		m_data.event_queue = ev_queue
	else
		ev_queue = m_data.event_queue or ev_queue
	end
end

function SetSwitchDistance(dist)
	if (alife()) then
		local p = net_packet()
		p:w_begin(18)
		p:w_float(dist or 2.0)
		level.send(p,true,true)
	end
end

function ChangeLevel(pos,lvid,gvid,angle)
-- IMPORTANT: You must realize that when you send this event it will happen immediately
-- if done in lua code it will not execute the rest of the block, level changes immediately happen!
--[[
		NET_Packet	p;
		p.w_begin	(M_CHANGE_LEVEL); -- M_CHANGE_LEVEL == 13
		p.w			(&m_game_vertex_id,sizeof(m_game_vertex_id));
		p.w			(&m_level_vertex_id,sizeof(m_level_vertex_id));
		p.w_vec3	(m_position);
		p.w_vec3	(m_angles);
		Level().Send(p,net_flags(TRUE));
--]]
	-- requires OpenXRay
	local p = net_packet()
	p:w_begin(13)
	p:w_u16(gvid)
	p:w_u32(lvid)
	p:w_vec3(pos)
	p:w_vec3(angle)
	level.send(p,true)
end

-- Wrapper for level.add_call 
-- For some reason in 1.6 engine level.remove_call does not work! If you know why, please contact me @alundaio
local level_add_call_unique = {}
function AddUniqueCall(functor_a)

	if (level_add_call_unique[functor_a]) then 
		return 
	end 
	
	local function wrapper()
		if not (level_add_call_unique[functor_a]) then 
			return true 
		end
		
		if (functor_a()) then
			level_add_call_unique[functor_a] = nil
			return true
		end
		
		return false
	end
	
	level_add_call_unique[functor_a] = true
	
	level.add_call(wrapper,function() end)
end 

function RemoveUniqueCall(functor_a)
	level_add_call_unique[functor_a] = nil
end

function JumpToLevel(new_level)
	-- requires OpenXray
	local level_name = level.name()
	if (level_name == new_level) then
		return false
	end
	
	local cvertex
	local sim,gg = alife(),game_graph()
	-- first try to find a smart_terrain on specified level
	for id,smart in pairs(db.smart_terrain_by_id) do
		cvertex = smart and gg:vertex(smart.m_game_vertex_id)
		if (cvertex and sim:level_name(cvertex:level_id()) == new_level) then
			ChangeLevel(cvertex:level_point(),cvertex:level_vertex_id(),smart.m_game_vertex_id,VEC_ZERO)
			return true
		end
	end

	-- in case level has no smarts then just teleport to first found gvid for level
	for gvid=0, 4860 do
		if gg:valid_vertex_id(gvid) then
			cvertex = gg:vertex(gvid)
			lvl = sim:level_name(cvertex:level_id())
			if (lvl == new_level) then
				ChangeLevel(cvertex:level_point(),cvertex:level_vertex_id(),gvid,VEC_ZERO)
				return true
			end
		else
			break
		end
	end
	return false
end

function TeleportObject(id,pos,lvid,gvid)
	-- Requires OpenXray
	if (db.offline_objects[id]) then
		db.offline_objects[id].level_vertex_id = nil
	end
	db.spawned_vertex_by_id[id] = nil
	alife():teleport_object(id,gvid,lvid,pos)
end

function TeleportSquad(squad,pos,lvid,gvid)
	-- Requires OpenXray
	local sim = alife()
	sim:teleport_object(squad.id,gvid,lvid,pos)
	for k in squad:squad_members() do
		if (db.offline_objects[k.id]) then
			db.offline_objects[k.id].level_vertex_id = nil
		end
		db.spawned_vertex_by_id[k.id] = nil
		sim:teleport_object(k.id,gvid,lvid,pos)
	end
end

function IsSurvivalMode()
	return axr_main.config and axr_main.config:r_value("character_creation","new_game_survival_mode",1) == true or alife_storage_manager.get_state().enable_survival_mode == true
end

function IsLastStandMode()
	return axr_main.config and axr_main.config:r_value("character_creation","new_game_laststand_mode",1) == true or alife_storage_manager.get_state().enable_laststand_mode == true
end

function IsEasyMode()
	return axr_main.config and axr_main.config:r_value("character_creation","new_game_easy_mode",1) == true or alife_storage_manager.get_state().enable_easy_mode == true
end

function IsGoodWpn()
	return axr_main.config and axr_main.config:r_value("character_creation","new_game_good_wpn",1) == true or alife_storage_manager.get_state().enable_good_wpn == true
end

function IsGoodLoot()
	return axr_main.config and axr_main.config:r_value("character_creation","new_game_good_loot",1) == true or alife_storage_manager.get_state().enable_good_loot == true
end


--------------------------------------------------------------------
-- Serialization of userdata for Marshal Library
--------------------------------------------------------------------
if (marshal) then
	function game_CTime___persist(self)
		local Y, M, D, h, m, s, ms = 0,0,0,0,0,0,0
		if (self and self.get) then
			Y, M, D, h, m, s, ms = self:get(Y, M, D, h, m, s, ms)
		end
		return function ()
			local t = game.CTime()
			t:set(Y, M, D, h, m, s, ms)
			return t
		end
	end
	getmetatable(game.CTime()).__persist = game_CTime___persist
end

-- debug to find objects that shouldn't be calling game_object:alive()
--[[
game_object.alive = function(self)
	callstack()
	printf("alive %s",self:name())
	local se_obj = alife_object(self:id())
	return se_obj:alive()
end
--]]
--------------------------------------------------------------------
function is_empty(t)
	if not (t) then
		return true
	end
	for i,j in pairs(t) do
		return false
	end
	return true
end

function strformat(text,...)
	if not (text) then return end
	local i = 0
	local p = {...}
	local function sr(a)
		i = i + 1
		if (type(p[1]) == "userdata") then
			return "userdata"
		end
		return tostring(p[i])
	end
	-- so that it doesn't return gsub's multiple returns
	local s = string.gsub(text,"%%s",sr)
	return s
end

-- Used by modules.script for generic module management
schemes = {}
schemes_by_stype = {}
function LoadScheme(filename, scheme, ...)
	if not (_G[filename]) then
		printf("ERROR: Trying to load scheme that does not exist! %s",filename)
		return
	end
	schemes[scheme] = filename
		local p = {...}
	for i=1,#p do
		if not (schemes_by_stype[p[i]]) then
			schemes_by_stype[p[i]] = {}
		end
		schemes_by_stype[p[i]][scheme] = true
	end
end

function printf(fmt,...)
	if not (fmt) then return end
	local fmt = tostring(fmt)

	if (select('#',...) >= 1) then
		local i = 0
		local p = {...}
		local function sr(a)
			i = i + 1
			if (type(p[i]) == 'userdata') then
				if (p[i].x and p[i].y) then
					return vec_to_str(p[i])
				end
				return 'userdata'
			end
			return tostring(p[i])
		end
		fmt = string.gsub(fmt,"%%s",sr)
	end
	if (log) then
		log(fmt)
		--get_console():execute("flush")
	else
		get_console():execute("load ~#debug msg:"..fmt)
	end	
end

function spairs(t, order)
    -- collect the keys
    local keys = {}
    for k in pairs(t) do keys[#keys+1] = k end

    -- if order function given, sort by it by passing the table and keys a, b,
    -- otherwise just sort the keys
    if order then
        table.sort(keys, function(a,b) return order(t, a, b) end)
    else
        table.sort(keys)
    end

    -- return the iterator function
    local i = 0
    return function()
        i = i + 1
        if keys[i] then
            return keys[i], t[keys[i]]
        end
    end
end
----------------------------------------------------------------------
function time_global()
	return device():time_global()
end

--[[ does not work?
function wait_game(time_to_wait)
	verify_if_thread_is_running()
	if (time_to_wait == nil) then
		coroutine.yield()
	else
		local time_to_stop = game.time() + time_to_wait
		while game.time() <= time_to_stop do
			coroutine.yield()
		end
	end
end

function wait(time_to_wait)
	verify_if_thread_is_running()
	if (time_to_wait == nil) then
		coroutine.yield()
	else
		local time_to_stop = time_global() + time_to_wait
		while time_global() <= time_to_stop do
			coroutine.yield()
		end
	end
end
--]]

function action(obj,...)
	local arg = {...}
	local e_act = entity_action()
	for i=1,#arg do 
		e_act:set_action(arg[i])
	end 
	if (obj ~= nil) then
		obj:command(e_act,false)
	end
	return entity_action(e_act)
end

function action_first(obj,...)
	local arg = {...}
	local e_act = entity_action()
	for i=1,#arg do 
		e_act:set_action(arg[i])
	end 
	if (obj ~= nil) then
		obj:command(e_act,true)
	end
	return entity_action(e_act)
end

function round (value)
	local min = math.floor (value)
	local max = min + 1
	if value - min > max - value then return max end
	return min
end

function distance_between(obj1, obj2)
	return obj1:position():distance_to(obj2:position())
end

-- +��� ���� ������ nil, �������� ��� ������, �� �������, ��� �� ������
function distance_between_safe(obj1, obj2)
	if(obj1 == nil or obj2 == nil) then return 100000 end
	return obj1:position():distance_to(obj2:position())
end

--' �������� �� ���������v, ���� ���� ������ �� ��	�������
function has_alife_info(info_id)
	local sim = alife()
	return sim:has_info(0, info_id)
end

function reset_action (npc, script_name)
	if npc:get_script () then
		 npc:script (false, script_name)
	end
	npc:script (true, script_name)
end

--------------------------------------------------
-- Functions and variables added by Zmey
--------------------------------------------------

-- ���������, ������ ������������ � ������, ��� ����� ������ �������������� ����� ��������
time_infinite = 100000000

-- +��� � ����v� ������ �v��������� �����-�� ��������, ����v���� ��� � �������� ��������v� �����
function interrupt_action(who, script_name)
	if who:get_script() then
		who:script(false, script_name)
	end
end

function random_choice(...)
	local arg = {...}
	if (#arg > 0) then
		local r = math.random(1, #arg)
		return arg[r]
	end
end

function random_number (min_value, max_value)
	if min_value == nil and max_value == nil then
		return math.random ()
	else
		return math.random (min_value, max_value)
	end
end

function parse_names( s )
	local t = {}
	--for name in string.gmatch( s, "([%w_\\]+)%p*" ) do
	for name in string.gmatch( s, "([%w_%-.\\]+)%p*" ) do
		t[#t+1] = name
	end
	return t
end

function parse_key_value( s )
	local t = {}
	if s == nil then
		return nil
	end
	local key, nam = nil, nil
	for name in string.gmatch( s, "([%w_\\]+)%p*" ) do
		if key == nil then
			key = name
		else
			t[key] = name
			key = nil
		end
	end
	return t
end

function parse_nums( s )
	local t = {}
	for entry in string.gmatch( s, "([%-%d%.]+)%,*" ) do
		t[#t+1] = tonumber(entry)
	end
	return t
end

function get_clsid(obj)
	if not (obj) then
		callstack()
		printf("ERROR: get_clsid - obj is nil!")
		return
	end
	if not (obj.clsid) then
		callstack()
		printf("ERROR: no clsid method for %s",obj:name())
		return
	end
	return obj:clsid()
end

--Tv������� yaw � ��������
function yaw( v1, v2 )
	return  math.acos( ( (v1.x*v2.x) + (v1.z*v2.z ) ) / ( math.sqrt(v1.x*v1.x + v1.z*v1.z ) * math.sqrt(v2.x*v2.x + v2.z*v2.z ) ) )
end
function yaw_degree( v1, v2 )
	return  (math.acos( ( (v1.x*v2.x) + (v1.z*v2.z ) ) / ( math.sqrt(v1.x*v1.x + v1.z*v1.z ) * math.sqrt(v2.x*v2.x + v2.z*v2.z ) ) ) * 57.2957)
end
function yaw_degree3d( v1, v2 )
	return  (math.acos((v1.x*v2.x + v1.y*v2.y + v1.z*v2.z)/(math.sqrt(v1.x*v1.x + v1.y*v1.y + v1.z*v1.z )*math.sqrt(v2.x*v2.x + v2.y*v2.y + v2.z*v2.z)))*57.2957)
end
function vector_cross(v1, v2)
	return vector():set(v1.y  * v2.z  - v1.z  * v2.y, v1.z  * v2.x  - v1.x  * v2.z, v1.x  * v2.y  - v1.y  * v2.x)
end

--������������ ������ ������ ��� y ������ ������� �������.
function vector_rotate_y(v, angle)
	angle = angle * 0.017453292519943295769236907684886
	local c = math.cos (angle)
	local s = math.sin (angle)
	return vector ():set (v.x * c - v.z * s, v.y, v.x * s + v.z * c)
end

-- ������� �������.
function iempty_table (t)
	if not (t) then
		return {}
	end
	while #t > 0 do
		table.remove(t)
	end
	return t
end

function empty_table(t)
	if not (t) then
		return {}
	end
	for k,v in pairs(t) do
		t[k] = nil
	end
	return t
end

function stop_play_sound(obj)
	if (IsStalker(obj) and not obj:alive()) then
		return
	end
	obj:set_sound_mask(-1)
	obj:set_sound_mask(0)
end

-- �������� ������� ��� ������.
function print_table(table, subs)
	--[[
	local sub
	if subs ~= nil then
		sub = subs
	else
		sub = ""
	end
	for k,v in pairs(table) do
		if type(v) == "table" then
			print_table(v, sub.."["..k.."]----->")
		elseif type(v) == "function" then
			printf(sub.."%s = function",k)
		elseif type(v) == "userdata" then
			if (v.x) then
				printf(sub.."%s = %s",k,alun_utils.vector_to_string(v))
			else
				printf(sub.."%s = userdata", k)
			end
		elseif type(v) == "boolean" then
					if v == true then
							if(type(k)~="userdata") then
									printf(sub.."%s = true",k)
							else
									printf(sub.."userdata = true")
							end
					else
							if(type(k)~="userdata") then
									printf(sub.."%s = false", k)
							else
									printf(sub.."userdata = false")
							end
					end
		else
			if v ~= nil then
				printf(sub.."%s = %s", k,v)
			else
				printf(sub.."%s = nil", k,v)
			end
		end
	end
	--]]
end
function store_table(table, subs)
	local sub
	if subs ~= nil then
		sub = subs
	else
		sub = ""
	end
	printf(sub.."{")
	for k,v in pairs(table) do
		if type(v) == "table" then
			printf(sub.."%s = ", tostring(k))
			store_table(v, sub.."    ")
		elseif type(v) == "function" then
			printf(sub.."%s = \"func\",", tostring(k))
			elseif type(v) == "userdata" then
					printf(sub.."%s = \"userdata\",", tostring(k))
		elseif type(v) == "string" then
			printf(sub.."%s = \"%s\",", tostring(k), tostring(v))
		else
			printf(sub.."%s = %s,", tostring(k), tostring(v))
		end
	end
	printf(sub.."},")
end
----------------------------------------
function IsWounded(o)
	if not (o:clsid() == clsid.script_stalker and o:alive()) then 
		return false 
	end 
	
	if (o:critically_wounded() or o:in_smart_cover()) then 
		return false 
	end
	
	if o:best_enemy() and utils.load_var(o, "wounded_fight") == "true" then
		return false
	end
	
	local state = tostring(utils.load_var(o, "wounded_state"))
	if (state == "nil") then
		return false
	end
	
	return true
end
-------------------------------------------------------------------------------------------
-- 										CLASS TESTING
-------------------------------------------------------------------------------------------
local monster_classes
local weapon_classes
local artefact_classes
local anomaly_classes

function IsOutfit(o,c)
	if not c then
		c = o and o:clsid()
	end
	return c and (c == clsid.equ_stalker_s or c == clsid.equ_stalker)
end

function IsHeadgear(o,c)
	if not c then
		c = o and o:clsid()
	end
	return c and (c == clsid.equ_helmet_s or c == clsid.helmet)
end

function IsExplosive(o,c)
	if not c then
		c = o and o:clsid()
	end
	return c and (c == clsid.obj_explosive_s or  c == clsid.obj_explosive)
end

function IsAddon(o)

	local addons = {
		["wpn_addon_scope"] = true,
		["wpn_addon_scope_x2.7"] = true,
		["wpn_addon_scope_detector"] = true,
		["wpn_addon_scope_night"] = true,
		["wpn_addon_scope_susat"] = true,
		["wpn_addon_scope_susat_x1.6"] = true,
		["wpn_addon_scope_susat_custom"] = true,
		["wpn_addon_scope_susat_dusk"] = true,
		["wpn_addon_scope_susat_night"] = true,
		["wpn_addon_silencer"] = true,
		["wpn_addon_grenade_launcher"] = true,
		["wpn_addon_grenade_launcher_m203"] = true,
	}
	
	return addons[tostring(o:section())]
end

function IsKnife(o,c)

	if not o then return false end
	
	if not (c) then
		c = o and o:clsid()
	end
	
	--if not string.match(tostring(o:section()),"wpn_knife") then return false end
	
	local knife = {
		[clsid.wpn_knife] = true,
		[clsid.wpn_knife_s] = true,
	}
	return c and knife[c] or false
end

function IsPistol(o,c)
	if not (c) then
		c = o and o:clsid()
	end
	local pistol = {
					[clsid.wpn_pm_s] = true,
					[clsid.wpn_walther_s] = true,
					[clsid.wpn_usp45_s] = true,
					[clsid.wpn_hpsa_s] = true,
					[clsid.wpn_lr300_s] = true,
					[clsid.wpn_pm] = true,
					[clsid.wpn_walther] = true,
					[clsid.wpn_usp45] = true,
					[clsid.wpn_hpsa] = true,
					[clsid.wpn_lr300] = true
	}
	return c and pistol[c] or false
end

function IsSniper(o,c)
	if not (c) then
		c = o and o:clsid()
	end
	local sniper = {
				[clsid.wpn_svu_s] = true,
				[clsid.wpn_svd_s] = true,
				[clsid.wpn_vintorez_s] = true,
				[clsid.wpn_svu] = true,
				[clsid.wpn_svd] = true,
				[clsid.wpn_vintorez] = true
	}
	return c and sniper[c] or false
end

function IsLauncher(o,c)
	if not (c) then
		c = o and o:clsid()
	end
	local launcher = {
					[clsid.wpn_rg6_s] = true,
					[clsid.wpn_rpg7_s] = true,
					[clsid.wpn_rg6] = true,
					[clsid.wpn_rpg7] = true
	}
	return c and launcher[c] or false
end

function IsShotgun(o,c)
	if not (c) then
		c = o and o:clsid()
	end
	local shotgun = {
				[clsid.wpn_bm16_s] = true,
				[clsid.wpn_shotgun_s] = true,
				[clsid.wpn_auto_shotgun_s] = true,
				[clsid.wpn_bm16] = true,
				[clsid.wpn_shotgun] = true
				--[clsid.wpn_auto_shotgun] = true
	}
	return c and shotgun[c] or false
end

function IsRifle(o,c)
	if not (c) then
		c = o and o:clsid()
	end
	local rifle = {
				[clsid.wpn_ak74_s] = true,
				[clsid.wpn_groza_s] = true,
				[clsid.wpn_val_s] = true,
				[clsid.wpn_ak74] = true,
				[clsid.wpn_groza] = true,
				[clsid.wpn_val] = true
	}
	return c and rifle[c] or false
end

function IsMonster(o,c)
	if not (c) then
		c = o and o:clsid()
	end
	if not (monster_classes) then
		monster_classes = {
		[clsid.bloodsucker_s] 			= true,
		[clsid.boar_s] 					= true,
		[clsid.dog_s] 					= true,
		[clsid.flesh_s] 				= true,
		[clsid.pseudodog_s] 			= true,
		[clsid.burer_s] 				= true,
		[clsid.cat_s] 					= true,
		[clsid.rat] 					= true,
		[clsid.rat_s]					= true,
		[clsid.chimera_s] 				= true,
		[clsid.controller_s] 			= true,
		[clsid.fracture_s] 				= true,
		[clsid.poltergeist_s] 			= true,
		[clsid.gigant_s] 				= true,
		[clsid.zombie_s] 				= true,
		[clsid.snork_s] 				= true,
		[clsid.tushkano_s] 				= true,
		[clsid.psy_dog_s] 				= true,
		[clsid.psy_dog_phantom_s] 		= true
		}
	end
	return c and monster_classes[c] or false
end

function IsMonsterRat(o,c)
	if not (c) then
		c = o and o:clsid()
	end
	if not (monster_rat_classes) then
		monster_rat_classes = {
		[clsid.rat] 					= true,
		[clsid.rat_s]					= true,
		[clsid.tushkano_s] 				= true,
		}
	end
	return c and monster_rat_classes[c] or false
end

function IsAnomaly(o,c)
	if not (c) then
		c = o and o:clsid()
	end
	if not (anomaly_classes) then
		anomaly_classes = {
		[clsid.zone]				= true,
		[clsid.zone_acid_fog]		= true,
		[clsid.zone_bfuzz]			= true,
		[clsid.zone_campfire]		= true,
		[clsid.zone_dead]			= true,
		[clsid.zone_galantine]		= true,
		[clsid.zone_mincer]			= true,
		[clsid.zone_mosquito_bald]	= true,
		[clsid.zone_radioactive]	= true,
		[clsid.zone_rusty_hair]		= true,
		[clsid.zone_bfuzz_s]		= true,
		[clsid.zone_mbald_s]		= true,
		[clsid.zone_galant_s]		= true,
		[clsid.zone_mincer_s]		= true,
		[clsid.zone_radio_s]		= true,
		[clsid.zone_torrid_s]		= true,
		[clsid.zone_nograv_s]		= true,
		}
	end
	return c and anomaly_classes[c] or false
end

function isLc(obj)
	return (obj:clsid() == clsid.level_changer)
end

function IsStalker(o,c)
	if not (c) then
		c = o and o:clsid()
	end
	return c and (c == clsid.script_stalker or c == clsid.script_actor) or false
end

function IsTrader(o,c)
	if not (c) then
		c = o and o:clsid()
	end
	return c and (c == clsid.script_trader) or (o and trade_manager.GetTraderIsReal(o:id())) or false
end 

function IsHelicopter(o,c)
	if not (c) then
		c = o and o:clsid()
	end
	return c and (c == clsid.helicopter or c == clsid.car or c == clsid.script_heli) or false
end

function IsWeapon(o,c)
	if not (c) then
		c = o and o:clsid()
	end
	if not (weapon_classes) then
		weapon_classes = {
				[clsid.wpn_vintorez_s] 			= true,
				[clsid.wpn_ak74_s] 				= true,
				[clsid.wpn_lr300_s] 			= true,
				[clsid.wpn_hpsa_s] 				= true,
				[clsid.wpn_pm_s] 				= true,
				[clsid.wpn_shotgun_s] 			= true,
				[clsid.wpn_auto_shotgun_s]		= true,
				[clsid.wpn_bm16_s] 				= true,
				[clsid.wpn_svd_s] 				= true,
				[clsid.wpn_svu_s] 				= true,
				[clsid.wpn_rg6_s] 				= true,
				[clsid.wpn_rpg7_s] 				= true,
				[clsid.wpn_val_s] 				= true,
				[clsid.wpn_walther_s] 			= true,
				[clsid.wpn_usp45_s] 			= true,
				[clsid.wpn_groza_s] 			= true,
				[clsid.wpn_knife_s]				= true,
				[clsid.wpn_vintorez] 			= true,
				[clsid.wpn_ak74] 				= true,
				[clsid.wpn_lr300] 				= true,
				[clsid.wpn_hpsa] 				= true,
				[clsid.wpn_pm] 					= true,
				[clsid.wpn_shotgun] 			= true,
				[clsid.wpn_bm16] 				= true,
				[clsid.wpn_svd] 				= true,
				[clsid.wpn_svu] 				= true,
				[clsid.wpn_rg6] 				= true,
				[clsid.wpn_rpg7] 				= true,
				[clsid.wpn_val] 				= true,
				[clsid.wpn_walther] 			= true,
				[clsid.wpn_usp45] 				= true,
				[clsid.wpn_groza] 				= true,
				[clsid.wpn_knife] 				= true
		}
	end
	return c and weapon_classes[c] or false
end

function IsAmmo(o,c)
	if not (c) then
		c = o and o:clsid()
	end
	return c and (c == clsid.wpn_ammo or c == clsid.wpn_ammo_s or c == clsid.wpn_ammo_vog25_s or c == clsid.wpn_ammo_m209_s)
end

function IsGrenade(o,c)
	if not (c) then
		c = o and o:clsid()
	end
	if not (grenade_classes) then
		grenade_classes = {
				[clsid.wpn_grenade_f1_s] 		= true,
				[clsid.wpn_grenade_rgd5_s] 		= true,
				[clsid.wpn_grenade_launcher_s] 	= true,
				[clsid.wpn_grenade_fake] 		= true,
				[clsid.wpn_grenade_f1]			= true,
				[clsid.wpn_grenade_launcher] 	= true,
				[clsid.wpn_grenade_rgd5] 		= true,
				[clsid.wpn_grenade_rpg7]		= true
		}
	end
	return c and grenade_classes[c] or false
end

function IsArtefact(o,c)
	if not (c) then
		c = o and o:clsid()
	end
	if not (artefact_classes) then
		artefact_classes = {
		[clsid.art_bast_artefact] 		= true,
		[clsid.art_black_drops] 		= true,
		[clsid.art_dummy] 				= true,
		[clsid.art_electric_ball] 		= true,
		[clsid.art_faded_ball] 			= true,
		[clsid.art_galantine] 			= true,
		[clsid.art_gravi] 				= true,
		[clsid.art_gravi_black] 		= true,
		[clsid.art_mercury_ball] 		= true,
		[clsid.art_needles] 			= true,
		[clsid.art_rusty_hair] 			= true,
		[clsid.art_thorn] 				= true,
		[clsid.art_zuda] 				= true,
		[clsid.artefact] 				= true,
		[clsid.artefact_s] 				= true
		}
	end
	return c and artefact_classes[c] or false
end

function IsInvbox(o,c)
	if not (c) then
		c = o and o:clsid()
	end
	
	local visual = o and o:get_visual_name()
	---[[
	if (visual == "dynamics\\box\\expl_dinamit") then
		--printf("SYSTEM BOX")
		return false
	end
	--]]
	
	return c and (c == clsid.inventory_box_s or c == clsid.inventory_box)
end


function IsFood(item)

	if not item then return false end

	local list = {
		["bread"] = true,
		["breadold"] = true,
		["kolbasa"] = true,
		["conserva"] = true,
		["tomato"] = true,
		["sausage"] = true,
		["corn"] = true,
		["beans"] = true,
		["chili"] = true,
		["tushonka"] = true,
		["salmon"] = true,
		["raisins"] = true,
		["chocolate"] = true,
		["nuts"] = true,
		["protein"] = true,
		["mre"] = true,
		["mre_2"] = true,
		["mre_3"] = true,
		["ration_ru"] = true,
		["ration_ru_2"] = true,
		["ration_ru_3"] = true,
		["ration_ru_4"] = true,
		["ration_ru_5"] = true,
		["ration_ru_6"] = true,
		["ration_ru_7"] = true,
		["ration_ukr"] = true,
		["ration_ukr_2"] = true,
		["ration_ukr_3"] = true,
		["ration_ukr_4"] = true,
		["ration_ukr_5"] = true,
		["ration_ukr_6"] = true,
		["meat_rat"] = true,
		["meat_tushkano"] = true,
		["meat_dog"] = true,
		["meat_pseudodog"] = true,
		["meat_flesh"] = true,
		["meat_boar"] = true,
		["meat_bloodsucker"] = true,
		["meat_snork"] = true,
		["meat_chimera"] = true,
		--["mint"] = true,
		--["mint_2"] = true,
		--["mint_3"] = true,
		--[[
		["mineral_water"] = true,
		["mineral_water_2"] = true,
		["mineral_water_3"] = true,
		["water_drink"] = true,
		["flask"] = true,
		["flask_2"] = true,
		["flask_3"] = true,
		["tea"] = true,
		["tea_2"] = true,
		["tea_3"] = true,
		["drink_crow"] = true,
		["energy_drink"] = true,
		["bottle_metal"] = true,
		["bottle_metal_2"] = true,
		["bottle_metal_3"] = true,
		["vodka_quality"] = true,
		["vodka_quality_2"] = true,
		["vodka_quality_3"] = true,
		["beer"] = true,
		["vodka"] = true,
		["vodka_2"] = true,
		["vodka_3"] = true,
		--]]
	}

	return list[item:section()]
end


function IsMedicine(item)

	if not item then return false end

	local list = {
		["medkit"] = true,
		["medkit_army"] = true,
		["medkit_scientic"] = true,
		["stimpack"] = true,
		["stimpack_army"] = true,
		["stimpack_scientic"] = true,
		["bandage"] = true,
		["survival_kit"] = true,
		["antirad"] = true,
		["glucose"] = true,
		["glucose_s"] = true,
		["tetanus"] = true,
		["adrenalin"] = true,
		["salicidic_acid"] = true,
		["morphine"] = true,
		["drug_anabiotic"] = true,
		["drug_coagulant"] = true,
		["drug_coagulant_2"] = true,
		["drug_coagulant_3"] = true,
		["drug_coagulant_4"] = true,
		["drug_coagulant_5"] = true,
		["drug_psy_blockade"] = true,
		["drug_psy_blockade_2"] = true,
		["drug_psy_blockade_3"] = true,
		["drug_psy_blockade_4"] = true,
		["drug_psy_blockade_5"] = true,
		["drug_antidot"] = true,
		["drug_antidot_2"] = true,
		["drug_radioprotector"] = true,
		["drug_radioprotector_2"] = true,
		["drug_charcoal"] = true,
		["drug_charcoal_2"] = true,
		["drug_charcoal_3"] = true,
		["drug_charcoal_4"] = true,
		["drug_charcoal_5"] = true,
		["joint"] = true,
		["marijuana"] = true,
		["cocaine"] = true,
		["akvatab"] = true,
		["akvatab_2"] = true,
		["akvatab_3"] = true,
		["caffeine"] = true,
		["caffeine_2"] = true,
		["caffeine_3"] = true,
		["caffeine_4"] = true,
		["caffeine_5"] = true,
	}

	return list[item:section()]
end


-------------------------------------------------------------
-- 					SQUAD BEHAVIOR TESTING
-------------------------------------------------------------
is_squad_monster = {
		["monster_predatory_day"] 	= true,
		["monster_predatory_night"] = true,
		["monster_vegetarian"] 		= true,
		["monster_zombied_day"] 	= true,
		["monster_zombied_night"] 	= true,
		["monster_special"] 		= true,
		["monster"]					= true
}
squad_community_by_behaviour = {
		["stalker"]							= "stalker",
		["bandit"]							= "bandit",
        ["csky"]							= "csky",
		["dolg"]							= "dolg",
		["freedom"]							= "freedom",
		["army"]							= "army",
		["ecolog"]							= "ecolog",
		["killer"]							= "killer",
		["zombied"]							= "zombied",
		["monolith"]						= "monolith",
		["monster"]							= "monster",
		["monster_predatory_day"]			= "monster",
		["monster_predatory_night"]			= "monster",
		["monster_vegetarian"]				= "monster",
		["monster_zombied_day"]				= "monster",
		["monster_zombied_night"]			= "monster",
		["monster_special"]					= "monster"
}
-------------------------------------------------------------------------------------------
function get_object_community(obj)
	if type(obj.id) == "function" then
		return character_community(obj)
	else
		return alife_character_community(obj)
	end
end

function character_community (obj)
	if not (obj) then
		return
	end
	if IsStalker(obj) then
		return obj:character_community()
	end
	return "monster"
end

function alife_character_community (obj)
	if not (obj) then
		return
	end
	if IsStalker(obj, obj:clsid()) then
		return obj:community()
	end
	return "monster"
end

-- �������� ���������� �� �����_����.
function level_object_by_sid( sid )
	local sim = alife()
	if sim then
		local se_obj = sim:story_object( sid )
		if se_obj then
			return level.object_by_id( se_obj.id )
		end
	end
	return nil
end
-- �������� �������� ������� �� ����� ����.
function id_by_sid( sid )
	local sim = alife()
	if sim then
		local se_obj = sim:story_object( sid )
		if se_obj then
			return se_obj.id
		end
	end
	return nil
end

function abort(msg, ...)
	if not (msg) then return end
	local fmt = tostring(msg)

	if (select('#',...) >= 1) then
		local i = 0
		local p = {...}
		local function sr(a)
			i = i + 1
			if (type(p[i]) == 'userdata') then
				return 'userdata'
			end
			return tostring(p[i])
		end
		fmt = string.gsub(fmt,"%%s",sr)
	end
		callstack()
	log(fmt)
	--[[
	error(fmt, 2)
	--]]
end

function set_inactivate_input_time(delta)
	db.storage[db.actor:id()].disable_input_time = game.get_game_time()
	db.storage[db.actor:id()].disable_input_idle = delta
	level.disable_input()
end

-- ��������� ����� ����� ����� �� ����������
function odd( x )
	return math.floor( x * 0.5 ) * 2 == math.floor( x )
end

--' ��������� �� NPC �� ��������� ������
function npc_in_actor_frustrum(npc)
	local actor_dir = device().cam_dir
	--local actor_dir = db.actor:direction()
	local npc_dir = vec_sub(npc:position(),db.actor:position())
	local yaw = yaw_degree3d(actor_dir, npc_dir)
	--printf("YAW %s", tostring(yaw))
	return yaw < 35
end

--' L��������
function on_actor_critical_power()

end

function on_actor_critical_max_power()
end

--' ������������
function on_actor_bleeding()

end

function on_actor_satiety()
end

--' ��������
function on_actor_radiation()

end

--' ��������� ������
function on_actor_weapon_jammed()

end

--' �� ����� ������ ���� ����
function on_actor_cant_walk_weight()

end

--' ��� �����������
function on_actor_psy()
end

function give_info (info)
	db.actor:give_info_portion(info)
	--printf("DEBUG: GIVE INFO %s",info)
	--if (xrs_debug_tools and xrs_debug_tools.actor_info) then
	--	xrs_debug_tools.actor_info[info] = true
	--end
end
function disable_info (info)
	if has_alife_info(info) then
		--printf("DEBUG: DISABLE INFO %s",info)
		--printf("*INFO*: disabled npc='single_player' id='%s'", info)
		db.actor:disable_info_portion(info)
		--if (xrs_debug_tools and xrs_debug_tools.actor_info) then
		--	xrs_debug_tools.actor_info[info] = nil
		--end
	end
end

function create_ammo(section, position, lvi, gvi, pid, num)
	local ini = system_ini()

	local num_in_box = ini:r_u32(section, "box_size")
	local t = {}
	while num > num_in_box do
		t[#t+1] = alife():create_ammo(section, position, lvi,	gvi, pid, num_in_box)
		num = num - num_in_box
	end
	local obj = alife():create_ammo(section, position, lvi,	gvi, pid, num)
	table.insert(t, obj)
	return t
end

-- ����������� ������ � ������������ �� ���������
function get_param_string(src_string , obj)
	--printf("src_string is [%s] obj name is [%s]", tostring(src_string), obj:name())
	local script_ids = db.script_ids[obj:id()]
	local out_string, num = string.gsub(src_string, "%$script_id%$", tostring(script_ids))
	if num > 0 then
		return out_string , true
	else
		return src_string , false
	end
end

local save_marker_result = {}
-- ������� ��� �������� ������������ ���� ����
function set_save_marker(p, mode, check, prefix)
	prefix = tostring(prefix)
		if (check ~= true) then
		if mode == "save" then
			save_marker_result[prefix] = p:w_tell() or 0
			if p:w_tell() > 16000 then
				abort("ERROR: You are saving too much")
			end
		else
			save_marker_result[prefix] = p:r_tell() or 0
		end
		return
	end
		if not (save_marker_result[prefix]) then
		abort("ERROR set_save_marker:%s: Trying to check without marker mode=%s",prefix,mode)
		if (mode == "save") then
			p:w_u16(0)
		elseif (mode == "load") then
			p:r_u16()
		end
		return
	end
		if mode == "save" then
		local dif = p:w_tell() - save_marker_result[prefix]
		if dif >= 8000 then
			printf("ERROR set_save_marker:%s: WARNING! may be this is problem save point dif=%s",prefix,dif)
		end
		p:w_u16(dif)
	else
		local c_dif = p:r_tell() - save_marker_result[prefix]
		local dif = p:r_u16()
		if dif ~= c_dif then
			printf("ERROR set_save_marker:%s: INCORRECT LOAD dif=%s c_dif=%s", prefix, dif, c_dif)
		end
	end
		save_marker_result[prefix] = nil
end

-- ��������� ������ � ������.
function vec_to_str (vector)
	if vector == nil then return "nil" end
	return string.format("[%s:%s:%s]", vector.x, vector.y, vector.z)
end
-- ������� � ��� ���� ������ �������.
function callstack()
	if (log and debug and type(debug.traceback) == 'function') then
		log(debug.traceback('\n', 2))
	end
end
-- ������ team:squad:group �������.
function change_team_squad_group(se_obj, team, squad, group)
	local cl_obj = db.storage[se_obj.id] and db.storage[se_obj.id].object
	if cl_obj ~= nil then
		cl_obj:change_team(team, squad, group)
	else
		se_obj.team = team
		se_obj.squad = squad
		se_obj.group = group
	end
	--printf("_G:TSG: [%s][%s][%s]", tostring(se_obj.team), tostring(se_obj.squad), tostring(se_obj.group))
end
--     Story_ID -------------------------------------------------------------
function add_story_object(obj_id , story_obj_id)
	story_objects.get_story_objects_registry():register(obj_id , story_obj_id)
end

function get_story_se_object(story_obj_id)
	local obj_id = story_obj_id and story_objects.get_story_objects_registry():get(story_obj_id)
	if obj_id == nil then return nil end
	return alife_object(obj_id)
end

function get_story_object(story_obj_id)
	local obj_id = story_obj_id and story_objects.get_story_objects_registry():get(story_obj_id)
	if obj_id == nil then return nil end
	return (db.storage[obj_id] and db.storage[obj_id].object) or (level ~= nil and level.object_by_id(obj_id))
end

function get_object_story_id(obj_id)
	return obj_id and story_objects.get_story_objects_registry():get_story_id(obj_id)
end

function get_story_object_id(story_obj_id)
	return story_obj_id and story_objects.get_story_objects_registry():get(story_obj_id)
end

function unregister_story_object_by_id(obj_id)
	story_objects.get_story_objects_registry():unregister_by_id(obj_id)
end

function unregister_story_id(story_id)
	story_objects.get_story_objects_registry():unregister_by_story_id(story_id)
end

-----------------------------------------------------------------------------------------------
-- �������� ����� �������!!!!!
function get_object_squad(object,caller)
	if not (object) then
		return
	end
		if (object.group_id ~= nil and object.group_id ~= 65535) then
		return alife_object(object.group_id)
	end
		local sim = alife()
	local se_obj = type(object.id) == "function" and sim:object(object:id())
	return se_obj and se_obj.group_id ~= 65535 and sim:object(se_obj.group_id) or nil
end

function get_story_squad(story_id)
	local squad_id = get_story_object_id(story_id)
	return squad_id and alife_object(squad_id)
end

--�������� �� ���������� ���������.
function in_time_interval(val1, val2)
	local game_hours = level.get_time_hours()
	if val1 >= val2 then
		return game_hours < val2 or game_hours >= val1
	else
		return game_hours < val2 and game_hours >= val1
	end
end

function show_all_ui(show)
	local hud = get_hud()
	if not (hud) then
		return
	end
	if(show) then
		level.show_indicators()
--	    db.actor:restore_weapon()
		db.actor:disable_hit_marks(false)
		hud:show_messages()
	else
		if db.actor:is_talking() then
			db.actor:stop_talk()
		end
		level.hide_indicators_safe()
		hud:HideActorMenu()
		hud:HidePdaMenu()
		hud:hide_messages()
--	    db.actor:hide_weapon()
		db.actor:disable_hit_marks(true)
	end
end

------------------------------------------------------------------------------------------------------
-- ENGINE EXPORTS!!!
------------------------------------------------------------------------------------------------------
-- called when an inventory item is eaten/used
-- returning false will prevent the item from being used
function CInventory__eat(npc,item)
	local return_flag = true
	SendScriptCallback("on_before_item_use",npc,item,return_flag)
	return return_flag
end

-- Called before actor hit callback
-- returning false will ignore the hit completely
function CActor__BeforeHitCallback(actor,shit,bone_id)
	--[[
	local hit_to_section = {
		[hit.light_burn] = "light_burn",
		[hit.burn] = "burn",
		[hit.strike] = "strike",
		[hit.shock] = "shock",
		[hit.wound] = "wound",
		[hit.radiation] = "radiation",
		[hit.telepatic] = "telepatic",
		[hit.chemical_burn] = "chemical_burn",
		[hit.explosion] = "explosion",
		[hit.fire_wound] = "fire_wound",
	}
	--]]
	--printf("power=%s impuse=%s type=%s bone=%s who=%s",shit.power,shit.impulse,hit_to_section[shit.type],bone_id,shit.draftsman and shit.draftsman:name())
	if (shit.draftsman and shit.draftsman:id() == 0 and shit.type == hit.radiation and shit.power > 1) then
	    --printf("ignore radiation type damage")
	    return false
	end

	if (level.name() == "k00_marsh" and shit.draftsman and shit.draftsman:id() == 0 and shit.type == hit.strike) then
		for i = 1, 65535 do
			local se_obj = level.object_by_id(i)
			if (se_obj) and (se_obj:name() == "mar_smart_terrain_11_3_mine_thermal_with_steam_0009") then
			local dist = db.actor:position():distance_to(se_obj:position())
				if dist < 25 then
					--printf("ignore strike type damage")
				    return false
				end
			end
		end
	end
	
	if (shit.power > 0) then 
		if (shit.draftsman and shit.draftsman:id() ~= 0 and IsStalker(shit.draftsman) and shit.draftsman:relation(db.actor) == game_object.friend) then 
			return false 
		end
	end
	
	local flags = { ret_value = true }
	SendScriptCallback("actor_on_before_hit",shit,bone_id,flags)
	return flags.ret_value
end

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

get_console():execute("r__clear_models_on_unload 0")
function CALifeUpdateManager__on_before_change_level(packet)
--[[
	C++:
	net_packet.r					(&graph().actor()->m_tGraphID,sizeof(graph().actor()->m_tGraphID));
	net_packet.r					(&graph().actor()->m_tNodeID,sizeof(graph().actor()->m_tNodeID));
	net_packet.r_vec3				(graph().actor()->o_Position);
	net_packet.r_vec3				(graph().actor()->o_Angle);
--]]
-- Here you can do stuff when level changes BEFORE save is called, even change destination!. Packet is constructed as stated above

	-- Release dead bodies on level change (TODO: Determine if it's a bad idea to do this here)
	--[[
	local rbm = release_body_manager.get_release_body_manager()
	if (rbm) then
		rbm:clear(true)
	end
	--]]
	
	-- READ PACKET
	local pos,angle = vector(),vector()
	local gvid = packet:r_u16()
	local lvid = packet:r_u32()
	packet:r_vec3(pos)
	packet:r_vec3(angle)
	-- crazy hack to help prevent crash on Trucks Cemetery
	local gg = game_graph()
	if (gg:valid_vertex_id(gvid) and alife():level_name(gg:vertex(gvid):level_id()) == "k02_trucks_cemetery") then
		log("k02_trucks_cemetery hack r__clear_models_on_unload 1")
		get_console():execute("r__clear_models_on_unload 1")
	end
	--printf("CALifeUpdateManager__on_before_change_level pos=%s gvid=%s lvid=%s angle=%s",pos,gvid,lvid,angle)
	-- fix for car in 1.6 (TODO*kinda For some reason after loading a game ALL physic objects will not be teleported by TeleportObject need to investigate as to why, possibly something to do with object flags)
	local car = db.actor and db.actor:get_attached_vehicle()
	if (car) then
		TeleportObject(car:id(),pos,lvid,gvid)
	end
		-- REPACK it for engine method to read as normal
	--[[
	packet:w_begin(13)
	packet:w_u16(gvid)
	packet:w_u32(lvid)
	packet:w_vec3(pos)
	packet:w_vec3(angle)
	--]]
	-- reset read pointer
	packet:r_seek(2)
		
	if (bind_container.containers) then
		for id,t in pairs(bind_container.containers) do
			if (t.id) then
				pos.y = pos.y+100
				TeleportObject(t.id,pos,lvid,gvid)
			end
		end	
	end
end

-- '������ ������������� ����.
function run_dynamic_element(folder,close_inv)
   if close_inv==false then
      folder:ShowDialog(true)
   elseif close_inv==true then
		folder:ShowDialog(true)
		local hud = get_hud()
		if (hud) then
			hud:HideActorMenu()
			hud:HidePdaMenu()
		end
		level.show_weapon(false)
   else
      folder:ShowDialog(true)
   end
end

-- '�������� �������� � ������� ��.
function give_object_to_actor(obj,count)
  if count==nil then count=1 end
  for i=1, count do
     alife():create(obj,db.actor:position(),db.actor:level_vertex_id(),db.actor:game_vertex_id(),db.actor:id())
  end
end

function string.gsplit(s, sep, plain)
	local start = 1
	local done = false
	local function pass(i, j, ...)
		if i then
			local seg = s:sub(start, i - 1)
			start = j + 1
			return seg, ...
		else
			done = true
			return s:sub(start)
		end
	end
	return function()
		if done then return end
		if sep == '' then done = true return s end
		return pass(s:find(sep, start, plain))
	end
end

-- INI Extensions
local ini_cache = { [system_ini()] = {} }
function clear_ini_cache(ini)
	ini_cache[ini] = empty_table(ini_cache[ini])
end
if (USE_INI_MEMOIZE) then
	-- memoize ini results
	local function r_memoize(ini,s,k,def,typ)
		if not (s) then
			callstack()
		end
		
		if (ini_cache[ini]) then
			local key = s.."&"..k
			if (ini_cache[ini][key]) then
				return ini_cache[ini][key]
			end
		end
		
		if not (ini:section_exist(s) and ini:line_exist(s,k)) then
			return def
		end
		
		local result = ini:r_string(s,k)
		if (result) then
			if (typ == 0) then
				result = result == "true" or result == "1" or false
			elseif (typ == 1) then
				result = tonumber(result)
			end
			
			if (result ~= nil) then
				if (ini_cache[ini]) then
					local key = s.."&"..k
					if (ini_cache[ini][key]) then
						ini_cache[ini][key] = result
					end
				end
			end
		end
		
		return result == nil and def or result
	end

	function ini_file.r_string_ex(ini,s,k,def)
		return r_memoize(ini,s,k,def)
	end

	-- It is wise to use the def with r_bool_ex, because false and nil are consider 'not'. def is only returned on nil
	function ini_file.r_bool_ex(ini,s,k,def)
		return r_memoize(ini,s,k,def,0)
	end
	function ini_file.r_float_ex(ini,s,k,def)
		return r_memoize(ini,s,k,def,1)
	end
	function ini_file.r_line_ex(ini,s,k)
		if not (ini_cache[ini]) then
			ini_cache[ini] = {}
		end
		
		if (ini_cache[ini]) then
			local key = s .. "&" .. k
			if (ini_cache[ini][key]) then
				return unpack(ini_cache[ini][key])
			end
		end
		
		local a,b,c = ini:r_line(s,k,"","")
		
		if (ini_cache[ini]) then
			local key = s.."&"..k
			if (ini_cache[ini][key]) then
				ini_cache[ini][key] = {a,b,c}
			end
		end
		
		return a,b,c
	end
else
	function ini_file.r_string_ex(ini,s,k,def)
		--callstack()
		--printf("r_string_ex(%s,%s)",s,k)
		if not (ini:section_exist(s) and ini:line_exist(s,k)) then
			return def
		end
		return ini:r_string(s,k) or def
	end
	function ini_file.r_float_ex(ini,s,k,def)
		--callstack()
		--printf("r_float_ex(%s,%s)",s,k)
		if not (ini:section_exist(s) and ini:line_exist(s,k)) then
			return def
		end
		return ini:r_float(s,k) or def
	end
		function ini_file.r_bool_ex(ini,s,k,def)
		--callstack()
		if not (ini:section_exist(s) and ini:line_exist(s,k)) then
			return def
		end
		--printf("r_bool_ex(%s,%s)",s,k)
		local v = ini:r_string(s,k)
		return v == nil and def or v == "true" or v == "1" or false
	end
		function ini_file.r_line_ex(ini,s,k)
		--callstack()
		return ini:r_line(s,k,"","")
	end
end
function ini_file.r_string_to_condlist(ini,s,k,def)
	local src = ini:r_string_ex(s,k) or def
	if (src) then
		return xr_logic.parse_condlist(nil, s, k, src)
	end
end
function ini_file.r_list(ini,s,k,def)
	local src = ini:r_string_ex(s,k) or def
	if (src) then
		return parse_names(src)
	end
end

-----------------------------------------
-- New INI wrapper to replace alun_utils.cfg_file
class "ini_file_ex"
function ini_file_ex:__init(fname,advanced_mode)
	self.fname = getFS():update_path('$game_config$', '')..fname
	self.ini = ini_file(fname)
	self.cache = {}
	if (advanced_mode) then
		self.ini:set_override_names(true)
		self.ini:set_readonly(false)
		--self.ini:save_at_end(true)
	end
end

function ini_file_ex:save()
	self.ini:save_as(self.fname)
end

-- r_value and w_value cache results
function ini_file_ex:r_value(s,k,typ,def)
	local cache_result = self.cache[s.."&"..k]
	if (cache_result) then
		return cache_result
	end
	if not (self.ini:section_exist(s) and self.ini:line_exist(s,k)) then
		return def
	end
	local v = self.ini:r_string(s,k)
	if (typ == 1) then
		v = v == nil and def or v == "true" or false
	elseif (typ == 2) then
		v = tonumber(v) or def
	end
	self.cache[s.."&"..k] = v
	return v == nil and def or v
end

function ini_file_ex:w_value(s,k,val,comment)
	self.cache[s.."&"..k] = val
	self.ini:w_string(s,k,val ~= nil and tostring(val) or "",comment ~= nil and tostring(comment) or "")
end

function ini_file_ex:collect_section(section)
	local _t = {}

	local n = self.ini:section_exist(section) and self.ini:line_count(section) or 0
	if (n > 0) then
		for i = 0,n-1 do
			local res,id,val = self.ini:r_line(section,i,"","")
			_t[id] = val
		end
	end

	return _t
end

function ini_file_ex:get_sections(keytable)
	local t = {}
	local function itr(section)
		if (keytable) then
			t[section] = true
		else
			t[#t+1] = section
		end
	end
	self.ini:section_for_each(itr)
	return t
end

function ini_file_ex:remove_line(section,key)
	self.ini:remove_line(section,key)
end

function ini_file_ex:section_exist(section)
	return self.ini:section_exist(section)
end

function ini_file_ex:line_exist(section,key)
	return self.ini:section_exist(section) and self.ini:line_exist(section,key)
end

function ini_file_ex:r_string_ex(s,k)
	return self.ini:section_exist(s) and self.ini:line_exist(s,k) and self.ini:r_string(s,k) or nil
end

function ini_file_ex:r_bool_ex(s,k,def)
	if not(self.ini:section_exist(s) and self.ini:line_exist(s,k)) then
		return def
	end
	local v = self.ini:r_string(s,k)
	return v == nil and def or v == "true" or v == "1" or false
end

function ini_file_ex:r_float_ex(s,k)
	return self.ini:section_exist(s) and self.ini:line_exist(s,k) and tonumber(self.ini:r_string(s,k)) or nil
end

function ini_file_ex:r_string_to_condlist(s,k,def)
	local src = self:r_string_ex(s,k) or def
	if (src) then
		return xr_logic.parse_condlist(nil, s, k, src)
	end
end

function ini_file_ex:r_list(s,k,def)
	local src = self:r_string_ex(s,k) or def
	if (src) then
		return parse_names(src)
	end
end
-----------------------------------------
-- Constants
-----------------------------------------
VEC_ZERO 	= vector():set(0,0,0)
VEC_X 		= vector():set(1,0,0)
VEC_Y 		= vector():set(0,1,0)
VEC_Z 		= vector():set(0,0,1)

function vec_sub(a,b)
	return vector():set(a):sub(b)
end

function vec_add(a,b)
	return vector():set(a):add(b)
end