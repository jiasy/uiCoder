[<File_doc|ui|/src/app/base/util/tableUtils.lua|replace>]
--utils for array
local tableUtilsInstance = class("tableUtilsInstance")

function tableUtilsInstance:copy(table_)
	local _back={}
	for _key, _value in pairs(table_) do _back[_key] = _value end
	return setmetatable(_back, getmetatable(table_))
end

function tableUtilsInstance:deepCopy(table_)
	local function _deepCopy(from_ ,to_)
		for _key, _value in pairs(from_)   do
			if type(_value) ~= "table" then
				to_[_key] = _value
			else
				to_[_key] = {}
				_deepCopy(_value,to_[_key])
			end
		end
		return setmetatable(from_, getmetatable(to_))
	end
	local _back = {}
	_deepCopy(table_,_back)
	return _back
end

function tableUtilsInstance:findKeyByValue(table_,value_)
	for _key,_value in pairs(table_) do
		if _value==value_ then
			return _key
		end
	end
	return false
end

function tableUtilsInstance:isEmpty(table_)
	for _key,_value in pairs(table_) do
		return false
	end
	return true
end

cc.exports.tableUtils={}
function tableUtils:getInstance()
    if self.instance == nil then
        self.instance = tableUtilsInstance:new()
    end
    return self.instance
end