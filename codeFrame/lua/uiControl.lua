[<File_doc|ui|/src/app/base/control/uiControl.lua|replace>]
local uiControlInstance = class("uiControlInstance")
--ui's control
function uiControlInstance:ctor(params_)
    local _displayUtils=displayUtils:getInstance()
    self.waitCount = 0
    self.stageContainer=cc.Layer:create()
    self.mainContainer = cc.Layer:create()
    self.stageContainer:addChild(self.mainContainer,1)
    self.scaleBuffer = 0
    self.realWidth = 0
    self.realHeight = 0
    self.bufferX =0
    self.bufferY =0
    self.designWidth  = UC_DESIGN_WIDTH
    self.designHeight = UC_DESIGN_HEIGHT
    local winSize     = cc.Director:getInstance():getWinSize()
    self.screenWidth  = winSize.width
    self.screenHeight = winSize.height
    if (self.screenHeight/self.screenWidth) < (self.designHeight/self.designWidth) then
        self.scaleBuffer = self.screenHeight/self.designHeight
        if UC_H_EXTEHD==false then--mask left and right
            self.bufferX=(self.screenWidth-self.designWidth*self.screenHeight/self.designHeight)*0.5
            local _maskRight= _displayUtils:getPicScaleToSize("greenPic.png",self.bufferX,self.screenHeight)
            _displayUtils:placeAndAddChildToContainer(_maskRight,self.stageContainer,0,0,0,0,nil,nil,nil,nil,2)
            local _maskLeft = _displayUtils:getPicScaleToSize("greenPic.png",self.bufferX,self.screenHeight)
            _displayUtils:placeAndAddChildToContainer(_maskLeft,self.stageContainer,0,0,self.screenWidth-self.bufferX,0,nil,nil,nil,nil,2)
            self.realWidth=self.designWidth
        else
            self.realWidth= self.screenWidth/self.scaleBuffer
        end
        self.realHeight=self.designHeight
    else
        self.scaleBuffer = self.screenWidth/self.designWidth 
        if UC_V_EXTEHD==false then--mask up and down
            self.bufferY=(self.screenHeight-self.designHeight*self.screenWidth/self.designWidth)*0.5
            local _maskUp= _displayUtils:getPicScaleToSize("greenPic.png",self.screenWidth,self.bufferY)
            _displayUtils:placeAndAddChildToContainer(_maskUp,self.stageContainer,0,0,0,0,nil,nil,nil,nil,2)
            local _maskDown = _displayUtils:getPicScaleToSize("greenPic.png",self.screenWidth,self.bufferY)
            _displayUtils:placeAndAddChildToContainer(_maskDown,self.stageContainer,0,0,0,self.screenHeight-self.bufferY,nil,nil,nil,nil,2)
            self.realHeight=self.designHeight
        else
            self.realHeight=self.screenHeight/self.scaleBuffer
        end
        self.realWidth=self.designWidth
    end
    --9 points for align
    self.p11 = cc.p(0,self.realHeight)
    self.p12 = cc.p(self.realWidth*0.5,self.realHeight)
    self.p13 = cc.p(self.realWidth,self.realHeight)
    self.p21 = cc.p(0,self.realHeight*0.5)
    self.p22 = cc.p(self.realWidth*0.5,self.realHeight*0.5)
    self.p23 = cc.p(self.realWidth,self.realHeight*0.5)
    self.p31 = cc.p(0,0)
    self.p32 = cc.p(self.realWidth*0.5,0)
    self.p33 = cc.p(self.realWidth,0)
    self.alignModePoints= {}
    self.alignModePoints["LT"] = self.p11--left top
    self.alignModePoints["T"]  = self.p12--center top
    self.alignModePoints["RT"] = self.p13--right top
    self.alignModePoints["LC"] = self.p21--left center
    self.alignModePoints["C"]  = self.p22--center
    self.alignModePoints["RC"] = self.p23--right center
    self.alignModePoints["LB"] = self.p31--left bottom
    self.alignModePoints["B"]  = self.p32--bottom
    self.alignModePoints["RB"] = self.p33--right bottom
    self.mainContainer:setScale(self.scaleBuffer)--Adaption for Mobile screen
    self.mainContainer:setAnchorPoint(cc.p(0,0))
    self.mainContainer:setPosition(cc.p(self.bufferX,self.bufferY))-- Move to the right place.
    --Array for container's sub layer
    self.lLoadingArr={}--loading : game loading... resource loading
    self.lTipArr={}--    tip     : guide or tip
    self.lMaskArr={}--   mask    : mask all ui when guide.
    self.lPopArr={}--    pop     : pop layers
    self.lUiArr={}--     ui      : float ui between pop and base
    self.lBaseArr={}--   base    : base ui
    self.lBgArr={}--     bg      : background
    --Dictionary for array
    self.arraySet={}
    self.arraySet["Loading"]=self.lLoadingArr
    self.arraySet["Tip"]=self.lTipArr
    self.arraySet["Mask"]=self.lMaskArr
    self.arraySet["Pop"]=self.lPopArr
    self.arraySet["Ui"]=self.lUiArr
    self.arraySet["Base"]=self.lBaseArr
    self.arraySet["Bg"]=self.lBgArr
    --Containers for different purposes
    self.lLoading=cc.Layer:create()
    self.lTip =cc.Layer:create()
    self.lMask=cc.Layer:create()
    self.lPop =cc.Layer:create()
    self.lUi =cc.Layer:create()
    self.lBase =cc.Layer:create()
    self.lBg =cc.Layer:create()
    --Dictionary for container
    self.containerSet={}
    self.containerSet["Loading"]=self.lLoading
    self.containerSet["Tip"]=self.lTip
    self.containerSet["Mask"]=self.lMask
    self.containerSet["Pop"]=self.lPop
    self.containerSet["Ui"]=self.lUi
    self.containerSet["Base"]=self.lBase
    self.containerSet["Bg"]=self.lBg
    --Add to main container
    _displayUtils:placeAndAddChildToContainer(self.lLoading,self.mainContainer,0,0,0,0,nil,nil,nil,nil,7)
    _displayUtils:placeAndAddChildToContainer(self.lTip,self.mainContainer,0,0,0,0,nil,nil,nil,nil,6)
    _displayUtils:placeAndAddChildToContainer(self.lMask,self.mainContainer,0,0,0,0,nil,nil,nil,nil,5)
    _displayUtils:placeAndAddChildToContainer(self.lPop,self.mainContainer,0,0,0,0,nil,nil,nil,nil,4)
    _displayUtils:placeAndAddChildToContainer(self.lUi,self.mainContainer,0,0,0,0,nil,nil,nil,nil,3)
    _displayUtils:placeAndAddChildToContainer(self.lBase,self.mainContainer,0,0,0,0,nil,nil,nil,nil,2)
    _displayUtils:placeAndAddChildToContainer(self.lBg,self.mainContainer,0,0,0,0,nil,nil,nil,nil,1)
    --Debug ui and tools when in debug mode

    self.lDebugArr={}
    self.lDebug =cc.Layer:create()
    self.arraySet["Debug"]=self.lDebugArr
    self.containerSet["Debug"]=self.lDebug
    _displayUtils:placeAndAddChildToContainer(self.lDebug,self.mainContainer,0,0,0,0,nil,nil,nil,nil,8)

    --UiRefer use
    self.uiRefers={}
    self.uiRefers.uiCount=0
