--[[
	数据模块包含以下命名空间
		UI自己持有的数据源是 UI.界面名            创建UI时，遍历节点将节点的uiPath设置成递归的路径
		Model持有的数据源是 Model.模块名         创建模块是，生成一个数据源
		服务器同步的数据源是 Sync.proto协议名     服务器同步协议时，proto前缀为Syn的设置到这个空间
		服务器响应的数据源是 Res.proto协议名      服务器响应时，proto不是Syn的设置到这个空间
		玩家本地配置数据源是 Settings 音量设置    玩家的本地配置，音量开关等等
		配置表转换的数据源是 Game                当前游戏的各种配置表，数值信息等等
        APP的相关的数据源是 App                 App信息 是否是测试版本，版本号等等，当前是否是提审状态
        运行时配置的数据源是 Config              当前连接的 websocket地址
        本地化翻译的数据源是 Trans               当前的语言配置，和 txt_ 的结节点命名配合，通过配置表达到更换语言的作用
]]
--[[
    dc:gvNumber("Model.Warehouse."..tostring(_itemID)) -- 这里一定要加 tostring ，以免 _itemID 为空的时候报错。转换字符串后，顶多取出来的值是空。
]]

local type = type
local pairs = pairs
local ipairs = ipairs
local tostring = tostring
local table_sort = table.sort
local string_find = string.find
local string_match = string.match
local string_gmatch = string.gmatch
local DataCenter = dcu_class("DataCenter")

function DataCenter:ctor ()
    _G.dc = self
    self.dataEventMgr = dcu.DataEventMgr.new()
    self:reset() -- 重置
end

function DataCenter:reset()
    -- self.setValueToPathTimes = 0
    self.whileTimes = 0
    if self.dataBaseList then
        local _length =  #self.dataBaseList
        for _idx = 1 , _length do
            self.dataBaseList[_idx]:destroy()
        end
    end
    self.dataBaseList = {}
    self.dataSet           = {}
    self.ds = self.dataSet -- 取值，不触发事件分发。可以通过 dc.ds.UI....  这样的方式来获取值
    self.justChangeInfoDict = {}
    self.valuePathDict = {} -- 同步键信息
    self.syncDictPathDict = {} -- 同步数据节点
    self.separateDict = {} -- 数据节点二次拆解
    self.remapValueDict = {} -- 数据节点值映射
    self.listToDictDict = {} -- 列表元素的键值同步给字典
    self.listToListDict = {} -- 列表同步
    self.listSumDict = {} -- 列表某键求和
    self:setValueToPath("Temp",{}) -- 临时数据源
    self:setValueToPath("UI",{}) -- 界面数据源
    self:setValueToPath("Model",{}) -- 模块数据源
    self:setValueToPath("Sync",{}) -- 服务器同步
    self:setValueToPath("Res",{}) -- 服务器响应
    self:setValueToPath("Game",{}) -- 游戏配置 - 游戏数值等表格
    self:setValueToPath("App",{}) -- 状态配置 - 是不是提审之类的
    self:setValueToPath("Config",{}) -- 运行配置 - 链服务器之类的
    self:setValueToPath("Settings",{}) -- 用户本地设置
    self:setValueToPath("Trans",{}) -- 翻译
    self.pureDataPathList = {} -- 存数据路径的缓存
    self.dataEventMgr:reset() -- 重置
end

-- 处理数据变化 -- 必须调用这个方法，才会进行数据变更事件分发
function DataCenter:dispatchDataChange(logTitle_)
    -- 只有发生过变化才会触发数据变更
    local _justChangeDataPathList = dcu_table_keys(self.justChangeInfoDict,dcu.isDebug)
    if #_justChangeDataPathList > 0 then
        local _logStr = nil
        if dcu.isDebug then -- 打印变更信息
            _logStr = "\n- DISPATCH DATA CHANGE -\n"
            if logTitle_ ~= nil then
                _logStr = "\n"..logTitle_ .."\n"
            end
        end
        local _syncCount = 0
        local _count = 0
        while #_justChangeDataPathList > 0 do -- 进行的过程中，又出现了新的内容，就继续
            _count = _count + 1
            if dcu.isDebug then -- 打印变更信息
                _logStr = _logStr .. " - " ..tostring(_count) .. " - \n"
            end
            local _justChangeInfoList = {} -- 数组将 self.justChangeInfoDict 清空。因为，过程中还会添加，所以，不要使用同一个应用，避免死循环。
            local _length =  #_justChangeDataPathList
            local _loopCount = 0
            for _idx = 1 , _length do
                _loopCount = _loopCount + 1
                local _changeDataPath = _justChangeDataPathList[_idx]
                _justChangeInfoList[_loopCount] = self.justChangeInfoDict[_changeDataPath] -- 引用移交给数组
                self.justChangeInfoDict[_changeDataPath] = nil -- 清理键值引用
            end
            while  #_justChangeInfoList > 0 do
                local _justChangeInfo = dcu_list_shift(_justChangeInfoList)
                local _valueList = _justChangeInfo.valueList
                local _valueListLength = #_valueList
                local _changeDataPath = _justChangeInfo.dataPath
                _justChangeInfo.finalValue = _valueList[_valueListLength] -- 赋值到最终值
                if dcu.isDebug then -- 打印变更信息
                    local _listenerCount = self.dataEventMgr:getListenerCount(_changeDataPath)
                    local _old = _valueList[1]
                    if _old == "<NIL_MARK>" then
                        _old = "nil"
                    elseif _old == "" then
                        _old = '""'
                    end
                    local _history = tostring(_old)
                    for _idx = 2 , _valueListLength do
                        local _current = tostring(_valueList[_idx])
                        if _current == "<NIL_MARK>"then
                            _current = "nil"
                        elseif _current == "" then
                            _current = '""'
                        end
                        _history = _history .." > ".. tostring(_current)
                    end

                    _logStr = _logStr .. _changeDataPath .. " : ".. _history
                    if _listenerCount > 0 then
                        _logStr = _logStr.."  -------------------<".._listenerCount..">"
                    end
                    _logStr = _logStr.."\n"
                end

                local _syncPathList = self.valuePathDict[_changeDataPath]
                if _syncPathList ~= nil then
                    local _length =  #_syncPathList
                    for _idx = 1 , _length do
                        -- if dcu.isDebug then self.whileTimes = self.whileTimes + 1 end
                        _syncCount = _syncCount + 1
                        local _syncPathInfo = _syncPathList[_idx]
                        local _finalValue = _justChangeInfo.finalValue
                        if _syncPathInfo.convertIngFunc then -- 有转换方法的话
                            _finalValue = _syncPathInfo.convertIngFunc(self:getValueOnPath(_syncPathInfo.toPath),_justChangeInfo.finalValue) -- 进行转换得到最终值
                        end
                        if dcu.isDebug then
                            _logStr = _logStr .. "    【SYNC】 -> ".._syncPathInfo.toPath .. " = " .. tostring(_finalValue).."\n"
                        end
                        self:setValueToPath(_syncPathInfo.toPath,_finalValue)
                    end
                end
                self.dataEventMgr:onDataChange(_changeDataPath) -- 数据变更
            end
            _justChangeDataPathList = dcu_table_keys(self.justChangeInfoDict,dcu.isDebug)
        end
        -- 打印数据变更信息
        if dcu.isDebug then
            dcu:logInfo(_logStr)
            -- print("setValueToPath : "..tostring(self.setValueToPathTimes))
            -- print("whileTimes : "..tostring(self.whileTimes))
            -- self.setValueToPathTimes = 0
            -- self.whileTimes = 0
        end
        if _syncCount > 0 then -- 同步过数据，需要在发一次数据变更
            self:dispatchDataChange("- SYNC ------> ")
        end
    end
