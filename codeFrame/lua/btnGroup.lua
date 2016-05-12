[<File_doc|ui|/src/app/base/ui/btnGroup.lua|replace>]
local btnGroup = class("btnGroup")

function btnGroup:ctor()
    self.btnArr = {}
    self.currBtn = nil
end

function btnGroup:initByBtnArr(btnArr_)
    self.btnArr = btnArr_
    for i=1,#self.btnArr do
        if self.btnArr[i].btnGroup then
            assert(false,self.btnArr[i].name .. " alread in a btnGroup.cann't add again.")
        end
        self.btnArr[i].btnGroup = self
    end
    -- if #self.btnArr>1 then
    --     self.btnArr[1]:toPressState(true)
    -- end
end
--Change btn's state
function btnGroup:btnToPresseState(btnPress)
    for i=1,#self.btnArr do
        local btn=self.btnArr[i]
        if btn~= btnPress then
            btn:toNormalState(false)
        else
            self.currBtn = btn
        end
    end
end

function btnGroup:deleteRefer(btn_)
    for i=1,#self.btnArr do
        local _tempBtn=self.btnArr[i]
        if btn_==_tempBtn then
            table.remove(self.btnArr,i)
            if #self.btnArr==0 then
                self:onDelete()
            end
            return
        end
    end
end

function btnGroup:onDelete()
    while #self.btnArr>0 do
        table.remove(self.btnArr)
    end
    self.btnArr=nil
    self.currBtn = nil
end

return btnGroup
