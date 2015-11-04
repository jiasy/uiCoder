[<File_doc|ui|/src/app/base/ui/disUIBtn.lua|replace>]
local disUI=require("src.app.base.ui.disUI")
local disUIBtn = class("disUIBtn",disUI)

function disUIBtn:ctor(params_)
	disUIBtn.super.ctor(self,params_)
	self.className="disUIBtn"
	self.displayType="base"
	self.name="none"
	self.btnGroup=nil
	self.pressing=false
	--实现长按监听
	self.pressCallFunc=nil
	self.moveOutCallFunc=nil
	self.normalCallFunc=nil
	--初始化的大小
	self.initScaleX=nil
	self.initScaleY=nil
	--控制父容器放缩
	self.parentScaleAction=nil
	self.parentScaleScaleTo=0.9
	self.parentScaleScaleTime=0.5
	self.parentScaleEaseType=32
	self.controlSelfActionScale=nil

	self.rollParent=nil

	self.currentBtnState=UC_BTNSTATE.UNINITED
end

--init--------------------------------------------------------
function disUIBtn:init(initDict_)--Btn的init一定会在上层init的时候执行
	disUIBtn.super.init(self,initDict_)
	self.rollParent=self:getParentUIByLayerType("roll")
	if self.rollParent==nil then
		self:addTouchEventListener()
		table.insert(self.rollParent.btnArr,self)
	end
end
--Special analyse--------------------------------------------------
function disUIBtn:specialDes()
	disUIBtn.super.specialDes(self,initDict_)
end

--Listener of touch
function disUIBtn:addTouchEventListener()
    local function began(touch,event) return self:onTouchBegan(touch, event) end
    local function moved(touch,event) self:onTouchMoved(touch,event) end
    local function ended(touch,event) self:onTouchEnded(touch,event) end
    local function cancelled(touch,event) self:onTouchEnded(touch,event) end
    self.touchListener = cc.EventListenerTouchOneByOne:create()--单击事件监听
    self.touchListener:setSwallowTouches(true)
    self.touchListener:registerScriptHandler(began,cc.Handler.EVENT_TOUCH_BEGAN )
    self.touchListener:registerScriptHandler(moved,cc.Handler.EVENT_TOUCH_MOVED )
    self.touchListener:registerScriptHandler(ended,cc.Handler.EVENT_TOUCH_ENDED )
    self.touchListener:registerScriptHandler(cancelled,cc.Handler.EVENT_TOUCH_CANCELLED )
    local eventDispatcher = self:getEventDispatcher()
    eventDispatcher:addEventListenerWithSceneGraphPriority(self.touchListener,self)
end

function disUIBtn:onTouchBegan(touch_,event_)
	if self.currentBtnState == UC_BTNSTATE.LOCK then return false end
	if self.currentBtnState == UC_BTNSTATE.UNINITED then assert(false,"ERROR : Touch a btn without initializ it.") end
	if self:isTouchAble(touch_) == false then return false end
	local _localPos=self:getPositionInSelf(touch_:getLocation())
	if self:posInRects(_localPos) then
		self.pressing=true
		if self.pressCallFunc then self.pressCallFunc() end
		if self.btnGroup == nil then
			self:toPressState(true)
		end
		return true
	else
		self.pressing=false
		return false
	end
end
function disUIBtn:onTouchMoved(touch_,event_)
	local _localPos=self:getPositionInSelf(touch_:getLocation())
	if self:posInRects(_localPos)==false then
		self:moveOut()
	end
end

function disUIBtn:moveOut()
	self.pressing=false
	if self.moveOutCallFunc then self.moveOutCallFunc() end
	if self.btnGroup == nil then
		self:toNormalState(true)
	end
end

function disUIBtn:onTouchEnded(touch_,event_)
	local _localPos=self:getPositionInSelf(touch_:getLocation())
	if self:posInRects(_localPos) and self.pressing then
		if self.normalCallFunc then self.normalCallFunc() end
		self:btnClicked()
	end
end

function disUIBtn:btnClicked()
	local _activeBool=false--是否触发
	local _isStateBack=false--状态切换回来
	if self.btnGroup == nil then
		_activeBool=true
		self:toNormalState(true)
	else
		if self.currentBtnState == UC_BTNSTATE.PRESS then
			local _nameInfo=self.uiControl:specialBtnAnalyse(self.name)
			--是状态切换，且有返回状态
			if _nameInfo and _nameInfo.type=="state" and _nameInfo.backState~="" then
				_activeBool=true
				_isStateBack=true
				self:toNormalState(false)
			else
				--按钮组只有一个按钮，它自己就是一个ratioBtn了...
				if #self.btnGroup.btnArr ==1 then
					_activeBool=true
					self:toNormalState(false)
				else
					_activeBool=false
				end
			end
		else
			_activeBool=true
			self:toPressState(false)
		end
	end
	if _activeBool then
		self:btnActive(_isStateBack)
	end
