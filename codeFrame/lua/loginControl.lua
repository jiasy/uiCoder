[<File_doc|ui|/src/app/base/control/loginControl.lua|replace>]
--登陆管理
--[[ 登陆 + 进入 游戏流程
	1.
		--读取本地设备
			game.deviceData
		--读取本地版本号         通过更新下来的代码获得
			game.versionData
		--读取平台数据           
			game.platformData
		--读取                  设置音效等等
			local.settingData

	2.
		--根据以下组合 取得版本更新信息
			game.deviceData + game.versionData + game.platformData
		--进行更新
			game.updateData

	3.
		--根据以下组合 取得服务器列表
			game.deviceData + game.versionData + game.platformData
		--显示列表
			game.serverData
		--SDK调用
		--获取账户信息【token+id.或者是其他什么反正都是字符串】【自有平台 账户密码填写】
			user.accountData
					--有   存
					--没有 建

	5.
		--读取本地登陆信息。根据记录的服务器信息指定默认服务器 [没有默认指向列表最后一个]
			local.loginData
					--有   读
					--没有 不创建

	6.
		--选择服务器，点击登陆
			local.loginData --[ uniqueID / username + password / token + id ]
					--有   写
					--没有 创建+写

	7.
		--读取到这个服务器下面的角色信息 [服务器端没有创建出来一个，前端进入新手向导][有就正常进入游戏]
			user.playerData
		--读取 游戏相关的静态表
			game.staticData
		--读取公告信息
			server.announceData
]]
local loginControlInstance = class("loginControlInstance")

cc.exports.loginControl={}
function loginControl:getInstance()
    if self.instance == nil then
        self.instance = loginControlInstance:new()
    end
    return self.instance
end