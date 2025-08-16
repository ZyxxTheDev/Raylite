--// Raylite UI Library — a lightweight, Studio‑safe take on Rayfield
--// Single ModuleScript file. Drop into ReplicatedStorage (or anywhere) and require it from a LocalScript.
--// API sketch (Rayfield‑inspired):
--// local ui = Raylite:CreateWindow({ Name = "My Hub", Theme = "Dark" })
--// local tab = ui:CreateTab("Main")
--// local sec = tab:AddSection("Controls")
--// sec:AddButton({Text="Click Me", Callback=function() print("clicked") end})
--// local t = sec:AddToggle({Text="God Mode", Default=false, Callback=function(v) print("toggle:", v) end})
--// local s = sec:AddSlider({Text="Speed", Min=0, Max=100, Default=16, Callback=function(v) print(v) end})
--// local d = sec:AddDropdown({Text="Weapon", Options={"Sword","Bow","Wand"}, Default="Sword", Callback=function(v) print(v) end})
--// ui:Notify({Title="Loaded", Text="Raylite initialised"})

local Raylite = {}
Raylite.__index = Raylite

--// Utilities
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

local function new(inst, props)
	local o = Instance.new(inst)
	if props then
		for k,v in pairs(props) do
			o[k] = v
		end
	end
	return o
end

local function tw(obj, ti, props)
	return TweenService:Create(obj, TweenInfo.new(ti, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), props)
end

local THEMES = {
	Dark = {
		Primary = Color3.fromRGB(18,18,20),
		Panel   = Color3.fromRGB(26,26,30),
		Accent  = Color3.fromRGB(98,114,164),
		Stroke  = Color3.fromRGB(60,60,66),
		Text    = Color3.fromRGB(235,235,243),
		Subtext = Color3.fromRGB(180,180,190),
		Hover   = Color3.fromRGB(35,35,42),
	},
	Light = {
		Primary = Color3.fromRGB(246,247,250),
		Panel   = Color3.fromRGB(255,255,255),
		Accent  = Color3.fromRGB(52,120,246),
		Stroke  = Color3.fromRGB(220,225,235),
		Text    = Color3.fromRGB(20,22,26),
		Subtext = Color3.fromRGB(90,96,106),
		Hover   = Color3.fromRGB(240,243,248),
	}
}

