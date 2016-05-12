[<File_doc|ui|/src/app/base/ui/disUI.lua|replace>]
--class define--------------------------------------------------------
local disBase=require("src.app.base.ui.disBase")
local disUI = class("disUI",disBase)
function disUI:ctor(params_)
	disUI.super.ctor(self,params_)
    --"Bg"/"Base"/"Ui"/"Pop"/"Mask"/"Tip"/"Loading"/"Debug"/
    self.uiType="none"
    --"base"/"ui"
    self.displayType="ui"
    --"sub" 						def
    --"ui"/"list"/"roll"/"btn"      Change this value when sub class call ctor().Write in class templet.
    --"item"/"title"        		Change this value when List create items and title
    self.layerType="sub"
    self.placeClass=nil
    self.rects=nil
	self.currentState=nil
	self.stateAniSet=nil
	self.uiStates=nil
	self.uiAnis=nil
    self.displayCreated=false
   	self.displayClass=nil
   	self.hideOtherUi=nil
   	self.showAni=nil

   	--显示对象
   	self.displayList=nil--所有承载的显示对象
	self.uiList=nil--继承自DisUI的对象，只用于UI用
	self.disBaseList=nil--继承自DisUI的对象，非UI用。FrameSprite，Btn之类的
	self.uiBtnList=nil--uiBtn
end
--init--------------------------------------------------------
function disUI:init(initDict_)
	--Create display children.
	--Get special params.
	disUI.super.init(self,initDict_)
	--btn init
	self:subBtnsInit()
    --Analyse special params
    self:specialDes()
end

function disUI:subBtnsInit()
	for i=1,#self.uiBtnList do
		self.uiBtnList[i]:init({})
	end
end
--layerType == item时才有用
function disUI:setItemIndex(itemIndex_)
	self.initDict.itemIndex=itemIndex_
	self.name="item"..itemIndex_
end
--预设状态切换的缓动效果。
function disUI:stateAniPreset(stateName_,aniBool_,aniTime_,aniEaseType_)
	local _infoObj={}
	_infoObj["aniBool"]=aniBool_        --是否做动画
	_infoObj["aniTime"]=aniTime_        --动画时间
	_infoObj["aniEaseType"]=aniEaseType_--动画缓动效果
	self.stateAniSet[stateName_]=_infoObj
end
--
function disUI:stateChange(stateName_,rightNow_)
	local _stateName = stateName_
	local _state = self:getStateByName(stateName_)
	if _state then
		if self.currentState ~= _stateName then
			self.currentState = _stateName
			if rightNow_ then
				_state:activate(false)
			else
				if self.stateAniSet[_stateName]["aniBool"] then--有预设
					self:toState(_state)
				else--没预设
					_state:activate(false)
				end
			end
		end
	end
	for i=1,#self.uiList do
		local _tempUi=self.uiList[i]
		_tempUi:stateChange(stateName_)
	end
end
--
function disUI:uiStructureChange()
	if self.uiList==nil then
		return
	end
	for i=1,#self.uiList do
		local _tempUi=self.uiList[i]
		_tempUi:uiStructureChange()
	end
end
--
function disUI:getStateByName(stateName_)
	for i=1,#self.uiStates do
		if self.uiStates[i].stateName==stateName_ then
			return self.uiStates[i]
		end
	end
end
--
function disUI:toState(state_)
	local _stateAniSet=self.stateAniSet[state_.stateName]
	state_:activate(_stateAniSet["aniBool"],_stateAniSet["aniTime"],_stateAniSet["aniEaseType"])
