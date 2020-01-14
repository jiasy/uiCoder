[<File_doc|ui|/src/app/base/control/dataControl.lua|replace>]
--[[客户端 基本 数据结构 具体游戏模块不涉及。只提供最基础的数据
	-----------------具体游戏-----
	game
		deviceData     --设备类型   苹果，安卓，win8 等等  直接设备读  唯一APP ID 作为ID。
		versionData    --版本信息   Ver.1.3 游戏名称 等   	ID 为版本号。
		platformData   --平台信息   iosStore/googlePlay  ID 为自定的一个周知字符串。
		serverData     --服务器列表  访问主服务器时，产生。
		staticData     --静态表   
	-----------------当前server数据--进入服务器后产生
	server
		announceData   --公告列表   公告列表。
		chatData       --聊天频道   聊天信息列表。
		noticeData     --通知信息   提示信息，跑马等，谁抽了什么奖励。
		activitieData  --活动信息   几点开放之类的。
	-----------------用户--------
	user
		accountData    --账户信息
		playerData     --无服务器，角色信息
			consumeData   --角色，消耗数据，金币，体力，钱的等价交换物，其他消耗类道具。[name:number]
			otherData  --其他的游戏具体逻辑产生的数据
	-----------------界面针对----
	ui
		uiData         --界面使用，与界面生存周期相同
	-----------------服务器交互---netUtils 监听的成对儿的---
	net
		requestData    --请求数据
		responseData   --返回数据
	-----------------本地设置----
	local
		settingData    --本地设置，音量等等
		loginData      --持有 accountData serverData
]]

local dataControlInstance = class("dataControlInstance")

cc.exports.dataControl={}
function dataControl:getInstance()
    if self.instance == nil then
        self.instance = dataControlInstance:new()
    end
    return self.instance
end