--// Base window
function Raylite:CreateWindow(cfg)
	cfg = cfg or {}
	local theme = THEMES[cfg.Theme] or THEMES.Dark

	local playerGui = Players.LocalPlayer:FindFirstChildOfClass("PlayerGui")
	local screenGui = new("ScreenGui", {Name = cfg.Name or "Raylite", ResetOnSpawn=false, ZIndexBehavior=Enum.ZIndexBehavior.Sibling})
	screenGui.Parent = playerGui

	local root = new("Frame", {Name="Root", Parent=screenGui, BackgroundColor3=theme.Primary, Size=UDim2.fromOffset(620, 430), Position=UDim2.fromScale(0.5,0.5), AnchorPoint=Vector2.new(0.5,0.5)})
	new("UICorner", {CornerRadius=UDim.new(0,14), Parent=root})
	new("UIStroke", {Color=theme.Stroke, Thickness=1, Transparency=0.2, Parent=root})

	-- draggable
	local dragging, dragStart, startPos
	root.InputBegan:Connect(function(i)
		if i.UserInputType == Enum.UserInputType.MouseButton1 then dragging = true; dragStart = i.Position; startPos = root.Position end
	end)
	root.InputEnded:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end end)
	UserInputService.InputChanged:Connect(function(i)
		if dragging and i.UserInputType == Enum.UserInputType.MouseMovement then
			local delta = i.Position - dragStart
			root.Position = UDim2.fromOffset(startPos.X.Offset + delta.X, startPos.Y.Offset + delta.Y)
		end
	end)

	local header = new("Frame", {Parent=root, BackgroundTransparency=1, Size=UDim2.fromOffset(root.Size.X.Offset, 50)})
	local title = new("TextLabel", {Parent=header, BackgroundTransparency=1, Text=cfg.Name or "Raylite", Font=Enum.Font.GothamSemibold, TextSize=18, TextColor3=theme.Text, Position=UDim2.fromOffset(16,12), Size=UDim2.fromOffset(400,26), TextXAlignment=Enum.TextXAlignment.Left})

	local tabbar = new("Frame", {Parent=root, BackgroundTransparency=1, Position=UDim2.fromOffset(14, 56), Size=UDim2.new(1,-28, 0, 32)})
	local tablist = new("UIListLayout", {Parent=tabbar, FillDirection=Enum.FillDirection.Horizontal, Padding=UDim.new(0,8), SortOrder=Enum.SortOrder.LayoutOrder, VerticalAlignment=Enum.VerticalAlignment.Center})

	local body = new("Frame", {Parent=root, BackgroundTransparency=1, Position=UDim2.fromOffset(14, 96), Size=UDim2.new(1,-28, 1,-110)})

	local notifHolder = new("Frame", {Parent=screenGui, BackgroundTransparency=1, Size=UDim2.fromScale(1,1)})

	-- public window object
	local win = setmetatable({
		_theme = theme,
		_root = root,
		_tabbar = tabbar,
		_body = body,
		_tabs = {},
		_notifyRoot = notifHolder,
	}, Raylite)

	-- methods
	function win:CreateTab(name)
		name = name or "Tab"
		local tabBtn = new("TextButton", {Parent=self._tabbar, Text=name, AutoButtonColor=false, Font=Enum.Font.Gotham, TextSize=14, TextColor3=self._theme.Subtext, BackgroundColor3=self._theme.Panel, Size=UDim2.fromOffset(110, 32)})
		new("UICorner", {CornerRadius=UDim.new(0,10), Parent=tabBtn})
		new("UIStroke", {Color=self._theme.Stroke, Thickness=1, Transparency=0.3, Parent=tabBtn})
		local hover = tw(tabBtn, 0.15, {BackgroundColor3 = self._theme.Hover})
		local unhover = tw(tabBtn, 0.15, {BackgroundColor3 = self._theme.Panel})
		tabBtn.MouseEnter:Connect(function() hover:Play() end)
		tabBtn.MouseLeave:Connect(function() unhover:Play() end)

		local page = new("ScrollingFrame", {Parent=self._body, CanvasSize=UDim2.new(0,0,0,0), AutomaticCanvasSize=Enum.AutomaticSize.Y, BorderSizePixel=0, BackgroundTransparency=1, Size=UDim2.fromScale(1,1), Visible=false})
		new("UIListLayout", {Parent=page, Padding=UDim.new(0,12), SortOrder=Enum.SortOrder.LayoutOrder})

		local tabObj = {
			_parent = self,
			_btn = tabBtn,
			_page = page,
			_sections = {},
		}

		function tabObj:Show()
			for _,t in pairs(self._parent._tabs) do t._page.Visible = false; t._btn.TextColor3 = self._parent._theme.Subtext end
			self._page.Visible = true
			self._btn.TextColor3 = self._parent._theme.Text
		end
		tabBtn.MouseButton1Click:Connect(function() tabObj:Show() end)

		function tabObj:AddSection(title)
			title = title or "Section"
			local section = new("Frame", {Parent=self._page, BackgroundColor3=self._parent._theme.Panel, Size=UDim2.new(1,0, 0, 70), AutomaticSize=Enum.AutomaticSize.Y})
			new("UICorner", {CornerRadius=UDim.new(0,10), Parent=section})
			new("UIStroke", {Color=self._parent._theme.Stroke, Transparency=0.3, Parent=section})
			local pad = new("UIPadding", {Parent=section, PaddingTop=UDim.new(0,10), PaddingBottom=UDim.new(0,10), PaddingLeft=UDim.new(0,10), PaddingRight=UDim.new(0,10)})
			local sTitle = new("TextLabel", {Parent=section, BackgroundTransparency=1, Text=title, Font=Enum.Font.GothamSemibold, TextColor3=self._parent._theme.Text, TextSize=16, Size=UDim2.new(1,0,0,20), TextXAlignment=Enum.TextXAlignment.Left})
			local list = new("UIListLayout", {Parent=section, Padding=UDim.new(0,8), SortOrder=Enum.SortOrder.LayoutOrder})

			local secObj = { _section = section, _parentTab = self }

			local function controlRow(height)
				local row = new("Frame", {Parent=section, BackgroundTransparency=1, Size=UDim2.new(1,0,0,height)})
				return row
			end

			function secObj:AddLabel(text)
				local row = controlRow(22)
				new("TextLabel", {Parent=row, BackgroundTransparency=1, Text=text or "Label", Font=Enum.Font.Gotham, TextSize=14, TextColor3=self._parentTab._parent._theme.Subtext, Size=UDim2.new(1,0,1,0), TextXAlignment=Enum.TextXAlignment.Left})
				return {
					Set = function(_, t) row:FindFirstChildOfClass("TextLabel").Text = t end
				}
			end

			function secObj:AddButton(cfg)
				cfg = cfg or {}
				local row = controlRow(34)
				local btn = new("TextButton", {Parent=row, Text=cfg.Text or "Button", AutoButtonColor=false, Font=Enum.Font.Gotham, TextSize=14, TextColor3=self._parentTab._parent._theme.Text, BackgroundColor3=self._parentTab._parent._theme.Accent, Size=UDim2.fromOffset(120, 28)})
				new("UICorner", {CornerRadius=UDim.new(0,8), Parent=btn})
				btn.MouseButton1Click:Connect(function()
					if typeof(cfg.Callback) == "function" then cfg.Callback() end
				end)
				return {Click = function() btn:Activate() end, SetText=function(_,t) btn.Text=t end}
			end

			function secObj:AddToggle(cfg)
				cfg = cfg or {}
				local value = cfg.Default or false
				local row = controlRow(28)
				local box = new("TextButton", {Parent=row, AutoButtonColor=false, BackgroundColor3=self._parentTab._parent._theme.Panel, Size=UDim2.fromOffset(24, 24), Text=""})
				new("UICorner", {CornerRadius=UDim.new(0,6), Parent=box})
				new("UIStroke", {Color=self._parentTab._parent._theme.Stroke, Transparency=0.3, Parent=box})
				local label = new("TextLabel", {Parent=row, BackgroundTransparency=1, Text=cfg.Text or "Toggle", Font=Enum.Font.Gotham, TextSize=14, TextColor3=self._parentTab._parent._theme.Text, Position=UDim2.fromOffset(32,0), Size=UDim2.new(1,-32,1,0), TextXAlignment=Enum.TextXAlignment.Left})
				local check = new("Frame", {Parent=box, BackgroundColor3=self._parentTab._parent._theme.Accent, Size=UDim2.fromScale(0,1)})
				new("UICorner", {CornerRadius=UDim.new(0,6), Parent=check})
				local function apply(v)
					value = v
					tw(check, 0.15, {Size = UDim2.fromScale(v and 1 or 0, 1)}):Play()
					if typeof(cfg.Callback) == "function" then cfg.Callback(value) end
				end
				box.MouseButton1Click:Connect(function() apply(not value) end)
				apply(value)
				return { Set=function(_,v) apply(v) end, Get=function() return value end }
			end

			function secObj:AddSlider(cfg)
				cfg = cfg or {}
				local min, max = cfg.Min or 0, cfg.Max or 100
				local value = math.clamp(cfg.Default or min, min, max)
				local row = controlRow(40)
				local label = new("TextLabel", {Parent=row, BackgroundTransparency=1, Text=(cfg.Text or "Slider") .. ": " .. tostring(value), Font=Enum.Font.Gotham, TextSize=14, TextColor3=self._parentTab._parent._theme.Text, Size=UDim2.new(1,0,0,16), TextXAlignment=Enum.TextXAlignment.Left})
				local bar = new("Frame", {Parent=row, BackgroundColor3=self._parentTab._parent._theme.Panel, Size=UDim2.new(1,0,0,10), Position=UDim2.fromOffset(0,22)})
				new("UICorner", {CornerRadius=UDim.new(0,6), Parent=bar})
				new("UIStroke", {Color=self._parentTab._parent._theme.Stroke, Transparency=0.3, Parent=bar})
				local fill = new("Frame", {Parent=bar, BackgroundColor3=self._parentTab._parent._theme.Accent, Size=UDim2.fromScale((value-min)/(max-min),1)})
				new("UICorner", {CornerRadius=UDim.new(0,6), Parent=fill})
				local dragging = false
				bar.InputBegan:Connect(function(i)
					if i.UserInputType == Enum.UserInputType.MouseButton1 then dragging = true end
				end)
				UserInputService.InputEnded:Connect(function(i)
					if i.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
				end)
				UserInputService.InputChanged:Connect(function(i)
					if dragging and i.UserInputType == Enum.UserInputType.MouseMovement then
						local rel = math.clamp((i.Position.X - bar.AbsolutePosition.X)/bar.AbsoluteSize.X, 0, 1)
						value = math.floor(min + (max-min)*rel + 0.5)
						fill.Size = UDim2.fromScale((value-min)/(max-min),1)
						label.Text = (cfg.Text or "Slider") .. ": " .. tostring(value)
						if typeof(cfg.Callback) == "function" then cfg.Callback(value) end
					end
				end)
				return { Set=function(_,v) value=math.clamp(v,min,max); fill.Size=UDim2.fromScale((value-min)/(max-min),1); label.Text=(cfg.Text or "Slider")..": "..tostring(value); if typeof(cfg.Callback)=="function" then cfg.Callback(value) end end, Get=function() return value end }
			end

			function secObj:AddDropdown(cfg)
				cfg = cfg or {}
				local options = cfg.Options or {}
				local value = cfg.Default or options[1]
				local row = controlRow(34)
				local btn = new("TextButton", {Parent=row, AutoButtonColor=false, BackgroundColor3=self._parentTab._parent._theme.Panel, Size=UDim2.new(0,220,0,28), Text = tostring(value or "Select"), Font=Enum.Font.Gotham, TextSize=14, TextColor3=self._parentTab._parent._theme.Text})
				new("UICorner", {CornerRadius=UDim.new(0,8), Parent=btn})
				new("UIStroke", {Color=self._parentTab._parent._theme.Stroke, Transparency=0.3, Parent=btn})
				local open = false
				local listFrame = new("Frame", {Parent=row, BackgroundColor3=self._parentTab._parent._theme.Panel, Size=UDim2.new(0,220,0,0), ClipsDescendants=true})
				new("UICorner", {CornerRadius=UDim.new(0,8), Parent=listFrame})
				local layo = new("UIListLayout", {Parent=listFrame, SortOrder=Enum.SortOrder.LayoutOrder})
				local function set(v)
					value = v; btn.Text = tostring(v)
					if typeof(cfg.Callback) == "function" then cfg.Callback(v) end
				end
				local function toggleList(state)
					open = state
					tw(listFrame, 0.2, {Size = UDim2.new(0,220,0, state and math.min(#options*28, 140) or 0)}):Play()
				end
				btn.MouseButton1Click:Connect(function() toggleList(not open) end)
				for _,opt in ipairs(options) do
					local o = new("TextButton", {Parent=listFrame, AutoButtonColor=true, Text=tostring(opt), BackgroundTransparency=1, Size=UDim2.new(1,0,0,28), Font=Enum.Font.Gotham, TextSize=14, TextColor3=self._parentTab._parent._theme.Subtext})
					o.MouseButton1Click:Connect(function() set(opt); toggleList(false) end)
				end
				set(value)
				return { Set=function(_,v) set(v) end, Get=function() return value end, SetOptions=function(_,opts) options=opts or {}; for _,c in ipairs(listFrame:GetChildren()) do if c:IsA("TextButton") then c:Destroy() end end; for _,opt in ipairs(options) do local o = new("TextButton", {Parent=listFrame, AutoButtonColor=true, Text=tostring(opt), BackgroundTransparency=1, Size=UDim2.new(1,0,0,28), Font=Enum.Font.Gotham, TextSize=14, TextColor3=self._parentTab._parent._theme.Subtext}); o.MouseButton1Click:Connect(function() set(opt); toggleList(false) end) end end }
			end

			return secObj
		end

		-- auto‑select first tab
		if #self._tabs == 0 then tabObj:Show() end
		table.insert(self._tabs, tabObj)
		return tabObj
	end

	function win:Notify(data)
		data = data or {}
		local card = new("Frame", {Parent=self._notifyRoot, BackgroundColor3=self._theme.Panel, Size=UDim2.fromOffset(260, 68), Position=UDim2.fromScale(1,1), AnchorPoint=Vector2.new(1,1)})
		new("UICorner", {CornerRadius=UDim.new(0,12), Parent=card})
		new("UIStroke", {Color=self._theme.Stroke, Transparency=0.3, Parent=card})
		local pad = new("UIPadding", {Parent=card, PaddingTop=UDim.new(0,10), PaddingBottom=UDim.new(0,10), PaddingLeft=UDim.new(0,12), PaddingRight=UDim.new(0,12)})
		local title = new("TextLabel", {Parent=card, BackgroundTransparency=1, Text=data.Title or "Notice", Font=Enum.Font.GothamSemibold, TextSize=15, TextColor3=self._theme.Text, Size=UDim2.new(1,0,0,18), TextXAlignment=Enum.TextXAlignment.Left})
		local text = new("TextLabel", {Parent=card, BackgroundTransparency=1, Text=data.Text or "", Font=Enum.Font.Gotham, TextSize=14, TextColor3=self._theme.Subtext, Size=UDim2.new(1,0,1,-18), Position=UDim2.fromOffset(0,18), TextWrapped=true, TextXAlignment=Enum.TextXAlignment.Left})
		card.Position = UDim2.fromOffset(card.AbsoluteSize.X + 20, card.AbsolutePosition.Y)
		tw(card, 0.25, {Position = UDim2.fromScale(1,-0.02)}):Play()
		task.delay(data.Duration or 2.5, function()
			tw(card, 0.25, {Position = UDim2.fromOffset(card.AbsoluteSize.X + 20, card.AbsolutePosition.Y)}):Play()
			wait(0.26)
			card:Destroy()
		end)
	end

	function win:Destroy()
		self._root:Destroy()
		self._notifyRoot:Destroy()
	end

	return win
end

return setmetatable({}, Raylite)
