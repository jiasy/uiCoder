[<File_doc|ui|/src/app/base/ui/disRoll.lua|replace>]
local disUI=require("src.app.base.ui.disUI")
local disRoll = class("disRoll",disUI)

function disRoll:ctor(params_)
    disRoll.super.ctor(self,params_)
    self.className="disRoll"
    self.displayType="ui"
    self.layerType="roll"
    self.name="none"

    self.clippingNode=nil--遮罩NODE
    self.rollContainer=nil--实际显示对象的容器
    --自己使用的Item 的 itemModuleName/itemClassName
    self.itemModuleName=nil
    self.itemClassName=nil
    self.itemNumPerLine=0--一行放几个
    self.itemBeginPo=nil--起始的位置
    
    self.rollType=""--创建列表的横竖 H/V
    
    self.mouseRect=nil--点击区大小位置
    self.maxHeight=0--滚动层的滚动部分大小，动态变化，根据列表长度
    self.maxWidth=0
    self.baseHeight=0--基础的滚动部分大小，这部分在UI编辑器中编辑的
    self.baseWidth=0
    
    self.lockEdge="unLock"--边缘锁[拖拽过边缘时的反应]

    self.pressing=false--是否点击中
    
    self.moved=false--是否移动中
    
    self.lockRoll=false--滚动层上锁
    
    self.xMoveLong=0--移动了多少距离
    self.yMoveLong=0
    
    self.easeing=false--是否正在移动中
    
    self.xMousePosArr={}--位置数组
    self.yMousePosArr={}
    
    self.moveLongMax=10--动了多少算动
    
    self.currentTapingBtn=nil--当前点击的按钮

    self.firstInPosDict=nil--初始化位置

    self.itemArray = nil
    self.btnArr={}--承载的按钮

    --定时添加
    self.touchPosDelayTimeAction=nil
end
function disRoll:init(initDict_)
    disRoll.super.init(self,initDict_)
    --if self.initDict.dataList then--初始化数组中有dataList就用它初始化。
    --    self:createList(self.initDict.dataList)
    --end
end
--列表的情况下获取列表的相关信息
function disRoll:setItemInfo(itemModuleName_,itemClassName_,itemNumPerLine_,beignPoX_,beignPoY_)
    self.itemModuleName=itemModuleName_
    self.itemClassName=itemClassName_
    self.itemNumPerLine=itemNumPerLine_
    self.itemBeginPo=cc.p(beignPoX_,beignPoY_)
end
--滚动区设置
function disRoll:createClippingNodeByRect()
    assert(self.inited,"ERROR 没有初始化的roll，不能调用它的方法")
    if self.clippingNode==nil then
        --死规定 "RectGreen" 为显示区
        self.mouseRect=self.rects["RectGreen"]
        --死规定 "RectRed" 滚动层内的显示区，也就是一堆显示对象。
        -- * 注意 : 不包含任何item的。
        -- *       ui编辑器中，item的摆放就是为了标识在什么位置加入列表，列表以什么行列数排序。
        self:setBaseSize(self.rects["RectRed"].width,self.rects["RectRed"].height)
        local _stencilSprite=cc.Sprite:create("greenPic.png")--蒙版设置
        --确认锚点 左上角为基准点
        _stencilSprite:setAnchorPoint(cc.p(0,1))
        _stencilSprite:setPosition(cc.p(self.mouseRect.x,self.mouseRect.y))
        --设置大小
        local _stencilSpriteSize=_stencilSprite:getContentSize()
        _stencilSprite:setScaleX(self.mouseRect.width/_stencilSpriteSize.width)
        _stencilSprite:setScaleY(self.mouseRect.height/_stencilSpriteSize.height)
        --实际承载层 坐标0.0 加入当前层以后其实坐标一致
        self.rollContainer=cc.Layer:create()
        self.rollContainer:setPosition(cc.p(0,0))
        self.rollContainer:setAnchorPoint(cc.p(0,0))
        --蒙版载入
        self.clippingNode = cc.ClippingNode:create()
        self.clippingNode:setAnchorPoint(cc.p(0,0))
        self.clippingNode:setPosition(cc.p(0,0))
        self.clippingNode:setStencil(_stencilSprite)
        self.clippingNode:setInverted(false)
        self.clippingNode:setAlphaThreshold(0)
        self.clippingNode:addChild(self.rollContainer)--蒙版遮挡 self.rollContainer
        self:addChild(self.clippingNode,1,1)
        --把显示对象都转移到self.rollContainer中。滚动的时候实际滚动对象为self.rollContainer。
        for i=1,#self.displayList do
            local _tempDis=self.displayList[i]
            _tempDis:retain()
            _tempDis:removeFromParent(false)
            self.rollContainer:addChild(_tempDis,_tempDis:getTag(),_tempDis:getTag())
            _tempDis:release()
        end
        self:addTouchEventListener()--注册点击事件
    end
