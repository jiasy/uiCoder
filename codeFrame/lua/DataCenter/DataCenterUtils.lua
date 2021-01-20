local string_sub = string.sub
local string_find = string.find
local string_match = string.match
local string_gmatch = string.gmatch
local table_sort = table.sort
local table_remove = table.remove

-- 引擎类型。根据引擎指定来选择执行代码。这样代码可以在不同环境中运行
ENV_ENGINE_NONE = 0
ENV_ENGINE_OPENRESTY = 1
ENV_ENGINE_UNITY_TOLUA_FGUI = 2
ENV_ENGINE_UNITY_TOLUA_UGUI = 3
ENV_ENGINE_COCOS_BUILDER = 4
ENV_ENGINE_COCOS_STUDIO = 5


BIND_TYPE_NONE = 0
BIND_TYPE_PURE_PATH = 1
BIND_TYPE_DATA_STRING = 2

function dcu_class(classname, super)
    local superType = type(super)  
    local cls
    if superType ~= "function" and superType ~= "table" then  
        superType = nil  
        super = nil  
    end  
    if superType == "function" or (super and super.__ctype == 1) then  
        cls = {} -- inherited from native C++ Object  
        if superType == "table" then  
            for k,v in pairs(super) do -- copy fields from super  
                cls[k] = v 
            end  
            cls.__create = super.__create  
            cls.super    = super
        else  
            cls.__create = super
            cls.ctor = function() end  
        end  

        cls.__cname = classname  
        cls.__ctype = 1  

        function cls.new(...)  
            local instance = cls.__create(...)  
            for k,v in pairs(cls) do -- copy fields from class to native object  
                instance[k] = v 
            end
            instance.class = cls  
            instance:ctor(...)  
            return instance  
        end
    else
        if super then -- inherited from Lua Object  
            cls = {}  
            setmetatable(cls, {__index = super})  
            cls.super = super  
        else  
            cls = {ctor = function() end}  
        end  
        cls.__cname = classname  
        cls.__ctype = 2
        cls.__index = cls  
        function cls.new(...)  
            local instance = setmetatable({}, cls)  
            instance.class = cls  
            instance:ctor(...)
            return instance  
        end  
    end
    return cls  
end