end
--界面动画入场
--type_　　　　 方向类型 L左，R右，T上，B下，中间的T是to的意思
--easeType_ 　 缓动ID
--time_ 　　　　进行时间
--aniType_ 　　动画 add添加型动画，force被动型动画
function disUI:uiAnimation(type_,easeType_,time_,aniType_)
	local _action=nil
	local _initPos=nil
	local _animationEndCallBack=nil
	local _uc=self.uiControl

    local function animationBegin()
 		_uc:waitAdd()
    end

 	local function animationEnd()
    	_uc:waitSub()
    end

    if aniType_ == "add" then
		self.removeAnimationType     = type_
		self.removeAnimationEaseType = easeType_
		self.removeAnimationTime     = time_
    elseif aniType_ == "force" then
    	self.backAnimationType     = type_
		self.backAnimationEaseType = easeType_
		self.backAnimationTime     = time_
    end

	if type_ == "" or type_ == nil then
		self:setPosition(self.designPos)
	else
		animationBegin()
		_animationEndCallBack = cc.CallFunc:create(animationEnd)
		if type_ == "MO" then
			_initPos=self.designPos
			self:setScaleX(0.01)
			self:setScaleY(0.01)
			_action=cc.ScaleTo:create(time_,1)
		elseif type_ == "MI" then
			_initPos=self.designPos
			self:setScaleX(3)
			self:setScaleY(3)
			_action=cc.ScaleTo:create(time_,1)
		else
			if aniType_=="force" then
				_initPos=self.designPos
				if type_ == "LTR" then
					_action=cc.MoveTo:create(time_,cc.p(self.designPos.x+_uc.realWidth,self.designPos.y))
				elseif type_ == "RTL" then
					_action=cc.MoveTo:create(time_,cc.p(self.designPos.x-_uc.realWidth,self.designPos.y))
				elseif type_ == "TTB" then
					_action=cc.MoveTo:create(time_,cc.p(self.designPos.x,self.designPos.y-_uc.realHeight))
				elseif type_ == "BTT" then
					_action=cc.MoveTo:create(time_,cc.p(self.designPos.x,self.designPos.y+_uc.realHeight))
				end
			elseif aniType_=="add" then
				if type_ == "LTR" then
					_initPos=cc.p(self.designPos.x-_uc.realWidth,self.designPos.y)
				elseif type_ == "RTL" then
					_initPos=cc.p(self.designPos.x+_uc.realWidth,self.designPos.y)
				elseif type_ == "TTB" then
					_initPos=cc.p(self.designPos.x,self.designPos.y+_uc.realHeight)
				elseif type_ == "BTT" then
					_initPos=cc.p(self.designPos.x,self.designPos.y-_uc.realHeight)
				end
				_action=cc.MoveTo:create(time_,self.designPos)
			end
		end
		self:setPosition(_initPos)
	end

	if easeType_ and easeType_~="" then
		_action=self.actionUtils:easeActionByType(_action,easeType_)
	end

	if _action then
		if self.addAnimation then
			self:stopAction(self.addAnimation)
			self.addAnimation = nil
		end
	  	self.addAnimation= cc.Sequence:create(_action,_animationEndCallBack)
		self:runAction(self.addAnimation)
	end