end

-- 调试接口 ---------------------------------------------------------------------------
function DataCenter:getKeyListOnPath(dataPath_)
    if dataPath_ == nil or dataPath_ == "" then
        return dcu_table_keys(dc.ds,true)
    else
        local _dataOnPath = self:getValueOnPath(dataPath_)
        return dcu_table_keys(_dataOnPath,true)
    end
end
-- 过滤和同步 ---------------------------------------------------------------------------
-- 通过 value_[separateKey_] 在 mapDict_ 中的键值映射，找到分支路径并写入。
function DataCenter:svk(dataPath_,value_,separateKey_,mapDict_)--数据设置路径时，通过Key创建一个分支路径
    self:setValueToPathSeparateByKey(dataPath_,value_,separateKey_,mapDict_)
end
-- 设置到数据路径的时候，根据其中一个键，将数据做分支录入，这个键可以提供一个映射关系(用来指明键的含义)
function DataCenter:setValueToPathSeparateByKey(
    dataPath_, -- 要录入的路径
    value_, -- 要录入的数据
    separateKey_  -- 用那个键来做分支录入
)
    local _extendsPath = value_[separateKey_]
    if _extendsPath == nil then
        dcu:logWarn("setValueToPathSeparateByKey 没有 "..separateKey_.." 键，无法拆分")
        return nil
    end
    local _separatePath = dataPath_.."."..tostring(_extendsPath)
    if dcu.isDebug then
        dcu:logInfo("【SEPARATE】"..dataPath_ .." -> "..tostring(_separatePath))
    end
    return self:setValueToPath(_separatePath,value_)
end
-- 设置数组元素，按照某属性求和
function DataCenter:setListSumSync(listPath_,sumKey_,toPath_)
    local _sumKeyToPathList = self.listSumDict[listPath_]
    if _sumKeyToPathList then
        if dcu_list_indexof(_sumKeyToPathList,sumKey_) ~= nil then
            dcu:logErr(listPath_.." -> "..sumKey_.." 已经存在一个数组求和了")
            return
        end
        _sumKeyToPathList[#_sumKeyToPathList + 1] = {
            sumKey = sumKey_,
            toPath = toPath_,
        }
    else
        _sumKeyToPathList = {}
        _sumKeyToPathList[1] = {
            sumKey = sumKey_,
            toPath = toPath_,
        }
        self.listSumDict[listPath_] = _sumKeyToPathList
    end
end
function DataCenter:clearListSum(listPath_)
    local _sumKeyToPathList = self.listSumDict[listPath_]
    if _sumKeyToPathList then
        local _length =  #_sumKeyToPathList
        for _idx = 1 , _length do
            self:setValueToPath(_sumKeyToPathList[_idx].toPath,0)
        end
    end
end
function DataCenter:listSum(listPath_)
    local _sumKeyToPathList = self.listSumDict[listPath_]
    if _sumKeyToPathList then
        local _length =  #_sumKeyToPathList
        for _idx = 1 , _length do
            self:setValueToPath(
                _sumKeyToPathList[_idx].toPath,
                self:sumDataInListByKey(listPath_,_sumKeyToPathList[_idx].sumKey)
            )
        end
    end
end
-- 数组同步，出现数组的时候，同步到另几个数组上，是增改操作
function DataCenter:setListToListSync(fromListPath_,toListPath_,matchByKey_,convertIngFunc_)
    -- convertIngFunc(id_,itemDict_,dataElement_)
    -- id_ 目标列表中匹配的序号
    -- itemDict_ 目标列表中匹配的元素
    -- dataElement_ 当前正在修改的列表元素
    -- return 目标列表元素，新值，或者修改原有值。如果返回空，代表不做修改
    local _toListPathDict = self.listToListDict[fromListPath_]-- 来源做起点
    if _toListPathDict then
        if _toListPathDict[toListPath_] then
            dcu:logErr(fromListPath_.." -> "..toListPath_.." 已经存在一个数组同步了")
            return
        end
        _toListPathDict[toListPath_] = {
            matchByKey = matchByKey_,
            convertIngFunc = convertIngFunc_
        }
    else
        _toListPathDict = {}
        _toListPathDict[toListPath_] = {
            matchByKey = matchByKey_,
            convertIngFunc = convertIngFunc_
        }
        self.listToListDict[fromListPath_] = _toListPathDict
    end
