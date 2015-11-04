--class define--------------------------------------------------------
local disBase = class("disBase",
	function()
		local ret = cc.Layer:create()
    	ret:setAnchorPoint(cc.p(0,0))
    	return ret
	end
)
function disBase:ctor(params_)
	self.className="disBase"
    self.moduleName="none"
    self.displayType="none"
    self.lifeState="none"
	self.parent=nil--logic parent
	self.uiControl=uiControl:getInstance()--refer for uiControl
	self.soundControl=soundControl:getInstance()--refer for uiControl
	--utils refers
	self.actionUtils=actionUtils:getInstance()
	self.mathUtils=mathUtils:getInstance()
	self.arrayUtils=arrayUtils:getInstance()
	self.stringUtils=stringUtils:getInstance()
	self.timeUtils=timeUtils:getInstance()
	self.displayUtils=displayUtils:getInstance()
	self.initDict=nil
	self.inited=false
end

--init--------------------------------------------------------
function disBase:init(initDict_)
	if self.inited==true then
		assert(false,"ERROR "..self.displayType.." : "..self.moduleName.." : "..self.className.." already inited.")
	end
	self.inited=true
	self.initDict=initDict_
	self:onCreate()
end

--Change world position to local
function disBase:getPositionInSelf(position_)
    return self:convertToNodeSpace(position_)
end
--Change world position to local
function disBase:getPositionInWorld(position_)
    return self:convertToWorldSpace(position_)
end

--Get ui layer which container this. 
function disBase:getUiParent()
	local _currentLayer=self
	local _count=0
	while true do
		if _currentLayer.uiType=="none" then
			_currentLayer=self.parent
		else
			return _currentLayer
		end
		_count=_count+1
		assert(_count <=100,"ERROR disBase : getUiParent can't get uiParent _ "..self.moduleName.." : "..self.className)
	end
end
--Get disUi which container this by type.
function disBase:getParentUIByLayerType(layerType_)
	local _currentLayer=self
	while true do
		if _currentLayer.displayType =="base" then--disBtn/disFs
			_currentLayer=self.parent
		else--"ui"
			if _currentLayer.uiType=="none" then
				if _currentLayer.layerType ==layerType_ then--"sub"/"ui"/"list"/"roll"/"btn"/"item"/"title"
					return _currentLayer
				end
				_currentLayer=self.parent
			else--"bg"/"base"/"ui"/"pop"/"mask"/"tip"/"loading"/"debug"/
				return nil
			end
		end
	end
end

--Whether this displayObject can be clicked
function disBase:isTouchAble()
	--Didn't show on stage
	if self:isVisible()==false then return false end
	--Not create stage
	if self.lifeState~="create" then return false end
	--User's operation waitting
	if self.uiControl:isWaitZero()==false then return false end
	--Parent is visible or not.
	if self:isParentVisible()==false then return false end
	--check ui structure
	local _uiParent=self:getUiParent()
	if self.uiControl:isUiTouchAble(_uiParent) then
		return true
	else
		return false
	end
end

--Parent visible
function disBase:isParentVisible()
	local _currentParent=self
	while _currentParent~=self.ownerUi do
		if _currentParent:isVisible()==false then
			return false
		end
		_currentParent=_currentParent.parent
	end
	return true
end

--Create--
function disBase:onCreate()
	if self.lifeState=="none" or self.lifeState=="destory" then
		self.lifeState="create"
		self:setVisible(true)
		self.p=self.parent
	elseif self.lifeState=="create" then
		assert(false, self.moduleName.." : "..self.className.." already create~!")
	end
end
--Destory--
function disBase:onDestory()
	if self.lifeState=="create" then
		self.lifeState="destory"
		self:setVisible(false)
		self.p=nil
	elseif self.lifeState=="destory" then
		assert(false, self.moduleName.." : "..self.className.." already destory~!")
	elseif self.createBoo=="none" then
		print("NOTICE : "..self.moduleName.." : "..self.className.." destory without create...")
	end
end

--delete
function disBase:onDelete()
	if self.lifeState =="create" then
		self:onDestory()
	end
	self.initDict=nil
	self.uiControl=nil
	self.parent=nil
	--utils refers
	self.actionUtils=nil
	self.mathUtils=nil
	self.arrayUtils=nil
	self.stringUtils=nil
	self.timeUtils=nil
	self.displayUtils=nil
end

return disBase