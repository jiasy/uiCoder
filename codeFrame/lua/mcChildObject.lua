[<File_doc|ui|/src/app/base/ui/mcChildObject.lua|replace>]
local mcChildObject = class("mcChildObject")

--创建
function mcChildObject:ctor(params_)
	self.displayObject=nil
	self.beginFrame=0
	self.endFrame=0
	self.testUtils=testUtils:getInstance()
	self.displayUtils=displayUtils:getInstance()
    self.frameProperty={}
end

--初始化
function mcChildObject:init(displayObject_,beginFrame_,endFrame_,ps_)
	self.displayObject=displayObject_
	self.beginFrame=beginFrame_
	self.endFrame=endFrame_

	self.xVector={}            --x
    self.yVector={}            --y
    self.rotationVector={}     --rotation
    self.sxVector={}           --scale X
    self.syVector={}           --scale Y
    self.aVector={}            --opacity
    -- self.rVector={}--r
    -- self.gVector={}--g
    -- self.bVector={}--b

	--每一帧属性
    local _propertyDataVector=ps_
    local _propertyDataCount=#_propertyDataVector
    --循环数据获取 每一个 属性对象 的数据
    for _currentIndex=1,_propertyDataCount do
        local _tempNode=_propertyDataVector[_currentIndex]
        local _tempNodeLength=#_tempNode
        _tempNodeLength=math.floor(_tempNodeLength/2)
        for _currentNodeIndex=1,_tempNodeLength do
            --循环几次写入这个值
            local _tempNodeLoopLength=_tempNode[2*_currentNodeIndex]
            for _currentNodeLoopIndex=1,_tempNodeLoopLength do
                if _currentIndex==1 then--x
                    table.insert(self.xVector,_tempNode[2*_currentNodeIndex-1])
                end
                if _currentIndex==2 then--y
                    table.insert(self.yVector,_tempNode[2*_currentNodeIndex-1])
                end
                if _currentIndex==3 then--r
                    table.insert(self.rotationVector,_tempNode[2*_currentNodeIndex-1])
                end
                if _currentIndex==4 then--sx
                    table.insert(self.sxVector,_tempNode[2*_currentNodeIndex-1])
                end
                if _currentIndex==5 then--sy
                    table.insert(self.syVector,_tempNode[2*_currentNodeIndex-1])
                end
                if _currentIndex==6 then--a
                    table.insert(self.aVector,_tempNode[2*_currentNodeIndex-1])
                end
                -- if _currentIndex==7 then--r
                --     table.insert(self.rVector,_tempNode[2*_currentNodeIndex-1])
                -- end
                -- if _currentIndex==8 then--g
                --     table.insert(self.gVector,_tempNode[2*_currentNodeIndex-1])
                -- end
                -- if _currentIndex==9 then--b
                --     table.insert(self.bVector,_tempNode[2*_currentNodeIndex-1])
                -- end
            end
        end
    end
end

--获取当前帧的数字
function mcChildObject:getByPropertysFrame(parentTargetFrame_)
    --self.testUtils:FI("frameUpdateProperty",self.displayObject.name,"getByPropertysFrame","parentTargetFrame_ : "..parentTargetFrame_)

    local _tempProperty=nil
    local _index=parentTargetFrame_-self.beginFrame+1
    self.parentCurrentFrame=parentTargetFrame_

    --这帧数下，没有数据的话，就创建一个
    if self.frameProperty[parentTargetFrame_] == nil then
        _tempProperty={}
        table.insert(_tempProperty,self.xVector[_index])
        table.insert(_tempProperty,self.yVector[_index])
        table.insert(_tempProperty,self.rotationVector[_index])
        table.insert(_tempProperty,self.sxVector[_index])
        table.insert(_tempProperty,self.syVector[_index])
        table.insert(_tempProperty,self.aVector[_index])
        -- table.insert(_tempProperty,self.rVector[_index])
        -- table.insert(_tempProperty,self.gVector[_index])
        -- table.insert(_tempProperty,self.bVector[_index])
        self.frameProperty[parentTargetFrame_]=_tempProperty
    else--有的时候，直接取得
        _tempProperty=self.frameProperty[parentTargetFrame_]
    end

    --self.testUtils:FO("frameUpdateProperty",self.displayObject.name,"getByPropertysFrame","")
    return _tempProperty
end
function mcChildObject:propertyInFrame(parentCurrentFrame_)
    local _propertyVector= self:getByPropertysFrame(parentCurrentFrame_)
    self.displayUtils:place(self.displayObject,_propertyVector[1],_propertyVector[2],_propertyVector[3],_propertyVector[4],_propertyVector[5],_propertyVector[6])
    -- if _propertyVector[7]~=0 or _propertyVector[8]~=0 or _propertyVector[9]~=0 then--TODO bug...when use
    --     self.displayObject:setColor(cc.c3b(_propertyVector[7],_propertyVector[8],_propertyVector[9]))
    -- end
end

--消除
function mcChildObject:onDelete()
    while #self.frameProperty~=0 do
        table.remove(self.frameProperty)
    end
    self.frameProperty=nil
	self.testUtils=nil
	self.displayObject=nil
	self.pxs=nil
	self.pys=nil
	self.rs=nil
	self.sxs=nil
	self.sys=nil
	self.as=nil
	self.vs=nil
	self.xVector=nil--x坐标
    self.yVector=nil--y坐标
    self.rotationVector=nil--旋转
    self.aVector=nil--透明
    self.sxVector=nil--x大小
    self.syVector=nil--y大小
    self.rVector=nil--r
    self.gVector=nil--g
    self.bVector=nil--b
end

return mcChildObject