--[[ This algorithm was written by エキドナアルビノ | Ekidona Arubino | 31.03.23 | 16:27 (JST)]]
function on_game_start()
	RegisterScriptCallback("actor_on_first_update",actor_on_first_update)
	RegisterScriptCallback("actor_on_update",actor_on_update)
	RegisterScriptCallback("actor_on_net_destroy",actor_on_net_destroy)
	RegisterScriptCallback("actor_on_item_use",actor_on_item_use)
end local WeightText=nil
function ReturnWeightBoostArray() local mdata=alife_storage_manager.get_state()
	if not(mdata)then return(nil)end if not(mdata.WeightBoostArray)then mdata.WeightBoostArray={}end
	return(mdata.WeightBoostArray)
end
function GetWeightBoostArray(id) local mdata=alife_storage_manager.get_state()
	if not(mdata)then return(nil)end if not(mdata.WeightBoostArray)then mdata.WeightBoostArray={}end
	return(mdata.WeightBoostArray[id])
end
function SetWeightBoostArray(id,var) local mdata=alife_storage_manager.get_state()
	if not(mdata)then return end if not(mdata.WeightBoostArray)then mdata.WeightBoostArray={}end
	mdata.WeightBoostArray[id]=var
end
function actor_on_first_update() local INV=ActorMenu.get_actor_menu()
	local xml=CScriptXmlInit() xml:ParseFile("ui_eki_mags.xml") WeightText=xml:InitTextWnd("actor_weight_caption",INV)
end function GetStringFromFloat(num,mod) mod=(mod or 0) local str=tostring(utils.round(num,mod))
	return(str:sub(1,string.len(tostring(math.floor(num)))+((mod>0 and mod+1)or 0)))--meh
end function actor_on_item_use(obj,sec) sec=(sec or obj:section()) local weight=(system_ini():r_float_ex(sec,"boost_max_weight")or 0)
	if(weight*(system_ini():r_float_ex(sec,"boost_time")or 0)<=0)then return end SetWeightBoostArray(sec,{weight,system_ini():r_float_ex(sec,"boost_time"),0})
	--table.insert(ReturnWeightBoostArray(),{weight,system_ini():r_float_ex(sec,"boost_time"),0})
end
function actor_on_update(bind,delta)
	if not(WeightText)then return end local weight,ialready=0,{}
	for k,v in pairs({{{7,12,13},3.5},{{1,2,3},2}})do
		for k2,v2 in pairs(v[1])do local obj=db.actor:item_in_slot(v2)
			if(obj)then ialready[obj:id()]=v[2] end
		end
	end local mweight,cweight,wdiff=system_ini():r_float_ex(system_ini():r_string_ex("actor","condition_sect"),"max_walk_weight"),0,1
	local function GetRealActorWeight(temp,item) weight=(weight+(item:weight()/(ialready[item:id()] or 1)))end
	local function GetRealMaxWeight(temp,item) if(ialready[item:id()])or(IsArtefact(item) and db.actor:is_on_belt(item))then
		local addweight=(((IsArtefact(item) and item:get_artefact_additional_weight())or item:get_additional_max_walk_weight())*item:condition())
		mweight=(mweight+addweight) cweight=(cweight+((addweight/wdiff)-addweight))
	end end db.actor:iterate_inventory(GetRealActorWeight) wdiff=(weight/db.actor:get_total_weight()) db.actor:iterate_inventory(GetRealMaxWeight)
	local WeightBoost,rtbl=0,{} for k,v in pairs(ReturnWeightBoostArray())do
		if(v[3]>=1)then SetWeightBoostArray(k,nil) else WeightBoost=(WeightBoost+v[1]) GetWeightBoostArray(k)[3]=(v[3]+(delta/(1000*v[2])))end
	end --for i=1,#rtbl do table.remove(ReturnWeightBoostArray(),rtbl[i]-(i-1))end--meh x2
	db.actor:set_actor_max_walk_weight((system_ini():r_float_ex(system_ini():r_string_ex("actor","condition_sect"),"max_walk_weight")/wdiff)+cweight+(WeightBoost/wdiff))
	WeightText:SetText(game.translate_string("ui_total_weight").." "..((GetStringFromFloat(weight,1).." "..game.translate_string("st_kg")).." / "..(GetStringFromFloat(mweight+WeightBoost,1).." "..game.translate_string("st_kg"))))
	WeightText:AdjustWidthToText()--meh x3
end function IncreaseBoostDelta(delta) for k,v in pairs(ReturnWeightBoostArray())do GetWeightBoostArray(k)[3]=(v[3]+(delta/(1000*v[2])))end end
function actor_on_net_destroy() WeightText:Show(false)end