end
--界面动画出场
--aniType_   动画类别，add添加动画的推出，force被动动画的退出
function disUI:animationOut(aniType_)
	local function animationEnd()
    	_uc:waitSub()
    end

    local function removeFromParentFun()
    	_uc:waitSub()
    	self:onDelete()
    end

	local _type
	local _easeType
	local _time
	if aniType_ == "force" then
		_type     = self.backAnimationType
		_easeType = self.backAnimationEaseType
		_time     = self.backAnimationTime
		self.backAnimationType     = nil
		self.backAnimationEaseType = nil
		self.backAnimationTime     = nil
	elseif aniType_ == "add" then
		_type     = self.removeAnimationType
		_easeType = self.removeAnimationEaseType
		_time     = self.removeAnimationTime
		self.removeAnimationType     = nil
		self.removeAnimationEaseType = nil
		self.removeAnimationTime     = nil
	end

	if _type~=nil then
		_uc:waitAdd()
		local _reverseAction=nil
		if _type == "MI" or type_ == "MO" then
			self:setVisible(false)
			_reverseAction=cc.DelayTime:create(0.01)
		else
			local _finalPos
			if aniType_=="force" then
				_finalPos=self.designPos
			elseif aniType_=="add" then
				if _type == "LTR" then
					_finalPos=cc.p(self.designPos.x-_uc.realWidth,self.designPos.y)
				elseif _type == "RTL" then
					_finalPos=cc.p(self.designPos.x+_uc.realWidth,self.designPos.y)
				elseif _type == "TTB" then
					_finalPos=cc.p(self.designPos.x,self.designPos.y+_uc.realHeight)
				elseif _type == "BTT" then
					_finalPos=cc.p(self.designPos.x,self.designPos.y-_uc.realHeight)
				end
			end
			_reverseAction=cc.MoveTo:create(_time,_finalPos)
		end 
		if _easeType and _easeType~="" then
			_reverseAction=self.actionUtils:easeActionByType(_reverseAction,_easeType)
		end

		local _sequenceOut
		local _animationEndCallBack
		if aniType_ == "add" then
			_animationEndCallBack = cc.CallFunc:create(removeFromParentFun)
			_sequenceOut=cc.Sequence:create(_reverseAction,_animationEndCallBack)
			self.removeAnimation=_sequenceOut
		elseif aniType_ == "force" then
			_animationEndCallBack = cc.CallFunc:create(animationEnd)
			_sequenceOut=cc.Sequence:create(_reverseAction,_animationEndCallBack)
			self.backAnimation=_sequenceOut
		end

		self:runAction(_sequenceOut)
	end
end

function disUI:close() self.uiControl:closeTop() end
function disUI:overlay(type_,moduleName_,className_) self.uiControl:uiOverlay(type_,moduleName_,className_) end
function disUI:pbs(param_) self.soundControl:playBackgroundSound(param_) end
function disUI:pes(param_) self.soundControl:playEffectSound(param_) end

--Call when btn click
function disUI:btnClicked(btnName_,rollName_,listName_,itemDataDict_)
	if self.layerType == "roll" or self.layerType == "list" then
		assert(false,"ERROR roll/list 不处理按钮方法")
	end
    print("-- 按钮点击 --------------------------")
    if self.layerType~="item" then
    	print("所在界面 : "..self.moduleName.." : "..self.className)
    	print("界面名称 : "..self.name)
    	if self.logicParent then
	        print("按钮所在UI是一个子UI，父容器为 : "..self.logicParent.moduleName.." : "..self.logicParent.className)
	    end
	    if rollName_ then 
	        print("按钮存在于滚动层中，所在滚动层名 : "..rollName_)
	        if listName_ then
	        	print("按钮存在于列表中，所在列表名 : "..listName_)
		        if itemDataDict_ then
		            print("按钮存在于一个item中，序号为 : "..itemDataDict_.itemIndex)
		        end
		    end
		    if itemDataDict_ then
		        print("按钮存在于一个item中，序号为 : "..itemDataDict_.itemIndex)
		    end
	    end
	else
		print("所在item : "..self.moduleName.." : "..self.className)
		print("item名称 : "..self.name)
	end
    print("按钮名 : "..btnName_)
end

--Special analyse--------------------------------------------------
function disUI:specialDes()
	if self.alignMode then--alignMode
		local _point=self.uiControl.alignModePoints[self.alignMode]
		if _point then
			self:setPosition(self:getParent():convertToNodeSpace(self.uiControl.mainContainer:convertToWorldSpace(_point)))
			self.designPos=self:getPosition()
		else
			print('ERROR When Special key is "alignMode" \n    Value noly can be one of "LT"/"T"/"RT"/"LC"/"C"/"R"/"LB"/"B"/"RB"\n    Current value : '..self.alignMode.."\n")
		end
	end
end

function disUI:getDisplayClass()
	if self.displayClass==nil then
		self.displayClass=require("src.app.ui.places."..self.moduleName..".p_"..self.className)
	end
	return self.displayClass
end

