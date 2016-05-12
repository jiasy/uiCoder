[<File_doc|ui|/src/app/base/ui/uiState.lua|replace>]
local uiState = class("uiState")
----------------------------------------------
--@param data Table {{node, x, y, scaleX, scaleY, rotation, alpha, width, height}, ...}
function uiState:ctor(host_, data_)
    self.stateName=nil
    self.host = host_
    self.node2prop = {}
    self.scaling = false
    if data_ then
        for _, item in pairs(data_) do
            local node = item[1]
            self:register(node, "x", item[2])
            self:register(node, "y", item[3])
            self:register(node, "scaleX", item[4])
            self:register(node, "scaleY", item[5])
            self:register(node, "rotation", item[6])
            self:register(node, "alpha", item[7])
            -- self:register(node, "width", item[8])
            -- self:register(node, "height", item[9])
        end 
    end
    self.uiControl=uiControl:getInstance()
    self.actionUtils=actionUtils:getInstance()
    self.displayUtils=displayUtils:getInstance()
end

function uiState:register(node_, propName_, propValue_)
    local _prop = self.node2prop[node_]
    if _prop == nil then
        _prop = {}
        self.node2prop[node_] = _prop
    end 
    _prop[propName_] = propValue_
end

function uiState:activate(playAnimation_, duration_, easeType_)
    if playAnimation_ == nil then playAnimation_ = true end
    duration_ = duration_ or 0.3
    for _node, _prop in pairs(self.node2prop) do
        local function moveComplete()
            self.uiControl:waitSub()
        end
        local function scaleComplete()
            self.scaling = false
            self.uiControl:waitSub()
        end
        local function rotateComplete()
            self.uiControl:waitSub()
        end
        local function fadeComplete()
            local _alpha = _prop["alpha"]
            if _alpha then
                if _alpha < 0.05 then 
                    _node.visible = false
                else 
                    _node.visible = true
                end
            end
            self.uiControl:waitSub()
        end

        local _x, _y = _node:getPosition()
        local _toX, _toY = _prop["x"] or _x, _prop["y"] or _y
        --if _node.alignBoo then _toX, _toY = _x, _y end
        local _opacitySupport=true
        if _node.isMotionStreak then
            _opacitySupport=false
        end

        local _opacity 
        local _toOpacity 
        local _toAlpha 
        if _opacitySupport then
            _opacity = _node:getOpacity()
            _toOpacity = _opacity
            _toAlpha = _prop["alpha"]
            if _toAlpha then _toOpacity = 255 * _toAlpha end
        end

        local _scaleX
        local _scaleY
        local _toScaleX
        local _toScaleY

        if _node.isSp9==true then
            local _tempRotationSave=_node:getRotation()
            _node:setRotation(0)
            local _currentSize=_node:getContentSize()
            _scaleX = _currentSize.width/_node.sourceWidth
            _scaleY = _currentSize.height/_node.sourceHeight
            _node:setRotation(_tempRotationSave)
            _toScaleX = _prop["scaleX"] or _scaleX
            _toScaleY = _prop["scaleY"] or _scaleY
        else
            _scaleX = _node:getScaleX()
            _scaleY = _node:getScaleY()
            _toScaleX = _prop["scaleX"] or _scaleX
            _toScaleY = _prop["scaleY"] or _scaleY
        end

        -- local size = _node:getContentSize()
        -- local _width= size.width
        -- local _height = size.height
        -- local _toWidth = _prop["width"] or _width
        -- local _toHeight = _prop["height"] or _height

        local _rotation=_node:getRotation()
        local _toRotation= _prop["rotation"] or _rotation
        
        if playAnimation_ then
            local _rotate
            if math.abs(_toRotation - _rotation) > 1 then
                _rotate = cc.RotateTo:create(duration_,_toRotation)
                _rotate = self.actionUtils:easeActionByType(_rotate, easeType_)
                _rotate = cc.Sequence:create(_rotate, cc.CallFunc:create(rotateComplete))
                _node:runAction(_rotate) 
                self.uiControl:waitAdd()
            end 

            local _fade
            if _opacitySupport then
                if math.abs(_toOpacity - _opacity) > 1 then
                    _fade = cc.FadeTo:create(duration_, _toOpacity)
                    _fade = self.actionUtils:easeActionByType(_fade, easeType_)
                    _fade = cc.Sequence:create(_fade, cc.CallFunc:create(fadeComplete))
                    _node:runAction(_fade)
                    self.uiControl:waitAdd()
                end
            end
            local _move
            if math.abs(_toX - _x) > 1 or math.abs(_toY - _y) > 1 then
                _move = cc.MoveTo:create(duration_, cc.vertex2F(_toX, _toY))
                _move = self.actionUtils:easeActionByType(_move, easeType_)
                _move = cc.Sequence:create(_move, cc.CallFunc:create(moveComplete))
                _node:runAction(_move) 
                self.uiControl:waitAdd()
            end 

            local _scale
            if (math.abs(_toScaleX - _scaleX) > 0.05 or math.abs(_toScaleY - _scaleY) > 0.05) then
                _scale = cc.ScaleTo:create(duration_, _toScaleX, _toScaleY)
                _scale = self.actionUtils:easeActionByType(_scale, easeType_)
                _scale = cc.Sequence:create(_scale, cc.CallFunc:create(scaleComplete))
                if _node.isSp9==true then
                    local function update()
                        local size = {}
                        size.width = _node.sourceWidth * _node.spriteIn:getScaleX()
                        size.height = _node.sourceHeight * _node.spriteIn:getScaleY()
                        _node:setContentSize(size)
                        if self.scaling then
                            self.actionUtils:nodeDelayCall(_node,0.05,update)
                        end
                    end
                    self.actionUtils:nodeDelayCall(_node,0.05,update)
                    _node.spriteIn:runAction(_scale) 
                    self.scaling = true
                else
                    _node:runAction(_scale) 
                end
                self.uiControl:waitAdd()
            end        

            if _fade or _move or _rotate or _scale  then
                _node:setVisible(true) 
            end
        else
            self.displayUtils:place(_node,_toX,_toY,_toRotation,_toScaleX,_toScaleY,_toAlpha)
        end
    end
end
function uiState:onDelete()
    self.displayUtils=nil
    self.host = nil
    self.node2prop = nil
    self.uiControl = nil
    self.actionUtils = nil
end

return uiState