end

function disRoll:setBaseSize(baseWidth_,baseHeight_)
    self.baseHeight=baseHeight_
    self.baseWidth=baseWidth_
    self.maxHeight=self.baseHeight
    self.maxWidth=self.baseWidth
end

--Listener of touch
function disRoll:addTouchEventListener()
    local function began(touch,event) return self:onTouchBegan(touch, event) end
    local function moved(touch,event) self:onTouchMoved(touch,event) end
    local function ended(touch,event) self:onTouchEnded(touch,event) end
    local function cancelled(touch,event) ended(touch,event) end
    self.touchListener = cc.EventListenerTouchOneByOne:create()--单击事件监听
    self.touchListener:setSwallowTouches(true)
    self.touchListener:registerScriptHandler(began,cc.Handler.EVENT_TOUCH_BEGAN )
    self.touchListener:registerScriptHandler(moved,cc.Handler.EVENT_TOUCH_MOVED )
    self.touchListener:registerScriptHandler(ended,cc.Handler.EVENT_TOUCH_ENDED )
    self.touchListener:registerScriptHandler(cancelled,cc.Handler.EVENT_TOUCH_CANCELLED )
    local eventDispatcher = self:getEventDispatcher()
    eventDispatcher:addEventListenerWithSceneGraphPriority(self.touchListener,self)
end

--点击是否在区域内
function disRoll:tapInRect(localPos_)
    if self.mathUtils:pointInRect(localPos_,self.mouseRect) then
        return true
    else
        return false
    end
end

--获取这个位置下得按钮
function disRoll:getTapBtn(touch_,event_)
    for i=#self.btnArr,1,-1 do
        local _tempBtn = self.btnArr[i]
        if _tempBtn:onTouchBegan(touch_,event_) then
            return _tempBtn
        end
    end
    return nil
end

--开始点击
function disRoll:onTouchBegan(touch_,event_)
    if self:isTouchAble()==false then return false end
    while #self.xMousePosArr>0 do
        table.remove(self.xMousePosArr)
    end
    while #self.yMousePosArr>0 do
        table.remove(self.yMousePosArr)
    end
    local _localPos=self:getPositionInSelf(touch_:getLocation())
    if self:tapInRect(_localPos) then
        self:stopEasing()
        self.pressing=true
        self.moved=false
        self.currentTapingBtn=self:getTapBtn(touch_,event_)
        return true
    else
        self.pressing=false
        return false
    end
end

