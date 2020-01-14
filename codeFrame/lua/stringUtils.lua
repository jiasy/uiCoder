[<File_doc|ui|/src/app/base/util/stringUtils.lua|replace>]
--Utils for string
local stringUtilsInstance = class("stringUtilsInstance")
--Split string1
function stringUtilsInstance:splitByStr(szFullString_, szSeparator_)
    if szSeparator_==nil or type(szSeparator_) ~= "string" or string.len(szSeparator_) <= 0 then
        return nil
    end
    local start = 1
    local _nSplitArray = {}
    while true do
        local pos = string.find (szFullString_, szSeparator_, start, true)
        if not pos then
          break
        end
        table.insert (_nSplitArray, string.sub (szFullString_, start, pos - 1))
        start = pos + string.len (szSeparator_)
    end
    table.insert (_nSplitArray, string.sub (szFullString_, start))
    return _nSplitArray
end
--Split string2
function stringUtilsInstance:split(str_, delimiter_)
    str_ = tostring(str_)
    delimiter_ = tostring(delimiter_)
    
    if (delimiter_=='') then 
      return nil 
    end

    local pos,arr = 0, {}
    for st,sp in function() return string.find(str_, delimiter_, pos, true) end do
        table.insert(arr, string.sub(str_, pos, st - 1))
        pos = sp + 1
    end
    table.insert(arr, string.sub(str_, pos))
    return arr
end
--Get sub string
function stringUtilsInstance:subStr(str_,beginIndex_,length_)
	local _backStr
    _backStr=string.sub(str_,beginIndex_,beginIndex_+length_-1)
    return _backStr
end
--Join string
function stringUtilsInstance:joinStrByVector(strVector_,joinStr_)
    local _backStr=""
    local _tempLength=#strVector_
    for i=1,#_tempLength do
        _backStr=_backStr+strVector_[i]
        if i~= _tempLength then
            _backStr=_backStr+joinStr_
        end
    end
    return _backStr
end
--Check numbrt
function stringUtilsInstance:isNumber(str_)
	local _type = type(str_);
	if _type == "number" then
		return true
	end
	return false
end
--Change string to number
function stringUtilsInstance:strToNum(str_)
	local _num = tonumber(str_);
	if _num then
		return _num
	end
	return nil
end
function string.ltrim(input)
    return string.gsub(input, "^[ \t\n\r]+", "")
end
function string.rtrim(input)
    return string.gsub(input, "[ \t\n\r]+$", "")
end
function string.trim(input)
    input = string.gsub(input, "^[ \t\n\r]+", "")
    return string.gsub(input, "[ \t\n\r]+$", "")
end

cc.exports.stringUtils={}
function stringUtils:getInstance()
    if self.instance == nil then
        self.instance = stringUtilsInstance:new()
    end
    return self.instance
end