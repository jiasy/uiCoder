[<File_doc|ui|/src/app/base/util/arrayUtils.lua|replace>]
--utils for array
local arrayUtilsInstance = class("arrayUtilsInstance")

function arrayUtilsInstance:removeElement(array_,element_)
	for i,v in ipairs(array_) do
		if element_== v then
			return table.remove(array_,i)
		end
	end
	return nil
end

function arrayUtilsInstance:isValueExist(table_,value_)
	for _key,_value in ipairs(table_) do
		if _value==value_ then return true end
	end
	return false
end

--清理数组
function arrayUtilsInstance:clearArray(arr_)
	if arr_==nil then return end
	while #arr_>0 do
		table.remove(arr_,1)
	end
end

cc.exports.arrayUtils={}
function arrayUtils:getInstance()
    if self.instance == nil then
        self.instance = arrayUtilsInstance:new()
    end
    return self.instance
end