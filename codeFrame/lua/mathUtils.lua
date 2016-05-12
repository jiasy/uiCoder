[<File_doc|ui|/src/app/base/util/mathUtils.lua|replace>]
--utils for math
local mathUtilsInstance = class("mathUtilsInstance")

function mathUtilsInstance:pointInRect(point_,rect_)
	if point_.x > rect_.x then
		if point_.y < rect_.y then
			if point_.x < rect_.x+rect_.width then
				if point_.y > rect_.y-rect_.height then
					return true
				end
			end
		end
	end
	return false
end

function mathUtilsInstance:pointInCircle(point_,centerPoint_,circleR_)
	local _disX=point_.x-centerPoint_.x
	local _disY=point_.y-centerPoint_.y
	if _disX*_disX+_disY*_disY < circleR_*circleR_ then
		return true
	else
		return false
	end
end

cc.exports.mathUtils={}
function mathUtils:getInstance()
    if self.instance == nil then
        self.instance = mathUtilsInstance:new()
    end
    return self.instance
end