-- Raylite UI Library — Enhanced edition
-- Single ModuleScript. Require from a LocalScript.
-- API:
-- local ui = Raylite:CreateWindow({ Name = "My Hub", Theme = "Dark" })
-- local tab = ui:CreateTab("Main")
-- local sec = tab:AddSection("Controls")
-- sec:AddButton({Text="Click Me", Callback=function() print("clicked") end})
-- sec:AddToggle({Text="God Mode", Default=false, Callback=function(v) print("toggle:", v) end})
-- sec:AddSlider({Text="Speed", Min=0, Max=100, Default=16, Callback=function(v) print(v) end})
-- sec:AddDropdown({Text="Weapon", Options={"Sword","Bow","Wand"}, Default="Sword", Callback=function(v) print(v) end})
-- sec:AddTextBox({Text="Name", Placeholder="Type name", Callback=function(v) print(v) end})
-- sec:AddKeybind({Text="Open Menu", Default=Enum.KeyCode.RightControl, Callback=function() print("key pressed") end})
-- sec:AddColorPicker({Text="Accent", Default=Color3.fromRGB(98,114,164), Callback=function(c) print(c) end})
-- ui:Notify({Title="Loaded", Text="Raylite initialized"})

local Raylite = {}
Raylite.__index = Raylite

-- Services
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService") -- only for small serialisation if needed

local LocalPlayer = Players.LocalPlayer

-- Helpers
local function new(inst, props)
	local o = Instance.new(inst)
	if props then
		for k, v in pairs(props) do
			pcall(function() o[k] = v end)
		end
	end
	return o
end

local function tw(obj, ti, props, style, dir)
	style = style or Enum.EasingStyle.Quad
	dir = dir or Enum.EasingDirection.Out
	return TweenService:Create(obj, TweenInfo.new(ti, style, dir), props)
end

local THEMES = {
	Dark = {
		Primary = Color3.fromRGB(18,18,20),
		Panel   = Color3.fromRGB(28,28,32),
		Accent  = Color3.fromRGB(98,114,164),
		Stroke  = Color3.fromRGB(60,60,66),
		Text    = Color3.fromRGB(235,235,243),
		Subtext = Color3.fromRGB(180,180,190),
		Hover   = Color3.fromRGB(36,36,42),
		BgFade  = Color3.fromRGB(0,0,0),
	},
	Light = {
		Primary = Color3.fromRGB(246,247,250),
		Panel   = Color3.fromRGB(255,255,255),
		Accent  = Color3.fromRGB(52,120,246),
		Stroke  = Color3.fromRGB(220,225,235),
		Text    = Color3.fromRGB(20,22,26),
		Subtext = Color3.fromRGB(90,96,106),
		Hover   = Color3.fromRGB(240,243,248),
		BgFade  = Color3.fromRGB(255,255,255),
	}
}

-- Utility: safe connect that returns disconnect func
local function connect(event, fn)
	local c = event:Connect(fn)
	return function() if c and c.Connected then c:Disconnect() end end
end

