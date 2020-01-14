[<File_doc|ui|/src/app/base/control/mcControl.lua|replace>]
local mcControlInstance = class("mcControlInstance")
local mcChildObject=require("src.app.base.ui.mcChildObject")
--mc's control
function mcControlInstance:ctor(params_)
    self.uiControl=uiControl:getInstance()
    self.actionUtils=actionUtils:getInstance()
    self.displayUtils=displayUtils:getInstance()
    self.updateArr={}
    self.controlSelfs={}
    table.insert(self.updateArr,self.uiControl.lBgArr)
    table.insert(self.updateArr,self.uiControl.lBaseArr)
    table.insert(self.updateArr,self.uiControl.lUiArr)
    table.insert(self.updateArr,self.uiControl.lPopArr)
    table.insert(self.updateArr,self.uiControl.lMaskArr)
    table.insert(self.updateArr,self.uiControl.lTipArr)
    table.insert(self.updateArr,self.uiControl.lLoadingArr)
    table.insert(self.updateArr,self.uiControl.lDebugArr)
    self:updateF()
end

function mcControlInstance:addMcObjectToContainer(dis_,container_,ax_,ay_,beginFrame_,endFrame_,ps_,index_)
    local _mcChildObject=mcChildObject.new()
    self.displayUtils:setAnchor(dis_,ax_,ay_)
    _mcChildObject:init(dis_,beginFrame_,endFrame_,ps_)
    table.insert(container_.mcChildObjectArr,_mcChildObject)
    container_:addChild(dis_,index_,index_)
    dis_:setVisible(false)
end
--update frame 
function mcControlInstance:updateF()
    local function _update() self:updateF() end
    self.actionUtils:nodeDelayCall(self.uiControl.mainContainer,0.02,_update)
    self:updateLayerArr(911)--Update layer's currentFrame.
    self:updateLayerArr(912)--Run action's in currentFrame.
    self:updateLayerArr(913)--Enter currentFrame.
    self:updateLayerArr(914)--Reset frame's state.
end

function mcControlInstance:updateLayerArr(type_)
    for i=1,#self.updateArr do
        local _uiArr=self.updateArr[i]
        for j=1,#_uiArr do
            _uiArr[j]:updateF(type_)
        end
    end
    --disMC,自己控制自己的
    for i=1,#self.controlSelfs do
        local _controlSelf=self.controlSelfs[i]
        _controlSelf:updateF(type_)
    end
end
----------------------------------------------------------------------------------------------------------------------------------------------------------------
cc.exports.mcControl = {}
function mcControl:getInstance()
    if self.instance == nil then
        self.instance = mcControlInstance:new()
    end
    return self.instance
end