end
function DataCenter:listToListByElement(arrayPath_,dataElement_) -- 通过当前的元素去另一个列表中找元素
    local _toListPathDict = self.listToListDict[arrayPath_]
    if _toListPathDict then -- 表元素同步
        for _toListPath,_matchInfo in pairs( _toListPathDict ) do
            -- if dcu.isDebug then self.whileTimes = self.whileTimes + 1 end
            local _matchBoo = false
            self:dataListForEach(_toListPath, -- 循环目标列表
                function(id_,itemDict_)
                    local _dataElementValue = dataElement_[_matchInfo.matchByKey] -- 给定键对应的值
                    local _itemDictValue = itemDict_[_matchInfo.matchByKey] -- 给定键对应的值
                    if _dataElementValue ~= nil and _itemDictValue ~= nil and _dataElementValue == _itemDictValue then -- 匹配上就调用转换方法
                        _matchBoo = true -- 有匹配元素
                        local _changedValue = dataElement_
                        if _matchInfo.convertIngFunc then -- 有转换方法执行转换方法
                            _changedValue = _matchInfo.convertIngFunc(id_,itemDict_,dataElement_)
                        end
                        self:setValueToPath(_toListPath.."["..id_.."]",_changedValue) -- 写到同步的那个列表
                        self:listToListByElement(_toListPath,_changedValue) -- 值更新，查看是否还有列表同步
                        self:listToDictByElement(_toListPath,id_,_changedValue) -- 值更新，查看目标列表是否有列表元素属性到字典的映射
                    end
                end
            )
            if _matchBoo == false then -- 没有匹配到的时候，增加元素同步到指定列表。
                local _newValue = dataElement_
                if _matchInfo.convertIngFunc then -- 有转换方法执行转换方法
                    _newValue = _matchInfo.convertIngFunc(nil,nil,dataElement_)
                end
                self:addToList(_toListPath,_newValue) -- 写入同步的那个列表
            end
        end
    end
end
-- 设置列表过滤，将列表按照一定条件过滤到另一个列表中
function DataCenter:setListFilterToListSync(fromListPath_,toListPath_,filterKeyPath_,filterConditionDict_)
    if filterConditionDict_["NONE"] == nil then -- 过滤中不存在 NONE
        filterConditionDict_["NONE"] = {} -- 就添加一个NONE，然后指定成空过滤条件。没有条件，就无法满足条件，所以，过滤出来就是空的。
    end

    local _filterFunc = function(type_) -- 数据变更触发方法，关注的数据路径对应的值
        local _valueOnFilterKeyPath = self:getValueOnPath(filterKeyPath_)
        if _valueOnFilterKeyPath == nil then -- 没有值
            _valueOnFilterKeyPath = "NONE" -- 取默认值，无条件，全过滤掉，一个不要
        end
        if dcu.isDebug then
            dcu:logInfo("【FILTER】"..fromListPath_.." -> "..toListPath_.." : "..tostring(_valueOnFilterKeyPath).." - "..type_)
        end
        self:filterDataPathListToOtherDataPath(fromListPath_,toListPath_,filterConditionDict_[_valueOnFilterKeyPath])
    end

    local _dataConnector = dcu.DataConnector.new( function(_) _filterFunc("FromListLengthChange") end)
    local _fromListPathLengthPath = fromListPath_..".length"
    _dataConnector:resetDataPath(fromListPath_..".length") -- 关注长度，除非是直接修改元素，否则，长度一定会有个 0 -> length 的过程。

    _dataConnector = dcu.DataConnector.new( function(_) _filterFunc("DataPathValueChange") end)
    _dataConnector:resetDataPath(filterKeyPath_) -- 关注那个数据源（修改这值，触发列表过滤）
end
-- 设置列表数据中的元素，其两个指定键对应的值，分别作为键值写入指定的字典路径
function DataCenter:setListToDictSync(fromListPath_,keyForKey_,keyForValue_,toDictPath_)
    -- 路径根据指定key的value做映射后，延展路径后，再写入
    local _listToDictKeyValueList = self.listToDictDict[fromListPath_] 
    if _listToDictKeyValueList then -- 这个路径的延展键值映射
        local _keyValueDict = _listToDictKeyValueList[toDictPath_]
        if _keyValueDict then
            dcu:logErr(fromListPath_.." -> "..toDictPath_.." 已经存在一个属性的键值映射设定了")
            return
        end
        _keyValueDict = {
            keyForKey = keyForKey_,
            keyForValue = keyForValue_,
        }
        self.listToDictDict[toDictPath_] = _keyValueDict
    else
        _listToDictKeyValueList = {}
        _listToDictKeyValueList[toDictPath_] = {
            keyForKey = keyForKey_,
            keyForValue = keyForValue_,
        }
        self.listToDictDict[fromListPath_] = _listToDictKeyValueList
    end
end
-- 列表重新创建的时候，要重新修改制定路径的键值
function DataCenter:listToDictByElement(arrayPath_,id_,dataElement_)
    local _listToDictKeyValueList = self.listToDictDict[arrayPath_]
    if _listToDictKeyValueList then -- 存在映射
        for _toDictPath,_keyValueDict in pairs( _listToDictKeyValueList ) do
            -- if dcu.isDebug then self.whileTimes = self.whileTimes + 1 end
            local _key = dataElement_[_keyValueDict.keyForKey]
            local _value = dataElement_[_keyValueDict.keyForValue]
            local _toPath = _toDictPath..'.'.._key
            if dcu.isDebug then
                dcu:logInfo("【ELE->KY】"..arrayPath_..".["..tostring(id_).."] -> ".._toPath.." = "..tostring(_value))
            end
            self:setValueToPath(_toPath,_value)
        end
    end 
end
-- 清理掉数据映射的键值
function DataCenter:clearListToDict(arrayPath_)
    local _listToDictKeyValueList = self.listToDictDict[arrayPath_]
    if _listToDictKeyValueList then -- 存在映射
        for _toDictPath,_keyValueDict in pairs( _listToDictKeyValueList ) do
            self:dataListForEach(arrayPath_,
                function(id_,itemDict_) -- 清理之前的映射值
                    local _key = itemDict_[_keyValueDict.keyForKey]
                    local _toPath = _toDictPath..'.'.._key
                    if dcu.isDebug then
                        dcu:logInfo("【ELE->KY】"..arrayPath_..".["..tostring(id_).."] -> ".._toPath.." = nil")
                    end
                    self:setValueToPath(_key,nil)
                end
            )
        end
    end
end
-- 设置数据值节点时，当值在给定的字典内有键值匹配，就把值转换成键映射的值
function DataCenter:setRemapValueSync(targetPath_,mapDict_)
    -- 路径根据指定key的value做映射后，延展路径后，再写入
    local _valueRemapDict = self.remapValueDict[targetPath_] 
    if _valueRemapDict then -- 这个路径的延展键值映射
        dcu:logErr(targetPath_.." 已经存在一个值映射了")
        return
    end
    self.remapValueDict[targetPath_] = mapDict_
