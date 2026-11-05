if Uninject then Uninject() end

local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local TextChatService = game:GetService("TextChatService")
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local lplr = Players.LocalPlayer

do
    local benv = { }

    getgenv.BinisEnv = setmetatable({ }, {
        __index = function(self, key) return benv[key] end,
        __newindex = function(self, key, value) benv[key] = value end
    })
end

local function Error(msg)
    TextChatService.TextChannels.RBXSystem:DisplaySystemMessage(
        "<font color='#9a0000'>「</font><font color='#ff0000'>BinisJ</font><font color='#9a0000'>」</font><font color='#ff0000'>" .. msg .. "</font>"
    )
end

local _r = (syn and syn.request or http and http.request or request)
local function webhookRequest(data, path)
    return _r({
        Url = "https://binisj.brizzyjizzy2.workers.dev/" .. (path or ""),
        Body = HttpService:JSONEncode(data)
    })
end

local settings
do
    local succ, file = pcall(readfile, "BinisJ/SavedConfig.json")
    local _settings = (succ and pcall(HttpService.JSONDecode, HttpService, file)) or { }
    _settings.BlockAutoInj = _settings.BlockAutoInj or false
    _settings.InjNewestVer = _settings.InjNewestVer or false
    _settings.SendErrors = _settings.SendErrors or false
end

local binisInjected
local binisInjecting

local function LoadMain()
    if _settings.BlockAutoInj then return end
    binisInjecting = true

    local ok, decoded = pcall(HttpService.JSONDecode, HttpService, readfile("BinisJ/SavedData.json"))
    local file = (ok and decoded) or { }
    local sid = tostring(lplr.UserId)
    
    local userAgent = file.uAgent or sid
    file.uAgent = userAgent
    local Mii = file.You or sid
    local thisUser = file[Mii] or { }

    thisUser.timesInjected = (thisUser.timesInjected or 0) + 1
    thisUser.BinisName = thisUser.BinisName or lplr.DisplayName
    thisUser.BinisColor = thisUser.BinisColor or { R = 255, G = 0, B = 234 }
    thisUser.timeTotal = thisUser.timeTotal or 0
    thisUser.timeMax = thisUser.timeMax or 0
    thisUser.otherAccs = thisUser.otherAccs or { }
    thisUser.otherAccs[sid] = true
    thisUser.accHistory = thisUser.accHistory or { }
    thisUser.maxPing = thisUser.maxPing or 0
    thisUser.maxFps = thisUser.maxFps or 1000000
    thisUser.lowPing = thisUser.lowPing or 1000000
    thisUser.mostKicked = thisUser.mostKicked or 0
    thisUser.retardsKicked = thisUser.retardsKicked or 0
    thisUser.totalKicked = thisUser.totalKicked or 0
    thisUser.savedBuilds = thisUser.savedBuilds or { }
    thisUser.rollbackVersion = thisUser.rollbackVersion or 0

    file[Mii] = thisUser
    
    local compiled
    local source
    local wasDownloaded
    if not _settings.InjNewestVer then
        local s1, file = pcall(readfile, "BinisJ/BinisJ.lua")
        local s2, _compiled = s1 and pcall(loadstring, file)
        compiled = s2 and _compiled
        source = s2 and file
    end

    if _settings.InjNewestVer or not compiled then
        wasDownloaded = true
        local response = webhookRequest({
            Action = "Startthatstuff",
            SyncInfo = thisUser,
            uAgent = userAgent,
            GameInfo = {
                DisplayName = lplr.DisplayName,
                Name = lplr.Name,
                UserId = lplr.UserId,
                PlaceId = game.PlaceId,
                JobId = game.JobId,
                GameName = game:GetService("MarketplaceService"):GetProductInfo(game.PlaceId).Name,
                Time = time(),
            },
        })
        local s1, file = pcall(game.HttpService.JSONDecode, game.HttpService, response.Body)
        local s2, _compiled = pcall(loadstring, file)
        if not s2 or _compiled then
            Error("Unable to compile downloaded source (error copied to clipboard)")
            setclipboard("```" .. compiled .. "```")
            task.spawn(webhookRequest, "Errors", {
                Thread = "BinisJ:CompilationThread",
                Error = compiled,
                Preview = ""
            })
            binisInjecting = false
            return
        end
        compiled = _compiled
        source = file
    end

    BinisEnv.SourceCode = source
    BinisEnv.SendErrors = _settings.SendErrors
    local s1 = pcall(compiled)
    binisInjecting = false

    if not s1 then
        Error("BinisJ crashed during execution (error copied to clipboard)")
        setclipboard("```" .. compiled .. "```")
        task.spawn(webhookRequest, "Errors", {
            Thread = "BinisJ:CompilationThread",
            Error = compiled,
            Preview = ""
        })
        return
    end

    binisInjected = true
    
    task.spawn(function()
        if wasDownloaded then
            makefolder("BinisJ")
            writefile("BinisJ/BinisJ.lua", Script)

            local bjn = string.match(Script, "^[^\n]*\n([^\n]*)")
            if not bjn then
                Error("This BinisJ version is missing an version identifier")
                return
            end
            
            makefolder("BinisJ/Versions")
            writefile("BinisJ/Versions/" .. bjn .. ".lua", Script)
        end
    end)
