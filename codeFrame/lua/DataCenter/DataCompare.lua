local string_find = string.find
-- 数据分发的封装，一个数据路径变化，通知给各个监听此路径的对象
local Super = dcu.DataBase
local DataCompare = dcu_class("DataCompare",Super)
local type = type
-- 数据比较
function DataCompare:ctor(uiNodeOrFunc_,propertyName_)
	Super.ctor(self,uiNodeOrFunc_)
	self.propertyName = propertyName_
	if self.propertyName ~= nil then
		if not (self.propertyName == "visible" or self.propertyName == "enabled" or self.propertyName == "selected" or self.propertyName == "grayed" or self.propertyName == "touchable") then
			dcu:logWarn(""..self.propertyName.." 并不支持")
		end
	end
	self.firstValue = nil
	self.compareMode = nil
	self.secondArr = nil
end

function DataCompare:destroy()
	if self.isDestroy == false then
		self.propertyName = nil
		self.firstValue = nil
		self.compareMode = nil
		self.secondArr = nil
		Super.destroy(self)
	end
end

function DataCompare:recreateListenersByDataStr(dataStr_)
	self.dataStr = dataStr_ --记录字符串
	local _compareMode = nil
	if string_find(dataStr_,'%(%)') then
		_compareMode = '()'
	elseif string_find(dataStr_,'%(%]') then
		_compareMode = '(]'
	elseif string_find(dataStr_,'%[%)') then
		_compareMode = '[)'
	elseif string_find(dataStr_,'%[%]')then
		_compareMode = '[]'
    elseif string_find(dataStr_,'>=') then
        _compareMode = '>='
    elseif string_find(dataStr_,'<=') then
        _compareMode = '<='
    elseif string_find(dataStr_,'>') then
        _compareMode = '>'
    elseif string_find(dataStr_,'<') then
        _compareMode = '<'
    elseif string_find(dataStr_,'==') then
        _compareMode = '=='
    elseif string_find(dataStr_,'!=') then
        _compareMode = '!='
    end
    if _compareMode ~= nil then
        local _compareArr = dcu_string_split(dataStr_,_compareMode)
        self.firstValue  = _compareArr[1]
        self.compareMode = _compareMode
		if string_find(_compareArr[2],',') then
			self.secondArr = dcu_string_split(_compareArr[2],",")
		else
			self.secondArr = {_compareArr[2]}
		end
    else
    	dcu:logErr(dataStr_.." , 没有比较字符串")
	end
	
	self:removeDataPathListeners() -- 清理原有路径监听
	self.dataPathListenerList = {}
	self:addToDataPathEventListenerList(self.firstValue)
    for _idx = 1 , #self.secondArr do
    	self:addToDataPathEventListenerList(self.secondArr[_idx])
	end
	self.bindType = BIND_TYPE_DATA_STRING
end

--数据发生变化
function DataCompare:dataChanged()
	Super.dataChanged(self)
	if not self.dataPathListenerList or #self.dataPathListenerList == 0 then
		return nil
	end
	local _arr={}
	local _firstValue  = self:getRealValue(self.firstValue)
	if _firstValue == nil then --可能数据还没有创建
		dcu:logWarn(""..self.firstValue.." 当前还没有值，无法参与比较")
		return nil
	end
	_arr[1] = _firstValue
	_arr[2] = self.compareMode
	if self.secondArr[1] then
		_arr[3] = self:getRealValue(self.secondArr[1])
	end
	if self.secondArr[2] then
		_arr[4] = self:getRealValue(self.secondArr[2])
	end
	local _compare_result = dc:dataCompare(_arr)
	local _resultBool = false
	if _compare_result==nil then
		dcu:logErr(self.dataStr.." 比较未能获取正确结果")
		return nil
	end
	if _compare_result==0 then
		_resultBool = false
	elseif _compare_result==1 then
		_resultBool = true
	end
	if self.uiNodeOrFunc then
		local _type = dcu_type_getType(self.uiNodeOrFunc)
		if _type == "function" then
			self.uiNodeOrFunc(_resultBool)
			return _resultBool
		else
			if self.propertyName ~= nil then
				local _gObjectType = FUiUtils.GetGObjectType(self.uiNodeOrFunc)
				if self.propertyName == "visible" then
					self.uiNodeOrFunc.visible = _resultBool
				elseif self.propertyName == "selected" then
					if not _gObjectType == "GButton" then
						dcu:logWarn(""..self.propertyName.." 不支持 ".._gObjectType)
					end
					self.uiNodeOrFunc.selected = _resultBool
				elseif self.propertyName == "enabled" then
					self.uiNodeOrFunc.enabled = _resultBool
				elseif self.propertyName == "touchable" then
					self.uiNodeOrFunc.touchable = _resultBool
				elseif self.propertyName == "grayed" then
					self.uiNodeOrFunc.grayed = _resultBool
				else
					dcu:logWarn("不支持 "..tostring(self.propertyName))
				end
			else
				dcu:logWarn("非方法必须指定属性 {propertyName} ")
			end
			return _resultBool
		end
	else
		local _printResult = function(result_)
			dcu:logInfo(self.dataStr .. " : "..tostring(result_))
		end
		if _compare_result == 0 then
			_printResult(false)
			return false
		elseif _compare_result == 1 then
			_printResult(true)
			return true
		else
			return nil
		end
	end
end

return DataCompare