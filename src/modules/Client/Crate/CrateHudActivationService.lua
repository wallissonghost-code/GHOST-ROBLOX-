local require=require(script.Parent.loader).load(script)
local CrateControlsService=require("CrateControlsService"); local CrateInventoryService=require("CrateInventoryService"); local Maid=require("Maid")
local S={ServiceName="CrateHudActivationService"}
function S:Init(b) self._maid=Maid.new(); self._crateControlsService=b:GetService(CrateControlsService); self._crateInventoryService=b:GetService(CrateInventoryService) end
function S:Start() self._maid:GiveTask(task.delay(.5,function() local m=Maid.new(); self._maid._push=m; m:GiveTask(self._crateControlsService:PushEnabled()); m:GiveTask(self._crateInventoryService:PushEnabled()) end)) end
function S:Destroy() self._maid:DoCleaning() end
return S
