[<File_doc|ui|/src/app/base/ui/disList.lua|replace>]
local disUI=require("src.app.base.ui.disUI")
local disList = class("disList",disUI)

function disList:ctor(params_)
	disList.super.ctor(self,params_)
	self.className="disList"
	self.displayType="ui"
	self.layerType="list"
	self.name="none"

	--自己使用的Item 的 itemModuleName/itemClassName
	self.itemModuleName=nil
	self.itemClassName=nil
	--标题
	self.titleModuleName=nil
	self.titleClassName=nil
	
	self.itemNumPerLine=0--一行放几个
	self.itemBeginPo=nil--起始的位置
	self.itemSize=nil--item的大小
    self.itemScaleX=nil
    self.itemScaleY=nil
	
	self.maxHeight=0--滚动层的滚动部分大小，动态变化，根据列表长度
    self.maxWidth=0
	self.baseHeight=0--基础的滚动部分大小，这部分在UI编辑器中编辑的
    self.baseWidth=0

	self.itemArray = nil
end

--列表的情况下获取列表的相关信息
function disList:setItemInfo(titleModuleName_,titleClassName_,itemModuleName_,itemClassName_,itemNumPerLine_,beignPoX_,beignPoY_,itemWidth_,itemHeight_,rollType_,scaleX_,scaleY_)
	self.titleModuleName=titleModuleName_
	self.titleClassName=titleClassName_
	self.itemModuleName=itemModuleName_
	self.itemClassName=itemClassName_
	self.itemNumPerLine=itemNumPerLine_
	self.itemBeginPo=cc.p(beignPoX_,beignPoY_)
	self.itemSize=cc.size(itemWidth_,itemHeight_)
	self.rollType=rollType_
    self.itemScaleX=scaleX_
    self.itemScaleY=scaleY_
end

function disRoll:setBaseSize(baseWidth_,baseHeight_)
    self.baseHeight=baseHeight_
    self.baseWidth=baseWidth_
    self.maxHeight=self.baseHeight
    self.maxWidth=self.baseWidth
end


