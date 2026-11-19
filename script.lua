

-- ============================================================
-- BYTE.WTF UI  (drop-in replacement for the Airflow API)
-- Supports: CreateWindow, CreateTab, CreateSection, CreateToggle,
-- CreateSlider, CreateDropdown, CreateKeybind, CreateButton,
-- CreateButtonRow, CreateInput, CreateLabel, CreateDivider,
-- Window:Notify / SaveConfig / LoadConfig
-- ============================================================
local Airflow = (function()
    local Players          = game:GetService("Players")
    local UIS              = game:GetService("UserInputService")
    local TweenService     = game:GetService("TweenService")
    local HttpService      = game:GetService("HttpService")
    local CoreGui          = game:GetService("CoreGui")
    local LP               = Players.LocalPlayer

    local Lib = { Themes = {}, Assets = {} }
    function Lib:LoadFont() end

    -- palette (taken from the screenshot)
    local C = {
        Window    = Color3.fromRGB(11, 11, 13),
        TitleBar  = Color3.fromRGB(9, 9, 11),
        Panel     = Color3.fromRGB(15, 15, 18),
        Field     = Color3.fromRGB(21, 21, 25),
        Stroke    = Color3.fromRGB(36, 36, 42),
        StrokeLt  = Color3.fromRGB(54, 54, 62),
        Text      = Color3.fromRGB(236, 236, 240),
        Muted     = Color3.fromRGB(128, 128, 138),
        Header    = Color3.fromRGB(150, 150, 160),
        Accent    = Color3.fromRGB(236, 236, 240),
        AccentDk  = Color3.fromRGB(196, 196, 204),
        ToggleOn  = Color3.fromRGB(232, 232, 236),
        ToggleOff = Color3.fromRGB(44, 44, 50),
        TabOn     = Color3.fromRGB(23, 23, 28),
        TabOnStr  = Color3.fromRGB(66, 66, 75),
        BtnDark   = Color3.fromRGB(8, 8, 10),
        SliderTrack = Color3.fromRGB(40, 40, 46),
        LoadTrack   = Color3.fromRGB(30, 30, 36),
        KnobOff     = Color3.fromRGB(118, 118, 128),
        TabText     = Color3.fromRGB(190, 190, 198),
        Placeholder = Color3.fromRGB(96, 96, 106),
        AccentHover = Color3.fromRGB(250, 250, 252),
        BtnHover    = Color3.fromRGB(32, 32, 38),
        Title       = Color3.fromRGB(255, 255, 253),
        TabSelText  = Color3.fromRGB(255, 254, 255),
    }

    local FAM = "rbxasset://fonts/families/GothamSSm.json"
    local function font(w) return Font.new(FAM, w or Enum.FontWeight.Medium) end

    local function new(class, props, kids)
        local o = Instance.new(class)
        local parent
        for k, v in pairs(props or {}) do
            if k == "Parent" then parent = v else o[k] = v end
        end
        for _, c in ipairs(kids or {}) do c.Parent = o end
        if parent then o.Parent = parent end
        return o
    end
    local function corner(r) return new("UICorner", { CornerRadius = UDim.new(0, r) }) end
    local function stroke(col, th) return new("UIStroke", { Color = col or C.Stroke, Thickness = th or 1, ApplyStrokeMode = Enum.ApplyStrokeMode.Border }) end
    local function pad(l, t, r, b) return new("UIPadding", { PaddingLeft = UDim.new(0, l), PaddingTop = UDim.new(0, t), PaddingRight = UDim.new(0, r), PaddingBottom = UDim.new(0, b) }) end
    local function text(parent, props)
        props.BackgroundTransparency = 1
        props.FontFace = props.FontFace or font()
        props.TextColor3 = props.TextColor3 or C.Text
        props.TextSize = props.TextSize or 14
        props.Parent = parent
        return new("TextLabel", props)
    end
    local function tween(o, t, props)
        TweenService:Create(o, TweenInfo.new(t, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), props):Play()
    end

    local function getGuiParent()
        local ok, h = pcall(function() return gethui and gethui() end)
        if ok and h then return h end
        local ok2 = pcall(function() return CoreGui.Name end)
        if ok2 then return CoreGui end
        return LP:WaitForChild("PlayerGui")
    end

    -- value (de)serialisation for configs
    local function ser(v)
        if typeof(v) == "EnumItem" then return { __key = v.Name } end
        return v
    end
    local function deser(v)
        if type(v) == "table" and v.__key then
            return Enum.KeyCode[v.__key]
        end
        return v
    end

    -- ----- baked-in logo (embedded PNG, loaded through the executor's file functions) -----
    local LOGO_B64 = "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"
    local function b64decode(data)
        local chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"
        local lookup = {}
        for i = 1, #chars do lookup[chars:sub(i, i)] = i - 1 end
        data = (data:gsub("[^%w%+/=]", ""))
        local out = {}
        for i = 1, #data, 4 do
            local a, b = lookup[data:sub(i, i)], lookup[data:sub(i + 1, i + 1)]
            local c, d = lookup[data:sub(i + 2, i + 2)], lookup[data:sub(i + 3, i + 3)]
            local n = a * 262144 + b * 4096 + (c or 0) * 64 + (d or 0)
            out[#out + 1] = string.char(math.floor(n / 65536) % 256)
            if c then out[#out + 1] = string.char(math.floor(n / 256) % 256) end
            if d then out[#out + 1] = string.char(n % 256) end
        end
        return table.concat(out)
    end
    local logoAsset
    local function getLogo()
        if logoAsset ~= nil then return logoAsset or nil end
        local ok, res = pcall(function()
            local gca = getcustomasset or getsynasset
            if not (writefile and gca) then return nil end
            if makefolder and isfolder and not isfolder("Byte.WTF") then makefolder("Byte.WTF") end
            writefile("Byte.WTF/logo.png", b64decode(LOGO_B64))
            return gca("Byte.WTF/logo.png")
        end)
        logoAsset = (ok and res) or false
        return logoAsset or nil
    end


    -- ============================================================
    -- THEME ENGINE
    -- Every colour in the UI comes from the palette table `C`.
    -- Switching a theme rewrites C, then recolours everything that
    -- already exists (matching old palette colour -> new one).
    -- ============================================================
    local WHITE, BLACK = Color3.new(1, 1, 1), Color3.new(0, 0, 0)
    local function rgbOf(c) return math.floor(c.R * 255 + 0.5), math.floor(c.G * 255 + 0.5), math.floor(c.B * 255 + 0.5) end
    local function ckey(c) local r, g, b = rgbOf(c); return r * 65536 + g * 256 + b end
    local function mix(a, b, t) return a:Lerp(b, t) end
    local function shift(c, dr, dg, db)
        local r, g, b = rgbOf(c)
        return Color3.fromRGB(math.clamp(r + dr, 0, 255), math.clamp(g + dg, 0, 255), math.clamp(b + db, 0, 255))
    end
    local function copyT(t) local n = {} for k, v in pairs(t) do n[k] = v end return n end
    local function toHex(c) local r, g, b = rgbOf(c); return string.format("#%02X%02X%02X", r, g, b) end
    local function parseHex(str)
        str = (tostring(str or ""):gsub("%s", "")):gsub("^#", "")
        if #str == 3 then str = str:gsub(".", function(ch) return ch .. ch end) end
        if not str:match("^%x%x%x%x%x%x$") then return nil end
        return Color3.fromRGB(tonumber(str:sub(1, 2), 16), tonumber(str:sub(3, 4), 16), tonumber(str:sub(5, 6), 16))
    end

    -- guarantee every palette colour is unique so old->new mapping is never ambiguous
    local function uniq(p)
        local used = { [ckey(WHITE)] = true }
        local keys = {}
        for k in pairs(p) do keys[#keys + 1] = k end
        table.sort(keys)
        for _, k in ipairs(keys) do
            local r, g, b = rgbOf(p[k])
            local guard = 0
            while used[r * 65536 + g * 256 + b] and guard < 600 do
                guard += 1
                if b > 0 then b -= 1 else g = (g + 1) % 256 end
            end
            used[r * 65536 + g * 256 + b] = true
            p[k] = Color3.fromRGB(r, g, b)
        end
        return p
    end

    local function neutrals(spec)
        local bg, flat = spec.bg, spec.flat
        local function S(dr, dg, db) if flat then return shift(bg, dr, dr, dr) end return shift(bg, dr, dg, db) end
        return {
            Window = bg, TitleBar = S(2, 2, 3), Panel = S(3, 3, 4), Field = S(10, 10, 13),
            Stroke = S(25, 25, 31), StrokeLt = S(37, 37, 46), ToggleOff = S(27, 27, 33),
            SliderTrack = S(25, 25, 32), LoadTrack = S(21, 21, 27), BtnHover = S(19, 19, 24),
            Text = spec.text or Color3.fromRGB(228, 228, 234),
            Muted = mix(bg, WHITE, 0.45), Header = mix(bg, WHITE, 0.51), KnobOff = mix(bg, WHITE, 0.58),
            TabText = mix(bg, WHITE, 0.78), Placeholder = mix(bg, WHITE, 0.38),
            Title = Color3.fromRGB(255, 255, 253), TabSelText = Color3.fromRGB(255, 254, 255),
        }
    end

    local function accentize(p, a, light)
        local bg = p.Window
        p.Accent      = a
        p.AccentDk    = light and mix(a, BLACK, 0.35) or mix(a, bg, 0.5)
        p.ToggleOn    = light and a or mix(a, bg, 0.3)
        p.TabOn       = mix(bg, a, 0.22)
        p.TabOnStr    = mix(bg, a, light and 0.45 or 0.4)
        p.BtnDark     = light and WHITE or mix(a, BLACK, 0.85)
        p.AccentHover = light and mix(a, BLACK, 0.12) or mix(a, WHITE, 0.17)
    end

    local DefaultPalette = copyT(C)
    local function rgb(r, g, b) return Color3.fromRGB(r, g, b) end

    local ThemeOrder = {
        "Default", "Midnight", "Crimson", "Emerald", "Ocean", "Sunset", "Rose",
        "Amethyst", "Cyber Yellow", "Mono", "Dracula", "Nord", "Light",
    }
    local Specs = {
        ["Default"]      = { palette = DefaultPalette },
        ["Midnight"]     = { bg = rgb(8, 9, 18),    accent = rgb(112, 128, 255) },
        ["Crimson"]      = { bg = rgb(16, 11, 12),  accent = rgb(235, 64, 82) },
        ["Emerald"]      = { bg = rgb(10, 15, 13),  accent = rgb(46, 204, 133) },
        ["Ocean"]        = { bg = rgb(9, 14, 19),   accent = rgb(30, 190, 210) },
        ["Sunset"]       = { bg = rgb(17, 12, 10),  accent = rgb(255, 140, 60) },
        ["Rose"]         = { bg = rgb(17, 11, 15),  accent = rgb(255, 105, 160) },
        ["Amethyst"]     = { bg = rgb(14, 11, 19),  accent = rgb(168, 110, 255) },
        ["Cyber Yellow"] = { bg = rgb(12, 12, 10),  accent = rgb(252, 238, 10) },
        ["Mono"]         = { bg = rgb(14, 14, 14),  accent = rgb(205, 205, 205), flat = true },
        ["Dracula"]      = { bg = rgb(24, 25, 33),  accent = rgb(189, 147, 249), text = rgb(248, 248, 242) },
        ["Nord"]         = { bg = rgb(30, 34, 42),  accent = rgb(136, 192, 208), text = rgb(216, 222, 233) },
        ["Light"] = {
            bg = rgb(238, 240, 245), accent = rgb(46, 108, 232), light = true,
            fixed = {
                TitleBar = rgb(246, 247, 251), Panel = rgb(250, 251, 254), Field = rgb(230, 233, 240),
                Stroke = rgb(208, 213, 224), StrokeLt = rgb(190, 197, 212), Text = rgb(28, 31, 40),
                Muted = rgb(108, 115, 132), Header = rgb(88, 96, 114), ToggleOff = rgb(198, 203, 214),
                SliderTrack = rgb(205, 210, 221), LoadTrack = rgb(214, 218, 228), KnobOff = rgb(146, 153, 168),
                TabText = rgb(62, 68, 84), Placeholder = rgb(138, 145, 160), BtnHover = rgb(220, 224, 233),
                Title = rgb(20, 22, 32), TabSelText = rgb(18, 26, 48),
            },
        },
    }

    local function build(spec, accentOverride)
        local p = spec.palette and copyT(spec.palette) or neutrals(spec)
        for k, v in pairs(spec.fixed or {}) do p[k] = v end
        local acc = accentOverride or ((not spec.palette) and spec.accent) or nil
        if acc then accentize(p, acc, spec.light) end
        return uniq(p)
    end

    local Active = { name = "Default", accent = nil }
    Lib._guis = {}

    local function recolor(gui, map)
        local function fix(c) return map[ckey(c)] end
        local function seq(cs)
            local pts, changed = {}, false
            for i, kp in ipairs(cs.Keypoints) do
                local n = fix(kp.Value)
                if n then changed = true end
                pts[i] = ColorSequenceKeypoint.new(kp.Time, n or kp.Value)
            end
            return changed and ColorSequence.new(pts) or nil
        end
        for _, d in ipairs(gui:GetDescendants()) do
            pcall(function()
                if d:IsA("GuiObject") then
                    local n = fix(d.BackgroundColor3); if n then d.BackgroundColor3 = n end
                    if d:IsA("TextLabel") or d:IsA("TextButton") or d:IsA("TextBox") then
                        n = fix(d.TextColor3); if n then d.TextColor3 = n end
                        if d:IsA("TextBox") then n = fix(d.PlaceholderColor3); if n then d.PlaceholderColor3 = n end end
                    elseif d:IsA("ScrollingFrame") then
                        n = fix(d.ScrollBarImageColor3); if n then d.ScrollBarImageColor3 = n end
                    elseif d:IsA("ImageLabel") or d:IsA("ImageButton") then
                        n = fix(d.ImageColor3); if n then d.ImageColor3 = n end
                    end
                elseif d:IsA("UIStroke") then
                    local n = fix(d.Color); if n then d.Color = n end
                elseif d:IsA("UIGradient") then
                    local n = seq(d.Color); if n then d.Color = n end
                end
            end)
        end
    end

    local function applyPalette(newP)
        local map = {}
        for k, old in pairs(C) do
            local nv = newP[k]
            if nv and ckey(old) ~= ckey(nv) then map[ckey(old)] = nv end
        end
        for k, v in pairs(newP) do C[k] = v end
        for i = #Lib._guis, 1, -1 do
            local g = Lib._guis[i]
            if g.Parent then recolor(g, map) else table.remove(Lib._guis, i) end
        end
    end

    local function persist()
        pcall(function()
            if not (writefile and Lib._folder) then return end
            if makefolder and isfolder and not isfolder(Lib._folder) then makefolder(Lib._folder) end
            writefile(Lib._folder .. "/theme.json", HttpService:JSONEncode({
                name = Active.name, accent = Active.accent and toHex(Active.accent) or nil,
            }))
        end)
    end

    function Lib:GetThemeNames() return ThemeOrder end
    function Lib:GetTheme() return Active.name, Active.accent end
    function Lib:SetTheme(name)
        local spec = Specs[name]
        if not spec then return false end
        Active.name, Active.accent = name, nil
        applyPalette(build(spec))
        persist()
        return true
    end
    -- color: Color3, hex string, or nil (nil = remove accent override)
    function Lib:SetAccent(color)
        if type(color) == "string" then
            if color:gsub("%s", "") == "" then color = nil else
                color = parseHex(color)
                if not color then return false end
            end
        end
        Active.accent = color
        applyPalette(build(Specs[Active.name], color))
        persist()
        return true
    end
    function Lib:ResetTheme()
        Active.name, Active.accent = "Default", nil
        applyPalette(build(Specs["Default"]))
        persist()
    end
    function Lib:LoadSavedTheme()
        pcall(function()
            if not (isfile and readfile and Lib._folder) then return end
            local path = Lib._folder .. "/theme.json"
            if not isfile(path) then return end
            local d = HttpService:JSONDecode(readfile(path))
            local spec = d and Specs[d.name]
            if not spec then return end
            Active.name = d.name
            Active.accent = d.accent and parseHex(d.accent) or nil
            applyPalette(build(spec, Active.accent))
        end)
    end
    Lib.ToHex, Lib.ParseHex = toHex, parseHex

    function Lib:CreateWindow(opts)
        opts = opts or {}
        local isMobile = UIS.TouchEnabled and not UIS.KeyboardEnabled
        local Window = { Flags = {} }
        local flags = Window.Flags

        local gui = new("ScreenGui", {
            Name = "ByteWTF_" .. tostring(math.random(1000, 9999)),
            ResetOnSpawn = false, IgnoreGuiInset = true,
            ZIndexBehavior = Enum.ZIndexBehavior.Sibling, DisplayOrder = 999,
        })
        pcall(function() if syn and syn.protect_gui then syn.protect_gui(gui) end end)
        gui.Parent = getGuiParent()
        Window.Gui = gui
        table.insert(Lib._guis, gui)

        local W, H = 880, 560
        local SB, HD = 216, 66 -- sidebar width, header height
        local scaleVal = 1
        local function calcScale()
            local vp = workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize or Vector2.new(1280, 720)
            scaleVal = math.clamp(math.min(vp.X / (W + 40), vp.Y / (H + 40)), 0.45, 1)
            return scaleVal
        end

        local root = new("Frame", {
            Name = "Root", AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5),
            Size = UDim2.fromOffset(W, H), BackgroundColor3 = C.Window, BorderSizePixel = 0, Parent = gui,
        }, { corner(14), stroke(C.Stroke, 1) })
        local uiScale = new("UIScale", { Scale = calcScale(), Parent = root })
        if workspace.CurrentCamera then
            workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(function() uiScale.Scale = calcScale() end)
        end

        -- ===== left sidebar =====
        local sidebar = new("Frame", { Size = UDim2.new(0, SB, 1, 0), BackgroundColor3 = C.TitleBar, BorderSizePixel = 0, Parent = root }, { corner(14) })
        new("Frame", { Position = UDim2.new(1, -14, 0, 0), Size = UDim2.new(0, 14, 1, 0), BackgroundColor3 = C.TitleBar, BorderSizePixel = 0, Parent = sidebar })
        new("Frame", { Position = UDim2.new(1, -1, 0, 0), Size = UDim2.new(0, 1, 1, 0), BackgroundColor3 = C.Stroke, BorderSizePixel = 0, ZIndex = 2, Parent = sidebar })

        local brandZone = new("Frame", { Size = UDim2.new(1, 0, 0, 90), BackgroundTransparency = 1, Parent = sidebar })
        local logo = getLogo()
        local brand = new("Frame", {
            Position = UDim2.fromOffset(18, 18), Size = UDim2.fromOffset(54, 54), BackgroundColor3 = Color3.fromRGB(0, 0, 0),
            BorderSizePixel = 0, ClipsDescendants = true, Parent = sidebar,
        }, { corner(14), stroke(C.Stroke) })
        if logo then
            new("ImageLabel", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Image = logo, ScaleType = Enum.ScaleType.Crop, Parent = brand }, { corner(14) })
        else
            text(brand, { Text = "B", TextSize = 26, FontFace = font(Enum.FontWeight.Bold), TextColor3 = Color3.new(1, 1, 1), Size = UDim2.fromScale(1, 1) })
        end
        text(sidebar, { Text = opts.Name or "Byte.WTF", TextSize = 18, FontFace = font(Enum.FontWeight.Bold), TextColor3 = C.Title, Position = UDim2.fromOffset(82, 21), Size = UDim2.new(1, -92, 0, 24), TextXAlignment = Enum.TextXAlignment.Left })
        text(sidebar, { Text = opts.LoadingSubtitle or "Byte On Top", TextSize = 12, TextColor3 = C.Muted, Position = UDim2.fromOffset(82, 46), Size = UDim2.new(1, -92, 0, 18), TextXAlignment = Enum.TextXAlignment.Left })

        local tabBar = new("ScrollingFrame", {
            Position = UDim2.fromOffset(12, 96), Size = UDim2.new(1, -24, 1, -178), BackgroundTransparency = 1, BorderSizePixel = 0,
            ScrollBarThickness = 0, AutomaticCanvasSize = Enum.AutomaticSize.Y, CanvasSize = UDim2.new(), ScrollingDirection = Enum.ScrollingDirection.Y, Parent = sidebar,
        }, { new("UIListLayout", { FillDirection = Enum.FillDirection.Vertical, Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder }) })

        -- user card (bottom of sidebar)
        do
            local card = new("Frame", {
                AnchorPoint = Vector2.new(0, 1), Position = UDim2.new(0, 12, 1, -12), Size = UDim2.new(1, -24, 0, 60),
                BackgroundColor3 = C.Panel, BorderSizePixel = 0, Parent = sidebar,
            }, { corner(12), stroke(C.Stroke) })
            local av = new("ImageLabel", { Position = UDim2.fromOffset(12, 12), Size = UDim2.fromOffset(36, 36), BackgroundColor3 = C.Field, BorderSizePixel = 0, Parent = card }, { corner(18) })
            task.spawn(function()
                local ok, img = pcall(function()
                    return Players:GetUserThumbnailAsync(LP.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size100x100)
                end)
                if ok and img and av.Parent then av.Image = img end
            end)
            text(card, { Text = LP.DisplayName, TextSize = 13, FontFace = font(Enum.FontWeight.Bold), Position = UDim2.fromOffset(58, 12), Size = UDim2.new(1, -66, 0, 18), TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd })
            text(card, { Text = "@" .. LP.Name, TextSize = 11, TextColor3 = C.Muted, Position = UDim2.fromOffset(58, 31), Size = UDim2.new(1, -66, 0, 16), TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd })
        end

        -- ===== header (page title, search, minimize, close) =====
        local header = new("Frame", { Position = UDim2.fromOffset(SB, 0), Size = UDim2.new(1, -SB, 0, HD), BackgroundTransparency = 1, Parent = root })
        local headerTitle = text(header, { Text = "", TextSize = 20, FontFace = font(Enum.FontWeight.Bold), TextColor3 = C.Title, Position = UDim2.fromOffset(26, 0), Size = UDim2.new(0, 200, 1, 0), TextXAlignment = Enum.TextXAlignment.Left })

        local function winBtn(offsetRight)
            local b = new("TextButton", {
                AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -offsetRight, 0.5, 0), Size = UDim2.fromOffset(38, 38),
                BackgroundColor3 = C.Field, Text = "", AutoButtonColor = false, ZIndex = 5, Parent = header,
            }, { corner(10), stroke(C.Stroke) })
            b.MouseEnter:Connect(function() tween(b, 0.1, { BackgroundColor3 = C.BtnHover }) end)
            b.MouseLeave:Connect(function() tween(b, 0.1, { BackgroundColor3 = C.Field }) end)
            return b
        end
        local closeB = winBtn(20)
        local minB = winBtn(66)
        new("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(12, 2), BackgroundColor3 = C.Header, BorderSizePixel = 0, ZIndex = 6, Parent = minB }, { corner(1) })
        for _, r in ipairs({ 45, -45 }) do
            new("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(15, 2), Rotation = r, BackgroundColor3 = C.Header, BorderSizePixel = 0, ZIndex = 6, Parent = closeB }, { corner(1) })
        end

        -- dragging (header + logo area)
        do
            local dragging, dragStart, startPos
            local function bind(h)
                h.InputBegan:Connect(function(i)
                    if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
                        dragging, dragStart, startPos = true, i.Position, root.Position
                    end
                end)
            end
            bind(header); bind(brandZone)
            UIS.InputChanged:Connect(function(i)
                if dragging and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then
                    local d = (i.Position - dragStart) / uiScale.Scale
                    root.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X, startPos.Y.Scale, startPos.Y.Offset + d.Y)
                end
            end)
            UIS.InputEnded:Connect(function(i)
                if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then dragging = false end
            end)
        end

        local content = new("Frame", {
            Position = UDim2.fromOffset(SB + 22, HD + 6), Size = UDim2.new(1, -(SB + 44), 1, -(HD + 26)), BackgroundTransparency = 1, Parent = root,
        })

        -- overlay for dropdown popups
        local overlay = new("TextButton", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Text = "", Visible = false, ZIndex = 50, AutoButtonColor = false, Parent = gui })
        local openPopup
        local function closePopup()
            if openPopup then openPopup:Destroy(); openPopup = nil end
            overlay.Visible = false
        end
        overlay.MouseButton1Click:Connect(closePopup)

        -- toggle keybind + mobile button
        local toggleKey = opts.ToggleUIKeybind
        if type(toggleKey) == "string" then toggleKey = Enum.KeyCode[toggleKey] end
        local uiReady = true
        local function toggleUI() if not uiReady then return end closePopup(); root.Visible = not root.Visible end
        UIS.InputBegan:Connect(function(i, gp)
            if gp then return end
            if toggleKey and i.KeyCode == toggleKey then toggleUI() end
        end)
        local function hideUI() if not uiReady then return end closePopup(); root.Visible = false end

        -- floating circle that reopens the menu (shown whenever the window is hidden)
        local openBtn = new("TextButton", {
            Size = UDim2.fromOffset(50, 50), Position = UDim2.new(0, 18, 0.5, -25), BackgroundColor3 = Color3.fromRGB(0, 0, 0),
            Text = "", AutoButtonColor = false, Visible = false, ZIndex = 60, ClipsDescendants = true, Parent = gui,
        }, { corner(25), stroke(C.StrokeLt, 1.5) })
        if logo then
            new("ImageLabel", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Image = logo, ScaleType = Enum.ScaleType.Crop, ZIndex = 61, Parent = openBtn }, { corner(25) })
        else
            text(openBtn, { Text = "B", TextSize = 20, FontFace = font(Enum.FontWeight.Bold), TextColor3 = Color3.new(1, 1, 1), Size = UDim2.fromScale(1, 1), ZIndex = 61 })
        end
        local function syncOpenBtn() openBtn.Visible = uiReady and not root.Visible end
        root:GetPropertyChangedSignal("Visible"):Connect(syncOpenBtn)
        syncOpenBtn()
        do -- click opens, drag moves
            local down, moved, startIn, startPos
            openBtn.InputBegan:Connect(function(i)
                if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
                    down, moved, startIn, startPos = true, false, i.Position, openBtn.Position
                end
            end)
            UIS.InputChanged:Connect(function(i)
                if down and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then
                    local d = i.Position - startIn
                    if moved or d.Magnitude > 6 then
                        moved = true
                        openBtn.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X, startPos.Y.Scale, startPos.Y.Offset + d.Y)
                    end
                end
            end)
            UIS.InputEnded:Connect(function(i)
                if down and (i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch) then
                    down = false
                    if not moved then toggleUI() end
                end
            end)
        end

        local function playLoadMusic()
            local id = tostring(LOAD_MUSIC_ID):gsub("%D", "")
            if id == "" or tonumber(id) == 0 then return end
            pcall(function()
                local snd = Instance.new("Sound")
                snd.Name = "ByteWTF_LoadMusic"
                snd.SoundId = "rbxassetid://" .. id
                snd.Volume = LOAD_MUSIC_VOLUME
                snd.Looped = false
                snd.Parent = game:GetService("SoundService")
                snd.Ended:Connect(function() snd:Destroy() end)
                snd:Play()
            end)
        end

        -- loading screen
        if opts.LoadingEnabled ~= false then
            uiReady = false
            root.Visible = false
            local yOff = logo and 0 or -34
            local loader = new("CanvasGroup", {
                AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(380, 232 + yOff),
                BackgroundColor3 = C.Window, BorderSizePixel = 0, GroupTransparency = 1, Parent = gui,
            }, { corner(14), stroke(C.Stroke), new("UIScale", { Scale = uiScale.Scale }) })
            if logo then
                new("ImageLabel", { AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 28), Size = UDim2.fromOffset(64, 64), BackgroundTransparency = 1, Image = logo, ScaleType = Enum.ScaleType.Fit, Parent = loader })
            end
            text(loader, { Text = opts.Name or "Byte.WTF", TextSize = 22, FontFace = font(Enum.FontWeight.Bold), TextColor3 = C.Title, Position = UDim2.fromOffset(0, 102 + yOff), Size = UDim2.new(1, 0, 0, 28) })
            text(loader, { Text = opts.LoadingSubtitle or "Loading", TextSize = 13, TextColor3 = C.Muted, Position = UDim2.fromOffset(0, 132 + yOff), Size = UDim2.new(1, 0, 0, 20) })
            local barTrack = new("Frame", { AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 174 + yOff), Size = UDim2.fromOffset(280, 6), BackgroundColor3 = C.LoadTrack, BorderSizePixel = 0, Parent = loader }, { corner(3) })
            local barFill = new("Frame", { Size = UDim2.fromScale(0, 1), BackgroundColor3 = Color3.new(1, 1, 1), BorderSizePixel = 0, Parent = barTrack }, {
                corner(3), new("UIGradient", { Color = ColorSequence.new(C.AccentDk, C.Accent) }),
            })
            local statusLbl = text(loader, { Text = "Initializing", TextSize = 12, TextColor3 = C.Muted, Position = UDim2.fromOffset(0, 190 + yOff), Size = UDim2.new(1, 0, 0, 20) })

            task.spawn(function()
                tween(loader, 0.3, { GroupTransparency = 0 })
                local steps = {
                    { "Initializing", 0.18 }, { "Loading modules", 0.46 }, { "Building interface", 0.76 },
                    { "Applying theme", 0.93 }, { "Ready", 1 },
                }
                for _, st in ipairs(steps) do
                    statusLbl.Text = st[1]
                    tween(barFill, 0.4, { Size = UDim2.fromScale(st[2], 1) })
                    task.wait(0.45)
                end
                task.wait(0.2)
                tween(loader, 0.3, { GroupTransparency = 1 })
                task.wait(0.32)
                loader:Destroy()
                uiScale.Scale = calcScale() * 0.94
                root.Visible = true
                uiReady = true
                tween(uiScale, 0.22, { Scale = calcScale() })
                playLoadMusic()
            end)
        else
            playLoadMusic()
        end

        -- notifications
        local toasts = new("Frame", {
            AnchorPoint = Vector2.new(1, 1), Position = UDim2.new(1, -16, 1, -16), Size = UDim2.fromOffset(260, 0),
            AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1, Parent = gui,
        }, { new("UIListLayout", { Padding = UDim.new(0, 8), VerticalAlignment = Enum.VerticalAlignment.Bottom, SortOrder = Enum.SortOrder.LayoutOrder }) })
        function Window:Notify(p)
            p = p or {}
            local t = new("CanvasGroup", {
                Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundColor3 = C.Panel, BorderSizePixel = 0,
                GroupTransparency = 1, Parent = toasts,
            }, { corner(8), stroke(C.StrokeLt), pad(12, 10, 12, 10), new("UIListLayout", { Padding = UDim.new(0, 2) }) })
            text(t, { Text = tostring(p.title or p.Title or "Notice"), FontFace = font(Enum.FontWeight.Bold), TextSize = 13, Size = UDim2.new(1, 0, 0, 16), TextXAlignment = Enum.TextXAlignment.Left, LayoutOrder = 1 })
            text(t, { Text = tostring(p.content or p.Content or ""), TextSize = 12, TextColor3 = C.Muted, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, TextWrapped = true, TextXAlignment = Enum.TextXAlignment.Left, LayoutOrder = 2 })
            tween(t, 0.2, { GroupTransparency = 0 })
            task.delay(tonumber(p.duration or p.Duration) or 3, function()
                if t.Parent then tween(t, 0.25, { GroupTransparency = 1 }); task.wait(0.3); t:Destroy() end
            end)
        end

        -- configs
        local cfgCfg = opts.ConfigurationSaving or {}
        local folder = cfgCfg.FolderName or "Byte.WTF"
        Lib._folder = folder
        Lib:LoadSavedTheme() -- re-applies the last theme the user picked
        function Window:SaveConfig(name)
            name = (name and name ~= "") and name or "default"
            local data = {}
            for flag, obj in pairs(flags) do data[flag] = ser(obj.Get()) end
            if makefolder and not (isfolder and isfolder(folder)) then pcall(makefolder, folder) end
            writefile(folder .. "/" .. name .. ".json", HttpService:JSONEncode(data))
        end
        function Window:LoadConfig(name)
            name = (name and name ~= "") and name or "default"
            local raw = readfile(folder .. "/" .. name .. ".json")
            local data = HttpService:JSONDecode(raw)
            for flag, v in pairs(data) do
                local obj = flags[flag]
                if obj then pcall(obj.Set, deser(v)) end
            end
        end
        function Window:Destroy() gui:Destroy() end

        -- tabs
        local tabs, activeTab = {}, nil
        local index = {} -- search registry: every control gets an entry
        local function selectTab(t)
            closePopup()
            activeTab = t
            headerTitle.Text = t.Name or ""
            for _, o in ipairs(tabs) do
                local on = (o == t)
                o.Page.Visible = on
                tween(o.Btn, 0.12, { BackgroundTransparency = on and 0 or 1, TextColor3 = on and C.TabSelText or C.TabText })
                tween(o.BtnStroke, 0.12, { Transparency = on and 0 or 1 })
            end
        end

        function Window:CreateTab(p)
            p = p or {}
            local Tab = { Panels = {}, Order = 0 }
            Tab.Name = p.Name or "Tab"
            local btn = new("TextButton", {
                Text = p.Name or "Tab", Size = UDim2.new(1, 0, 0, 42),
                BackgroundColor3 = C.TabOn, BackgroundTransparency = 1, TextColor3 = C.TabText, TextSize = 14, FontFace = font(Enum.FontWeight.Medium),
                AutoButtonColor = false, TextXAlignment = Enum.TextXAlignment.Left, LayoutOrder = #tabs + 1, Parent = tabBar,
            }, { corner(10), pad(18, 0, 12, 0) })
            local bs = stroke(C.TabOnStr); bs.Transparency = 1; bs.Parent = btn
            Tab.Btn, Tab.BtnStroke = btn, bs
            btn.MouseEnter:Connect(function() if activeTab ~= Tab then tween(btn, 0.1, { TextColor3 = C.Text }) end end)
            btn.MouseLeave:Connect(function() if activeTab ~= Tab then tween(btn, 0.1, { TextColor3 = C.TabText }) end end)

            local page = new("ScrollingFrame", {
                Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 3,
                ScrollBarImageColor3 = C.StrokeLt, AutomaticCanvasSize = Enum.AutomaticSize.Y, CanvasSize = UDim2.new(),
                ScrollingDirection = Enum.ScrollingDirection.Y, Visible = false, Parent = content,
            }, { pad(0, 0, 4, 4) })
            Tab.Page = page
            local function column(x, w)
                return new("Frame", {
                    Position = x, Size = w, AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1, Parent = page,
                }, { new("UIListLayout", { Padding = UDim.new(0, 16), SortOrder = Enum.SortOrder.LayoutOrder }) })
            end
            local colL = column(UDim2.fromOffset(0, 0), UDim2.new(0.5, -8, 0, 0))
            local colR = column(UDim2.new(0.5, 8, 0, 0), UDim2.new(0.5, -8, 0, 0))

            local pending = false
            local function relayout()
                if pending then return end
                pending = true
                task.defer(function()
                    pending = false
                    local hL, hR = 0, 0
                    for i, pn in ipairs(Tab.Panels) do
                        local toRight
                        if pn.Pin == "Right" then toRight = true
                        elseif pn.Pin == "Left" then toRight = false
                        else toRight = hR < hL end
                        local h = 60 + pn.Est
                        pn.Frame.LayoutOrder = i
                        pn.Frame.Parent = toRight and colR or colL
                        if toRight then hR = hR + h + 16 else hL = hL + h + 16 end
                    end
                end)
            end

            local function newPanel(name, pin)
                local f = new("Frame", {
                    Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundColor3 = C.Panel, BorderSizePixel = 0,
                }, { corner(12), stroke(C.Stroke), pad(20, 20, 20, 20), new("UIListLayout", { Padding = UDim.new(0, 14), SortOrder = Enum.SortOrder.LayoutOrder }) })
                text(f, { Text = name, TextSize = 15, FontFace = font(Enum.FontWeight.Bold), TextColor3 = C.Text, Size = UDim2.new(1, 0, 0, 22), TextXAlignment = Enum.TextXAlignment.Left, LayoutOrder = 0 })
                local pn = { Frame = f, Est = 0, Pin = pin, Order = 0, Name = name }
                table.insert(Tab.Panels, pn)
                relayout()
                return pn
            end

            local function addItem(pn, h)
                pn.Order = pn.Order + 1
                pn.Est = pn.Est + h + 14
                relayout()
                return pn.Order
            end

            local function reg(flag, getter, setter)
                if flag then flags[flag] = { Get = getter, Set = setter } end
            end

            -- builders; each takes the panel they belong to
            local B = {}

            function B.Toggle(pn, o)
                local checkbox = (o.Style == "Checkbox") or o.Checkbox == true
                local hasDesc = o.Desc and o.Desc ~= ""
                local h = hasDesc and 54 or 34
                local row = new("Frame", { Size = UDim2.new(1, 0, 0, h), BackgroundTransparency = 1, LayoutOrder = addItem(pn, h), Parent = pn.Frame })
                text(row, { Text = o.Name or "Toggle", Position = UDim2.fromOffset(0, hasDesc and 2 or 0), Size = UDim2.new(1, -70, 0, hasDesc and 22 or h), TextXAlignment = Enum.TextXAlignment.Left })
                if hasDesc then
                    text(row, { Text = o.Desc, TextSize = 12, TextColor3 = C.Muted, Position = UDim2.fromOffset(0, 28), Size = UDim2.new(1, -70, 0, 18), TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd })
                end
                local hit = new("TextButton", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Text = "", Parent = row })
                local state = o.CurrentValue == true
                local obj = {}
                local render
                if checkbox then
                    local box = new("Frame", { AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, 0, 0.5, 0), Size = UDim2.fromOffset(22, 22), BackgroundColor3 = C.ToggleOff, BorderSizePixel = 0, Parent = row }, { corner(6), stroke(C.StrokeLt) })
                    local c1 = new("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromOffset(8, 13), Size = UDim2.fromOffset(6, 2), Rotation = 45, BackgroundColor3 = C.BtnDark, BorderSizePixel = 0, Parent = box })
                    local c2 = new("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromOffset(13, 11), Size = UDim2.fromOffset(11, 2), Rotation = -45, BackgroundColor3 = C.BtnDark, BorderSizePixel = 0, Parent = box })
                    render = function(animate)
                        c1.Visible, c2.Visible = state, state
                        local col = state and C.ToggleOn or C.ToggleOff
                        if animate then tween(box, 0.12, { BackgroundColor3 = col }) else box.BackgroundColor3 = col end
                    end
                else
                    local track = new("Frame", { AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, 0, 0.5, 0), Size = UDim2.fromOffset(44, 24), BackgroundColor3 = C.ToggleOff, BorderSizePixel = 0, Parent = row }, { corner(12) })
                    local knob = new("Frame", { AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 4, 0.5, 0), Size = UDim2.fromOffset(16, 16), BackgroundColor3 = C.KnobOff, BorderSizePixel = 0, Parent = track }, { corner(8) })
                    render = function(animate)
                        local tp = { BackgroundColor3 = state and C.ToggleOn or C.ToggleOff }
                        local kp = { Position = state and UDim2.new(1, -20, 0.5, 0) or UDim2.new(0, 4, 0.5, 0), BackgroundColor3 = state and C.BtnDark or C.KnobOff }
                        if animate then tween(track, 0.15, tp); tween(knob, 0.15, kp)
                        else for k, v in pairs(tp) do track[k] = v end for k, v in pairs(kp) do knob[k] = v end end
                    end
                end
                render(false)
                function obj:Set(v)
                    v = v == true
                    if v == state then return end
                    state = v; render(true)
                    if o.Callback then task.spawn(o.Callback, state) end
                end
                function obj:Get() return state end
                hit.MouseButton1Click:Connect(function() obj:Set(not state) end)
                reg(o.Flag, obj.Get, function(v) obj:Set(v) end)
                return obj
            end

            function B.Slider(pn, o)
                local h = 54
                local row = new("Frame", { Size = UDim2.new(1, 0, 0, h), BackgroundTransparency = 1, LayoutOrder = addItem(pn, h), Parent = pn.Frame })
                text(row, { Text = o.Name or "Slider", Size = UDim2.new(0.65, 0, 0, 22), TextXAlignment = Enum.TextXAlignment.Left })
                local valLbl = text(row, { Text = "", TextSize = 13, TextColor3 = C.Muted, AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, 0, 0, 0), Size = UDim2.new(0.35, 0, 0, 22), TextXAlignment = Enum.TextXAlignment.Right })
                local min, max = (o.Range and o.Range[1]) or 0, (o.Range and o.Range[2]) or 100
                local inc = o.Increment or 1
                local dec = #((tostring(inc):match("%.(%d+)")) or "")
                local suffix = (o.Suffix and o.Suffix ~= "") and (" " .. o.Suffix) or ""
                local track = new("Frame", { Position = UDim2.new(0, 0, 0, 35), Size = UDim2.new(1, 0, 0, 4), BackgroundColor3 = C.SliderTrack, BorderSizePixel = 0, Parent = row }, { corner(2) })
                local fill = new("Frame", { Size = UDim2.fromScale(0, 1), BackgroundColor3 = Color3.new(1, 1, 1), BorderSizePixel = 0, Parent = track }, {
                    corner(2),
                    new("UIGradient", { Color = ColorSequence.new(C.AccentDk, C.Accent) }),
                })
                local knob = new("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0, 0, 0.5, 0), Size = UDim2.fromOffset(14, 14), BackgroundColor3 = Color3.new(1, 1, 1), BorderSizePixel = 0, ZIndex = 2, Parent = track }, { corner(7), stroke(C.Accent, 2) })
                local hit = new("TextButton", { Position = UDim2.new(0, 0, 0, 28), Size = UDim2.new(1, 0, 0, 26), BackgroundTransparency = 1, Text = "", Parent = row })

                local value = math.clamp(o.CurrentValue or min, min, max)
                local obj = {}
                local function snap(v)
                    v = math.clamp(math.floor((v - min) / inc + 0.5) * inc + min, min, max)
                    return tonumber(string.format("%." .. dec .. "f", v))
                end
                local function render()
                    local a = (max == min) and 0 or (value - min) / (max - min)
                    fill.Size = UDim2.fromScale(a, 1)
                    knob.Position = UDim2.new(a, 0, 0.5, 0)
                    valLbl.Text = string.format("%." .. dec .. "f", value) .. suffix
                end
                render()
                function obj:Set(v, silent)
                    v = snap(tonumber(v) or min)
                    if v == value then return end
                    value = v; render()
                    if o.Callback and not silent then task.spawn(o.Callback, value) end
                end
                function obj:Get() return value end

                local dragging = false
                local function fromInput(i)
                    local a = math.clamp((i.Position.X - track.AbsolutePosition.X) / math.max(track.AbsoluteSize.X, 1), 0, 1)
                    obj:Set(min + (max - min) * a)
                end
                hit.InputBegan:Connect(function(i)
                    if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
                        dragging = true; page.ScrollingEnabled = false; fromInput(i)
                    end
                end)
                UIS.InputChanged:Connect(function(i)
                    if dragging and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then fromInput(i) end
                end)
                UIS.InputEnded:Connect(function(i)
                    if dragging and (i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch) then
                        dragging = false; page.ScrollingEnabled = true
                    end
                end)
                reg(o.Flag, obj.Get, function(v) obj:Set(v) end)
                return obj
            end

            function B.Dropdown(pn, o)
                local h = 68
                local row = new("Frame", { Size = UDim2.new(1, 0, 0, h), BackgroundTransparency = 1, LayoutOrder = addItem(pn, h), Parent = pn.Frame })
                text(row, { Text = o.Name or "Dropdown", Size = UDim2.new(1, 0, 0, 22), TextXAlignment = Enum.TextXAlignment.Left })
                local box = new("TextButton", {
                    Position = UDim2.fromOffset(0, 28), Size = UDim2.new(1, 0, 0, 38),
                    BackgroundColor3 = C.Field, Text = "", AutoButtonColor = false, Parent = row,
                }, { corner(7), stroke(C.Stroke) })
                local valLbl = text(box, { Text = "", TextSize = 13, Position = UDim2.fromOffset(12, 0), Size = UDim2.new(1, -36, 1, 0), TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd })
                do -- chevron drawn from two thin bars (no font glyphs)
                    local chev = new("Frame", { AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -12, 0.5, 0), Size = UDim2.fromOffset(10, 6), BackgroundTransparency = 1, Parent = box })
                    for _, d in ipairs({ { 3, 40 }, { 7, -40 } }) do
                        new("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromOffset(d[1], 3), Size = UDim2.fromOffset(7, 2), Rotation = d[2], BackgroundColor3 = C.Muted, BorderSizePixel = 0, Parent = chev }, { corner(1) })
                    end
                end

                local options = o.Options or {}
                local current = o.CurrentValue
                if type(current) == "table" then current = current[1] end
                local obj = {}
                local function render()
                    if current ~= nil and current ~= "" then
                        valLbl.Text = tostring(current); valLbl.TextColor3 = C.Text
                    else
                        valLbl.Text = o.Placeholder or "Select"; valLbl.TextColor3 = C.Muted
                    end
                end
                render()
                function obj:Set(v, silent)
                    current = v; render()
                    if o.Callback and not silent then task.spawn(o.Callback, v) end
                end
                function obj:Get() return current end
                function obj:Refresh(list) options = list or {} end

                box.MouseButton1Click:Connect(function()
                    if openPopup then closePopup() return end
                    if o.Dynamic then
                        local ok, list = pcall(o.Dynamic)
                        if ok and type(list) == "table" then options = list end
                    end
                    local s = uiScale.Scale
                    local shown = math.min(#options, 6)
                    local ph = math.max(shown, 1) * 32 + 10
                    local pop = new("Frame", {
                        Position = UDim2.fromOffset(box.AbsolutePosition.X, box.AbsolutePosition.Y + box.AbsoluteSize.Y + 4),
                        Size = UDim2.fromOffset(box.AbsoluteSize.X / s, ph), BackgroundColor3 = C.Field, BorderSizePixel = 0, ZIndex = 51, Parent = overlay,
                    }, { corner(7), stroke(C.StrokeLt), new("UIScale", { Scale = s }) })
                    local list = new("ScrollingFrame", {
                        Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 2,
                        ScrollBarImageColor3 = C.StrokeLt, AutomaticCanvasSize = Enum.AutomaticSize.Y, CanvasSize = UDim2.new(), ZIndex = 52, Parent = pop,
                    }, { pad(5, 5, 5, 5), new("UIListLayout", { Padding = UDim.new(0, 0), SortOrder = Enum.SortOrder.LayoutOrder }) })
                    if #options == 0 then
                        text(list, { Text = "No options", TextSize = 12, TextColor3 = C.Muted, Size = UDim2.new(1, 0, 0, 32), ZIndex = 53 })
                    end
                    for i, name in ipairs(options) do
                        local b = new("TextButton", {
                            Size = UDim2.new(1, 0, 0, 32), BackgroundColor3 = C.TabOn, BackgroundTransparency = 1, Text = tostring(name),
                            TextColor3 = (name == current) and C.Accent or C.Text, TextSize = 13, FontFace = font(), AutoButtonColor = false,
                            TextXAlignment = Enum.TextXAlignment.Left, LayoutOrder = i, ZIndex = 53, Parent = list,
                        }, { corner(6), pad(10, 0, 10, 0) })
                        b.MouseEnter:Connect(function() b.BackgroundTransparency = 0 end)
                        b.MouseLeave:Connect(function() b.BackgroundTransparency = 1 end)
                        b.MouseButton1Click:Connect(function() closePopup(); obj:Set(name) end)
                    end
                    openPopup = pop
                    overlay.Visible = true
                end)
                reg(o.Flag, obj.Get, function(v) obj:Set(v) end)
                return obj
            end

            function B.Keybind(pn, o)
                local h = 36
                local row = new("Frame", { Size = UDim2.new(1, 0, 0, h), BackgroundTransparency = 1, LayoutOrder = addItem(pn, h), Parent = pn.Frame })
                text(row, { Text = o.Name or "Keybind", Size = UDim2.new(1, -130, 1, 0), TextXAlignment = Enum.TextXAlignment.Left })
                local box = new("TextButton", {
                    AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, 0, 0.5, 0), Size = UDim2.fromOffset(88, 30),
                    BackgroundColor3 = C.Field, TextColor3 = C.Text, TextSize = 13, FontFace = font(), AutoButtonColor = false, Text = "", Parent = row,
                }, { corner(6), stroke(C.Stroke) })
                local key = o.CurrentValue
                if type(key) == "string" then key = Enum.KeyCode[key] end
                local function render() box.Text = key and key.Name or "None" end
                render()
                local obj = {}
                function obj:Set(k, silent)
                    if type(k) == "string" then k = Enum.KeyCode[k] end
                    key = k; render()
                    if o.Callback and not silent and k then task.spawn(o.Callback, k) end
                end
                function obj:Get() return key end
                local listening = false
                box.MouseButton1Click:Connect(function()
                    if listening then return end
                    listening = true; box.Text = "..."; box.TextColor3 = C.Accent
                    local conn
                    conn = UIS.InputBegan:Connect(function(i)
                        if i.UserInputType == Enum.UserInputType.Keyboard then
                            conn:Disconnect(); listening = false; box.TextColor3 = C.Text
                            if i.KeyCode ~= Enum.KeyCode.Escape then obj:Set(i.KeyCode) else render() end
                        end
                    end)
                end)
                reg(o.Flag, obj.Get, function(v) obj:Set(v) end)
                return obj
            end

            function B.Input(pn, o)
                local h = 72
                local row = new("Frame", { Size = UDim2.new(1, 0, 0, h), BackgroundTransparency = 1, LayoutOrder = addItem(pn, h), Parent = pn.Frame })
                text(row, { Text = o.Name or "Input", Size = UDim2.new(1, 0, 0, 22), TextXAlignment = Enum.TextXAlignment.Left })
                local tb = new("TextBox", {
                    Position = UDim2.fromOffset(0, 30), Size = UDim2.new(1, 0, 0, 38), BackgroundColor3 = C.Field, Text = tostring(o.CurrentValue or ""),
                    PlaceholderText = o.Placeholder or "", PlaceholderColor3 = C.Placeholder, TextColor3 = C.Text,
                    TextSize = 13, FontFace = font(), ClearTextOnFocus = false, TextXAlignment = Enum.TextXAlignment.Left, Parent = row,
                }, { corner(7), stroke(C.Stroke), pad(12, 0, 12, 0) })
                local obj = {}
                function obj:Set(v) tb.Text = tostring(v or "") end
                function obj:Get() return tb.Text end
                tb.Focused:Connect(function() tb.UIStroke.Color = C.Accent end)
                tb.FocusLost:Connect(function()
                    tb.UIStroke.Color = C.Stroke
                    if o.Callback then task.spawn(o.Callback, tb.Text) end
                    if o.RemoveTextAfterFocusLost then tb.Text = "" end
                end)
                reg(o.Flag, obj.Get, function(v) tb.Text = tostring(v or ""); if o.Callback then task.spawn(o.Callback, tb.Text) end end)
                return obj
            end

            local function makeButton(parent, b, size, pos)
                local primary = (b.Style ~= "Secondary")
                local btn = new("TextButton", {
                    Size = size, Position = pos or UDim2.new(), BackgroundColor3 = primary and C.Accent or C.Field, Text = b.Name or "Button",
                    TextColor3 = primary and C.BtnDark or C.Text, TextSize = 13, FontFace = font(Enum.FontWeight.Bold), AutoButtonColor = false, Parent = parent,
                }, { corner(7) })
                if not primary then stroke(C.Stroke).Parent = btn end
                -- read colours at hover time so buttons follow theme changes
                btn.MouseEnter:Connect(function() tween(btn, 0.1, { BackgroundColor3 = primary and C.AccentHover or C.BtnHover }) end)
                btn.MouseLeave:Connect(function() tween(btn, 0.1, { BackgroundColor3 = primary and C.Accent or C.Field }) end)
                btn.MouseButton1Click:Connect(function() if b.Callback then task.spawn(b.Callback) end end)
                return btn
            end

            function B.Button(pn, o)
                local h = 40
                local row = new("Frame", { Size = UDim2.new(1, 0, 0, h), BackgroundTransparency = 1, LayoutOrder = addItem(pn, h), Parent = pn.Frame })
                makeButton(row, o, UDim2.fromScale(1, 1))
                return {}
            end

            -- { {Name=, Callback=, Style=}, {...} }  (first button wide, rest narrow, like the screenshot)
            function B.ButtonRow(pn, list)
                local h = 40
                local row = new("Frame", { Size = UDim2.new(1, 0, 0, h), BackgroundTransparency = 1, LayoutOrder = addItem(pn, h), Parent = pn.Frame })
                new("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 10), SortOrder = Enum.SortOrder.LayoutOrder, Parent = row })
                local n = #list
                for i, b in ipairs(list) do
                    local w = (n == 1) and UDim2.fromScale(1, 1)
                        or (i == 1 and UDim2.new(0.62, -5, 1, 0) or UDim2.new(0.38 / (n - 1), -5, 1, 0))
                    local btn = makeButton(row, b, w)
                    btn.LayoutOrder = i
                end
                return {}
            end

            function B.Label(pn, o)
                local h = 22
                local row = new("Frame", { Size = UDim2.new(1, 0, 0, h), BackgroundTransparency = 1, LayoutOrder = addItem(pn, h), Parent = pn.Frame })
                local l = text(row, { Text = o.Name or o.Text or "", TextSize = 13, TextColor3 = C.Muted, Size = UDim2.fromScale(1, 1), TextXAlignment = Enum.TextXAlignment.Left })
                return { Set = function(_, t) l.Text = t end }
            end

            function B.Divider(pn)
                local row = new("Frame", { Size = UDim2.new(1, 0, 0, 1), BackgroundColor3 = C.Stroke, BorderSizePixel = 0, LayoutOrder = addItem(pn, 1), Parent = pn.Frame })
                return {}
            end

            local function install(target, getPanel)
                local function wrap(fn, kind)
                    return function(self, o)
                        local pn = getPanel()
                        local res = fn(pn, o)
                        if kind then
                            local row
                            for _, c in ipairs(pn.Frame:GetChildren()) do
                                if c:IsA("Frame") and c.LayoutOrder == pn.Order then row = c break end
                            end
                            if row then
                                local names = {}
                                if kind == "row" then
                                    for _, b in ipairs(o) do table.insert(names, b.Name or "Button") end
                                else
                                    table.insert(names, o.Name or "Item")
                                end
                                for _, nm in ipairs(names) do
                                    table.insert(index, {
                                        Name = nm, Desc = (kind == "item") and o.Desc or nil, Tab = Tab,
                                        TabName = p.Name or "Tab", Section = pn.Name, Row = row,
                                    })
                                end
                            end
                        end
                        return res
                    end
                end
                target.CreateToggle    = wrap(B.Toggle, "item")
                target.CreateSlider    = wrap(B.Slider, "item")
                target.CreateDropdown  = wrap(B.Dropdown, "item")
                target.CreateKeybind   = wrap(B.Keybind, "item")
                target.CreateInput     = wrap(B.Input, "item")
                target.CreateButton    = wrap(B.Button, "item")
                target.CreateButtonRow = wrap(B.ButtonRow, "row")
                target.CreateLabel     = wrap(B.Label)
                target.CreateParagraph = wrap(B.Label)
                target.CreateDivider   = wrap(B.Divider)
            end

            local current
            install(Tab, function()
                if not current then current = newPanel(p.Name or "Options") end
                return current
            end)

            function Tab:CreateSection(s)
                local name, pin = s, nil
                if type(s) == "table" then name, pin = s.Name or s.Title or "Section", s.Column end
                current = newPanel(tostring(name), pin)
                local Section = {}
                local mine = current
                install(Section, function() return mine end)
                return Section
            end

            btn.MouseButton1Click:Connect(function() selectTab(Tab) end)
            table.insert(tabs, Tab)
            if #tabs == 1 then selectTab(Tab) end
            return Tab
        end

        -- ===== search bar (top right of the title bar) =====
        do
            local box = new("TextBox", {
                AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -114, 0.5, 0), Size = UDim2.fromOffset(300, 38),
                BackgroundColor3 = C.Field, Text = "", PlaceholderText = "Search Functions...", ZIndex = 6,
                PlaceholderColor3 = C.Placeholder, TextColor3 = C.Text, TextSize = 13, FontFace = font(),
                ClearTextOnFocus = false, TextXAlignment = Enum.TextXAlignment.Left, Parent = header,
            }, { corner(10), stroke(C.Stroke), pad(42, 0, 14, 0) })
            do -- magnifier icon drawn from frames
                local ic = new("Frame", { AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(1, -(114 + 300 - 15), 0.5, 0), Size = UDim2.fromOffset(16, 16), BackgroundTransparency = 1, ZIndex = 7, Parent = header })
                new("Frame", { Size = UDim2.fromOffset(11, 11), BackgroundTransparency = 1, ZIndex = 7, Parent = ic }, { corner(6), stroke(C.Header, 1.5) })
                new("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromOffset(12.5, 12.5), Size = UDim2.fromOffset(6, 2), Rotation = 45, BackgroundColor3 = C.Header, BorderSizePixel = 0, ZIndex = 7, Parent = ic }, { corner(1) })
            end

            local results = new("Frame", {
                AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -114, 0, 58), Size = UDim2.fromOffset(420, 0),
                BackgroundColor3 = C.Field, BorderSizePixel = 0, Visible = false, ZIndex = 40, ClipsDescendants = true, Parent = root,
            }, { corner(9), stroke(C.StrokeLt) })
            local list = new("ScrollingFrame", {
                Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 3, ScrollBarImageColor3 = C.StrokeLt,
                AutomaticCanvasSize = Enum.AutomaticSize.Y, CanvasSize = UDim2.new(), ZIndex = 41, Parent = results,
            }, { pad(6, 6, 6, 6), new("UIListLayout", { Padding = UDim.new(0, 2), SortOrder = Enum.SortOrder.LayoutOrder }) })

            -- block everything behind the results while they're open
            results.Active = true
            list.Active = true
            local blocker = new("TextButton", {
                Position = UDim2.fromOffset(0, HD), Size = UDim2.new(1, 0, 1, -HD), BackgroundTransparency = 1, Text = "",
                AutoButtonColor = false, Active = true, Visible = false, ZIndex = 30, Parent = root,
            })
            blocker.MouseButton1Click:Connect(function() results.Visible = false; box:ReleaseFocus() end)
            results:GetPropertyChangedSignal("Visible"):Connect(function() blocker.Visible = results.Visible end)

            local current = {}
            local function jump(e)
                if not e then return end
                results.Visible = false
                box:ReleaseFocus()
                closePopup()
                selectTab(e.Tab)
                task.spawn(function()
                    task.wait(0.08)
                    local page = e.Tab.Page
                    local y = e.Row.AbsolutePosition.Y - page.AbsolutePosition.Y + page.CanvasPosition.Y - 12
                    page.CanvasPosition = Vector2.new(0, math.max(0, y))
                    local hl = new("Frame", {
                        Size = UDim2.new(1, 16, 1, 10), Position = UDim2.fromOffset(-8, -5), BackgroundColor3 = C.Accent,
                        BackgroundTransparency = 0.7, BorderSizePixel = 0, ZIndex = 5, Parent = e.Row,
                    }, { corner(8) })
                    task.wait(0.5)
                    tween(hl, 0.8, { BackgroundTransparency = 1 })
                    task.wait(0.9)
                    hl:Destroy()
                end)
            end

            local function refresh()
                for _, c in ipairs(list:GetChildren()) do
                    if c:IsA("GuiObject") then c:Destroy() end
                end
                local q = string.lower((box.Text:gsub("^%s+", ""):gsub("%s+$", "")))
                if q == "" then results.Visible = false; current = {} return end
                local scored = {}
                for _, e in ipairs(index) do
                    local n = string.lower(e.Name)
                    local sc
                    if n == q then sc = 1
                    elseif n:sub(1, #q) == q then sc = 2
                    elseif n:find(q, 1, true) then sc = 3
                    elseif string.lower(e.Section):find(q, 1, true) then sc = 4
                    elseif string.lower(e.TabName):find(q, 1, true) then sc = 5
                    elseif e.Desc and string.lower(e.Desc):find(q, 1, true) then sc = 6 end
                    if sc then table.insert(scored, { e = e, sc = sc }) end
                end
                table.sort(scored, function(a, b) if a.sc ~= b.sc then return a.sc < b.sc end return a.e.Name < b.e.Name end)
                current = {}
                local shown = math.min(#scored, 40)
                for i = 1, shown do
                    local e = scored[i].e
                    current[i] = e
                    local b = new("TextButton", {
                        Size = UDim2.new(1, 0, 0, 36), BackgroundColor3 = C.TabOn, BackgroundTransparency = 1, Text = "", AutoButtonColor = false,
                        LayoutOrder = i, ZIndex = 42, Parent = list,
                    }, { corner(6) })
                    text(b, { Text = e.Name, TextSize = 13, Position = UDim2.fromOffset(10, 0), Size = UDim2.new(0.55, -10, 1, 0), TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd, ZIndex = 43 })
                    text(b, { Text = e.TabName .. " / " .. e.Section, TextSize = 12, TextColor3 = C.Muted, AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -10, 0, 0), Size = UDim2.new(0.45, -10, 1, 0), TextXAlignment = Enum.TextXAlignment.Right, TextTruncate = Enum.TextTruncate.AtEnd, ZIndex = 43 })
                    b.MouseEnter:Connect(function() b.BackgroundTransparency = 0 end)
                    b.MouseLeave:Connect(function() b.BackgroundTransparency = 1 end)
                    b.Activated:Connect(function() jump(e) end)
                end
                if shown == 0 then
                    text(list, { Text = "No matches", TextSize = 13, TextColor3 = C.Muted, Size = UDim2.new(1, 0, 0, 36), ZIndex = 42 })
                end
                results.Size = UDim2.fromOffset(420, math.min(math.max(shown, 1), 6) * 38 + 12)
                results.Visible = true
            end

            box:GetPropertyChangedSignal("Text"):Connect(refresh)
            box.Focused:Connect(function() box.UIStroke.Color = C.Accent; refresh() end)
            box.FocusLost:Connect(function(enter)
                box.UIStroke.Color = C.Stroke
                if enter and current[1] then jump(current[1]) end
            end)
        end

        -- minimize / close
        minB.MouseButton1Click:Connect(hideUI)
        closeB.MouseButton1Click:Connect(hideUI)


        -- ===== theme API + ready-made Theme tab =====
        function Window:SetTheme(n) return Lib:SetTheme(n) end
        function Window:SetAccent(c) return Lib:SetAccent(c) end
        function Window:ResetTheme() return Lib:ResetTheme() end
        function Window:GetTheme() return Lib:GetTheme() end

        function Window:CreateThemeTab(tabName)
            local Tab = Window:CreateTab({ Name = tabName or "Theme", Icon = "palette" })
            local function describe()
                local n, a = Lib:GetTheme()
                return "Active theme: " .. n .. (a and ("  (accent " .. Lib.ToHex(a) .. ")") or "")
            end

            -- left column: presets + reset
            Tab:CreateSection({ Name = "Themes", Column = "Left" })
            local status
            local accentBox
            local dd = Tab:CreateDropdown({
                Name = "Theme", Options = Lib:GetThemeNames(), CurrentValue = (Lib:GetTheme()),
                Callback = function(v)
                    if Lib:SetTheme(v) then
                        if accentBox then accentBox:Set("") end
                        if status then status:Set(describe()) end
                        Window:Notify({ title = "Theme", content = "Applied " .. tostring(v), duration = 2 })
                    end
                end,
            })
            status = Tab:CreateLabel({ Name = describe() })
            Tab:CreateButton({
                Name = "Reset Theme",
                Callback = function()
                    Lib:ResetTheme()
                    dd:Set("Default", true)
                    if accentBox then accentBox:Set("") end
                    status:Set(describe())
                    Window:Notify({ title = "Theme", content = "Reset to the default theme", duration = 2 })
                end,
            })

            -- right column: custom accent colour
            Tab:CreateSection({ Name = "Custom Accent", Column = "Right" })
            accentBox = Tab:CreateInput({
                Name = "Accent color (hex)", Placeholder = "#66AAFF", CurrentValue = "",
            })
            local function applyAccent(val)
                if Lib:SetAccent(val) then
                    status:Set(describe())
                    return true
                end
                Window:Notify({ title = "Theme", content = "Invalid hex color. Try something like #FF4466", duration = 3 })
                return false
            end
            Tab:CreateButtonRow({
                { Name = "Apply accent", Callback = function()
                    local v = accentBox:Get()
                    if (v:gsub("%s", "")) == "" then
                        Window:Notify({ title = "Theme", content = "Type a hex color first (e.g. #FF4466)", duration = 3 })
                        return
                    end
                    applyAccent(v)
                end },
                { Name = "Random", Style = "Secondary", Callback = function()
                    local c = Color3.fromHSV(math.random(), 0.55 + math.random() * 0.4, 1)
                    accentBox:Set(Lib.ToHex(c))
                    applyAccent(c)
                end },
            })
            Tab:CreateLabel({ Name = "Accent recolors buttons, sliders, toggles and highlights." })

            -- live preview so people can see what a theme does without leaving the tab
            Tab:CreateSection({ Name = "Preview", Column = "Left" })
            Tab:CreateToggle({ Name = "Preview toggle", Desc = "Just for showing the theme", CurrentValue = true })
            Tab:CreateSlider({ Name = "Preview slider", Range = { 0, 100 }, Increment = 1, CurrentValue = 60 })
            Tab:CreateButton({ Name = "Preview button", Style = "Secondary" })
            return Tab
        end

        return Window
    end

    return Lib
end)()




Airflow.Themes.FatalBlue = {
    Background  = Color3.fromRGB(5,   10,  22),
    Surface     = Color3.fromRGB(9,   16,  34),
    Surface2    = Color3.fromRGB(13,  22,  45),
    Surface3    = Color3.fromRGB(20,  32,  60),
    Stroke      = Color3.fromRGB(28,  45,  90),
    StrokeHover = Color3.fromRGB(55,  90, 180),
    Accent      = Color3.fromRGB(60,  120, 255),
    AccentDark  = Color3.fromRGB(8,   18,  50),
    Text        = Color3.fromRGB(220, 230, 255),
    Muted       = Color3.fromRGB(110, 140, 200),
    Glow        = Color3.fromRGB(60,  120, 255),
    Warning     = Color3.fromRGB(240, 176, 108),
    Success     = Color3.fromRGB(150, 220, 170),
    Error       = Color3.fromRGB(240, 120, 120),
}

Airflow.Assets.Logo = "rbxassetid://85087336560627"

-- ============================================================
-- GAME ID WHITELIST
-- ============================================================
local ARCADE_IDS = {
    [134558434771720] = true,
    [130736793665498] = true,
    [92216849541624]  = true,
    [95439417741900]  = true,
}

local BL_IDS = {
    [14386691987]    = true,
    [71832465156084] = true,
    [17652855195]    = true,
}

local isArcade = ARCADE_IDS[game.PlaceId] == true
local isBL     = BL_IDS[game.PlaceId] == true

-- ============================================================
-- SHARED THEME
-- ============================================================


-- ============================================================
-- SHARED SERVICES
-- ============================================================
local Players             = game:GetService("Players")
local RunService          = game:GetService("RunService")
local UserInputService    = game:GetService("UserInputService")
local ReplicatedStorage   = game:GetService("ReplicatedStorage")
local VirtualInput        = game:GetService("VirtualInputManager")
local SharedTableRegistry = game:GetService("SharedTableRegistry")
local CoreGui             = game:GetService("CoreGui")

local LocalPlayer = Players.LocalPlayer
local Camera      = workspace.CurrentCamera
local isMobile    = UserInputService.TouchEnabled

-- ============================================================
-- SHARED HVH ENGINE (HipHeight + Swim + Speed + InfJump)
-- ============================================================
local HVH = {
    active = false,
    conn = nil,
    swimEngaged = false,
    infJumpState = {
        conn = nil,
        charBind = nil,
    },
    cfg = nil,
}

local function getChar()
    local char = LocalPlayer.Character
    if not char then return nil, nil, nil end
    return char,
        char:FindFirstChild("Humanoid"),
        char:FindFirstChild("HumanoidRootPart")
end

-- One extra jump while airborne. Sets a fixed upward speed (a normal jump times the
-- Infinite Jump power) once, with a cooldown, so it can never build up or run away.
local function infJumpTry(hum, hrp, onlyWhenFalling)
    local cfg = HVH.cfg
    if not cfg or not cfg.InfiniteJump.Enabled then return end
    local now = os.clock()
    if now - (HVH.lastInfJump or 0) < 0.25 then return end
    -- Only a limited number of air jumps; landing resets the count.
    if (HVH.airJumps or 0) >= (cfg.InfiniteJump.Count or 2) then return end
    local st = hum:GetState()
    if st ~= Enum.HumanoidStateType.Freefall and st ~= Enum.HumanoidStateType.Jumping then
        return
    end
    local v = hrp.AssemblyLinearVelocity
    if onlyWhenFalling and v.Y > 0 then return end
    HVH.lastInfJump = now
    HVH.airJumps = (HVH.airJumps or 0) + 1
    local base = hum.UseJumpPower and hum.JumpPower
        or math.sqrt(2 * workspace.Gravity * hum.JumpHeight)
    local jumpSpeed = math.clamp(base * (cfg.InfiniteJump.Power or 1), 10, 120)
    hrp.AssemblyLinearVelocity = Vector3.new(v.X, jumpSpeed, v.Z)
end

local function hvhStart()
    if HVH.conn then HVH.conn:Disconnect(); HVH.conn = nil end
    if HVH.infJumpState.conn then HVH.infJumpState.conn:Disconnect(); HVH.infJumpState.conn = nil end
    if not HVH.cfg then return end

    -- Every jump press (space or the mobile jump button). On the ground this just
    -- starts the cooldown so the normal jump never double-fires; in the air it gives
    -- one extra jump per press.
    HVH.infJumpState.conn = UserInputService.JumpRequest:Connect(function()
        local cfg = HVH.cfg
        if not cfg or not cfg.InfiniteJump.Enabled then return end
        local _, hum, hrp = getChar()
        if not hum or not hrp then return end
        if hum.FloorMaterial ~= Enum.Material.Air then
            HVH.lastInfJump = os.clock()
            HVH.airJumps = 0
            return
        end
        infJumpTry(hum, hrp, false)
    end)

    HVH.active = true
    HVH.swimEngaged = false

    HVH.conn = RunService.Heartbeat:Connect(function()
        local cfg = HVH.cfg
        if not cfg then return end

        local char, hum, hrp = getChar()

        if cfg.HipHeight.Enabled and hum then
            if hum.HipHeight ~= cfg.HipHeight.Value then
                hum.HipHeight = cfg.HipHeight.Value
            end
        end

        if not hum then return end

        if cfg.Swim.Enabled then
            if hum.FloorMaterial ~= Enum.Material.Air then
                HVH.swimEngaged = false
            else
                local st = hum:GetState()
                if st ~= Enum.HumanoidStateType.Swimming then
                    hum:ChangeState(Enum.HumanoidStateType.Swimming)
                    if not HVH.swimEngaged and hrp then
                        local v = hrp.AssemblyLinearVelocity
                        hrp.AssemblyLinearVelocity = Vector3.new(v.X, 0, v.Z)
                        HVH.swimEngaged = true
                    end
                end
                if hrp then
                    local v = hrp.AssemblyLinearVelocity
                    local cap = 20 * (cfg.Swim.Power or 1)
                    if v.Y > cap then
                        hrp.AssemblyLinearVelocity = Vector3.new(v.X, cap, v.Z)
                    end
                end
            end
        else
            HVH.swimEngaged = false
        end

        -- Landing gives the air jumps back.
        if hum.FloorMaterial ~= Enum.Material.Air then HVH.airJumps = 0 end

        -- Double jump, hold-to-repeat (keyboard). Re-jumps only once you are
        -- already falling, and only up to the air jump limit.
        -- Taps (keyboard or mobile button) are handled by the JumpRequest hook above.
        if cfg.InfiniteJump.Enabled and hrp and not isMobile
            and UserInputService:IsKeyDown(Enum.KeyCode.Space) then
            infJumpTry(hum, hrp, true)
        end

        if cfg.Speed.Enabled and hrp and hum.MoveDirection.Magnitude > 0.05 then
            local mult = cfg.Speed.Multiplier or 1.35
            local targetVel = hum.MoveDirection.Unit * (16 * mult)
            local y = hrp.AssemblyLinearVelocity.Y
            hrp.AssemblyLinearVelocity = Vector3.new(targetVel.X, y, targetVel.Z)
        end
    end)
end

local function hvhStop()
    HVH.active = false
    if HVH.conn then HVH.conn:Disconnect(); HVH.conn = nil end
    if HVH.infJumpState.conn then HVH.infJumpState.conn:Disconnect(); HVH.infJumpState.conn = nil end
    HVH.swimEngaged = false
end

local function hvhResetAll()
    local cfg = HVH.cfg
    if not cfg then return end
    cfg.HipHeight.Enabled = false
    cfg.Swim.Enabled = false
    cfg.InfiniteJump.Enabled = false
    cfg.Speed.Enabled = false
    local char, hum = getChar()
    if hum then
        hum.HipHeight = cfg.HipHeight.Default
        if hum:GetState() == Enum.HumanoidStateType.Swimming then
            hum:ChangeState(Enum.HumanoidStateType.Running)
        end
    end
end

local function buildHVHTab(tab, cfg)
    tab:CreateSection("HipHeight")
    tab:CreateToggle({
        Name = "HipHeight changer",
        Desc = "Overrides your Humanoid.HipHeight each frame.",
        Flag = "hvh_hipheight",
        CurrentValue = cfg.HipHeight.Enabled,
        Callback = function(v) cfg.HipHeight.Enabled = v end,
    })
    tab:CreateSlider({
        Name = "HipHeight value",
        Range = { -5, 20 }, Increment = 0.5, Suffix = " studs",
        CurrentValue = cfg.HipHeight.Value, Flag = "hvh_hipheight_val",
        Callback = function(v)
            cfg.HipHeight.Value = v
            local _, hum = getChar()
            if hum and cfg.HipHeight.Enabled then hum.HipHeight = v end
        end,
    })

    tab:CreateSection("Swim")
    tab:CreateToggle({
        Name = "Swim",
        Desc = "Forces swimming while airborne. Velocity is clamped to prevent launch.",
        Flag = "hvh_swim",
        CurrentValue = cfg.Swim.Enabled,
        Callback = function(v) cfg.Swim.Enabled = v end,
    })
    tab:CreateSlider({
        Name = "Swim power",
        Desc = "Caps upward velocity while swimming (lower = less launch).",
        Range = { 0.1, 5 }, Increment = 0.1,
        CurrentValue = cfg.Swim.Power, Flag = "hvh_swim_power",
        Callback = function(v) cfg.Swim.Power = v end,
    })

    tab:CreateSection("Speed")
    tab:CreateToggle({
        Name = "Speed boost",
        Flag = "hvh_ws",
        CurrentValue = cfg.Speed.Enabled,
        Callback = function(v) cfg.Speed.Enabled = v end,
    })
    tab:CreateKeybind({
        Name = "Speed keybind",
        Flag = "hvh_ws_key",
        CurrentValue = cfg.Speed.Keybind,
        Callback = function(key)
            if typeof(key) == "EnumItem" then cfg.Speed.Keybind = key end
        end,
    })
    tab:CreateSlider({
        Name = "Speed multiplier",
        Range = { 1, 3 }, Increment = 0.05,
        CurrentValue = cfg.Speed.Multiplier, Flag = "hvh_ws_val",
        Callback = function(v) cfg.Speed.Multiplier = v end,
    })

    tab:CreateSection("Double Jump")
    tab:CreateToggle({
        Name = "Double jump",
        Desc = "Jump again in mid-air, up to the air jump limit. Landing resets it.",
        Flag = "hvh_infjump",
        CurrentValue = cfg.InfiniteJump.Enabled,
        Callback = function(v) cfg.InfiniteJump.Enabled = v end,
    })
    tab:CreateSlider({
        Name = "Air jumps",
        Desc = "How many extra jumps you get in the air before it stops (1 = classic double jump).",
        Range = { 1, 5 }, Increment = 1,
        CurrentValue = cfg.InfiniteJump.Count, Flag = "hvh_infjump_count",
        Callback = function(v) cfg.InfiniteJump.Count = v end,
    })
    tab:CreateSlider({
        Name = "Double jump strength",
        Desc = "Strength of each extra jump (1 = a normal jump).",
        Range = { 0.1, 5 }, Increment = 0.1,
        CurrentValue = cfg.InfiniteJump.Power, Flag = "hvh_infjump_power",
        Callback = function(v) cfg.InfiniteJump.Power = v end,
    })
end

-- ============================================================
-- BRANCH: ARCADE BASKETBALL
-- ============================================================
if isArcade then
    local Settings = {
        Shooting = {
            AutoGreen = false,
            AutoGreenKeybind = Enum.KeyCode.E,
            AutoGreenOnShootButton = true,
        },
        HVH = {
            HipHeight = { Enabled = false, Value = 0, Default = 0 },
            Swim = { Enabled = false, Power = 1 },
            Speed = { Enabled = false, Mult = 1.35, Keybind = Enum.KeyCode.RightShift },
            InfiniteJump = { Enabled = false, Power = 1, Count = 2 },
        },
        AntiContest = {
            Enabled = false,
            Keybind = Enum.KeyCode.E,
            Height = 25,
        },
        BallSize = {
            Enabled = false,
            Size = 6,
            Transparency = 0.5,
        },
    }
    local s = Settings
    HVH.cfg = s.HVH

    local Cleanup = { conns = {} }
    local function Track(c) if c then table.insert(Cleanup.conns, c) end return c end

    local ShootRemote = nil
    local function resolveShootRemote()
        if ShootRemote and ShootRemote.Parent then return ShootRemote end
        pcall(function()
            local Events = ReplicatedStorage:FindFirstChild("Events")
            ShootRemote = Events and Events:FindFirstChild("Shoot")
        end)
        return ShootRemote
    end

    local function fireAutoGreen()
        local remote = resolveShootRemote()
        if not remote then return false end
        local ok = pcall(function()
            remote:FireServer(true, 100, false)
        end)
        pcall(function()
            remote:FireServer(false, -1, true)
        end)
        return ok
    end

    local greenLock = false
    local function fireAutoGreenSafe()
        if greenLock then return end
        greenLock = true
        fireAutoGreen()
        task.delay(0.15, function() greenLock = false end)
    end

    local ballResizeConn = nil
    local trackedBalls = {}
    local origData     = {}

    local function isBallPart(inst)
        if not inst:IsA("BasePart") then return false end
        return string.lower(inst.Name):find("ball", 1, true) ~= nil
    end

    local function addTrackedBall(inst)
        if not isBallPart(inst) or trackedBalls[inst] then return end
        trackedBalls[inst] = true
        origData[inst] = { Size = inst.Size, Transparency = inst.Transparency }
        if s.BallSize.Enabled then
            local size = tonumber(s.BallSize.Size) or 6
            local trans = tonumber(s.BallSize.Transparency) or 0.5
            pcall(function()
                inst.Size = Vector3.new(size, size, size)
                inst.Transparency = trans
            end)
        end
    end

    local function removeTrackedBall(inst)
        trackedBalls[inst] = nil
        origData[inst] = nil
    end

    local function applyBallSize()
        local size = tonumber(s.BallSize.Size) or 6
        local trans = tonumber(s.BallSize.Transparency) or 0.5
        for part in pairs(trackedBalls) do
            if part.Parent then
                pcall(function()
                    part.Size = Vector3.new(size, size, size)
                    part.Transparency = trans
                end)
            else
                removeTrackedBall(part)
            end
        end
    end

    local function restoreBallSize()
        for part, data in pairs(origData) do
            if part.Parent then
                pcall(function()
                    part.Size = data.Size
                    part.Transparency = data.Transparency
                end)
            end
        end
        table.clear(origData)
        table.clear(trackedBalls)
    end

    local ballAddedConn, ballRemovedConn = nil, nil
    local function enableBallResizer()
        for _, inst in ipairs(workspace:GetDescendants()) do addTrackedBall(inst) end
        ballAddedConn = workspace.DescendantAdded:Connect(function(inst)
            if isBallPart(inst) then
                task.defer(function() addTrackedBall(inst) end)
            end
        end)
        ballRemovedConn = workspace.DescendantRemoving:Connect(function(inst)
            if isBallPart(inst) then removeTrackedBall(inst) end
        end)
        applyBallSize()
        if ballResizeConn then ballResizeConn:Disconnect() end
        ballResizeConn = RunService.Heartbeat:Connect(function()
            if s.BallSize.Enabled then applyBallSize() end
        end)
        Track(ballResizeConn)
    end

    local function disableBallResizer()
        if ballAddedConn then ballAddedConn:Disconnect(); ballAddedConn = nil end
        if ballRemovedConn then ballRemovedConn:Disconnect(); ballRemovedConn = nil end
        if ballResizeConn then ballResizeConn:Disconnect(); ballResizeConn = nil end
        restoreBallSize()
    end

    local antiContestLock = false
    local function doAntiContest()
        if antiContestLock then return end
        antiContestLock = true
        task.delay(0.1, function() antiContestLock = false end)
        local _, _, hrp = getChar()
        if not hrp then return end
        local height = tonumber(s.AntiContest.Height) or 25
        hrp.CFrame = hrp.CFrame + Vector3.new(0, height, 0)
    end

    local Window = Airflow:CreateWindow({Name = "Byte.WTF", LoadingSubtitle = "Byte On Top", Theme = "FatalBlue", ToggleUIKeybind = "RightControl", ConfigurationSaving = {Enabled = true, FolderName = "FatalLabs", FileName = "FatalLabs"}})

    local Notify = function(props) pcall(function() Window:Notify(props) end) end

    local CombatTab = Window:CreateTab({ Name = "Combat", Icon = "swords" })
    local BallTab = Window:CreateTab({ Name = "Ball", Icon = "circle" })
    local HVHTab = Window:CreateTab({ Name = "Movement", Icon = "activity" })
    pcall(function() Window:CreateThemeTab() end)

    CombatTab:CreateSection("Auto Green")
    CombatTab:CreateToggle({
        Name = "Auto Green",
        Desc = "Fires Events.Shoot with the perfect-shot sequence.",
        Flag = "ab_autogreen",
        CurrentValue = s.Shooting.AutoGreen,
        Callback = function(v) s.Shooting.AutoGreen = v end,
    })
    CombatTab:CreateKeybind({
        Name = "Auto Green keybind",
        Desc = "Hold then RELEASE this key to fire a green shot.",
        Flag = "ab_autogreen_key",
        CurrentValue = s.Shooting.AutoGreenKeybind,
        Callback = function(key)
            if typeof(key) == "EnumItem" then s.Shooting.AutoGreenKeybind = key end
        end,
    })
    CombatTab:CreateToggle({
        Name = "Auto Green on Shoot button",
        Desc = "Fires the remote INSTANTLY when you RELEASE the in-game Shoot button.",
        Flag = "ab_autogreen_btn",
        CurrentValue = s.Shooting.AutoGreenOnShootButton,
        Callback = function(v) s.Shooting.AutoGreenOnShootButton = v end,
    })
    CombatTab:CreateButton({
        Name = "Fire Green Now",
        Callback = function()
            if fireAutoGreen() then
                Notify({ title = "Auto Green", content = "Shot fired.", duration = 2 })
            else
                Notify({ title = "Auto Green", content = "Remote not found.", duration = 3 })
            end
        end,
    })

    CombatTab:CreateSection("Anti Contest")
    CombatTab:CreateToggle({
        Name = "Anti Contest",
        Desc = "Press E to teleport straight up (dodges contests).",
        Flag = "ab_ac",
        CurrentValue = s.AntiContest.Enabled,
        Callback = function(v) s.AntiContest.Enabled = v end,
    })
    CombatTab:CreateKeybind({
        Name = "Anti Contest keybind",
        Desc = "Press this key to jump straight up.",
        Flag = "ab_ac_key",
        CurrentValue = s.AntiContest.Keybind,
        Callback = function(key)
            if typeof(key) == "EnumItem" then s.AntiContest.Keybind = key end
        end,
    })
    CombatTab:CreateSlider({
        Name = "Anti Contest height",
        Range = { 1, 25 }, Increment = 1, Suffix = " studs",
        CurrentValue = s.AntiContest.Height, Flag = "ab_ac_h",
        Callback = function(v) s.AntiContest.Height = v end,
    })

    BallTab:CreateSection("Ball Resizer")
    BallTab:CreateToggle({
        Name = "Ball Resizer",
        Desc = "Scales every ball part and sets its transparency to 0.5.",
        Flag = "ab_ballsize",
        CurrentValue = s.BallSize.Enabled,
        Callback = function(v)
            s.BallSize.Enabled = v
            if v then enableBallResizer() else disableBallResizer() end
        end,
    })
    BallTab:CreateSlider({
        Name = "Ball size",
        Range = { 1, 12 }, Increment = 1, Suffix = " studs",
        CurrentValue = s.BallSize.Size, Flag = "ab_ballsize_val",
        Callback = function(v)
            s.BallSize.Size = v
            if s.BallSize.Enabled then applyBallSize() end
        end,
    })

    buildHVHTab(HVHTab, s.HVH)

    do
        local hookedButtons = {}
        local pressedButtons = {}

        local function matchesShoot(inst)
            if not (inst:IsA("GuiButton") or inst:IsA("ImageButton")) then return false end
            local n = string.lower(inst.Name)
            if n == "shoot" or n:find("shoot", 1, true) then return true end
            for _, d in ipairs(inst:GetDescendants()) do
                if d:IsA("TextLabel") or d:IsA("TextButton") or d:IsA("TextBox") then
                    if string.lower(d.Text or ""):find("shoot", 1, true) then return true end
                end
            end
            return false
        end

        local function onPress(inst)
            if not s.Shooting.AutoGreen then return end
            if not s.Shooting.AutoGreenOnShootButton then return end
            pressedButtons[inst] = true
        end

        local function onRelease(inst)
            if not s.Shooting.AutoGreen then return end
            if not s.Shooting.AutoGreenOnShootButton then return end
            if not pressedButtons[inst] then return end
            pressedButtons[inst] = nil
            fireAutoGreenSafe()
        end

        local function tryHook(inst)
            if hookedButtons[inst] then return end
            if not matchesShoot(inst) then return end
            hookedButtons[inst] = true
            Track(inst.MouseButton1Down:Connect(function() onPress(inst) end))
            Track(inst.MouseButton1Up:Connect(function() onRelease(inst) end))
            Track(inst.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.Touch
                    or input.UserInputType == Enum.UserInputType.MouseButton1 then
                    onPress(inst)
                end
            end))
            Track(inst.InputEnded:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.Touch
                    or input.UserInputType == Enum.UserInputType.MouseButton1 then
                    onRelease(inst)
                end
            end))
            Track(inst.MouseLeave:Connect(function()
                if pressedButtons[inst] then onRelease(inst) end
            end))
        end

        local function scanAndHook(root)
            if not root then return end
            for _, inst in ipairs(root:GetDescendants()) do tryHook(inst) end
        end

        local function watchRoot(root)
            if not root then return end
            Track(root.DescendantAdded:Connect(function(inst)
                task.wait(0.05)
                tryHook(inst)
            end))
        end

        local pg = LocalPlayer:FindFirstChild("PlayerGui")
        if pg then scanAndHook(pg); watchRoot(pg) end
        Track(LocalPlayer.ChildAdded:Connect(function(child)
            if child.Name == "PlayerGui" then
                task.wait(0.5)
                scanAndHook(child); watchRoot(child)
            end
        end))

        scanAndHook(workspace); watchRoot(workspace)
        Track(LocalPlayer.CharacterAdded:Connect(function(char)
            task.wait(0.5)
            scanAndHook(char); watchRoot(char)
        end))

        pcall(function()
            scanAndHook(CoreGui); watchRoot(CoreGui)
        end)
    end

    local eWasHeld = false

    UserInputService.InputBegan:Connect(function(input, gpe)
        if gpe then return end
        local hvhCfg = s.HVH

        local greenBind = s.Shooting.AutoGreenKeybind
        local greenKey = (type(greenBind) == "string") and Enum.KeyCode[greenBind] or greenBind
        if input.KeyCode == greenKey then
            if s.Shooting.AutoGreen then eWasHeld = true end
            if s.AntiContest.Enabled then
                local acBind = s.AntiContest.Keybind
                local acKey = (type(acBind) == "string") and Enum.KeyCode[acBind] or acBind
                if input.KeyCode == acKey then doAntiContest() end
            end
            return
        end

        local acBind = s.AntiContest.Keybind
        local acKey = (type(acBind) == "string") and Enum.KeyCode[acBind] or acBind
        if input.KeyCode == acKey and s.AntiContest.Enabled then
            doAntiContest(); return
        end

        local speedBind = hvhCfg.Speed.Keybind
        local speedKey = (type(speedBind) == "string") and Enum.KeyCode[speedBind] or speedBind
        if input.KeyCode == speedKey then
            hvhCfg.Speed.Enabled = not hvhCfg.Speed.Enabled
        end
    end)

    UserInputService.InputEnded:Connect(function(input, gpe)
        if gpe then return end
        local greenBind = s.Shooting.AutoGreenKeybind
        local greenKey = (type(greenBind) == "string") and Enum.KeyCode[greenBind] or greenBind
        if input.KeyCode == greenKey and eWasHeld then
            eWasHeld = false
            if s.Shooting.AutoGreen then fireAutoGreenSafe() end
        end
    end)

    hvhStart()

    local function cleanup()
        pcall(disableBallResizer)
        pcall(hvhResetAll)
        pcall(hvhStop)
        for _, c in Cleanup.conns do pcall(function() c:Disconnect() end) end
    end
    Track(LocalPlayer.AncestryChanged:Connect(function()
        if not LocalPlayer.Parent then cleanup() end
    end))

