
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- kill any previous instance before starting
if getgenv()._ZeroWindow then pcall(function() getgenv()._ZeroWindow:Unload() end) end
pcall(function() local RS=game:GetService("RunService")
    for _,n in ipairs({"VVUFly","VVUSpeed","VVUTween","VVUMobTween","VVUChestTween","VVUServerESP"}) do
        RS:UnbindFromRenderStep(n)
    end
end)
local NetworkManager = nil
local Old = nil
pcall(function()
    NetworkManager = require(ReplicatedStorage.SharedModules.NetworkManager)
    Old = hookfunction(NetworkManager.FireServer, newcclosure(function(self, Name, ...)
        if Name == "ProcessDamage" then warn("blocked"); return end
        return Old(self, Name, ...)
    end))
end)

repeat task.wait() until game:IsLoaded()
task.wait(3)
-- wait for Requests to replicate before anything accesses it
ReplicatedStorage:WaitForChild("Requests", 30)

local RS  = game:GetService("RunService")
local PS  = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local LT  = game:GetService("Lighting")
local HS  = game:GetService("HttpService")
local TP  = game:GetService("TeleportService")
local Cam = workspace.CurrentCamera
local LP  = PS.LocalPlayer

local function launchTP(placeId, jobId)
    local ok = pcall(function() game:GetService("ExperienceService"):LaunchExperience({placeId=placeId,gameInstanceId=jobId}) end)
    if not ok then pcall(function() TP:TeleportToPlaceInstance(placeId, jobId or game.JobId, LP) end) end
end
local function getChar() return LP.Character end
local function getHRP()  local c=getChar(); return c and c:FindFirstChild("HumanoidRootPart") end
local function getHum()  local c=getChar(); return c and c:FindFirstChildOfClass("Humanoid") end

local S = {
    speed=100, infJumpH=50, flySpeed=100, tweenSpeed=100,
    aimbotFOV=45, aimbotSens=1, aimbotX=0, aimbotY=0,
    aimbotMode="Toggle", aimbotActive=false, aimbotEnabled=false,
    aimbotMethod="Camera", targetPlayers=true, visibleOnly=false, teamCheck=false,
    brightness=2, freeCamSens=0.3, freeCamSpeed=0.5, fovVal=70,
    espDist=1000, espFontSize=14, tracerThick=2,
    espRainbow=false, hlFillTrans=0.5, hlOutlineTrans=0, espAntiLag=true,
}
_wFPS = 60

local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/lionun-lab/Newstar/refs/heads/main/EthosSuite"))()

local Window = Library:CreateWindow({
    Title = "ZERO HUB",
    GameName = "VV Ultimatum",
    Version = "v2.3",
})

local Tog, Opt, Connections = {}, {}, {}

local _cleanupFns = {}
local function onUnload(fn) table.insert(_cleanupFns, fn) end
getgenv()._ZeroWindow = Library
do
    local _origUnload = Window.Unload
    function Window:Unload()
        for _, fn in ipairs(_cleanupFns) do pcall(fn) end
        getgenv()._ZeroWindow = nil
        return _origUnload(self)
    end
end

local function notify(msg, dur)
    task.defer(function()
        pcall(function() Library:Notify({ Title="VV Ultimatum", Description=msg, Duration=dur or 3 }) end)
    end)
end
local Tabs = {}
local CatGame   = Window:AddCategory("GAME")
Tabs.Game      = CatGame:AddTab("Main")
local CatChar   = Window:AddCategory("CHARACTER")
Tabs.Character = CatChar:AddTab("Character")
local CatViz    = Window:AddCategory("VISUALS")
Tabs.Visuals   = CatViz:AddTab("Visuals")
local CatWorld  = Window:AddCategory("WORLD")
Tabs.World     = CatWorld:AddTab("World")
Tabs.Nav       = CatWorld:AddTab("Navigation")
local CatMisc   = Window:AddCategory("MISC")
Tabs.Misc      = CatMisc:AddTab("Misc")

Library:CreateSettingsTab(Window)

local GameL = Tabs.Game:AddGroupbox("Player Farm")
local GameL2 = Tabs.Game:AddGroupbox("Mob Farm")
local GameL4 = Tabs.Game:AddGroupbox("Auto Sell")
local GameL5 = Tabs.Game:AddGroupbox("Auto Store")
local GameR = Tabs.Game:AddGroupbox("Farm Config")
local GameR2 = Tabs.Game:AddGroupbox("Auto Skill")
local GameR3 = Tabs.Game:AddGroupbox("Item Notifier")
local GameR4 = Tabs.Game:AddGroupbox("Quest Helper")
local GameR5 = Tabs.Game:AddGroupbox("Auto Raid")
local GameR6 = Tabs.Game:AddGroupbox("Gauntlet")
local CharL = Tabs.Character:AddGroupbox("Movement")
local CharL2 = Tabs.Character:AddGroupbox("Morphs")
local CharR = Tabs.Character:AddGroupbox("Utility")
local CharR2 = Tabs.Character:AddGroupbox("Enhancements")
local CharR3 = Tabs.Character:AddGroupbox("Aimbot")
local VizL = Tabs.Visuals:AddGroupbox("Player ESP")
local VizL2 = Tabs.Visuals:AddGroupbox("Mob ESP")
local VizL3 = Tabs.Visuals:AddGroupbox("Chest ESP")
local VizR = Tabs.Visuals:AddGroupbox("ESP Config")
local VizR2 = Tabs.Visuals:AddGroupbox("NPC ESP")
local VizR3 = Tabs.Visuals:AddGroupbox("Portal ESP")
local VizR4 = Tabs.Visuals:AddGroupbox("Marker ESP")
local VizL4 = Tabs.Visuals:AddGroupbox("Quest ESP")
local WorldL2 = Tabs.World:AddGroupbox("Camera")
local WorldR = Tabs.World:AddGroupbox("Visual FX")
local WorldR2 = Tabs.World:AddGroupbox("FPS Boost")
local WorldR3 = Tabs.World:AddGroupbox("Tools")
local NavL = Tabs.Nav:AddGroupbox("Teleport")
local NavL2 = Tabs.Nav:AddGroupbox("Game Teleports")
local NavL3 = Tabs.Nav:AddGroupbox("Chest Farm")
local NavR = Tabs.Nav:AddGroupbox("Attach")
local NavR2 = Tabs.Nav:AddGroupbox("Attach Config")
local MiscL4 = Tabs.Misc:AddGroupbox("Ownership")
local MiscL5 = Tabs.Misc:AddGroupbox("Hogyoku Sniper")
local MiscR = Tabs.Misc:AddGroupbox("Abilities")
local MiscR2 = Tabs.Misc:AddGroupbox("Anti Status")
local MiscR3 = Tabs.Misc:AddGroupbox("Auto Hop")

getgenv()._ZHBoxes = getgenv()._ZHBoxes or {}

local _cancelTween = false; local _tweenVersion = 0
local function tweenTo(cf, cancelCheck)
    local hrp=getHRP(); if not hrp then return end
    hrp.AssemblyLinearVelocity=Vector3.zero
    local tweenMode=Library.Options["TweenMode"] and Library.Options["TweenMode"].Value or "Normal"
    local target=cf.Position
    local vim=game:GetService("VirtualInputManager")
    pcall(function() vim:SendKeyEvent(true,Enum.KeyCode.W,false,game) end)
    local function releaseW() pcall(function() vim:SendKeyEvent(false,Enum.KeyCode.W,false,game) end) end
    local _toggleFlight=ReplicatedStorage.Requests:FindFirstChild("ToggleFlight")
    _tweenVersion=_tweenVersion+1; local myVersion=_tweenVersion
    local function doLerp(from, to)
        if (to-from).Magnitude<1 then return true end
        if _toggleFlight then pcall(function() _toggleFlight:FireServer(true) end) end
        local done=false; local success=false; local tweenFrame=CFrame.new(from)
        RS:BindToRenderStep("VVUTween",Enum.RenderPriority.Input.Value,function(dt)
            if _tweenVersion~=myVersion then RS:UnbindFromRenderStep("VVUTween"); done=true; return end
            if _cancelTween then _cancelTween=false; releaseW(); RS:UnbindFromRenderStep("VVUTween"); done=true; return end
            if cancelCheck and cancelCheck() then releaseW(); RS:UnbindFromRenderStep("VVUTween"); done=true; return end
            local c=getChar(); if not c then RS:UnbindFromRenderStep("VVUTween"); done=true; return end
            local h=c:FindFirstChild("HumanoidRootPart"); if not h then RS:UnbindFromRenderStep("VVUTween"); done=true; return end
            local mv=to-tweenFrame.Position
            if mv.Magnitude<=1 then h.AssemblyLinearVelocity=Vector3.zero; h.CFrame=CFrame.new(to,to+(to-from).Unit); success=true; RS:UnbindFromRenderStep("VVUTween"); done=true; return end
            tweenFrame=tweenFrame+mv.Unit*S.tweenSpeed*dt
            local hDir=Vector3.new(mv.X,0,mv.Z); if hDir.Magnitude>0 then tweenFrame=CFrame.new(tweenFrame.Position,tweenFrame.Position+hDir.Unit) end
            h.AssemblyLinearVelocity=Vector3.zero; h.CFrame=tweenFrame
        end)
        while not done do task.wait() end
        if _toggleFlight then pcall(function() _toggleFlight:FireServer(false) end) end
        return success
    end
    if tweenMode=="Normal" then
        local p0=hrp.Position; if doLerp(p0,target) then local h=getHRP(); if h then h.CFrame=cf end end
    elseif tweenMode=="Safe" then
        local height=Library.Options["SafeModeHeight"] and Library.Options["SafeModeHeight"].Value or 1000
        local up1=Vector3.new(hrp.Position.X,target.Y+height,hrp.Position.Z); hrp.CFrame=CFrame.new(up1)
        local up2=Vector3.new(target.X,target.Y+height,target.Z)
        if doLerp(up1,up2) then local h=getHRP(); if h then h.CFrame=cf end end
    end
    releaseW()
end
local _chestTweenVersion=0
local function tweenToChest(cf,cancelCheck)
    local hrp=getHRP(); if not hrp then return end; hrp.AssemblyLinearVelocity=Vector3.zero
    _chestTweenVersion=_chestTweenVersion+1; local myVersion=_chestTweenVersion
    local target=cf.Position; local tweenFrame=CFrame.new(hrp.Position); local done=false
    RS:BindToRenderStep("VVUChestTween",Enum.RenderPriority.Input.Value-1,function(dt)
        if _chestTweenVersion~=myVersion or (cancelCheck and cancelCheck()) then RS:UnbindFromRenderStep("VVUChestTween"); done=true; return end
        local h=getHRP(); if not h then RS:UnbindFromRenderStep("VVUChestTween"); done=true; return end
        local mv=target-tweenFrame.Position
        if mv.Magnitude<=1 then h.CFrame=cf; RS:UnbindFromRenderStep("VVUChestTween"); done=true; return end
        tweenFrame=tweenFrame+mv.Unit*S.tweenSpeed*dt; h.AssemblyLinearVelocity=Vector3.zero; h.CFrame=CFrame.new(tweenFrame.Position)
    end)
    while not done do task.wait() end
end
local _mobTweenVersion=0
local function tweenToMob(cf,cancelCheck)
    local hrp=getHRP(); if not hrp then return end; hrp.AssemblyLinearVelocity=Vector3.zero
    _mobTweenVersion=_mobTweenVersion+1; local myVersion=_mobTweenVersion
    local target=cf.Position; local tweenFrame=CFrame.new(hrp.Position); local done=false
    RS:BindToRenderStep("VVUMobTween",Enum.RenderPriority.Input.Value-2,function(dt)
        if _mobTweenVersion~=myVersion or (cancelCheck and cancelCheck()) then RS:UnbindFromRenderStep("VVUMobTween"); done=true; return end
        local h=getHRP(); if not h then RS:UnbindFromRenderStep("VVUMobTween"); done=true; return end
        local mv=target-tweenFrame.Position
        if mv.Magnitude<=1 then h.CFrame=cf; RS:UnbindFromRenderStep("VVUMobTween"); done=true; return end
        tweenFrame=tweenFrame+mv.Unit*S.tweenSpeed*dt; h.AssemblyLinearVelocity=Vector3.zero; h.CFrame=CFrame.new(tweenFrame.Position)
    end)
    while not done do task.wait() end
end

local function _getStatus() local c=getChar(); if not c then return end; return c:FindFirstChild("Status") end
local function _injectStatus(name) local s=_getStatus(); if not s then return end; if not s:FindFirstChild(name) then local f=Instance.new("Folder"); f.Name=name; f.Parent=s end end
local function _removeStatus(name) local s=_getStatus(); if not s then return end; local v=s:FindFirstChild(name); if v then v:Destroy() end end
local function _getRemote(name) local req=ReplicatedStorage:FindFirstChild("Requests"); return req and req:FindFirstChild(name) end

local _PLACE_NAMES={
    ["6270290407"]="VV: ULTIMATUM",["14321102147"]="Fort Adams",["14218523102"]="Soul Society Outskirts",
    ["9854445386"]="Content Deleted",["15645525857"]="Arctic Cave",["14711269481"]="Arctic Plain (OLD)",
    ["15079707729"]="Arctic Plains",["11131834995"]="Hueco Mundo",["14219489601"]="Human World",
    ["9861495985"]="Inner World",["11127942816"]="Las Noches",["121345602945775"]="Matchmaking",
    ["16914874220"]="Menos Forest",["10627960269"]="OLD.",["18972283841"]="Snow Encampment",
    ["12337012844"]="Soul Society",["17083682617"]="The Dangai",["95787471190312"]="The Marsh",
    ["13229243486"]="Tournament",["102123868363969"]="Trade Realm",["132224751888154"]="UPDATE PLACE",
    ["10626511620"]="Valley of Screams",["18416507779"]="VV TEST ZONE",["11780443293"]="Wandenreich",
}
local function serverHop()
    local placeId=game.PlaceId
    local ok,res=pcall(function() return HS:JSONDecode(game:HttpGet("https://games.roblox.com/v1/games/"..tostring(placeId).."/servers/Public?sortOrder=Asc&limit=100")) end)
    if ok and res then for _,s in ipairs(res.data or {}) do if s.id~=game.JobId and s.playing<s.maxPlayers then launchTP(placeId,s.id); return end end end
    launchTP(placeId,game.JobId)
end

Library:Notify({ Title = "Zero Hub", Description = "VV Ultimatum v2.3 loaded.", Type = "Success", Duration = 4 })

Tog.Fly = CharL:AddToggle("Fly", {
    Text ="Fly", Default=false,
    Callback=function(p)
        if p then
            RS:BindToRenderStep("VVUFly",Enum.RenderPriority.Input.Value,function(dt)
                local c=getChar(); if not c then return end
                local hrp=c:FindFirstChild("HumanoidRootPart"); if not hrp then return end
                if not getgenv()._VVU_flyFrame then getgenv()._VVU_flyFrame=hrp.CFrame end
                local frame=getgenv()._VVU_flyFrame; local cf=Cam.CFrame; local mv=Vector3.zero
                local fmode=Library.Options["FlyMode"] and Library.Options["FlyMode"].Value or "MoveDirection"
                if fmode=="MoveDirection" then
                    local fwd=Vector3.new(cf.LookVector.X,0,cf.LookVector.Z).Unit; local rgt=Vector3.new(cf.RightVector.X,0,cf.RightVector.Z).Unit
                    if UIS:IsKeyDown(Enum.KeyCode.W) then mv=mv+fwd end; if UIS:IsKeyDown(Enum.KeyCode.S) then mv=mv-fwd end
                    if UIS:IsKeyDown(Enum.KeyCode.A) then mv=mv-rgt end; if UIS:IsKeyDown(Enum.KeyCode.D) then mv=mv+rgt end
                else
                    local hum=c:FindFirstChildOfClass("Humanoid")
                    if hum and hum.MoveDirection.Magnitude>0 then
                        local fwd2=Vector3.new(cf.LookVector.X,0,cf.LookVector.Z).Unit; local rgt2=Vector3.new(cf.RightVector.X,0,cf.RightVector.Z).Unit
                        mv=mv+fwd2*hum.MoveDirection:Dot(fwd2)+rgt2*hum.MoveDirection:Dot(rgt2)
                    end
                end
                if UIS:IsKeyDown(Enum.KeyCode.Space)       then mv=mv+Vector3.new(0,1,0) end
                if UIS:IsKeyDown(Enum.KeyCode.LeftControl) then mv=mv-Vector3.new(0,1,0) end
                if mv.Magnitude>0 then frame=frame+mv.Unit*S.flySpeed*dt end
                local fwd3=Vector3.new(cf.LookVector.X,0,cf.LookVector.Z)
                if fwd3.Magnitude>0 then frame=CFrame.new(frame.Position,frame.Position+fwd3.Unit) end
                getgenv()._VVU_flyFrame=frame; hrp.AssemblyLinearVelocity=Vector3.zero; hrp.CFrame=frame
            end)
        else RS:UnbindFromRenderStep("VVUFly"); getgenv()._VVU_flyFrame=nil end
    end})
Opt.FlySpeed = CharL:AddSlider("FlySpeed", { Text ="Fly Speed", Default=100, Min =0, Max =5000, Rounding =0, Callback=function(v) S.flySpeed=v end })
Opt.FlyMode  = CharL:AddDropdown("FlyMode", { Text ="Fly Mode", Values ={"MoveDirection","Camera LookVector"}, Default=1, Multi=false, Callback=function() end })
CharL:AddDivider()
Opt.TweenMode      = CharL:AddDropdown("TweenMode", { Text ="Safe Mode", Values ={"Normal","Safe"}, Default=1, Multi=false, Callback=function() end })
Opt.SafeModeHeight = CharL:AddSlider("SafeModeHeight", { Text ="Safe Height", Default=1000, Min =0, Max =100000, Rounding =0, Callback=function() end })
CharL:AddButton({ Text ="Cancel Tween", Func =function() _cancelTween=true end })
Tog.Speedhack = CharL:AddToggle("Speedhack", {
    Text ="Speedhack", Default=false,
    Callback=function(p)
        if p then RS:BindToRenderStep("VVUSpeed",Enum.RenderPriority.Input.Value,function(dt)
            local c=getChar(); if not c then return end; local hum=c:FindFirstChildOfClass("Humanoid"); if not hum or hum.Health<=0 then return end
            local hrp=c:FindFirstChild("HumanoidRootPart"); if not hrp then return end
            if hum.MoveDirection.Magnitude>0 then hrp.CFrame=hrp.CFrame+hum.MoveDirection*S.speed*dt end
        end) else RS:UnbindFromRenderStep("VVUSpeed") end
    end})
Opt.SpeedhackSpeed = CharL:AddSlider("SpeedhackSpeed", { Text ="Speedhack Speed", Default=100, Min =0, Max =5000, Rounding =0, Callback=function(v) S.speed=v end })
local ijConn=nil
Tog.InfiniteJump = CharL:AddToggle("InfiniteJump", {
    Text ="Infinite Jump", Default=false,
    Callback=function(p)
        if ijConn then ijConn:Disconnect(); ijConn=nil end
        if p then ijConn=UIS.InputBegan:Connect(function(input,gpe)
            if gpe or input.KeyCode~=Enum.KeyCode.Space then return end
            local hrp=getHRP(); if not hrp then return end
            hrp.AssemblyLinearVelocity=Vector3.new(hrp.AssemblyLinearVelocity.X,S.infJumpH,hrp.AssemblyLinearVelocity.Z)
        end) end
    end})
