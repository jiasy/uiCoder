local disBase=require("src.app.base.ui.disBase")
local disTableView = class("disTableView",disBase)

function disTableView:ctor(params_)
	disTableView.super.ctor(self,params_)
	self.className="disTableView"
	self.displayType="base"
	self.name="none"

	--元素宽高
	self.sellNumber=0
	--模块名-类名
	self.cellUIModuleName=nil
	self.cellUIClassName=nil
	--方向
	self.direction=nil


	self.tableView=nil
	self.dataList=nil
end

--init
function disTableView:init(initDict_)
	disTableView.super.init(self,initDict_)
	if self.rects["RectGreen"]==nil then
		assert(false,"ERROR tableView有且只有一个Rect")
	end
	self.tableView = cc.TableView:create(cc.size(self.rects["RectGreen"].width,self.rects["RectGreen"].height))
    if self.direction=="h" then
    	self.tableView:setDirection(cc.SCROLLVIEW_DIRECTION_HORIZONTAL)
    elseif self.direction=="v" then
    	self.tableView:setDirection(cc.SCROLLVIEW_DIRECTION_VERTICAL)
    end
    self.tableView:setAnchorPoint(cc.p(0,0))
    self.tableView:setPosition(cc.p(0,0))
    self.tableView:setDelegate()
    self:addChild(self.tableView)
    function _numberOfCellsInTableView(table_)
    	self:numberOfCellsInTableView(table_)
    end
    function _cellSizeForTable(table_,idx_)
    	self:cellSizeForTable(table_)
    end
    function _tableCellAtIndex(table_,idx_)
    	self:tableCellAtIndex(table_,idx_)
    end
    --registerScriptHandler functions must be before the reloadData funtion
    self.tableView:registerScriptHandler(_numberOfCellsInTableView,cc.NUMBER_OF_CELLS_IN_TABLEVIEW)  
    self.tableView:registerScriptHandler(_cellSizeForTable,cc.TABLECELL_SIZE_FOR_INDEX)
    self.tableView:registerScriptHandler(_tableCellAtIndex,cc.TABLECELL_SIZE_AT_INDEX)
    self.tableView:reloadData()
    if self.initDict.dataList then
    	self:reCreateItemByList(self.initDict.dataList)
    end
end


--设置基础属性
function disTableView:setProperty(cellUIModuleName_,cellUIClassName_,direction_)
	self.cellUIModuleName=cellUIModuleName_
	self.cellUIClassName=cellUIClassName_
	self.direction=direction_
end

--获取元素宽高
function disTableView:cellSizeForTable(table_,idx_)
	--元素宽高
	local _cellWidth
	local _cellHeight
	--取得item
	local _tempItem=self.uiList[idx_+1]
	local _itemRect
	if _tempItem.rects["RectGreen"] then
		_itemRect=_tempItem.rects["RectGreen"]
	else
		assert(false,"ERROR Item必须有一个RectGreen来标示item大小")
	end
	_cellWidth=_itemRect.width
	_cellHeight=_itemRect.height
    return _cellWidth,_cellHeight
end

function disTableView:reCreateItemByList(dataList_)
	self.sellNumber=#dataList_
	self.initDict.dataList=dataList_
	self:clearOldList()
end

function disTableView:clearOldList()
	local _firstCell=self.tableView:cellAtIndex(0)
	while _firstCell do
		local _tempItem=table.remove(self.uiList,1)
		_tempItem:onDelete()
		_tempItem:removeFromParent(true)
		self.tableView:removeCellAtIndex(0)
		_firstCell=self.tableView:cellAtIndex(0)
	end
end

function disTableView:tableCellAtIndex(table_, idx_)
    local cell = table_:dequeueCell()
    local label = nil
    if nil == cell then
        cell = cc.TableViewCell:new()
        local _item
        self.uiList[idx_+1]=_item
        _item:setItemIndex(idx_)
        _item.parent=self.parent
        _item.layerType="item"
        cell:addChild(_item)
    end

    return cell
end

function disTableView:numberOfCellsInTableView(table_)
   return self.sellNumber
end

--Create--
function disTableView:onCreate()
	disTableView.super.onCreate(self)
end

--Destory--
function disTableView:onDestory()
	disTableView.super.onDestory(self)
end

function disTableView:onDelete()
	--先调用这个，uiList清理。再走onDelete，uiList为0长。
	self:clearOldList()
	disTableView.super.onDelete(self)
	if self.tableView then
		self.tableView:removeFromParent(true)
	end
end

return disTableView