local type = type
local string_find = string.find
local DataBase = dcu_class("DataBase")

function DataBase:ctor(uiNodeOrFunc_)
	self.uiNodeOrFunc = uiNodeOrFunc_
	self.dataPath = nil
	self.dataStr = nil
	self.isDestroy = false
	self.bindType = BIND_TYPE_NONE
	dc.dataBaseList[#dc.dataBaseList + 1] = self
end

function DataBase:destroy()
	if self.isDestroy == false then
		self:removeDataPathListeners()
		self.uiNodeOrFunc = nil
		self.dataPath = nil
		self.dataStr = nil
		self.isDestroy = true
	end
end

-- 直接设置监听路径列表，不包含取其中值的过程
function DataBase:resetPureDataPathList(dataPathList_)
	self:removeDataPathListeners() -- 清理原有路径监听
	self.dataPathListenerList = {}
	self.dataStr = nil
	local _length =  #dataPathList_ -- 有移除操作的不要用这个写法
	for _idx = 1 , _length do
		self:addToDataPathEventListenerList(dataPathList_[_idx])
	end
	self.bindType = BIND_TYPE_PURE_PATH
	return self:dataChanged()
end

--重置数据路径，不包含获取其中值的过程
function DataBase:resetPureDataPath(dataPath_)
	self:resetPureDataPathList({dataPath_})
end

--重置数据路径，重新取值。需要取其中内容。然后走resetByStr
function DataBase:resetDataPath(dataPath_)
	self.dataPath = dataPath_
	local _dataStr = self:getValue(self.dataPath)--数据路径中的值取出来
	return self:resetByStr(_dataStr,true)
end

--重置数据路径，重新取值
function DataBase:resetByStr(dataStr_,internalCalls_)
	internalCalls_ = internalCalls_ or false
	if internalCalls_ == false then -- 外部调用，指定字符串。不指定路径
		self.dataPath = nil --外部调用，需要清空路径指定。
	end
	self:recreateListenersByDataStr(dataStr_) -- 重新创建监听
    return self:dataChanged()
end

function DataBase:dataChanged()
	if self.bindType == BIND_TYPE_NONE then
		dcu:logErr("绑定类型没有修改，请校验逻辑")
	end
end

-- 字符串，是不是一个数据路径
function DataBase:isDataPath(valueStr_)
	if string_find(valueStr_,'%.') and dcu:isPureDataPath(valueStr_) then
		return true
	else
		return false
	end
end

-- 获取值 
function DataBase:getRealValue(dataPathStr_)
	if self:isDataPath(dataPathStr_) then
		return self:getValue(dataPathStr_)
	else
		return dataPathStr_
	end
end

-- 获取数据
function DataBase:getValue(dataPathStr_)
	if string_find(dataPathStr_,'this.') then -- 需要路径转换
		local _uiDataPath = self:changeUIDataPath(dataPathStr_) -- 拓展
		if _uiDataPath ~= nil then
			return dc:getValueOnPath(_uiDataPath)
		end
	else -- 不需要路径转换
		return dc:getValueOnPath(dataPathStr_)
	end
end

-- 添加数据监听
function DataBase:addToDataPathEventListenerList(dataPathStr_)
	if self:isDataPath(dataPathStr_) then -- 是一个数据路径
		if string_find(dataPathStr_,'this.') then -- 需要路径转换
			local _uiDataPath = self:changeUIDataPath(dataPathStr_)
			local _idx = dcu_list_indexof(self.dataPathListenerList,_uiDataPath);
			if _idx == nil then-- 没有建听过，就监听它
				self.dataPathListenerList[#self.dataPathListenerList + 1] = _uiDataPath
				dc.dataEventMgr:registerEvent(_uiDataPath,self)
			end
		else -- 不需要路径转换
			local _idx = dcu_list_indexof(self.dataPathListenerList,dataPathStr_);
			if _idx == nil then-- 没有建听过，就监听它
				self.dataPathListenerList[#self.dataPathListenerList + 1] = dataPathStr_
				dc.dataEventMgr:registerEvent(dataPathStr_,self)
			end
		end
	end
end

function DataBase:changeUIDataPath(dataPath_)
	if self.uiNodeOrFunc == nil then -- 没有关联对象，直接返回
		return dataPath_
	end
	if dcu_type_getType(self.uiNodeOrFunc) == "function" then -- 不是UI对象关联
		return dataPath_
	end
	if self.uiNodeOrFunc.uiPath == nil then
		dcu:logWarn(": DataBase " .. dataPath_ .. " 为UI数据路径，没有绑定是哪个UI")
		return nil
	end
	local _dataPath = dataPath_
	local _subDataPath = dcu_string_split(_dataPath,"this.")[2]
	_dataPath = self.uiNodeOrFunc.uiPath .. "." .. _subDataPath
	return _dataPath
end

--移除数据路径监听
function DataBase:removeDataPathListeners()
	if self.dataPathListenerList then
		local _length = #self.dataPathListenerList 
	    for _idx = 1 , _length do
			dc.dataEventMgr:removeEvent(self.dataPathListenerList[_idx],self)
	    end
	end
	self.dataPathListenerList = nil
end

return DataBase