end
-- 根据映射修改值
function DataCenter:remapValue(dataPath_,value_)
    -- 值在映射表的作用下转换成对应的值
    local _valueRemapDict = self.remapValueDict[dataPath_]
    if _valueRemapDict then -- 映射
        local _newValue = _valueRemapDict[value_]
        if _newValue ~= nil then -- 存在映射就转换，不存在就保持远值
            if dcu.isDebug then
                dcu:logInfo("【REMAP】"..dataPath_ .." : "..tostring(value_).." -> "..tostring(_newValue))
            end
            return _newValue
        else
            return value_
        end
    else
        return value_
    end
end

-- 设置数据节点二次拆解
function DataCenter:setSeparateSync(targetPath_,separateKey_)
    -- 路径根据指定key的value做映射后，延展路径后，再写入
    local _separateKey = self.separateDict[targetPath_] 
    if _separateKey then -- 这个路径的延展键值映射
        dcu:logErr(targetPath_.." 已经存在一个二级路径拆解")
        return
    end
    self.separateDict[targetPath_] = separateKey_
end
-- 设置数据值节点同步
function DataCenter:setValuePathSync(fromPath_,toPath_,convertIngFunc_)
    local _syncPathList = self.valuePathDict[fromPath_]
    if _syncPathList == nil then
        _syncPathList = {}
        _syncPathList[1] = {
            toPath = toPath_, -- 对哪个路径做操作
            convertIngFunc = convertIngFunc_, -- 转换时，使用的方法
        }
        self.valuePathDict[fromPath_] = _syncPathList
    else
        if dcu_list_indexof(_syncPathList,toPath_) ~= nil then -- 存在，代表已经记录过
            return false
        end
        -- 不存在就记录
        _syncPathList[#_syncPathList + 1] =  {
            toPath = toPath_,
            convertIngFunc = convertIngFunc_,
        }
    end
    return true
end
-- 值操作 ---------------------------------------------------------------------------
--简单写，因为经常使用所以写的短一些
function DataCenter:gv(dataPath_)--通过数据路径获取数据
    return self:getValueOnPath(dataPath_)
end
function DataCenter:sv(dataPath_,value_)--给数据路径设置数据
    self:setValueToPath(dataPath_,value_)
end
-- 设置指定ui上的相对路径
function DataCenter:suv(uiNode_,relativePath_,value_)
    self:setValueToUIPath(uiNode_,relativePath_,value_)
end
function DataCenter:setValueToUIPath(uiNode_,relativePath_,value_)--向一个ui节点设置数据，ui节点有自己的数据路径
    if relativePath_ == nil or relativePath_ == "" then
        self:setValueToPath(uiNode_.uiPath,value_)
        if not uiNode_.dataSet then -- 挂载转换过后的数据对象
            uiNode_.dataSet = self:getValueOnPath(uiNode_.uiPath)
        end
    else
        self:setValueToPath(uiNode_.uiPath.."."..relativePath_,value_)
    end
end
-- 获取指定ui上的相对路径
function DataCenter:guv(uiNode_,relativePath_)
    return self:getValueOnUIPath(uiNode_,relativePath_)
end
function DataCenter:getValueOnUIPath(uiNode_,relativePath_)
    if relativePath_ == nil or relativePath_ == "" then
        return self:getValueOnPath(uiNode_.uiPath)
    else
        return self:getValueOnPath(uiNode_.uiPath.."."..relativePath_)
    end
end
--获取路径，转换成数字，没有默认值为0
function DataCenter:gvNumber(dataPath_)
    local _value = self:getValueOnPath(dataPath_)
    if _value == nil then
        return 0
    end
    return _value
end
--获取路径，转换成数字，没有默认值为false
function DataCenter:gvBool(dataPath_)
    local _value = self:getValueOnPath(dataPath_)
    if _value == nil then
        return false
    end
    return _value
end
--获取路径，转换成字符串
function DataCenter:gvString(dataPath_)
    local _value = self:getValueOnPath(dataPath_)
    if _value == nil then
        return "nil"
    end
    local _currentType = dcu_type_getType(_value)
    if 'table' == _currentType then
        return '[DICT]'
    elseif 'list' == _currentType then
        return '[LIST]'
    elseif 'boolean' == _currentType then
        if _value then
            return "True"
        else
            return "False"
        end
    elseif 'function' == _currentType then
        return '[FUNC]'
    else
        return tostring(_value)
    end
end

--清理一个ui节点的数据，子节点都会随之清理
function DataCenter:clearUiPath(uiNode_)
    self:clearDataPath(uiNode_.uiPath)
end
--清理一个节点的数据
function DataCenter:clearDataPath(dataPath_)
    local _dataPathList = {}
    local _savePath = dataPath_
    _dataPathList = dcu_string_split(dataPath_,".")
    local _dataPosition = self.dataSet
    while #_dataPathList > 0 do
        -- if dcu.isDebug then self.whileTimes = self.whileTimes + 1 end
        local _currentKey = dcu_list_shift(_dataPathList)
        if #_dataPathList ~= 0 then
            if not _dataPosition[_currentKey] then
                dcu:logWarn(": ".._currentKey.." in ".._savePath.." is none.")
                return
            else
                _dataPosition = _dataPosition[_currentKey]
            end
        else
            _dataPosition[_currentKey] = nil
        end
    end
end
-- 设置一个路径上的内容是空数组
function DataCenter:setBlankListToPath(arrayPath_)
    self:clearListToDict(arrayPath_) -- 列表元素有映射的话，清理之前的映射
    self:clearListSum(arrayPath_) -- 列表求和变为0
    local _oldListDict = self:getValueOnPath(arrayPath_)
    local _oldLength = nil
    if _oldListDict then
        _oldLength = _oldListDict["length"]
        if _oldListDict["length"] == nil or _oldListDict["[0]"] == nil then
            dcu:logErr(arrayPath_.." 不是数组，清理数组的方式清理它。请确保逻辑正确(确保 [0],length 有值)。")
        end
    else
        _oldLength = "<NIL_MARK>"
    end
    local _blankListDict = {}
    _blankListDict["[0]"] = "<LIST_MARK>"
    _blankListDict["length"] = _oldLength -- 旧长度
    self:setValueToPath(arrayPath_,nil) -- 先清干净
    self:setValueToPath(arrayPath_,_blankListDict)
    self:setValueToPath(arrayPath_..".length",0) -- 分发长度变化