function dcu_string_split(str_, delimiter_)
    local _str = tostring(str_)
    local _delimiter = tostring(delimiter_)
    if _delimiter=='' then 
        return false 
    end
    local _pos,_arr = 0, {}
    for st,sp in -- for each divider found
        function()
            return string_find(_str, _delimiter, _pos, true) 
        end 
    do
        _arr[#_arr + 1] = string_sub(_str, _pos, st - 1)
        _pos = sp + 1
    end
    _arr[#_arr + 1] = string_sub(_str, _pos)
    return _arr
end

function dcu_list_indexof(list_,value_,beginIdx_)
    local _length = #list_
    for _idx = beginIdx_ or 1, _length do
        if list_[_idx] == value_ then 
            return _idx 
        end
    end
    return nil
end

function dcu_table_keys(table_,sort_,ascending_)
    function list_sort_inside(list_)
        if ascending_ == nil or ascending_ == true then
            table_sort(list_)
        else -- 倒叙排列
            table_sort(list_,function(current_,next_) 
                return current_ > next_ 
            end)
        end
        return list_
    end
    local _keyList = {}
    local _loopCount = 0
    for _key, _value in pairs(table_) do
        _loopCount = _loopCount + 1
        _keyList[_loopCount] = _key
    end
    if sort_ then
        list_sort_inside(_keyList)
    end
    return _keyList
end

-- UI 中关联一个属性的时候， 按照 ‘{属性}比较字符串’ 这样的格式指定。所以，第一个字符一定是{
function dcu_isUICompareStyle(dataStr_)
    if string_match(dataStr_,"^{") then
        return true
    else
        return false
    end
end
--[[
    数据比较关系和属性的关联
    {属性}数据路径 比较符号 值1,值2
]]
function dcu_splitUICompare(initDataStr_)
    local _initDataSplitArr = dcu_string_split(initDataStr_,"{")
    local _compareDict = {}
    local _length =  #_initDataSplitArr -- 有移除操作的不要用这个写法
    for _idx = 1 , _length do
        local _propertyAndCompare = dcu_string_split(_initDataSplitArr[_idx],"}")
        _compareDict[_propertyAndCompare[1]]=_propertyAndCompare[2]
    end
    return _compareDict
end

function dcu_list_shift(list_)
    return table_remove(list_ , 1)
end

function dcu_isConvertedList(jsonDict_)
    if jsonDict_["[0]"]=="<LIST_MARK>" then
        return true
    end
    return false
end

--判断是不是一个列表
function dcu_list_checkIsList(table_)
    if type(table_) ~= "table" then
        return false
    end
    if #dcu_table_keys(table_) == 0 then
        return false
    end
    local _length = #table_
    for _id,_ in pairs(table_) do
        if type(_id) ~= "number" then
            return false
        end
        if _id > _length then
            return false
        end
    end
    return true
end
--获取类型
function dcu_type_getType(value_)
    local _type =type(value_)
    if _type == "table" then
        if dcu_list_checkIsList(value_) then
            return "list"
        end
    end
    return _type
end
-- 非数字
function dcu_isNotNaN(valueC1_,valueC2_,valueC3_)
    valueC1_ = tonumber(valueC1_)
    valueC2_ = tonumber(valueC2_)
    valueC3_ = valueC3_ or nil
    local _value3Number = false
    if valueC3_ then
        valueC3_ = tonumber(valueC3_)
        if valueC3_ then
            _value3Number = true
        end
    end
    if  valueC1_ and valueC2_ then
        if valueC3_ and _value3Number==false then
            return false
        end
        return true
    else
        if valueC3_ then
            dcu:logErr("进行比较的数值，非数字类型无法比较 ".._mode.." : "..valueC1_..","..valueC2_..","..valueC3_)
        else
            dcu:logErr("进行比较的数值，非数字类型无法比较 ".._mode.." : "..valueC1_..","..valueC2_)
        end
        return false
    end
end


-- 分离变量
function dcu_splitDataStr(dataString_)
	local _dataPathListenerList = nil
    local _otherStringList = nil
    if dataString_ and string_find(dataString_,'${') then -- 字符串可拆分，就监听拆分出来的数据路径
        _dataPathListenerList = {}
        _otherStringList = {}
		local _dataPathListSplit = dcu_string_split(dataString_,"${")
		_otherStringList[#_otherStringList + 1] = _dataPathListSplit[1]
		local _length =  #_dataPathListSplit 
	    for _idx = 2 , _length do
			local _string_item=_dataPathListSplit[_idx]
			local _string_list= dcu_string_split(_string_item,"}")
			_dataPathListenerList[#_dataPathListenerList + 1] = _string_list[1]
			_otherStringList[#_otherStringList + 1] = _string_list[2]
		end
	end
	return _dataPathListenerList,_otherStringList
end
------------------------------------------------------------------------------------------------------------------------
local DataCenterUtils = dcu_class("DataCenterUtils")
function DataCenterUtils:ctor()
    _G.dcu = self
end

function DataCenterUtils:init(
    engineAndUIFrameWork_, -- 引擎
    requirePath_, -- 当前工程中的引用路径
    isDebug_ -- 是否需要Debug输出
)
    -- 指明使用的引擎和UI类库
    self.engineAndUIFrameWork = engineAndUIFrameWork_
    self.requirePathPrefix = requirePath_
    -- 纯数据路径缓存，判断一个路径是否是一个数据路径，由字母数字下划线构成的。判断的方法比较笨，通过缓存减少开销
    self.pureDataPathCache = {}
    self.DataBase          = require(self.requirePathPrefix.."DataBase")
    self.DataConnector     = require(self.requirePathPrefix.."DataConnector")
    self.DataCompare       = require(self.requirePathPrefix.."DataCompare")
    self.DataCenter        = require(self.requirePathPrefix.."DataCenter")
    self.DataListConnector = require(self.requirePathPrefix.."DataListConnector")
    self.DataEventMgr      = require(self.requirePathPrefix.."DataEventMgr")
    self.isDebug = isDebug_
end

function DataCenterUtils:logErr(str_)
    if self.engineAndUIFrameWork == ENV_ENGINE_NONE then
        print("ERR : "..str_)
    elseif self.engineAndUIFrameWork == ENV_ENGINE_OPENRESTY then
        ngx.log(ngx.ERR,"ERR : "..str_) -- nginx Log
    elseif self.engineAndUIFrameWork == ENV_ENGINE_UNITY_TOLUA_FGUI or self.engineAndUIFrameWork == ENV_ENGINE_UNITY_TOLUA_UGUI  then
        Util.LogError(str_) -- tolua Log
    end
end

function DataCenterUtils:logWarn(str_)
    if self.engineAndUIFrameWork == ENV_ENGINE_NONE then
        print("WARN : "..str_)
    elseif self.engineAndUIFrameWork == ENV_ENGINE_OPENRESTY then
        ngx.log(ngx.WARN,"WARN : "..str_) -- nginx Log
    elseif self.engineAndUIFrameWork == ENV_ENGINE_UNITY_TOLUA_FGUI or self.engineAndUIFrameWork == ENV_ENGINE_UNITY_TOLUA_UGUI  then
        Util.LogWarning(str_) -- tolua Log
    end
end

function DataCenterUtils:logInfo(str_)
    if self.engineAndUIFrameWork == ENV_ENGINE_NONE then
        print(str_)
    elseif self.engineAndUIFrameWork == ENV_ENGINE_OPENRESTY then
        ngx.log(ngx.INFO,str_) -- nginx Log
    elseif self.engineAndUIFrameWork == ENV_ENGINE_UNITY_TOLUA_FGUI or self.engineAndUIFrameWork == ENV_ENGINE_UNITY_TOLUA_UGUI  then
        Util.Log(str_) -- tolua Log
    end
end

-- 纯数据路径，没有拼接
function DataCenterUtils:isPureDataPath(str_)
    if dcu_list_indexof(self.pureDataPathCache,str_) ~= nil then -- 存在，代表已经记录过
        return true
    end
	local _countInput = #str_
	local _count = 0
	for _char in string_gmatch(str_,'[%w_%.]') do
		_count = _count + 1
	end
    if _countInput == _count then
        self.pureDataPathCache[#self.pureDataPathCache + 1] = str_
		return true
	else
		return false
	end
end

return DataCenterUtils