local require=require(script.Parent.loader).load(script)
local S={ServiceName="ColorRngService"}
function S:Init(b)b:GetService(require("HideService"));b:GetService(require("CrateService"))end
return S