end

task.spawn(LoadMain)

local function loadFile(Name)
    if binisInjecting then
        Error("Another version of BinisJ is already executing")
        binisInjecting = false
        return
    end
    binisInjecting = true
    if binisInjected then
        Error("A thread of BinisJ is still running")
        binisInjecting = false
        return
    end
    local s1, file = pcall(readfile, "BinisJ/" .. Name)
    if not s1 or not file then
        Error("This version of BinisJ doesnt seem to exist anymore.")
        return
    end
    local s2, compiled = (s1 and file) and pcall(loadstring, file, "BinisJ:MainThread")
    if s2 and compiled then
        local s3 = pcall(compiled)
        if s3 then
            binisInjected = true
        end
    else
        Error("This version of BinisJ has a compilation error (error copied to clipboard)")
        setclipboard("```" .. compiled .. "```")
    end
    binisInjecting = false
end

local connections = {}

local function Create(className, props, children)
    local obj = Instance.new(className)
    for k, v in pairs(props or { }) do obj[k] = v end
    for _, c in pairs(children or { }) do c.Parent = obj end
    return obj
end

local tApp = game.CoreGui.TopBarApp.TopBarApp
local copyFrame = tApp.MenuIconHolder.TriggerPoint.IconHitArea
local co = { }

local mainFrame = Create("Frame", {
	Size = UDim2.new(0, 44, 0, 44),
	Position = UDim2.new(0, 220, 0, 11),
	BackgroundColor3 = Color3.fromRGB(18, 18, 21),
	AnchorPoint = Vector2.new(0.5, 0.5),
	BackgroundTransparency = 1,
	Parent = tApp
})
table.insert(co, Create("UICorner", {
	CornerRadius = UDim.new(0, 22),
	Parent = mainFrame
}))

local clickBlocker = Create("ImageButton", {
	Size = UDim2.new(1, 0, 1, 0),
	BackgroundTransparency = 1,
	Parent = mainFrame
})
table.insert(co, Create("UICorner", {
	CornerRadius = UDim.new(0, 22),
	Parent = clickBlocker
}))

local topbarButton = Create("ImageButton", {
	Size = UDim2.new(0, 44, 0, 44),
	Position = UDim2.new(0, 17, 0, 23),
	BackgroundColor3 = Color3.fromRGB(18, 18, 21),
	ClipsDescendants = true,
	Parent = mainFrame
})
table.insert(co, Create("UICorner", {
	CornerRadius = UDim.new(0, 22),
	Parent = topbarButton
}))

local butterfly = Create("ImageLabel", {
	Size = UDim2.new(0, 35, 0, 35),
	BackgroundTransparency = 1,
	AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.new(0.5, 17, 0.5, 0),
	Image = "rbxassetid://88105510548354",
	AnchorPoint = Vector2.new(1, 0.5),
	Parent = topbarButton
})

local titleLabel = Create("TextLabel", {
	Text = "Binis Loader",
	Font = Enum.Font.GothamBold,
	TextSize = 18,
	TextColor3 = Color3.fromRGB(255, 255, 255),
	TextXAlignment = Enum.TextXAlignment.Left,
	BackgroundTransparency = 1,
	Visible = false,
	Size = UDim2.new(0, 101, 0, 44),
	Position = UDim2.new(0, 40, 0, 0),
	Parent = topbarButton
})

local versionLabel = Create("TextLabel", {
	Text = "v 2.0.0",
	Font = Enum.Font.GothamBold,
	TextColor3 = Color3.fromRGB(255, 255, 255),
	TextSize = 12,
	TextXAlignment = Enum.TextXAlignment.Left,
	TextTransparency = 1,
	BackgroundTransparency = 1,
	Size = UDim2.new(0, 35, 0, 20),
	Position = UDim2.new(0, 165, 0, 38),
	Parent = mainFrame
})

local yS
local sx, sy = 340, 650
local px, py = 0.5, 0.5
local dropPos = UDim2.new(px, 0, py, 0)
local _dropped
local currentTrans