end

----------------------------------------------------------------------------------------------------------------------------------------------------------------
--Jump to a ui,clear "Pop" and "Base" container's all layers
function uiControlInstance:jumpTo(moduleName_,className_)
    self:containerClear("Base",false,true)
    self:containerClear("Pop",false,true)
    return self:baseOverlay(moduleName_,className_)
end
function uiControlInstance:baseOverlay(moduleName_,className_)
    return self:uiOverlay("Base",moduleName_,className_)
end
function uiControlInstance:popOverlay(moduleName_,className_)
    return self:uiOverlay("Pop",moduleName_,className_)
end
function uiControlInstance:baseReplace(moduleName_,className_)
    return self:replaceTopUi("Base",moduleName_,className_)
end
function uiControlInstance:popReplace(moduleName_,className_)
    return self:replaceTopUi("Pop",moduleName_,className_)
end
function uiControlInstance:basePull(moduleName_,className_)
    return self:uiPull("Base")
end
function uiControlInstance:popPull(moduleName_,className_)
    return self:uiPull("Pop")
end
function uiControlInstance:close(type_)
    return self:uiPull(type_)
end
--Close top layer which is highest is all containers.
function uiControlInstance:closeTop()--关闭掉最上面的一个层
    if #self:getLayerArrByType("Loading")>0 then self:uiPull("Loading")
    elseif #self:getLayerArrByType("Tip")>0 then self:uiPull("Tip")
    elseif #self:getLayerArrByType("Mask")>0 then self:uiPull("Mask")
    elseif #self:getLayerArrByType("Pop")>0 then self:uiPull("Pop")
    elseif #self:getLayerArrByType("Base")>0 then self:uiPull("Base")
    end
    self:uiStructure()--显示UI结构