end

--赋值是一个数组的时候，数组会进行格式转换
--    因为lua中并不存在真正意义的数组，没有length属性，且idx序号从1起始，
--    为了统一js和lua在数据模块中的查找方式，和序号索引方式，使用特殊格式的字典来承接数组内容。
--    每一个数据元素可以通过数据 <路径名.[序号]> 的路径，来取得。
--    字典代表数组时，必须有一个键值对 [0] : "<LIST_MARK>"。目的是，当数组零长时，只携带length属性的字典区分开。
function DataCenter:setValueToPath(dataPath_,value_)
    if dcu.isDebug then 
        if string_match(dataPath_,"^dc%.") then
            dcu:logErr(dataPath_ .." 数据路径不能以 dc. 开头，dc.ds 是lua运行时的数据源，数据路径中不包含这个路径")
            return nil
        end
    end

    -- if dcu.isDebug then self.setValueToPathTimes = self.setValueToPathTimes + 1 end
        
    local _dataPathList = {}
    if string_find(dataPath_,'%.') then
        _dataPathList = dcu_string_split(dataPath_,".")
    else
        _dataPathList[1] = dataPath_
    end
    
    local _dataPosition = self.dataSet
    while #_dataPathList > 0 do
        -- if dcu.isDebug then self.whileTimes = self.whileTimes + 1 end
        local _currentKey = dcu_list_shift(_dataPathList)
        if #_dataPathList == 0 then
            local _currentType= dcu_type_getType(value_)
            if value_ == nil then -- 之前，赋值过数组元素的数据路径，就先清理掉之前的
                _dataPosition[_currentKey]=nil
            elseif 'table' == _currentType then
                if not _dataPosition[_currentKey] then
                    _dataPosition[_currentKey] = {}
                end
                self:recursiveDataPath(_dataPosition[_currentKey],value_,dataPath_)
            elseif 'list' == _currentType then
                self:resetArrayOnDataPath(_dataPosition,dcu_string_split(dataPath_,".".._currentKey)[1],_currentKey,value_)
            elseif 'boolean' == _currentType or 'string' == _currentType or 'number' == _currentType then
                local _value = self:remapValue(dataPath_,value_)
                self:recordOldAndNew(dataPath_,_dataPosition[_currentKey],_value)
                _dataPosition[_currentKey] = _value
            else
                dcu:logErr("意外的类型 : ".._currentType..","..dataPath_)
            end
        else
            if not _dataPosition[_currentKey] then
                _dataPosition[_currentKey]={}
            end
            _dataPosition = _dataPosition[_currentKey]
        end
    end
end

-- 记录新旧值
function DataCenter:recordOldAndNew(dataPath_,old_,new_)
    if old_ == nil and new_ == "<LIST_MARK>" then
        -- list.[0] 这样的路径值变更忽略
        return
    end
    -- 新旧值，如果是 nil 的话，要进行一次标示转换。确保新旧都是转换后的值
    local _oldMarkIfNil = old_
    if old_ == nil then
        _oldMarkIfNil = "<NIL_MARK>"
    end
    local _newMarkIfNil = new_
    if new_ == nil then
        _newMarkIfNil = "<NIL_MARK>"
    end
    local _tempInfo = self.justChangeInfoDict[dataPath_]
    if _tempInfo then
        local _valueLength = #_tempInfo.valueList -- 
        if _newMarkIfNil ~= _tempInfo.valueList[_valueLength] then -- 最后一次变化的值不相同
            _tempInfo.valueList[_valueLength + 1] = _newMarkIfNil -- 记录新值
        end
    else
        if _oldMarkIfNil ~= _newMarkIfNil then -- 转换后的值不相等
            self.justChangeInfoDict[dataPath_] = { -- 创建这个之变化的记录对象
                dataPath = dataPath_,
                valueList = {_oldMarkIfNil,_newMarkIfNil},
            }
        end
    end
end

--遍历字段，提醒数据路径的监听者改变数据
function DataCenter:recursiveDataPath(dataOnParentPath_,valueDict_,dataPath_)
    -- 路径根据指定key的value做映射后，延展路径后，再写入
    local _separateKey = self.separateDict[dataPath_] 
    if _separateKey then -- 这个路径的延展键值映射
        valueDict_[_separateKey] = self:remapValue(dataPath_..".".._separateKey,valueDict_[_separateKey]) -- 根据值节点映射修改值
        self:setValueToPathSeparateByKey(dataPath_,valueDict_,_separateKey)
        return nil -- 延展写入，后续就不在做处理了
    end

    for _key,_value in pairs( valueDict_ ) do
        -- if dcu.isDebug then self.whileTimes = self.whileTimes + 1 end
        _key = tostring(_key)
        local _currentPath = ""
        if dataPath_=="" then
            _currentPath = _key
        else
            _currentPath = dataPath_..".".._key
        end
        local _currentType = dcu_type_getType(_value)
        if 'table' == _currentType then
            if not dataOnParentPath_[_key] then
                dataOnParentPath_[_key]={}
            end
            self:recursiveDataPath(dataOnParentPath_[_key],valueDict_[_key],_currentPath)
        elseif 'list' == _currentType then
            self:resetArrayOnDataPath(dataOnParentPath_,dataPath_,_key,_value)
        elseif 'function' == _currentType then
            -- function 什么都不做
        else -- 其他都是直接赋值
            _value = self:remapValue(_currentPath,_value)
            self:recordOldAndNew(_currentPath,dataOnParentPath_[_key],_value)
            dataOnParentPath_[_key] = _value
        end
    end
end

--递归设置数据
function DataCenter:resetArrayOnDataPath(dataOnCurrentDataPath_,dataPath_,lastKey_,arrayValue_)
    local _arrayPath = dataPath_.."."..lastKey_
    self:setBlankListToPath(_arrayPath) -- 先设置成空数组
    local _arrayLengthPath = _arrayPath..".length"
    local _length =  #arrayValue_
    for _id = 1 , _length do -- 数组的每一个元素，进行递归处理
        -- if dcu.isDebug then self.whileTimes = self.whileTimes + 1 end
        local _elementPath =_arrayPath..".["..(_id).."]"
        local _dataElement = arrayValue_[_id]
        self:setValueToPath(_elementPath,_dataElement)
        self:listToDictByElement(_arrayPath,_id,_dataElement) -- 通过元素映射到字典上
        self:listToListByElement(_arrayPath,_dataElement) -- 通过元素同步列表 -- 可能会修改另一个列表的长度
    end
    self:setValueToPath(_arrayLengthPath,_length) -- 设置长度
    self:listSum(_arrayPath)-- 重新求和