--Update Frame
function disUI:updateF(type_)
	for i=1,#self.uiList do
		if self.uiList[i].lifeState=="create" then
			self.uiList[i]:updateF(type_)
		end
	end
end

--根据两个字典初始化
--specialDict_   需要init里初始化的UI
--avoidInit_     不需要在init里面初始化的UI
function disUI:initSubUIs(specialDict_,avoidInit_)
    for i=1,#self.uiList do
        local _subUI=self.uiList[i]
        local _subUIName=_subUI.name
        if specialDict_[_subUIName] then
            --初始化，且用自定义数据进行
            _subUI:init(specialDict_[_subUIName])
        else
            if avoidInit_[_subUIName] then
                --可能在其他时间初始化
            else
                --默认情况都会立刻初始化
                _subUI:init({})
            end
        end 
    end
    if specialDict_ then
	    for k,v in pairs(specialDict_) do
	    	if self[k]==nil then
	    		assert(false,"ERROR "..self.moduleName.." : "..self.className.." 中没有名称为 "..k.."的UI")
	    	end
	    	if avoidInit_ and avoidInit_[k] then
	    		assert(false,"ERROR "..self.moduleName.." : "..self.className.." 名为 "..k.."的UI，初始化设置矛盾，既有初始化字典，规避初始化设置中也存在")
	    	end
	    end
	end
	if avoidInit_ then
	    for k,v in pairs(avoidInit_) do
	    	if self[k]==nil then
	    		assert(false,"ERROR "..self.moduleName.." : "..self.className.." 中没有名称为 "..k.."的UI")
	    	end
	    end
	end

end

--Display children add
function disUI:childrenAdd()
	self.displayList={}
	self.uiList={}--UI displays
	self.disBaseList={}--DIY displays
	self.uiBtnList={}--uiBtn
	self.uiStates={}
	self.uiAnis={}
	self.stateAniSet={}
	self.rects={}
	self:getDisplayClass():initPlace(self,self)
end
--Display children remove
function disUI:childrenRemove()
	if self.uiList then--ui refers
	    while #self.uiList>0 do
	    	local _uiLayer = self.uiList[#self.uiList]
	    	_uiLayer:onDelete()
			table.remove(self.uiList)
	    end
 		self.uiList=nil
	end
	if self.uiBtnList then
		while #self.uiBtnList>0 do
			table.remove(self.uiBtnList)
	    end
 		self.uiBtnList=nil
	end
	if self.disBaseList then--DIY displays refers
	    while #self.disBaseList>0 do
	    	local _disBase = self.disBaseList[#self.disBaseList]
	    	_disBase:onDelete()
			table.remove(self.disBaseList)
	    end
 		self.disBaseList=nil
	end
	if self.displayList then--displayList refers
	    while #self.displayList>0 do
	    	table.remove(self.displayList):removeFromParent(true)
		end
	    self.displayList=nil
	end
end

--Create--
function disUI:onCreate()
	disUI.super.onCreate(self)
	if self.displayCreated==false then
		self.displayCreated=true
		self:childrenAdd()
		self.uiControl:addUiRefer(self.moduleName,self.className)
	end
end
--Destory--
function disUI:onDestory()
	disUI.super.onDestory(self)
end

--delete
function disUI:onDelete()
	if self.lifeState =="create" then
		self:onDestory()
	end
	if self.displayCreated then
		self.uiControl:subUiRefer(self.moduleName,self.className)
	else
		print("NOTICE : "..self.moduleName.." : "..self.className.." kill without createDisplay...")
	end
	if self.uiStates then
		while #self.uiStates>0 do
			local _tempState=table.remove(self.uiStates)
			self.stateAniSet[_tempState.stateName]=nil
			_tempState:onDelete()
		end
		self.uiStates=nil
		self.stateAniSet=nil
	end
	while #self.rects>0 do
		table.remove(self.rects)
	end
	self.rects=nil
	self.displayClass=nil
	self:childrenRemove()
	
	disUI.super.onDelete(self)
end

return disUI