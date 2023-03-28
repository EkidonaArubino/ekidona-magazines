--[[ This algorithm was written by エキドナ　アルビノ | Ekidona Arubino | 15.10.22 | 18:49 (JST)
It was originally created for "Sediment" back in mid-August 2022 - its essence is to adjust the weight of the inventory to the weight of the items whose parameter has been changed.
This script should "slightly replace" the original by changing "actor_max_walk_weight" to match the "official" weight designation.
<=\|/=> 16.10.22 | 15:37 (JST) | I forgot to tritely add the calculation for artifacts and boosters, meh.
The whole algorithm has been slightly simplified, and a method for determining the booster has also been added.
I'll explain in advance: I don't use "ev_queue" for the reason that it stores time in the form "time_global" is a limitless variable whose value can exceed 2^32, and "CTime" is not suitable for measuring boosters - they are updated at the time of games, and are independent of in-game time.
For this reason, I decided to use the standard "delta time" function.
<=\|/=> 16.10.22 | 16:37 (JST) | Fixed a bug with applying the effect of an artifact from the inventory, meh.
<=\|/=> 29.10.22 | 23:40 (JST) ("LIAR!") | It was clarified that "set_actor_max_walk_weight" should not be set to values below zero - because of this, the player's ability to run is automatically blocked (although the weight value may not reach the limit).
<=\|/=> 31.10.22 | 04:13 (JST) | It turned out that the functions "get_artefact_additional_weight()" and "get_additional_max_walk_weight()" give values without taking into account the condition.
<=\|/=> 1.11.22 | 19:00 (JST) | At the request of the "craftsmen" I redid the system for registering boosters with an increase in the carry weight: now they do not stack. Also, a bug with the continuation of the booster effect after sleep has now been fixed (see "ui_sleep_dialog").
<=\|/=> 26.02.23 | 13:19 (JST) | "ui_eki_mags.xml"]]
function on_game_start()
	RegisterScriptCallback("actor_on_first_update",actor_on_first_update)
	RegisterScriptCallback("actor_on_update",actor_on_update)
	RegisterScriptCallback("actor_on_net_destroy",actor_on_net_destroy)
	RegisterScriptCallback("actor_on_item_use",actor_on_item_use)
end local WeightBoostArray,WeightText={}
function actor_on_first_update() local INV=ActorMenu.get_actor_menu()
	local xml=CScriptXmlInit() xml:ParseFile("ui_eki_mags.xml") WeightText=xml:InitTextWnd("actor_weight_caption",INV)
end function GetStringFromFloat(num,mod) mod=(mod or 0) local str=tostring(utils.round(num,mod))
	return(str:sub(1,string.len(tostring(math.floor(num)))+((mod>0 and mod+1)or 0)))--meh
end function actor_on_item_use(obj,sec) sec=(sec or obj:section()) local weight=(system_ini():r_float_ex(sec,"boost_max_weight")or 0)
	if(weight*(system_ini():r_float_ex(sec,"boost_time")or 0)<=0)then return end WeightBoostArray[sec]={weight,system_ini():r_float_ex(sec,"boost_time"),0}
	--table.insert(WeightBoostArray,{weight,system_ini():r_float_ex(sec,"boost_time"),0})
end function save_state(mdata) mdata.WeightBoostArray=WeightBoostArray end
function load_state(mdata) WeightBoostArray=(mdata.WeightBoostArray or {}) end
function actor_on_update(bind,delta) local weight,ialready=0,{}
	for k,v in pairs({{{7,12,15},3.5},{{1,2,3,4,5},2}})do
		for k2,v2 in pairs(v[1])do local obj=db.actor:item_in_slot(v2)
			if(obj)then ialready[obj:id()]=v[2] end
		end
	end local mweight,cweight,wdiff=system_ini():r_float_ex(system_ini():r_string_ex("actor","condition_sect"),"max_walk_weight"),0,1
	local function GetRealActorWeight(temp,item) weight=(weight+(item:weight()/(ialready[item:id()] or 1)))end
	local function GetRealMaxWeight(temp,item) if(IsArtefact(item) and(ialready[item:id()] or db.actor:is_on_belt(item)))or(IsOutfit(item) and(ialready[item:id()]))then
		local addweight=(((IsArtefact(item) and item:get_artefact_additional_weight())or item:get_additional_max_walk_weight())*item:condition())
		mweight=(mweight+addweight) cweight=(cweight+((addweight/wdiff)-addweight))
	end end db.actor:iterate_inventory(GetRealActorWeight) wdiff=(weight/db.actor:get_total_weight()) db.actor:iterate_inventory(GetRealMaxWeight)
	local WeightBoost,rtbl=0,{} for k,v in pairs(WeightBoostArray)do
		if(v[3]>=1)then WeightBoostArray[k]=nil else WeightBoost=(WeightBoost+v[1]) WeightBoostArray[k][3]=(v[3]+(delta/(1000*v[2])))end
	end --for i=1,#rtbl do table.remove(WeightBoostArray,rtbl[i]-(i-1))end--meh x2
	db.actor:set_actor_max_walk_weight((system_ini():r_float_ex(system_ini():r_string_ex("actor","condition_sect"),"max_walk_weight")/wdiff)+cweight+(WeightBoost/wdiff))
	WeightText:SetText(game.translate_string("ui_total_weight").." "..((GetStringFromFloat(weight,1).." "..game.translate_string("st_kg")).." / "..(GetStringFromFloat(mweight+WeightBoost,1).." "..game.translate_string("st_kg"))))
	WeightText:AdjustWidthToText()--meh x3
end function IncreaseBoostDelta(delta) for k,v in pairs(WeightBoostArray)do WeightBoostArray[k][3]=(v[3]+(delta/(1000*v[2])))end end
function actor_on_net_destroy() WeightText:Show(false)end