end

-- 在数组中通过键值匹配找到一个元素，然后在元素上通过键取得另一个值。
function DataCenter:getDictMatchInListThenGetVaueByKey(dataListPath_,targetKey_,matchValue_,queryKey_)
    local _dataOnPath = self:getDictMatchInList(dataListPath_,targetKey_,matchValue_)
    if not _dataOnPath[queryKey_] then
        dcu:logWarn("WARING : "..dataListPath_.." 类表中，元素的键 "..targetKey_.."=="..matchValue_.." 的元素 "..queryKey_.." 键没有对应任何值")
        return nil
    end
    return _dataOnPath[queryKey_]
end
--将列表内的元素的某一个键对应的值进行累加
function DataCenter:sumDataInListByKey(listDataPath_,sumKey_)
    local _dataOnPath = self:getValueOnPath(listDataPath_)
    if _dataOnPath == nil then
        dcu:logWarn("WARING : sumDataInListByKey "..listDataPath_.." 没有值")
        return nil
    end
    if not dcu_isConvertedList(_dataOnPath) then
        dcu:logWarn("WARING : sumDataInListByKey "..listDataPath_.." 不是数组")
        return nil
    end
    local _id = 1
    local _tempKey = "[1]"
    local _sumValue = 0
    while(_dataOnPath[_tempKey]) do
        _sumValue = _sumValue + _dataOnPath[_tempKey][sumKey_]
        _id = _id + 1
        _tempKey = "["..tostring(_id).."]"
    end
    return _sumValue
end
--将一个数组，通过给定两个键值，转换成键值对的平表结构(例如 道具类 id:num)。
function DataCenter:mapListToKeyValueDict(dataListPath_,keyAsKey_,keyAsValue_)
    local _dataList = self:getValueOnPath(dataListPath_)
    if _dataList == nil then
        return nil
    end
    if not dcu_isConvertedList(_dataList) then
        dcu:logWarn("WARING : getDictMatchInList "..dataListPath_.." 不是数组")
        return nil
    end
    local _keyValueDict = {}
    self:dataListForEach(dataListPath_,
        function(id_,itemDict_)
            _keyValueDict[tostring(itemDict_[keyAsKey_])] = itemDict_[keyAsValue_]
        end
    )
    return _keyValueDict
end
--获取列表中键 targetKey_ 对应的值 等于 matchValue_ 的数组序位 id
function DataCenter:getIdsMatchInList(dataListPath_,targetKey_,matchValue_)
    local _dataList = self:getValueOnPath(dataListPath_)
    if _dataList == nil then
        dcu:logWarn("WARING : getIdsMatchInList "..dataListPath_.." 不存在")
        return nil
    end
    if not dcu_isConvertedList(_dataList) then
        dcu:logWarn("WARING : getIdsMatchInList "..dataListPath_.." 不是数组")
        return nil
    end
    local _ids = {}
    local _forEachCount = 0
    self:dataListForEach(dataListPath_,
        function(id_,itemDict_)
            if itemDict_[targetKey_] == matchValue_ then
                _forEachCount = _forEachCount + 1
                _ids[_forEachCount] = id_
            end
        end
    )
    return _ids
end
function DataCenter:getIdMatchInList(dataListPath_,targetKey_,matchValue_)
    local _ids = self:getIdsMatchInList(dataListPath_,targetKey_,matchValue_)
    if _ids == nil then
        dcu:logWarn("getIdMatchInList "..dataListPath_.." 列表中没有 "..targetKey_.." 键的值等于 "..matchValue_.." 的元素")
        return nil
    end
    if #_ids > 1 then
        dcu:logWarn("getIdMatchInList "..dataListPath_.." 列表中 "..targetKey_.." 键的值等于 "..matchValue_.." 的不止一个")
    end
    return _ids[1]--返回第一个
end
--获取列表中键 targetKey_ 对应的值 等于 matchValue_ 的元素
function DataCenter:getDictMatchInList(dataListPath_,targetKey_,matchValue_)
    local _id = self:getIdMatchInList(dataListPath_,targetKey_,matchValue_)
    if _id then
        local _dataList = self:getValueOnPath(dataListPath_)
        return _dataList["["..tostring(_id).."]"]
    end
    return nil