-- ============================================================
-- BRANCH: BASKETBALL LEGENDS
-- ============================================================
elseif isBL then
    local Settings = {
        Shooting = {
            AutoGreen = false,
            AutoGreenKeybind = Enum.KeyCode.E,
            AutoGreenOnJump = false,
            AutoGreenOnShootButton = true,
        },
        HVH = {
            HipHeight = { Enabled = false, Value = 0, Default = 0 },
            Swim = { Enabled = false, Power = 1 },
            Speed = { Enabled = false, Mult = 1.35, Keybind = Enum.KeyCode.RightShift },
            InfiniteJump = { Enabled = false, Power = 1, Count = 2 },
        },
        Mag = {
            Enabled = false,
            BallName = "Ball",
            Reach = 20,
            Keybind = Enum.KeyCode.L,
        },
    }
    local s = Settings
    HVH.cfg = s.HVH

    local Cleanup = { conns = {} }
    local function Track(c) if c then table.insert(Cleanup.conns, c) end return c end

    local ShootRemote = nil
    local function resolveShootRemote()
        if ShootRemote and ShootRemote.Parent then return ShootRemote end
        pcall(function()
            local Packages = ReplicatedStorage:FindFirstChild("Packages")
            local Knit = Packages and Packages:FindFirstChild("Knit")
            local Services = Knit and Knit:FindFirstChild("Services")
            local ControlService = Services and Services:FindFirstChild("ControlService")
            local RE = ControlService and ControlService:FindFirstChild("RE")
            ShootRemote = RE and RE:FindFirstChild("Shoot")
        end)
        return ShootRemote
    end

    local function fireAutoGreen()
        local remote = resolveShootRemote()
        if not remote then return false end
        return pcall(function() remote:FireServer(1) end)
    end

    local greenLock = false
    local function fireAutoGreenSafe()
        if greenLock then return end
        greenLock = true
        fireAutoGreen()
        task.delay(0.15, function() greenLock = false end)
    end

    local magConnection = nil
    local magRefreshThread = nil
    local magCache = {}

    local function rebuildMagCache()
        table.clear(magCache)
        local targetName = s.Mag.BallName
        for _, inst in ipairs(workspace:GetDescendants()) do
            if inst:IsA("BasePart") and inst.Name == targetName then
                if inst:FindFirstChildWhichIsA("TouchTransmitter")
                    or inst:FindFirstChild("TouchInterest") then
                    magCache[#magCache + 1] = inst
                end
            end
        end
    end

    local function magTick()
        if not s.Mag.Enabled then return end
        local character, _, touchPart = getChar()
        if not character or not touchPart then return end
        if character:FindFirstChild("Basketball") then return end
        local reach = tonumber(s.Mag.Reach) or 20
        local reachSq = reach * reach
        local origin = touchPart.Position
        for i = #magCache, 1, -1 do
            local part = magCache[i]
            if not part or not part.Parent then
                table.remove(magCache, i)
            else
                local d = origin - part.Position
                if (d.X*d.X + d.Y*d.Y + d.Z*d.Z) <= reachSq then
                    pcall(function()
                        firetouchinterest(touchPart, part, 0)
                        firetouchinterest(touchPart, part, 1)
                    end)
                    if not part.Anchored then
                        part.AssemblyLinearVelocity = (touchPart.Position - part.Position) * 30
                    end
                end
            end
        end
    end

    local function enableMag()
        if magConnection then magConnection:Disconnect(); magConnection = nil end
        if magRefreshThread then task.cancel(magRefreshThread); magRefreshThread = nil end
        rebuildMagCache()
        magRefreshThread = task.spawn(function()
            while s.Mag.Enabled do
                task.wait(0.5)
                if s.Mag.Enabled then rebuildMagCache() end
            end
        end)
        magConnection = RunService.Heartbeat:Connect(function() pcall(magTick) end)
        Track(magConnection)
    end

    local function disableMag()
        if magConnection then magConnection:Disconnect(); magConnection = nil end
        if magRefreshThread then task.cancel(magRefreshThread); magRefreshThread = nil end
        table.clear(magCache)
    end

    local Window = Airflow:CreateWindow({Name = "Byte.WTF", LoadingSubtitle = "Byte On Top", Theme = "FatalBlue", ToggleUIKeybind = "RightControl", ConfigurationSaving = {Enabled = true, FolderName = "Byte.WTF", FileName = "Byte.WTF"}})

    local Notify = function(props) pcall(function() Window:Notify(props) end) end

    local CombatTab = Window:CreateTab({ Name = "Main", Icon = "swords" })
    local BallTab = Window:CreateTab({ Name = "Ball", Icon = "circle" })
    local HVHTab = Window:CreateTab({ Name = "HVH", Icon = "activity" })

    CombatTab:CreateSection("Auto Green")
    CombatTab:CreateToggle({
        Name = "Auto Green",
        Desc = "Fires ControlService.RE.Shoot with argument 1 (perfect shot).",
        Flag = "bl_autogreen",
        CurrentValue = s.Shooting.AutoGreen,
        Callback = function(v) s.Shooting.AutoGreen = v end,
    })
    CombatTab:CreateKeybind({
        Name = "Auto Green keybind",
        Desc = "Hold then RELEASE this key to fire a green shot.",
        Flag = "bl_autogreen_key",
        CurrentValue = s.Shooting.AutoGreenKeybind,
        Callback = function(key)
            if typeof(key) == "EnumItem" then s.Shooting.AutoGreenKeybind = key end
        end,
    })
    CombatTab:CreateToggle({
        Name = "Auto Green on Jump",
        Desc = "Fires the remote automatically after you jump-shot.",
        Flag = "bl_autogreen_jump",
        CurrentValue = s.Shooting.AutoGreenOnJump,
        Callback = function(v) s.Shooting.AutoGreenOnJump = v end,
    })
    CombatTab:CreateToggle({
        Name = "Auto Green on Shoot button",
        Desc = "Fires the remote INSTANTLY when you RELEASE the in-game Shoot button.",
        Flag = "bl_autogreen_btn",
        CurrentValue = s.Shooting.AutoGreenOnShootButton,
        Callback = function(v) s.Shooting.AutoGreenOnShootButton = v end,
    })
    CombatTab:CreateButton({
        Name = "Fire Green Now",
        Callback = function()
            if fireAutoGreen() then
                Notify({ title = "Auto Green", content = "Shot fired.", duration = 2 })
            else
                Notify({ title = "Auto Green", content = "Remote not found.", duration = 3 })
            end
        end,
    })

    BallTab:CreateSection("Mag")
    BallTab:CreateToggle({
        Name = "Mag",
        Desc = "Fast cached magnet. Auto firetouchinterest on nearby balls.",
        Flag = "bl_mag",
        CurrentValue = s.Mag.Enabled,
        Callback = function(v)
            s.Mag.Enabled = v
            if v then enableMag() else disableMag() end
        end,
    })
    BallTab:CreateKeybind({
        Name = "Mag keybind",
        Desc = "Press this key to toggle Mag on/off.",
        Flag = "bl_mag_key",
        CurrentValue = s.Mag.Keybind,
        Callback = function(key)
            if typeof(key) == "EnumItem" then s.Mag.Keybind = key end
        end,
    })
    BallTab:CreateInput({
        Name = "Ball name",
        Desc = "Name of the part to magnet (default: Ball).",
        Placeholder = "Ball",
        CurrentValue = s.Mag.BallName,
        Flag = "bl_mag_name",
        Callback = function(text)
            if text ~= "" then
                s.Mag.BallName = text
                if s.Mag.Enabled then rebuildMagCache() end
            end
        end,
    })
    BallTab:CreateSlider({
        Name = "Reach (studs)",
        Range = { 1, 100 }, Increment = 1,
        CurrentValue = s.Mag.Reach, Flag = "bl_mag_reach",
        Callback = function(v) s.Mag.Reach = v end,
    })

    buildHVHTab(HVHTab, s.HVH)

    local function setupAutoGreenChar(char)
        local hum = char:WaitForChild("Humanoid", 5)
        if not hum then return end
        Track(hum.Jumping:Connect(function(active)
            if not active then return end
            if not s.Shooting.AutoGreen or not s.Shooting.AutoGreenOnJump then return end
            if not char:FindFirstChild("Basketball") then return end
            fireAutoGreenSafe()
        end))
    end
    if LocalPlayer.Character then setupAutoGreenChar(LocalPlayer.Character) end
    Track(LocalPlayer.CharacterAdded:Connect(setupAutoGreenChar))

    do
        local hookedButtons = {}
        local pressedButtons = {}

        local function matchesShoot(inst)
            if not (inst:IsA("GuiButton") or inst:IsA("ImageButton")) then return false end
            local n = string.lower(inst.Name)
            if n == "shoot" or n:find("shoot", 1, true) then return true end
            for _, d in ipairs(inst:GetDescendants()) do
                if d:IsA("TextLabel") or d:IsA("TextButton") or d:IsA("TextBox") then
                    if string.lower(d.Text or ""):find("shoot", 1, true) then return true end
                end
            end
            return false
        end

        local function onPress(inst)
            if not s.Shooting.AutoGreen or not s.Shooting.AutoGreenOnShootButton then return end
            pressedButtons[inst] = true
        end

        local function onRelease(inst)
            if not s.Shooting.AutoGreen or not s.Shooting.AutoGreenOnShootButton then return end
            if not pressedButtons[inst] then return end
            pressedButtons[inst] = nil
            fireAutoGreenSafe()
        end

        local function tryHook(inst)
            if hookedButtons[inst] or not matchesShoot(inst) then return end
            hookedButtons[inst] = true
            Track(inst.MouseButton1Down:Connect(function() onPress(inst) end))
            Track(inst.MouseButton1Up:Connect(function() onRelease(inst) end))
            Track(inst.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.Touch
                    or input.UserInputType == Enum.UserInputType.MouseButton1 then
                    onPress(inst)
                end
            end))
            Track(inst.InputEnded:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.Touch
                    or input.UserInputType == Enum.UserInputType.MouseButton1 then
                    onRelease(inst)
                end
            end))
            Track(inst.MouseLeave:Connect(function()
                if pressedButtons[inst] then onRelease(inst) end
            end))
        end

        local function scanAndHook(root)
            if not root then return end
            for _, inst in ipairs(root:GetDescendants()) do tryHook(inst) end
        end

        local function watchRoot(root)
            if not root then return end
            Track(root.DescendantAdded:Connect(function(inst)
                task.wait(0.05)
                tryHook(inst)
            end))
        end

        local pg = LocalPlayer:FindFirstChild("PlayerGui")
        if pg then scanAndHook(pg); watchRoot(pg) end
        Track(LocalPlayer.ChildAdded:Connect(function(child)
            if child.Name == "PlayerGui" then
                task.wait(0.5)
                scanAndHook(child); watchRoot(child)
            end
        end))

        scanAndHook(workspace); watchRoot(workspace)
        Track(LocalPlayer.CharacterAdded:Connect(function(char)
            task.wait(0.5)
            scanAndHook(char); watchRoot(char)
        end))

        pcall(function()
            scanAndHook(CoreGui); watchRoot(CoreGui)
        end)
    end

    local eWasHeld = false

    Track(UserInputService.InputBegan:Connect(function(input, gpe)
        if gpe then return end
        local greenBind = s.Shooting.AutoGreenKeybind
        local greenKey = (type(greenBind) == "string") and Enum.KeyCode[greenBind] or greenBind
        if input.KeyCode == greenKey then
            if s.Shooting.AutoGreen then eWasHeld = true end
            return
        end

        local magBind = s.Mag.Keybind
        local magKey = (type(magBind) == "string") and Enum.KeyCode[magBind] or magBind
        if input.KeyCode == magKey then
            s.Mag.Enabled = not s.Mag.Enabled
            if s.Mag.Enabled then enableMag() else disableMag() end
            return
        end

        local speedBind = s.HVH.Speed.Keybind
        local speedKey = (type(speedBind) == "string") and Enum.KeyCode[speedBind] or speedBind
        if input.KeyCode == speedKey then
            s.HVH.Speed.Enabled = not s.HVH.Speed.Enabled
        end
    end))

    Track(UserInputService.InputEnded:Connect(function(input, gpe)
        if gpe then return end
        local greenBind = s.Shooting.AutoGreenKeybind
        local greenKey = (type(greenBind) == "string") and Enum.KeyCode[greenBind] or greenBind
        if input.KeyCode == greenKey and eWasHeld then
            eWasHeld = false
            if s.Shooting.AutoGreen then fireAutoGreenSafe() end
        end
    end))

    hvhStart()

    local function cleanup()
        pcall(disableMag)
        pcall(hvhResetAll)
        pcall(hvhStop)
        for _, c in Cleanup.conns do pcall(function() c:Disconnect() end) end
    end
    Track(LocalPlayer.AncestryChanged:Connect(function()
        if not LocalPlayer.Parent then cleanup() end
    end))

end
