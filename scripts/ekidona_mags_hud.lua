--[[--All by エキドナ　アルビノ (Ekidona Arubino)--]]--
--04.03.23 : 21:39 (JST)
EkiAddHUDInfo=nil
local function actor_on_first_update()
	EkiAddHUDInfo=inv_add_info() get_hud():AddDialogToRender(EkiAddHUDInfo)
end local function actor_on_net_destroy()
	if(EkiAddHUDInfo)then get_hud():RemoveDialogToRender(EkiAddHUDInfo) EkiAddHUDInfo=nil end
end
function on_game_start()
	RegisterScriptCallback("actor_on_first_update",actor_on_first_update)
	RegisterScriptCallback("actor_on_net_destroy",actor_on_net_destroy)
end
class "inv_add_info" (CUIScriptWnd)
function inv_add_info:__init() super() local xml=CScriptXmlInit() xml:ParseFile("ui_eki_mags.xml")
	self.WPNFrame=xml:InitStatic("actor_weapon_info",self) local lpos=self.WPNFrame:GetWndPos() self.WPNPos={lpos.x,lpos.y}
	self.WPNFrame.mag=xml:InitStatic("actor_weapon_info:magazine",self.WPNFrame) self.WPNFrame.mag:InitTexture("ui\\ui_icon_equipment")
	self.WPNFrame.ammo=xml:InitTextWnd("actor_weapon_info:ammo",self.WPNFrame)
end
function inv_add_info:UpdateWpnIcons(riser) local color,calpha=fcolor():set(self.WPNFrame.mag:GetTextureColor())
	local function change_alpha() calpha=math.max(0,math.min(255,math.floor(255*(color.a+((device().time_delta/1000)*(riser and 1 or -1))))))
		self.WPNFrame.mag:SetTextureColor(GetARGB(calpha,255,255,255)) local catext=fcolor():set(self.WPNFrame.ammo:GetTextColor())
		self.WPNFrame.ammo:SetTextColor(GetARGB(calpha,math.floor(255*catext.r),math.floor(255*catext.g),math.floor(255*catext.b)))
	end change_alpha() self.WPNFrame:Show(calpha>0)
end
function inv_add_info:Update() CUIScriptWnd.Update(self)
	local wpn,msec=db.actor:active_item() local sec=(wpn and wpn:section())
	if(sec)and(IsWeapon(wpn))and not(IsKnife(wpn))then
		if(ekidona_mags.GetWeaponGrenadeLauncher(wpn))then msec=alun_utils.str_explode(system_ini():r_string_ex(sec,"grenade_class"),",")[wpn:get_ammo_type()+1]
		elseif(ekidona_mags.WaMArray[wpn:id()])then msec=ekidona_mags.GetMagFromInd(ekidona_mags.WaMArray[wpn:id()])
		elseif(wpn:get_ammo_in_magazine()>0)then msec=alun_utils.str_explode(system_ini():r_string_ex(sec,"ammo_class"),",")[wpn:get_ammo_type()+1]end
	end if(msec)then local fary=ekidona_mags.GetTFrectFromSec(msec) self.WPNFrame.mag:SetTextureRect(Frect():set(unpack(fary)))
		local size={fary[3]-fary[1],fary[4]-fary[2]} self.WPNFrame.mag:SetWndSize(vector2():set(size[1],size[2]))
		self.WPNFrame:SetWndPos(vector2():set(self.WPNPos[1]-(size[1]-50),self.WPNPos[2]-(size[2]-50)))
		self.WPNFrame.ammo:SetWndPos(vector2():set(size[1]-50,size[2]-50)) self.WPNFrame.ammo:SetText(wpn:get_ammo_in_magazine())
	end self:UpdateWpnIcons(msec~=nil)
end