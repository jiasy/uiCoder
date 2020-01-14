[<File_doc|ui|/src/app/base/util/actionUtils.lua|replace>]
--tools for action
local actionUtilsInstance = class("actionUtilsInstance")
function actionUtilsInstance:ctor(params_)
    self.actionEases = {
        [11] = cc.EaseBounceIn,-------------------1 : EaseBounce
        [12] = cc.EaseBounceOut,
        [13] = cc.EaseBounceInOut,
        [21] = cc.EaseBackIn,---------------------2 : EaseBack
        [22] = cc.EaseBackOut,
        [23] = cc.EaseBackInOut,
        [31] = cc.EaseElasticIn,------------------3 : EaseElastic
        [32] = cc.EaseElasticOut,
        [33] = cc.EaseElasticInOut,
        [41] = cc.EaseExponentialIn,--------------4 : EaseExponential
        [42] = cc.EaseExponentialOut,
        [43] = cc.EaseExponentialInOut,
        [51] = cc.EaseSineIn,---------------------5 : EaseSine
        [52] = cc.EaseSineOut,
        [53] = cc.EaseSineInOut,
    }
end

--action convert to a easeAction 
function actionUtilsInstance:easeActionByType(action_,key_)
    key_ = key_ or 0
    assert(type(key_) == "number", "actionUtils:easeActionByType() - invalid key : "..key_)
    local actionClass = self.actionEases[key_]
    assert(actionClass, "actionUtils:easeActionByType() - invalid key : "..key_)
    return actionClass:create(action_)
end

function actionUtilsInstance:delayCall(delayTime_,callback_)
    local _scheduler = cc.Director:getInstance():getScheduler()
    local _entry
    local function _delayCallFun()
        callback_()--Call fun
        _scheduler:unscheduleScriptEntry(_entry)--Remove delay
    end
    _entry=_scheduler:scheduleScriptFunc(_delayCallFun, delayTime_, false)
    return _entry--Return,You can operate it.
end
--Delay call,use node runAction
function actionUtilsInstance:nodeDelayCall(node_,delayTime_,callback_)
    local delay = cc.DelayTime:create(delayTime_)
    local sequence = cc.Sequence:create(delay, cc.CallFunc:create(callback_))
    node_:runAction(sequence)
    return sequence
end

cc.exports.actionUtils={}
function actionUtils:getInstance()
    if self.instance == nil then
        self.instance = actionUtilsInstance:new()
    end
    return self.instance
end