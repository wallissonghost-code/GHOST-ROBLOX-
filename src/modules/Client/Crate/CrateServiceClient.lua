local require=require(script.Parent.loader).load(script)
local Players=game:GetService("Players")
local Maid=require("Maid");local ObservableMap=require("ObservableMap");local PromiseGetRemoteFunction=require("PromiseGetRemoteFunction");local RemoteFunctionUtils=require("RemoteFunctionUtils");local RxBrioUtils=require("RxBrioUtils");local RxInstanceUtils=require("RxInstanceUtils");local RxValueBaseUtils=require("RxValueBaseUtils")
local S={ServiceName="CrateServiceClient"}
function S:Init()self._maid=Maid.new();self._remoteFunctionPromise=self._maid:Add(PromiseGetRemoteFunction("CrateServiceRemoteFunction"));self._model=ObservableMap.new();self._maid:GiveTask(self._model)end
function S:Start()self._maid:GiveTask(RxInstanceUtils.observeLastNamedChildBrio(Players.LocalPlayer,"Folder","ColorInventory"):Pipe({RxBrioUtils.switchMapBrio(function(c)return RxInstanceUtils.observeChildrenOfClassBrio(c,"IntValue")end)}):Subscribe(function(brio)local maid,obj=brio:ToMaidAndValue();maid:GiveTask(RxValueBaseUtils.observeValue(obj):Subscribe(function(count)self._model:Set(obj.Name,count)end));maid:GiveTask(function()self._model:Remove(obj.Name)end)end))end
function S:GetModel()return self._model end
function S:PromiseTryUnbox()return self._remoteFunctionPromise:Then(function(r)return RemoteFunctionUtils.promiseInvokeServer(r,"Unbox")end)end
function S:Destroy()self._maid:DoCleaning()end
return S
