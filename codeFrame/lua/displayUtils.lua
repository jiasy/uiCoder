[<File_doc|ui|/src/app/base/util/displayUtils.lua|replace>]
--Tools for display
local displayUtilsInstance = class("displayUtilsInstance")
--Init------------------------------------------
function displayUtilsInstance:ctor(params_)
	self.ttfConfig = {}
    self.ttfConfig.fontFilePath = "FZHLJW.TTF"
    self.ttfConfig.glyphs   = cc.GLYPHCOLLECTION_DYNAMIC
    self.ttfConfig.customGlyphs = nil
    self.ttfConfig.distanceFieldEnabled = true
    self.ttfConfig.outlineSize = 0
    self.spriteFrames={}
end
--Set displayObject's parameter. add to container.
function displayUtilsInstance:placeAndAddChildToContainer(dis_,container_,ax_,ay_,px_,py_,r_,sx_,sy_,a_,index_)
	self:setAnchor(dis_,ax_,ay_)
	self:place(dis_,px_,py_,r_,sx_,sy_,a_)
	container_:addChild(dis_,index_,index_)
end
--Set displayObject's logic parent.
function displayUtilsInstance:setLogicParent(dis_,logicParent_)
	dis_.logicParent=logicParent_--设置逻辑父容器
	dis_:setCascadeOpacityEnabled(true)
	table.insert(logicParent_.displayList,dis_)--放入显示列表
end
function displayUtilsInstance:setAnchor(dis_,ax_,ay_)
	if ax_ and ay_ and (ax_~=0 or ay_~=0) then dis_:setAnchorPoint( cc.p(ax_, ay_)) end
end

function displayUtilsInstance:setSp9Info(dis_,namePath_)
	dis_.spriteIn=cc.Sprite:create(namePath_)
	local _size=dis_.spriteIn:getContentSize()
	dis_.sourceWidth=_size.width
	dis_.sourceHeight=_size.height
	dis_.spriteIn:setVisible(false)
	dis_:addChild(dis_.spriteIn)
end

--Short code for set displayObject's parameter.
function displayUtilsInstance:place(dis_,px_,py_,r_,sx_,sy_,a_)
	if a_~=nil then
		if a_ >0.05 and dis_:isVisible()==false then
			dis_:setVisible(true) 
			if dis_.isMotionStreak==true then
			else
				dis_:setOpacity(a_*255)
			end
		elseif a_ <=0.05 and dis_:isVisible() then 
			dis_:setVisible(false) 
			dis_:setOpacity(a_*255)--看不到但是透明度的数值需要跟着变
		end
	end
	if dis_:isVisible() then
	    if dis_.isSp9==true then
            dis_:setContentSize(cc.size(dis_.sourceWidth * sx_,dis_.sourceHeight * sy_))
        else
			if sx_~=nil then dis_:setScaleX(sx_) end
			if sy_~=nil then dis_:setScaleY(sy_) end
        end
        if px_~=nil and py_ ~=nil then dis_:setPosition( cc.p(px_, py_) ) end
		if r_~=nil then dis_:setRotation(r_) end
	end
end
--Set text's color and width/height
function displayUtilsInstance:textSet(text_,r_,g_,b_,w_,h_)
    text_:setTextColor(cc.c4b(r_,g_,b_,255))
    if w_ then text_:setWidth(w_) end
	if h_ then text_:setHeight(h_) end
	text_:setLineBreakWithoutSpace(true) 
end
--Create a pic and scale it
function displayUtilsInstance:getPicScaleToSize(picName_,width_,height_)
    local _pic = cc.Sprite:create(picName_)
    _pic:setAnchorPoint(cc.p(0,0))
    _pic:setScaleX(width_/_pic:getContentSize().width)
    _pic:setScaleY(height_/_pic:getContentSize().height)
    return _pic
end
--Set btn's text
function displayUtilsInstance:setBtnText(btn_,text_,fontName_,fontSize_,align_,color3C_)
	btn_:setTitleFontName(fontName_)
	btn_:setTitleFontSize(fontSize_)
	if align_=="left" then
		btn_:setTitleAlignment(cc.TEXT_ALIGNMENT_LEFT)
	elseif align_=="right" then
		btn_:setTitleAlignment(cc.TEXT_ALIGNMENT_CENTER)
	elseif align_=="center" then
		btn_:setTitleAlignment(cc.TEXT_ALIGNMENT_RIGHT)
	end
	btn_:setTitleColor(color3C_)
	btn_:setTitleText(text_)
end

--Set blend mode to displayObject
function displayUtilsInstance:setBlendToDisplay(dis_,mode_)
	if mode_=="lighten" then--lighten
		dis_:setBlendFunc(cc.blendFunc(gl.ONE , gl.ONE))
	elseif mode_=="overlay" then--overlay
		dis_:setBlendFunc(cc.blendFunc(gl.DST_COLOR , gl.ONE))
	elseif mode_=="multiply" then--multiply
		dis_:setBlendFunc(cc.blendFunc(gl.DST_COLOR , gl.ONE_MINUS_SRC_ALPHA))
	elseif mode_=="screen" then--screen
		dis_:setBlendFunc(cc.blendFunc(gl.ONE_MINUS_DST_COLOR , gl.ONE))
	elseif mode_=="add" then--add
		dis_:setBlendFunc(cc.blendFunc(gl.SRC_ALPHA, gl.ONE))
	elseif mode_=="layer" then--layer--black edge
		dis_:setBlendFunc(cc.blendFunc(gl.ONE_MINUS_SRC_ALPHA, gl.ONE_MINUS_SRC_ALPHA))
	else--unSupport show black rectangle
		dis_:setBlendFunc(cc.blendFunc(gl.ZERO, gl.ONE_MINUS_DST_ALPHA))
	end
