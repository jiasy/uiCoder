[<File_doc|ui|/src/config.lua|replace>]
-- 0 - disable debug info, 1 - less debug info, 2 - verbose debug info
DEBUG = 2
-- use framework, will disable all deprecated API, false - use legacy API
CC_USE_FRAMEWORK = true
-- show FPS on screen
CC_SHOW_FPS = true
-- disable create unexpected global variable
CC_DISABLE_GLOBAL = true
-- for module display
CC_DESIGN_RESOLUTION = {
    width = 640,
    height = 960,
    autoscale = "FIXED_HEIGHT",
    callback = function(framesize)
        local ratio = framesize.width / framesize.height
        if ratio <= 1.34 then
            -- iPad 768*1024(1536*2048) is 4:3 screen
            return {autoscale = "FIXED_WIDTH"}
        end
    end
}
-- uiCoder use -------------
--h/v extends
UC_H_EXTEHD=false
UC_V_EXTEHD=true
--design size
UC_DESIGN_WIDTH =640
UC_DESIGN_HEIGHT=960
--debug--false when release
UC_DEBUG =true
--logShow
UC_FUNLOG=true
--btn states
UC_BTNSTATE={
    UNINITED=0,
    NORMAL=1,
    PRESS=2,
    LOCK=3
}

--server url
if UC_DEBUG == true then
    UC_SERVER_URL  = "http://123.123.123.123:1234/"
else
    UC_SERVER_URL  = "http://123.123.123.123:1234/"
end