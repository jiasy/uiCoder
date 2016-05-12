[<File_doc|ui|/src/app/base/ui/disMC.lua|replace>]
--class define--------------------------------------------------------
local disUI=require("src.app.base.ui.disUI")
local disMC = class("disMC",disUI)

function disMC:ctor(params_)
	disMC.super.ctor(self,params_)
	self.totalFrames=0
	self.frameNames={}
	self.frameActions={}
	self.mcChildObjectArr={}
	self.mcControl=mcControl:getInstance()
	self.testUtils=testUtils:getInstance()
end

function disMC:gtp(param_) self:gotoAndPlay(param_) end
function disMC:gts(param_) self:gotoAndStop(param_) end
function disMC:nf() self:nextFrame() end
function disMC:pf() self:prevFrame() end

--init--------------------------------------------------------
function disMC:init(initDict_)
	disMC.super.init(self,initDict_)
end

--获取动作
function disMC:getFrameActionByFrameInt(frameInt_)
	return self.frameActions[frameInt_]
end

--获取名称
function disMC:getFrameNameByFrameInt(frameInt_)
	return self.frameNames[frameInt_]
end

--更换
function disMC:replaceDisplayObject(disTarget_,disReplace_)
    if disTarget_ then
    	--ui层不能替换，只能替换简单的显示对象
    	assert(disTarget_.lifeState==nil,"ERROR cann't replace ui.")
        local _tempChildObject=self:getMcChildObjectByDisplay(disTarget_)
        _tempChildObject.displayObject=nil
        disTarget_:removeFromParent(true)
        _tempChildObject=disReplace_
    end
end

--通过显示对象获取承载 它 的mcChildObject
function disMC:getMcChildObjectByDisplay(dis_)
	for i=1,#self.mcChildObjectArr do
		local _mcChildObject=self.mcChildObjectArr[i]
		if _mcChildObject.displayObject==dis_ then
			return _mcChildObject
		end
	end
end

--Update Frame
function disMC:updateF(type_)
	--911--Update layer's currentFrame.
    --912--Run action's in currentFrame.
    --913--Enter currentFrame.
	if type_==911 then
		self:updateCurrentFrame()
	elseif type_==912 then
		self:runActions()
	elseif type_==913 then
		self:enterFrame()
	elseif type_==914 then
		self:resetFrameState()
	end
	disMC.super.updateF(self,type_)
end

function disMC:updateCurrentFrame()
	--其他帧动作控制过这个对象的话，当前帧就无法自己控制了
    if self.currentFrameChangeByOtherBoo==false then
        if self.autoPlay then --确定帧号
            if self.currentFrame<self.totalFrames then
                self.currentFrame=self.currentFrame+1
            else
                self.currentFrame=1
            end
        end
    end
end
function disMC:runActions()
	if self.currentFrame==self.lastFrame then
		return
	end
	self.frameActionRunning=true
	self:runActionByFrame(self.currentFrame)
end

function disMC:enterFrame()
	if self.currentFrame==self.lastFrame then
		return
	end
	self:updateDisplayList()
	self.lastFrame=self.currentFrame
end

function disMC:resetFrameState()
	self.frameActionRunning=false
	self.currentFrameChangeByOtherBoo=false
end

function disMC:updateDisplayList()
	for i=1,#self.mcChildObjectArr do
		local _mcChildObj=self.mcChildObjectArr[i]
		local _tempObject=_mcChildObj.displayObject
		if _tempObject.lifeState then--这个就是ui层
			if _mcChildObj.beginFrame<=self.currentFrame and _mcChildObj.endFrame>=self.currentFrame then
				if _tempObject.lifeState=="none" or _tempObject.lifeState=="destory" then
					if _tempObject.inited==false then
						_tempObject:init({})
					else
						_tempObject:onCreate()
					end
					_tempObject:updateF(911)--_tempObject:updateCurrentFrame() + 子对象:updateCurrentFrame()
					_tempObject:updateF(912)--_tempObject:runActions() + 子对象:runActions()
					_tempObject:updateF(913)--_tempObject:enterFrame() + 子对象:enterFrame()
					_tempObject:updateF(914)--_tempObject:resetFrameState() + 子对象:resetFrameState()
				end
				_mcChildObj:propertyInFrame(self.currentFrame)
			else
				if _tempObject.lifeState=="create" then
					_tempObject:onDestory()				end
			end
		else--普通显示对象
			if _mcChildObj.beginFrame<=self.currentFrame and _mcChildObj.endFrame>=self.currentFrame then
				_mcChildObj:propertyInFrame(self.currentFrame)
			else--普通的就看不见就完了
				_tempObject:setVisible(false)
			end
		end
	end
