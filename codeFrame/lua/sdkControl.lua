[<File_doc|ui|/src/app/base/control/sdkControl.lua|replace>]
--各个平台的SDK判断
local sdkControlInstance = class("sdkControlInstance")

cc.exports.sdkControl={}
function sdkControl:getInstance()
    if self.instance == nil then
        self.instance = sdkControlInstance:new()
    end
    return self.instance
end