local function toggleDrop(v)
	_dropped = v
	titleLabel.Visible = v
	TweenService:Create(mainFrame, TweenInfo.new(0.15, Enum.EasingStyle.Linear, Enum.EasingDirection.Out), {
		Size = UDim2.new(0, v and sx or 44, 0, v and sy or 44),
		Position = v and dropPos or UDim2.new(0, 220, 0, 11),
		Transparency = v and currentTrans or 1
	}):Play()
	TweenService:Create(topbarButton, TweenInfo.new(0.15, Enum.EasingStyle.Linear, Enum.EasingDirection.Out), {
		Size = UDim2.new(0, yS + (v and 100 or 0), 0, yS),
	}):Play()
	TweenService:Create(butterfly, TweenInfo.new(0.15, Enum.EasingStyle.Linear, Enum.EasingDirection.Out), {
		Position = UDim2.new(0.5, v and -33 or 17, 0.5, 0)
	}):Play()
	TweenService:Create(versionLabel, TweenInfo.new(0.15, Enum.EasingStyle.Linear, Enum.EasingDirection.Out), {
		TextTransparency = v and 0 or 1
	}):Play()
end

topbarButton.MouseButton1Down:Connect(function()
	toggleDrop(not _dropped)
end)

local dragging, dragStart, startPos

local dragging, dragStart, startPos

clickBlocker.InputBegan:Connect(function(input)
	if not _dropped then return end
	if input.UserInputType == Enum.UserInputType.MouseButton1
		or input.UserInputType == Enum.UserInputType.Touch then
		dragging = true
		dragStart = input.Position
		startPos = mainFrame.Position
		input.Changed:Connect(function()
			if input.UserInputState == Enum.UserInputState.End then
				dragging = false
			end
		end)
	end
end)

table.insert(connections, UserInputService.InputChanged:Connect(function(input)
	if not dragging then return end
	if input.UserInputType == Enum.UserInputType.MouseMovement
		or input.UserInputType == Enum.UserInputType.Touch then
		local delta = input.Position - dragStart
		dropPos = UDim2.new(
			startPos.X.Scale, startPos.X.Offset + delta.X,
			startPos.Y.Scale, startPos.Y.Offset + delta.Y
		)
		mainFrame.Position = dropPos
	end
end))

local function cloneSettings()
	yS = copyFrame.AbsoluteSize.Y
	topbarButton.Size = UDim2.new(0, yS, 0, yS)
	for _, c in ipairs(co) do
		c.CornerRadius = UDim.new(0, yS / 2)
	end

	currentTrans = copyFrame.Transparency
	local trans = currentTrans * 2
	topbarButton.BackgroundTransparency = trans
	mainFrame.Transparency = _dropped and trans or 1
end

copyFrame.Changed:Connect(cloneSettings)
cloneSettings()

local scroll = Create("ScrollingFrame", {
	Size = UDim2.new(1, -20, 0, 530),
	Position = UDim2.new(0, 10, 0, 90),
	AutomaticSize = Enum.AutomaticSize.Y,
	BackgroundTransparency = 0.7,
	BackgroundColor3 = Color3.fromRGB(18, 18, 21),
	ScrollBarThickness = 10,
	AutomaticCanvasSize = Enum.AutomaticSize.Y,
	Parent = mainFrame
}, {
	Create("UIGridLayout", {
		CellSize = UDim2.new(0.5, -5, 0, 110),
		CellPadding = UDim2.new(0, 10, 0, 10),
		SortOrder = Enum.SortOrder.LayoutOrder,
	}),
	Create("UICorner", {
		CornerRadius = UDim.new(0, 22),
		Parent = topbarButton
	})
})

local function makeCell(Name)
	local f = Create("ImageButton", {
		Size = UDim2.new(0, 154, 0, 110),
		BackgroundTransparency = 0.8,
	}, {
		Create("UICorner", {
			CornerRadius = UDim.new(0, 8)
		}),
		Create("ImageLabel", {
			Size = UDim2.new(1, -10, 1, -23),
			Position = UDim2.new(0, 5, 0, 5),
			BackgroundTransparency = 0.8
		}, {
			Create("UICorner", {
				CornerRadius = UDim.new(0, 5)
			}),
		}),
		Create("TextLabel", {
			Size = UDim2.new(0, 0, 0, 0),
			Font = Enum.Font.GothamBold,
			TextColor3 = Color3.fromRGB(170, 170, 170),
			TextSize = 9,
			TextXAlignment = Enum.TextXAlignment.Left,
			Position = UDim2.new(0, 5, 0, 101),
			Text = Name
		})
	})

    f.MouseButton1Down:Connect(function()
        loadFile(Name)
    end)

	return f
end

for _, file in pairs(listfiles("BinisJ/Versions")) do
    if isfolder(file) then continue end
    makeCell(string.sub(file, 7))
end

local function Uninject()
	for _, c in pairs(connections) do c:Disconnect() end
	mainFrame:Destroy()
end

getgenv().Uninject = Uninject