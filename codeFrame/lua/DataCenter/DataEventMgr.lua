local table_remove = table.remove
local DataEventMgr = dcu_class("DataEventMgr")

function DataEventMgr:ctor()
	self:reset()
end

function DataEventMgr:reset()
    self.dataEventDict = {}
end

function DataEventMgr:registerEvent(dataPath_,dataBase_)
	if not dataBase_.dataChanged then
		dcu:logErr("<"..dataPath_.."> 注册的数据变化监听对象，必须有dataChanged方法")
		return
    end
    local _dataBaseList = self.dataEventDict[dataPath_]
    if not _dataBaseList then
        _dataBaseList = {}
        self.dataEventDict[dataPath_] = _dataBaseList
        _dataBaseList[1] = dataBase_
    else
        _dataBaseList[#_dataBaseList + 1] = dataBase_
    end
end

function DataEventMgr:removeEvent(dataPath_,dataBase_)
    local _dataBaseList = self.dataEventDict[dataPath_]
    local _idxKey = dcu_list_indexof(_dataBaseList,dataBase_)
    if _idxKey ~= nil then
    	table_remove(_dataBaseList,_idxKey)
        if #_dataBaseList == 0 then
            self.dataEventDict[dataPath_] = nil
        end
    else
        dcu:logErr("<"..dataPath_.."> 没有对应的显示对象!")
    end
end

function DataEventMgr:showAllListenDataPath()
    local _logStr = "-------------------------- listeners --------------------------------------\n"
    local _keyList = dcu_table_keys(self.dataEventDict,true)
    local _length =  #_keyList
    for _idx = 1 , _length do
        local _dataPath = _keyList[_idx]
        _logStr = _logStr .. _dataPath .." : "..tostring(#self.dataEventDict[_dataPath]) .."\n"
    end
    dcu:logInfo(_logStr)
end

function DataEventMgr:hasdataBaseForDataPath(dataPath_)
    if self.dataEventDict[dataPath_]then
        return true
    else
        return false
    end
end

function DataEventMgr:getListenerCount(dataPath_)
    local _dataBaseList = self.dataEventDict[dataPath_]
    if _dataBaseList ~= nil then
        return #_dataBaseList
    end
    return 0
end

function DataEventMgr:onDataChange(dataPath_)
    local _dataBaseList = self.dataEventDict[dataPath_]
    if _dataBaseList ~= nil then
        local _length =  #_dataBaseList
	    for _idx = 1 , _length do
	        local _dataBase = _dataBaseList[_idx]
	        _dataBase:dataChanged()
	    end
    end
end

return DataEventMgr