end
--按钮的实际触发
function disUIBtn:btnActive(isStateBack_)
	local _itemData=nil
	--list 和 roll 不实际处理任何按钮的点击方法
	--item 会处理，但同时也会越过 list和roll 直接调用roll的承载体的btnClicked方法
	local _itemParent=self:getParentUIByLayerType("item")
	if _itemParent then--是item的话，先调用一次item的方法。看看有什么操作。之后再调用所有列表的承载体。进行主层级的判断
		_itemData=_itemParent.initDict
		_itemParent:btnClicked(self.name,nil,nil,nil)
	end
	local _rollParent=self:getParentUIByLayerType("roll")
	if _rollParent then--在滚动层中
		local _listParent=self:getParentUIByLayerType("list")
		if _listParent then--在列表中
			_rollParent.parent:btnClicked(self.name,_rollParent.name,_listParent.name,_itemData)
		else
			_rollParent.parent:btnClicked(self.name,_rollParent.name,"",_itemData)
		end
	else--不在直接调用父容器方法
		self.parent:btnClicked(self.name,nil,nil,nil)
	end
	--播放音效
	if self.soundName then
		--TODO soundplay
	end
	--解析按钮名称，尽心界面跳转、状态切换等等操作。
	--这个一定最后执行，上面的调用了父容器处理一些数据，之后调用这个进行跳转
	self.uiControl:doUIOperationByInfo(self.uiControl:specialBtnAnalyse(self.name),isStateBack_)
end
--Touch in btn's rects
function disUIBtn:posInRects(localPos_)
    local _inTouch=false
    for _key,_rect in pairs(self.rects) do
    	if self.mathUtils:pointInRect(localPos_,_rect) then
			_inTouch=true
            break
        end
    end
    return _inTouch
end

--Sound when press
function disUIBtn:setSoundName(soundName_)
	self.soundName=soundName_
end
--Change btn's state
function disUIBtn:toNormalState(rightNow_)
	if self.name=="btn_act_scale" and self.currentBtnState~=UC_BTNSTATE.NORMAL then
		self:parentToScale(1)
	end
	self.pressing=false
	self:toBtnState(UC_BTNSTATE.NORMAL,rightNow_)
end
function disUIBtn:toPressState(rightNow_)
	if self.currentBtnState == UC_BTNSTATE.LOCK then return end
	if self.currentBtnState ~= UC_BTNSTATE.UNINITED then 
		if self.btnGroup~=nil then
			self.btnGroup:btnToPresseState(self)
		end
	end
	if self.name == "btn_act_scale" then
		self:parentToScale(self.parentScaleScaleTo)
	end
	self:toBtnState(UC_BTNSTATE.PRESS,rightNow_)
end
function disUIBtn:toLockState(rightNow_)
	self:toBtnState(UC_BTNSTATE.LOCK,rightNow_)
end
function disUIBtn:toBtnState(state_,rightNow_)
	self.currentBtnState=state_
	self:stateChange(self.uiStates[self.currentBtnState].stateName,rightNow_)
end

function disUIBtn:parentToScale(scaleTo_)
	if self.parent == nil then return end
	self:clearParentScaleActions()
	local _scaleAction=nil
	_scaleAction=cc.ScaleTo:create(self.parentScaleScaleTime,scaleTo_)
	_scaleAction = self.actionUtils:easeActionByType(_scaleAction,self.parentScaleEaseType)
	self.parentScaleAction = _scaleAction
	self.parent:runAction(self.parentScaleAction)
	_scaleAction=cc.ScaleTo:create(self.parentScaleScaleTime,1/scaleTo_*self.initScaleX,1/scaleTo_*self.initScaleY)
	_scaleAction = self.actionUtils:easeActionByType(_scaleAction,self.parentScaleEaseType)
	self.controlSelfActionScale = _scaleAction
	self:runAction(self.controlSelfActionScale)
end
function disUIBtn:clearParentScaleActions()
	if self.parentScaleAction then
		self.parent:stopAction(self.parentScaleAction)
		self.parentScaleAction = nil
	end
	if self.controlSelfActionScale then
		self:stopAction(self.controlSelfActionScale)
		self.controlSelfActionScale = nil
	end
end

--Create--
function disUIBtn:onCreate()
	disUIBtn.super.onCreate(self)
	self:toNormalState(true)
end

--Destory--
function disUIBtn:onDestory()
	disUIBtn.super.onDestory(self)
end

function disUIBtn:onDelete()
	self:clearParentScaleActions()
	if self.btnGroup then
		self.btnGroup:deleteRefer(self)
	end
	self.btnGroup=nil
	if self.rollParent then
		self.arrayUtils:removeElement(self.rollParent.btnArr,self)
	end
	self.rollParent=nil
	disUIBtn.super.onDelete(self)
end

return disUIBtn
