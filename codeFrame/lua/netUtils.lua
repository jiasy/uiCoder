[<File_doc|ui|/src/app/base/util/netUtils.lua|replace>]
--http
--sokect
--utils for net
local netUtilsInstance = class("netUtilsInstance")

cc.exports.netUtils={}
function netUtils:getInstance()
    if self.instance == nil then
        self.instance = netUtilsInstance:new()
    end
    return self.instance
end