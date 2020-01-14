[<File_doc|ui|/src/app/base/util/languageUtils.lua|replace>]
--Utils for language.Multi language
local languageUtilsInstance = class("languageUtilsInstance")

function languageUtilsInstance:ctor(params_)

end
--Multi language
function languageUtilsInstance:init()

end

--Trans word into current language
function languageUtilsInstance:tansWord(chineseStr_)
	
	return chineseStr_
end
--Trans fnt file name into current language
function languageUtilsInstance:tansFnt(fntFileName_)
	
	return fntFileName_
end
--Trans pic file name into current language
function languageUtilsInstance:tansPic(picName_)
	
	return picName_
end


cc.exports.languageUtils={}
function languageUtils:getInstance()
    if self.instance == nil then
        self.instance = languageUtilsInstance:new()
    end
    return self.instance
end