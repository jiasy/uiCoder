[<File_doc|ui|/src/app/base/ui/disFs.lua|replace>]
local disBase=require("src.app.base.ui.disBase")
local disFs = class("disFs",disBase)

function disFs:ctor(params_)
	disFs.super.ctor(self,params_)
	self.className="disFs"
	self.displayType="base"
	self.name="none"
	self.frameArr=nil
	self.sprite=nil
	self.frameBaseName=""
	self.currentIndex=0
end

--init
function disFs:init(initDict_)
	if initDict_.frameBaseName then
		self.frameBaseName=initDict_.frameBaseName
	elseif initDict_.frameArray then
		self.frameArr=initDict_.frameArray
	else
		assert(false,"ERROR disFs cann't initializ")
	end
	disFs.super.init(self,initDict_)
end

function disFs:getFramePicNameByIndex(index_)
	return self.frameArr[index_]
end

function disFs:setFrameTo(index_)
	if index_ ~= self.currentIndex then
		local _picName=self:getPicNameByIndex(index_)
		if self.sprite==nil then
			self.sprite=cc.Sprite:create(_picName)
			self.sprite:setAnchorPoint(cc.p(0.5,0.5))
			self:addChild(self.sprite,1)
		else
			self.sprite:setTexture(_picName)
		end
		self.currentIndex=index_
	end
end

function disFs:getPicNameByIndex(index_)
	if self.frameBaseName~="" then
		return string.format("%s%04d",self.frameBaseName,index_)
	else
		return self.frameArr[index_]
	end
end

--Create--
function disFs:onCreate()
	disFs.super.onCreate(self)
	self:setFrameTo(1)
end

--Destory--
function disFs:onDestory()
	disFs.super.onDestory(self)
end

function disFs:onDelete()
	self.arrayUtils:clearArray(self.frameArr)
	self.frameArr=nil
	if self.sprite then
		self.sprite:removeFromParent(true)
	end
	disFs.super.onDelete(self)
end

return disFs