--移动
function disRoll:onTouchMoved(touch_,event_)
    if self.lockRoll then return end
    if self.pressing and self.easeing==false then--按下且不在滑动状态中
        self.moved=true--移动状态

        local _nowPos=self:getPositionInSelf(touch_:getLocation())
        local _prevPos=self:getPositionInSelf(touch_:getPreviousLocation())

        local _xMove
        local _xMoveAbs
        if self.rollType=="h" or self.rollType=="x" then
            _xMove=(_nowPos.x-_prevPos.x)
            _xMoveAbs=math.abs(_xMove)
            self.xMoveLong=self.xMoveLong+_xMoveAbs
            table.insert(self.xMousePosArr,_xMove)
        end

        local _yMove
        local _yMoveAbs
        if self.rollType=="v" or self.rollType=="x" then
            _yMove=(_nowPos.y-_prevPos.y)
            _yMoveAbs=math.abs(_yMove)
            self.yMoveLong=self.yMoveLong+_yMoveAbs
            table.insert(self.yMousePosArr,_yMove)
        end

        --移动的同时，有按下的按钮
        if self.currentTapingBtn then
            --判断是否移动出按钮的选区
            if self.currentTapingBtn:onTouchMoved(touch_,event_) then
                self.currentTapingBtn=nil 
            end
            --如果没移动出按钮的选区
            if self.currentTapingBtn then
                --判断移动的距离[self.xMoveLong/self.yMoveLong]是否超过了一定范围【self.moveLongMax】
                if  (self.xMoveLong>self.moveLongMax and self.rollType =="h") or
                    (self.yMoveLong>self.moveLongMax and self.rollType =="v") or
                    (self.xMoveLong>self.moveLongMax or self.yMoveLong>self.moveLongMax and self.rollType =="x")
                then
                    --超过了视为手指移动太远，按钮就恢复原状
                    self.currentTapingBtn:moveOut()
                    self.currentTapingBtn=nil 
                end
            end
        end

        --X方向的超界运算 --边界值获取
        local _xEdge
        local _xPos
        if self.rollType=="h" or self.rollType=="x" then
            _xEdge=self.mouseRect.width-self.maxWidth
            _xPos=self.rollContainer:getPositionX()+_xMove
            if self.lockEdge=="unLock" then--边界不上锁，才有意义
                if _xPos<_xEdge then-- 左方向滑动 - 右超界
                    --TODO 加载元素 --立刻进行
                elseif _xPos>_xEdge then-- 右方向滑动 - 左超界
                    --TODO 刷新列表 --计时一小段时间 之后做
                end
            end
        end

        --Y方向的超界运算 --边界值获取
        local _yEdge
        local _yPos
        if self.rollType=="v" or self.rollType=="x" then
            _yEdge=self.maxHeight-self.mouseRect.height
            _yPos=self.rollContainer:getPositionY()+_yMove
            if self.lockEdge=="unLock" then--边界不上锁，才有意义
                if _yPos>_yEdge then-- 上方向滑动 - 下超界
                    --TODO 加载元素 --立刻进行
                elseif _yPos<_yEdge then-- 下方向滑动 - 上超界
                    --TODO 刷新列表 --计时一小段时间 之后做
                end
            end
        end

        --可以拖动超过边界的
        if self.lockEdge=="lock" then
            if self.rollType=="h" or self.rollType=="x" then
                if _xPos<_xEdge then
                    if self.maxWidth<self.mouseRect.width then
                        self.rollContainer:setPositionX(0)
                    else
                        self.rollContainer:setPositionX(_xEdge)
                    end
                elseif _xPos>0 then
                    self.rollContainer:setPositionX(0)
                else
                    self.rollContainer:setPositionX(_xPos)
                end
            end
            if self.rollType=="v" or self.rollType=="x" then
                if _yPos>_yEdge then
                    if self.maxHeight<self.mouseRect.height then
                        self.rollContainer:setPositionY(0)
                    else
                        self.rollContainer:setPositionY(_yEdge)
                    end
                elseif _yPos<0 then
                    self.rollContainer:setPositionY(0)
                else
                    self.rollContainer:setPositionY(_yPos)
                end
            end
        elseif self.lockEdge=="unLock" then
            if self.rollType=="h" or self.rollType=="x" then
                if _xPos<_xEdge or _xPos>0 then
                    _xMove=_xMove*0.5
                end
                self.rollContainer:setPositionX(self.rollContainer:getPositionX()+_xMove)
            end
            if self.rollType=="v" or self.rollType=="x" then
                if _yPos>_yEdge or _yPos<0 then
                    _yMove=_yMove*0.5
                end
                self.rollContainer:setPositionY(self.rollContainer:getPositionY()+_yMove)
            end
        else

        end
        --定时添加
        if self.touchPosDelayTimeAction then
            self:stopAction(self.touchPosDelayTimeAction)
            self.touchPosDelayTimeAction=nil
        end
        local function _callBackFun() self:timeListener() end
        self.touchPosDelayTimeAction=self.actionUtils:nodeDelayCall(self,0.05,_callBackFun)
    end