end
--[[
    根据条件过滤列表并赋值给另一个数据源
    [键，比较条件，值]
    [键，比较条件，值1，值2]
]]
function DataCenter:filterDataPathListToOtherDataPath(sourceDataPath_,targetDataPath_,conditions_)
    self:setBlankListToPath(targetDataPath_) -- 先设置成空数组，然后在过滤
    local _copyArrFunc = function (arr_)
        local _copyArr = {}
        local _length =  #arr_ -- 有移除操作的不要用这个写法
        local _loopCount = 0
        for _idx = 1 , _length do
            _loopCount = _loopCount + 1
            _copyArr[_loopCount] = arr_[_idx]
        end
        return _copyArr
    end
    local _itemList = {} -- 过滤出来的列表
    self:dataListForEach(sourceDataPath_,
        function(id_,itemDict_)
            local _filterBool = false
            local _length =  #conditions_ -- 有移除操作的不要用这个写法
            if _length > 0 then
                for _idx = 1 , _length do
                    local _condition = conditions_[_idx]
                    local _compareArr = _copyArrFunc(_condition) -- 复制出一个数组
                    _compareArr[1] = itemDict_[_compareArr[1]] -- 第一个更换成值
                    local _compare_result = self:dataCompare(_compareArr) -- 得出比较结果
                    if _compare_result == nil then
                        dcu:logWarn("filterDataPathListToList 比较结果为空。可能是数字比较出现文字或其他")
                        return nil
                    end
                    if _compare_result == 0 then -- 条件没有成立
                        _filterBool = true -- 过滤掉
                        break
                    end
                end
            else
                _filterBool = true -- 没有条件，就过滤。
            end
            if _filterBool == false then -- 没有过滤掉
                _itemList[#_itemList + 1] = itemDict_ -- 记录下来
            end
        end
    )
    if #_itemList > 0 then
        self:setValueToPath(targetDataPath_,_itemList) -- 设置给数据路径
    end
end

--将数组字典变换成数组
function DataCenter:backToNormalList(jsonDict_)
    if dcu_isConvertedList(jsonDict_) then
        local _backJsonList = {}
        local _idx = 0
        local _length = jsonDict_["length"]
        local _loopCount = 0
        while (_idx < _length) do
            _loopCount = _loopCount + 1
            _backJsonList[_loopCount] = jsonDict_["["..tostring(_loopCount).."]"]
            _idx = _idx + 1
        end
        return _backJsonList
    else
        return nil
    end
end
--遍历转换获得一个正常的字典对象，用来转换回json
function DataCenter:backToNormalJsonDict(jsonDict_)
    if dcu_isConvertedList(jsonDict_) then
        return self:backToNormalList(jsonDict_)
    end
    local _backJsonDict = {}
    for _tempKey,_tempValue in pairs( jsonDict_ ) do
        local _currentType = dcu_type_getType(_tempValue)
        if 'table' == _currentType then
            if dcu_isConvertedList(_tempValue) then
                _backJsonDict[_tempKey] = self:backToNormalList(_tempValue)
            else
                _backJsonDict[_tempKey] = self:backToNormalJsonDict(_tempValue)
            end
        else
            _backJsonDict[_tempKey] = _tempValue
        end
    end
    return _backJsonDict
end
--删除一个指定 index 对应的元素
function DataCenter:removeFromListByIdx(listDataPath_,id_)
    self:removeFromListById(listDataPath_,id_ + 1)
end
--删除一个指定 id(index + 1) 对应的元素
function DataCenter:removeFromListById(listDataPath_,id_)
    local _dataOnPath = self:getValueOnPath(listDataPath_)
    if not dcu_isConvertedList(_dataOnPath) then
        dcu:logWarn("WARING : sumDataInListByKey "..listDataPath_.." 不是数组")
        return
    end
    local _id = id_
    local _currentIdKey = "["..tostring(_id).."]"
    if not _dataOnPath[_currentIdKey] then
        dcu:logWarn("WARING : sumDataInListByKey "..listDataPath_.." 中，第 ".._currentIdKey.." 个元素不存在。")
        return
    end
    local _nextIdKey = "["..tostring(_id + 1).."]"
    while(_dataOnPath[_nextIdKey]) do
        _dataOnPath[_currentIdKey] = _dataOnPath[_nextIdKey] -- 往前移
        _id = _id + 1
        _currentIdKey = "["..tostring(_id).."]"
        _nextIdKey = "["..tostring(_id + 1).."]"
    end
    _dataOnPath["length"] = _dataOnPath["length"] - 1
    _dataOnPath[_currentIdKey] = nil -- _currentIdKey 当前值是删除者(删除最后一个时)，或者是移动的最后一个(往前移的最后一个)
    self.dataEventMgr:onDataChange(listDataPath_..".length") -- 数组长变化
end
--添加一个元素
function DataCenter:addToList(dataListPath_,value_)
    local _dataList = self:getValueOnPath(dataListPath_)
    if _dataList == nil then -- 不存在。
        self:setBlankListToPath(dataListPath_) -- 添加一个空数组
        _dataList = self:getValueOnPath(dataListPath_) -- 现在有数组了
    end
    if not dcu_isConvertedList(_dataList) then
        dcu:logWarn("WARING : addToList "..dataListPath_.." 不是数组")
        return
    end
    local _nextLength = _dataList["length"] + 1
    local _currentPath = dataListPath_..".["..tostring(_nextLength).."]"
    self:setValueToPath(_currentPath,value_)
    self:setValueToPath(dataListPath_..".length",_nextLength)
    self:listToListByElement(dataListPath_,value_) -- 值更新，查看是否还有列表同步
    self:listToDictByElement(dataListPath_,_nextLength,value_) -- 值增加，查看目标列表是否有列表元素属性到字典的映射
end
--数组中的每一个元素进行操作
function DataCenter:dataListForEach(dataListPath_,operationFunc_)
    local _dataList = self:getValueOnPath(dataListPath_)
    if _dataList == nil then
        return 
    end
    if not dcu_isConvertedList(_dataList) then
        dcu:logWarn("WARING : dataListForEach "..dataListPath_.." 不是数组")
        return
    end
    if _dataList then -- 原来有数据
        local _id = 1
        local _tempKey = "[1]"
        while(_dataList[_tempKey]) do
            -- if dcu.isDebug then self.whileTimes = self.whileTimes + 1 end
            operationFunc_(_id,_dataList[_tempKey])
            _id = _id + 1
            _tempKey = "["..tostring(_id).."]"
        end
    end
end
--获取路径数据
function DataCenter:getValueOnPath(dataPath_)
    if string_match(dataPath_,"^dc%.") then
        dcu:logErr(dataPath_ .." 数据路径不能以 dc. 开头，dc.ds 是lua运行时的数据源，数据路径中不包含这个路径")
        return
    end

    local _justChangeInfo = self.justChangeInfoDict[dataPath_]
    if _justChangeInfo ~= nil then
        local _value = _justChangeInfo.valueList[#_justChangeInfo.valueList]
        if _value == "<NIL_MARK>" then
            return nil
        end
        return _value
    end

    local _dataPathList={}
    if string_find(dataPath_,'%.') then
        _dataPathList = dcu_string_split(dataPath_,".")
    else
        _dataPathList[1] = dataPath_
    end
    local _dataPosition = self.dataSet
    while #_dataPathList>0 do
        local _currentKey = dcu_list_shift(_dataPathList)
        if not _dataPosition then
            return nil
        end
        _dataPosition = _dataPosition[_currentKey]
    end
    if _dataPosition == "<NIL_MARK>" then
        return nil
    end
    return _dataPosition
end
-- 当做 json 打印
function DataCenter:printAsJsonString()
    dcu:logInfo(self:toJsonString())
end
-- 转换成 json 字符串
function DataCenter:toJsonString()
    local _dict = self:backToNormalJsonDict(self.dataSet);
    return json.encode(_dict)
end
-- 打印现有路径键值对
function DataCenter:printSelfAsKeyValueDict(desc_)
    self:printDataPathAsKeyValueDict(nil,desc_)
end
-- 打印指定路径上有什么东西
function DataCenter:printDataPathAsKeyValueDict(dataPath_,desc_)
    local _desc = desc_ or ""
    _desc = _desc .. "  "
    local _pathAndValueList = self:getPathAndValueList(dataPath_)
    local _dataPath = dataPath_
    if _dataPath == nil then
        _dataPath = _desc .. "<Root>"
    end
    local _printLogStr = _desc .. " - SHOW DATA ON - ".._dataPath
    local _length =  #_pathAndValueList -- 有移除操作的不要用这个写法
    for _idx = 1 , _length do
        _printLogStr = _printLogStr .. "\n" .. _pathAndValueList[_idx]
    end
    dcu:logInfo(_printLogStr)
end
-- 数据路径键值对
function DataCenter:getPathAndValueList(dataPath_)
    local _keyValueDict = {}
    local _dataOnPath = self.dataSet
    if dataPath_ ~= nil then
        _dataOnPath = self:getValueOnPath(dataPath_)
    end
    self:convertToKeyValueDict(nil,_dataOnPath,_keyValueDict)
    local _keyList = dcu_table_keys(_keyValueDict,true)
    local _keyValueList = {}
    local _loopCount = 0
    for _,_key in pairs( _keyList ) do
        _loopCount = _loopCount + 1
        _keyValueList[_loopCount] = _key .. " : " .. tostring(_keyValueDict[_key])
    end
    return _keyValueList
end
--转换 路径:值 键值对
function DataCenter:convertToKeyValueDict(parentPath_,dataOnParentPath_,keyValueDict_)
    for _key,_value in pairs( dataOnParentPath_ ) do
        local _currentPath 
        if parentPath_ == nil then
            _currentPath = _key
        else
            _currentPath = parentPath_..".".._key
        end
        local _currentType = dcu_type_getType(_value)
        if 'table' == _currentType then
            self:convertToKeyValueDict(_currentPath,dataOnParentPath_[_key],keyValueDict_)
        else
            keyValueDict_[_currentPath] = _value
        end
    end
end
-- 确保字典是数组转换后的样式
function DataCenter:table_makeSureList(dict_)
    if #dcu_table_keys(dict_) == 0 then
        dict_["[0]"] = "<LIST_MARK>"
        dict_["length"] = 0   
    end
end

--模式，值，比较方式------------------------------------------------------------------------
function DataCenter:dataCompare(paramsArray_)
    local _targetValue = paramsArray_[1]
    local _mode = paramsArray_[2]
    local _value1 = paramsArray_[3]
    local _value2 = paramsArray_[4]
    local _backValue=nil
    if _mode == "()" then--x< n <y
        if dcu_isNotNaN(_targetValue,_value1,_value2) then
            if tonumber(_value1) < tonumber(_targetValue) and  tonumber(_targetValue) < tonumber(_value2) then
             	_backValue = 1 
            else
            	_backValue = 0
           	end
        end
    elseif _mode == "(]" then--x< n <=y
        if dcu_isNotNaN(_targetValue,_value1,_value2) then
            if tonumber(_value1) < tonumber(_targetValue) and tonumber(_targetValue) <= tonumber(_value2) then
             	_backValue = 1 
            else
            	_backValue = 0
           	end
        end
    elseif _mode == "[)" then--x<= n <y
        if dcu_isNotNaN(_targetValue,_value1,_value2) then
            if tonumber(_value1) <= tonumber(_targetValue) and tonumber(_targetValue) < tonumber(_value2) then
             	_backValue = 1 
            else
            	_backValue = 0
           	end
        end
    elseif _mode == "[]" then--x<= n <=y
        if dcu_isNotNaN(_targetValue,_value1,_value2) then
            if tonumber(_value1) <= tonumber(_targetValue) and tonumber(_targetValue) <= tonumber(_value2) then
             	_backValue = 1 
            else
            	_backValue = 0
           	end
        end
    elseif _mode == ">=" then
        if dcu_isNotNaN(_targetValue,_value1) then
            if tonumber(_targetValue) >= tonumber(_value1) then
             	_backValue = 1 
            else
            	_backValue = 0
           	end
        end
    elseif _mode == "<=" then
        if dcu_isNotNaN(_targetValue,_value1) then
            if tonumber(_targetValue) <= tonumber(_value1) then
             	_backValue = 1 
            else
            	_backValue = 0
           	end
        end
    elseif _mode == ">" then
        if dcu_isNotNaN(_targetValue,_value1) then
            if tonumber(_targetValue) > tonumber(_value1) then
             	_backValue = 1 
            else
            	_backValue = 0
           	end
        end
    elseif _mode == "<" then
        if dcu_isNotNaN(_targetValue,_value1) then
            if tonumber(_targetValue) < tonumber(_value1) then
             	_backValue = 1 
            else
            	_backValue = 0
           	end
        end
    elseif _mode == "==" then--
    	if tostring(_targetValue) == tostring(_value1) then
         	_backValue = 1 
        else
        	_backValue = 0
       	end
    elseif _mode == "!=" then--
    	if tostring(_targetValue) ~= tostring(_value1) then
         	_backValue = 1 
        else
        	_backValue = 0
       	end
    else
        dcu:logErr("不存在比较模式 : "..tostring(_mode))
    end
    return _backValue
end

--字典构成的列表，按照键值匹配，查找到对象并返回
function DataCenter:getMatchItemsMatchInDictList(dictList_,conditions_)
    local _matchList = {} -- 满足条件的字典列表
    local _length =  #dictList_ -- 循环列表
    for _idx = 1 , _length do
        local _dict = dictList_[_idx] -- 列表元素
        local _lengthInside =  #conditions_ -- 循环条件
        for _idxInside = 1 , _lengthInside do
            local _condition = conditions_[_idxInside] -- 条件键值对
            if _dict[_condition[1]] == _condition[2]then -- 列表元素的【条件键】指定的值 等于 【条件值】
                _matchList[#_matchList + 1] = _dict
            end
        end
    end
    if #_matchList > 0 then
        return _matchList
    else
        return nil
    end
end
-------------------------------------------------------------------------------------------------------
return DataCenter