end

--运行当前帧的方法
function disMC:runActionByFrame(frame_)
	local _actions=self:getFrameActionByFrameInt(frame_)
	if _actions then--TODO 开始执行 action
		_actions()
	end
end
--<><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><>MovieClip
function disMC:gotoAndStop(param_)
	--被帧控制了
    self.currentFrameChangeByOtherBoo=true
    local _targetFrameInt--前往的帧数
    local _number=tonumber(param_)
    
    if _number then--数字
        _targetFrameInt=_number
    else
        _targetFrameInt=self:getFrameIntByFrameName(param_)
    end
    --不在自动播放
    self.autoPlay=false
    --去哪个帧
    self:gotoFrame(_targetFrameInt)
end

function disMC:gotoAndPlay(param_)
	--被帧控制了
    self.currentFrameChangeByOtherBoo=true
    local _targetFrameInt
    local _number=tonumber(param_)
    if _number then--数字
        _targetFrameInt=_number
    else
        _targetFrameInt=self:getFrameIntByFrameName(param_)
    end
    --自动播放
    self.autoPlay=true
    --去哪个帧
    self:gotoFrame(_targetFrameInt)
end

function disMC:gotoFrame(frameInt_)
    --超越界限就走到最后一帧
    if frameInt_>self.totalFrames then
        frameInt_=self.totalFrames
    --零 或 负数 是不存在的,默认走到第一帧
    elseif frameInt_<1 then
        frameInt_=1
    end
    --帧数不同才能进入该帧
    if self.currentFrame~=frameInt_ then
    	self.currentFrame=frameInt_
	    --循环中。且这个对象已经执行过了。证明当前执行方法的
	    if self.frameActionRunning then
	    	--enterFrame 执行 这个值就变成true了。
	    	--runActions 执行时，这个对象已经执行完了它自己的方法，变动帧，这个帧的方法会立刻执行。
	    	self:runActionByFrame(_targetFrameInt)
	   	else
	   		--updateCurrentFrame 执行的时候。但是不会有action执行
	   		--runActions 执行的时候，还没循环到自己的时候，其他的action执行，只会影响其帧数，不会执行方法
	   		--enterFrame 执行中，不会触发任何action
	   		--enterFrame 执行过后，也就是。循环之外可以有action执行。但是也是改变帧，等到下个循环的runActions自然执行方法
	   	end
	end
end

--前一帧
function disMC:nextFrame()
    self.currentFrameChangeByOtherBoo =true
    if self.currentFrame<self.totalFrames then
        self:gotoAndStop(self.currentFrame+1)
    end
end
--下一帧
function disMC:prevFrame()
    self.currentFrameChangeByOtherBoo =true;
    if self.currentFrame > 1 then --不是第一帧就可以向前
        self:gotoAndStop(self.currentFrame-1)
    end
end
--播放
function disMC:play()
 	self.autoPlay=true
end
--停止
function disMC:stop()
    self.autoPlay=false
end

--帧名变帧数
function disMC:getFrameIntByFrameName(name_)
	return self.frameNames[name_]
end

--create-- call when init
function disMC:onCreate()
	disMC.super.onCreate(self)--onCreate中有initPlace摆放位置
	print("disMC : onCreate")
	self:resetPars()
end
--destory-- call when removeChild
function disMC:onDestory()
	print("disMC : onDestory")
	self:resetPars()
	disMC.super.onDestory(self)
end

function disMC:resetPars()
	self:resetFrameState()
	self.currentFrame=0
	self.lastFrame=0
	self.autoPlay=true
end

function disMC:onDelete()
	while #self.mcChildObjectArr>0 do
		table.remove(self.mcChildObjectArr):onDelete()
	end
	self.mcChildObjectArr=nil
	self.testUtils=nil
	self.frameNames=nil
	self.mcControl=nil
	disMC.super.onDelete(self)
end


return disMC