[<File_doc|ui|/src/app/views/MainScene.lua|replace>]
local MainScene = class("MainScene", cc.load("mvc").ViewBase)

function MainScene:onCreate()
	self:addChild(uiControl:getInstance().stageContainer)
	uiControl:getInstance():jumpTo("three","main"):init({})
end

return MainScene