[<File_doc|ui|/src/app/base/control/soundControl.lua|replace>]
local soundControlInstance = class("soundControlInstance")

function soundControlInstance:init()
	self.sharedEngine = cc.SimpleAudioEngine:getInstance()--音频控制
end

function soundControlInstance:playEffectByName(effectSoundName_)
    self:playSound(effectSoundName_,false)
end

function soundControlInstance:playBackgroundByName(backGroundSoundName_)
    self:playMusic(backGroundSoundName_,true)
end

--[[--
返回音乐的音量值
@return number 返回值在 0.0 到 1.0 之间，0.0 表示完全静音，1.0 表示 100% 音量
]]
function soundControlInstance:getMusicVolume()
    local volume = self.sharedEngine:getMusicVolume()
    return volume
end


--[[--
设置音乐的音量
@param number volume 音量在 0.0 到 1.0 之间, 0.0 表示完全静音，1.0 表示 100% 音量
]]
function soundControlInstance:setMusicVolume(volume)
    volume = checknumber(volume)
    self.sharedEngine:setMusicVolume(volume)
end

--[[--
返回音效的音量值
@return number 返回值在 0.0 到 1.0 之间, 0.0 表示完全静音，1.0 表示 100% 音量
]]
function soundControlInstance:getSoundsVolume()
    local volume = self.sharedEngine:getEffectsVolume()
    return volume
end

--[[--
设置音效的音量
@param number volume 音量在 0.0 到 1.0 之间, 0.0 表示完全静音，1.0 表示 100% 音量
]]
function soundControlInstance:setSoundsVolume(volume)
    volume = checknumber(volume)
    self.sharedEngine:setEffectsVolume(volume)
end

--[[--
预载入一个音乐文件
在播放音乐前预先载入，可以在需要播放音乐时无延迟立即播放。
不过限于硬件设备和操作系统的限制，通常只能预载入一个音乐文件。

@param string filename 音乐文件名
]]
function soundControlInstance:preloadMusic(filename)
    self.sharedEngine:preloadMusic(filename)
end

--[[--
播放音乐
如果音乐文件尚未载入，则会首先载入音乐文件，然后开始播放。
注意：即便音乐音量为 0.0，soundControlInstance:playMusic() 仍然会进行播放操作。
如果希望停止音乐来降低 CPU 占用，应该使用 soundControlInstance:stopMusic() 接口完全停止音乐播放。

@param string filename 音乐文件名
@param boolean isLoop 是否循环播放，默认为 true
]]
function soundControlInstance:playMusic(filename, isLoop)
    if type(isLoop) ~= "boolean" then isLoop = true end
    soundControlInstance:stopMusic()
    self.sharedEngine:playMusic(filename, isLoop)
end

--[[--
停止播放音乐
@param boolean isReleaseData 是否释放音乐数据，默认为 true

]]
function soundControlInstance:stopMusic(isReleaseData)
    isReleaseData = checkbool(isReleaseData)
    self.sharedEngine:stopMusic(isReleaseData)
end

--[[--
暂停音乐的播放
]]
function soundControlInstance:pauseMusic()
    self.sharedEngine:pauseMusic()
end

--[[--
恢复暂停的音乐
]]
function soundControlInstance:resumeMusic()
    self.sharedEngine:resumeMusic()
end

--[[--
从头开始重新播放当前音乐
]]
function soundControlInstance:rewindMusic()
    self.sharedEngine:rewindMusic()
end

--[[--
检查是否可以开始播放音乐
如果可以则返回 true。
如果尚未载入音乐，或者载入的音乐格式不被设备所支持，该方法将返回 false。

@return boolean
]]
function soundControlInstance:willPlayMusic()
    local ret = self.sharedEngine:willPlayMusic()
    return ret
end

--[[--
检查当前是否正在播放音乐
如果有音乐正在播放则返回 true，否则返回 false

@return boolean
]]
function soundControlInstance:isMusicPlaying()
    local ret = self.sharedEngine:isMusicPlaying()
    return ret
end

--[[--
播放音效，并返回音效句柄
如果音效尚未载入，则会载入后开始播放。
该方法返回的音效句柄用于 soundControlInstance:stopSound()、soundControlInstance:pauseSound() 等方法。

@param string filename 音效文件名
@param boolean isLoop 是否重复播放，默认为 false

@return integer 音效句柄
]]
function soundControlInstance:playSound(filename, isLoop)
    if type(isLoop) ~= "boolean" then isLoop = false end
    local _backHandle=self.sharedEngine:playEffect(filename, isLoop)
    return _backHandle
end

--[[--
暂停指定的音效
@param integer 音效句柄
]]
function soundControlInstance:pauseSound(handle)
    self.sharedEngine:pauseEffect(handle)
end

--[[--
暂停所有音效
]]
function soundControlInstance:pauseAllSounds()
    self.sharedEngine:pauseAllEffects()
end

--[[--
恢复暂停的音效
@param integer 音效句柄
]]
function soundControlInstance:resumeSound(handle)
    self.sharedEngine:resumeEffect(handle)
end

--[[--
恢复所有的音效
]]
function soundControlInstance:resumeAllSounds()
    self.sharedEngine:resumeAllEffects()
end

--[[--
停止指定的音效
@param integer 音效句柄
]]
function soundControlInstance:stopSound(handle)
    self.sharedEngine:stopEffect(handle)
end

--[[--
停止所有音效
]]
function soundControlInstance:stopAllSounds()
    self.sharedEngine:stopAllEffects()
end

--[[--
预载入一个音效文件
可以在进入场景前，载入该场景需要的所有音效。这样就不会因为首次播放某个未载入的音效，而导致游戏暂停执行。
@param string 音效文件名
]]
function soundControlInstance:preloadSound(filename)
    self.sharedEngine:preloadEffect(filename)
end

--[[--
从内存卸载一个音效
退出场景时，可以卸载掉只有该场景使用的音效，从而节约内存。
@param string 音效文件名
]]
function soundControlInstance:unloadSound(filename)
    self.sharedEngine:unloadEffect(filename)
end
----------------------------------------------------------------------------------------------------------------------------------------------------------------
cc.exports.soundControl = {}
function soundControl:getInstance()
	if self.uniqueInstance == nil then
		self.uniqueInstance = soundControlInstance:new()
	end
	return self.uniqueInstance
end

return SM