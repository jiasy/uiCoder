local ItemContainer = dcu_class("ItemContainer")

function ItemContainer:ctor(item_,luaItemClickHander_)
	self.item = item_
	self.luaItemClickHander = luaItemClickHander_
	self.idx = -1 -- 序号
	self.dataBaseList = {} -- 数据监听
	self.btnRemoveFuncDict = {}
	self.specialNameCacheList = {}
end

function ItemContainer:destroy()
	self.item = nil
	self.luaItemClickHander = nil
	local _length =  #self.btnRemoveFuncDict
    for _idx = 1 , _length do
        self[self.btnRemoveFuncDict[_idx]] = nil
	end
	local _length =  #self.dataBaseList
    for _idx = 1 , _length do
        self.dataBaseList[_idx]:destroy()
	end
	for _,_btnPressAndClickRemoveFunc in pairs( self.btnRemoveFuncDict ) do
		_btnPressAndClickRemoveFunc()-- 调用清理方法
	end
	self.idx = nil
end

function ItemContainer:onBtnClick(btnName_,context_)
	self.luaItemClickHander.onItemBtnClick(self.luaItemClickHander,self.idx,self.item,btnName_,context_)
end

function ItemContainer:onScroll(scrollPane_)
	self.luaItemClickHander.onScroll(self.luaItemClickHander,scrollPane_)
end


-- 数据分发的封装，一个数据路径变化，通知给各个监听此路径的对象
local Super = dcu.DataBase
local DataListConnector = dcu_class("DataListConnector",Super)

function DataListConnector:ctor(uiNode_,luaItemClickHander_)
	Super.ctor(self,uiNode_)
	self.luaItemClickHander = luaItemClickHander_
	self.itemContainerDict = {} -- item 和 其包含对象
	self.listInited = false
end

function DataListConnector:destroy()
	if self.isDestroy == false then
		self.luaItemClickHander = nil
		for _item,_itemContainer in pairs( self.itemContainerDict ) do
			_itemContainer:destroy()
		end
		self.itemContainerDict = nil
		Super.destroy(self)
	end
end
--重置数据路径，重新取值
function DataListConnector:resetPureDataPath(dataPath_)
	if string.match(dataPath_,"length$") == nil then
		dcu:logErr("数组绑定，一定绑定数组的长对应的键。")
		return
	end
	Super.resetPureDataPath(self,dataPath_)
end
--重置数据路径，重新取值
function DataListConnector:resetDataPath(dataPath_)
	dcu:logErr("List 只能使用 resetPureDataPath 方法指定绑定数据路径。只能是 BIND_TYPE_PURE_PATH 类型，并关联 .length 路径")
end

function DataListConnector:resetByStr(dataStr_,internalCalls_)
	dcu:logErr("List 不能进行拼接值绑定。只能是 BIND_TYPE_PURE_PATH 类型，并关联 .length 路径")
end

function DataListConnector:recreateListenersByDataStr(dataStr_)
	dcu:logErr("List 绑定的只能是一个数据路径，不能绑定拼接值。只能是 BIND_TYPE_PURE_PATH 类型，并关联 .length 路径")
end

-- 重置数组元素序号的时候重置数组元素内容
-- TODO item 不是FguiObjectBase，是一个 C# FGUI 对象
function DataListConnector:resetItemInfo(item_,uiPath_,idx_)
	item_.uiPath = uiPath_
	local _itemContainer = self.itemContainerDict[item_]
	local _lastIdx = 0
	if _itemContainer ==nil then -- 没有初始化过
		_itemContainer = ItemContainer.new(item_,self.luaItemClickHander)
		du:eachGComponentWhenNodeCreate(_itemContainer,item_,uiPath_,_itemContainer.dataBaseList) -- 创建 dataBase 监听
		self.itemContainerDict[item_] = _itemContainer
	else
		du:resetItemUIPath(item_,uiPath_) -- 重置所有的 uiPath 和 item 关联的 uiPath_ 保持一致
		if _itemContainer.idx ~= idx_ then -- 变更监听的数据路径。序号不变的话，数据路径不变，不用重置
			local _length =  #_itemContainer.dataBaseList
			for _idx = 1 , _length do
				local _dataBase = _itemContainer.dataBaseList[_idx]
				if _dataBase.dataPath == nil then
					_dataBase:resetByStr(_dataBase.dataStr,false)
				else
					_dataBase:resetDataPath(_dataBase.dataPath)
				end
			end
		end
	end
	_itemContainer.idx = idx_
	du:dynamicName(item_,uiPath_) -- 变更显示名称
	return _itemContainer
end

--数据变化
function DataListConnector:dataChanged()
	Super.dataChanged(self)
	local _dataPathListenerList = self.dataPathListenerList
	if not _dataPathListenerList or #_dataPathListenerList == 0 then
		return
	end
	if self.uiNodeOrFunc then
		if #_dataPathListenerList == 1 then -- 列表只能监听一个数据源，两个或以上，要加工到一个数据源之后，再关联到这里
			local _listDataPath = string.split(_dataPathListenerList[1],".length")[1]-- 关注的是列表路径
			local _listDict = dc:getValueOnPath(_listDataPath) -- 取数据
			if #dcu_table_keys(_listDict) ~= 0 and dcu_isConvertedList(_listDict)==false then -- 不是空的时候不是数组样式
				dcu:logErr("GList只能关注列表， 确保其关联的数据源是数组长度键")
			else
				dc:table_makeSureList(_listDict) -- 确保其格式，长度为零的时候，表象是空表。
				local _length = _listDict["length"]
				if self.listInited == false then -- 没初始化过
					self.uiNodeOrFunc:SetVirtual() -- 虚拟列表
					self.uiNodeOrFunc.itemRenderer = function(idx_, item_)-- 绑定数据路径
						self:resetItemInfo(item_,_listDataPath..".["..tostring(idx_+1).."]",idx_)
					end
					self.listInited = true
				end
				self.uiNodeOrFunc.numItems = _length -- 刷新长度
			end
		else
			dcu:logErr("GList只能关注一个数据源，确保其关注的内容不是一个拼接字符串")
		end
	end
	return nil
end

return DataListConnector