end
--Change top ui in a container.
function uiControlInstance:replaceTopUi(type_,moduleName_,className_)
    self:uiPull(type_)
    return self:uiOverlay(type_,moduleName_,className_)
end

--Pull a ui from a container.
function uiControlInstance:uiPull(type_)
    self:containerClear(type_,true,false)
    self:uiStructureChange()
end
--Push a ui to a container.
function uiControlInstance:uiOverlay(type_,moduleName_,className_)
    local _tempUI=self:getUIByClassName(moduleName_,className_).new()
    _tempUI.uiType=type_
    _tempUI.name=moduleName_.."_"..className_
    table.insert(self.arraySet[type_],_tempUI)
    self:getContainerByType(type_):addChild(_tempUI,#self.arraySet,#self.arraySet)
    self:uiStructure()--Show ui structure
    self:uiStructureChange()
    return _tempUI
end
--Clear layer's container or clear one layer
function uiControlInstance:containerClear(type_,onlyOne_,rightNow_)
    local _tempLayerArr=self:getLayerArrByType(type_)
    local _layerContainer=self:getContainerByType(type_)
    while #_tempLayerArr>0 do
        local _tempUI=table.remove(_tempLayerArr)
        if rightNow_ or  _tempUI:animationOut()==false then
            self:removeUI(_tempUI)
        end
        if rightNow_ then
            self:removeUI(_tempUI)
        else
            
        end

        if onlyOne_ then--Clear only one...
            break;
        end
    end
end

function uiControlInstance:removeUI(tempUI_)
    tempUI_:onDelete()
    tempUI_:removeFromParent(true)
end

--Get ui's control instance by "moduleName_" and "className_"
function uiControlInstance:getUIByClassName(moduleName_,className_)
    --local _fullName=moduleName_..className_
    --if cc.Registry.exists(_fullName) then return cc.Registry.getClass(_fullName) end
    local _cls = require("src.app.ui.controls."..moduleName_..".c_"..className_)
    --cc.Registry.add(_cls,_fullName)
    return _cls
end
----------------------------------------------------------------------------------------------------------------------------------------------------------------
--get layer touchable
function uiControlInstance:isUiTouchAble(uiLayer_)
    local _uiContainerIndex=self:getTouchMainIndexByType(uiLayer_.uiType)
    local _currentTopIndex=self:currentTopLayerIndex()
    if _uiContainerIndex==2 and _currentTopIndex==3 then
        _uiContainerIndex=3
    end
    local _touchAble = false
    if _uiContainerIndex ==_currentTopIndex then
        _touchAble=true
    else
        if _uiContainerIndex==8 then--Debug always touchable
            _touchAble=true
        else
            assert(false,"ERROR ui structure error.please check uiPush/uiPull's logic.")
        end
    end
    if _touchAble then
        local _uiContainerArray=self:getLayerArrByType(uiLayer_.uiType)
        if _uiContainerArray[#_uiContainerArray] == uiLayer_ then
            return true
        end
    end
    return false
end
--Get current top layer's Container index
function uiControlInstance:currentTopLayerIndex()
    local _touchIndex=0
    --Ignore lDebug.because it aways touchable
    if #self.lLoadingArr>0 then
        _touchIndex=7
    elseif #self.lTipArr>0 then
        _touchIndex=6
    elseif #self.lMaskArr>0 then
        _touchIndex=5
    elseif #self.lPopArr>0 then
        _touchIndex=4
    elseif #self.lUiArr>0 then
        _touchIndex=3
    elseif #self.lBaseArr>0 then
        _touchIndex=2
    elseif #self.lBgArr>0 then
        _touchIndex=1
    end
    return _touchIndex
end
--Get touch index (Container's index + Ui's index)
function uiControlInstance:getTouchMainIndexByType(type_)
    if type_=="Bg" then
        return 1
    elseif type_=="Base" then
        return 2
    elseif type_=="Ui" then
        return 3
    elseif type_=="Pop" then
        return 4
    elseif type_=="Mask" then
        return 5
    elseif type_=="Tip" then
        return 6
    elseif type_=="Loading" then
        return 7
    elseif type_=="Debug" then
        return 8
    end
end
--------------------------------------------------------------------------------
--Check btn's name like this.
--btn_xx_a_b_c
function uiControlInstance:specialBtnAnalyse(btnName_)
    local _error=false
    local _backNameInfo=nil
    local _stateArr = stringUtils:getInstance():split(btnName_,'_')
    if _stateArr[1] =="btn" then
        if _stateArr[2] =="state" then
            if #_stateArr~=3 and #_stateArr~=4 then
                _error=true
            end
            _backNameInfo={}
            _backNameInfo.type=_stateArr[2]
            _backNameInfo.toState=_stateArr[3]
            if _stateArr[4] then
                _backNameInfo.backState=_stateArr[4]
            end
        elseif _stateArr[2] =="jumpTo" or _stateArr[2] =="popOverlay" or _stateArr[2] =="baseOverlay" then
            if #_stateArr~=4 then
                _error=true
            end
            _backNameInfo={}
            _backNameInfo.type=_stateArr[2]
            _backNameInfo.toModule=_stateArr[3]
            _backNameInfo.toClass=_stateArr[4]
        elseif _stateArr[2] =="overlay" then
            if #_stateArr~=5 then
                _error=true
            end
            _backNameInfo={}
            _backNameInfo.type=_stateArr[2]
            _backNameInfo.toContainer=_stateArr[3]
            _backNameInfo.toModule=_stateArr[4]
            _backNameInfo.toClass=_stateArr[5]
        end
        if _error then
            assert(false,"ERROR : Wrong btn name for state change.\n name : "..btnName_)
        end
    end
    return _backNameInfo
end
function uiControlInstance:doUIOperationByInfo(nameInfo_,isStateBack_)
    if nameInfo_==nil then return end
    --btn for stateChange
    if nameInfo_.type=="state" then
        local _toState
        if isStateBack_ then
            _toState=nameInfo_.backState
        else
            _toState=nameInfo_.toState
        end
        self:uiStateChange(_toState)
    end
    --btn for uiChange
    if nameInfo_.type=="jumpTo" or nameInfo_.type=="popOverlay" or nameInfo_.type=="baseOverlay" then
        if nameInfo_.type=="jumpTo" then
            self:jumpTo(nameInfo_.toModule,nameInfo_.toClass)
        elseif nameInfo_.type=="baseOverlay" then
            self:baseOverlay(nameInfo_.toModule,nameInfo_.toClass)
        elseif nameInfo_.type=="popOverlay" then
            self:popOverlay(nameInfo_.toModule,nameInfo_.toClass)
        end
    elseif nameInfo_.type=="overlay" then
        self:uiOverlay(nameInfo_.toContainer,nameInfo_.toModule,nameInfo_.toClass)
    end
end
--------------------------------------------------------------------------------
function uiControlInstance:getContainerByType(type_)
    return self.containerSet[type_]
end
function uiControlInstance:getLayerArrByType(type_)
    return self.arraySet[type_]
end
----------------------------------------------------------------------------------------------------------------------------------------------------------------
--User's operation watting
function uiControlInstance:waitAdd()
    self.waitCount=self.waitCount+1
end
function uiControlInstance:waitSub()
    self.waitCount=self.waitCount-1
end
function uiControlInstance:isWaitZero()
    if self.waitCount==0 then
        return true
    else
        return false
    end
end

function uiControlInstance:uiStructureChange()
    self:uiArrStructureChange("Bg")
    self:uiArrStructureChange("Base")
    self:uiArrStructureChange("Ui")
    self:uiArrStructureChange("Pop")
    self:uiArrStructureChange("Mask")
    self:uiArrStructureChange("Tip")
    self:uiArrStructureChange("Loading")
    self:uiArrStructureChange("Debug")
end
function uiControlInstance:uiArrStructureChange(type_)
    local layerArr=self.arraySet[type_]
    if layerArr~=nil and #layerArr>0 then
        for i=#layerArr,1,-1 do 
            layerArr[i]:uiStructureChange()
        end
    end
end
--Ui' state change.Ui which has this state will change to it.
function uiControlInstance:uiStateChange(stateName_)
    self:uiArrStateChange("Bg",stateName_)
    self:uiArrStateChange("Base",stateName_)
    self:uiArrStateChange("Ui",stateName_)
    self:uiArrStateChange("Pop",stateName_)
    self:uiArrStateChange("Mask",stateName_)
    self:uiArrStateChange("Tip",stateName_)
    self:uiArrStateChange("Loading",stateName_)
    self:uiArrStateChange("Debug",stateName_)
end
function uiControlInstance:uiArrStateChange(type_,stateName_)
    local layerArr=self.arraySet[type_]
    if layerArr~=nil and #layerArr>0 then
        for i=#layerArr,1,-1 do 
            layerArr[i]:stateChange(stateName_)
        end
    end
end

----------------------------------------------------------------------------------------------------------------------------------------------------------------
if UC_DEBUG then
    function uiControlInstance:addUiRefer(moduleName_,className_)--add refer 
        local _key=moduleName_.."_"..className_
        if self.uiRefers[_key]==nil then
            self.uiRefers[_key]=0
        end
        self.uiRefers[_key]=self.uiRefers[_key]+1
        self.uiRefers.uiCount=self.uiRefers.uiCount+1
    end
    function uiControlInstance:subUiRefer(moduleName_,className_)--sub refer 
        local _key=moduleName_.."_"..className_
        assert(self.uiRefers[_key]~=nil , "uiControl:subUiRefer() - invalid key : ".._key)
        self.uiRefers[_key]=self.uiRefers[_key]-1
        self.uiRefers.uiCount=self.uiRefers.uiCount-1
        assert(self.uiRefers[_key]>=0, "uiControl:subUiRefer() - className : ".._key.. " refer == -1")
        assert(self.uiRefers.uiCount>=0, "uiControl:subUiRefer() - uiCount == -1")
    end
    function uiControlInstance:showUiRefers()--show refers
        for _keyName,_count in pairs(self.uiRefers) do
            if self.uiRefers[_keyName]~=0 and _keyName ~= "uiCount" then
                print(_keyName .." : ".._count)
            end
        end
        print("uiCount : "..self.uiRefers["uiCount"])
    end
    function uiControlInstance:uiStructure()
        print("-------------- UI STRUCTURE ----------------")
        self:showContainerStructure("Debug")
        self:showContainerStructure("Loading")
        self:showContainerStructure("Tip")
        self:showContainerStructure("Mask")
        self:showContainerStructure("Pop")
        self:showContainerStructure("Ui")
        self:showContainerStructure("Base")
        self:showContainerStructure("Bg")
    end
else
    function uiControlInstance:addUiRefer(moduleName_,className_) end
    function uiControlInstance:subUiRefer(moduleName_,className_) end
    function uiControlInstance:showUiRefers() end
    function uiControlInstance:uiStructure() end
end
--Show ui's structure
function uiControlInstance:showContainerStructure(type_)
    local layerArr=self.arraySet[type_]
    if layerArr~=nil and #layerArr>0 then
        print(type_.." ---------------------------")
        for i=#layerArr,1,-1 do print(i.." : "..layerArr[i].moduleName.." : "..layerArr[i].className) end
    end
end
----------------------------------------------------------------------------------------------------------------------------------------------------------------
cc.exports.uiControl = {}
function uiControl:getInstance()
    if self.instance == nil then
        self.instance = uiControlInstance:new()
    end
    return self.instance
end