-- Main: Create Window
function Raylite:CreateWindow(cfg)
	cfg = cfg or {}
	local themeName = cfg.Theme or "Dark"
	local theme = THEMES[themeName] or THEMES.Dark

	-- ScreenGui parent
	local playerGui = LocalPlayer:FindFirstChildOfClass("PlayerGui") or LocalPlayer:WaitForChild("PlayerGui")
	local screenGui = new("ScreenGui", {
		Name = cfg.Name or "Raylite",
		ResetOnSpawn = false,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
	})
	screenGui.Parent = playerGui

	-- Tooltip (global)
	local tooltip = new("TextLabel", {
		Name = "RayliteTooltip",
		Parent = screenGui,
		BackgroundColor3 = theme.Panel,
		BackgroundTransparency = 0.05,
		Size = UDim2.new(0,200,0,28),
		Visible = false,
		Font = Enum.Font.Gotham,
		TextSize = 13,
		TextColor3 = theme.Text,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextWrapped = true,
	})
	new("UICorner", {Parent = tooltip, CornerRadius = UDim.new(0,6)})
	new("UIStroke", {Parent = tooltip, Color = theme.Stroke, Transparency = 0.5})

	-- root window
	local root = new("Frame", {
		Name = "Root",
		Parent = screenGui,
		BackgroundColor3 = theme.Primary,
		Size = UDim2.fromOffset(720, 480),
		Position = UDim2.fromScale(0.5,0.5),
		AnchorPoint = Vector2.new(0.5,0.5),
	})
	new("UICorner", {CornerRadius = UDim.new(0,14), Parent = root})
	new("UIStroke", {Color = theme.Stroke, Thickness = 1, Transparency = 0.18, Parent = root})

	-- header
	local header = new("Frame", {Parent = root, BackgroundTransparency = 1, Size = UDim2.new(1,0,0,56)})
	local title = new("TextLabel", {
		Parent = header,
		BackgroundTransparency = 1,
		Text = cfg.Name or "Raylite",
		Font = Enum.Font.GothamSemibold,
		TextSize = 20,
		TextColor3 = theme.Text,
		Position = UDim2.new(0,16,0,12),
		Size = UDim2.new(0.6, -16, 0, 32),
		TextXAlignment = Enum.TextXAlignment.Left,
	})
	-- right controls (search, theme switch, minimize, close)
	local controlHolder = new("Frame", {Parent = header, BackgroundTransparency = 1, Size = UDim2.new(0.4, -16, 1, 0), Position = UDim2.new(0.6, 8, 0, 0)})
	local controlLayout = new("UIListLayout", {Parent = controlHolder, FillDirection = Enum.FillDirection.Horizontal, HorizontalAlignment = Enum.HorizontalAlignment.Right, Padding = UDim.new(0,8)})
	controlLayout.SortOrder = Enum.SortOrder.LayoutOrder

	-- Search box
	local searchBox = new("TextBox", {
		Parent = controlHolder,
		Size = UDim2.fromOffset(180, 28),
		BackgroundColor3 = theme.Panel,
		PlaceholderText = "Search controls...",
		Font = Enum.Font.Gotham,
		TextSize = 14,
		TextColor3 = theme.Text,
		Text = "",
		ClearTextOnFocus = false,
	})
	new("UICorner", {Parent = searchBox, CornerRadius = UDim.new(0,8)})
	new("UIStroke", {Parent = searchBox, Color = theme.Stroke, Transparency = 0.3})

	-- Theme toggle
	local themeBtn = new("TextButton", {
		Parent = controlHolder,
		Text = (themeName == "Dark") and "🌙" or "☀️",
		AutoButtonColor = false,
		Size = UDim2.fromOffset(40,28),
		Font = Enum.Font.Gotham,
		TextSize = 14,
		BackgroundColor3 = theme.Panel,
		TextColor3 = theme.Text,
	})
	new("UICorner", {Parent = themeBtn, CornerRadius = UDim.new(0,8)})
	new("UIStroke", {Parent = themeBtn, Color = theme.Stroke, Transparency = 0.3})

	-- Minimize and Close
	local minBtn = new("TextButton", {
		Parent = controlHolder, Text = "—", Size = UDim2.fromOffset(36,28), AutoButtonColor = false, Font = Enum.Font.GothamSemibold, TextSize = 18, BackgroundColor3 = theme.Panel, TextColor3 = theme.Text
	})
	new("UICorner", {Parent = minBtn, CornerRadius = UDim.new(0,8)})
	new("UIStroke", {Parent = minBtn, Color = theme.Stroke, Transparency = 0.3})

	local closeBtn = new("TextButton", {
		Parent = controlHolder, Text = "✕", Size = UDim2.fromOffset(36,28), AutoButtonColor = false, Font = Enum.Font.GothamSemibold, TextSize = 16, BackgroundColor3 = theme.Panel, TextColor3 = theme.Text
	})
	new("UICorner", {Parent = closeBtn, CornerRadius = UDim.new(0,8)})
	new("UIStroke", {Parent = closeBtn, Color = theme.Stroke, Transparency = 0.3})

	-- tabbar
	local tabbar = new("Frame", {Parent = root, BackgroundTransparency = 1, Position = UDim2.fromOffset(16, 66), Size = UDim2.new(1,-32,0,40)})
	new("UIListLayout", {Parent = tabbar, FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0,8), SortOrder = Enum.SortOrder.LayoutOrder, VerticalAlignment = Enum.VerticalAlignment.Center})

	-- body
	local body = new("Frame", {Parent = root, BackgroundTransparency = 1, Position = UDim2.fromOffset(16, 112), Size = UDim2.new(1,-32,1,-140)})
	local bodyPadding = new("UIPadding", {Parent = body, PaddingTop = UDim.new(0,4), PaddingBottom = UDim.new(0,6), PaddingLeft = UDim.new(0,6), PaddingRight = UDim.new(0,6)})

	-- notification area
	local notifRoot = new("Frame", {Parent = screenGui, BackgroundTransparency = 1, Size = UDim2.fromScale(1,1)})
	notifRoot.ZIndex = 50

	-- resize grip
	local grip = new("Frame", {Parent = root, Size = UDim2.fromOffset(14,14), Position = UDim2.new(1,-16,1,-16), BackgroundTransparency = 1, AnchorPoint = Vector2.new(0,0)})
	new("UICorner", {Parent = grip, CornerRadius = UDim.new(0,3)})

	-- Store window state
	local win = setmetatable({
		_theme = theme,
		_themeName = themeName,
		_root = root,
		_tabbar = tabbar,
		_body = body,
		_tabs = {},
		_notifyRoot = notifRoot,
		_searchBox = searchBox,
		_tooltip = tooltip,
	}, Raylite)

	-- Internal helpers: theme apply
	function win:SetTheme(name)
		local t = THEMES[name] or THEMES.Dark
		self._theme = t
		self._themeName = name
		-- update main palette
		root.BackgroundColor3 = t.Primary
		tooltip.BackgroundColor3 = t.Panel
		tooltip.TextColor3 = t.Text
		for _, v in ipairs(root:GetDescendants()) do
			if v:IsA("TextLabel") or v:IsA("TextBox") or v:IsA("TextButton") then
				if v.TextColor3 == self._theme.Text then v.TextColor3 = t.Text end
				if v.TextColor3 == self._theme.Subtext then v.TextColor3 = t.Subtext end
				if v.BackgroundColor3 == self._theme.Panel then v.BackgroundColor3 = t.Panel end
				if v.BackgroundColor3 == self._theme.Accent then v.BackgroundColor3 = t.Accent end
				if v.BackgroundColor3 == self._theme.Hover then v.BackgroundColor3 = t.Hover end
			elseif v:IsA("Frame") then
				if v.BackgroundColor3 == self._theme.Primary then v.BackgroundColor3 = t.Primary end
				if v.BackgroundColor3 == self._theme.Panel then v.BackgroundColor3 = t.Panel end
				if v.BackgroundColor3 == self._theme.Accent then v.BackgroundColor3 = t.Accent end
				if v.BackgroundColor3 == self._theme.Hover then v.BackgroundColor3 = t.Hover end
			elseif v:IsA("UIStroke") then
				if v.Color == self._theme.Stroke then v.Color = t.Stroke end
			end
		end
		for _, notif in ipairs(notifRoot:GetChildren()) do
			if notif:IsA("Frame") then
				notif.BackgroundColor3 = t.Panel
				for _, child in ipairs(notif:GetDescendants()) do
					if child:IsA("TextLabel") then
						child.TextColor3 = t.Text
					elseif child:IsA("UIStroke") then
						child.Color = t.Stroke
					end
				end
			end
		end
		-- update header icons
		themeBtn.Text = (name == "Dark") and "🌙" or "☀️"
	end

	-- Tooltip helper
	local tooltipHideTick = 0
	local function showTooltip(text, elem)
		if not text or text == "" then tooltip.Visible = false; return end
		tooltip.Text = "  " .. text
		tooltip.Visible = true
		-- position near mouse
		local pos = UserInputService:GetMouseLocation()
		tooltip.Position = UDim2.fromOffset(pos.X + 16, pos.Y + 16)
		tooltipHideTick = tick() + 5
	end

	-- Close and Minimize handlers
	local minimized = false
	minBtn.MouseButton1Click:Connect(function()
		minimized = not minimized
		body.Visible = not minimized
		tabbar.Visible = not minimized
		if minimized then
			tw(root, 0.2, {Size = UDim2.fromOffset(root.AbsoluteSize.X, 64)}):Play()
		else
			tw(root, 0.2, {Size = UDim2.fromOffset(720, 480)}):Play()
		end
	end)
	closeBtn.MouseButton1Click:Connect(function()
		win:Destroy()
	end)

	-- Theme toggle
	themeBtn.MouseButton1Click:Connect(function()
		local newName = (win._themeName == "Dark") and "Light" or "Dark"
		win:SetTheme(newName)
	end)

	-- Draggable window (header area)
	do
		local dragging, dragStart, startPos
		header.InputBegan:Connect(function(i)
			if i.UserInputType == Enum.UserInputType.MouseButton1 then
				dragging = true
				dragStart = i.Position
				startPos = root.Position
			end
		end)
		header.InputEnded:Connect(function(i)
			if i.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
		end)
		UserInputService.InputChanged:Connect(function(i)
			if dragging and i.UserInputType == Enum.UserInputType.MouseMovement then
				local delta = i.Position - dragStart
				root.Position = UDim2.fromOffset(startPos.X.Offset + delta.X, startPos.Y.Offset + delta.Y)
			end
		end)
	end

	-- Resizing (grip)
	do
		local resizing = false
		local startSize, startMouse
		grip.MouseEnter:Connect(function() grip.BackgroundTransparency = 0.9; grip.BackgroundColor3 = win._theme.Hover end)
		grip.MouseLeave:Connect(function() grip.BackgroundTransparency = 1 end)
		grip.InputBegan:Connect(function(i)
			if i.UserInputType == Enum.UserInputType.MouseButton1 then
				resizing = true
				startSize = root.Size
				startMouse = i.Position
			end
		end)
		UserInputService.InputEnded:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 then resizing = false end end)
		UserInputService.InputChanged:Connect(function(i)
			if resizing and i.UserInputType == Enum.UserInputType.MouseMovement then
				local delta = i.Position - startMouse
				local newW = math.max(420, startSize.X.Offset + delta.X)
				local newH = math.max(220, startSize.Y.Offset + delta.Y)
				root.Size = UDim2.fromOffset(newW, newH)
			end
		end)
	end

	-- Notifications with stacking
	function win:Notify(data)
		data = data or {}
		local card = new("Frame", {Parent = self._notifyRoot, BackgroundColor3 = self._theme.Panel, Size = UDim2.fromOffset(300, 74), AnchorPoint = Vector2.new(1,1)})
		new("UICorner", {Parent = card, CornerRadius = UDim.new(0,12)})
		new("UIStroke", {Parent = card, Color = self._theme.Stroke, Transparency = 0.3})
		card.ZIndex = 60
		local pad = new("UIPadding", {Parent = card, PaddingTop = UDim.new(0,10), PaddingLeft = UDim.new(0,12), PaddingRight = UDim.new(0,12)})
		local title = new("TextLabel", {Parent = card, BackgroundTransparency = 1, Text = data.Title or "Notice", Font = Enum.Font.GothamSemibold, TextSize = 15, TextColor3 = self._theme.Text, Size = UDim2.new(1,0,0,18), TextXAlignment = Enum.TextXAlignment.Left})
		local text = new("TextLabel", {Parent = card, BackgroundTransparency = 1, Text = data.Text or "", Font = Enum.Font.Gotham, TextSize = 14, TextColor3 = self._theme.Subtext, Position = UDim2.fromOffset(0,20), Size = UDim2.new(1,0,1,-20), TextWrapped = true, TextXAlignment = Enum.TextXAlignment.Left})
		
		-- Stack notifications upwards from bottom right
		local notifs = {}
		for _, child in ipairs(self._notifyRoot:GetChildren()) do
			if child:IsA("Frame") and child ~= card then
				table.insert(notifs, child)
			end
		end
		table.sort(notifs, function(a, b) return a.AbsolutePosition.Y > b.AbsolutePosition.Y end)
		local yOffset = -20  -- Start below the screen edge
		for _, n in ipairs(notifs) do
			yOffset = yOffset - n.AbsoluteSize.Y - 8
		end
		card.Position = UDim2.new(1, 20, 1, yOffset)
		tw(card, 0.28, {Position = UDim2.new(0.98, 0, 1, yOffset + 20)}):Play()  -- Slight inset
		
		task.delay(data.Duration or 3, function()
			if card and card.Parent then
				tw(card, 0.22, {Position = UDim2.new(1, 20, card.Position.Y.Scale, card.Position.Y.Offset)}):Play()
				task.wait(0.26)
				pcall(function() card:Destroy() end)
			end
		end)
		return card
	end

	-- Search/filter: filters visible controls in active tab by label text
	do
		local function filterControls(txt)
			txt = (txt or ""):lower()
			-- find active tab
			for _, t in ipairs(win._tabs) do
				if t._page.Visible then
					for _, section in ipairs(t._sections) do
						local anyVisible = false
						for _, child in ipairs(section._content:GetChildren()) do
							if child:IsA("Frame") then
								-- check descendants for text labels
								local matched = false
								for _, d in ipairs(child:GetDescendants()) do
									if d:IsA("TextLabel") or d:IsA("TextButton") or d:IsA("TextBox") then
										local s = (d.Text or ""):lower()
										if s:find(txt, 1, true) then matched = true; break end
									end
								end
								child.Visible = matched or txt == ""
								if child.Visible then anyVisible = true end
							end
						end
						-- show/hide content based on visible children
						section._content.Visible = anyVisible or txt == ""
						section._section.Size = UDim2.new(1, -12, 0, section._titleRow.AbsoluteSize.Y + (section._content.Visible and section._content.AbsoluteSize.Y or 0) + 22)
					end
				end
			end
		end
		searchBox:GetPropertyChangedSignal("Text"):Connect(function()
			local txt = searchBox.Text
			filterControls(txt)
		end)
	end

	-- Tab creation
	function win:CreateTab(name, icon)
		name = name or "Tab"
		local tabBtn = new("TextButton", {Parent = self._tabbar, Text = name, AutoButtonColor = false, Font = Enum.Font.Gotham, TextSize = 14, TextColor3 = self._theme.Subtext, BackgroundColor3 = self._theme.Panel, Size = UDim2.fromOffset(120, 34)})
		new("UICorner", {CornerRadius = UDim.new(0,10), Parent = tabBtn})
		new("UIStroke", {Color = self._theme.Stroke, Transparency = 0.3, Parent = tabBtn})
		local hover = tw(tabBtn, 0.12, {BackgroundColor3 = self._theme.Hover})
		local unhover = tw(tabBtn, 0.12, {BackgroundColor3 = self._theme.Panel})
		tabBtn.MouseEnter:Connect(function() hover:Play() end)
		tabBtn.MouseLeave:Connect(function() unhover:Play() end)

		local page = new("ScrollingFrame", {Parent = self._body, CanvasSize = UDim2.new(0,0,0,0), AutomaticCanvasSize = Enum.AutomaticSize.Y, BorderSizePixel = 0, BackgroundTransparency = 1, Size = UDim2.fromScale(1,1), Visible = false, ScrollBarThickness = 6})
		local listLayout = new("UIListLayout", {Parent = page, Padding = UDim.new(0,12), SortOrder = Enum.SortOrder.LayoutOrder})
		listLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left
		page:GetPropertyChangedSignal("CanvasSize"):Connect(function() end)

		local tabObj = {
			_parent = self,
			_btn = tabBtn,
			_page = page,
			_sections = {},
		}

		function tabObj:Show()
			for _, t in pairs(self._parent._tabs) do
				t._page.Visible = false
				t._btn.TextColor3 = self._parent._theme.Subtext
			end
			self._page.Visible = true
			self._btn.TextColor3 = self._parent._theme.Text
		end

		tabBtn.MouseButton1Click:Connect(function() tabObj:Show() end)

		-- Section creator
		function tabObj:AddSection(title)
			title = title or "Section"
			local section = new("Frame", {Parent = self._page, BackgroundColor3 = self._parent._theme.Panel, Size = UDim2.new(1, -12, 0, 60), AutomaticSize = Enum.AutomaticSize.Y})
			section.Name = "SectionPanel"
			new("UICorner", {CornerRadius = UDim.new(0,10), Parent = section})
			new("UIStroke", {Color = self._parent._theme.Stroke, Transparency = 0.3, Parent = section})
			local pad = new("UIPadding", {Parent = section, PaddingTop = UDim.new(0,10), PaddingBottom = UDim.new(0,12), PaddingLeft = UDim.new(0,10), PaddingRight = UDim.new(0,10)})

			-- title row with collapse arrow
			local titleRow = new("Frame", {Parent = section, BackgroundTransparency = 1, Size = UDim2.new(1,0,0,22)})
			local titleLabel = new("TextLabel", {Parent = titleRow, BackgroundTransparency = 1, Text = title, Font = Enum.Font.GothamSemibold, TextSize = 16, TextColor3 = self._parent._theme.Text, Size = UDim2.new(1, -28, 1, 0), TextXAlignment = Enum.TextXAlignment.Left})
			local collapseBtn = new("TextButton", {Parent = titleRow, Text = "▾", Size = UDim2.new(0,24,0,20), Position = UDim2.new(1,-24,0,0), AutoButtonColor = false, Font = Enum.Font.GothamBold, TextSize = 14, TextColor3 = self._parent._theme.Subtext, BackgroundTransparency = 1})
			new("UICorner", {Parent = collapseBtn, CornerRadius = UDim.new(0,6)})

			local content = new("Frame", {Parent = section, BackgroundTransparency = 1, Size = UDim2.new(1,0,0,0), AutomaticSize = Enum.AutomaticSize.Y, Position = UDim2.new(0,0,0,22)})
			new("UIListLayout", {Parent = content, Padding = UDim.new(0,8), SortOrder = Enum.SortOrder.LayoutOrder})

			local secObj = { _section = section, _content = content, _parentTab = self, _titleLabel = titleLabel, _titleRow = titleRow }

			-- collapse behavior
			local collapsed = false
			collapseBtn.MouseButton1Click:Connect(function()
				collapsed = not collapsed
				collapseBtn.Text = collapsed and "▸" or "▾"
				content.Visible = not collapsed
			end)

			-- small helper to add control rows
			local function controlRow(h)
				local row = new("Frame", {Parent = content, BackgroundTransparency = 1, Size = UDim2.new(1,0,0,h or 28)})
				return row
			end

			-- Controls implementation

			function secObj:AddLabel(text)
				local row = controlRow(22)
				local lbl = new("TextLabel", {Parent = row, BackgroundTransparency = 1, Text = text or "Label", Font = Enum.Font.Gotham, TextSize = 14, TextColor3 = self._parentTab._parent._theme.Subtext, Size = UDim2.new(1,0,1,0), TextXAlignment = Enum.TextXAlignment.Left})
				return {
					Set = function(_, t) lbl.Text = t end
				}
			end

			function secObj:AddButton(cfg)
				cfg = cfg or {}
				local row = controlRow(36)
				local btn = new("TextButton", {Parent = row, Text = cfg.Text or "Button", AutoButtonColor = false, Font = Enum.Font.Gotham, TextSize = 14, TextColor3 = self._parentTab._parent._theme.Text, BackgroundColor3 = self._parentTab._parent._theme.Accent, Size = UDim2.fromOffset(140, 32)})
				new("UICorner", {Parent = btn, CornerRadius = UDim.new(0,8)})
				local hoverIn = tw(btn, 0.12, {BackgroundColor3 = self._parentTab._parent._theme.Accent:Lerp(Color3.new(1,1,1), 0.1)})
				local hoverOut = tw(btn, 0.12, {BackgroundColor3 = self._parentTab._parent._theme.Accent})
				btn.MouseEnter:Connect(function() hoverIn:Play() end)
				btn.MouseLeave:Connect(function() hoverOut:Play() end)
				btn.MouseButton1Click:Connect(function()
					if typeof(cfg.Callback) == "function" then
						task.spawn(cfg.Callback)
					end
				end)
				btn.MouseEnter:Connect(function() showTooltip(cfg.Tooltip) end)
				btn.MouseLeave:Connect(function() showTooltip("") end)
				return {Click = function() btn:Activate() end, SetText = function(_, t) btn.Text = t end}
			end

			function secObj:AddToggle(cfg)
				cfg = cfg or {}
				local value = cfg.Default or false
				local row = controlRow(28)
				local box = new("TextButton", {Parent = row, AutoButtonColor = false, BackgroundColor3 = self._parentTab._parent._theme.Panel, Size = UDim2.fromOffset(26, 22), Text = ""})
				new("UICorner", {Parent = box, CornerRadius = UDim.new(0,6)})
				new("UIStroke", {Parent = box, Color = self._parentTab._parent._theme.Stroke, Transparency = 0.3})
				local label = new("TextLabel", {Parent = row, BackgroundTransparency = 1, Text = cfg.Text or "Toggle", Font = Enum.Font.Gotham, TextSize = 14, TextColor3 = self._parentTab._parent._theme.Text, Position = UDim2.fromOffset(32,0), Size = UDim2.new(1,-32,1,0), TextXAlignment = Enum.TextXAlignment.Left})
				local check = new("Frame", {Parent = box, BackgroundColor3 = self._parentTab._parent._theme.Accent, Size = UDim2.fromScale(value and 1 or 0,1)})
				new("UICorner", {Parent = check, CornerRadius = UDim.new(0,6)})
				local function apply(v)
					value = v
					tw(check, 0.15, {Size = UDim2.fromScale(v and 1 or 0, 1)}):Play()
					if typeof(cfg.Callback) == "function" then task.spawn(cfg.Callback, value) end
				end
				box.MouseButton1Click:Connect(function() apply(not value) end)
				box.MouseEnter:Connect(function() showTooltip(cfg.Tooltip) end)
				box.MouseLeave:Connect(function() showTooltip("") end)
				apply(value)
				return { Set = function(_, v) apply(v) end, Get = function() return value end }
			end

			function secObj:AddSlider(cfg)
				cfg = cfg or {}
				local min, max = cfg.Min or 0, cfg.Max or 100
				local value = math.clamp(cfg.Default or min, min, max)
				local row = controlRow(44)
				local label = new("TextLabel", {Parent = row, BackgroundTransparency = 1, Text = (cfg.Text or "Slider") .. ": " .. tostring(value), Font = Enum.Font.Gotham, TextSize = 14, TextColor3 = self._parentTab._parent._theme.Text, Size = UDim2.new(1,0,0,16), TextXAlignment = Enum.TextXAlignment.Left})
				local bar = new("Frame", {Parent = row, BackgroundColor3 = self._parentTab._parent._theme.Panel, Size = UDim2.new(1,0,0,10), Position = UDim2.fromOffset(0,24)})
				new("UICorner", {Parent = bar, CornerRadius = UDim.new(0,6)})
				new("UIStroke", {Parent = bar, Color = self._parentTab._parent._theme.Stroke, Transparency = 0.3})
				local fill = new("Frame", {Parent = bar, BackgroundColor3 = self._parentTab._parent._theme.Accent, Size = UDim2.fromScale((value-min)/(max-min),1)})
				new("UICorner", {Parent = fill, CornerRadius = UDim.new(0,6)})
				local dragging = false
				bar.InputBegan:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 then dragging = true end end)
				UserInputService.InputEnded:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end end)
				local conn = UserInputService.InputChanged:Connect(function(i)
					if dragging and i.UserInputType == Enum.UserInputType.MouseMovement then
						local rel = math.clamp((i.Position.X - bar.AbsolutePosition.X)/bar.AbsoluteSize.X, 0, 1)
						value = math.floor(min + (max-min)*rel + 0.5)
						fill.Size = UDim2.fromScale((value-min)/(max-min),1)
						label.Text = (cfg.Text or "Slider") .. ": " .. tostring(value)
						if typeof(cfg.Callback) == "function" then task.spawn(cfg.Callback, value) end
					end
				end)
				row.Destroying:Connect(function() if conn and conn.Connected then conn:Disconnect() end end)
				bar.MouseEnter:Connect(function() showTooltip(cfg.Tooltip) end)
				bar.MouseLeave:Connect(function() showTooltip("") end)
				return {
					Set = function(_, v) value = math.clamp(v, min, max); fill.Size = UDim2.fromScale((value-min)/(max-min),1); label.Text = (cfg.Text or "Slider") .. ": " .. tostring(value); if typeof(cfg.Callback) == "function" then task.spawn(cfg.Callback, value) end end,
					Get = function() return value end
				}
			end

			function secObj:AddDropdown(cfg)
				cfg = cfg or {}
				local options = cfg.Options or {}
				local value = cfg.Default or options[1]
				local row = controlRow(34)
				local btn = new("TextButton", {Parent = row, AutoButtonColor = false, BackgroundColor3 = self._parentTab._parent._theme.Panel, Size = UDim2.new(1,0,0,28), Text = tostring(value or "Select"), Font = Enum.Font.Gotham, TextSize = 14, TextColor3 = self._parentTab._parent._theme.Text})
				new("UICorner", {Parent = btn, CornerRadius = UDim.new(0,8)})
				new("UIStroke", {Parent = btn, Color = self._parentTab._parent._theme.Stroke, Transparency = 0.3})
				local open = false
				local listFrame = new("Frame", {Parent = row, BackgroundColor3 = self._parentTab._parent._theme.Panel, Size = UDim2.new(1,0,0,0), Position = UDim2.new(0,0,0,30), ClipsDescendants = true})
				new("UICorner", {Parent = listFrame, CornerRadius = UDim.new(0,8)})
				new("UIStroke", {Parent = listFrame, Color = self._parentTab._parent._theme.Stroke, Transparency = 0.3})
				local scroller = new("ScrollingFrame", {Parent = listFrame, BackgroundTransparency = 1, Size = UDim2.fromScale(1,1), CanvasSize = UDim2.new(0,0,0,0), AutomaticCanvasSize = Enum.AutomaticSize.Y, ScrollBarThickness = 4})
				local layo = new("UIListLayout", {Parent = scroller, SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0,2)})
				local function set(v)
					value = v; btn.Text = tostring(v)
					if typeof(cfg.Callback) == "function" then task.spawn(cfg.Callback, v) end
				end
				local function toggleList(state)
					open = state
					tw(listFrame, 0.18, {Size = UDim2.new(1,0,0, state and math.min(#options*30, 180) or 0)}):Play()
				end
				btn.MouseButton1Click:Connect(function() toggleList(not open) end)
				local function rebuildOptions()
					for _, c in ipairs(scroller:GetChildren()) do if c:IsA("TextButton") then c:Destroy() end end
					for _, opt in ipairs(options) do
						local o = new("TextButton", {Parent = scroller, AutoButtonColor = true, Text = tostring(opt), BackgroundTransparency = 1, Size = UDim2.new(1,0,0,30), Font = Enum.Font.Gotham, TextSize = 14, TextColor3 = self._parentTab._parent._theme.Subtext})
						o.MouseButton1Click:Connect(function() set(opt); toggleList(false) end)
					end
				end
				rebuildOptions()
				set(value)
				btn.MouseEnter:Connect(function() showTooltip(cfg.Tooltip) end)
				btn.MouseLeave:Connect(function() showTooltip("") end)
				return {
					Set = function(_, v) set(v) end,
					Get = function() return value end,
					SetOptions = function(_, opts) options = opts or {}; rebuildOptions() end
				}
			end

			function secObj:AddTextBox(cfg)
				cfg = cfg or {}
				local row = controlRow(36)
				local box = new("TextBox", {Parent = row, BackgroundColor3 = self._parentTab._parent._theme.Panel, Size = UDim2.new(1,0,0,28), Text = "", PlaceholderText = cfg.Placeholder or "", Font = Enum.Font.Gotham, TextSize = 14, TextColor3 = self._parentTab._parent._theme.Text})
				new("UICorner", {Parent = box, CornerRadius = UDim.new(0,8)})
				new("UIStroke", {Parent = box, Color = self._parentTab._parent._theme.Stroke, Transparency = 0.3})
				box.FocusLost:Connect(function(enter)
					if enter and typeof(cfg.Callback) == "function" then
						task.spawn(cfg.Callback, box.Text)
					end
				end)
				box.MouseEnter:Connect(function() showTooltip(cfg.Tooltip) end)
				box.MouseLeave:Connect(function() showTooltip("") end)
				return { Get = function() return box.Text end, Set = function(_,v) box.Text = tostring(v) end }
			end

			function secObj:AddKeybind(cfg)
				cfg = cfg or {}
				local key = cfg.Default or Enum.KeyCode.Unknown
				local row = controlRow(32)
				local label = new("TextLabel", {Parent = row, BackgroundTransparency = 1, Text = cfg.Text or "Keybind", Font = Enum.Font.Gotham, TextSize = 14, TextColor3 = self._parentTab._parent._theme.Text, Size = UDim2.new(1,-100,1,0), TextXAlignment = Enum.TextXAlignment.Left})
				local btn = new("TextButton", {Parent = row, Text = key.Name ~= "Unknown" and key.Name or "Unbound", AutoButtonColor = false, Size = UDim2.new(0,88,0,26), BackgroundColor3 = self._parentTab._parent._theme.Panel, Font = Enum.Font.Gotham, TextSize = 13, TextColor3 = self._parentTab._parent._theme.Text})
				new("UICorner", {Parent = btn, CornerRadius = UDim.new(0,6)})
				new("UIStroke", {Parent = btn, Color = self._parentTab._parent._theme.Stroke, Transparency = 0.3})
				local capturing = false

				local function displayKey(k)
					btn.Text = (k and k.Name ~= "Unknown") and k.Name or "Unbound"
				end
				displayKey(key)

				btn.MouseButton1Click:Connect(function()
					capturing = true
					btn.Text = "Press key..."
				end)

				local captureConn = UserInputService.InputBegan:Connect(function(input, processed)
					if capturing and not processed then
						if input.UserInputType == Enum.UserInputType.Keyboard then
							key = input.KeyCode
							displayKey(key)
							capturing = false
							if typeof(cfg.Callback) == "function" then task.spawn(cfg.Callback, key) end
						end
					end
				end)

				-- runtime hook: when the key is pressed, call callback
				local runtimeConn = UserInputService.InputBegan:Connect(function(input, processed)
					if not processed and input.UserInputType == Enum.UserInputType.Keyboard and input.KeyCode == key then
						if typeof(cfg.Callback) == "function" then task.spawn(cfg.Callback) end
					end
				end)

				row.Destroying:Connect(function()
					if captureConn and captureConn.Connected then captureConn:Disconnect() end
					if runtimeConn and runtimeConn.Connected then runtimeConn:Disconnect() end
				end)

				btn.MouseEnter:Connect(function() showTooltip(cfg.Tooltip) end)
				btn.MouseLeave:Connect(function() showTooltip("") end)
				return { Set = function(_,k) key = k; displayKey(key) end, Get = function() return key end, Disconnect = function() if captureConn then captureConn:Disconnect() end; if runtimeConn then runtimeConn:Disconnect() end end }
			end

			function secObj:AddColorPicker(cfg)
				cfg = cfg or {}
				local color = cfg.Default or Color3.fromRGB(98,114,164)
				local row = controlRow(90)
				local label = new("TextLabel", {Parent = row, BackgroundTransparency = 1, Text = cfg.Text or "Color", Font = Enum.Font.Gotham, TextSize = 14, TextColor3 = self._parentTab._parent._theme.Text, Size = UDim2.new(1, -120, 0, 18), TextXAlignment = Enum.TextXAlignment.Left})
				local preview = new("Frame", {Parent = row, BackgroundColor3 = color, Size = UDim2.new(0,20,0,20), Position = UDim2.new(1,-110,0,0)})
				new("UICorner", {Parent = preview, CornerRadius = UDim.new(0,6)})
				new("UIStroke", {Parent = preview, Color = self._parentTab._parent._theme.Stroke, Transparency = 0.3})
				-- open color subpanel
				local panel = new("Frame", {Parent = row, BackgroundColor3 = self._parentTab._parent._theme.Panel, Size = UDim2.new(1,0,0,0), Position = UDim2.new(0,0,0,26), ClipsDescendants = true})
				new("UICorner", {Parent = panel, CornerRadius = UDim.new(0,8)})
				new("UIStroke", {Parent = panel, Color = self._parentTab._parent._theme.Stroke, Transparency = 0.3})
				local container = new("Frame", {Parent = panel, BackgroundTransparency = 1, Size = UDim2.new(1,0,0,120)})
				local layout = new("UIListLayout", {Parent = container, Padding = UDim.new(0,6), SortOrder = Enum.SortOrder.LayoutOrder})
				container.AutomaticSize = Enum.AutomaticSize.Y

				-- RGB sliders
				local function rgbSlider(component, default)
					local val = default or 128
					local rRow = new("Frame", {Parent = container, BackgroundTransparency = 1, Size = UDim2.new(1,0,0,36)})
					local lbl = new("TextLabel", {Parent = rRow, BackgroundTransparency = 1, Text = component .. ": " .. tostring(val), Font = Enum.Font.Gotham, TextSize = 13, TextColor3 = self._parentTab._parent._theme.Subtext, Size = UDim2.new(1,-0,0,16), TextXAlignment = Enum.TextXAlignment.Left})
					local bar = new("Frame", {Parent = rRow, BackgroundColor3 = self._parentTab._parent._theme.Panel, Size = UDim2.fromOffset(200,10), Position = UDim2.fromOffset(0,20)})
					new("UICorner", {Parent = bar, CornerRadius = UDim.new(0,6)})
					new("UIStroke", {Parent = bar, Color = self._parentTab._parent._theme.Stroke, Transparency = 0.3})
					local fill = new("Frame", {Parent = bar, BackgroundColor3 = self._parentTab._parent._theme.Accent, Size = UDim2.fromScale(val/255,1)})
					new("UICorner", {Parent = fill, CornerRadius = UDim.new(0,6)})
					local dragging = false
					bar.InputBegan:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 then dragging = true end end)
					UserInputService.InputEnded:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end end)
					local conn = UserInputService.InputChanged:Connect(function(i)
						if dragging and i.UserInputType == Enum.UserInputType.MouseMovement then
							local rel = math.clamp((i.Position.X - bar.AbsolutePosition.X)/bar.AbsoluteSize.X, 0, 1)
							val = math.floor(255 * rel + 0.5)
							lbl.Text = component .. ": " .. tostring(val)
							fill.Size = UDim2.fromScale(val/255, 1)
							local r = math.floor(color.R * 255)
							local g = math.floor(color.G * 255)
							local b = math.floor(color.B * 255)
							if component == "R" then r = val end
							if component == "G" then g = val end
							if component == "B" then b = val end
							color = Color3.fromRGB(r, g, b)
							preview.BackgroundColor3 = color
							if typeof(cfg.Callback) == "function" then task.spawn(cfg.Callback, color) end
						end
					end)
					rRow.Destroying:Connect(function() if conn and conn.Connected then conn:Disconnect() end end)
					return val
				end

				rgbSlider("R", math.floor(color.R*255))
				rgbSlider("G", math.floor(color.G*255))
				rgbSlider("B", math.floor(color.B*255))

				local open = false
				local toggle = new("TextButton", {Parent = row, Text = "Edit", BackgroundColor3 = self._parentTab._parent._theme.Panel, Size = UDim2.new(0,88,0,26), Position = UDim2.new(1,-88,0,0), AutoButtonColor = false, Font = Enum.Font.Gotham, TextSize = 13, TextColor3 = self._parentTab._parent._theme.Text})
				new("UICorner", {Parent = toggle, CornerRadius = UDim.new(0,6)})
				new("UIStroke", {Parent = toggle, Color = self._parentTab._parent._theme.Stroke, Transparency = 0.3})
				toggle.MouseButton1Click:Connect(function()
					open = not open
					tw(panel, 0.18, {Size = UDim2.new(1,0,0, open and 140 or 0)}):Play()
				end)
				-- initial preview
				preview.BackgroundColor3 = color
				toggle.MouseEnter:Connect(function() showTooltip(cfg.Tooltip) end)
				toggle.MouseLeave:Connect(function() showTooltip("") end)
				return {
					Set = function(_, c) color = c; preview.BackgroundColor3 = color; if typeof(cfg.Callback) == "function" then task.spawn(cfg.Callback, color) end end,
					Get = function() return color end
				}
			end

			-- finished building section
			table.insert(self._sections, secObj)
			return secObj
		end

		-- auto select first tab on create
		if #self._tabs == 0 then
			tabObj:Show()
		end
		table.insert(self._tabs, tabObj)
		return tabObj
	end

	-- Destroy
	function win:Destroy()
		if screenGui and screenGui.Parent then
			pcall(function() screenGui:Destroy() end)
		end
	end

	-- Tooltip autohide loop
	RunService.Heartbeat:Connect(function()
		if tooltip.Visible then
			local pos = UserInputService:GetMouseLocation()
			tooltip.Position = UDim2.fromOffset(pos.X + 16, pos.Y + 16)
		end
	end)

	-- Hide tooltip after some time when set
	RunService.Heartbeat:Connect(function()
		if tooltip.Visible and tooltipHideTick ~= 0 and tick() > tooltipHideTick then
			tooltip.Visible = false
			tooltipHideTick = 0
		end
	end)

	return win
end

return setmetatable({}, Raylite)