function disList:resetItemAndDisplayPlace(type_)
    if self.displayArray_replace==nil then--获取一下根随列表变动坐标的东西
        self.displayArray_replace={}
        for i=1,#self.displayArray do
            local _tempDis=self.displayArray[i]
            local _tempDisFirstInPos=self.firstInPosDict[_tempDis.name]
            if self.rollType=="v" and _tempDisFirstInPos.y < self.itemBeginPo.y-self.itemSize.height+self.itemRectY*self.itemScaleY then
                table.insert(self.displayArray_replace,self.displayArray[i])
            elseif self.rollType=="h" and _tempDisFirstInPos.x > self.itemBeginPo.x+self.itemSize.height-self.itemRectY*self.itemScaleY then
                table.insert(self.displayArray_replace,self.displayArray[i])
            end
        end
    end

    local _deleteMoveTime=0.2
    local _deleteActionEaseType=31

    local _needMove=false
    if type_ == "delete" or type_ == "add" or type_ == "update" then _needMove =true end

    local _itemCountInLine=0--当前行第几个
    local _currentLineMax=0--当前行，最高的
    local _currentLinePo=0--当前行，位置
    local _currentItemPo

    _currentItemPo=cc.p(self.itemBeginPo.x,self.itemBeginPo.y)
    if self.rollType =="h" then
        _currentLinePo=_currentItemPo.x
    elseif self.rollType =="v" or self.rollType =="x" then
        _currentLinePo=_currentItemPo.y
    end

    for i=1,#self.itemArray do--设置item位置
        local _tempItem=self.itemArray[i]
        local _targetPoint--计算位置
        if self.rollType =="v" or self.rollType =="x" then
            _targetPoint = cc.p(_currentItemPo.x,_currentLinePo)
            if _currentLineMax < _tempItem.contentHeight then
                _currentLineMax=_tempItem.contentHeight
            end
            _itemCountInLine=_itemCountInLine+1
            if _itemCountInLine == self.itemNumPerLine then--换行
                _itemCountInLine=0
                _currentLinePo=_currentLinePo-_currentLineMax
                _currentLineMax=0
                _currentItemPo.x=self.itemBeginPo.x
            else
                _currentItemPo.x=_currentItemPo.x+_tempItem.contentWidth*self.itemScaleX
            end
        elseif self.rollType =="h"  then
            _targetPoint = cc.p(_currentLinePo,_currentItemPo.y)
            if _currentLineMax < _tempItem.contentWidth then
                _currentLineMax=_tempItem.contentWidth
            end
            _itemCountInLine=_itemCountInLine+1
            if _itemCountInLine == self.itemNumPerLine then--换行
                _itemCountInLine=0
                _currentLinePo=_currentLinePo+_currentLineMax
                _currentLineMax=0
                _currentItemPo.y=self.itemBeginPo.y
            else
                _currentItemPo.y=_currentItemPo.y-_tempItem.contentHeight*self.itemScaleY
            end
        end
        if _needMove then
            _tempItem:stopActionByTag(995)
            local _moveAction=cc.MoveTo:create(_deleteMoveTime,_targetPoint)
            _moveAction=self.actionUtils:easeActionByType(_moveAction,_deleteActionEaseType)
            _moveAction:setTag(995)
            _tempItem:runAction(_moveAction)
        else
            _tempItem:setPosition(_targetPoint)
        end
    end

    local _lastItem=self.itemArray[#self.itemArray]
    --重新计算item之外的元素的位置
    for i=1,#self.displayArray_replace do
        local _tempDis=self.displayArray_replace[i]
        local _tempDisFirstInPos=self.firstInPosDict[_tempDis.name]
        local _targetX=_tempDis:getPositionX()
        local _targetY=_tempDis:getPositionY()
        if self.rollType=="v" and #self.itemArray == 0 then
            if #self.itemArray == 0 then
                _targetY=_tempDisFirstInPos.y+self.itemSize.height
            else
                _targetY=_tempDisFirstInPos.y+self.itemSize.height+_lastItem:getPositionY()-_lastItem.contentHeight
            end
        end
        if self.rollType=="h" and #self.itemArray == 0 then
            if #self.itemArray == 0 then
                _targetX=_tempDisFirstInPos.x-self.itemSize.width
            else
                _targetX=_tempDisFirstInPos.x-self.itemSize.width+_lastItem:getPositionX()+_lastItem.contentWidth
            end
        end
        if _needMove then
            _tempDis:stopActionByTag(996)
            local _moveAction=cc.MoveTo:create(_deleteMoveTime,cc.p(_targetX,_targetY))
            _moveAction=self.actionUtils:easeActionByType(_moveAction,_deleteActionEaseType)
            _moveAction:setTag(996)
            _tempDis:runAction(_moveAction)
        else
            _tempDis:setPosition(cc.p(_targetX,_targetY))
        end
    end
    --重新结算列表内容宽高
    if self.rollType=="v" or self.rollType=="x" then
        if #self.itemArray==0 then
            self.maxHeight=self.baseHeight-self.itemSize.height
        else
            self.maxHeight=self.baseHeight-self.itemSize.height-_lastItem:getPositionY()+_lastItem.contentHeight
        end
    end
    if self.rollType=="h" then
        if #self.itemArray==0 then
            self.maxWidth=self.baseWidth-self.itemSize.width
        else
            self.maxHeight=self.baseHeight-self.itemSize.widht+_lastItem:getPositionX()+_lastItem.contentWidth
        end
    end
    
    if _needMove then
        self.uiControl:waitAdd()
        local function _callBackFun()
            self:deleteMoveEnd()
        end
        self.actionUtils:nodeDelayCall(self,_deleteMoveTime,_callBackFun)
        if (self:getPositionY()*-1)>self.maxHeight then
            self:stopActionByTag(997)
            local _moveAction = cc.MoveTo:create(_deleteMoveTime,cc.p(0,-1*self.maxHeight))
            _moveAction=self.actionUtils:easeActionByType(_moveAction,_deleteActionEaseType)
            _moveAction:setTag(997)
            self:runAction(_moveAction)
        end
    elseif type_== nil then --create
        --self.rollContainer:setPosition(cc.p(0,0))
    end
end

--移除 多个元素，其他元素位移。
--self:removeItemByIndexs({1,2,4,5})
function disList:removeItemByIndexs(indexArray_)
    for i=#self.itemArray,1,-1 do
        for j=#indexArray_,1,-1 do
            if self.itemArray[i].dataDict.itemIndex == indexArray_[j] then
            	self.itemArray[i]:onDelete()
                self.itemArray[i]:removeFromParent(true)
                table.remove(self.itemArray,i)
                table.remove(indexArray_,j)
                break
            end
        end
        if #indexArray_==0 then
            break
        end
    end
    self:resetItemIndexInfo()
    self:resetItemAndDisplayPlace("delete")
end
--重置 dataDict 中的 index 和 name
function disList:resetItemIndexInfo()
    for i=1,#self.itemArray do--重排数据index
        self.itemArray[i]:setItemIndex(i)
    end
end
--清空元素列表
function disList:clearItems()
    if self.itemArray then--ui refers
	    while #self.itemArray>0 do
	    	local _tempItem = self.itemArray[#self.itemArray]
	    	_tempItem:onDelete()
			_tempItem:removeFromParent(true)
			table.remove(self.itemArray)
            self.arrayUtils:removeElement(self.uiList,_tempItem)
	    end
 		self.itemArray=nil
	end
end

-- 创建一个对应于数据的item
function disList:createItemByData(data_, idx_)
    local _item=self.uiControl:getUIByClassName(self.itemModuleName,self.itemClassName).new()
    _item.layerType = "item"
    _item:init(data_)
    _item:setItemIndex(idx_)
    table.insert(self.uiList,_item)
    self.displayUtils:setLogicParent(_item,self)
    return _item
end

--按照一个列表创建数据
function disList:createList(dataList_)
    self:clearItems()
    self.itemArray = {}
    for i=1, #dataList_ do
        local _item = self:createItemByData(dataList_[i], i)
        table.insert(self.itemArray, _item)
        self.rollContainer:addChild(_item)
    end
end

--获取初始化摆放的位置
function disList:getChildrenFirstInPos()
    if self.firstInPosDict==nil then
        self.firstInPosDict={}--初始化位置
        for i=1,#self.displayArray do
            local _tempDis=self.displayArray[i]
            self.firstInPosDict[_tempDis.name]=cc.p(_tempDis:getPositionX(),_tempDis:getPositionY())
        end
    end
end

--create-- call when init
function disList:onCreate()
	disList.super.onCreate(self)--onCreate中有initPlace摆放位置
    self:getChildrenFirstInPos()
end
--destory-- call when removeChild
function disList:onDestory()
	disList.super.onDestory(self)
end
function disList:onDelete()
    if self.displayArray_replace then self.arrayUtils:clearArray(self.displayArray_replace) end
    self:clearItems()
	disList.super.onDelete(self)
end

return disList
