local uiState=require("src.app.base.ui.uiState")
local p_main = {}

function p_main:initPlace(referUI_,container_)
	local du=displayUtils:getInstance()
	local lu=languageUtils:getInstance()
	local uc=uiControl:getInstance()
	local _maskInfos={}
	--Place all displays----------------------------------------------------------
	referUI_.instance3= cc.Sprite:create("btnUp.png")
	referUI_.instance3.name="instance3"
	du:placeAndAddChildToContainer(referUI_.instance3,container_,0.50,0.50,0,0,0,1,1,1,1)
	du:setLogicParent(referUI_.instance3,referUI_)
	
	while #_maskInfos>0 do
		local _maskInfo=table.remove(_maskInfos)
		du:createMask(container_,_maskInfo.stencil,_maskInfo.maskNumber)
	end

end

return p_main