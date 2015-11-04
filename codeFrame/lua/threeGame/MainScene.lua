[<File_doc|ui|/src/app/views/MainScene.lua|replace>]
local MainScene = class("MainScene", cc.load("mvc").ViewBase)
local LocalProxy = require "app.ui.controls.three.fight.proxies.LocalProxy"
local Proxy  = require "app.ui.controls.three.fight.Proxy"

local function callLater(delay, callback)
    local data = {}
    data.funcID = cc.Director:getInstance():getScheduler():scheduleScriptFunc(function()
        callback()
        cc.Director:getInstance():getScheduler():unscheduleScriptEntry(data.funcID)
    end, delay, false)
end

function MainScene:onCreate()
    local proxy = LocalProxy.new()
	self:addChild(uiControl:getInstance().stageContainer)
	uiControl:getInstance():jumpTo("three","main"):init(proxy)
end

return MainScene