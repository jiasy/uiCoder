[<File_doc|ui|/src/app/base/util/timeUtils.lua|replace>]
--utils for time
local timeUtilsInstance = class("timeUtilsInstance")

function timeUtilsInstance:getCurrentTime()
	return os.time()
end
cc.exports.timeUtils={}
function timeUtils:getInstance()
    if self.instance == nil then
        self.instance = timeUtilsInstance:new()
    end
    return self.instance
end