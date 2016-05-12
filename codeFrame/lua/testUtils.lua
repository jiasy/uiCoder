[<File_doc|ui|/src/app/base/util/testUtils.lua|replace>]
local testUtilsInstance = class("testUtilsInstance")
function testUtilsInstance:ctor(params_)
	self.className="testUtils"
	--functionStack函数运行堆栈
	self.functionStack={}
    --那些类型能输出LOG
    self.showLogTypeArr={}
    
    --self.showLogTypeArr["frameUpdate"]="~"--帧更新
    self.showLogTypeArr["frameUpdateProperty"]="~"

    self.showLogTypeArr["frameControl"]="~"--帧控制代码
    
    --self.showLogTypeArr["frameAction"]="~"--帧动作
    
    --self.showLogTypeArr["soundControl"]="~"--声音控制
    
    --self.showLogTypeArr["baseFunLog"]="~"--基础框架的函数输出
    
    --self.showLogTypeArr["mouseTouch"]="~"--鼠标点击事件
    
    --self.showLogTypeArr["manager"]="~"--管理器代码
    
    self.showLogTypeArr["disCreate"]="~"--创建显示对象
    --self.showLogTypeArr["disCreateRoll"]="~"`
    
    --self.showLogTypeArr["util"]="~"--工具代码
    
    self.showLogTypeArr[""]="~"--funLog在就输出
    self.interStr="   |"

    self.timeU=timeUtils:getInstance()
end

--显示log
function testUtilsInstance:showLog(log_)
	print(log_)
end


function testUtilsInstance:isTypeShowLog(type_)
    -- body
    if self.showLogTypeArr[type_] then
        return true
    else
        return false
    end
end


--那个类型的，那个类，那个方法，那些说明
--self.testM:FI("type",self.className,"function","")
--方法进入
function testUtilsInstance:FI(type_,path_,functionName_,comment_)
    --测试--开启函数LOG模式
    if UC_DEBUG and UC_FUNLOG then
        if self:isTypeShowLog(type_)==false then
            return
        end
    	--记录这个方法执行时的相关信息
    	local _tempTable = {}
    	--组合成唯一函数路径
    	_tempTable["uniquePath"]=path_.." -> "..functionName_
    	--执行起始时间
    	_tempTable["time"]=self.timeU:getCurrentTime()
    	--进行了几次入栈
    	_tempTable["pushTime"]=#self.functionStack
        table.insert(self.functionStack,_tempTable)
        -- for i=1,#self.functionStack do
        --     print(i.." : "..self.functionStack[i]["uniquePath"])
        -- end
    	--层级字符串
    	local _tempStr=""
    	for i=1,#self.functionStack do
    		_tempStr=_tempStr..self.interStr
    	end
    	--层级叠加得到当前的方法执行字符串
    	_tempStr=_tempStr..path_.." -> "..functionName_
        
        --显示LOG
        if comment_ and comment_~="" then
            self:showLog("->".._tempStr.."  :  "..comment_)
        else
            self:showLog("->".._tempStr)
        end
    end
end

--方法跳出
function testUtilsInstance:FO(type_,path_,functionName_,comment_)
    --测试--开启函数LOG模式
    if UC_DEBUG and UC_FUNLOG then
        if self:isTypeShowLog(type_)==false then
            return
        end
    	local _tempStr=""
    	for i=1,#self.functionStack do
    		_tempStr=_tempStr..self.interStr
    	end
    	--获取堆栈的最后一个
    	local _tempTable=table.remove(self.functionStack)
    	local _lastFunStr=_tempTable["uniquePath"]
    	--组合成唯一函数路径
    	if path_.." -> "..functionName_ == _lastFunStr then
    		_tempStr=_tempStr.._lastFunStr
    		local _timeDiff=self.timeU:getCurrentTime()-_tempTable["time"]
            --显示LOG
            if comment_ and comment_~="" then
                self:showLog("<-".._tempStr.." [".._timeDiff.."]".."  :  "..comment_)
            else
                self:showLog("<-".._tempStr.." [".._timeDiff.."]")
            end
    	else
    		local _functionOut=path_.." -> "..functionName_
    		local _functionStack=_lastFunStr
    		self:error(self.className,"FO",_functionOut.." <> ".._functionStack)
    	end
    end
end

function testUtilsInstance:FL(type_,path_,functionName_,comment_)
    if UC_DEBUG and UC_FUNLOG then
        if self:isTypeShowLog(type_)==false then
            return
        end
        local _tempStr=""
        for i=1,#self.functionStack do
            _tempStr=_tempStr..self.interStr
        end
        --多一个保持层级
        _tempStr=_tempStr..self.interStr

        if comment_ and comment_~="" then
            self:showLog("  ".._tempStr..path_.." -> "..functionName_.." : "..comment_)
        else
            self:showLog("  ".._tempStr..path_.." -> "..functionName_)
        end
    end
        
end

--函数方法
function testUtilsInstance:funLog(className_,funName_,log_)
	local _blank=""
	self:showLog(string.format("%s_%s_%s : %s",_blank,className_,funName_,log_))
end

--self.testM:error(self.calssName,"funName","log")
--错误log
function testUtilsInstance:error(className_,funName_,log_)
    assert(false,string.format("ERROR_%s_%s : %s",className_,funName_,log_))
end

cc.exports.testUtils = {}
function testUtils:getInstance()
    if self.instance == nil then
        self.instance = testUtilsInstance:new()
    end
    return self.instance
end