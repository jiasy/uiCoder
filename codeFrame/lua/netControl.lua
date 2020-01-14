[<File_doc|ui|/src/app/base/control/netControl.lua|replace>]
local netControlInstance = class("netControlInstance")

cc.exports.netControl={}
function netControl:getInstance()
    if self.instance == nil then
        self.instance = netControlInstance:new()
    end
    return self.instance
end