Opt.InfiniteJumpHeight = CharL:AddSlider("InfiniteJumpHeight", { Text ="Jump Height", Default=50, Min =0, Max =1000, Rounding =0, Callback=function(v) S.infJumpH=v end })
local noclipConn=nil
Tog.Noclip = CharL:AddToggle("Noclip", {
    Text ="Noclip", Default=false,
    Callback=function(p)
        if noclipConn then noclipConn:Disconnect(); noclipConn=nil end
        if not p then return end
        local cached={}; local lastChar=nil
        noclipConn=RS.Heartbeat:Connect(function()
            local c=getChar()
            if c~=lastChar then cached={}; lastChar=c; if c then for _,d in ipairs(c:GetDescendants()) do if d:IsA("BasePart") then cached[#cached+1]=d end end end end
            for _,part in ipairs(cached) do if part.Parent then part.CanCollide=false end end
        end)
    end})
CharL:AddDivider()
local MORPHS={
    ["Goku"]       ={hair=96778240725860, shirt=18642081551,    pants=13980707182   },
    ["Naruto"]     ={hair=129818847988995,shirt=6469644436,     pants=2733834231    },
    ["Gojo"]       ={hair=132501783778842,shirt=73084050138865, pants=15312673306   },
    ["Toji"]       ={hair=135664715112347,shirt=121088463088431,pants=16149857407   },
    ["Aizen"]      ={hair=117644781784979,shirt=87853669951881, pants=118029167731205},
    ["Guts"]       ={hair=117337600216775,shirt=13381096342,    pants=13381103162   },
    ["Vasto Lorde"]={hair=107798985962651,shirt=15549196125,    pants=15886594659   },
    ["Luffy"]      ={hair=103832443149308,shirt=8483860912,     pants=6274345723    },
    ["Zero Two"]   ={hair=93023559996037, shirt=6392201226,     pants=5896597102    },
    ["Yoruichi"]   ={hair=80207230854028, face=82588218846528,  shirt=18842292222,  pants=79431307149311},
}
local function clearMorph(char) for _,v in ipairs(char:GetChildren()) do if v:IsA("Accessory") or v:IsA("Hat") or v:IsA("Shirt") or v:IsA("Pants") or v:IsA("ShirtGraphic") then pcall(function() v:Destroy() end) end end end
local function addHair(char,id)
    local head=char:FindFirstChild("Head"); if not head then return end
    pcall(function()
        local objs=game:GetObjects("rbxassetid://"..tostring(id)); if not objs or not objs[1] then return end
        local acc=objs[1]; if not (acc:IsA("Accessory") or acc:IsA("Hat")) then return end
        local handle=acc:FindFirstChild("Handle"); if not handle then return end
        local headAtt=head:FindFirstChild("HairAttachment") or head:FindFirstChild("HatAttachment")
        local handleAtt=handle:FindFirstChild("HairAttachment") or handle:FindFirstChild("HatAttachment") or handle:FindFirstChild("BodyFrontAttachment")
        if headAtt and handleAtt then handle.CFrame=head.CFrame*headAtt.CFrame*handleAtt.CFrame:Inverse()
        else handle.CFrame=head.CFrame*CFrame.new(0,head.Size.Y*0.5+handle.Size.Y*0.3,0) end
        local wc=Instance.new("WeldConstraint"); wc.Part0=head; wc.Part1=handle; wc.Parent=handle
        handle.Anchored=false; acc.Parent=char
    end)
end
local function applyMorph(name)
    local char=LP.Character; if not char then return end
    local def=MORPHS[name]; clearMorph(char)
    local head=char:FindFirstChild("Head")
    if head then
        for _,v in ipairs(head:GetChildren()) do if v:IsA("Decal") then v:Destroy() end end
        if def and def.face then head.Transparency=0; local d=Instance.new("Decal"); d.Texture="rbxassetid://"..tostring(def.face); d.Face=Enum.NormalId.Front; d.Parent=head else head.Transparency=def and 1 or 0 end
    end
    if not def then return end
    if def.shirt then local s=char:FindFirstChildOfClass("Shirt") or Instance.new("Shirt",char); s.ShirtTemplate="rbxassetid://"..tostring(def.shirt) end
    if def.pants then local p=char:FindFirstChildOfClass("Pants") or Instance.new("Pants",char); p.PantsTemplate="rbxassetid://"..tostring(def.pants) end
    addHair(char,def.hair)
end
local morphNames={"None"}; for k in pairs(MORPHS) do table.insert(morphNames,k) end; table.sort(morphNames)
Opt.MorphSelect = CharL2:AddDropdown("MorphSelect", { Text ="Morph", Values =morphNames, Default=1, Multi=false, Callback=function(v) local sel=type(v)=="table" and next(v) or v; task.spawn(function() applyMorph(sel~="None" and sel or nil) end) end })
CharL2:AddButton({ Text ="Reset Morph", Func =function() Library.Options["MorphSelect"]:SetValue(1); task.spawn(function() applyMorph(nil) end) end })
CharL2:AddDivider()
CharR:AddButton({ Text ="Kill Self", Func =function() local hum=getHum(); if hum then hum.Health=0 end end })
CharR:AddDivider()
local noAnimsThread=nil; local forcedTracks={}; local origTracks={}
Tog.NoAnims = CharR:AddToggle("NoAnims", {
    Text ="No Anims", Default=false,
    Callback=function(p)
        if noAnimsThread then task.cancel(noAnimsThread); noAnimsThread=nil end
        if p then
            local c=getChar(); if not c then return end; local hum=c:FindFirstChildOfClass("Humanoid"); if not hum then return end
            local anim=hum:FindFirstChildOfClass("Animator"); if not anim then return end
            local dummy=Instance.new("Animation"); dummy.AnimationId="rbxassetid://109212722752"
            noAnimsThread=task.spawn(function()
                while Tog.NoAnims and Library.Flags["NoAnims"] and Library.Flags["NoAnims"].Value and hum and hum.Parent do
                    for _,track in ipairs(anim:GetPlayingAnimationTracks()) do if track.Animation.AnimationId~=dummy.AnimationId then if not table.find(origTracks,track) then table.insert(origTracks,track) end; pcall(function() track:Stop(); task.defer(track.Destroy,track) end) end end
                    local found=false; for _,track in ipairs(anim:GetPlayingAnimationTracks()) do if track.Animation.AnimationId==dummy.AnimationId then found=true end end
                    if not found then local t=anim:LoadAnimation(dummy); table.insert(forcedTracks,t); t.Priority=Enum.AnimationPriority.Core; t:AdjustSpeed(0); t:Play() end
                    task.wait(0.1)
                end
            end)
        else
            for _,track in pairs(forcedTracks) do pcall(function() track:Stop(); track:Destroy() end) end; forcedTracks={}
            for _,track in pairs(origTracks) do pcall(function() track:Play() end) end; origTracks={}
        end
    end})
;(function()
    local _animSpeedConn=nil; local _animSpeed=1
    local function applyAnimSpeed(speed)
        pcall(function() local char=getChar(); if not char then return end; local hum=char:FindFirstChildOfClass("Humanoid"); if not hum then return end; local anim=hum:FindFirstChildOfClass("Animator"); if not anim then return end; for _,track in ipairs(anim:GetPlayingAnimationTracks()) do pcall(function() track:AdjustSpeed(speed) end) end end)
    end
    Tog.AnimSpeed = CharR:AddToggle("AnimSpeed", { Text ="Anim Speed", Default=false, Callback=function(p) if _animSpeedConn then _animSpeedConn:Disconnect(); _animSpeedConn=nil end; if p then _animSpeedConn=RS.Heartbeat:Connect(function() applyAnimSpeed(_animSpeed) end) else applyAnimSpeed(1) end end })
    Opt.AnimSpeedSlider = CharR:AddSlider("AnimSpeedSlider", { Text ="Speed", Default=1, Min =0.1, Max =200, Rounding =1, Callback=function(v) _animSpeed=v end })
    onUnload(function() if _animSpeedConn then _animSpeedConn:Disconnect(); _animSpeedConn=nil end; applyAnimSpeed(1) end)
end)()
CharR:AddDivider()
local _autoRespLoop=false
Tog.AutoRespawnLoop = CharR:AddToggle("AutoRespawnLoop", { Text ="Auto Respawn", Default=false, Callback=function(p) _autoRespLoop=p; if not p then return end; task.spawn(function() while _autoRespLoop do pcall(function() local btn=LP.PlayerGui.MainUI.HUDContainer.DeathScreen.Options:GetChildren()[3].TextButton; firesignal(btn.MouseButton1Click) end); task.wait(0.1) end end) end })
CharR:AddDivider()
local _savedPos=nil; local _autoTPConn=nil
CharR:AddButton({ Text ="Save Position", Func =function() local hrp=getHRP(); if hrp then _savedPos=hrp.CFrame end end })
CharR:AddButton({ Text ="TP to Saved",   Func =function() if not _savedPos then return end; task.spawn(function() tweenTo(_savedPos) end) end })
CharR:AddDivider()
Opt.AutoTPHP = CharR:AddSlider("AutoTPHP", { Text ="HP Threshold", Default=20, Min =1, Max =99, Rounding =0, Callback=function() end })
local _autoTPing=false
Tog.AutoTPSafe = CharR:AddToggle("AutoTPSafe", { Text ="Auto Retreat", Default=false, Callback=function(p) if _autoTPConn then _autoTPConn:Disconnect(); _autoTPConn=nil end; if not p then return end; _autoTPConn=RS.Heartbeat:Connect(function() if not _savedPos or _autoTPing then return end; local hum=getHum(); if not hum or hum.Health<=0 then return end; if (hum.Health/hum.MaxHealth*100)<=(Library.Options["AutoTPHP"] and Library.Options["AutoTPHP"].Value or 20) then _autoTPing=true; task.spawn(function() tweenTo(_savedPos); _autoTPing=false end) end end) end })
local afkConn=nil; local _afkLoop=false
Tog.AntiAFK = CharR:AddToggle("AntiAFK", { Text ="Anti AFK", Default=true, Callback=function(p)
    if afkConn then afkConn:Disconnect(); afkConn=nil end
    _afkLoop=p
    if not p then return end
    local function nudge()
        pcall(function()
            local VU=game:GetService("VirtualUser")
            VU:Button2Down(Vector2.zero,workspace.CurrentCamera.CFrame)
            task.wait(0.1)
            VU:Button2Up(Vector2.zero,workspace.CurrentCamera.CFrame)
        end)
    end

    afkConn=LP.Idled:Connect(nudge)

    task.spawn(function()
        while _afkLoop do task.wait(240); if _afkLoop then nudge() end end
    end)
end})
CharR:AddDivider()
local _noSlowConn=nil
Tog.NoSlow = CharR2:AddToggle("NoSlow", { Text ="No Slow", Default=false, Callback=function(p) if _noSlowConn then _noSlowConn:Disconnect(); _noSlowConn=nil end; if not p then return end; _noSlowConn=RS.Heartbeat:Connect(function() pcall(function() local s=_getStatus(); if not s then return end; for _,v in ipairs(s:GetChildren()) do local n=v.Name:lower(); if n:find("slow") or n:find("stun") or n:find("freeze") or n:find("root") or n:find("immobil") or n:find("paraly") or n:find("stop") or n:find("bind") or n:find("snare") then pcall(function() v:Destroy() end) end end; local char=LP.Character; local hum=char and char:FindFirstChildOfClass("Humanoid"); if hum and hum.WalkSpeed<16 then hum.WalkSpeed=16 end end) end) end })
onUnload(function() if _noSlowConn then _noSlowConn:Disconnect() end end)
;(function()
    local _tpDeathConn=nil; local _tpDeathPos=nil
    Tog.TPOnDeath = CharR2:AddToggle("TPOnDeath", { Text ="TP Back on Death", Default=false, Callback=function(p)
        if _tpDeathConn then _tpDeathConn:Disconnect(); _tpDeathConn=nil end; if not p then return end
        local function hookChar(char) if not char then return end; local hum=char:WaitForChild("Humanoid",5); if not hum then return end; local hrp=char:WaitForChild("HumanoidRootPart",5); if not hrp then return end; local saveConn=RS.Heartbeat:Connect(function() if hum.Health>0 then _tpDeathPos=hrp.CFrame end end); hum.Died:Connect(function() saveConn:Disconnect(); if not _tpDeathPos then return end; local savedCF=_tpDeathPos; local newChar=LP.CharacterAdded:Wait(); local newHRP=newChar:WaitForChild("HumanoidRootPart",5); if newHRP and Tog.TPOnDeath and Library.Flags["TPOnDeath"] and Library.Flags["TPOnDeath"].Value then newHRP.CFrame=savedCF end end) end
        hookChar(LP.Character); _tpDeathConn=LP.CharacterAdded:Connect(function(char) task.wait(0.1); hookChar(char) end)
    end})
    onUnload(function() if _tpDeathConn then pcall(function() _tpDeathConn:Disconnect() end) end end)
end)()
CharR2:AddDivider()
CharR2:AddLabel("⚠ RAKNET NEEDED TURN IT ON IN YOUR EXECUTOR SETTINGS ⚠")
CharR2:AddLabel("⚠ AFTER ENABLING IT WILL RESET YOU ⚠")
do
    local RakNet = raknet or rnet
    local Hooked = false
    local function Hook(Packet)
        if Packet.PacketId == 0x1B then
            local Buffer = Packet.AsBuffer
            buffer.writeu32(Buffer, 1, 0xFFFFFF)
            Packet:SetData(Buffer)
        end
    end
    Tog.RakNetDesync = CharR2:AddToggle("RakNetDesync", {
        Text ="Invisibility", Default=false,
        Callback=function(p)
            if not RakNet then notify("RakNet not found", 3); Library.Flags["RakNetDesync"]:SetValue(false); return end
            if p and not Hooked then
                RakNet.add_send_hook(Hook)
                Hooked = true
                task.delay(1, function()
                    local hum = LP.Character and LP.Character:FindFirstChildOfClass("Humanoid")
                    if hum then hum.Health = 0 end
                end)
            elseif not p and Hooked then
                RakNet.remove_send_hook(Hook)
                Hooked = false
            end
        end})
    onUnload(function() if Hooked and RakNet then pcall(function() RakNet.remove_send_hook(Hook) end); Hooked=false end end)
end
CharR2:AddDivider()
local aimbotConn=nil; local fovCircle=nil; local aimKeyType="MB2"
local function getFOVScale() return Cam.ViewportSize.Y/2/math.tan(math.rad(Cam.FieldOfView/2)) end
local function getAimTargets() local list={}; if S.targetPlayers then for _,plr in ipairs(PS:GetPlayers()) do if plr~=LP and plr.Character then if not S.teamCheck or not LP.Team or plr.Team~=LP.Team then table.insert(list,plr.Character) end end end end; return list end
local function getAimPart(char) local v=Library.Options["AimPart"] and Library.Options["AimPart"].Value or "Head"; if v=="Head" then return char:FindFirstChild("Head") end; if v=="Torso" then return char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("Torso") end; if v=="Random" then local parts={}; for _,n in ipairs({"Head","HumanoidRootPart","Torso"}) do local p=char:FindFirstChild(n); if p then table.insert(parts,p) end end; return #parts>0 and parts[math.random(1,#parts)] or nil end; return char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("Head") end
local function isVisible(part) if not S.visibleOnly then return true end; local c=getChar(); if not c then return false end; local origin=Cam.CFrame.Position; local params=RaycastParams.new(); params.FilterDescendantsInstances={c}; params.FilterType=Enum.RaycastFilterType.Exclude; local result=workspace:Raycast(origin,(part.Position-origin),params); if not result then return true end; return result.Instance and result.Instance:IsDescendantOf(part.Parent) end
UIS.InputBegan:Connect(function(inp,gpe) if gpe then return end; local n=inp.UserInputType==Enum.UserInputType.MouseButton1 and "MB1" or inp.UserInputType==Enum.UserInputType.MouseButton2 and "MB2" or inp.KeyCode.Name; if n==aimKeyType and S.aimbotMode=="Hold" then S.aimbotActive=true end end)
UIS.InputEnded:Connect(function(inp) local n=inp.UserInputType==Enum.UserInputType.MouseButton1 and "MB1" or inp.UserInputType==Enum.UserInputType.MouseButton2 and "MB2" or inp.KeyCode.Name; if n==aimKeyType and S.aimbotMode=="Hold" then S.aimbotActive=false end end)
Opt.AimbotMode   = CharR3:AddDropdown("AimbotMode", { Text ="Aimbot Mode",   Values ={"Toggle","Hold","Always"}, Default=1, Multi=false, Callback=function(v) S.aimbotMode=type(v)=="table" and next(v) or v; if S.aimbotMode=="Always" then S.aimbotActive=true elseif S.aimbotMode~="Hold" then S.aimbotActive=false end end })
Opt.AimbotMethod = CharR3:AddDropdown("AimbotMethod", { Text ="Aimbot Method", Values ={"Camera","mousemoverel"},   Default=1, Multi=false, Callback=function(v) S.aimbotMethod=type(v)=="table" and next(v) or v end })
Opt.AimPart      = CharR3:AddDropdown("AimPart", { Text ="Aim Part",      Values ={"Head","Torso","Random"},   Default=1, Multi=false, Callback=function() end })
Tog.Aimbot = CharR3:AddToggle("Aimbot", {
    Text ="Aimbot", Default=false,
    Callback=function(p)
        S.aimbotEnabled=p; if aimbotConn then aimbotConn:Disconnect(); aimbotConn=nil end
        if not p then S.aimbotActive=false; return end
        if S.aimbotMode=="Always" then S.aimbotActive=true end
        local accum=Vector2.zero
        aimbotConn=RS.RenderStepped:Connect(function()
            if not S.aimbotActive then return end
            local vpSize=Cam.ViewportSize; local cx=vpSize.X/2+S.aimbotX; local cy=vpSize.Y/2+S.aimbotY
            local fovPx=math.tan(math.rad(S.aimbotFOV/2))*getFOVScale(); local best,bestDist=nil,fovPx
            for _,char in ipairs(getAimTargets()) do
                local part=getAimPart(char); if not part then continue end
                local hum=char:FindFirstChildOfClass("Humanoid"); if not hum or hum.Health<=0 then continue end
                if not isVisible(part) then continue end
                local sp,onScreen=Cam:WorldToViewportPoint(part.Position); if not onScreen then continue end
                local d=((sp.X-cx)^2+(sp.Y-cy)^2)^0.5; if d<bestDist then bestDist=d; best=part end
            end
            if best then
                local target=best.Position
                if S.aimbotX~=0 or S.aimbotY~=0 then local v=Cam:WorldToViewportPoint(target); local shifted=Vector2.new(v.X+S.aimbotX,v.Y+S.aimbotY); local ray=Cam:ViewportPointToRay(shifted.X,shifted.Y); target=ray.Origin+ray.Direction*100 end
                if S.aimbotMethod=="Camera" then local t=math.clamp(S.aimbotSens*0.1,0.01,1); local lv=Cam.CFrame.LookVector:Lerp((target-Cam.CFrame.Position).Unit,t); Cam.CFrame=CFrame.new(Cam.CFrame.Position,Cam.CFrame.Position+lv)
                else local sp2=Cam:WorldToViewportPoint(target); local mouse=UIS:GetMouseLocation(); accum=accum+(Vector2.new(sp2.X,sp2.Y)-mouse)*S.aimbotSens; local cap=10; local clamped=Vector2.new(math.clamp(accum.X,-cap,cap),math.clamp(accum.Y,-cap,cap)); pcall(function() mousemoverel(clamped.X,clamped.Y) end); accum=accum-clamped end
            end
        end)
    end})
Tog.AimbotPlayers = CharR3:AddToggle("AimbotPlayers", { Text ="Target Players", Default=true,  Callback=function(p) S.targetPlayers=p end })
Tog.VisibleOnly   = CharR3:AddToggle("VisibleOnly", { Text ="Visible Only",   Default=false, Callback=function(p) S.visibleOnly=p   end })
Tog.TeamCheck     = CharR3:AddToggle("TeamCheck", { Text ="Team Check",     Default=false, Callback=function(p) S.teamCheck=p     end })
CharR3:AddDivider()
Opt.AimbotSens    = CharR3:AddSlider("AimbotSens", { Text ="Lock Strength",  Default=1,     Min =0.1, Max =5,   Rounding =2, Callback=function(v) S.aimbotSens=v end })
Opt.AimbotXOffset = CharR3:AddSlider("AimbotXOffset", { Text ="X Offset",       Default=0,     Min =-300, Max =300, Rounding =0, Callback=function(v) S.aimbotX=v end })
Opt.AimbotYOffset = CharR3:AddSlider("AimbotYOffset", { Text ="Y Offset",       Default=0,     Min =-300, Max =300, Rounding =0, Callback=function(v) S.aimbotY=v end })
Tog.ShowFOV = CharR3:AddToggle("ShowFOV", { Text ="Show FOV", Default=false, Callback=function(p) if p then if not fovCircle then fovCircle=Drawing.new("Circle"); fovCircle.Thickness=1; fovCircle.NumSides=100; fovCircle.Filled=false; fovCircle.Color=Color3.fromRGB(255,255,255) end; fovCircle.Radius=S.aimbotFOV*getFOVScale(); fovCircle.Position=Vector2.new(Cam.ViewportSize.X/2,Cam.ViewportSize.Y/2); fovCircle.Visible=true elseif fovCircle then fovCircle.Visible=false end end })
Opt.AimbotFOV = CharR3:AddSlider("AimbotFOV", { Text ="Lock FOV", Default=45, Min =1, Max =120, Rounding =0, Callback=function(v) S.aimbotFOV=v; if fovCircle and fovCircle.Visible then fovCircle.Radius=v*getFOVScale() end end })

onUnload(function()
    RS:UnbindFromRenderStep("VVUSpeed")
    RS:UnbindFromRenderStep("VVUFly")
    RS:UnbindFromRenderStep("VVUTween")
    RS:UnbindFromRenderStep("VVUChestTween")
    RS:UnbindFromRenderStep("VVUMobTween")
    getgenv()._VVU_flyFrame=nil

    if noclipConn then noclipConn:Disconnect(); noclipConn=nil end
    local c=getChar(); if c then for _,p in ipairs(c:GetDescendants()) do if p:IsA("BasePart") then pcall(function() p.CanCollide=true end) end end end

    if ijConn then ijConn:Disconnect() end
    if _autoTPConn then _autoTPConn:Disconnect() end
    if afkConn then afkConn:Disconnect() end; _afkLoop=false

    if aimbotConn then aimbotConn:Disconnect() end
    if fovCircle then pcall(function() fovCircle:Remove() end) end

    if noAnimsThread then task.cancel(noAnimsThread); noAnimsThread=nil end
    for _,t in pairs(forcedTracks) do pcall(function() t:Stop(); t:Destroy() end) end; forcedTracks={}
    for _,t in pairs(origTracks) do pcall(function() t:Play() end) end; origTracks={}

    _autoRespLoop=false

    if getgenv()._ZHCrosshair then for _,d in ipairs(getgenv()._ZHCrosshair) do pcall(function() d:Remove() end) end; getgenv()._ZHCrosshair=nil end
end)

local farmState = { plrs=false, plrTarget="", mobs=false, mobTargets={}, croc=false }
local _farmMode="Behind"; local _farmOffX=0; local _farmOffY=0; local _farmOffZ=6.5
local function _calcFarmPos(rp)
    local mp=rp.Position
    local flatLook=Vector3.new(rp.CFrame.LookVector.X,0,rp.CFrame.LookVector.Z).Unit
    local flatRight=Vector3.new(rp.CFrame.RightVector.X,0,rp.CFrame.RightVector.Z).Unit
    local base
    if     _farmMode=="Above"    then base=mp+Vector3.new(0,_farmOffZ,0)
    elseif _farmMode=="Below"    then base=mp+Vector3.new(0,-_farmOffZ,0)
    elseif _farmMode=="In Front" then base=mp+flatLook*_farmOffZ
    else                              base=mp-flatLook*_farmOffZ end
    return base+flatRight*_farmOffX+Vector3.new(0,_farmOffY,0)
end
local farmConns={}
getgenv()._VVU_autoM1=false; getgenv()._VVU_autoCrit=false; getgenv()._VVU_autoEquip=false
getgenv()._VVU_autoRes=false; getgenv()._VVU_autoGrip=false; getgenv()._VVU_combatLoopsStarted=false

-- re-enable combat after respawn if farm is active
LP.CharacterAdded:Connect(function()
    task.wait(2)
    if farmState.mobs or farmState.plrs or farmState.croc then
        enableFarmCombat()
    end
end)
if not getgenv()._VVU_combatLoopsStarted then
    getgenv()._VVU_combatLoopsStarted=true
    local RS2=game:GetService("ReplicatedStorage")
    task.spawn(function() while true do task.wait(0.15); if getgenv()._VVU_autoM1 then pcall(function() RS2.Requests.Combat:FireServer("LightAttack",true,false) end) end end end)
    task.spawn(function() while true do task.wait(0.15); if getgenv()._VVU_autoCrit then pcall(function() RS2.Requests.Combat:FireServer("HeavyAttack",true) end) end end end)
    task.spawn(function()
        while true do task.wait(0.5)
            if getgenv()._VVU_autoGrip then pcall(function()
                local ents=workspace:FindFirstChild("Living"); if not ents then return end
                for _,mob in ipairs(ents:GetChildren()) do
                    if PS:GetPlayerFromCharacter(mob) or mob==LP.Character then continue end
                    local h=mob:FindFirstChildOfClass("Humanoid"); if h and h.Health>0 then
                        RS2.Requests.Grip:FireServer(mob); break
                    end
                end
            end) end
        end
    end)
    task.spawn(function()
        while true do task.wait(0.5)
            if getgenv()._VVU_autoRes then pcall(function()
                local living=workspace:FindFirstChild("Living"); local myModel=living and living:FindFirstChild(LP.Name)
                local status=myModel and myModel:FindFirstChild("Status"); local partialRes=status and status:FindFirstChild("PartialResActive")
                if not (partialRes and partialRes.Value) then RS2.Requests.FastWeaponRelease:FireServer(nil,nil) end
            end) end
        end
    end)
    task.spawn(function()
        while true do task.wait(0.5)
            if getgenv()._VVU_autoEquip then pcall(function()
                local living=workspace:FindFirstChild("Living"); local myModel=living and living:FindFirstChild(LP.Name)
                local status=myModel and myModel:FindFirstChild("Status"); local we=status and status:FindFirstChild("WeaponEquipped")
                if not (we and we.Value) then RS2.Requests.Combat:FireServer("ToggleWeapon") end
            end) end
        end
    end)
end
local function enableFarmCombat()
    getgenv()._VVU_autoEquip=true; getgenv()._VVU_autoM1=true; getgenv()._VVU_autoCrit=true; getgenv()._VVU_autoGrip=true
end
local function disableFarmCombat()
    getgenv()._VVU_autoEquip=false; getgenv()._VVU_autoM1=false; getgenv()._VVU_autoCrit=false; getgenv()._VVU_autoGrip=false
end
local _farmSkillFire=nil

local function getMobType(mob)
    if mob:GetAttribute("Team") == "BossGauntlet" then return "Gauntlet Boss" end
    local ht=mob:GetAttribute("HollowType"); if ht and ht~="" then return tostring(ht) end
    local name = mob.Name:match("^(.-)_[^_]+$") or mob.Name
    if name == "" then return "Unknown NPC" end
    return name
end

local function makeFarmLoop(targetFn, activeKey, killWait)
    local lastTgt=nil; local killCooldown=0; killWait=killWait or 3
    local inPosition=false; local tweening=false
    return RS.Heartbeat:Connect(function()
        if not farmState[activeKey] then return end
        local c=getChar(); if not c then lastTgt=nil; return end
        local hum=c:FindFirstChildOfClass("Humanoid")
        if not hum or not hum.RootPart then lastTgt=nil; return end
        if hum.Health<=0 then lastTgt=nil; killCooldown=0; inPosition=false; tweening=false; disableFarmCombat(); return end
        local hrp=hum.RootPart; hum.Health=hum.MaxHealth
        local tHum=lastTgt and lastTgt:FindFirstChildOfClass("Humanoid")
        local mobDied=lastTgt and (not lastTgt.Parent or not tHum or tHum.Health<=0)
        if not lastTgt or mobDied then
            if mobDied and killCooldown==0 then killCooldown=tick() end
            if killCooldown>0 and tick()-killCooldown<killWait then disableFarmCombat(); return end
            killCooldown=0; lastTgt=targetFn(); inPosition=false; tweening=false
        end
        if not lastTgt then inPosition=false; tweening=false; disableFarmCombat(); pcall(function() if sethiddenproperty then sethiddenproperty(hrp,"PhysicsRepRootPart",nil) end end); return end
        local rp=lastTgt:FindFirstChild("HumanoidRootPart"); if not rp then return end
        if _farmSkillFire then _farmSkillFire() end
        local targetPos=_calcFarmPos(rp)
        local dist=(hrp.Position-targetPos).Magnitude
        local offsetDist=(_farmOffX^2+_farmOffY^2+_farmOffZ^2)^0.5
        if dist>offsetDist+8 then
            inPosition=false; disableFarmCombat()
            if not tweening then
                tweening=true
                task.spawn(function()
                    tweenTo(CFrame.lookAt(_calcFarmPos(rp),rp.Position),function() return not farmState[activeKey] end)
                    tweening=false
                end)
            end
        else
            tweening=false
            if not inPosition then
                inPosition=true
                pcall(function() if sethiddenproperty then sethiddenproperty(hrp,"PhysicsRepRootPart",rp) end end)
            end
            enableFarmCombat()
            hrp.AssemblyLinearVelocity=Vector3.zero
            hrp.AssemblyAngularVelocity=Vector3.zero
            hrp.CFrame=CFrame.lookAt(targetPos,rp.Position)
        end
    end)
end

local function nearestPlayer()
    local hrp=getHRP(); if not hrp then return end
    local best,bestD=nil,math.huge
    for _,plr in ipairs(PS:GetPlayers()) do
        if plr==LP then continue end
        if farmState.plrTarget~="" and plr.Name~=farmState.plrTarget then continue end
        local c=plr.Character; if not c then continue end
        local r=c:FindFirstChild("HumanoidRootPart"); local h=c:FindFirstChildOfClass("Humanoid")
        if not (r and h and h.Health>0) then continue end
        local d=(r.Position-hrp.Position).Magnitude; if d<bestD then best=c; bestD=d end
    end
    return best
end
local function nearestMob()
    local hrp=getHRP(); if not hrp then return end
    local ents=workspace:FindFirstChild("Living"); if not ents then return end
    local best,bestD=nil,math.huge
    local useFilter=next(farmState.mobTargets)~=nil and not farmState.mobTargets["Nearest Mob"]
    for _,mob in ipairs(ents:GetChildren()) do
        if mob==LP.Character then continue end
        if PS:GetPlayerFromCharacter(mob) then continue end
        if mob:GetAttribute("TrainingDummy") then continue end
        local r=mob:FindFirstChild("HumanoidRootPart"); local h=mob:FindFirstChildOfClass("Humanoid")
        if not (r and h and h.Health>0) then continue end
        if useFilter and not farmState.mobTargets[getMobType(mob)] then continue end
        local d=(r.Position-hrp.Position).Magnitude; if d<bestD then best=mob; bestD=d end
    end
    return best
end

;(function()
    local function buildPlrList()
        local list={"Any (Closest)"}
        for _,plr in ipairs(PS:GetPlayers()) do if plr~=LP then table.insert(list,plr.Name) end end
        return list
    end
    Opt.PlrSelect = GameL:AddDropdown("PlrSelect", {
        Text ="Target Player", Values =buildPlrList(), Default=1, Multi=false,
        Callback=function(v)
            local sel=type(v)=="table" and next(v) or v
            farmState.plrTarget=tostring(sel or "")
        end
    })
        GameL:AddButton({ Text ="Refresh Players", Func =function()
        pcall(function() Library.Options["PlrSelect"]:SetValues(buildPlrList()) end)
    end})
end)()
Tog.AutoFarmPlrs = GameL:AddToggle("AutoFarmPlrs", {
    Text ="Farm Players", Default=false,
    Callback=function(p)
        farmState.plrs=p
        if farmConns.plrs then farmConns.plrs:Disconnect(); farmConns.plrs=nil end
        if p then farmConns.plrs=makeFarmLoop(nearestPlayer,"plrs") else disableFarmCombat() end
    end})

local function scanMobList()
    local list={"Nearest Mob"}; local seen={}
    local ents=workspace:FindFirstChild("Living")
    if ents then
        for _,mob in ipairs(ents:GetChildren()) do
            if PS:GetPlayerFromCharacter(mob) or mob==LP.Character then continue end
            if mob:GetAttribute("TrainingDummy") then continue end
            local h=mob:FindFirstChildOfClass("Humanoid"); if not (h and h.Health>0) then continue end
            local t=getMobType(mob); if not seen[t] then table.insert(list,t); seen[t]=true end
        end
        table.sort(list, function(a,b)
            if a=="Nearest Mob" then return true end; if b=="Nearest Mob" then return false end; return a<b
        end)
    end
    return list
end
Opt.MobSelect = GameL2:AddDropdown("MobSelect", {
    Text ="Target Mob", Values =scanMobList(), Default={"Nearest Mob"}, Multi=true,
    Callback=function(v) farmState.mobTargets=(type(v)=="table") and v or {} end
})
GameL2:AddButton({ Text ="Refresh Mobs", Func =function()
    pcall(function() Library.Options["MobSelect"]:SetValues(scanMobList()) end)
end})
Tog.AutoFarmMobs = GameL2:AddToggle("AutoFarmMobs", {
    Text ="Mob Farm", Default=false,
    Callback=function(p)
        farmState.mobs=p
        if farmConns.mobs then farmConns.mobs:Disconnect(); farmConns.mobs=nil end
        if not p then disableFarmCombat(); return end
        local lastTgt,killCooldown,tweening,lastMobType,mobInPosition=nil,0,false,nil,false
        farmConns.mobs=RS.Heartbeat:Connect(function()
            if not farmState.mobs then return end
            local c=getChar(); if not c then lastTgt=nil; tweening=false; return end
            local hum=c:FindFirstChildOfClass("Humanoid"); local hrp=hum and hum.RootPart
            if not hum or not hrp then lastTgt=nil; tweening=false; return end
            if hum.Health<=0 then lastTgt=nil; killCooldown=0; tweening=false; mobInPosition=false; disableFarmCombat(); return end
            local tHum=lastTgt and lastTgt:FindFirstChildOfClass("Humanoid")
            local mobDied=lastTgt and (not lastTgt.Parent or not tHum or tHum.Health<=0)
            if not lastTgt or mobDied then
                if mobDied then

                    if lastTgt then lastMobType=getMobType(lastTgt) end
                    if killCooldown==0 then killCooldown=tick() end
                end
                if killCooldown>0 and tick()-killCooldown<4 then
                    disableFarmCombat()
                    hrp.AssemblyLinearVelocity = Vector3.zero
                    hrp.AssemblyAngularVelocity = Vector3.zero
                    return
                end
                killCooldown=0

                local nextTgt = nil
                if lastMobType then
                    local ents=workspace:FindFirstChild("Living")
                    if ents then
                        local hrpPos=hrp.Position; local best,bestD=nil,math.huge
                        for _,mob in ipairs(ents:GetChildren()) do
                            if mob==LP.Character or PS:GetPlayerFromCharacter(mob) then continue end
                            if mob:GetAttribute("TrainingDummy") then continue end
                            local r=mob:FindFirstChild("HumanoidRootPart"); local h=mob:FindFirstChildOfClass("Humanoid")
                            if not (r and h and h.Health>0) then continue end
                            if getMobType(mob)==lastMobType then
                                local d=(r.Position-hrpPos).Magnitude
                                if d<bestD then best=mob; bestD=d end
                            end
                        end
                        nextTgt=best
                    end
                end
                lastTgt = nextTgt or nearestMob()
                tweening=false; mobInPosition=false
            end
            if not lastTgt then tweening=false; disableFarmCombat(); return end
            local rp=lastTgt:FindFirstChild("HumanoidRootPart"); if not rp then return end
            if _farmSkillFire then _farmSkillFire() end
            local mp=rp.Position
            local flatLook=Vector3.new(rp.CFrame.LookVector.X,0,rp.CFrame.LookVector.Z).Unit
            local flatRight=Vector3.new(rp.CFrame.RightVector.X,0,rp.CFrame.RightVector.Z).Unit
            local base
            if     _farmMode=="Above"    then base=mp+Vector3.new(0,_farmOffZ,0)
            elseif _farmMode=="Below"    then base=mp+Vector3.new(0,-_farmOffZ,0)
            elseif _farmMode=="In Front" then base=mp+flatLook*_farmOffZ
            else                              base=mp-flatLook*_farmOffZ end
            local targetPos=CFrame.new(base+flatRight*_farmOffX+Vector3.new(0,_farmOffY,0))
            local dist=(hrp.Position-targetPos.Position).Magnitude
            local offsetDist=(_farmOffX^2+_farmOffY^2+_farmOffZ^2)^0.5
            local tweenThresh=offsetDist+8
            if dist>tweenThresh then
                disableFarmCombat(); mobInPosition=false
                if not tweening then
                    tweening=true; local snapMob=rp.Position
                    task.spawn(function()
                        pcall(function() tweenToMob(targetPos,function() return not farmState.mobs or (rp.Position-snapMob).Magnitude>3 end) end)
                        tweening=false
                    end)
                end
            else
                tweening=false
                if not mobInPosition then mobInPosition=true end
                pcall(function() if sethiddenproperty then sethiddenproperty(hrp,"PhysicsRepRootPart",rp) end end)
                enableFarmCombat()
                hrp.AssemblyLinearVelocity=Vector3.zero
                hrp.AssemblyAngularVelocity=Vector3.zero
                hrp.CFrame=CFrame.lookAt(targetPos.Position,rp.Position)
            end
        end)
    end})
Opt.TweenSpeed = GameL2:AddSlider("TweenSpeed", { Text ="Tween Speed", Default=100, Min =10, Max =5000, Rounding =0, Callback=function(v) S.tweenSpeed=v end })

-- ═══ GAUNTLET ═══
do
    local _gauntletRunning = false
    local _gauntletConn = nil
    local NetworkManager = require(game.ReplicatedStorage.SharedModules.NetworkManager)

    GameR6:AddLabel("Must be in Fort Adams")

    Opt.GauntletSelect = GameR6:AddDropdown("GauntletSelect", {
        Text ="Gauntlet", Values ={"4 - The Terrible","1 - Dangerous Wanderer","2 - Predator Chain","3 - Unparalleled Strength","5 - The Other Side"},
        Default=1, Multi=false, Callback=function() end
    })

    Tog.AutoGauntlet = GameR6:AddToggle("AutoGauntlet", {
        Text ="Auto Gauntlet Farm", Default=false,
        Callback=function(p)
            _gauntletRunning = p
            if _gauntletConn then _gauntletConn:Disconnect(); _gauntletConn = nil end
            if not p then return end
            local sel = Library.Options["GauntletSelect"] and Library.Options["GauntletSelect"].Value or "4 - The Terrible"
            local id = tonumber(tostring(sel):match("^(%d+)")) or 4
            -- Tween to gauntlet area first
            local spawnFolder = workspace.Debris.GauntletSpawns:FindFirstChild("Albrecht")
            if spawnFolder then
                local sp = spawnFolder:FindFirstChild("1")
                if sp then
                    pcall(function() tweenToMob(CFrame.new(sp.Position + Vector3.new(0, 5, 0)), function() return not _gauntletRunning end) end)
                end
            end
            task.wait(1)
            pcall(function() NetworkManager:FireServer("StartGauntlet", id) end)
            task.wait(2)
            pcall(function() Library.Options["MobSelect"]:SetValues(scanMobList()) end)
            farmState.mobTargets = {["Gauntlet Boss"] = true}
            if not farmState.mobs then
                farmState.mobs = true
                if Tog.AutoFarmMobs then Library.Flags["AutoFarmMobs"]:SetValue(true) end
            end
            notify("Gauntlet " .. id .. " started")
            _gauntletConn = RS.Heartbeat:Connect(function()
                if not _gauntletRunning then return end
                local ents = workspace:FindFirstChild("Living")
                if not ents then return end
                local hasGauntletMob = false
                for _, mob in ipairs(ents:GetChildren()) do
                    if mob:GetAttribute("Team") == "BossGauntlet" then
                        hasGauntletMob = true
                        -- Auto grip: check if mob is knocked via Status.Knocked value
                        local status = mob:FindFirstChild("Status")
                        if status then
                            local knockedVal = status:FindFirstChild("Knocked")
                            if knockedVal and knockedVal:IsA("NumberValue") and knockedVal.Value > 0 then
                                pcall(function() game.ReplicatedStorage.Requests.Grip:FireServer(mob.Name) end)
                            end
                        end
                        break
                    end
                end
                if not hasGauntletMob then
                    task.wait(3)
                    pcall(function()
                        -- Tween back to gauntlet area
                        local spawnFolder = workspace.Debris.GauntletSpawns:FindFirstChild("Albrecht")
                        if spawnFolder then
                            local sp = spawnFolder:FindFirstChild("1")
                            if sp then pcall(function() tweenToMob(CFrame.new(sp.Position + Vector3.new(0, 5, 0)), function() return not _gauntletRunning end) end) end
                        end
                        task.wait(1)
                        NetworkManager:FireServer("StartGauntlet", id)
                        task.wait(2)
                        pcall(function() Library.Options["MobSelect"]:SetValues(scanMobList()) end)
                    end)
                end
            end)
        end})

    -- Standalone auto grip toggle for any knocked mob
    Tog.AutoGrip = GameR6:AddToggle("AutoGrip", {
        Text ="Auto Grip", Default=false,
        Callback=function(p)
            if Connections["AutoGrip"] then Connections["AutoGrip"]:Disconnect(); Connections["AutoGrip"]=nil end
            if not p then return end
            Connections["AutoGrip"] = RS.Heartbeat:Connect(function()
                local ents = workspace:FindFirstChild("Living"); if not ents then return end
                for _, mob in ipairs(ents:GetChildren()) do
                    if PS:GetPlayerFromCharacter(mob) or mob:GetAttribute("TrainingDummy") then continue end
                    local status = mob:FindFirstChild("Status")
                    if status then
                        local knockedVal = status:FindFirstChild("Knocked")
                        if knockedVal and knockedVal:IsA("NumberValue") and knockedVal.Value > 0 then
                            pcall(function() game.ReplicatedStorage.Requests.Grip:FireServer(mob.Name) end)
                        end
                    end
                end
            end)
        end})

    onUnload(function() _gauntletRunning=false; if _gauntletConn then _gauntletConn:Disconnect() end end)
end

;(function()
    local _bossSelected={}
    Opt.BossFarmSelect = GameL2:AddDropdown("BossFarmSelect", {
        Text ="Boss", Values ={"Crocodile King","Argus","Lord Nivis","Nix","Shamballa","Giant Dragonfly","Frigus","The Parasite","Securis","Mammoth Hollow","Calamitas"},
        Default=nil, Multi=true, Callback=function(v) _bossSelected=type(v)=="table" and v or {} end
    })
    local _bossRunning=false; local _bossTweening=false
    local function stopBossFarm()
        _bossRunning=false; _bossTweening=false
        farmState.croc=false; if farmConns.croc then farmConns.croc:Disconnect(); farmConns.croc=nil end
        disableFarmCombat()
    end
    LP.CharacterAdded:Connect(function() task.wait(1); _bossTweening=false end)
    -- Respawn handler: waits for a NEW living character (not the dead body)
    local function waitForRespawn()
        local oldChar=getChar()
        local newChar=nil
        local conn; conn=LP.CharacterAdded:Connect(function(c) newChar=c end)
        local t0=tick()
        while not newChar and tick()-t0<30 do task.wait(0.2) end
        conn:Disconnect()
        if not newChar then newChar=getChar() end
        if newChar then
            local t1=tick()
            while tick()-t1<10 do
                local hum=newChar:FindFirstChildOfClass("Humanoid")
                local hrp=newChar:FindFirstChild("HumanoidRootPart")
                if hum and hrp and hum.Health>0 then break end
                task.wait(0.2)
            end
        end
        task.wait(1)
    end
    local _bossConfigs={
        ["Crocodile King"]={find=function() return workspace.Living and workspace.Living:FindFirstChild("The Crocodile King") end, x=0,y=20.4,z=6.5},
        ["Argus"]          ={find=function() return workspace.Living and workspace.Living:FindFirstChild("Argus") end,           x=4.5,y=11.8,z=6.5},
        ["Lord Nivis"]     ={find=function() return workspace.Living and workspace.Living:FindFirstChild("Lord Nivis") end,      x=0,y=10.6,z=6.5},
        ["Giant Dragonfly"]={find=function() return workspace.Living and workspace.Living:FindFirstChild("Giant Dragonfly") end, x=0,y=14.3,z=6.7},
        ["Frigus"]         ={find=function() return workspace.Living and workspace.Living:FindFirstChild("Frigus") end,          x=-0.2,y=7,z=8.1},
        ["The Parasite"]   ={find=function() return workspace.Living and workspace.Living:FindFirstChild("The Parasite") end,    x=0,y=0,z=6.5},
        ["Securis"]        ={find=function() return workspace.Living and workspace.Living:FindFirstChild("Securis") end,         x=0,y=0,z=6.5},
        ["Mammoth Hollow"] ={find=function() return workspace.Living and workspace.Living:FindFirstChild("Mammoth Hollow") end,  x=14.3,y=50,z=45.8},
        ["Junichiro"]      ={find=function() return workspace.Living and workspace.Living:FindFirstChild("Junichiro") end,       x=0,y=0,z=6.5},
    }
    local function startMultiBossLoop(names)
        local _argusGoneSince=nil; local _argusParked=false
        task.spawn(function()
            while _bossRunning do
                local c=getChar(); local hum=c and c:FindFirstChildOfClass("Humanoid"); local hrp=hum and hum.RootPart
                if not (c and hum and hrp) then task.wait(0.1); continue end
                if hum.Health<=0 then disableFarmCombat(); waitForRespawn(); continue end
                
                local target,offX,offY,offZ
                for _,name in ipairs(names) do
                    local cfg=_bossConfigs[name]; if not cfg then continue end
                    local t=cfg.find(); if not t then continue end
                    local bHum=t:FindFirstChildOfClass("Humanoid")
                    if bHum and bHum.Health>0 then target=t; offX=cfg.x; offY=cfg.y; offZ=cfg.z; break end
                end
                
                if not target then
                    disableFarmCombat(); _bossTweening=false
                    -- Argus spawn-park: if Argus is selected but not spawned, tween to spawn after 5s
                    local argusSelected=false
                    for _,n in ipairs(names) do if n=="Argus" then argusSelected=true; break end end
                    if argusSelected then
                        if not _argusGoneSince then _argusGoneSince=tick(); _argusParked=false end
                        if tick()-_argusGoneSince>=2 and not _argusParked then
                            _argusParked=true
                            local parkPos=CFrame.new(-1913.26025390625, 536.9530639648438, -2540.353759765625)
                            task.spawn(function()
                                pcall(function() tweenToMob(parkPos, function()
                                    if not _bossRunning then return true end
                                    if workspace.Living and workspace.Living:FindFirstChild("Argus") then return true end
                                    return false
                                end) end)
                            end)
                        end
                    else
                        _argusGoneSince=nil; _argusParked=false
                    end
                    task.wait(0.1); continue
                end
                _argusGoneSince=nil; _argusParked=false
                
                local rp=target:FindFirstChild("HumanoidRootPart"); if not rp then task.wait(0.1); continue end
                local mp=rp.Position
                local flatLook=Vector3.new(rp.CFrame.LookVector.X,0,rp.CFrame.LookVector.Z).Unit
                local flatRight=Vector3.new(rp.CFrame.RightVector.X,0,rp.CFrame.RightVector.Z).Unit
                local targetPos=CFrame.new(mp - flatLook*offZ + flatRight*offX + Vector3.new(0,offY,0))
                local dist=(hrp.Position-targetPos.Position).Magnitude
                local bossOffDist=(offX^2+offY^2+offZ^2)^0.5
                
                if dist>bossOffDist+8 then
                    disableFarmCombat()
                    if not _bossTweening then
                        _bossTweening=true
                        task.spawn(function() pcall(function() tweenToMob(targetPos,function() return not _bossRunning end) end); _bossTweening=false end)
                    end
                else
                    _bossTweening=false; enableFarmCombat()
                    hrp.AssemblyLinearVelocity=Vector3.zero; hrp.AssemblyAngularVelocity=Vector3.zero
                    pcall(function() if sethiddenproperty then sethiddenproperty(hrp,"PhysicsRepRootPart",rp) end end)
                    hrp.CFrame=CFrame.lookAt(targetPos.Position,rp.Position)
                end
                task.wait()
            end
        end)
    end
    local _DODGE_ANIMS={
        ["rbxassetid://17838591203"]=2.5,["rbxassetid://17838591987"]=2.5,
        ["rbxassetid://17838592800"]=2.5,["rbxassetid://17838593550"]=2.5,
    }
    Tog.BossFarm = GameL2:AddToggle("BossFarm", {
        Text ="Boss Farm", Default=false,
        Callback=function(p)
            stopBossFarm()
            if not p then return end
            _bossRunning=true
            local names={}; for name,on in pairs(_bossSelected) do if on then table.insert(names,name) end end
            if #names==0 then notify("Select a boss first",3); _bossRunning=false; return end
            local hasCal=_bossSelected["Calamitas"]; local hasNix=_bossSelected["Nix"]; local hasGiantDragonfly=_bossSelected["Giant Dragonfly"]; local nonSpecial={}
            for _,n in ipairs(names) do if n~="Calamitas" and n~="Nix" and n~="Giant Dragonfly" and n~="Lord Nivis" then table.insert(nonSpecial,n) end end
            if #nonSpecial>0 then startMultiBossLoop(nonSpecial) end
            if hasNix then
                task.spawn(function()
                    local vim=game:GetService("VirtualInputManager")
                    local function hasShard()
                        return LP.Backpack:FindFirstChild("Frostvein Shard")
                            or (LP.Character and LP.Character:FindFirstChild("Frostvein Shard"))
                    end
                    local nixHealCF=CFrame.new(-2197.20751953125,497.1107177734375,1397.9189453125)
                    local spawnCF=CFrame.new(-2410.928466796875,266.1025085449219,992.0736694335938)

                    while _bossRunning do
                        -- Phase 1: farm BearHollow/PantherHollow until shard
                        if not hasShard() then
                            while _bossRunning and not hasShard() do
                                local living=workspace:FindFirstChild("Living")
                                if living and living:FindFirstChild("Nix") then break end
                                local c=getChar(); local hum=c and c:FindFirstChildOfClass("Humanoid"); local hrp=hum and hum.RootPart
                                if not (c and hum and hrp) then task.wait(0.1); continue end
                                if hum.Health<=0 then disableFarmCombat(); waitForRespawn(); continue end
                                local target,bestD=nil,math.huge
                                if living then
                                    for _,mob in ipairs(living:GetChildren()) do
                                        if PS:GetPlayerFromCharacter(mob) then continue end
                                        if mob:GetAttribute("HollowType")~="BearHollow" then continue end
                                        local r=mob:FindFirstChild("HumanoidRootPart"); local h=mob:FindFirstChildOfClass("Humanoid")
                                        if not (r and h and h.Health>0) then continue end
                                        local d=(r.Position-hrp.Position).Magnitude
                                        if d<bestD then target=mob; bestD=d end
                                    end
                                    if not target then
                                        for _,mob in ipairs(living:GetChildren()) do
                                            if PS:GetPlayerFromCharacter(mob) then continue end
                                            if mob:GetAttribute("HollowType")~="PantherHollow" then continue end
                                            local r=mob:FindFirstChild("HumanoidRootPart"); local h=mob:FindFirstChildOfClass("Humanoid")
                                            if not (r and h and h.Health>0) then continue end
                                            local d=(r.Position-hrp.Position).Magnitude
                                            if d<bestD then target=mob; bestD=d end
                                        end
                                    end
                                end
                                if not target then disableFarmCombat(); task.wait(0.5); continue end
                                local rp=target:FindFirstChild("HumanoidRootPart"); if not rp then task.wait(0.1); continue end
                                local targetCF=rp.CFrame*CFrame.new(0,0,4)
                                local dist=(hrp.Position-targetCF.Position).Magnitude
                                if dist>10 then
                                    disableFarmCombat()
                                    if not _bossTweening then
                                        _bossTweening=true
                                        task.spawn(function()
                                            pcall(function() tweenToMob(targetCF,function() return not _bossRunning or hasShard() end) end)
                                            _bossTweening=false
                                        end)
                                    end
                                else
                                    _bossTweening=false; enableFarmCombat()
                                    hrp.AssemblyLinearVelocity=Vector3.zero; hrp.AssemblyAngularVelocity=Vector3.zero
                                    pcall(function() if sethiddenproperty then sethiddenproperty(hrp,"PhysicsRepRootPart",rp) end end)
                                    hrp.CFrame=CFrame.lookAt(targetCF.Position,rp.Position)
                                end
                                task.wait()
                            end
                        end
                        if not _bossRunning then break end

                        -- Phase 2+3: tween to spawn, equip shard, spam T until Nix spawns
                        local living=workspace:FindFirstChild("Living")
                        if not (living and living:FindFirstChild("Nix")) then
                            disableFarmCombat(); _bossTweening=false
                            pcall(function() tweenToMob(spawnCF,function() return not _bossRunning end) end)
                            if not _bossRunning then break end
                            local eHum=LP.Character and LP.Character:FindFirstChildOfClass("Humanoid")
                            if eHum then
                                for _=1,5 do
                                    if LP.Character and LP.Character:FindFirstChild("Frostvein Shard") then break end
                                    local shard=LP.Backpack:FindFirstChild("Frostvein Shard")
                                    if shard then pcall(function() eHum:EquipTool(shard) end) end
                                    task.wait(0.3)
                                end
                            end
                            -- keep spamming T until Nix spawns, tween back if drifted
                            while _bossRunning do
                                local l=workspace:FindFirstChild("Living")
                                if l and l:FindFirstChild("Nix") then break end
                                local h=getHRP()
                                if h and (h.Position-spawnCF.Position).Magnitude>5 then
                                    pcall(function() tweenToMob(spawnCF,function() return not _bossRunning or (workspace:FindFirstChild("Living") and workspace.Living:FindFirstChild("Nix")) end) end)
                                end
                                pcall(function() vim:SendKeyEvent(true,Enum.KeyCode.T,false,game); task.wait(0.05); vim:SendKeyEvent(false,Enum.KeyCode.T,false,game) end)
                                task.wait(0.3)
                            end
                        end
                        if not _bossRunning then break end

                        local _nixOrbiting=false; local _nixOrbitAngle=0
                        -- animation detector for orbit dodge
                        task.spawn(function()
                            local NIX_DODGE_ANIM="127359882437058"
                            local _lastNixDodge=nil
                            while _bossRunning do
                                pcall(function()
                                    if _nixOrbiting then return end
                                    local nix=workspace.Living and workspace.Living:FindFirstChild("Nix"); if not nix then return end
                                    local nixHum=nix:FindFirstChildOfClass("Humanoid"); local anim=nixHum and nixHum:FindFirstChildOfClass("Animator"); if not anim then return end
                                    for _,t in ipairs(anim:GetPlayingAnimationTracks()) do
                                        local id=tostring(t.Animation.AnimationId):match("%d+$")
                                        if id==NIX_DODGE_ANIM and _lastNixDodge~=id then
                                            _lastNixDodge=id; _nixOrbiting=true
                                            task.delay(4,function() _nixOrbiting=false; task.delay(2,function() if _lastNixDodge==id then _lastNixDodge=nil end end) end)
                                            break
                                        end
                                    end
                                end)
                                task.wait(0.05)
                            end
                        end)
                        -- Phase 5: farm Nix, retreat on low HP, loop back when Nix dies
                        while _bossRunning do
                            local c=getChar(); local hum=c and c:FindFirstChildOfClass("Humanoid"); local hrp=hum and hum.RootPart
                            if not (c and hum and hrp) then task.wait(0.1); continue end
                            if hum.Health<=0 then disableFarmCombat(); waitForRespawn(); continue end
                            if _nixOrbiting then
                                disableFarmCombat(); _bossTweening=false
                                local nix2=workspace.Living and workspace.Living:FindFirstChild("Nix")
                                local rp2=nix2 and nix2:FindFirstChild("HumanoidRootPart")
                                if rp2 then
                                    _nixOrbitAngle=_nixOrbitAngle+15*task.wait()
                                    local ox=rp2.Position.X+math.cos(_nixOrbitAngle)*25
                                    local oz=rp2.Position.Z+math.sin(_nixOrbitAngle)*25
                                    hrp.AssemblyLinearVelocity=Vector3.zero; hrp.AssemblyAngularVelocity=Vector3.zero
                                    hrp.CFrame=CFrame.new(ox,rp2.Position.Y+24.8,oz)*CFrame.Angles(0,-_nixOrbitAngle,0)
                                else task.wait(0.1) end
                                continue
                            end
                            local nix=workspace.Living and workspace.Living:FindFirstChild("Nix")
                            if not nix then
                                -- Nix died - wait for chest to be taken before farming for next shard
                                disableFarmCombat(); _bossTweening=false
                                local chestTaken=false
                                local startWait=os.clock()
                                while not chestTaken and (os.clock()-startWait)<10 do
                                    if not workspace.DialogueInteractables:FindFirstChildOfClass("Model") then
                                        chestTaken=true; break
                                    end
                                    task.wait(0.1)
                                end
                                task.wait(1); break
                            end
                            local rp=nix:FindFirstChild("HumanoidRootPart"); if not rp then task.wait(0.1); continue end
                            local targetPos=rp.CFrame*CFrame.new(0,24.8,17.1)
                            local dist=(hrp.Position-targetPos.Position).Magnitude
                            if dist>10 then
                                disableFarmCombat()
                                if not _bossTweening then
                                    _bossTweening=true
                                    task.spawn(function() pcall(function() tweenToMob(targetPos,function() return not _bossRunning end) end); _bossTweening=false end)
                                end
                            else
                                _bossTweening=false; enableFarmCombat()
                                hrp.AssemblyLinearVelocity=Vector3.zero; hrp.AssemblyAngularVelocity=Vector3.zero
                                pcall(function() if sethiddenproperty then sethiddenproperty(hrp,"PhysicsRepRootPart",rp) end end)
                                hrp.CFrame=CFrame.lookAt(targetPos.Position,rp.Position)
                            end
                            task.wait()
                        end
                    end
                end)
            end
            local hasCal = _bossSelected["Calamitas"]
            if hasCal then
                task.spawn(function()
                    local CAL_DODGE_ANIMS={
                        ["123027684175200"]=true,["104549708275048"]=true,
                        ["126948192880374"]=true,["123903488088917"]=true
                    }
                    -- dodge animation remover
                    task.spawn(function()
                        while _bossRunning do
                            pcall(function()
                                local cal=workspace.Living and workspace.Living:FindFirstChild("Calamitas"); if not cal then return end
                                local calHum=cal:FindFirstChildOfClass("Humanoid"); if not calHum then return end
                                local animator=calHum:FindFirstChildOfClass("Animator"); if not animator then return end
                                for _,t in ipairs(animator:GetPlayingAnimationTracks()) do
                                    local id=tostring(t.Animation.AnimationId):match("%d+$")
                                    if id and CAL_DODGE_ANIMS[id] then
                                        pcall(function() t:Stop(0) end)
                                        pcall(function() t:AdjustSpeed(0) end)
                                    end
                                end
                            end)
                            task.wait(0.05)
                        end
                    end)
                    -- farm Calamitas: fixed offset
                    while _bossRunning do
                        local c=getChar(); local hum=c and c:FindFirstChildOfClass("Humanoid"); local hrp=hum and hum.RootPart
                        if not (c and hum and hrp) then task.wait(0.1); continue end
                        if hum.Health<=0 then disableFarmCombat(); waitForRespawn(); continue end
                        local cal=workspace.Living and workspace.Living:FindFirstChild("Calamitas")
                        if not cal then
                            disableFarmCombat(); _bossTweening=false; task.wait(1); break
                        end
                        local rp=cal:FindFirstChild("HumanoidRootPart"); if not rp then task.wait(0.1); continue end
                        local targetPos=CFrame.new(rp.Position.X - 1.2, rp.Position.Y + 30.5, rp.Position.Z + 12.6)
                        local dist=(hrp.Position-targetPos.Position).Magnitude
                        if dist>10 then
                            disableFarmCombat()
                            if not _bossTweening then
                                _bossTweening=true
                                task.spawn(function() pcall(function() tweenToMob(targetPos,function() return not _bossRunning end) end); _bossTweening=false end)
                            end
                        else
                            _bossTweening=false; enableFarmCombat()
                            hrp.AssemblyLinearVelocity=Vector3.zero; hrp.AssemblyAngularVelocity=Vector3.zero
                            pcall(function() if sethiddenproperty then sethiddenproperty(hrp,"PhysicsRepRootPart",rp) end end)
                            hrp.CFrame=CFrame.lookAt(targetPos.Position,rp.Position)
                        end
                        task.wait()
                    end
                end)
            end
            if hasGiantDragonfly then
                task.spawn(function()
                    local _dragonOrbiting=false; local _dragonOrbitAngle=0
                    -- animation detector for orbit dodge
                    task.spawn(function()
                        local DRAGON_DODGE_ANIM="115495827589598"
                        local _lastDragonDodge=nil
                        while _bossRunning do
                            pcall(function()
                                if _dragonOrbiting then return end
                                local dragon=workspace.Living and workspace.Living:FindFirstChild("Giant Dragonfly"); if not dragon then return end
                                local dragonHum=dragon:FindFirstChildOfClass("Humanoid"); local anim=dragonHum and dragonHum:FindFirstChildOfClass("Animator"); if not anim then return end
                                for _,t in ipairs(anim:GetPlayingAnimationTracks()) do
                                    local id=tostring(t.Animation.AnimationId):match("%d+$")
                                    if id==DRAGON_DODGE_ANIM and _lastDragonDodge~=id then
                                        _lastDragonDodge=id; _dragonOrbiting=true
                                        task.delay(3,function() _dragonOrbiting=false; task.delay(2,function() if _lastDragonDodge==id then _lastDragonDodge=nil end end) end)
                                        break
                                    end
                                end
                            end)
                            task.wait(0.05)
                        end
                    end)
                    -- farm Giant Dragonfly, orbit dodge on animation
                    while _bossRunning do
                        local c=getChar(); local hum=c and c:FindFirstChildOfClass("Humanoid"); local hrp=hum and hum.RootPart
                        if not (c and hum and hrp) then task.wait(0.1); continue end
                        if hum.Health<=0 then disableFarmCombat(); waitForRespawn(); continue end
                        if _dragonOrbiting then
                            disableFarmCombat(); _bossTweening=false
                            local dragon=workspace.Living and workspace.Living:FindFirstChild("Giant Dragonfly")
                            local rp=dragon and dragon:FindFirstChild("HumanoidRootPart")
                            if rp then
                                _dragonOrbitAngle=_dragonOrbitAngle+15*task.wait()
                                local ox=rp.Position.X+math.cos(_dragonOrbitAngle)*25
                                local oz=rp.Position.Z+math.sin(_dragonOrbitAngle)*25
                                hrp.AssemblyLinearVelocity=Vector3.zero; hrp.AssemblyAngularVelocity=Vector3.zero
                                hrp.CFrame=CFrame.new(ox,48,oz)*CFrame.Angles(0,-_dragonOrbitAngle,0)
                            else task.wait(0.1) end
                            continue
                        end
                        local dragon=workspace.Living and workspace.Living:FindFirstChild("Giant Dragonfly")
                        if not dragon then
                            disableFarmCombat(); _bossTweening=false; task.wait(1); break
                        end
                        local rp=dragon:FindFirstChild("HumanoidRootPart"); if not rp then task.wait(0.1); continue end
                        local targetPos=rp.CFrame*CFrame.new(0,14.3,6.7)
                        local dist=(hrp.Position-targetPos.Position).Magnitude
                        if dist>10 then
                            disableFarmCombat()
                            if not _bossTweening then
                                _bossTweening=true
                                task.spawn(function() pcall(function() tweenToMob(targetPos,function() return not _bossRunning end) end); _bossTweening=false end)
                            end
                        else
                            _bossTweening=false; enableFarmCombat()
                            hrp.AssemblyLinearVelocity=Vector3.zero; hrp.AssemblyAngularVelocity=Vector3.zero
                            pcall(function() if sethiddenproperty then sethiddenproperty(hrp,"PhysicsRepRootPart",rp) end end)
                            hrp.CFrame=CFrame.lookAt(targetPos.Position,rp.Position)
                        end
                        task.wait()
                    end
                end)
            end
            local hasLordNivis=_bossSelected["Lord Nivis"]
            if hasLordNivis then
                task.spawn(function()
                    local _nivisOrbiting=false; local _nivisOrbitAngle=0
                    -- animation detector for orbit dodge
                    task.spawn(function()
                        local NIVIS_DODGE_ANIMS={
                            ["121890671665317"]=3,
                            ["83118719637202"]=5,
                            ["86978856932820"]=1.6,
                            ["99036187968467"]=2.88,
                        }
                        local _lastNivisDodge=nil
                        while _bossRunning do
                            pcall(function()
                                if _nivisOrbiting then return end
                                local nivis=workspace.Living and workspace.Living:FindFirstChild("Lord Nivis"); if not nivis then return end
                                local nivisHum=nivis:FindFirstChildOfClass("Humanoid"); local anim=nivisHum and nivisHum:FindFirstChildOfClass("Animator"); if not anim then return end
                                for _,t in ipairs(anim:GetPlayingAnimationTracks()) do
                                    local id=tostring(t.Animation.AnimationId):match("%d+$")
                                    if NIVIS_DODGE_ANIMS[id] and _lastNivisDodge~=id then
                                        _lastNivisDodge=id; _nivisOrbiting=true
                                        local orbitDur=NIVIS_DODGE_ANIMS[id]
                                        task.delay(orbitDur,function() _nivisOrbiting=false; task.delay(2,function() if _lastNivisDodge==id then _lastNivisDodge=nil end end) end)
                                        break
                                    end
                                end
                            end)
                            task.wait(0.05)
                        end
                    end)
                    -- farm Lord Nivis, orbit dodge on animation
                    while _bossRunning do
                        local c=getChar(); local hum=c and c:FindFirstChildOfClass("Humanoid"); local hrp=hum and hum.RootPart
                        if not (c and hum and hrp) then task.wait(0.1); continue end
                        if hum.Health<=0 then disableFarmCombat(); waitForRespawn(); continue end
                        if _nivisOrbiting then
                            disableFarmCombat(); _bossTweening=false
                            local nivis=workspace.Living and workspace.Living:FindFirstChild("Lord Nivis")
                            local rp=nivis and nivis:FindFirstChild("HumanoidRootPart")
                            if rp then
                                _nivisOrbitAngle=_nivisOrbitAngle+15*task.wait()
                                local ox=rp.Position.X+math.cos(_nivisOrbitAngle)*25
                                local oz=rp.Position.Z+math.sin(_nivisOrbitAngle)*25
                                hrp.AssemblyLinearVelocity=Vector3.zero; hrp.AssemblyAngularVelocity=Vector3.zero
                                hrp.CFrame=CFrame.new(ox,rp.Position.Y+25,oz)*CFrame.Angles(0,-_nivisOrbitAngle,0)
                            else task.wait(0.1) end
                            continue
                        end
                        local nivis=workspace.Living and workspace.Living:FindFirstChild("Lord Nivis")
                        if not nivis then
                            disableFarmCombat(); _bossTweening=false; task.wait(1); break
                        end
                        local rp=nivis:FindFirstChild("HumanoidRootPart"); if not rp then task.wait(0.1); continue end
                        local targetPos=rp.CFrame*CFrame.new(0,10.6,6.5)
                        local dist=(hrp.Position-targetPos.Position).Magnitude
                        if dist>10 then
                            disableFarmCombat()
                            if not _bossTweening then
                                _bossTweening=true
                                task.spawn(function() pcall(function() tweenToMob(targetPos,function() return not _bossRunning end) end); _bossTweening=false end)
                            end
                        else
                            _bossTweening=false; enableFarmCombat()
                            hrp.AssemblyLinearVelocity=Vector3.zero; hrp.AssemblyAngularVelocity=Vector3.zero
                            pcall(function() if sethiddenproperty then sethiddenproperty(hrp,"PhysicsRepRootPart",rp) end end)
                            hrp.CFrame=CFrame.lookAt(targetPos.Position,rp.Position)
                        end
                        task.wait()
                    end
                end)
            end
        end})
    onUnload(function() stopBossFarm() end)
end)()

Tog.AutoTakeBossChest = GameL2:AddToggle("AutoTakeBossChest", {
    Text ="Auto Boss Chest", Default=false,
    Callback=function(p)
        local _running=p
        if not p then return end
        local function getMyNames()
            local names={LP.Name}
            pcall(function() if LP.DisplayName~="" and LP.DisplayName~=LP.Name then table.insert(names,LP.DisplayName) end end)
            pcall(function()
                local cn=LP.PlayerGui.MainUI.HUDContainer.TopLeftDetailsContainer.PlayerName.ContentText
                if cn and cn~="" then table.insert(names,cn) end
            end)
            return names
        end
        local function isMyChest(m)
            local ok,cn=pcall(function() return m.ChestUI.Container.PlayerName.ContentText end)
            if not ok or not cn or cn=="" then return true end -- can't tell, assume ours
            local myNames=getMyNames()
            for _,n in ipairs(myNames) do if cn:find(n,1,true) then return true end end
            return false
        end
        local function collectChest(m)
            -- method 1: RemoteEvent
            for _,v in ipairs(m:GetDescendants()) do
                if v:IsA("RemoteEvent") then pcall(function() v:FireServer("Take","All") end); pcall(function() v:FireServer() end) end
            end
            -- method 2: ProximityPrompt
            for _,v in ipairs(m:GetDescendants()) do
                if v:IsA("ProximityPrompt") then pcall(function() fireproximityprompt(v) end) end
            end
            -- method 3: ClickDetector
            local hrp=getHRP()
            for _,v in ipairs(m:GetDescendants()) do
                if v:IsA("ClickDetector") then
                    pcall(function() fireclickdetector(v) end)
                    if hrp and v.Parent then pcall(function() firetouchinterest(hrp,v.Parent,0) end) end
                end
            end
            -- method 4: touch
            if hrp then
                for _,v in ipairs(m:GetDescendants()) do
                    if v:IsA("BasePart") then pcall(function() firetouchinterest(hrp,v,0) end); pcall(function() firetouchinterest(hrp,v,1) end) end
                end
            end
        end
        -- loop 1: spam collect on all interactables
        task.spawn(function()
            while _running and Library.Flags["AutoTakeBossChest"] and Library.Flags["AutoTakeBossChest"].Value do
                pcall(function()
                    local di=workspace:FindFirstChild("DialogueInteractables"); if not di then return end
                    for _,child in ipairs(di:GetChildren()) do
                        local re=child:FindFirstChildOfClass("RemoteEvent"); if re then pcall(function() re:FireServer("Take","All") end) end
                    end
                end); task.wait(0.1)
            end
        end)
        -- loop 2: find & tween to chests
        task.spawn(function()
            local _hadChests=false; local _lastMoveTick=0; local _chestSeen={}
            while _running and Library.Flags["AutoTakeBossChest"] and Library.Flags["AutoTakeBossChest"].Value do
                pcall(function()
                    local hrp=getHRP(); if not hrp then return end
                    local di=workspace:FindFirstChild("DialogueInteractables"); if not di then return end
                    local foundChest=false
                    for _,m in ipairs(di:GetChildren()) do
                        if not Library.Flags["AutoTakeBossChest"] and Library.Flags["AutoTakeBossChest"].Value then return end
                        if not (m:IsA("Model") and m.Name:find("Chest") and m.Parent) then continue end
                        local pp=m.PrimaryPart or m:FindFirstChildWhichIsA("BasePart")
                        if not pp or (hrp.Position-pp.Position).Magnitude>300 then continue end
                        foundChest=true
                        if not _chestSeen[m] then _chestSeen[m]=tick() end
                        if tick()-_chestSeen[m]<0.5 then continue end
                        collectChest(m)
                        local timedOut=false; local timer=task.delay(3,function() timedOut=true end)
                        pcall(function() tweenToChest(pp.CFrame*CFrame.new(0,3,0),function() return not Library.Flags["AutoTakeBossChest"] and Library.Flags["AutoTakeBossChest"].Value or not pp.Parent or timedOut end) end)
                        task.cancel(timer)
                        if m.Parent then collectChest(m) end
                    end
                    if foundChest then _hadChests=true
                    elseif _hadChests and tick()-_lastMoveTick>3 then
                        _hadChests=false; _lastMoveTick=tick(); _chestSeen={}
                        local leftPos=hrp.Position-hrp.CFrame.RightVector*30
                        task.spawn(function() pcall(function() tweenToChest(CFrame.new(leftPos),function() return not Library.Flags["AutoTakeBossChest"] and Library.Flags["AutoTakeBossChest"].Value end) end) end)
                    end
                end); task.wait(0.1)
            end
        end)
    end})
;(function()
    local _eatConn=nil
    Tog.AutoEatPart = GameL2:AddToggle("AutoEatPart", {
        Text ="Auto Eat Hollow Part", Default=false,
        Callback=function(p)
            if _eatConn then _eatConn:Disconnect(); _eatConn=nil end
            if not p then return end
            _eatConn=RS.Heartbeat:Connect(function()
                local hrp=getHRP(); if not hrp then return end
                local best,bestDist=nil,20
                local root=workspace:FindFirstChild("Debris") or workspace
                for _,v in ipairs(root:GetDescendants()) do
                    if not v:IsA("ProximityPrompt") then continue end
                    local pp=v.Parent; if not (pp and pp:IsA("BasePart")) then continue end
                    local dist=(hrp.Position-pp.Position).Magnitude
                    if dist<bestDist then best=v; bestDist=dist end
end
                if best then pcall(function() fireproximityprompt(best) end) end
            end)
        end})
    onUnload(function() if _eatConn then _eatConn:Disconnect() end end)
end)()

local _chestRunning=false
Tog.ChestTPEnabled = NavL3:AddToggle("ChestTPEnabled", {
    Text ="Chest Farm", Default=false,
    Callback=function(p)
        _chestRunning=p
        if not p then return end
        task.spawn(function()
            while _chestRunning do
                local di=workspace:FindFirstChild("DialogueInteractables")
                if not di then task.wait(2); continue end
                local chests={}
                for _,v in ipairs(di:GetChildren()) do
                    if v:IsA("Model") and v.Name:find("ChestTemplate") then table.insert(chests,v) end
                end
                if #chests==0 then task.wait(2); continue end
                for _,chest in ipairs(chests) do
                    if not _chestRunning then break end
                    if not chest or not chest.Parent then continue end
                    local hrp=getHRP(); if not hrp then break end
                    local pp=chest.PrimaryPart or chest:FindFirstChildWhichIsA("BasePart")
                    if not pp or not pp.Parent then continue end
                    -- try RemoteEvent first (same as boss chest farm)
                    local re=chest:FindFirstChildOfClass("RemoteEvent")
                    if re then
                        pcall(function() re:FireServer("Take","All") end)
                    else
                        -- fall back: tween to chest and fire prompts
                        pcall(function() tweenTo(pp.CFrame*CFrame.new(0,3,0),function() return not _chestRunning end) end)
                        if not chest.Parent then continue end
                        task.wait(0.3)
                        pcall(function()
                            if not chest.Parent then return end
                            for _,v in ipairs(chest:GetDescendants()) do
                                if v:IsA("ProximityPrompt") then fireproximityprompt(v)
                                elseif v:IsA("ClickDetector") then firetouchinterest(hrp,v.Parent,false); fireclickdetector(v) end
                            end
                        end)
                        task.wait(3)
                    end
                    task.wait(0.3)
                end
                task.wait(0.5)
            end
        end)
    end})
onUnload(function() _chestRunning=false end)

GameR:AddLabel("Position")
Opt.FarmMode    = GameR:AddDropdown("FarmMode", { Text ="Position", Values ={"Above","Below","In Front","Behind"}, Default=4, Multi=false, Callback=function(v) _farmMode=type(v)=="table" and next(v) or v end })
Opt.FarmOffsetX = GameR:AddSlider("FarmOffsetX", { Text ="X Offset", Default=0,   Min =-50, Max =50, Rounding =1, Callback=function(v) _farmOffX=v end })
Opt.FarmOffsetY = GameR:AddSlider("FarmOffsetY", { Text ="Y Offset", Default=0,   Min =-50, Max =50, Rounding =1, Callback=function(v) _farmOffY=v end })
Opt.FarmOffsetZ = GameR:AddSlider("FarmOffsetZ", { Text ="Z Offset", Default=6.5, Min =0,   Max =50, Rounding =1, Callback=function(v) _farmOffZ=v end })
GameR:AddDivider()
GameR:AddLabel("Combat")
Tog.AutoEquip = GameR:AddToggle("AutoEquip", { Text ="Auto Equip Weapon",      Default=false, Callback=function(p) getgenv()._VVU_autoEquip=p end })
Tog.AutoGrip  = GameR:AddToggle("AutoGrip", { Text ="Auto Grip",              Default=false, Callback=function(p) getgenv()._VVU_autoGrip=p  end })
Tog.AutoRes   = GameR:AddToggle("AutoRes", { Text ="Res/Shikai/Volt Weapon", Default=false, Callback=function(p) getgenv()._VVU_autoRes=p   end })
Tog.AutoM1    = GameR:AddToggle("AutoM1", { Text ="Kill Aura",              Default=false, Callback=function(p) getgenv()._VVU_autoM1=p    end })
Tog.AutoCrit  = GameR:AddToggle("AutoCrit", { Text ="Auto Critical Aura",     Default=false, Callback=function(p) getgenv()._VVU_autoCrit=p  end })

;(function()
    local _skillRemote; pcall(function() _skillRemote=ReplicatedStorage.Requests.UseSkill end)
    local _skillRunning=false; local _skillCooldowns={}
    local function _isSkill(tool) if not tool:IsA("Tool") then return false end; local ok=pcall(function() return tool.SkillName end); return ok end
    local function _getSkillList()
        local seen,skills={},{}
        local bp=LP.Backpack; if bp then for _,v in ipairs(bp:GetChildren()) do if _isSkill(v) and not seen[v.Name] then seen[v.Name]=true; table.insert(skills,v.Name) end end end
        local c=LP.Character; if c then for _,v in ipairs(c:GetChildren()) do if _isSkill(v) and not seen[v.Name] then seen[v.Name]=true; table.insert(skills,v.Name) end end end
        table.sort(skills); return #skills>0 and skills or {"(no skills found)"}
    end
    local function _refreshList() if Opt.AutoSkillSelect then task.defer(function() pcall(function() Library.Options["AutoSkillSelect"]:SetValues(_getSkillList()) end) end) end end
    _farmSkillFire=function()
        if not _skillRemote then return end
        local selected=Library.Options["AutoSkillSelect"] and Library.Options["AutoSkillSelect"].Value; if not selected or not next(selected) then return end
        local c=getChar(); if not c then return end; local now=tick()
        for skillName,on in pairs(selected) do
            if on and (not _skillCooldowns[skillName] or now-_skillCooldowns[skillName]>=0.3) then
                local item=LP.Backpack:FindFirstChild(skillName) or c:FindFirstChild(skillName)
                if item then pcall(function() _skillRemote:FireServer(skillName,item,{HoldingSpace=false}) end); _skillCooldowns[skillName]=now end
            end
        end
end
    Opt.AutoSkillSelect = GameR2:AddDropdown("AutoSkillSelect", { Text ="Skills", Values ={"-- loading --"}, Default=nil, Multi=true, Callback=function() end })
    Tog.AutoSkillEnabled = GameR2:AddToggle("AutoSkillEnabled", { Text ="Auto Use Skill", Default=false, Callback=function(p) _skillRunning=p; if not p then return end; task.spawn(function() while _skillRunning do _farmSkillFire(); task.wait(0.1) end end) end })
    Tog.AutoSkillAll = GameR2:AddToggle("AutoSkillAll", { Text ="Auto Use All Skills", Default=false, Callback=function(p) if not p then return end; task.spawn(function() while Tog.AutoSkillAll and Library.Flags["AutoSkillAll"] and Library.Flags["AutoSkillAll"].Value do if _skillRemote then local c=getChar(); local now=tick(); for _,src in ipairs({LP.Backpack,c}) do if src then for _,item in ipairs(src:GetChildren()) do if _isSkill(item) then if not _skillCooldowns[item.Name] or now-_skillCooldowns[item.Name]>=0.3 then pcall(function() _skillRemote:FireServer(item.Name,item,{HoldingSpace=false}) end); _skillCooldowns[item.Name]=now end end end end end end; task.wait(0.1) end end) end })
    GameR2:AddDivider()
    local _elemAbilRemote; pcall(function() _elemAbilRemote=ReplicatedStorage.Requests.UseAbility end)
    Opt.ElemAbilSelect = GameR2:AddDropdown("ElemAbilSelect", { Text ="Element Ability", Values ={"1","2","3","4","5"}, Default=nil, Multi=true, Callback=function() end })
    Tog.ElemAbilEnabled = GameR2:AddToggle("ElemAbilEnabled", { Text ="Auto Use Ability", Default=false, Callback=function(p) if not p then return end; task.spawn(function() while Tog.ElemAbilEnabled and Library.Flags["ElemAbilEnabled"] and Library.Flags["ElemAbilEnabled"].Value do local sel=Library.Options["ElemAbilSelect"] and Library.Options["ElemAbilSelect"].Value; if sel and next(sel) then for numStr in pairs(sel) do if not (Tog.ElemAbilEnabled and Library.Flags["ElemAbilEnabled"] and Library.Flags["ElemAbilEnabled"].Value) then break end; if _elemAbilRemote then pcall(function() _elemAbilRemote:FireServer(tonumber(numStr) or 1) end) end; task.wait(0.5) end else task.wait(0.5) end end end) end })
    task.spawn(function() task.wait(1); _refreshList() end)
    LP.Backpack.ChildAdded:Connect(_refreshList); LP.Backpack.ChildRemoved:Connect(_refreshList)
    LP.CharacterAdded:Connect(function(c) task.wait(1); _refreshList(); c.ChildAdded:Connect(function(v) if _isSkill(v) then _refreshList() end end) end)
    onUnload(function() _skillRunning=false end)
end)()

;(function()
    local AttemptSell=ReplicatedStorage.Requests:WaitForChild("AttemptSell")
    local _sellRunning=false; local _sellRarities={}; local _sellExclude={}; local _sellExcludeTraits={}
    local _ToolInfo=nil; local _PlayerData=nil; local _SellAcc=nil
    local function _getToolInfo() if not _ToolInfo then pcall(function() _ToolInfo=require(game.ReplicatedStorage.SharedAssets.Info.ToolInfo) end) end; return _ToolInfo end
    local function _getPlayerData() if not _PlayerData then pcall(function() _PlayerData=require(game.ReplicatedStorage.SharedModules.PlayerData) end) end; return _PlayerData end
    local function _getSellAcc() if not _SellAcc then pcall(function() _SellAcc=require(game.ReplicatedStorage.SharedAssets.Info.Accessories) end) end; return _SellAcc end
    local function _isSkillItem(tool) if not tool:IsA("Tool") then return false end; local ok=pcall(function() return tool.SkillName end); return ok end
    local function _buildSellTraitList()
        local acc=_getSellAcc(); local list={}
        if acc and acc.ModifierPool then for _,mod in pairs(acc.ModifierPool) do if mod.Prefix then table.insert(list,mod.Prefix) end end end
        table.sort(list); if #list==0 then list={"No traits found"} end; return list
    end
    local function _getItemTraitSell(item)
        local acc=_getSellAcc(); if not acc then return nil end
        local pd=_getPlayerData(); if not pd then return nil end
        local uid=item:GetAttribute("U_ID"); if not uid then return nil end
        local charData=pd:GetCharacterData(LP); if not charData then return nil end
        for _,inv in ipairs(charData.Inventory) do
            if inv.U_ID==uid and inv.Trait then
                local mod=acc.ModifierPool and acc.ModifierPool[inv.Trait]
                if mod and mod.Prefix then return mod.Prefix end
                local ok2,prefix2=pcall(function() return acc:GetAccessoryPrefix(inv) end)
                if ok2 and prefix2 then return prefix2 end
                return "Trait#"..tostring(inv.Trait)
            end
        end
        return nil
    end
    local function _buildSellList()
        local items={}; for _,item in ipairs(LP.Backpack:GetChildren()) do if item:IsA("Tool") and not _isSkillItem(item) then table.insert(items,item.Name) end end
        table.sort(items); if #items==0 then items={"Empty"} end
        pcall(function() if Opt.SellSelect then Library.Options["SellSelect"]:SetValues(items) end end)
        pcall(function() if Opt.ExcludeSelect then Library.Options["ExcludeSelect"]:SetValues(items) end end)
    end
    local function _getRarity(item)
        local ti=_getToolInfo(); if not ti then return nil end; local pd=_getPlayerData(); if not pd then return nil end
        local id=item:GetAttribute("ItemId"); if not id then return nil end; local uid=item:GetAttribute("U_ID"); if not uid then return nil end
        local charData=pd:GetCharacterData(LP); if not charData then return nil end
        local itemData=nil; for _,inv in ipairs(charData.Inventory) do if inv.U_ID==uid then itemData=inv; break end end
        local info=ti:GetItemFromId(id); if not info then return nil end
        local ok,str=pcall(function() return info:GetRarityStr(itemData,true) end)
        if not ok or not str then return nil end; return (str:gsub("<[^>]+>",""))
    end
    local function _shouldSell(item) if not next(_sellRarities) then return true end; local rarity=_getRarity(item); if not rarity then return true end; return _sellRarities[rarity]==true end
    Opt.SellRarities  = GameL4:AddDropdown("SellRarities", { Text ="Sell Rarities", Values ={"Common","Uncommon","Rare","Epic","Legendary"}, Default=nil, Multi=true, Callback=function(v) _sellRarities=v end })
    Opt.SellSelect    = GameL4:AddDropdown("SellSelect", { Text ="Items",         Values ={"--"}, Default=nil, Multi=true, Callback=function() end })
    Opt.ExcludeSelect = GameL4:AddDropdown("ExcludeSelect", { Text ="Exclude Items",  Values ={"--"}, Default=nil, Multi=true, Callback=function(v) _sellExclude=type(v)=="table" and v or {} end })
    GameL4:AddDivider()
    Opt.SellExcludeTraits = GameL4:AddDropdown("SellExcludeTraits", { Text ="Exclude Traits", Values =_buildSellTraitList(), Default=nil, Multi=true, Callback=function(v) _sellExcludeTraits=type(v)=="table" and v or {} end })
    Tog.AutoSellEnabled = GameL4:AddToggle("AutoSellEnabled", { Text ="Auto Sell", Default=false, Callback=function(p) _sellRunning=p; if not p then return end; task.spawn(function() while _sellRunning do local sel=Library.Options["SellSelect"] and Library.Options["SellSelect"].Value or {}; for _,item in ipairs(LP.Backpack:GetChildren()) do if not item:IsA("Tool") or _isSkillItem(item) then continue end; local uuid=item:GetAttribute("U_ID"); if not uuid then continue end; if item.Text =="Frostvein Shard" then continue end; if _sellExclude[item.Name] then continue end; local trait=_getItemTraitSell(item); if trait and _sellExcludeTraits[trait] then continue end; local byRarity=next(_sellRarities) and _shouldSell(item); local byName=sel[item.Name]; if byRarity or byName then pcall(function() AttemptSell:FireServer(uuid,item,1) end) end end; task.wait(0.5) end end) end })
    GameL4:AddButton({ Text ="Refresh Sell List", Func =_buildSellList })
    task.spawn(function() task.wait(3); _buildSellList() end)
    LP.Backpack.ChildAdded:Connect(function() task.defer(_buildSellList) end)
    LP.Backpack.ChildRemoved:Connect(function() task.defer(_buildSellList) end)
    onUnload(function() _sellRunning=false end)
end)()

;(function()
    local AttemptBank=ReplicatedStorage.Requests:WaitForChild("AttemptBank")
    local _ToolInfoB=nil; local _PlayerDataB=nil
    local function _bTI() if not _ToolInfoB then pcall(function() _ToolInfoB=require(game.ReplicatedStorage.SharedAssets.Info.ToolInfo) end) end; return _ToolInfoB end
    local function _bPD() if not _PlayerDataB then pcall(function() _PlayerDataB=require(game.ReplicatedStorage.SharedModules.PlayerData) end) end; return _PlayerDataB end
    local function _isSkillItemB(tool) if not tool:IsA("Tool") then return false end; local ok=pcall(function() return tool.SkillName end); return ok end
    local function _getItemRarityB(id, uid, inventory)
        local ti=_bTI(); if not ti then return nil end
        local itemData=nil; for _,inv in ipairs(inventory) do if inv.U_ID==uid then itemData=inv; break end end
        local info=ti:GetItemFromId(id); if not info then return nil end
        local ok,str=pcall(function() return info:GetRarityStr(itemData,true) end)
        if not ok or not str then return nil end; return str:gsub("<[^>]+>","")
    end

    -- ── AUTO STORE ────────────────────────────────────────────────────────────
    local _storeRunning=false; local _storeRarities={}; local _storeItems={}; local _storeExclude={}; local _storeExcludeTraits={}; local _storeSelectTraits={}
    local _AccessoriesB=nil
    local function _bAcc() if not _AccessoriesB then pcall(function() _AccessoriesB=require(game.ReplicatedStorage.SharedAssets.Info.Accessories) end) end; return _AccessoriesB end
    local function _getItemTrait(id, uid, inventory)
        local acc=_bAcc(); if not acc then return nil end
        for _,inv in ipairs(inventory) do
            if inv.U_ID==uid and inv.Trait then
                local ok,prefix=pcall(function() return acc:GetAccessoryPrefix(inv) end)
                if ok and prefix then return prefix end
                -- fallback: use raw trait ID
                local mod=acc.ModifierPool and acc.ModifierPool[inv.Trait]
                if mod then return mod.Prefix end
                return "Trait#"..tostring(inv.Trait)
            end
        end
        return nil
    end
    local function _buildTraitList()
        local acc=_bAcc(); local list={}
        if acc and acc.ModifierPool then
            for id, mod in pairs(acc.ModifierPool) do
                if mod.Prefix then table.insert(list, mod.Prefix) end
            end
        end
        table.sort(list)
        if #list==0 then list={"No traits found"} end
        return list
    end
    local function _shouldStore(item, inventory)
        local id=item:GetAttribute("ItemId"); local uid=item:GetAttribute("U_ID")
        if not id or not uid then return false end
        local trait=_getItemTrait(id,uid,inventory)
        -- Exclude traits always wins
        if trait and _storeExcludeTraits[trait] then return false end
        -- If specific traits are selected in Store Traits, store items with those traits
        if next(_storeSelectTraits) then
            if trait and _storeSelectTraits[trait] then return true end
        end
        -- Otherwise fall through to rarity/item filters
        local hasR=next(_storeRarities); local hasI=next(_storeItems)
        if not hasR and not hasI and not next(_storeSelectTraits) then return true end
        if hasR then local r=_getItemRarityB(id,uid,inventory); if r and _storeRarities[r] then return true end end
        if hasI and _storeItems[item.Name] then return true end
        return false
    end
    local function _buildStoreList()
        local items={}; for _,item in ipairs(LP.Backpack:GetChildren()) do if item:IsA("Tool") and not _isSkillItemB(item) then table.insert(items,item.Name) end end
        table.sort(items); if #items==0 then items={"Empty"} end
        pcall(function() if Opt.StoreItemSelect then Library.Options["StoreItemSelect"]:SetValues(items) end end)
        pcall(function() if Opt.StoreExcludeSelect then Library.Options["StoreExcludeSelect"]:SetValues(items) end end)
    end
    Opt.StoreRarities   = GameL5:AddDropdown("StoreRarities", { Text ="Rarities", Values ={"Common","Uncommon","Rare","Epic","Legendary"}, Default=nil, Multi=true, Callback=function(v) _storeRarities=type(v)=="table" and v or {} end })
    Opt.StoreItemSelect = GameL5:AddDropdown("StoreItemSelect", { Text ="Items", Values ={"--"}, Default=nil, Multi=true, Callback=function(v) _storeItems=type(v)=="table" and v or {} end })
    Opt.StoreExcludeSelect = GameL5:AddDropdown("StoreExcludeSelect", { Text ="Exclude Items", Values ={"--"}, Default=nil, Multi=true, Callback=function(v) _storeExclude=type(v)=="table" and v or {} end })
    GameL5:AddDivider()
    Opt.StoreTraits = GameL5:AddDropdown("StoreTraits", { Text ="Store Traits", Values =_buildTraitList(), Default=nil, Multi=true, Callback=function(v) _storeSelectTraits=type(v)=="table" and v or {} end })
    Opt.StoreExcludeTraits = GameL5:AddDropdown("StoreExcludeTraits", { Text ="Exclude Traits", Values =_buildTraitList(), Default=nil, Multi=true, Callback=function(v) _storeExcludeTraits=type(v)=="table" and v or {} end })
    Tog.AutoStoreEnabled = GameL5:AddToggle("AutoStoreEnabled", { Text ="Auto Store", Default=false, Callback=function(p)
        _storeRunning=p; if not p then return end
        task.spawn(function()
            while _storeRunning do
                local pd=_bPD(); local charData=pd and pd:GetCharacterData(LP)
                local inventory=charData and charData.Inventory or {}
                for _,item in ipairs(LP.Backpack:GetChildren()) do
                    if not item:IsA("Tool") or _isSkillItemB(item) then continue end
                    if _storeExclude[item.Name] then continue end
                    if not _shouldStore(item, inventory) then continue end
                    local id=item:GetAttribute("ItemId"); local uid=item:GetAttribute("U_ID")
                    pcall(function() AttemptBank:InvokeServer({Id=id, U_ID=uid, Amount=1}) end)
                end
                task.wait(0.5)
            end
        end)
    end})
    GameL5:AddButton({ Text ="Refresh Items", Func =_buildStoreList })
    task.spawn(function() task.wait(3); _buildStoreList() end)
    LP.Backpack.ChildAdded:Connect(function() task.defer(_buildStoreList) end)
    LP.Backpack.ChildRemoved:Connect(function() task.defer(_buildStoreList) end)
    onUnload(function() _storeRunning=false end)
    GameL5:AddDivider()
    do
        local _bankUpgradeThread = nil
        Tog.AutoBankSlot = GameL5:AddToggle("AutoBankSlot", {
            Text ="Auto Upgrade Bank Slot", Default=false,
            Callback=function(p)
                if _bankUpgradeThread then pcall(task.cancel, _bankUpgradeThread); _bankUpgradeThread=nil end
                if not p then return end
                pcall(function() AttemptBank:InvokeServer({ BuySlot = true }) end)
                _bankUpgradeThread = task.spawn(function()
                    while Tog.AutoBankSlot and Library.Flags["AutoBankSlot"] and Library.Flags["AutoBankSlot"].Value do
                        pcall(function() AttemptBank:InvokeServer({ BuySlot = true }) end)
                        task.wait(1)
                    end
                end)
            end})
        onUnload(function() if _bankUpgradeThread then pcall(task.cancel, _bankUpgradeThread) end end)
    end
end)()

;(function()
    local _whRunning=false; local _whConn=nil; local _whRarities={}; local _whQueue={}; local _whSeen={}
    local _whToolInfo=nil; local _whPlrData=nil
    local function _whTI() if not _whToolInfo then pcall(function() _whToolInfo=require(game.ReplicatedStorage.SharedAssets.Info.ToolInfo) end) end; return _whToolInfo end
    local function _whPD() if not _whPlrData then pcall(function() _whPlrData=require(game.ReplicatedStorage.SharedModules.PlayerData) end) end; return _whPlrData end
    local function _isSkillItem2(tool) if not tool:IsA("Tool") then return false end; local ok=pcall(function() return tool.SkillName end); return ok end
    local function _whRarityAndName(item)
        local ti=_whTI(); local pd=_whPD(); if not ti or not pd then return nil,item.Name end
        local id=item:GetAttribute("ItemId"); local uid=item:GetAttribute("U_ID"); if not id or not uid then return nil,item.Name end
        local charData=pd:GetCharacterData(LP); if not charData then return nil,item.Name end
        local inv=nil; for _,v in ipairs(charData.Inventory) do if v.U_ID==uid then inv=v; break end end
        local info=ti:GetItemFromId(id); if not info then return nil,item.Name end
        local ok1,str=pcall(function() return info:GetRarityStr(inv,true) end)
        local ok2,name=pcall(function() return info:GetName(inv) end)
        return (ok1 and str) and (str:gsub("<[^>]+>","")) or nil, (ok2 and name) or item.Name
    end
    local function _sendWebhook(url, lines)
        local reqFn = request or (syn and syn.request) or http_request or (http and http.request)
        if not reqFn or url == "" then return end
        local hasLeg = false
        for _, l in ipairs(lines) do if l:find("Legendary") then hasLeg = true; break end end
        local desc = table.concat(lines, "\n")
        local ok, body = pcall(function()
            return HS:JSONEncode({
                content = hasLeg and "@everyone 💰 **LEGENDARY DROP** 💰" or nil,
                embeds = {{
                    title = "Item Drop — " .. LP.Name,
                    description = desc,
                    color = hasLeg and 16766720 or 5793266,
                    footer = { text = "VV Ultimatum • Zero Hub" }
                }}
            })
        end)
        if not ok then return end
        pcall(function() reqFn({ Url=url, Method="POST", Headers={["Content-Type"]="application/json"}, Body=body }) end)
    end

    local function _onItemAdded(item)
        if not _whRunning then return end
        if not item:IsA("Tool") or _isSkillItem2(item) then return end
        if item.Name == "Frostvein Shard" then return end
        local uid = item:GetAttribute("U_ID")
        if not uid or _whSeen[uid] then return end
        _whSeen[uid] = true
        task.spawn(function()
            task.wait(0.3)
            if not item.Parent then return end
            local rarity, name = _whRarityAndName(item)
            if next(_whRarities) then if not rarity or not _whRarities[rarity] then return end end
            local url = Library.Options["WebhookURL"] and Library.Options["WebhookURL"].Value or ""
            if url == "" then return end
            local line = name .. (rarity and (" (" .. rarity .. ")") or "")
            _sendWebhook(url, { line })
        end)
    end

    Opt.WebhookURL = GameR3:AddInput("WebhookURL", { Default="", Placeholder="https://discord.com/api/webhooks/...", Callback =function() end })
    GameR3:AddButton({ Text ="Test Webhook", Func =function()
        local url = Library.Options["WebhookURL"] and Library.Options["WebhookURL"].Value or ""
        if url == "" then notify("Enter a webhook URL first", 2); return end
        task.spawn(function() _sendWebhook(url, {"Test Item (Legendary)"}) end)
        notify("Webhook sent", 2)
    end})
    Opt.WebhookRarities = GameR3:AddDropdown("WebhookRarities", { Text ="Rarities", Values ={"Common","Uncommon","Rare","Epic","Legendary"}, Default=nil, Multi=true, Callback=function(v) _whRarities=v end })
    Tog.WebhookEnabled = GameR3:AddToggle("WebhookEnabled", {
        Text ="Notify on Drop", Default=false,
        Callback=function(p)
            _whRunning=p; _whSeen={}
            if _whConn then _whConn:Disconnect(); _whConn=nil end
            if not p then return end
            task.spawn(function() _whTI(); _whPD() end)
            -- watch backpack AND character (some games add to character first)
            _whConn=LP.Backpack.ChildAdded:Connect(_onItemAdded)
            if LP.Character then
                LP.Character.ChildAdded:Connect(function(item) task.defer(function() _onItemAdded(item) end) end)
            end
            LP.CharacterAdded:Connect(function(c)
                c.ChildAdded:Connect(function(item) task.defer(function() _onItemAdded(item) end) end)
            end)
        end})
    onUnload(function() _whRunning=false; if _whConn then _whConn:Disconnect() end end)
end)()

-- ── QUEST HELPER ─────────────────────────────────────────────────────────────
;(function()
    local _PD = nil; pcall(function() _PD = require(ReplicatedStorage.SharedModules.PlayerData) end)
    local _QC = nil; pcall(function() _QC = require(ReplicatedStorage.SharedAssets.Info.QuestCache) end)
    local _DI = workspace:FindFirstChild("DialogueInteractables")

    local function _getCD()
        if not _PD then return nil end
        local ok, cd = pcall(function() return _PD:GetCharacterData(LP) end)
        return ok and cd or nil
    end

    local function _getQI(id)
        if not _QC or not id then return nil end
        local ok, info = pcall(function() return _QC:GetInfoFromId(id) end)
        return ok and info or nil
    end

    -- QuestId attribute only — QuestLine is a Configuration (no .Value)
    local function _findNPC(questId)
        if not _DI then return nil end
        local sid = tostring(questId)
        for _, npc in ipairs(_DI:GetChildren()) do
            local qid = npc:GetAttribute("QuestId")
            if qid and tostring(qid) == sid then return npc end
        end
        return nil
end

    local function _getPrompt(npc)
        if not npc then return nil end
        for _, v in ipairs(npc:GetDescendants()) do
            if v:IsA("ProximityPrompt") then return v end
        end
        return nil
    end

    local function _getRoot(npc)
        if not npc then return nil end
        return npc:FindFirstChild("HumanoidRootPart") or npc:FindFirstChildWhichIsA("BasePart")
    end

    -- ── Labels ───────────────────────────────────────────────────────────────

    GameR4:AddDivider()

    -- ── Get All Available Quests ──────────────────────────────────────────────
    -- Uses QuestAvailable attribute set by the game's NPC client script
    GameR4:AddButton({ Text ="List Available Quests", Func =function()
        if not _DI then notify("DialogueInteractables not found",2); return end
        local cd = _getCD()
        local found = {}
        for _, npc in ipairs(_DI:GetChildren()) do
            local available = npc:GetAttribute("QuestAvailable")
            local qid = npc:GetAttribute("QuestId")
            if available then
                local info = qid and _getQI(qid)
                local title = info and info.QuestTitle or (qid and tostring(qid) or npc.Name)
                table.insert(found, title.." ("..npc.Name..")")
            end
end
        if #found == 0 then
            notify("No available quests found nearby",3)
        else
            notify("Available: "..table.concat(found, " | "), 8)
        end
    end})

    -- ── NPC Dropdown for Tween ────────────────────────────────────────────────
    local function _buildNPCList()
        local list = {"Auto (tracked quest)"}
        if not _DI then return list end
        for _, npc in ipairs(_DI:GetChildren()) do
            local qid = npc:GetAttribute("QuestId")
            if qid then
                local info = _getQI(qid)
                local label = (info and info.QuestTitle or tostring(qid)).." / "..npc.Name
                table.insert(list, label)
            elseif npc:GetAttribute("MissionGiver") then
                table.insert(list, "[Missions] "..npc.Name)
            end
        end
        return list
    end

    Opt.QuestNPCSelect = GameR4:AddDropdown("QuestNPCSelect", {
        Text ="Select NPC", Values =_buildNPCList(), Default=1, Multi=false,
        Callback=function() end
    })

    GameR4:AddButton({ Text ="Refresh NPC List", Func =function()
        pcall(function()
            Library.Options["QuestNPCSelect"]:SetValues(_buildNPCList())
        end)
    end})

    local function _resolveSelectedNPC()
        local sel = Library.Options["QuestNPCSelect"] and Library.Options["QuestNPCSelect"].Value
        if not sel or sel == "Auto (tracked quest)" or sel == "" then
            -- use tracked quest
            local cd = _getCD(); if not cd then return nil end
            local id = cd.CurrentQuestID; if not id or id==-1 then return nil end
            return _findNPC(id)
        end
        -- find by label match
        if not _DI then return nil end
        for _, npc in ipairs(_DI:GetChildren()) do
            if sel:find(npc.Name, 1, true) then return npc end
        end
        return nil
    end

    GameR4:AddDivider()

    GameR4:AddDivider()

    GameR4:AddButton({ Text ="Tween to NPC", Func =function()
        local npc = _resolveSelectedNPC()
        if not npc then notify("No NPC selected or no tracked quest",3); return end
        local root = _getRoot(npc); if not root then notify("NPC has no root",2); return end
        task.spawn(function() tweenTo(root.CFrame * CFrame.new(0,0,5)) end)
        notify("Tweening to "..npc.Name, 2)
    end})

    GameR4:AddButton({ Text ="Talk to NPC", Func =function()
        local npc = _resolveSelectedNPC()
        if not npc then notify("No NPC selected or no tracked quest",3); return end
        local prompt = _getPrompt(npc); if not prompt then notify("No ProximityPrompt on "..npc.Name,3); return end
        pcall(fireproximityprompt, prompt)
        notify("Fired prompt on "..npc.Name, 2)
    end})

    GameR4:AddButton({ Text ="Go & Talk", Func =function()
        local npc = _resolveSelectedNPC()
        if not npc then notify("No NPC selected or no tracked quest",3); return end
        local root = _getRoot(npc); if not root then notify("NPC has no root",2); return end
        task.spawn(function()
            notify("Heading to "..npc.Name.."...", 2)
            tweenTo(root.CFrame * CFrame.new(0,0,5))
            task.wait(0.5)
            local prompt = _getPrompt(npc)
            if prompt then pcall(fireproximityprompt, prompt); notify("Talking to "..npc.Name, 2) end
        end)
    end})

    GameR4:AddDivider()

    -- ── Tween to All Quest NPCs ───────────────────────────────────────────────
    local _tweenAllRunning = false

    Tog.TweenAllQuestNPCs = GameR4:AddToggle("TweenAllQuestNPCs", {
        Text ="Tween to All Quest NPCs", Default=false,
        Callback=function(p)
            _tweenAllRunning = p
            if not p then _cancelTween = true; return end
            task.spawn(function()
                if not _DI then notify("DialogueInteractables not found",2); return end
                local npcs = {}
                for _, npc in ipairs(_DI:GetChildren()) do
                    if npc:GetAttribute("QuestAvailable") then
                        table.insert(npcs, npc)
                    end
                end
                if #npcs == 0 then
                    notify("No available quest NPCs found",3)
                    _tweenAllRunning = false
                    if Tog.TweenAllQuestNPCs then Library.Flags["TweenAllQuestNPCs"]:SetValue(false) end
                    return
                end
                notify("Visiting "..#npcs.." quest NPCs...", 3)
                for _, npc in ipairs(npcs) do
                    if not _tweenAllRunning then break end
                    local root = _getRoot(npc); if not root then continue end
                    tweenTo(root.CFrame * CFrame.new(0, 0, 5))
                    task.wait(0.4)
                    if not _tweenAllRunning then break end
                    local prompt = _getPrompt(npc)
                    if prompt then
                        pcall(fireproximityprompt, prompt)
                        notify("Talked to "..npc.Name, 2)
                        task.wait(2)
                    end
                end
                _tweenAllRunning = false
                if Tog.TweenAllQuestNPCs then Library.Flags["TweenAllQuestNPCs"]:SetValue(false) end
                notify("Done visiting all quest NPCs", 3)
            end)
        end})

    onUnload(function() _tweenAllRunning = false end)

    GameR4:AddDivider()

    local _autoDialogEnabled = false
    Tog.AutoQuestDialogue = GameR4:AddToggle("AutoQuestDialogue", {
        Text ="Auto Quest Dialogue", Default=false,
        Callback=function(p)
            _autoDialogEnabled = p
            if p then
                local _priority = {
                    "task","quest","accept","complete","turn","about",
                    "mission","yes","sure","okay","give","receive","begin"
                }
                pcall(function()
                    ReplicatedStorage.Requests.Dialogue.OnClientInvoke = function(data)
                        if not _autoDialogEnabled then return end
                        local responses = (type(data)=="table" and data.Responses) or {}
                        if #responses == 0 then return end
                        local nonLeave = {}
                        for _, r in ipairs(responses) do
                            local id = type(r)=="string" and r or (r.Id or "")
                            if id ~= "Leave" then table.insert(nonLeave, id) end
                        end
                        if #nonLeave == 0 then return "Leave" end
                        for _, kw in ipairs(_priority) do
                            for _, id in ipairs(nonLeave) do
                                if id:lower():find(kw) then return id end
                            end
                        end
                        return nonLeave[1]
                    end
                end)
            else
                pcall(function() ReplicatedStorage.Requests.Dialogue.OnClientInvoke = nil end)
            end
        end})
end)()

;(function()
    local TeleportToServer=ReplicatedStorage.Requests:WaitForChild("TeleportToServer")
    local _raids={
        ["Soul Society Outskirts"]={PlaceId=14218523102, ReserveServerCode="_xjr7JA0AFKIUc6fGVfjKYU5C868SFpDiXjbMDX75P_ecX1PAwAAAA2"},
        ["Soul Society"]          ={PlaceId=12337012844, ReserveServerCode="Uv-pYOQYNxf560p5ZT_eSpsFSuXtr9JCkxXc8zuTj8ps4FffAgAAAA2"},
        ["Las Noches"]            ={PlaceId=11127942816, ReserveServerCode="MkxUKSweAir5-XJRQiFcdby4TU7JJUJAhIrVxcYr7-mg7kaXAgAAAA2"},
        ["Wandenreich"]           ={PlaceId=11780443293, ReserveServerCode="FmKhJAd5QlVTfOOQ8kVWSaEvHcX_iwhFngK2Fyx2zNqdTCu-AgAAAA2"},
        ["Hueco Mundo"]           ={PlaceId=11131834995, ReserveServerCode="HHV4VUCjNMfOqVcBRLksifTD1L4orYBErowuqh7JDGNzUoKXAgAAAA2"},
        ["Human World"]           ={PlaceId=14219489601, ReserveServerCode="rDs2DI12Pdf-7u_WJ79X46drbMiTt3BBkUgVu-N_3NtBMYxPAwAAAA2"},
    }
    local _raidKeys={"Soul Society Outskirts","Soul Society","Las Noches","Wandenreich","Hueco Mundo","Human World"}
    local _selectedRaid=_raidKeys[1]
    Opt.RaidSelect=GameR5:AddDropdown("RaidSelect", {
        Text ="Raid", Values =_raidKeys, Default=1, Multi=false,
        Callback=function(v) _selectedRaid=type(v)=="table" and next(v) or v end
    })
    GameR5:AddButton({Text ="Join Raid",Func =function()
        local raid=_raids[_selectedRaid]; if not raid then return end
        pcall(function() TeleportToServer:InvokeServer({PlaceId=raid.PlaceId,ReserveServerCode=raid.ReserveServerCode}) end)
        notify("Joining ".._selectedRaid,2)
    end})
end)()
onUnload(function()
    getgenv()._VVU_autoM1=false; getgenv()._VVU_autoCrit=false; getgenv()._VVU_autoEquip=false
    getgenv()._VVU_autoGrip=false; getgenv()._VVU_autoRes=false
    for _,conn in pairs(farmConns) do if conn then conn:Disconnect() end end
end)

;(function()
local espEnabled=false; local espColor=Color3.fromRGB(255,255,255)
local espActive={}; local espConns={}
local _plrESP={components={["Box 2D"]=true,["Text"]=true,["HP Bar"]=true},showName=true,showHP=true,showDist=true}

local function removeESP(char)
    local d=espActive[char]; if not d then return end
    pcall(function() if d.txt    then d.txt:Remove()    end end)
    pcall(function() if d.box    then d.box:Remove()    end end)
    pcall(function() if d.hpFill then d.hpFill:Remove() end end)
    pcall(function() if d.hpBack then d.hpBack:Remove() end end)
    pcall(function() if d.tracer then d.tracer:Remove() end end)
    pcall(function() if d.dot    then d.dot:Remove()    end end)
    pcall(function() if d.hl     then d.hl:Destroy()    end end)
    if d.rname   then pcall(function() RS:UnbindFromRenderStep(d.rname) end) end
    if d.ancConn then pcall(function() d.ancConn:Disconnect() end) end
    if d.dieConn then pcall(function() d.dieConn:Disconnect() end) end
    espActive[char]=nil
end
local function addESP(char,plr)
    if not char or espActive[char] then return end
    local hum=char:FindFirstChildOfClass("Humanoid"); local hrp=char:FindFirstChild("HumanoidRootPart"); local head=char:FindFirstChild("Head")
    if not (hum and hrp and head) then return end
    local txt=Drawing.new("Text"); txt.Center=true; txt.Outline=true; txt.Visible=false; txt.Size=14
    local box=Drawing.new("Square"); box.Filled=false; box.Thickness=1.5; box.Visible=false
    local hpFill=Drawing.new("Square"); hpFill.Filled=true; hpFill.Visible=false
    local hpBack=Drawing.new("Square"); hpBack.Filled=false; hpBack.Thickness=1; hpBack.Color=Color3.new(0,0,0); hpBack.Visible=false
    local tracer=Drawing.new("Line"); tracer.Thickness=1; tracer.Visible=false
    local dot=Drawing.new("Circle"); dot.Radius=4; dot.Filled=true; dot.Visible=false; dot.Thickness=1
    local hl=Instance.new("Highlight",char); hl.FillTransparency=0.5; hl.OutlineTransparency=0; hl.Enabled=false
    local rname="ZH_ESP_"..char:GetDebugId()
    RS:BindToRenderStep(rname, Enum.RenderPriority.Camera.Value+1, function()
        if not (espEnabled and char and char.Parent) then removeESP(char); return end
        local myHRP=LP.Character and LP.Character:FindFirstChild("HumanoidRootPart"); if not myHRP then return end
        local dist=(hrp.Position-myHRP.Position).Magnitude
        if dist>(S.espDist or 1000) then
            txt.Visible=false; box.Visible=false; hpFill.Visible=false; hpBack.Visible=false; tracer.Visible=false; dot.Visible=false; hl.Enabled=false; return
        end
        if S.espAntiLag and _wFPS<30 then
            txt.Visible=false; box.Visible=false; hpFill.Visible=false; hpBack.Visible=false; tracer.Visible=false; dot.Visible=false; hl.Enabled=false; return
        end
        local col=espColor or Color3.new(1,1,1)
        local comps=_plrESP.components or {}
        local sv,onS=Cam:WorldToViewportPoint(hrp.Position); local hv,onH=Cam:WorldToViewportPoint(head.Position)
        if not onS then txt.Visible=false; box.Visible=false; hpFill.Visible=false; hpBack.Visible=false; tracer.Visible=false; dot.Visible=false; hl.Enabled=false; return end
        local scale=math.clamp(1/(sv.Z*0.04),0.5,3)
        local bw=35*scale; local bh=70*scale; local bx=sv.X-bw/2; local by=sv.Y-bh/2
        local hpPct=math.clamp(hum.Health/math.max(hum.MaxHealth,1),0,1)
        local hpCol=Color3.fromHSV(hpPct*0.33,1,1)
        if comps["Box 2D"] then box.Position=Vector2.new(bx,by); box.Size=Vector2.new(bw,bh); box.Color=col; box.Visible=true else box.Visible=false end
        if comps["HP Bar"] then
            local barW=6; local barX=bx-barW-3
            hpBack.Position=Vector2.new(barX-1,by-1); hpBack.Size=Vector2.new(barW+2,bh+2); hpBack.Visible=true
            hpFill.Position=Vector2.new(barX,by+bh*(1-hpPct)); hpFill.Size=Vector2.new(barW,bh*hpPct); hpFill.Color=hpCol; hpFill.Visible=true
        else hpFill.Visible=false; hpBack.Visible=false end
        if comps["Text"] then
            local parts={}; local name=(plr and plr.DisplayName) or char.Name
            if _plrESP.showName then table.insert(parts,name) end
            if _plrESP.showHP   then table.insert(parts,string.format("[%d/%d]",hum.Health,hum.MaxHealth)) end
            if _plrESP.showDist then table.insert(parts,string.format("[%.0fm]",dist)) end
            txt.Text=table.concat(parts," "); txt.Color=col; txt.Size=S.espFontSize or 14
            txt.Position=Vector2.new(sv.X,by-(S.espFontSize or 14)-2); txt.Visible=#parts>0
        else txt.Visible=false end
        if comps["Tracer"] then tracer.From=Vector2.new(sv.X,sv.Y); tracer.To=Vector2.new(Cam.ViewportSize.X/2,Cam.ViewportSize.Y); tracer.Color=col; tracer.Thickness=S.tracerThick or 1; tracer.Visible=true else tracer.Visible=false end
        if comps["Head Dot"] and onH then dot.Position=Vector2.new(hv.X,hv.Y); dot.Color=col; dot.Visible=true else dot.Visible=false end
        hl.Enabled=comps["Highlight"] and espEnabled; hl.FillColor=col; hl.OutlineColor=col
        hl.FillTransparency=S.hlFillTrans or 0.5; hl.OutlineTransparency=S.hlOutlineTrans or 0
    end)
    espActive[char]={txt=txt,box=box,hpFill=hpFill,hpBack=hpBack,tracer=tracer,dot=dot,hl=hl,rname=rname,
        ancConn=char.AncestryChanged:Connect(function(_,p) if not p then removeESP(char) end end),
        dieConn=hum.Died:Connect(function() task.wait(3); removeESP(char) end)}
end

local _hue=0
local mobESPColor2=Color3.fromRGB(255,100,100); local npcESPColor2=Color3.fromRGB(100,220,255)
local _mobESP2={components={["Box 2D"]=true,["Text"]=true,["HP Bar"]=true},showName=true,showHP=true,showDist=true,rainbow=false}
local _npcESP2={components={["Box 2D"]=true,["Text"]=true},showName=true,showDist=true,rainbow=false}
RS.Heartbeat:Connect(function(dt)
    _hue=(_hue+dt*0.25)%1; local rc=Color3.fromHSV(_hue,1,1)
    if S.espRainbow     then espColor=rc      end
    if _mobESP2.rainbow then mobESPColor2=rc  end
    if _npcESP2.rainbow then npcESPColor2=rc  end
end)

Tog.PlayerESPEnabled = VizL:AddToggle("PlayerESPEnabled", {
    Text ="Player ESP", Default=false,
    Callback=function(p)
        espEnabled=p
        if p then
            local function hook(plr)
                if plr==LP then return end
                if plr.Character then task.spawn(addESP,plr.Character,plr) end
                table.insert(espConns,plr.CharacterAdded:Connect(function(c) task.wait(0.25); addESP(c,plr) end))
            end
            for _,plr in ipairs(PS:GetPlayers()) do hook(plr) end
            table.insert(espConns,PS.PlayerAdded:Connect(hook))
            table.insert(espConns,PS.PlayerRemoving:Connect(function(plr) if plr.Character then removeESP(plr.Character) end end))
        else
            for _,conn in ipairs(espConns) do pcall(function() conn:Disconnect() end) end
            espConns={}
            local _eList={}; for c in pairs(espActive) do _eList[#_eList+1]=c end; for _,c in ipairs(_eList) do removeESP(c) end
        end
    end})
Opt.ESPColor = VizL:AddColorPicker("ESPColor", { Default=Color3.fromRGB(255,255,255), Callback=function(col) espColor=col end })
Tog.ESPRainbow  = VizL:AddToggle("ESPRainbow", { Text ="Rainbow",  Default=false, Callback=function(p) S.espRainbow=p  end })
Tog.ESPShowName = VizL:AddToggle("ESPShowName", { Text ="Name",     Default=true,  Callback=function(p) _plrESP.showName=p end })
Tog.ESPShowHP   = VizL:AddToggle("ESPShowHP", { Text ="Health",   Default=true,  Callback=function(p) _plrESP.showHP=p   end })
Tog.ESPShowDist = VizL:AddToggle("ESPShowDist", { Text ="Distance", Default=true,  Callback=function(p) _plrESP.showDist=p end })
Opt.PlrESPComponents = VizL:AddDropdown("PlrESPComponents", {
    Text ="Components", Multi=true, Default={"Text","Box 2D","HP Bar"}, Values ={"Text","Highlight","Tracer","Box 2D","HP Bar","Head Dot"},
    Callback=function(v) _plrESP.components=v end
})
VizL:AddDivider()

VizR:AddLabel("Range")
Opt.ESPDist     = VizR:AddSlider("ESPDist", { Text ="Max Distance",  Default=1000, Min =0, Max =10000, Rounding =0, Callback=function(v) S.espDist=v     end })
Opt.ESPFontSize = VizR:AddSlider("ESPFontSize", { Text ="Font Size",      Default=14,   Min =8, Max =32,   Rounding =0, Callback=function(v) S.espFontSize=v end })
VizR:AddDivider()
VizR:AddLabel("Highlight")
Opt.HLFillTrans    = VizR:AddSlider("HLFillTrans", { Text ="Fill Trans",    Default=0.5, Min =0, Max =1, Rounding =2, Callback=function(v) S.hlFillTrans=v    end })
Opt.HLOutlineTrans = VizR:AddSlider("HLOutlineTrans", { Text ="Outline Trans", Default=0,   Min =0, Max =1, Rounding =2, Callback=function(v) S.hlOutlineTrans=v end })
VizR:AddDivider()
VizR:AddLabel("Tracer")
Opt.TracerThick = VizR:AddSlider("TracerThick", { Text ="Tracer Width", Default=1, Min =1, Max =5, Rounding =1, Callback=function(v) S.tracerThick=v end })
VizR:AddDivider()
VizR:AddLabel("Anti-Lag")
Tog.ESPThrottle = VizR:AddToggle("ESP_Throttle", { Text ="FPS Guard", Default=true, Callback=function(p) S.espAntiLag=p end })
VizR:AddLabel("Disables ESP when FPS < 30")

local _mobESPActive={}; local _mobESPEnabled=false
local function removeMobESP(mob)
    local d=_mobESPActive[mob]; if not d then return end
    pcall(function() if d.txt    then d.txt:Remove()    end end)
    pcall(function() if d.box    then d.box:Remove()    end end)
    pcall(function() if d.hpFill then d.hpFill:Remove() end end)
    pcall(function() if d.hpBack then d.hpBack:Remove() end end)
    pcall(function() if d.tracer then d.tracer:Remove() end end)
    pcall(function() if d.dot    then d.dot:Remove()    end end)
    pcall(function() if d.hl     then d.hl:Destroy()    end end)
    if d.conn    then pcall(function() d.conn:Disconnect()    end) end
    if d.ancConn then pcall(function() d.ancConn:Disconnect() end) end
    _mobESPActive[mob]=nil
end
local function getMobType2(mob)
    local ht=mob:GetAttribute("HollowType"); if ht and ht~="" then return tostring(ht) end
    return mob.Name:match("^(.-)_[^_]+$") or mob.Name
end
local function addMobESP(mob)
    if not mob or _mobESPActive[mob] then return end
    local hum=mob:FindFirstChildOfClass("Humanoid"); if not hum then return end
    local hrp=mob:FindFirstChild("HumanoidRootPart"); if not hrp then return end
    local head=mob:FindFirstChild("Head")
    local txt=Drawing.new("Text"); txt.Center=true; txt.Outline=true; txt.Visible=false; txt.Size=14
    local box=Drawing.new("Square"); box.Filled=false; box.Thickness=1.5; box.Visible=false
    local hpFill=Drawing.new("Square"); hpFill.Filled=true; hpFill.Visible=false
    local hpBack=Drawing.new("Square"); hpBack.Filled=false; hpBack.Thickness=1; hpBack.Color=Color3.new(0,0,0); hpBack.Visible=false
    local tracer=Drawing.new("Line"); tracer.Thickness=1; tracer.Visible=false
    local dot=Drawing.new("Circle"); dot.Radius=4; dot.Filled=true; dot.Visible=false; dot.Thickness=1
    local hl=Instance.new("Highlight",mob); hl.FillTransparency=0.5; hl.OutlineTransparency=0; hl.Enabled=false
    local conn=RS.Heartbeat:Connect(function()
        if not (_mobESPEnabled and mob and mob.Parent) then removeMobESP(mob); return end
        local myHRP=getHRP(); if not myHRP then return end
        local col=mobESPColor2; local dist=(hrp.Position-myHRP.Position).Magnitude
        local comps=_mobESP2.components or {}
        if dist>(S.espDist or 1000) then txt.Visible=false; box.Visible=false; hpFill.Visible=false; hpBack.Visible=false; tracer.Visible=false; dot.Visible=false; hl.Enabled=false; return end
        local sv,onS=Cam:WorldToViewportPoint(hrp.Position); local hv,onH=head and Cam:WorldToViewportPoint(head.Position)
        if not onS then txt.Visible=false; box.Visible=false; hpFill.Visible=false; hpBack.Visible=false; tracer.Visible=false; dot.Visible=false; hl.Enabled=false; return end
        local scale=math.clamp(1/(sv.Z*0.04),0.5,3); local bw=35*scale; local bh=70*scale; local bx=sv.X-bw/2; local by=sv.Y-bh/2
        local hpPct=math.clamp(hum.Health/math.max(hum.MaxHealth,1),0,1); local hpCol=Color3.fromHSV(hpPct*0.33,1,1)
        if comps["Box 2D"] then box.Position=Vector2.new(bx,by); box.Size=Vector2.new(bw,bh); box.Color=col; box.Visible=true else box.Visible=false end
        if comps["HP Bar"] then local barW=6; local barX=bx-barW-3; hpBack.Position=Vector2.new(barX-1,by-1); hpBack.Size=Vector2.new(barW+2,bh+2); hpBack.Visible=true; hpFill.Position=Vector2.new(barX,by+bh*(1-hpPct)); hpFill.Size=Vector2.new(barW,bh*hpPct); hpFill.Color=hpCol; hpFill.Visible=true else hpFill.Visible=false; hpBack.Visible=false end
        if comps["Text"] then local parts={}; if _mobESP2.showName then table.insert(parts,getMobType2(mob)) end; if _mobESP2.showHP then table.insert(parts,string.format("[%d/%d]",hum.Health,hum.MaxHealth)) end; if _mobESP2.showDist then table.insert(parts,string.format("[%.0fm]",dist)) end; txt.Text=table.concat(parts," "); txt.Color=col; txt.Size=S.espFontSize or 14; txt.Position=Vector2.new(sv.X,by-(S.espFontSize or 14)-2); txt.Visible=#parts>0 else txt.Visible=false end
        if comps["Tracer"] then tracer.From=Vector2.new(sv.X,sv.Y); tracer.To=Vector2.new(Cam.ViewportSize.X/2,Cam.ViewportSize.Y); tracer.Color=col; tracer.Thickness=S.tracerThick or 1; tracer.Visible=true else tracer.Visible=false end
        if comps["Head Dot"] and onH and head then dot.Position=Vector2.new(hv.X,hv.Y); dot.Color=col; dot.Visible=true else dot.Visible=false end
        hl.Enabled=comps["Highlight"] and _mobESPEnabled or false; hl.FillColor=col; hl.OutlineColor=col; hl.FillTransparency=S.hlFillTrans or 0.5; hl.OutlineTransparency=S.hlOutlineTrans or 0
    end)
    _mobESPActive[mob]={txt=txt,box=box,hpFill=hpFill,hpBack=hpBack,tracer=tracer,dot=dot,hl=hl,conn=conn,
        ancConn=mob.AncestryChanged:Connect(function(_,p) if not p then removeMobESP(mob) end end)}
end
local function scanMobESP2() local living=workspace:FindFirstChild("Living"); if not living then return end; for _,m in ipairs(living:GetChildren()) do if m:IsA("Model") and not PS:GetPlayerFromCharacter(m) then addMobESP(m) end end end
local function stopMobESP() _mobESPEnabled=false; for mob in pairs(_mobESPActive) do removeMobESP(mob) end end

Tog.MobESPEnabled = VizL2:AddToggle("MobESPEnabled", {
    Text ="Mob ESP", Default=false,
    Callback=function(p)
        _mobESPEnabled=p
        if p then scanMobESP2(); task.spawn(function() while _mobESPEnabled do task.wait(3); scanMobESP2() end end)
        else stopMobESP() end
    end})
Opt.MobESPColor2 = VizL2:AddColorPicker("MobESPColor2", { Default=Color3.fromRGB(255,100,100), Callback=function(c) mobESPColor2=c end })
Tog.MobESPRainbow2 = VizL2:AddToggle("MobESPRainbow2", { Text ="Rainbow",  Default=false, Callback=function(p) _mobESP2.rainbow=p  end })
Tog.MobESPShowName = VizL2:AddToggle("MobESPShowName", { Text ="Name",     Default=true,  Callback=function(p) _mobESP2.showName=p end })
Tog.MobESPShowHP   = VizL2:AddToggle("MobESPShowHP", { Text ="Health",   Default=true,  Callback=function(p) _mobESP2.showHP=p   end })
Tog.MobESPShowDist = VizL2:AddToggle("MobESPShowDist", { Text ="Distance", Default=true,  Callback=function(p) _mobESP2.showDist=p end })
Opt.MobESPComponents = VizL2:AddDropdown("MobESPComponents", { Text ="Components", Multi=true, Default={"Text","Box 2D","HP Bar"}, Values ={"Text","Highlight","Tracer","Box 2D","HP Bar","Head Dot"}, Callback=function(v) _mobESP2.components=v end })
onUnload(function() stopMobESP() end)
VizL2:AddDivider()

local _npcESPActive={}; local _npcESPEnabled=false
local function removeNPCESP(npc)
    local d=_npcESPActive[npc]; if not d then return end
    for _,k in ipairs({"txt","box","hpFill","hpBack","tracer","dot"}) do if d[k] then pcall(function() d[k]:Remove() end) end end
    if d.hl then pcall(function() d.hl:Destroy() end) end
    if d.conn    then pcall(function() d.conn:Disconnect()    end) end
    if d.ancConn then pcall(function() d.ancConn:Disconnect() end) end
    _npcESPActive[npc]=nil
end
local function addNPCESP(npc,label)
    if not npc or _npcESPActive[npc] then return end
    local hrp=npc:FindFirstChild("HumanoidRootPart") or npc.PrimaryPart; if not hrp then return end
    local hum=npc:FindFirstChildOfClass("Humanoid"); local head=npc:FindFirstChild("Head")
    local txt=Drawing.new("Text"); txt.Center=true; txt.Outline=true; txt.Visible=false; txt.Size=14
    local box=Drawing.new("Square"); box.Filled=false; box.Thickness=1.5; box.Visible=false
    local hpFill=Drawing.new("Square"); hpFill.Filled=true; hpFill.Visible=false
    local hpBack=Drawing.new("Square"); hpBack.Filled=false; hpBack.Thickness=1; hpBack.Color=Color3.new(0,0,0); hpBack.Visible=false
    local tracer=Drawing.new("Line"); tracer.Thickness=1; tracer.Visible=false
    local dot=Drawing.new("Circle"); dot.Radius=4; dot.Filled=true; dot.Visible=false; dot.Thickness=1
    local hl=Instance.new("Highlight",npc); hl.FillTransparency=0.5; hl.OutlineTransparency=0; hl.Enabled=false
    local conn=RS.Heartbeat:Connect(function()
        if not (_npcESPEnabled and npc and npc.Parent) then removeNPCESP(npc); return end
        local myHRP=getHRP(); if not myHRP then return end
        local col=npcESPColor2; local dist=(hrp.Position-myHRP.Position).Magnitude
        local comps=_npcESP2.components or {}
        if dist>(S.espDist or 1000) then txt.Visible=false; box.Visible=false; hpFill.Visible=false; hpBack.Visible=false; tracer.Visible=false; dot.Visible=false; hl.Enabled=false; return end
        local sv,onS=Cam:WorldToViewportPoint(hrp.Position); local hv,onH=head and Cam:WorldToViewportPoint(head.Position)
        if not onS then txt.Visible=false; box.Visible=false; hpFill.Visible=false; hpBack.Visible=false; tracer.Visible=false; dot.Visible=false; hl.Enabled=false; return end
        local scale=math.clamp(1/(sv.Z*0.04),0.5,3); local bw=35*scale; local bh=70*scale; local bx=sv.X-bw/2; local by=sv.Y-bh/2
        if comps["Box 2D"] then box.Position=Vector2.new(bx,by); box.Size=Vector2.new(bw,bh); box.Color=col; box.Visible=true else box.Visible=false end
        if comps["HP Bar"] and hum then local hpPct=math.clamp(hum.Health/math.max(hum.MaxHealth,1),0,1); local hpCol=Color3.fromHSV(hpPct*0.33,1,1); local barW=6; local barX=bx-barW-3; hpBack.Position=Vector2.new(barX-1,by-1); hpBack.Size=Vector2.new(barW+2,bh+2); hpBack.Visible=true; hpFill.Position=Vector2.new(barX,by+bh*(1-hpPct)); hpFill.Size=Vector2.new(barW,bh*hpPct); hpFill.Color=hpCol; hpFill.Visible=true else hpFill.Visible=false; hpBack.Visible=false end
        if comps["Text"] then local parts={}; if _npcESP2.showName then table.insert(parts,label or npc.Name) end; if _npcESP2.showDist then table.insert(parts,string.format("[%.0fm]",dist)) end; txt.Text=table.concat(parts," "); txt.Color=col; txt.Size=S.espFontSize or 14; txt.Position=Vector2.new(sv.X,by-(S.espFontSize or 14)-2); txt.Visible=#parts>0 else txt.Visible=false end
        if comps["Tracer"] then tracer.From=Vector2.new(sv.X,sv.Y); tracer.To=Vector2.new(Cam.ViewportSize.X/2,Cam.ViewportSize.Y); tracer.Color=col; tracer.Thickness=S.tracerThick or 1; tracer.Visible=true else tracer.Visible=false end
        if comps["Head Dot"] and onH and head then dot.Position=Vector2.new(hv.X,hv.Y); dot.Color=col; dot.Visible=true else dot.Visible=false end
        hl.Enabled=comps["Highlight"] and _npcESPEnabled or false; hl.FillColor=col; hl.OutlineColor=col; hl.FillTransparency=S.hlFillTrans or 0.5; hl.OutlineTransparency=S.hlOutlineTrans or 0
    end)
    _npcESPActive[npc]={txt=txt,box=box,hpFill=hpFill,hpBack=hpBack,tracer=tracer,dot=dot,hl=hl,conn=conn,
        ancConn=npc.AncestryChanged:Connect(function(_,p) if not p then removeNPCESP(npc) end end)}
end
local function scanNPCESP2() local di=workspace:FindFirstChild("DialogueInteractables"); if not di then return end; for _,m in ipairs(di:GetChildren()) do if m:IsA("Model") then addNPCESP(m,m.Name) end end end
local function stopNPCESP() _npcESPEnabled=false; for npc in pairs(_npcESPActive) do removeNPCESP(npc) end end

Tog.NPCESPEnabled = VizR2:AddToggle("NPCESPEnabled", {
    Text ="NPC ESP", Default=false,
    Callback=function(p) _npcESPEnabled=p; if p then scanNPCESP2(); task.spawn(function() while _npcESPEnabled do task.wait(3); scanNPCESP2() end end) else stopNPCESP() end end})
Opt.NpcESPColor2 = VizR2:AddColorPicker("NpcESPColor2", { Default=Color3.fromRGB(100,220,255), Callback=function(c) npcESPColor2=c end })
Tog.NpcESPRainbow2 = VizR2:AddToggle("NpcESPRainbow2", { Text ="Rainbow",  Default=false, Callback=function(p) _npcESP2.rainbow=p  end })
Tog.NpcESPShowName = VizR2:AddToggle("NpcESPShowName", { Text ="Name",     Default=true,  Callback=function(p) _npcESP2.showName=p end })
Tog.NpcESPShowDist = VizR2:AddToggle("NpcESPShowDist", { Text ="Distance", Default=true,  Callback=function(p) _npcESP2.showDist=p end })
Opt.NpcESPComponents = VizR2:AddDropdown("NpcESPComponents", { Text ="Components", Multi=true, Default={"Text","Box 2D"}, Values ={"Text","Highlight","Tracer","Box 2D","HP Bar","Head Dot"}, Callback=function(v) _npcESP2.components=v end })
onUnload(function() stopNPCESP() end)
end)()
VizR2:AddDivider()

;(function()
    local _chestESPActive={}; local _chestESPEnabled=false; local _chestESPColor=Color3.fromRGB(255,215,0)
    local _chestESP2={components={},showName=true,showDist=true}
    local function removeChestESP(chest)
        local d=_chestESPActive[chest]; if not d then return end
        for _,k in ipairs({"txt","box","tracer"}) do if d[k] then pcall(function() d[k]:Remove() end) end end
        if d.hl then pcall(function() d.hl:Destroy() end) end
        if d.conn then pcall(function() d.conn:Disconnect() end) end
        if d.ancConn then pcall(function() d.ancConn:Disconnect() end) end
        _chestESPActive[chest]=nil
    end
    local function addChestESP(chest)
        if not chest or _chestESPActive[chest] then return end
        if not chest.Name:find("ChestTemplate") then return end
        local anchor=chest.PrimaryPart or chest:FindFirstChildWhichIsA("BasePart"); if not anchor then return end
        local txt=Drawing.new("Text"); txt.Center=true; txt.Outline=true; txt.Visible=false; txt.Size=14
        local box=Drawing.new("Square"); box.Filled=false; box.Thickness=1.5; box.Visible=false
        local tracer=Drawing.new("Line"); tracer.Thickness=1; tracer.Visible=false
        local hl=Instance.new("Highlight",chest); hl.FillTransparency=0.5; hl.OutlineTransparency=0; hl.Enabled=false
        local conn=RS.Heartbeat:Connect(function()
            if not (_chestESPEnabled and chest and chest.Parent) then removeChestESP(chest); return end
            local myHRP=getHRP(); if not myHRP then return end
            local col=_chestESPColor; local dist=(anchor.Position-myHRP.Position).Magnitude
            local comps=_chestESP2.components or {}
            if dist>(S.espDist or 1000) then txt.Visible=false; box.Visible=false; tracer.Visible=false; hl.Enabled=false; return end
            local sv,onS=Cam:WorldToViewportPoint(anchor.Position)
            if not onS then txt.Visible=false; box.Visible=false; tracer.Visible=false; hl.Enabled=false; return end
            local scale=math.clamp(1/(sv.Z*0.04),0.5,3); local bw=30*scale; local bh=30*scale; local bx=sv.X-bw/2; local by=sv.Y-bh/2
            if comps["Box 2D"] then box.Position=Vector2.new(bx,by); box.Size=Vector2.new(bw,bh); box.Color=col; box.Visible=true else box.Visible=false end
            if comps["Text"] then local parts={}; if _chestESP2.showName then table.insert(parts,chest.Name:gsub("ChestTemplate","Chest")) end; if _chestESP2.showDist then table.insert(parts,string.format("[%.0fm]",dist)) end; txt.Text=table.concat(parts," "); txt.Color=col; txt.Size=S.espFontSize or 14; txt.Position=Vector2.new(sv.X,by-(S.espFontSize or 14)-2); txt.Visible=#parts>0 else txt.Visible=false end
            if comps["Tracer"] then tracer.From=Vector2.new(sv.X,sv.Y); tracer.To=Vector2.new(Cam.ViewportSize.X/2,Cam.ViewportSize.Y); tracer.Color=col; tracer.Thickness=S.tracerThick or 1; tracer.Visible=true else tracer.Visible=false end
            hl.Enabled=comps["Highlight"] and _chestESPEnabled or false; hl.FillColor=col; hl.OutlineColor=col; hl.FillTransparency=S.hlFillTrans or 0.5; hl.OutlineTransparency=S.hlOutlineTrans or 0
        end)
        _chestESPActive[chest]={txt=txt,box=box,tracer=tracer,hl=hl,conn=conn,
            ancConn=chest.AncestryChanged:Connect(function(_,p) if not p then removeChestESP(chest) end end)}
end
    local function scanChestESP() local di=workspace:FindFirstChild("DialogueInteractables"); if not di then return end; for _,m in ipairs(di:GetChildren()) do if m:IsA("Model") and m.Name:find("ChestTemplate") then addChestESP(m) end end end
    local function stopChestESP() _chestESPEnabled=false; for c in pairs(_chestESPActive) do removeChestESP(c) end end
    local VizL = VizL3
    Tog.ChestESPEnabled = VizL:AddToggle("ChestESPEnabled", {
        Text ="Chest ESP", Default=false,
        Callback=function(p) _chestESPEnabled=p; if p then scanChestESP(); task.spawn(function() while _chestESPEnabled do task.wait(3); scanChestESP() end end); local di=workspace:FindFirstChild("DialogueInteractables"); if di then di.ChildAdded:Connect(function(m) task.wait(0.2); if _chestESPEnabled then addChestESP(m) end end) end else stopChestESP() end end})
    Opt.ChestESPColor = VizL:AddColorPicker("ChestESPColor", { Default=Color3.fromRGB(255,215,0), Callback=function(c) _chestESPColor=c end })
    Tog.ChestESPShowName = VizL:AddToggle("ChestESPShowName", { Text ="Name",     Default=true, Callback=function(p) _chestESP2.showName=p end })
    Tog.ChestESPShowDist = VizL:AddToggle("ChestESPShowDist", { Text ="Distance", Default=true, Callback=function(p) _chestESP2.showDist=p end })
    Opt.ChestESPComponents = VizL:AddDropdown("ChestESPComponents", { Text ="Components", Multi=true, Default=nil, Values ={"Text","Highlight","Tracer","Box 2D"}, Callback=function(v) _chestESP2.components=v end })
    onUnload(function() stopChestESP() end)
end)()

;(function()
    local _portalESPActive={}; local _portalESPEnabled=false; local _portalESPColor=Color3.fromRGB(0,180,255)
    local _portalESP2={components={},showName=true,showDist=true}
    local function removePortalESP(portal) local d=_portalESPActive[portal]; if not d then return end; for _,k in ipairs({"txt","box","tracer"}) do if d[k] then pcall(function() d[k]:Remove() end) end end; if d.hl then pcall(function() d.hl:Destroy() end) end; if d.conn then pcall(function() d.conn:Disconnect() end) end; if d.ancConn then pcall(function() d.ancConn:Disconnect() end) end; _portalESPActive[portal]=nil end
    local function addPortalESP(portal)
        if not portal or _portalESPActive[portal] then return end
        if not portal:IsA("BasePart") or portal.Name~="Portal" then return end
        local txt=Drawing.new("Text"); txt.Center=true; txt.Outline=true; txt.Visible=false; txt.Size=14
        local box=Drawing.new("Square"); box.Filled=false; box.Thickness=1.5; box.Visible=false
        local tracer=Drawing.new("Line"); tracer.Thickness=1; tracer.Visible=false
        local hl=Instance.new("Highlight",portal); hl.FillTransparency=0.5; hl.OutlineTransparency=0; hl.Enabled=false
        local conn=RS.Heartbeat:Connect(function()
            if not (_portalESPEnabled and portal and portal.Parent) then removePortalESP(portal); return end
            local myHRP=getHRP(); if not myHRP then return end
            local col=_portalESPColor; local dist=(portal.Position-myHRP.Position).Magnitude
            local comps=_portalESP2.components or {}
            if dist>(S.espDist or 1000) then txt.Visible=false; box.Visible=false; tracer.Visible=false; hl.Enabled=false; return end
            local sv,onS=Cam:WorldToViewportPoint(portal.Position)
            if not onS then txt.Visible=false; box.Visible=false; tracer.Visible=false; hl.Enabled=false; return end
            local scale=math.clamp(1/(sv.Z*0.04),0.5,3); local bw=30*scale; local bh=30*scale; local bx=sv.X-bw/2; local by=sv.Y-bh/2
            if comps["Box 2D"] then box.Position=Vector2.new(bx,by); box.Size=Vector2.new(bw,bh); box.Color=col; box.Visible=true else box.Visible=false end
            if comps["Text"] then local parts={}; if _portalESP2.showName then table.insert(parts,"Portal") end; if _portalESP2.showDist then table.insert(parts,string.format("[%.0fm]",dist)) end; txt.Text=table.concat(parts," "); txt.Color=col; txt.Size=S.espFontSize or 14; txt.Position=Vector2.new(sv.X,by-(S.espFontSize or 14)-2); txt.Visible=#parts>0 else txt.Visible=false end
            if comps["Tracer"] then tracer.From=Vector2.new(sv.X,sv.Y); tracer.To=Vector2.new(Cam.ViewportSize.X/2,Cam.ViewportSize.Y); tracer.Color=col; tracer.Thickness=S.tracerThick or 1; tracer.Visible=true else tracer.Visible=false end
            hl.Enabled=comps["Highlight"] and _portalESPEnabled or false; hl.FillColor=col; hl.OutlineColor=col; hl.FillTransparency=S.hlFillTrans or 0.5; hl.OutlineTransparency=S.hlOutlineTrans or 0
        end)
        _portalESPActive[portal]={txt=txt,box=box,tracer=tracer,hl=hl,conn=conn,
            ancConn=portal.AncestryChanged:Connect(function(_,p) if not p then removePortalESP(portal) end end)}
    end
    local function scanPortalESP() local spawns=workspace:FindFirstChild("Debris") and workspace.Debris:FindFirstChild("PortalSpawns"); if not spawns then return end; for _,child in ipairs(spawns:GetChildren()) do addPortalESP(child) end end
    local function stopPortalESP() _portalESPEnabled=false; for p in pairs(_portalESPActive) do removePortalESP(p) end end
    local VizR = VizR3
    Tog.PortalESPEnabled = VizR3:AddToggle("PortalESPEnabled", {
        Text ="Portal ESP", Default=false,
        Callback=function(p) _portalESPEnabled=p; if p then scanPortalESP(); local spawns=workspace:FindFirstChild("Debris") and workspace.Debris:FindFirstChild("PortalSpawns"); if spawns then spawns.ChildAdded:Connect(function(child) task.wait(0.2); if _portalESPEnabled then addPortalESP(child) end end) end else stopPortalESP() end end})
    Opt.PortalESPColor = VizR3:AddColorPicker("PortalESPColor", { Default=Color3.fromRGB(0,180,255), Callback=function(c) _portalESPColor=c end })
    Tog.PortalESPShowName = VizR3:AddToggle("PortalESPShowName", { Text ="Name",     Default=true, Callback=function(p) _portalESP2.showName=p end })
    Tog.PortalESPShowDist = VizR3:AddToggle("PortalESPShowDist", { Text ="Distance", Default=true, Callback=function(p) _portalESP2.showDist=p end })
    Opt.PortalESPComponents = VizR3:AddDropdown("PortalESPComponents", { Text ="Components", Multi=true, Default=nil, Values ={"Text","Highlight","Tracer","Box 2D"}, Callback=function(v) _portalESP2.components=v end })
    onUnload(function() stopPortalESP() end)
end)()

;(function()
    local _questESPActive={}; local _questESPEnabled=false; local _questESPColor=Color3.fromRGB(0,255,80)
    local _questESP2={components={},showName=true,showDist=true}

    local function removeQuestESP(npc)
        local d=_questESPActive[npc]; if not d then return end
        pcall(function() if d.txt    then d.txt:Remove()     end end)
        pcall(function() if d.box    then d.box:Remove()     end end)
        pcall(function() if d.tracer then d.tracer:Remove()  end end)
        pcall(function() if d.hl     then d.hl:Destroy()     end end)
        pcall(function() if d.conn   then d.conn:Disconnect() end end)
        pcall(function() if d.ancConn then d.ancConn:Disconnect() end end)
        _questESPActive[npc]=nil
    end

    local function addQuestESP(npc)
        if not npc or _questESPActive[npc] then return end
        if not npc:GetAttribute("QuestAvailable") then return end
        local hrp=npc:FindFirstChild("HumanoidRootPart") or npc.PrimaryPart; if not hrp then return end
        local txt=Drawing.new("Text"); txt.Center=true; txt.Outline=true; txt.Visible=false; txt.Size=14
        local box=Drawing.new("Square"); box.Filled=false; box.Thickness=1.5; box.Visible=false
        local tracer=Drawing.new("Line"); tracer.Thickness=1; tracer.Visible=false
        local hl=Instance.new("Highlight",npc); hl.FillTransparency=0.5; hl.OutlineTransparency=0; hl.Enabled=false
        local conn=RS.Heartbeat:Connect(function()
            if not (_questESPEnabled and npc and npc.Parent) then removeQuestESP(npc); return end
            if not npc:GetAttribute("QuestAvailable") then removeQuestESP(npc); return end
            local myHRP=getHRP(); if not myHRP then return end
            local col=_questESPColor; local dist=(hrp.Position-myHRP.Position).Magnitude
            local comps=_questESP2.components or {}
            if dist>(S.espDist or 1000) then txt.Visible=false; box.Visible=false; tracer.Visible=false; hl.Enabled=false; return end
            local sv,onS=Cam:WorldToViewportPoint(hrp.Position)
            if not onS then txt.Visible=false; box.Visible=false; tracer.Visible=false; hl.Enabled=false; return end
            local scale=math.clamp(1/(sv.Z*0.04),0.5,3); local bw=35*scale; local bh=70*scale; local bx=sv.X-bw/2; local by=sv.Y-bh/2
            if comps["Box 2D"] then box.Position=Vector2.new(bx,by); box.Size=Vector2.new(bw,bh); box.Color=col; box.Visible=true else box.Visible=false end
            if comps["Text"] then
                local parts={}
                if _questESP2.showName then table.insert(parts,npc.Name) end
                if _questESP2.showDist then table.insert(parts,string.format("[%.0fm]",dist)) end
                txt.Text=table.concat(parts," "); txt.Color=col; txt.Size=S.espFontSize or 14
                txt.Position=Vector2.new(sv.X,by-(S.espFontSize or 14)-2); txt.Visible=#parts>0
            else txt.Visible=false end
            if comps["Tracer"] then tracer.From=Vector2.new(sv.X,sv.Y); tracer.To=Vector2.new(Cam.ViewportSize.X/2,Cam.ViewportSize.Y); tracer.Color=col; tracer.Thickness=S.tracerThick or 1; tracer.Visible=true else tracer.Visible=false end
            hl.Enabled=comps["Highlight"] and _questESPEnabled or false; hl.FillColor=col; hl.OutlineColor=col; hl.FillTransparency=S.hlFillTrans or 0.5; hl.OutlineTransparency=S.hlOutlineTrans or 0
        end)
        _questESPActive[npc]={txt=txt,box=box,tracer=tracer,hl=hl,conn=conn,
            ancConn=npc.AncestryChanged:Connect(function(_,p) if not p then removeQuestESP(npc) end end)}
end

    local function scanQuestESP()
        local di=workspace:FindFirstChild("DialogueInteractables"); if not di then return end
        for _,m in ipairs(di:GetChildren()) do if m:IsA("Model") then addQuestESP(m) end end
    end
    local function stopQuestESP() _questESPEnabled=false; for npc in pairs(_questESPActive) do removeQuestESP(npc) end end

    Tog.QuestESPEnabled = VizL4:AddToggle("QuestESPEnabled", {
        Text ="Quest ESP", Default=false,
        Callback=function(p)
            _questESPEnabled=p
            if p then
                scanQuestESP()
                task.spawn(function() while _questESPEnabled do task.wait(3); scanQuestESP() end end)
            else
                stopQuestESP()
            end
        end})
    Opt.QuestESPColor    = VizL4:AddColorPicker("QuestESPColor", { Default=Color3.fromRGB(0,255,80), Callback=function(c) _questESPColor=c end })
    Tog.QuestESPShowName = VizL4:AddToggle("QuestESPShowName", { Text ="Name",       Default=true, Callback=function(p) _questESP2.showName=p end })
    Tog.QuestESPShowDist = VizL4:AddToggle("QuestESPShowDist", { Text ="Distance",   Default=true, Callback=function(p) _questESP2.showDist=p end })
    Opt.QuestESPComponents = VizL4:AddDropdown("QuestESPComponents", { Text ="Components", Multi=true, Default=nil, Values ={"Text","Highlight","Tracer","Box 2D"}, Callback=function(v) _questESP2.components=v end })
    onUnload(function() stopQuestESP() end)
end)()

;(function()
    local _markerESPActive  = {}
    local _markerESPEnabled = false
    local _markerESPColor   = Color3.fromRGB(255, 165, 0)
    local _markerESP2       = { components={}, showName=true, showDist=true }

    local function removeMarkerESP(obj)
        local d=_markerESPActive[obj]; if not d then return end
        pcall(function() if d.txt    then d.txt:Remove()    end end)
        pcall(function() if d.tracer then d.tracer:Remove() end end)
        pcall(function() if d.hl     then d.hl:Destroy()    end end)
        pcall(function() if d.conn   then d.conn:Disconnect() end end)
        pcall(function() if d.ancConn then d.ancConn:Disconnect() end end)
        _markerESPActive[obj]=nil
    end

    local function addMarkerESP(obj, label)
        if not obj or _markerESPActive[obj] then return end
        local part=obj:IsA("BasePart") and obj or (obj:IsA("Model") and (obj.PrimaryPart or obj:FindFirstChildWhichIsA("BasePart")))
        if not part then return end
        local txt    = Drawing.new("Text"); txt.Center=true; txt.Outline=true; txt.Visible=false; txt.Size=14
        local tracer = Drawing.new("Line"); tracer.Thickness=1; tracer.Visible=false
        local hl     = Instance.new("Highlight"); hl.Adornee=obj; hl.FillTransparency=0.5; hl.OutlineTransparency=0; hl.Enabled=false; hl.Parent=obj
        local conn=RS.Heartbeat:Connect(function()
            if not (_markerESPEnabled and obj and obj.Parent) then removeMarkerESP(obj); return end
            local myHRP=getHRP(); if not myHRP then return end
            local col=_markerESPColor
            local dist=(part.Position-myHRP.Position).Magnitude
            local comps=_markerESP2.components or {}
            if dist>(S.espDist or 1000) then txt.Visible=false; tracer.Visible=false; hl.Enabled=false; return end
            local sv,onS=Cam:WorldToViewportPoint(part.Position)
            if not onS then txt.Visible=false; tracer.Visible=false; hl.Enabled=false; return end
            if comps["Text"] then
                local parts={}
                if _markerESP2.showName then table.insert(parts, label or obj.Name) end
                if _markerESP2.showDist then table.insert(parts, string.format("[%.0fm]",dist)) end
                txt.Text=table.concat(parts," "); txt.Color=col; txt.Size=S.espFontSize or 14
                txt.Position=Vector2.new(sv.X,sv.Y-20); txt.Visible=#parts>0
            else txt.Visible=false end
            if comps["Tracer"] then tracer.From=Vector2.new(sv.X,sv.Y); tracer.To=Vector2.new(Cam.ViewportSize.X/2,Cam.ViewportSize.Y); tracer.Color=col; tracer.Thickness=S.tracerThick or 1; tracer.Visible=true else tracer.Visible=false end
            hl.Enabled=comps["Highlight"] and _markerESPEnabled or false
            hl.FillColor=col; hl.OutlineColor=col
        end)
        _markerESPActive[obj]={txt=txt,tracer=tracer,hl=hl,conn=conn,
            ancConn=obj.AncestryChanged:Connect(function(_,p) if not p then removeMarkerESP(obj) end end)}
end

    local function scanMarkerESP()
        local debris=workspace:FindFirstChild("Debris"); if not debris then return end
        for _,child in ipairs(debris:GetChildren()) do
            if child.Name:find("Marker") then
                if child:IsA("Model") or child:IsA("BasePart") then addMarkerESP(child, child.Name) end
                for _,sub in ipairs(child:GetChildren()) do
                    if sub:IsA("BasePart") or sub:IsA("Model") then addMarkerESP(sub, child.Name..": "..sub.Name) end
                end
            end
        end
    end

    local function stopMarkerESP() _markerESPEnabled=false; for obj in pairs(_markerESPActive) do removeMarkerESP(obj) end end

    Tog.MarkerESPEnabled = VizR4:AddToggle("MarkerESPEnabled", {
        Text ="Marker ESP", Default=false,
        Callback=function(p)
            _markerESPEnabled=p
            if p then
                scanMarkerESP()
                task.spawn(function() while _markerESPEnabled do task.wait(5); scanMarkerESP() end end)
            else stopMarkerESP() end
        end})
    Opt.MarkerESPColor    = VizR4:AddColorPicker("MarkerESPColor", { Default=Color3.fromRGB(255,165,0), Callback=function(c) _markerESPColor=c end })
    Tog.MarkerESPShowName = VizR4:AddToggle("MarkerESPShowName", { Text ="Name",     Default=true, Callback=function(p) _markerESP2.showName=p end })
    Tog.MarkerESPShowDist = VizR4:AddToggle("MarkerESPShowDist", { Text ="Distance", Default=true, Callback=function(p) _markerESP2.showDist=p end })
    Opt.MarkerESPComponents = VizR4:AddDropdown("MarkerESPComponents", { Text ="Components", Multi=true, Default=nil,
        Values ={"Text","Highlight","Tracer"},
        Callback=function(v) _markerESP2.components=v end
    })
    onUnload(function() stopMarkerESP() end)
end)()

;(function()
local _wFrameTimer=tick(); local _wFrames=0; _wFPS=60; local _wPingTimer=0; local _wPing=0
RS.RenderStepped:Connect(function()
    _wFrames=_wFrames+1; local now=tick()
    if now-_wFrameTimer>=1 then _wFPS=_wFrames; _wFrames=0; _wFrameTimer=now end
    if now-_wPingTimer>=1 then pcall(function() _wPing=math.floor(game:GetService("Stats").Network.ServerStatsItem["Data Ping"]:GetValue()) end); _wPingTimer=now end
end)
onUnload(function()
    local _el={}; for c in pairs(espActive) do _el[#_el+1]=c end; for _,c in ipairs(_el) do removeESP(c) end
end)

local specTarget=nil; local specConn=nil
local function buildSpecList()
    local list={"--"}; for _,plr in ipairs(PS:GetPlayers()) do if plr~=LP then table.insert(list,plr.Name) end end; return list
end
Opt.SpectatePlayers = WorldL2:AddDropdown("SpectatePlayers", { Text ="Spectate Player", Values =buildSpecList(), Default=1, Multi=false, Callback=function(v) specTarget=type(v)=="table" and next(v) or v end })
WorldL2:AddButton({ Text ="Spectate / Stop", Func =function()
    if specConn then pcall(function() specConn:Disconnect() end); specConn=nil
        local c=getChar(); Cam.CameraSubject=c and c:FindFirstChildOfClass("Humanoid") or c; Cam.CameraType=Enum.CameraType.Custom; return
    end
    local name=tostring(specTarget or ""); local plr=PS:FindFirstChild(name); local char=plr and plr.Character; local hum=char and char:FindFirstChildOfClass("Humanoid")
    if not hum then return end
    Cam.CameraSubject=hum; Cam.CameraType=Enum.CameraType.Custom
    specConn=plr.CharacterAdded:Connect(function(c) task.wait(0.5); local h=c:FindFirstChildOfClass("Humanoid"); if h then Cam.CameraSubject=h end end)
end})
local noFogConn=nil
Tog.NoFog = WorldL2:AddToggle("NoFog", {
    Text ="No Fog", Default=false,
    Callback=function(p)
        if noFogConn then noFogConn:Disconnect(); noFogConn=nil end
        local atmos=LT:FindFirstChildOfClass("Atmosphere")
        if p then
            LT.FogStart=1e9; LT.FogEnd=1e9
            if atmos then atmos.Density=0; atmos.Haze=0; atmos.Glare=0 end
            noFogConn=LT:GetPropertyChangedSignal("FogEnd"):Connect(function() if LT.FogEnd<1e8 then LT.FogStart=1e9; LT.FogEnd=1e9 end end)
        else
            LT.FogStart=0; LT.FogEnd=100000
            if atmos then atmos.Density=0.395; atmos.Haze=0; atmos.Glare=0 end
        end
    end})
Tog.NoAtmosphere = WorldL2:AddToggle("NoAtmosphere", {
    Text ="No Atmosphere", Default=false,
    Callback=function(p)
        pcall(function()
            local atmos=LT:FindFirstChildOfClass("Atmosphere"); if not atmos then return end
            if p then atmos.Density=0; atmos.Offset=0; atmos.Haze=0; atmos.Glare=0
            else atmos.Density=0.395; atmos.Offset=0; atmos.Haze=0; atmos.Glare=0 end
        end)
    end})
WorldL2:AddDivider()
local fbConn=nil
Tog.FullBright = WorldL2:AddToggle("FullBright", {
    Text ="FullBright", Default=false,
    Callback=function(p)
        if fbConn then fbConn:Disconnect(); fbConn=nil end
        if p then fbConn=RS.RenderStepped:Connect(function() LT.Brightness=S.brightness; LT.ClockTime=14; LT.FogEnd=100000; LT.GlobalShadows=false; LT.OutdoorAmbient=Color3.fromRGB(128,128,128) end)
        else LT.Brightness=1; LT.ClockTime=14; LT.FogEnd=1000000; LT.GlobalShadows=true end
    end})
Opt.Brightness = WorldL2:AddSlider("Brightness", { Text ="Brightness", Default=2, Min =0, Max =10, Rounding =1, Callback=function(v) S.brightness=v end })
WorldL2:AddDivider()
local _ambientConn=nil; local _ambientColor=Color3.fromRGB(128,128,128)
Tog.CustomAmbient = WorldL2:AddToggle("CustomAmbient", {
    Text ="World Ambient", Default=false,
    Callback=function(p)
        if _ambientConn then _ambientConn:Disconnect(); _ambientConn=nil end
        if p then _ambientConn=RS.RenderStepped:Connect(function() LT.Ambient=_ambientColor; LT.OutdoorAmbient=_ambientColor end)
        else LT.Ambient=Color3.fromRGB(0,0,0); LT.OutdoorAmbient=Color3.fromRGB(128,128,128) end
    end})
Opt.WorldAmbient = WorldL2:AddColorPicker("WorldAmbient", { Default=Color3.fromRGB(128,128,128), Callback=function(v) _ambientColor=v end })
WorldL2:AddDivider()
local freecamConns={}; local _fcPitch=0; local _fcYaw=0; local _fcPos=Vector3.zero
Tog.Freecam = WorldL2:AddToggle("Freecam", {
    Text ="Free Cam", Default=false,
    Callback=function(p)
        for _,c in ipairs(freecamConns) do pcall(function() c:Disconnect() end) end; freecamConns={}
        UIS.MouseBehavior=Enum.MouseBehavior.Default
        if not p then Cam.CameraType=Enum.CameraType.Custom; return end
        local cf=Cam.CFrame; _fcPos=cf.Position
        _fcYaw=math.atan2(-cf.LookVector.X,-cf.LookVector.Z)
        _fcPitch=math.asin(math.clamp(cf.LookVector.Y,-1,1))
        Cam.CameraType=Enum.CameraType.Scriptable
        local rmb=false
        table.insert(freecamConns,UIS.InputBegan:Connect(function(inp,gpe) if gpe then return end; if inp.UserInputType==Enum.UserInputType.MouseButton2 then rmb=true end end))
        table.insert(freecamConns,UIS.InputEnded:Connect(function(inp) if inp.UserInputType==Enum.UserInputType.MouseButton2 then rmb=false; UIS.MouseBehavior=Enum.MouseBehavior.Default end end))
        table.insert(freecamConns,RS.RenderStepped:Connect(function(dt)
            if rmb then local d=UIS:GetMouseDelta(); _fcYaw=_fcYaw-d.X*S.freeCamSens*0.003; _fcPitch=math.clamp(_fcPitch-d.Y*S.freeCamSens*0.003,-1.55,1.55); UIS.MouseBehavior=Enum.MouseBehavior.LockCurrentPosition
            else UIS.MouseBehavior=Enum.MouseBehavior.Default end
            local rot=CFrame.fromEulerAnglesYXZ(_fcPitch,_fcYaw,0)
            local spd=S.freeCamSpeed*dt*20*(UIS:IsKeyDown(Enum.KeyCode.LeftShift) and 3 or 1)
            if UIS:IsKeyDown(Enum.KeyCode.W)           then _fcPos=_fcPos+rot.LookVector*spd  end
            if UIS:IsKeyDown(Enum.KeyCode.S)           then _fcPos=_fcPos-rot.LookVector*spd  end
            if UIS:IsKeyDown(Enum.KeyCode.A)           then _fcPos=_fcPos-rot.RightVector*spd end
            if UIS:IsKeyDown(Enum.KeyCode.D)           then _fcPos=_fcPos+rot.RightVector*spd end
            if UIS:IsKeyDown(Enum.KeyCode.Space)       then _fcPos=_fcPos+Vector3.yAxis*spd   end
            if UIS:IsKeyDown(Enum.KeyCode.LeftControl) then _fcPos=_fcPos-Vector3.yAxis*spd   end
            Cam.CFrame=CFrame.new(_fcPos)*rot
        end))
    end})
Opt.FreeCamSens  = WorldL2:AddSlider("FreeCamSens", { Text ="Look Sensitivity", Default=0.3, Min =0.1, Max =5,  Rounding =1, Callback=function(v) S.freeCamSens=v  end })
Opt.FreeCamSpeed = WorldL2:AddSlider("FreeCamSpeed", { Text ="Move Speed",       Default=0.5, Min =0.1, Max =50, Rounding =1, Callback=function(v) S.freeCamSpeed=v end })

Tog.FOVChanger = WorldR:AddToggle("FOVChanger", { Text ="Custom FOV", Default=false, Callback=function(p) if p then Cam.FieldOfView=S.fovVal else Cam.FieldOfView=70 end end })
Opt.FOV = WorldR:AddSlider("FOV", { Text ="Camera FOV", Default=70, Min =0, Max =120, Rounding =1, Callback=function(v) S.fovVal=v; if Tog.FOVChanger and Library.Flags["FOVChanger"] and Library.Flags["FOVChanger"].Value then Cam.FieldOfView=v end end })
local _cursorConn=nil; local _cursorDot=nil; local _cursorRing=nil
Tog.CustomCursor = WorldR:AddToggle("CustomCursor", {
    Text ="Dot Cursor", Default=false,
    Callback=function(p)
        if _cursorConn then _cursorConn:Disconnect(); _cursorConn=nil end
        if _cursorDot  then _cursorDot:Remove();  _cursorDot=nil   end
        if _cursorRing then _cursorRing:Remove(); _cursorRing=nil  end
        game:GetService("UserInputService").MouseIconEnabled=not p
        if not p then return end
        _cursorDot=Drawing.new("Circle"); _cursorDot.Radius=6; _cursorDot.Filled=true; _cursorDot.Visible=true; _cursorDot.Color=Color3.new(1,1,1); _cursorDot.Transparency=1; _cursorDot.Thickness=1
        _cursorRing=Drawing.new("Circle"); _cursorRing.Radius=10; _cursorRing.Filled=false; _cursorRing.Visible=true; _cursorRing.Color=Color3.new(1,1,1); _cursorRing.Transparency=0.8; _cursorRing.Thickness=1.5
        _cursorConn=RS.RenderStepped:Connect(function()
            local mp=game:GetService("UserInputService"):GetMouseLocation()
            _cursorDot.Position=mp; _cursorRing.Position=mp
            local curCol=espColor or Color3.new(1,1,1)
            _cursorDot.Color=curCol; _cursorRing.Color=curCol
        end)
    end})
Tog.CursorFilled = WorldR:AddToggle("CursorFilled", { Text ="Cursor Dot Filled", Default=true, Callback=function(p) if _cursorDot then _cursorDot.Filled=p end end })
Opt.CursorSize     = WorldR:AddSlider("CursorSize", { Text ="Cursor Size",  Default=6,  Min =1, Max =20, Rounding =0, Callback=function(v) if _cursorDot  then _cursorDot.Radius=v  end end })
Opt.CursorRingSize = WorldR:AddSlider("CursorRingSize", { Text ="Ring Size",    Default=10, Min =0, Max =30, Rounding =0, Callback=function(v) if _cursorRing then _cursorRing.Radius=v end end })
WorldR:AddDivider()
Tog.CustomCrosshair = WorldR:AddToggle("CustomCrosshair", {
    Text ="Crosshair", Default=false,
    Callback=function(p)
        if p then
            if not getgenv()._ZHCrosshair then
                local d=Drawing.new("Square"); d.Size=Vector2.new(14,14); d.Position=Vector2.new(Cam.ViewportSize.X/2-7,Cam.ViewportSize.Y/2-7); d.Color=Color3.new(1,1,1); d.Transparency=1; d.Filled=false; d.Thickness=1; d.Visible=true
                local d2=Drawing.new("Line"); d2.From=Vector2.new(Cam.ViewportSize.X/2-6,Cam.ViewportSize.Y/2); d2.To=Vector2.new(Cam.ViewportSize.X/2+6,Cam.ViewportSize.Y/2); d2.Color=Color3.new(1,1,1); d2.Thickness=1; d2.Visible=true
                local d3=Drawing.new("Line"); d3.From=Vector2.new(Cam.ViewportSize.X/2,Cam.ViewportSize.Y/2-6); d3.To=Vector2.new(Cam.ViewportSize.X/2,Cam.ViewportSize.Y/2+6); d3.Color=Color3.new(1,1,1); d3.Thickness=1; d3.Visible=true
                getgenv()._ZHCrosshair={d,d2,d3}
            end
        else
            if getgenv()._ZHCrosshair then for _,d in ipairs(getgenv()._ZHCrosshair) do pcall(function() d:Remove() end) end; getgenv()._ZHCrosshair=nil end
        end
    end})

Tog.AntiLag = WorldR2:AddToggle("AntiLag", {
    Text ="Anti-Lag", Default=false,
    Callback=function(p)
        pcall(function() setfpscap(p and 0 or 60) end)
        local LT3=game:GetService("Lighting")
        if p then LT3.GlobalShadows=false; LT3.Brightness=2; for _,v in ipairs(workspace:GetDescendants()) do if v:IsA("ParticleEmitter") or v:IsA("Trail") or v:IsA("Smoke") or v:IsA("Fire") then pcall(function() v.Enabled=false end) end end
        else LT3.GlobalShadows=true end
    end})
Opt.AntiLagFPSCap = WorldR2:AddSlider("AntiLagFPSCap", { Text ="FPS Cap", Default=0, Min =0, Max =360, Rounding =0, Callback=function(v) pcall(function() setfpscap(v==0 and math.huge or v) end) end })
WorldR2:AddButton({ Text ="Boost FPS", Func =function()
    pcall(function()
        for _,v in ipairs(game:GetDescendants()) do
            if v:IsA("ParticleEmitter") or v:IsA("Smoke") or v:IsA("Fire") or v:IsA("Sparkles") then v.Enabled=false end
            if v:IsA("BloomEffect") or v:IsA("BlurEffect") or v:IsA("DepthOfFieldEffect") or v:IsA("SunRaysEffect") then v.Enabled=false end
        end
        LT.GlobalShadows=false; LT.Brightness=5
    end)
end})
WorldR3:AddButton({ Text ="Copy Coordinates", Func =function()
    local hrp=getHRP(); if not hrp then return end
    local p=hrp.Position; local str=string.format("%.2f, %.2f, %.2f",p.X,p.Y,p.Z); setclipboard(str)
end})
local nearbyConn=nil; local nearbyTracked={}; local _nearbyTimer=0
Tog.NearbyNotifier = WorldR3:AddToggle("NearbyNotifier", {
    Text ="Nearby Alert", Default=false,
    Callback=function(p)
        if nearbyConn then nearbyConn:Disconnect(); nearbyConn=nil end; nearbyTracked={}
        if not p then return end
        nearbyConn=RS.Heartbeat:Connect(function()
            local now=tick(); if now-_nearbyTimer<0.5 then return end; _nearbyTimer=now
            local myHRP=getHRP(); if not myHRP then return end
            local dist=Library.Options["NearbyDist"] and Library.Options["NearbyDist"].Value or 500
            for _,plr in ipairs(PS:GetPlayers()) do
                if plr~=LP and plr.Character then
                    local hrp=plr.Character:FindFirstChild("HumanoidRootPart")
                    if hrp then
                        local mag=(myHRP.Position-hrp.Position).Magnitude; local id=plr.UserId
                        if mag<=dist and not nearbyTracked[id] then nearbyTracked[id]=true; notify(plr.Name.." is nearby ["..math.floor(mag).."m]",6)
                        elseif mag>dist and nearbyTracked[id] then nearbyTracked[id]=nil; notify(plr.Name.." left range",3) end
                    end
                end
            end
        end)
    end})
Opt.NearbyDist = WorldR3:AddSlider("NearbyDist", { Text ="Alert Range", Default=500, Min =0, Max =10000, Rounding =0, Callback=function() end })

onUnload(function()
    if _ambientConn then _ambientConn:Disconnect() end
    if noFogConn then noFogConn:Disconnect(); LT.FogStart=0; LT.FogEnd=100000 end
    if fbConn then fbConn:Disconnect(); LT.GlobalShadows=true; LT.Brightness=1 end
    if specConn then specConn:Disconnect() end
    if _cursorConn then _cursorConn:Disconnect() end
    if _cursorDot  then pcall(function() _cursorDot:Remove() end) end
    if _cursorRing then pcall(function() _cursorRing:Remove() end) end
    UIS.MouseIconEnabled=true
    for _,c in ipairs(freecamConns) do pcall(function() c:Disconnect() end) end
    Cam.FieldOfView=70; Cam.CameraType=Enum.CameraType.Custom; UIS.MouseBehavior=Enum.MouseBehavior.Default
end)

local _coordInput=nil
Opt.Coordinates = NavL:AddInput("Coordinates", { Default="", Placeholder="X, Y, Z", Callback =function() end })
NavL:AddButton({ Text ="Tween To", Func =function()
    local v=Library.Options["Coordinates"] and Library.Options["Coordinates"].Value or ""
    local x,y,z=v:match("([%-%d%.]+)%s*,%s*([%-%d%.]+)%s*,%s*([%-%d%.]+)")
    if x then task.spawn(function() tweenTo(CFrame.new(tonumber(x),tonumber(y),tonumber(z))) end) end
end})
NavL:AddButton({ Text ="Copy Position", Func =function()
    local hrp=getHRP(); if hrp then setclipboard(tostring(hrp.Position)) end
end})
NavL:AddDivider()
local clickTPConn=nil
Tog.ClickTP = NavL:AddToggle("ClickTP", {
    Text ="Click TP", Default=false,
    Callback=function(p)
        if clickTPConn then clickTPConn:Disconnect(); clickTPConn=nil end
        if p then clickTPConn=UIS.InputBegan:Connect(function(inp,gpe)
            if gpe or inp.UserInputType~=Enum.UserInputType.MouseButton2 then return end
            local ray=Cam:ScreenPointToRay(inp.Position.X,inp.Position.Y)
            local res=workspace:Raycast(ray.Origin,ray.Direction*2000)
            if res then task.spawn(function() tweenTo(CFrame.new(res.Position+Vector3.new(0,3,0))) end) end
        end) end
    end})

NavL2:AddLabel("NPC Teleport")
local _npcTPMap={}; local _npcListPending=false
local function _buildNPCList()
    if _npcListPending then return end; _npcListPending=true
    task.defer(function()
        _npcListPending=false
        local di=workspace:FindFirstChild("DialogueInteractables"); if not di then return end
        local list={}; _npcTPMap={}
        for _,model in ipairs(di:GetChildren()) do
            if not model:IsA("Model") then continue end
            local hrp=model:FindFirstChild("HumanoidRootPart") or model.PrimaryPart
            if hrp and not _npcTPMap[model.Name] then _npcTPMap[model.Name]=hrp.CFrame; table.insert(list,model.Name) end
        end
        table.sort(list); if #list==0 then list={"No NPCs found"} end
        pcall(function() if Opt.NPCSelect then Library.Options["NPCSelect"]:SetValues(list) end end)
    end)
end
Opt.NPCSelect = NavL2:AddDropdown("NPCSelect", { Text ="NPC", Values ={"--"}, Default=1, Multi=false, Callback=function() end })
NavL2:AddButton({ Text ="Teleport to NPC", Func =function()
    local sel=Library.Options["NPCSelect"] and Library.Options["NPCSelect"].Value; if not sel or not _npcTPMap[sel] then return end
    task.spawn(function() tweenTo(_npcTPMap[sel]*CFrame.new(0,0,4)) end)
end})
task.spawn(function() task.wait(1); _buildNPCList(); local di=workspace:FindFirstChild("DialogueInteractables"); if di then di.ChildAdded:Connect(function() task.wait(0.5); _buildNPCList() end); di.ChildRemoved:Connect(function() task.wait(0.5); _buildNPCList() end) end end)

NavL2:AddDivider()
NavL2:AddLabel("Location Teleport")
local _locTPMap={}
local function _buildLocList()
    local lm=workspace:FindFirstChild("Debris") and workspace.Debris:FindFirstChild("LocationMarkers"); if not lm then return end
    local list={}; _locTPMap={}
    for _,child in ipairs(lm:GetChildren()) do
        local part=child:IsA("BasePart") and child or (child:IsA("Model") and (child.PrimaryPart or child:FindFirstChildWhichIsA("BasePart")))
        if part and not _locTPMap[child.Name] then _locTPMap[child.Name]=part.CFrame; table.insert(list,child.Name) end
    end
    table.sort(list); if #list==0 then list={"No locations found"} end
    pcall(function() if Opt.LocSelect then Library.Options["LocSelect"]:SetValues(list) end end)
end
Opt.LocSelect = NavL2:AddDropdown("LocSelect", { Text ="Location", Values ={"--"}, Default=1, Multi=false, Callback=function() end })
NavL2:AddButton({ Text ="Teleport to Location", Func =function()
    local sel=Library.Options["LocSelect"] and Library.Options["LocSelect"].Value; if not sel or not _locTPMap[sel] then return end
    task.spawn(function() tweenTo(_locTPMap[sel]*CFrame.new(0,0,4)) end)
end})
task.spawn(function() task.wait(1); _buildLocList() end)

NavL2:AddDivider()
NavL2:AddLabel("Map Teleporter")
local MapData = {
	{ Name = "Soul Society Outskirts", PlaceId = 14218523102 },
	{ Name = "Arctic Plains", PlaceId = 15079707729 },
	{ Name = "Las Noches", PlaceId = 11127942816 },
	{ Name = "Soul Society", PlaceId = 12337012844 },
	{ Name = "Wandenreich", PlaceId = 11780443293 },
	{ Name = "Hueco Mundo", PlaceId = 11131834995 },
	{ Name = "Snowy Mountain", PlaceId = 14321102147 },
	{ Name = "Arctic Cave", PlaceId = 15645525857 },
	{ Name = "Snow Camp", PlaceId = 18972283841 },
	{ Name = "Outskirts Swamp", PlaceId = 95787471190312 },
	{ Name = "Menos Forest", PlaceId = 16914874220 },
	{ Name = "Human World", PlaceId = 14219489601 }
}
local _mapNames={}; for _,m in ipairs(MapData) do table.insert(_mapNames,m.Name) end
Opt.MapSelect = NavL2:AddDropdown("MapSelect", { Text ="Map", Values =_mapNames, Default=1, Multi=false, Callback=function() end })
NavL2:AddButton({ Text ="Teleport to Map", Func =function()
	local sel=Library.Options["MapSelect"] and Library.Options["MapSelect"].Value; if not sel then return end
	local map=nil; for _,m in ipairs(MapData) do if m.Text ==sel then map=m; break end end
	if not map then return end
	local TeleportToServer=ReplicatedStorage:FindFirstChild("Requests") and ReplicatedStorage.Requests:FindFirstChild("TeleportToServer")
	if not TeleportToServer then return end
	pcall(function() TeleportToServer:InvokeServer({ PlaceId=map.PlaceId, ReserveServerCode="", IsRaid=true }) end)
end})

NavL2:AddDivider()
NavL2:AddLabel("Must be in Soul Society Outskirts")
NavL2:AddButton({ Text ="Insta TP to Marsh", Func =function()
    local hrp=LP.Character and LP.Character:FindFirstChild("HumanoidRootPart"); if not hrp then return end
    local marsh=workspace.Debris:FindFirstChild("MarshTeleporters"); if not marsh then return end
    for _,child in ipairs(marsh:GetChildren()) do
        if child:IsA("BasePart") then pcall(firetouchinterest, child, hrp, 0) end
    end
end})
NavL2:AddDivider()
NavL2:AddLabel("Must be in Marsh")
NavL2:AddButton({ Text ="Insta TP to Soul Society Outskirts", Func =function()
    local hrp=LP.Character and LP.Character:FindFirstChild("HumanoidRootPart"); if not hrp then return end
    local tp=workspace.Debris:FindFirstChild("Teleporter")
    if tp and tp:IsA("BasePart") then pcall(firetouchinterest, tp, hrp, 0) end
end})

NavL2:AddDivider()
NavL2:AddLabel("Dangai Portal")
NavL2:AddButton({ Text ="Tween to Portal", Func =function()
    local spawns=workspace:FindFirstChild("Debris") and workspace.Debris:FindFirstChild("PortalSpawns"); if not spawns then return end
    for _,child in ipairs(spawns:GetChildren()) do
        if child.Text =="Portal" and child:IsA("BasePart") then task.spawn(function() tweenTo(child.CFrame*CFrame.new(0,0,5)) end); return end
    end
end})

Tog.AttachNearby = NavR:AddToggle("AttachNearby", {
    Text ="Attach Nearby", Default=false,
    Callback=function(p)
        if not p then return end
        task.spawn(function()
            while Tog.AttachNearby and Library.Flags["AttachNearby"] and Library.Flags["AttachNearby"].Value do
                local myHRP=getHRP(); if not myHRP then task.wait(0.1); continue end
                local range=Library.Options["MobsRange"] and Library.Options["MobsRange"].Value or 1000
                local best,bestD=nil,range
                for _,plr in ipairs(PS:GetPlayers()) do
                    if plr~=LP and plr.Character then
                        local hrp=plr.Character:FindFirstChild("HumanoidRootPart"); local hum=plr.Character:FindFirstChildOfClass("Humanoid")
                        if hrp and hum and hum.Health>0 then local d=(myHRP.Position-hrp.Position).Magnitude; if d<bestD then best=hrp; bestD=d end end
                    end
                end
                if best then
                    local offset=CFrame.new(0,Library.Options["MobsHeight"] and Library.Options["MobsHeight"].Value or 0,Library.Options["MobsDistance"] and Library.Options["MobsDistance"].Value or 0)
                    myHRP.CFrame=best.CFrame*offset; myHRP.AssemblyLinearVelocity=Vector3.zero
                end
                task.wait(0.1)
            end
        end)
    end})
NavR:AddDivider()
end)()
;(function()
    local function buildAttachPlrList() local l={"--"}; for _,p in ipairs(PS:GetPlayers()) do if p~=LP then table.insert(l,p.Name) end end; return l end
    Opt.AttachTargetPlayer = NavR:AddDropdown("AttachTargetPlayer", { Text ="Attach Target", Values =buildAttachPlrList(), Default=1, Multi=false, Callback=function() end })
end)()
Tog.AttachSelected = NavR:AddToggle("AttachSelected", {
    Text ="Attach Player", Default=false,
    Callback=function(p)
        if not p then return end
        task.spawn(function()
            while Tog.AttachSelected and Library.Flags["AttachSelected"] and Library.Flags["AttachSelected"].Value do
                local myHRP=getHRP(); if not myHRP then task.wait(); continue end
                local val=Library.Options["AttachTargetPlayer"] and Library.Options["AttachTargetPlayer"].Value
                local plr=type(val)=="string" and PS:FindFirstChild(val) or val
                if plr and plr~=LP and plr.Character then
                    local hrp=plr.Character:FindFirstChild("HumanoidRootPart"); local hum=plr.Character:FindFirstChildOfClass("Humanoid")
                    if hrp and hum and hum.Health>0 then
                        local offset=CFrame.new(0,Library.Options["MobsHeight"] and Library.Options["MobsHeight"].Value or 0,Library.Options["MobsDistance"] and Library.Options["MobsDistance"].Value or 0)
                        tweenTo(hrp.CFrame*offset)
end
                end
                task.wait()
            end
        end)
    end})
Opt.MobsRange    = NavR2:AddSlider("MobsRange", { Text ="Range",    Default=1000, Min =0,   Max =10000, Rounding =0, Callback=function() end })
Opt.MobsDistance = NavR2:AddSlider("MobsDistance", { Text ="Distance", Default=0,    Min =-50, Max =50,   Rounding =0, Callback=function() end })
Opt.MobsHeight   = NavR2:AddSlider("MobsHeight", { Text ="Height",   Default=0,    Min =-50, Max =50,   Rounding =0, Callback=function() end })
NavR2:AddDivider()

-- World Portal
NavR2:AddLabel("World Portal")

-- display name → { internal Id for portal, placeId for server hop }
local _WORLDS = {
    ["Fort Adams"]             = { id="SnowyMountain",        placeId=14219489601         },
    ["Soul Society Outskirts"] = { id="SoulSocietyOutskirts", placeId=121345602945775     },
    ["Las Noches"]             = { id="LasNoches",            placeId=119777193083785     },
    ["Wandenreich"]            = { id="Wandenreich",          placeId=11780443293         },
    ["Soul Society"]           = { id="SoulSociety",          placeId=13229243486         },
    ["Hueco Mundo"]            = { id="HuecoMundo",           placeId=18972283841         },
    ["Human World"]            = { id="HumanWorld",           placeId=10626511620         },
    ["Menos Forest"]           = { id="MenosForest",          placeId=12337012844         },
    ["Arctic Plains"]          = { id="ArcticPlains",         placeId=17083682617         },
    ["Arctic Cave"]            = { id="ArcticCave",           placeId=102123868363969     },
    ["Snow Encampment"]        = { id="SnowCamp",             placeId=9861495985          },
    ["The Marsh"]              = { id="OutskirtsSwamp",       placeId=14321102147         },
    ["Trade Realm"]            = { id="TradeRealm",           placeId=95787471190312      },
    ["Inner World"]            = { id="InnerWorld",           placeId=15645525857         },
    ["Valley of Screams"]      = { id="ValleyOfScreams",      placeId=16914874220         },
    ["Dangai"]                 = { id="Dangai",               placeId=6270290407          },
    ["Tournament"]             = { id="Tournament",           placeId=11131834995         },
    ["Hub"]                    = { id="Hub",                  placeId=11127942816         },
}

local _worldList = {}
for name in pairs(_WORLDS) do table.insert(_worldList, name) end
table.sort(_worldList)

local _portalUnlocked = false

local function _hookAllWorlds()
    local IdMap = require(ReplicatedStorage.SharedAssets.Info.PlaceIds.IDMap.MainGame)
    local allWorldsList = {}
    for _, name in next, IdMap do table.insert(allWorldsList, name) end

    -- hook GetCharacterData so every caller gets unlocked data
    pcall(function()
        local PD = require(ReplicatedStorage.SharedModules.PlayerData)
        local origGCD = PD.GetCharacterData
        PD.GetCharacterData = function(self, player)
            local cd = origGCD(self, player)
            if cd and player == LP then
                cd.UnlockedHueco = true
                if cd.QuestData and cd.QuestData.CompletedQuests then
                    cd.QuestData.CompletedQuests["40"]  = true
                    cd.QuestData.CompletedQuests["114"] = true
                end
            end
            return cd
        end
    end)

    -- hook GetJoinablePlaces to return all worlds
    local GJP = require(ReplicatedStorage.SharedModules.Places.GetJoinablePlaces)
    hookfunction(GJP, function() return allWorldsList end)

    -- hook the WorldPortal OnClientEvent handler's upvalues
    -- to catch any secondary checks inside the LocalScript
    pcall(function()
        local conns = getconnections(ReplicatedStorage.Requests.WorldPortal.OnClientEvent)
        for _, conn in ipairs(conns) do
            local fn = conn.Function
            if not fn then continue end
            for _, uv in ipairs(getupvalues(fn)) do
                if type(uv) == "function" then
                    -- if it's GetJoinablePlaces inside the handler, hook it too
                    pcall(function()
                        local uvInner = getupvalues(uv)
                        if uvInner and #uvInner > 0 then
                            hookfunction(uv, function() return allWorldsList end)
                        end
                    end)
                end
            end
        end
    end)

    -- hook parseChoiceTbl (upvalue [2]) so RadialWheel UI shows all worlds
    hookfunction(
        getupvalues(require(ReplicatedStorage.SharedModules.UIManager.Components.Prompts.RadialWheel))[2],
        function()
            local all = {}
            for _, name in next, IdMap do
                all[#all + 1] = { AppearAs = name, Id = name }
            end
            return all
        end
    )
end

Tog.UnlockAllWorlds = NavR2:AddToggle("UnlockAllWorlds", {
    Text = "Unlock All Worlds",
    Default = false,
    Callback = function(p)
        if not p or _portalUnlocked then return end
        pcall(_hookAllWorlds)
        _portalUnlocked = true
        notify("All worlds unlocked", 2)
    end})

NavR2:AddDivider()

Opt.WorldHopSelect = NavR2:AddDropdown("WorldHopSelect", {
    Text = "World",
    Values = _worldList,
    Default  = 1,
    Multi    = false,
    Callback = function() end
})

NavR2:AddButton({
    Text = "Insta Portal TP",
    Func = function()
        local sel = Library.Options["WorldHopSelect"] and Library.Options["WorldHopSelect"].Value
        if not sel then notify("Select a world", 2); return end
        local w = _WORLDS[sel]
        if not w then notify("World not mapped", 2); return end
        notify("Portaling to " .. sel .. "...", 3)
        pcall(function()
            -- hook GetJoinablePlaces to return only our world
            local GJP = require(ReplicatedStorage.SharedModules.Places.GetJoinablePlaces)
            hookfunction(GJP, function() return { w.id } end)
            -- hook parseChoiceTbl to show only our world in UI
            hookfunction(
                getupvalues(require(ReplicatedStorage.SharedModules.UIManager.Components.Prompts.RadialWheel))[2],
                function() return {{ AppearAs = w.id, Id = w.id }} end
            )
            ReplicatedStorage.Requests.WorldPortal:FireServer()
        end)
        -- RadialWheel waits 0.5s then blocks on InputBegan:Wait()
        -- one choice = auto-hovered, fire click to confirm
        task.spawn(function()
            task.wait(0.6)
            pcall(function()
                firesignal(game:GetService("UserInputService").InputBegan,
                    {UserInputType=Enum.UserInputType.MouseButton1,
                     KeyCode=Enum.KeyCode.Unknown,
                     Delta=Vector3.zero,
                     Position=Vector3.zero}, false)
            end)
        end)
    end
})

NavR2:AddButton({
    Text = "Hop to World",
    Func = function()
        local sel = Library.Options["WorldHopSelect"] and Library.Options["WorldHopSelect"].Value
        if not sel then notify("Select a world", 2); return end
        local w = _WORLDS[sel]
        if not w then notify("World not mapped", 2); return end
        notify("Portaling to " .. sel .. "...", 3)
        pcall(function()
            local GJP = require(ReplicatedStorage.SharedModules.Places.GetJoinablePlaces)
            hookfunction(GJP, function() return { w.id } end)
            hookfunction(
                getupvalues(require(ReplicatedStorage.SharedModules.UIManager.Components.Prompts.RadialWheel))[2],
                function() return {{ AppearAs = w.id, Id = w.id }} end
            )
            ReplicatedStorage.Requests.WorldPortal:FireServer()
        end)
    end
})

NavR2:AddButton({
    Text = "Open Portal UI",
    Func = function()
        if not _portalUnlocked then pcall(_hookAllWorlds); _portalUnlocked = true end
        pcall(function() ReplicatedStorage.Requests.WorldPortal:FireServer() end)
    end
})

onUnload(function()
    if clickTPConn then clickTPConn:Disconnect() end
    if nearbyConn then nearbyConn:Disconnect() end
end)

;(function()
    local HOG="Hogyoku Shard"
    local _sniperConn=nil; local _sniperTarget="Any"
    local _notifConn=nil; local _notifSeen={}

    local function playersWithHog()
        local list={"Any"}
        for _,plr in ipairs(PS:GetPlayers()) do
            if plr~=LP and plr.Backpack:FindFirstChild(HOG) then
                table.insert(list,plr.Name)
            end
        end
        return list
    end

    local function nearestHogTarget()
        local hrp=getHRP(); if not hrp then return end
        local best,bestD=nil,math.huge
        for _,plr in ipairs(PS:GetPlayers()) do
            if plr==LP then continue end
            if _sniperTarget~="Any" and plr.Name~=_sniperTarget then continue end
            if not plr.Backpack:FindFirstChild(HOG) then continue end
            local c=plr.Character; if not c then continue end
            local r=c:FindFirstChild("HumanoidRootPart"); local h=c:FindFirstChildOfClass("Humanoid")
            if not (r and h and h.Health>0) then continue end
            local d=(r.Position-hrp.Position).Magnitude
            if d<bestD then best=c; bestD=d end
        end
        return best
    end

    Opt.SniperSelect = MiscL5:AddDropdown("SniperSelect", {
        Text ="Target", Values ={"Any"}, Default=1, Multi=false,
        Callback=function(v) _sniperTarget=type(v)=="table" and next(v) or (v or "Any") end
    })
    MiscL5:AddButton({ Text ="Scan Players", Func =function()
        pcall(function()
            Library.Options["SniperSelect"]:SetValues(playersWithHog())
        end)
    end})
    Tog.HogyokuSniper = MiscL5:AddToggle("HogyokuSniper", {
        Text ="Hog Sniper", Default=false,
        Callback=function(p)
            farmState.plrs=p
            if _sniperConn then _sniperConn:Disconnect(); _sniperConn=nil end
            if p then _sniperConn=makeFarmLoop(nearestHogTarget,"plrs")
            else disableFarmCombat() end
        end})

    MiscL5:AddDivider()

    Tog.HogNotifier = MiscL5:AddToggle("HogNotifier", {
        Text ="Hog Notifier", Default=false,
        Callback=function(p)
            if _notifConn then _notifConn:Disconnect(); _notifConn=nil end
            _notifSeen={}
            if not p then return end
            _notifConn=RS.Heartbeat:Connect(function()
                for _,plr in ipairs(PS:GetPlayers()) do
                    if plr==LP then continue end
                    if plr.Backpack:FindFirstChild(HOG) and not _notifSeen[plr.Name] then
                        _notifSeen[plr.Name]=true
                        notify(plr.Name.." has a Hogyoku Shard!",5)
                        -- refresh scan dropdown
                        pcall(function() Library.Options["SniperSelect"]:SetValues(playersWithHog()) end)
                    elseif not plr.Backpack:FindFirstChild(HOG) then
                        _notifSeen[plr.Name]=nil
                    end
                end
            end)
        end})

    onUnload(function()
        if _sniperConn then _sniperConn:Disconnect() end
        if _notifConn then _notifConn:Disconnect() end
    end)
end)()

MiscL4:AddDivider()
local _ownHighlights={}; local _ownVizConn=nil
local _ownedColor=Color3.fromRGB(0,255,0); local _notOwnedColor=Color3.fromRGB(255,0,0)
local function hasNetworkOwnership(part)
    if isnetworkowner then local ok,r=pcall(isnetworkowner,part); return ok and r end
    local ok,result=pcall(function()
        local myHRP2=LP.Character and LP.Character:FindFirstChild("HumanoidRootPart"); if not myHRP2 then return false end
        local ok1,myId=pcall(gethiddenproperty,myHRP2,"NetworkOwnerV3"); local ok2,partId=pcall(gethiddenproperty,part,"NetworkOwnerV3")
        return ok1 and ok2 and myId~=nil and myId==partId
    end)
    return ok and result
end
local function updateOwnershipViz()
    for part,hl in pairs(_ownHighlights) do if not part or not part.Parent then pcall(function() hl:Destroy() end); _ownHighlights[part]=nil end end
    local ents=workspace:FindFirstChild("Living"); if not ents then return end
    for _,model in ipairs(ents:GetChildren()) do
        if not model:IsA("Model") then continue end
        local hrp2=model:FindFirstChild("HumanoidRootPart"); if not hrp2 then continue end
        if not _ownHighlights[hrp2] then local hl2=Instance.new("Highlight",model); hl2.FillTransparency=0.7; _ownHighlights[hrp2]=hl2 end
        local hl2=_ownHighlights[hrp2]
        local owned=pcall(hasNetworkOwnership,hrp2) and hasNetworkOwnership(hrp2)
        hl2.FillColor=owned and _ownedColor or _notOwnedColor
        hl2.OutlineColor=hl2.FillColor
    end
end
Tog.ShowOwnership = MiscL4:AddToggle("ShowOwnership", {
    Text ="Show Ownership", Default=false,
    Callback=function(p)
        if p then
            if not _ownVizConn then _ownVizConn=RS.Heartbeat:Connect(function() if Tog.ShowOwnership and Library.Flags["ShowOwnership"] and Library.Flags["ShowOwnership"].Value then updateOwnershipViz() end end) end
        else
            if _ownVizConn then _ownVizConn:Disconnect(); _ownVizConn=nil end
            for _,hl2 in pairs(_ownHighlights) do pcall(function() hl2:Destroy() end) end; _ownHighlights={}
        end
    end})
MiscL4:AddDivider()
Opt.OwnedColor    = MiscL4:AddColorPicker("OwnedColor", { Default=Color3.fromRGB(0,255,0), Callback=function(c) _ownedColor=c    end })
Opt.NotOwnedColor = MiscL4:AddColorPicker("NotOwnedColor", { Default=Color3.fromRGB(255,0,0), Callback=function(c) _notOwnedColor=c end })
onUnload(function()
    if _ownVizConn then _ownVizConn:Disconnect() end
    for _,hl2 in pairs(_ownHighlights) do pcall(function() hl2:Destroy() end) end
end)

MiscR:AddDivider()
Tog.AutoClash = MiscR:AddToggle("AutoClash", {
    Text ="Auto Clash", Default=false,
    Callback=function(p)
        if not p then return end
        task.spawn(function()
            local function getClashEvent()
                for _,obj in ipairs(getnilinstances()) do if obj.Text =="ClashEvent" and obj:IsA("RemoteEvent") then return obj end end
            end
            while Tog.AutoClash and Library.Flags["AutoClash"] and Library.Flags["AutoClash"].Value do
                local living=workspace:FindFirstChild("Living"); local myModel=living and living:FindFirstChild(LP.Name)
                local status=myModel and myModel:FindFirstChild("Status")
                if status and (status:FindFirstChild("Clashing") or status:FindFirstChild("InGeki")) then
                    local ev=getClashEvent(); if ev then pcall(function() ev:FireServer(math.pi*0.8) end) end
                end
                task.wait(0.05)
            end
        end)
    end})
Tog.AutoKidoChant = MiscR:AddToggle("AutoKidoChant", {
    Text ="Auto Kido Chant", Default=false,
    Callback=function(p)
        local chant=ReplicatedStorage.Requests:WaitForChild("ChantMinigame")
        if p then chant.OnClientInvoke=function() return true end else chant.OnClientInvoke=nil end
    end})
local _meditateConn=nil
Tog.AutoMeditate = MiscR:AddToggle("AutoMeditate", {
    Text ="Auto Meditate", Default=false,
    Callback=function(p)
        if _meditateConn then _meditateConn:Disconnect(); _meditateConn=nil end
        if not p then return end
        _meditateConn=RS.Heartbeat:Connect(function()
            pcall(function()
                local living=workspace:FindFirstChild("Living"); if not living then return end
                local myModel=living:FindFirstChild(LP.Name); if not myModel then return end
                local s=myModel:FindFirstChild("Status"); if not s then return end
                if not s:FindFirstChild("Meditating") and not s:FindFirstChild("InCombat") then
                    local r=_getRemote("Meditate"); if r then r:FireServer() end
                end
            end)
        end)
    end})
onUnload(function() if _meditateConn then _meditateConn:Disconnect() end end)
MiscR:AddDivider()
task.spawn(function()
    local _noCombatConn=nil; local _noCombatThread=nil
    Tog.NoCombatTag = MiscR:AddToggle("NoCombatTag", {
        Text ="No Combat Tag", Default=false,
        Callback=function(p)
            if _noCombatConn then _noCombatConn:Disconnect(); _noCombatConn=nil end
            if _noCombatThread then task.cancel(_noCombatThread); _noCombatThread=nil end
            if not p then return end
            local CS=game:GetService("CollectionService")
            _noCombatConn=CS:GetInstanceAddedSignal("InCombat"):Connect(function(instance) if instance==LP then CS:RemoveTag(LP,"InCombat") end end)
            _noCombatThread=task.spawn(function() while true do if CS:HasTag(LP,"InCombat") then CS:RemoveTag(LP,"InCombat") end; task.wait(0.05) end end)
        end})
    onUnload(function() if _noCombatConn then _noCombatConn:Disconnect() end; if _noCombatThread then task.cancel(_noCombatThread) end end)
end)
MiscR:AddDivider()
;(function()
    local SP={conns={}}
    SP.RS=RS; SP.LP=LP
    SP.getLivStat=function() local living=workspace:FindFirstChild("Living"); if not living then return nil end; local m=living:FindFirstChild(LP.Name); if not m then return nil end; return m:FindFirstChild("Status") end
    SP.getCharStat=function() local c=LP.Character; if not c then return nil end; return c:FindFirstChild("Status") end
    SP.clearStatuses=function(statusFolder,nameList) if not statusFolder then return end; for _,name in ipairs(nameList) do local v=statusFolder:FindFirstChild(name); if v then pcall(function() v:Destroy() end) end end end
    Tog.NoFallDmg = MiscR2:AddToggle("NoFallDmg", {
        Text ="No Fall Damage", Default=true,
        Callback=function(p)
            if SP.conns.fall then SP.conns.fall:Disconnect(); SP.conns.fall=nil end
            if p then
                pcall(function() _injectStatus("FallImmunity") end)
                SP.conns.fall=RS.Heartbeat:Connect(function() pcall(function() _injectStatus("FallImmunity") end) end)
            else pcall(function() _removeStatus("FallImmunity") end) end
end})
    Tog.NoStun = MiscR2:AddToggle("NoStun", {
        Text ="No Stun", Default=false,
        Callback=function(p)
            if SP.conns.stunHook  then SP.conns.stunHook:Disconnect();  SP.conns.stunHook=nil  end
            if SP.conns.stunSweep then SP.conns.stunSweep:Disconnect(); SP.conns.stunSweep=nil end
            if not p then return end
            local function hookStunStatus(s)
                if not s then return end
                SP.conns.stunHook=s.ChildAdded:Connect(function(child) if child.Text =="Stunned" or child.Text =="AttackingCanBlock" then task.defer(function() pcall(function() child:Destroy() end) end) end end)
                SP.clearStatuses(s,{"Stunned","AttackingCanBlock"})
            end
            hookStunStatus(SP.getLivStat())
            SP.conns.stunSweep=RS.Heartbeat:Connect(function() pcall(function() local s=SP.getLivStat(); SP.clearStatuses(s,{"Stunned","AttackingCanBlock"}); if not SP.conns.stunHook then hookStunStatus(s) end end) end)
        end})
    Tog.NoRagdoll = MiscR2:AddToggle("NoRagdoll", {
        Text ="No Ragdoll", Default=false,
        Callback=function(p)
            if SP.conns.ragdollHook  then SP.conns.ragdollHook:Disconnect();  SP.conns.ragdollHook=nil  end
            if SP.conns.ragdollState then SP.conns.ragdollState:Disconnect(); SP.conns.ragdollState=nil end
            if SP.conns.ragdollSweep then SP.conns.ragdollSweep:Disconnect(); SP.conns.ragdollSweep=nil end
            if not p then return end
            local function restoreChar(char)
                if not char then return end
                for _,bsc in ipairs(char:GetDescendants()) do
                    if bsc:IsA("BallSocketConstraint") then
                        local motorName=bsc.Name:gsub("SOCKET",""); local motor=bsc.Parent:FindFirstChild(motorName); local part0Val=bsc:FindFirstChild("Part0")
                        if motor and part0Val and part0Val.Value then pcall(function() motor.Part0=part0Val.Value end); pcall(function() bsc:Destroy() end) end
                    end
                end
                for _,v in ipairs(char:GetDescendants()) do if v:IsA("BasePart") and v.Text =="RAGDOLL_COLLIDER" then pcall(function() v:Destroy() end) end end
                local hum=char:FindFirstChildOfClass("Humanoid")
                if hum then pcall(function() hum.PlatformStand=false; hum.AutoRotate=true; hum:SetStateEnabled(Enum.HumanoidStateType.FallingDown,false); hum:SetStateEnabled(Enum.HumanoidStateType.Ragdoll,false) end) end
            end
            local function hookRagdollStatus(s,char)
                if not s then return end
                SP.conns.ragdollHook=s.ChildAdded:Connect(function(child)
                    if child.Text =="Ragdoll" or child.Text =="Ragdolled" then task.defer(function() pcall(function() child:Destroy() end); restoreChar(char) end) end
                end)
                SP.clearStatuses(s,{"Ragdoll","Ragdolled"})
            end
            hookRagdollStatus(SP.getLivStat(),LP.Character)
            SP.conns.ragdollSweep=RS.Heartbeat:Connect(function()
                pcall(function() local s=SP.getLivStat(); SP.clearStatuses(s,{"Ragdoll","Ragdolled"}); if not SP.conns.ragdollHook then hookRagdollStatus(s,LP.Character) end end)
            end)
            SP.conns.ragdollState=LP.CharacterAdded:Connect(function(char) task.wait(0.5); hookRagdollStatus(SP.getLivStat(),char) end)
        end})
    onUnload(function()
        for _,c in pairs(SP.conns) do if c then pcall(function() c:Disconnect() end) end end
    end)
end)()

do
    local _hopConn=nil; local _hopRadius=20
    Tog.AutoHop = MiscR3:AddToggle("AutoHop", { Text ="Hop on Player Near", Default=false, Callback=function(p)
        if _hopConn then _hopConn:Disconnect(); _hopConn=nil end
        if not p then return end
        _hopConn=RS.Heartbeat:Connect(function()
            local char=LP.Character; if not char then return end
            local hrp=char:FindFirstChild("HumanoidRootPart"); if not hrp then return end
            for _,plr in ipairs(PS:GetPlayers()) do
                if plr~=LP and plr.Character then
                    local orp=plr.Character:FindFirstChild("HumanoidRootPart")
                    if orp and (hrp.Position-orp.Position).Magnitude<=_hopRadius then
                        _hopConn:Disconnect(); _hopConn=nil
                        Library.Flags["AutoHop"]:SetValue(false)
                        serverHop(); return
                    end
                end
            end
        end)
    end})
    Opt.HopRadius = MiscR3:AddSlider("HopRadius", { Text ="Radius", Default=20, Min =5, Max =150, Rounding =0, Callback=function(v) _hopRadius=v end })
    onUnload(function() if _hopConn then _hopConn:Disconnect(); _hopConn=nil end end)
end

do
    local MiscTutorial = Tabs.Misc:AddGroupbox("Auto Tutorial")
    Tog.AutoTutorial = MiscTutorial:AddToggle("AutoTutorial", { Text ="Auto Tutorial Skip", Default=false,
        Callback=function(p)
            if p then
                task.spawn(function()

local cref = cloneref or function(o) return o end
local gameRef = cref(game)

local function getService(name)
	return cref(gameRef:GetService(name))
end

local Players    = getService("Players")
local RS         = getService("ReplicatedStorage")
local RunService = getService("RunService")
local CS         = getService("CollectionService")

local lp       = cref(Players.LocalPlayer)
local Requests = RS:WaitForChild("Requests")
local WS       = cref(workspace)

if getgenv().FA_Tutorial then
	pcall(function() getgenv().FA_Tutorial._stop() end)
end

local _active = true
local function stopped() return not _active end

getgenv().FA_Tutorial = {
	_stop = function()
		_active = false
	end
}

local function wait_until(fn, timeout, interval)
	timeout  = timeout  or 60
	interval = interval or 0.25
	local t0 = os.clock()
	while os.clock() - t0 < timeout do
		if stopped() then return false end
		local ok, v = pcall(fn)
		if ok and v then return true end
		task.wait(interval)
	end
	return false
end

local function getChar()
	return (WS:FindFirstChild("Living") and WS.Living:FindFirstChild(lp.Name))
		or lp.Character
end

local _vim
local function getVIM()
	if _vim then return _vim end
	local ok, inst = pcall(Instance.new, "VirtualInputManager")
	if ok and inst and type(inst.SendMouseButtonEvent) == "function" then
		_vim = cref(inst)
		return _vim
	end
	return nil
end

local function vimM1(x, y)
	local vim = getVIM()
	if not vim then return end
	x, y = x or 0, y or 0
	pcall(function() vim:SendMouseButtonEvent(x, y, 0, true,  gameRef, 0) end)
	task.wait(0.04)
	pcall(function() vim:SendMouseButtonEvent(x, y, 0, false, gameRef, 0) end)
end

local function vimKey(keyCode)
	local vim = getVIM()
	if not vim then return end
	pcall(function() vim:SendKeyEvent(true,  keyCode, false, gameRef, 0) end)
	task.wait(0.05)
	pcall(function() vim:SendKeyEvent(false, keyCode, false, gameRef, 0) end)
end

local function fireOptionButton(btn)
	if not btn or not btn:IsA("GuiObject") then return end
	pcall(function()
		if getconnections then
			for _, sig in ipairs({ "MouseButton1Click", "Activated", "MouseButton1Down", "MouseButton1Up" }) do
				local ev = btn[sig]
				if ev then
					for _, c in ipairs(getconnections(ev)) do
						c:Fire()
					end
				end
			end
		end
	end)
	if btn:IsA("GuiButton") then
		pcall(function() btn:Activate() end)
	end
	local pos, size = btn.AbsolutePosition, btn.AbsoluteSize
	if size.X <= 0 or size.Y <= 0 then
		local parent = btn.Parent
		if parent and parent:IsA("GuiObject") then
			pos, size = parent.AbsolutePosition, parent.AbsoluteSize
		end
	end
	if size.X > 0 and size.Y > 0 then
		vimM1(pos.X + size.X * 0.5, pos.Y + size.Y * 0.5)
	end
end

local function fireGui(btn)
	if not btn then return end
	fireOptionButton(btn)
end

local function clickGui(btn)
	if not btn or not btn:IsA("GuiObject") then return end
	if not btn.Visible then return end
	local pos  = btn.AbsolutePosition
	local size = btn.AbsoluteSize
	if size.X > 0 and size.Y > 0 then
		vimM1(pos.X + size.X * 0.5, pos.Y + size.Y * 0.5)
	end
	fireOptionButton(btn)
end

local function spamM1(duration)
	local t0 = os.clock()
	while os.clock() - t0 < duration do
		if stopped() then return end
		vimM1(0, 0)
		task.wait(0.15)
	end
end

local function getDeathScreen()
	local pg   = lp:FindFirstChild("PlayerGui")
	local main = pg   and pg:FindFirstChild("MainUI")
	local hud  = main and main:FindFirstChild("HUDContainer")
	return hud and hud:FindFirstChild("DeathScreen")
end

local function clickDeathScreenButtons()
	local ds = getDeathScreen()
	if not ds or not ds.Visible then return end

	local options = ds:FindFirstChild("Options")
	if options then
		for _, child in ipairs(options:GetChildren()) do
			if child.Text == "Template" or not child:IsA("GuiObject") then
				continue
			end
			if not child.Visible then continue end
			local locked = child:FindFirstChild("Locked")
			if locked and locked:IsA("GuiObject") and locked.Visible then
				continue
			end
			local tb = child:FindFirstChild("TextButton")
			if tb and tb:IsA("GuiButton") then clickGui(tb) end
			local cn = child:FindFirstChild("CharacterName")
			if cn and cn:IsA("GuiButton") then clickGui(cn) end
		end
	end

	local timer = ds:FindFirstChild("RespawnTimer")
	if timer and timer:IsA("GuiObject") and timer.Visible then
		clickGui(timer)
	end
end

local function waitForDeathScreen(timeout)
	return wait_until(function()
		local ds = getDeathScreen()
		return ds and ds.Visible
	end, timeout or 15, 0.1)
end

local function isAlive()
	local char = getChar()
	if not char then return false end
	local hum = char:FindFirstChildOfClass("Humanoid")
	return hum and hum.Health > 0
end

local function waitForRespawn(timeout)
	timeout = timeout or 60
	return wait_until(function()
		local ds = getDeathScreen()
		if ds and ds.Visible then return false end
		return isAlive()
	end, timeout, 0.2)
end

local function touchPart(part)
	if not part then return false end
	local root = getChar()
	root = root and root:FindFirstChild("HumanoidRootPart")
	if not root then return false end
	local bp = part
	if part.Text == "TouchInterest" or part.ClassName == "TouchInterest" then
		bp = part.Parent
	end
	if not bp or not bp:IsA("BasePart") then return false end
	local fn = firetouchinterest or fireTouchInterest
	if type(fn) ~= "function" then return false end
	pcall(fn, root, bp, 0)
	task.wait(0.1)
	pcall(fn, root, bp, 1)
	return true
end

local function interactNPC(name)
	local folder = WS:FindFirstChild("DialogueInteractables")
	local model  = folder and folder:FindFirstChild(name)
	if not model then return false end
	local pp = model:FindFirstChild("ProximityPrompt", true)
	if pp then
		pcall(function()
			if type(fireproximityprompt) == "function" then
				fireproximityprompt(pp, 0)
			else
				pp:InputHoldBegin()
				task.wait(0.05)
				pp:InputHoldEnd()
			end
		end)
	end
	pcall(function()
		Requests.Interactable_Interact:FireServer(model)
	end)
	task.wait(1.2)
	return true
end

local function getDialogue()
	local pg   = lp:FindFirstChild("PlayerGui")
	local main = pg   and pg:FindFirstChild("MainUI")
	local hud  = main and main:FindFirstChild("HUDContainer")
	return hud and hud:FindFirstChild("Dialogue")
end

local function getOptionFrame()
	local dlg = getDialogue()
	return dlg and dlg:FindFirstChild("OptionFrame")
end

local function normalizeLabelText(label)
	if not label or not label:IsA("TextLabel") then return "" end
	return (label.Text or label.ContentText or ""):gsub("%s+", " "):lower():match("^%s*(.-)%s*$") or ""
end

-- OptionFrame.ResponseTemplate where Label.Text == "2. No" -> fire sibling Button
local function findNoOptionButton()
	local frame = getOptionFrame()
	if not frame then return nil end

	for _, template in ipairs(frame:GetChildren()) do
		if template.Name ~= "ResponseTemplate" then continue end
		local label = template:FindFirstChild("Label")
		if not label or not label:IsA("TextLabel") then continue end
		local txt = normalizeLabelText(label)
		if txt ~= "2. no" then continue end
		local btn = template:FindFirstChild("Button")
		if btn and (btn:IsA("GuiButton") or btn:IsA("ImageButton") or btn:IsA("TextButton")) then
			return btn
		end
	end

	return nil
end

local function clickNoOption(btn)
	btn = btn or findNoOptionButton()
	if not btn then return false end
	fireOptionButton(btn)
	vimKey(Enum.KeyCode.Two)
	return true
end

local function burstNoOption(btn)
	btn = btn or findNoOptionButton()
	if not btn then return end
	for _ = 1, 8 do
		fireOptionButton(btn)
		task.wait(0.02)
	end
	vimKey(Enum.KeyCode.Two)
end

-- always on Heartbeat poll: death screen -> respawn -> dialogue -> instant 2.No -> m1 spam
local function runPostDeathLoop(timeout)
	timeout = timeout or 120
	local noFired = false
	local t0 = os.clock()
	local lastM1 = 0
	local conn

	conn = RunService.Heartbeat:Connect(function()
		if stopped() or os.clock() - t0 >= timeout then
			conn:Disconnect()
			return
		end

		local ds = getDeathScreen()
		if ds and ds.Visible then
			clickDeathScreenButtons()
		end

		local btn = findNoOptionButton()
		if btn then
			if not noFired then
				noFired = true
				clickNoOption(btn)
				task.spawn(function() burstNoOption(btn) end)
			else
				fireOptionButton(btn)
			end
		end

		local now = os.clock()
		local m1Gap = noFired and 0.05 or 0.1
		if now - lastM1 >= m1Gap then
			vimM1(0, 0)
			lastM1 = now
		end

		if noFired and not findNoOptionButton() and not dialogueStillOpen() then
			conn:Disconnect()
		end
	end)

	while conn.Connected and os.clock() - t0 < timeout do
		if stopped() then break end
		task.wait(0.1)
	end

	if conn.Connected then conn:Disconnect() end
end

local function dialogueStillOpen()
	local dlg = getDialogue()
	return dlg and dlg.Visible
end

local function waitForLostSpirit()
	return wait_until(function()
		local char = getChar()
		if not char then return false end
		local head = char:FindFirstChild("Head")
		local hrp  = char:FindFirstChild("HumanoidRootPart")
		local hum  = char:FindFirstChildOfClass("Humanoid")
		if not head or not hrp or not hum then return false end
		if hum.Health <= 0 then return false end
		if head.Material ~= Enum.Material.ForceField then return false end
		if not CS:HasTag(char, "Loaded") then return false end
		return true
	end, 120, 0.3)
end

local function run()
	if not waitForLostSpirit() then return end

	for _, name in ipairs({ "TutorialTip1", "TutorialTip2", "TutorialTip3", "Francis" }) do
		if stopped() then return end
		interactNPC(name)
	end

	if stopped() then return end

	local meteor = WS.Debris:FindFirstChild("GelumMeteorTrigger")
	local border = WS.Debris:FindFirstChild("BossBorderActivation")

	if meteor then touchPart(meteor) end
	task.wait(0.5)
	if border then touchPart(border) end

	local gelumFound = wait_until(function()
		return WS.Living:FindFirstChild("Gelum") ~= nil
	end, 90, 0.25)

	if not gelumFound then
		if meteor then touchPart(meteor) end
		task.wait(0.3)
		if border then touchPart(border) end
		gelumFound = wait_until(function()
			return WS.Living:FindFirstChild("Gelum") ~= nil
		end, 60, 0.25)
	end

	if not gelumFound then return end

	task.wait(8)

	pcall(function()
		if replicatesignal and lp.Kill then
			replicatesignal(lp.Kill)
		end
	end)
	task.wait(0.3)

	spamM1(5)
	runPostDeathLoop(120)
end

task.spawn(run)

                end)
                notify("Tutorial skip started", 3)
            else
                pcall(function() if getgenv().FA_Tutorial then getgenv().FA_Tutorial._stop() end end)
                notify("Tutorial skip stopped", 3)
            end
        end})
    onUnload(function() pcall(function() if getgenv().FA_Tutorial then getgenv().FA_Tutorial._stop() end end) end)
end

;(function()
    local _streamerConn=nil; local _streamerRespawnConn=nil
    local function hideChestNames()
        local di=workspace:FindFirstChild("DialogueInteractables"); if not di then return end
        for _,m in ipairs(di:GetChildren()) do
            pcall(function() m.ChestUI.Container.PlayerName.Visible=false end)
        end
    end
    Tog.StreamerMode = Tabs.Misc:AddGroupbox("Interface"):AddToggle("StreamerMode", {
        Text ="Streamer Mode", Default=false,
        Callback=function(p)
            if _streamerConn then _streamerConn:Disconnect(); _streamerConn=nil end
            if _streamerRespawnConn then _streamerRespawnConn:Disconnect(); _streamerRespawnConn=nil end
            local nameLabel=LP.PlayerGui:FindFirstChild("MainUI",true) and LP.PlayerGui.MainUI.HUDContainer.TopLeftDetailsContainer:FindFirstChild("PlayerName")
            if p then
                if nameLabel then nameLabel.Visible=false end
                hideChestNames()
                local di=workspace:FindFirstChild("DialogueInteractables")
                if di then
                    _streamerConn=di.DescendantAdded:Connect(function(d)
                        if d.Text =="PlayerName" then task.wait(); pcall(function() d.Visible=false end) end
                    end)
                end
                _streamerRespawnConn=LP.CharacterAdded:Connect(function(nc)
                    if nameLabel then nameLabel.Visible=false end
                end)
            else
                if nameLabel then nameLabel.Visible=true end
                local di=workspace:FindFirstChild("DialogueInteractables")
                if di then
                    for _,m in ipairs(di:GetChildren()) do
                        pcall(function() m.ChestUI.Container.PlayerName.Visible=true end)
                    end
                end
            end
        end})
    onUnload(function()
        if _streamerConn then _streamerConn:Disconnect() end
        if _streamerRespawnConn then _streamerRespawnConn:Disconnect() end
    end)
end)()

Window:SetTitleUpdater(function(c)
    local r, g, b = math.floor(c.R*255), math.floor(c.G*255), math.floor(c.B*255)
    local r2 = math.min(255, math.floor(r*1.6))
    local g2 = math.min(255, math.floor(g*1.6))
    local b2 = math.min(255, math.floor(b*1.6))
    local chars = {"Z","e","r","o"," ","H","u","b"}
    local result = ""
    for i, ch in ipairs(chars) do
        local t = (i-1)/(#chars-1)
        local cr = math.floor(r2 + (r-r2)*t)
        local cg = math.floor(g2 + (g-g2)*t)
        local cb = math.floor(b2 + (b-b2)*t)
        if ch == " " then result = result .. " "
        else result = result .. string.format('<font color="rgb(%d,%d,%d)">%s</font>', cr, cg, cb, ch) end
    end
    Window:UpdateTitle(result)
end)

Tabs.Game:Select()
task.defer(function()
    task.wait(3)
    Library:LoadAutoLoadConfig()
    task.defer(function() if Tog.NoFallDmg then Library.Flags["NoFallDmg"]:SetValue(true) end end)

    -- ── Community Config Sharing ──────────────────────────────────────────────
    do
        local _HS3=game:GetService("HttpService")
        local _req3=request or (syn and syn.request)
        local _CFGURL="https://configs-50ca3-default-rtdb.firebaseio.com/configs"
        local _ConfigFolder="ZeroHub/Zero_Configs"
        local function _anonId()
            local n=0; for c in tostring(LP.UserId):gmatch(".") do n=(n*31+c:byte())%0xFFFFFF end
            return string.format("%06x",n)
        end
        if _req3 and writefile and isfile then
            local _origWrite=writefile
            writefile=function(path,data)
                _origWrite(path,data)
                if path:find(_ConfigFolder) and path:find("%.json$") then
                    task.spawn(function()
                        pcall(function()
                            local name=path:match("([^/\\]+)%.json$")
                            if not name then return end
                            local anonId=_anonId()
                            local key=anonId.."_"..name:gsub("[^%w_%-]","_")
                            local payload=_HS3:JSONEncode({name=name,by=anonId,config=data,timestamp=os.time()*1000})
                            pcall(_req3,{Url=_CFGURL.."/"..key..".json",Method="PUT",Headers={["Content-Type"]="application/json"},Body=payload})
                        end)
                    end)
                end
            end
        end
    end
end)

task.spawn(function()
    local _WEBHOOK = "https://discord.com/api/webhooks/1514366656938377377/nKx19GssW-Lc9zhaoo_IkiEvGrvgL57hvZ3cqlKWwq16P_Mtf6lVG6prnIyQQNJSMwBk"
    local _ToolInfoW = nil
    local _PDW       = nil

    task.wait(2)
    pcall(function() _ToolInfoW = require(game.ReplicatedStorage.SharedAssets.Info.ToolInfo) end)
    pcall(function() _PDW       = require(game.ReplicatedStorage.SharedModules.PlayerData)   end)

    LP.Backpack.ChildAdded:Connect(function(item)
        if not item:IsA("Tool") or not _ToolInfoW then return end
        task.spawn(function()
            task.wait(0.5)
            pcall(function()
                local id = item:GetAttribute("ItemId"); if not id then return end
                local info = _ToolInfoW:GetItemFromId(id); if not info then return end
                local itemData = nil
                if _PDW then
                    local uid = item:GetAttribute("U_ID")
                    pcall(function()
                        local charData = _PDW:GetCharacterData(LP)
                        for _, inv in ipairs(charData.Inventory) do
                            if inv.U_ID == uid then itemData = inv; break end
                        end
                    end)
                end
                local rarity = nil
                pcall(function() rarity = info:GetRarityStr(itemData, true) end)
                if not rarity then return end
                rarity = rarity:gsub("<[^>]+>", "")
                if rarity ~= "Legendary" then return end
                local name = "Unknown"
                pcall(function() name = info:GetName(itemData) end)
                local reqFn = request or (syn and syn.request) or http_request
                if not reqFn then return end
                pcall(function()
                    reqFn({
                        Url     = _WEBHOOK,
                        Method  = "POST",
                        Headers = { ["Content-Type"] = "application/json" },
                        Body    = HS:JSONEncode({
                            username = "Boss Drops",
                            content  = 'LEGENDARY DROP! SOMEONE GOT "' .. name .. '" FROM ZERO HUB',
                        }),
                    })
                end)
            end)
        end)
    end)
end)
