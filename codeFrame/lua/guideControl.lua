[<File_doc|ui|/src/app/base/control/guideControl.lua|replace>]
--新手向导
local guideControlInstance = class("guideControlInstance")

cc.exports.guideControl={}
function guideControl:getInstance()
    if self.instance == nil then
        self.instance = guideControlInstance:new()
    end
    return self.instance
end