end

--Use "stencil_" create a mask in "container_" to mask childs.
function displayUtilsInstance:createMask(container_,stencil_,disCount_)
	local _startIndex=stencil_:getTag()
	local _maskContainer=cc.Layer:create()
	_maskContainer:setPosition(cc.p(0,0))
	_maskContainer:setAnchorPoint(cc.p(0,0))
	for _loopIndex=_startIndex-1,(_startIndex-disCount_),-1 do
		if _loopIndex >0 then
			local _disPlay=container_:getChildByTag(_loopIndex)
			_disPlay:retain()
			stencil_.logicParent:removeChild(_disPlay)
			_maskContainer:addChild(_disPlay,_loopIndex,_loopIndex)
			_disPlay:release()
		else
			break
		end
	end
	local _clippingNode = cc.ClippingNode:create()
	_clippingNode:setAnchorPoint(cc.p(0,0))
	_clippingNode:setStencil(stencil_)
	_clippingNode:setInverted(false)
	_clippingNode:setAlphaThreshold(0)
    _clippingNode:setPosition(cc.p(0,0))
	stencil_:removeFromParent(false)
    _clippingNode:addChild(_maskContainer)
    container_:addChild(_clippingNode,_startIndex)
end

--[[图片调整大小，适应屏幕
	type_   "fit" x，y方向放缩去适应屏幕
			"in"  在屏幕里,等比放缩直到x，y任意一方接触到屏幕边缘
			"out" 在屏幕外,包含屏幕
]]
function displayUtilsInstance:picFitWindowSize(pic_,type_)
	local _picSize=pic_:getContentSize()
	local _uc=uiControl:getInstance()
	if type_ == "fit" then
		local _scaleX,_scaleY=1.0
		_scaleX=_uc.realWidth/_picSize.width
		pic_:setScaleX(_scaleX)
		_scaleY=_uc.realHeight/_picSize.height
		pic_:setScaleY(_scaleY)
		return _scaleX,_scaleY
	else
		local _scale=1.0
		if _picSize.width/_picSize.height>_uc.realWidth/_uc.realHeight then
			if type_=="in" then
				_scale=_uc.realWidth/_picSize.width
			elseif type_=="out" then
				_scale=_uc.realHeight/_picSize.height
			end
		else
			if type_=="in" then
				_scale=_uc.realHeight/_picSize.height
			elseif type_=="out" then
				_scale=_uc.realWidth/_picSize.width
			end
		end
		pic_:setScale(_scale)
		return _scale,_scale
	end
	return nil,nil
end

function displayUtilsInstance:createPartical(particalName_,type_)
    local _aniSprite = cc.ParticleSystemQuad:create(string.format("%s.plist",particalName_))
    if type_ == "free" then
    	_aniSprite:setPositionType(cc.POSITION_TYPE_FREE)
    elseif type_ == "grouped" then
    	_aniSprite:setPositionType(cc.POSITION_TYPE_GROUPED)
    elseif type_ == "relative" then
    	_aniSprite:setPositionType(cc.POSITION_TYPE_RELATIVE)
    end
   	return _aniSprite
end

function displayUtilsInstance:createAnimation(animationName_,loop_,fun_)
    local sharedSpriteFrameCache = cc.SpriteFrameCache:getInstance()
    sharedSpriteFrameCache:addSpriteFrames(
        string.format("%s.plist",animationName_)
        ,
        string.format("%s.pvr.ccz",animationName_)
        )
    local _spriteFrames=self.spriteFrames[animationName_]

    if _spriteFrames==nil then
    	_spriteFrames={}
	    local _loopBoolean=true
	    local j=1
	    while _loopBoolean do
	    	local _spritePicName=string.format("%s%04d.png",animationName_,j)
	        local _tempSpriteFrame=sharedSpriteFrameCache:getSpriteFrame(_spritePicName)
	        table.insert(_spriteFrames, _tempSpriteFrame)
	        if _tempSpriteFrame == nil then
	            _loopBoolean=false
	        end
	        j=j+1
	    end
	    self.spriteFrames[animationName_]=_spriteFrames
    end

    local _aniSprite =cc.Sprite:createWithSpriteFrame(_spriteFrames[#_spriteFrames])
    local _animation = cc.Animation:createWithSpriteFrames(_spriteFrames,0.083)
    local _animationSequence
    if loop_ then
        _animationSequence=cc.RepeatForever:create(cc.Animate:create(_animation))
    else
        local function removeFun()
            _aniSprite:stopAllActions()
            _aniSprite:removeFromParent(true)
            if fun_ then fun_() end--make sure call it when is exist
        end
        local callfunc = cc.CallFunc:create(removeFun)
        _animationSequence = cc.Sequence:create(cc.Animate:create(_animation),callfunc)
    end
    _aniSprite:runAction(_animationSequence)
   	return _aniSprite
end

cc.exports.displayUtils={}
function displayUtils:getInstance()
	if self.instance == nil then
		self.instance = displayUtilsInstance:new()
	end
	return self.instance
end