if _G.dc == nil then
    -- 创建 数据中心 的三个步骤。
    require("DataCenterUtils").new() -- 1.引用 专属 工具类
    dcu:init(ENV_ENGINE_NONE,"",true) --  2.指定引擎，没有引擎指定，DataCenterTest.lua 独立运行。指明 require 的相对路径
    dcu.DataCenter.new() -- 3.构建数据中心对象
    if json == nil then
        require(dcu.requirePathPrefix.."json")
    end
end

local doTest = function()
    print("------------------------------ Json数据读取到键上 ------------------------------")
    local _jsonStr = [=[
        {
            "v1": 10,
            "v2": 15,
            "v3": 30,
            "result": 123456,
            "roomCardCount": 1000000,
            "dict": {
                "num": 1,
                "bool": false
            },
            "list": [
                {
                    "id": 300001,
                    "startTime": 3242141,
                    "endTime": 23131
                },
                {
                    "id": 300002,
                    "startTime": 231231123,
                    "endTime": 3231412
                }
            ]
        }
    ]=]
    local _jsonDict = json.decode(_jsonStr)
    dc:setValueToPath("user",_jsonDict)
    dc:setValueToPath("test.stringSample1","_1_${user.result}_2_${user.roomCardCount}_3_") -- 数据路径是拼接另外两个数据源
    dc:setValueToPath("test.stringSample2","${user.v1} 和 ${user.v2}")
    dc:dispatchDataChange() -- 触发数据变更
    
    print("------------------------------ DataConnector ------------------------------")
    -- 创建数据关联对象，每次修改监听的数据路径，都会触发一次数据变更以便获取当前的值。
    local _connector = dcu.DataConnector.new(nil) -- 不关联方法或显示对象
    -- 更换监听路径。路径内是${}的数据拼接，所以，实际监听的会是${}指定的数据
    _connector:resetDataPath('test.stringSample1') -- test.stringSample1 : _1_1245186_2_1000000_3_
    assert(dc.dataEventMgr:getListenerCount('user.result') == 1)
    assert(dc.dataEventMgr:getListenerCount('user.roomCardCount') == 1)
    -- 更换监听路径。${}的拼接跟换，所以，之前的会监听会被清除
    _connector:resetDataPath('test.stringSample2') -- test.stringSample2 : 10 和 20
    assert(dc.dataEventMgr:getListenerCount('user.v1') == 1)
    assert(dc.dataEventMgr:getListenerCount('user.v2') == 1)
    assert(dc.dataEventMgr:getListenerCount('user.result') == 0)
    assert(dc.dataEventMgr:getListenerCount('user.roomCardCount') == 0)
    -- 更换成 字符串 指定的数据关联。解析 ${} 路径，形成新的监听
    _connector:resetByStr("${user.v1} 和 ${user.v3}") -- ${user.v1} 和 ${user.v3} : 10 和 30
    assert(dc.dataEventMgr:getListenerCount('user.v1') == 1)
    assert(dc.dataEventMgr:getListenerCount('user.v2') == 0)
    assert(dc.dataEventMgr:getListenerCount('user.v3') == 1)
    -- 变更回 路径指定，路径内容也不是拼接型的。所以，直接监听这个路径
    _connector:resetDataPath("user.v1") -- user.v1 : 10
    assert(dc.dataEventMgr:getListenerCount('user.v1') == 1)
    assert(dc.dataEventMgr:getListenerCount('user.v3') == 0)
    _connector:destroy() -- 清理对象
    assert(dc.dataEventMgr:getListenerCount('user.v1') == 0)
    
    print("------------------------------ DataCompare ------------------------------")
    -- 创建数据比较对象，每次修改监听的数据路径，都会触发一次数据变更以便获取当前的值
    local _compare = dcu.DataCompare.new(nil) -- 不关联方法或显示对象
    -- 重新对比较路径进行监听
    _compare:resetByStr('user.v1==10') -- user.v1==10 : true 
    assert(dc.dataEventMgr:getListenerCount('user.v1') == 1)
    -- 公式变换，监听变换
    assert(_compare:resetByStr('15[)user.v2,20')==true) -- 15[)user.v2,20 : true
    assert(dc.dataEventMgr:getListenerCount('user.v1') == 0)
    assert(dc.dataEventMgr:getListenerCount('user.v2') == 1)
    dc:setValueToPath("user.v2",16) -- 15[)user.v2,20 : false
    dc:dispatchDataChange() -- 触发数据变更 -- 上面的表达执行才有结果
    _compare:destroy() -- 清理对象
    assert(dc.dataEventMgr:getListenerCount('user.v2') == 0)
    
    print("------------------------------ 字典结构覆盖 ------------------------------")
    -- 在现有的基础上，再次添加值
    _jsonStr = '{ "v1":16,"result": 654321}'
    _jsonDict = json.decode(_jsonStr)
    dc:setValueToPath("user",_jsonDict)
    dc:dispatchDataChange() -- 触发数据变更
    
    print("------------------------------ 数组元素变更 ------------------------------")
    dc:setValueToPath("user.list.[1].id",300003)
    dc:dispatchDataChange() -- 触发数据变更    

end
-- 执行测试
doTest()