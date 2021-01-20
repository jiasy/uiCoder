-- 数据分发的封装，一个数据路径变化，通知给各个监听此路径的对象
local Super = dcu.DataBase
local DataConnector = dcu_class("DataConnector",Super)

function DataConnector:ctor(uiNodeOrFunc_)
	Super.ctor(self,uiNodeOrFunc_)
	self.otherStringList = nil
	self.finalValue = nil
end

function DataConnector:destroy()
	if self.isDestroy == false then
		self.otherStringList=nil
		self.finalValue = nil
		Super.destroy(self)
	end
end

function DataConnector:recreateListenersByDataStr(dataStr_)
	self.dataStr = dataStr_ --记录字符串
	self:removeDataPathListeners() -- 清理原有路径监听
	self.dataPathListenerList = {}
	local _dataPathListenerList ,_otherStringList = dcu_splitDataStr(dataStr_)
	if _otherStringList ~= nil then
		self.otherStringList = _otherStringList
		for _idx = 1 , #_dataPathListenerList do
			self:addToDataPathEventListenerList(_dataPathListenerList[_idx])
		end
		self.bindType = BIND_TYPE_DATA_STRING
	else
		self:addToDataPathEventListenerList(self:changeUIDataPath(self.dataPath))
		self.bindType = BIND_TYPE_PURE_PATH
	end
end

function DataConnector:getFinalVaueFunc()
	if self.bindType ~= BIND_TYPE_DATA_STRING then
		dcu:logErr("非 BIND_TYPE_DATA_STRING 类型，无法获取字符串拼接 : "..tostring(self.bindType))
		return nil
	end
	local _final_string=""
	local _length =  #self.dataPathListenerList 
	for _idx = 1 , _length do
		local _dataPath = self.dataPathListenerList[_idx]
		local _dataOnPath = dc:getValueOnPath(_dataPath)
		if _dataOnPath == nil then
			dcu:logWarn("DataConnector -> dataChanged : " .. _dataPath .. " 值为空")
			return nil
		end
		_final_string = _final_string .. self.otherStringList[_idx] .. tostring(_dataOnPath)
	end 
	_final_string = _final_string .. self.otherStringList[#self.otherStringList]
	return _final_string
end
--数据变化
function DataConnector:dataChanged()
	Super.dataChanged(self)
	if not self.dataPathListenerList or #self.dataPathListenerList == 0 then
		return
	end

	if self.uiNodeOrFunc then
		local _type = dcu_type_getType(self.uiNodeOrFunc)
		if _type == "function" then
			local _length =  #self.dataPathListenerList -- 有移除操作的不要用这个写法
			if _length == 1 then
				local _dataOnPath = dc:getValueOnPath(self.dataPathListenerList[1])
				self.uiNodeOrFunc(_dataOnPath)
				return _dataOnPath
			else -- 监听的是一个列表的话，返回的是路径和值的列表集合
				local _pathAndValueDictList = {}
				local _loopCount = 0
				for _idx = 1 , _length do
					_loopCount = _loopCount + 1
					local _dataPath = self.dataPathListenerList[_idx]
					_pathAndValueDictList[_loopCount] ={
						path = _dataPath,
						value =  dc:getValueOnPath(_dataPath)	
					}
				end
				self.uiNodeOrFunc(_pathAndValueDictList)
				return _pathAndValueDictList
			end
			return nil
		else
			local _gObjectType = FUiUtils.GetGObjectType(self.uiNodeOrFunc)
			if _gObjectType == "GTextField" then
				self.finalValue = self:getFinalVaueFunc()
				if self.finalValue ~= nil then
					self.uiNodeOrFunc.text = self.finalValue -- 文字
				end
			elseif _gObjectType == "GLoader" then
				self.finalValue = self:getFinalVaueFunc()
				if self.finalValue ~= nil then
					self.uiNodeOrFunc.url = self.finalValue -- 图片url
				end
			else
				dcu:logWarn("".._gObjectType.." 不支持")
			end
			return self.finalValue
		end
	else
		if self.bindType == BIND_TYPE_DATA_STRING then
			self.finalValue = self:getFinalVaueFunc()
		elseif self.bindType == BIND_TYPE_PURE_PATH then
			--TODO
		end
		if self.dataPath then
			dcu:logInfo(self.dataPath.." : "..self.finalValue)
		else
			dcu:logInfo(self.dataStr.." : "..self.finalValue)
		end
	end
	return self.finalValue
end

return DataConnector