end

--时间监听
function disRoll:timeListener()
    for i=1,5 do 
        table.insert(self.xMousePosArr,0)
        table.insert(self.yMousePosArr,0)
    end
    self.touchPosDelayTimeAction=nil
end

--结束
function disRoll:onTouchEnded(touch_,event_)
    if self.pressing == false or self.easeing then return end
    if self.moved then
        self.moved=false
        local _xDis,_widthEdge,_xMovePlus,_xEaseXS,xEdgeBeyond=0,0,0,1,false
        if self.rollType == "h" or self.rollType=="x" then
            _widthEdge=self.maxWidth-self.mouseRect.width
            if _widthEdge >0 then
                for i=1,3 do
                    if self.xMousePosArr[#self.xMousePosArr-i+1] then
                        _xDis=_xDis+self.xMousePosArr[#self.xMousePosArr-i+1]
                    end
                end
                --算缓动的速度
                _xMovePlus,_xEaseXS=self:getMoveInfo(_xDis)
                local _xPos=self.rollContainer:getPositionX()+_xMovePlus
                --if self.rollType~="x" then
                    --计算缓动的距离
                    if _xPos < -_widthEdge then
                        _xMovePlus=-_widthEdge-self.rollContainer:getPositionX()
                    elseif _xPos >0 then
                        _xMovePlus=-self.rollContainer:getPositionX()
                    end
                --end
            else
                if self.rollType == "h" then
                    self:moveEnd()
                end
            end
        end
        local _yDis,_heightEdge,_yMovePlus,_yEaseXS,yEdgeBeyond=0,0,0,1,false
        if self.rollType == "v" or self.rollType=="x" then
            _heightEdge=self.maxHeight-self.mouseRect.height
            if _heightEdge >0 then
                for i=1,3 do
                    if self.yMousePosArr[#self.yMousePosArr-i+1] then
                        _yDis=_yDis+self.yMousePosArr[#self.yMousePosArr-i+1]
                    end
                end
                --算缓动的速度
                _yMovePlus,_yEaseXS=self:getMoveInfo(_yDis)
                local _yPos=self.rollContainer:getPositionY()+_yMovePlus
                --if self.rollType~="x" then
                    --计算缓动的距离
                    if _yPos > _heightEdge then
                        _yMovePlus=_heightEdge-self.rollContainer:getPositionY()
                    elseif _yPos <0 then
                        _yMovePlus=-self.rollContainer:getPositionY()
                    end
                --end
            else
                if self.rollType == "v" then
                    self:moveEnd()
                end
            end
        end

        if _xMovePlus~=0 or _yMovePlus ~=0 then
            self:startEasing(_xMovePlus,_yMovePlus,_xEaseXS,_yEaseXS,"touchEnd")
        else
            if self.rollType == "x" then
                self:moveEnd()
            end
        end
    end

    if self.currentTapingBtn then
        if
            self.xMoveLong<=self.moveLongMax and self.rollType =="h"
            or
            self.yMoveLong<=self.moveLongMax and self.rollType =="v"
            or
            self.xMoveLong<=self.moveLongMax and self.yMoveLong>self.moveLongMax and self.rollType =="x"
        then
            self.currentTapingBtn:onTouchEnded(touch_,event_)
            self.currentTapingBtn=nil
        end
    end

    self.xMoveLong=0
    self.yMoveLong=0
end

function disRoll:getMoveInfo( dis_ )
    -- body
    local _plus,_ease
    local _minus=false
    if dis_<0 then _minus=true end
    dis_=math.abs(dis_)
    if dis_<20 then
        _plus=dis_
        _ease=4
    elseif dis_<40 then
        _plus=dis_*1.5
        _ease=3.5
    elseif dis_<80 then
        _plus=dis_*2.5
        _ease=3
    elseif dis_<160 then
        _plus=dis_*2.5
        _ease=2.5
    else
        _plus=dis_*3
        _ease=2
    end
    if _minus then _plus=-_plus end
    return _plus,_ease
end


--停止移动
function disRoll:moveEnd()
    local _xMove=0
    if self.rollType=="h" or self.rollType=="x" then
        local _widthEdge = self.maxWidth-self.mouseRect.width
        if self.rollContainer:getPositionX()<-_widthEdge then -- 超界限  -- 左
            if _widthEdge>0 then-- 列表 比 显示区 宽
                _xMove=-_widthEdge-self.rollContainer:getPositionX()
            else-- 列表 没 显示区 宽
                _xMove=-self.rollContainer:getPositionX()
            end
        elseif self.rollContainer:getPositionX()>0 then -- 超界限 -- 右
            _xMove=-self.rollContainer:getPositionX()
        else--显示区内松手
            self.pressing=false -- 松手
            self.easeing=false -- 界内，不用缓动回位
        end
        if _xMove==0 then--没有超界
            for i=1,5 do
                table.insert(self.xMousePosArr,0)
            end
        end
    end
    local _yMove=0
    if self.rollType=="v" or self.rollType=="x" then
        local _heightEdge = self.maxHeight-self.mouseRect.height
        if self.rollContainer:getPositionY()>_heightEdge then -- 超界限 -- 下
            if _heightEdge>0 then-- 列表 比 显示区 长
                _yMove=_heightEdge-self.rollContainer:getPositionY()
            else-- 列表 比 显示区 短
                _yMove=-1*self.rollContainer:getPositionY()
            end
        elseif self.rollContainer:getPositionY()<0 then -- 超界限 -- 上
            _yMove=-1*self.rollContainer:getPositionY()
        else--显示区内松手
            self.pressing=false -- 松手
            self.easeing=false -- 界内，不用缓动回位
        end
        if _yMove==0 then--没有超界
            for i=1,5 do
                table.insert(self.yMousePosArr,0)
            end
        end
    end
    --只有超界才会发生的回弹
    if _xMove~=0 or _yMove~=0 then
        self.easeing=true--超界回弹 缓动又开始了
        self:startEasing(_xMove,_yMove,3,3,"moveEnd_beyondEdge")
    end
end

--开始缓动
function disRoll:startEasing(xMovePlus_,yMovePlus_,easeX_,easeY_,easeType_)
    self.easeing=true
    local _time
    --距离越长，时间越长，比较x跟y那个更长，谁长用谁计算
    if math.abs(xMovePlus_)>math.abs(yMovePlus_) then
        _time=0.002*(xMovePlus_)/1.0
    else
        _time=0.002*(yMovePlus_)/1.0
    end
    _time=math.abs(_time)--取正

    if easeType_=="moveEnd_beyondEdge" then
        if _time > 0.3 then --超界回弹，时间不要太长
            _time = 0.3
        end
    elseif easeType_=="touchEnd" then
        if _time >1.5 then --限制运算得到的时间
            _time=1.5
        end
    end
    local _moveAction
    if easeType_ == "touchEnd" then
        _moveAction=cc.EaseOut:create(cc.MoveBy:create(_time,cc.p(xMovePlus_,yMovePlus_)),easeX_+easeY_)
    elseif easeType_ == "moveEnd_beyondEdge" then
        _moveAction=cc.EaseInOut:create(cc.MoveBy:create(_time,cc.p(xMovePlus_,yMovePlus_)),easeX_+easeY_)
    end
    local function _callBackFun()
        --时间结束 -- 缓动结束
        self:easeEnd()
    end
    local _easeEnd = cc.CallFunc:create(_callBackFun)
    local _sequence = cc.Sequence:create(_moveAction, _easeEnd)
    --用tag来索引动作
    _sequence:setTag(999)
    self.rollContainer:runAction(_sequence) 
end

--手指按下的时候--停止缓动
function disRoll:stopEasing()
    if self.easeing then
        self.easeing=false
        --用tag来索引动作
        self.rollContainer:stopActionByTag(999)
        for i=1,5 do
            table.insert(self.yMousePosArr,0)
            table.insert(self.xMousePosArr,0)
        end
    end
end


--[[
缓动自然结束 以下两种情况都用到了这个函数
    松手的缓动结束
    超界回弹的缓动结束
]]--
function disRoll:easeEnd()
    if self.easeing then
        self.easeing =false
        self:moveEnd()
    end
end

--根据不同的类型进行元素排列
function disRoll:resetItemAndDisplayPlace(type_)
    if self.displayList_replace==nil then--获取一下根随列表变动坐标的东西
        self.displayList_replace={}
        for i=1,#self.displayList do
            local _tempDis=self.displayList[i]
            local _tempDisFirstInPos=self.firstInPosDict[_tempDis.name]
            if _tempDisFirstInPos then--创建出来的item没有对应的键值
                --获取在列表元素下面的显示对象
                if self.rollType=="v" and _tempDisFirstInPos.y < self.itemBeginPo.y then
                    table.insert(self.displayList_replace,self.displayList[i])
                elseif self.rollType=="h" and _tempDisFirstInPos.x > self.itemBeginPo.x then
                    table.insert(self.displayList_replace,self.displayList[i])
                end
            end
        end
    end

    local _deleteMoveTime=0.2
    local _deleteActionEaseType=31

    local _needMove=false
    if type_ == "delete" or type_ == "add" or type_ == "update" then
        _needMove = true
    elseif type_=="create" then
        _needMove=false
    else
        print('type_ : '..type_)
        assert(false,"ERROR resetItemAndDisplayPlace 不在规定之内")
    end

    local _itemCountInLine=0--当前行第几个
    local _currentLineMax=0--当前行，最高的
    local _currentLinePo=0--当前行，位置
    local _currentItemPo=cc.p(self.itemBeginPo.x,self.itemBeginPo.y)
    if self.rollType =="h" then
        _currentLinePo=_currentItemPo.x
    elseif self.rollType =="v" or self.rollType =="x" then--横纵向滚动层，默认列表是纵向的
        _currentLinePo=_currentItemPo.y
    end

    for i=1,#self.itemArray do--设置item位置
        local _tempItem=self.itemArray[i]
        local _targetPoint--计算位置
        if self.rollType =="v" or self.rollType =="x" then
            _targetPoint = cc.p(_currentItemPo.x,_currentLinePo)
            if _currentLineMax < _tempItem.rects["RectGreen"].height then
                _currentLineMax=_tempItem.rects["RectGreen"].height
            end
            _itemCountInLine=_itemCountInLine+1
            if _itemCountInLine == self.itemNumPerLine then--换行
                _itemCountInLine=0
                _currentLinePo=_currentLinePo-_currentLineMax
                _currentLineMax=0
                _currentItemPo.x=self.itemBeginPo.x
            else
                _currentItemPo.x=_currentItemPo.x+_tempItem.rects["RectGreen"].width
            end
        elseif self.rollType =="h"  then
            _targetPoint = cc.p(_currentLinePo,_currentItemPo.y)
            if _currentLineMax < _tempItem.rects["RectGreen"].width then
                _currentLineMax=_tempItem.rects["RectGreen"].width
            end
            _itemCountInLine=_itemCountInLine+1
            if _itemCountInLine == self.itemNumPerLine then--换行
                _itemCountInLine=0
                _currentLinePo=_currentLinePo+_currentLineMax
                _currentLineMax=0
                _currentItemPo.y=self.itemBeginPo.y
            else
                _currentItemPo.y=_currentItemPo.y-_tempItem.rects["RectGreen"].height
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
    for i=1,#self.displayList_replace do
        local _tempDis=self.displayList_replace[i]
        local _tempDisFirstInPos=self.firstInPosDict[_tempDis.name]
        local _targetX=_tempDis:getPositionX()
        local _targetY=_tempDis:getPositionY()
        if self.rollType=="v" then
            if #self.itemArray == 0 then
                _targetY=_tempDisFirstInPos.y
            else
                _targetY=_tempDisFirstInPos.y+_lastItem:getPositionY()-_lastItem.rects["RectGreen"].height-self.itemBeginPo.y
            end
        end
        if self.rollType=="h" then
            if #self.itemArray == 0 then
                _targetX=_tempDisFirstInPos.x
            else
                _targetX=_tempDisFirstInPos.x+_lastItem:getPositionX()+_lastItem.rects["RectGreen"].width-self.itemBeginPo.x
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
            self.maxHeight=self.baseHeight
        else
            self.maxHeight=self.baseHeight-_lastItem:getPositionY()-_lastItem.rects["RectGreen"].height-self.itemBeginPo.y
        end
    end
    if self.rollType=="h" then
        if #self.itemArray==0 then
            self.maxWidth=self.baseWidth
        else
            self.maxWidth=self.baseWidth+_lastItem:getPositionX()+_lastItem.rects["RectGreen"].width-self.itemBeginPo.x
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
    elseif type_=="create"then --create
        self.rollContainer:setPosition(cc.p(0,0))
    end
end
--删除元素结束
function disRoll:deleteMoveEnd()
    self.uiControl:waitSub()
end
--移除 多个元素，其他元素位移。
--self:removeItemByIndexs({1,2,4,5})
function disRoll:removeItemByIndexs(indexArray_)
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
function disRoll:resetItemIndexInfo()
    for i=1,#self.itemArray do--重排数据index
        self.itemArray[i]:setItemIndex(i)
    end
end
--清空元素列表
function disRoll:clearItems()
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
function disRoll:createItemByData(data_, idx_)
    local _item=self.uiControl:getUIByClassName(self.itemModuleName,self.itemClassName).new()
    _item.layerType = "item"
    table.insert(self.uiList,_item)
    self.displayUtils:setLogicParent(_item,self)
    _item:init(data_)
    _item:setItemIndex(idx_)
    return _item
end

--按照一个列表创建数据
function disRoll:createList(dataList_)
    if dataList_ ==nil then
        assert(false,"ERROR 用来创建列表的list为空")
    end
    self:clearItems()
    self.itemArray = {}
    for i=1, #dataList_ do
        local _item = self:createItemByData(dataList_[i], i)
        table.insert(self.itemArray, _item)
        self.rollContainer:addChild(_item)
    end
    self:resetItemAndDisplayPlace("create")
end

--获取初始化摆放的位置
function disRoll:getChildrenFirstInPos()
    if self.firstInPosDict==nil then
        self.firstInPosDict={}--初始化位置
        for i=1,#self.displayList do
            local _tempDis=self.displayList[i]
            self.firstInPosDict[_tempDis.name]=cc.p(_tempDis:getPositionX(),_tempDis:getPositionY())
        end
    end
end

--create-- call when init
function disRoll:onCreate()
    disRoll.super.onCreate(self)--onCreate中有initPlace摆放位置
    self:createClippingNodeByRect()
    self:getChildrenFirstInPos()
end
--destory-- call when removeChild
function disRoll:onDestory()
    disRoll.super.onDestory(self)
end
function disRoll:onDelete()
    self.currentTapingBtn=nil
    self.mouseRect=nil
    if self.displayList_replace then self.arrayUtils:clearArray(self.displayList_replace) end
    self.arrayUtils:clearArray(self.xMousePosArr)
    self.xMousePosArr=nil
    self.arrayUtils:clearArray(self.yMousePosArr)
    self.yMousePosArr=nil
    self.arrayUtils:clearArray(self.firstInPosDict)
    self.firstInPosDict=nil
    self:clearItems()
    disRoll.super.onDelete(self)
end

return disRoll
