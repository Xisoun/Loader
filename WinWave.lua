local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer

local buyRemote = ReplicatedStorage
	:WaitForChild("ScriptSignals")
	:WaitForChild("UnitShop")
	:WaitForChild("BuyUnit")

local pedestalRemote = ReplicatedStorage
	:WaitForChild("ScriptSignals")
	:WaitForChild("Pedestals")
	:WaitForChild("ClaimPedestalIncome")

local rarityColors = {
	Rare = Color3.fromRGB(0, 200, 0),
	Epic = Color3.fromRGB(150, 0, 200),
	Mythical = Color3.fromRGB(255, 100, 200),
	Divine = "rainbow",
	Celestial = "glow_yellow",
	Secret = "glow_black"
}

local rarities = {
	{name = "Rare", units = { "Barbarini", "Archerini" }},
	{name = "Epic", units = { "Knighty", "DartGoblini", "Musketeeri" }},
	{name = "Mythical", units = { "Valkerius", "Wizarderes" }},
	{name = "Divine", units = { "MiniPekku", "Witchu" }},
	{name = "Celestial", units = { "Golem", "Bowlerini" }},
	{name = "Secret", units = { "ElectroWizard", "Sparky", "Pekka", "RoyalGhosty" }}
}

local units = {}
local unitButtons = {}
for _, rarity in ipairs(rarities) do
	for _, name in ipairs(rarity.units) do
		units[name] = false
		unitButtons[name] = nil
	end
end

local enabled = false
local stopped = false
local pedestalEnabled = false
local collectInterval = 60
local bought = {}
local nextCollectTime = 0
local nextBuyTime = 0

local function buyAllUnits()
	print("=== Starting buy attempt ===")
	print("Checking unit shop for selected units...")
	
	for unit, active in pairs(units) do
		if active and not bought[unit] then
			print("Attempting to buy unit:", unit)
			for i = 1, 20 do
				task.spawn(function()
					local success, err = pcall(function()
						local args = {unit}
						buyRemote:FireServer(unpack(args))
						print("Sent buy request for:", unit)
					end)
					if not success then
						print("Failed attempt " .. i .. " for " .. unit .. ":", err)
					end
				end)
				task.wait(0.15)
			end
		end
	end
	print("=== Buy attempt complete ===")
end

-- AUTO BUY LOOP
task.spawn(function()
	while not stopped do
		if enabled then
			print("Auto-buy enabled, buying now...")
			buyAllUnits()
			print("Waiting 5 minutes until next buy...")
			nextBuyTime = os.time() + 300
			
			local waited = 0
			while waited < 300 and enabled and not stopped do
				task.wait(1)
				waited = waited + 1
			end
		else
			task.wait(1)
		end
	end
end)

-- AUTO COLLECT LOOP
task.spawn(function()
	while not stopped do
		if pedestalEnabled then
			print("Auto-collect enabled, collecting now...")
			print("Using interval:", collectInterval, "seconds")
			for i = 1, 15 do
				task.spawn(function()
					pcall(function()
						pedestalRemote:FireServer(i)
					end)
				end)
				task.wait(0.15)
			end
			nextCollectTime = os.time() + collectInterval
			
			local waited = 0
			while waited < collectInterval and pedestalEnabled and not stopped do
				task.wait(1)
				waited = waited + 1
			end
		else
			task.wait(1)
		end
	end
end)

-- TRACK BOUGHT UNITS
task.spawn(function()
	local inv = player:WaitForChild("Inventory", 10)
	if not inv then return end
	inv.ChildAdded:Connect(function(child)
		if units[child.Name] then
			print("Successfully bought:", child.Name)
			bought[child.Name] = true
			units[child.Name] = false
			
			if unitButtons[child.Name] then
				unitButtons[child.Name].Text = child.Name .. ": OFF"
				unitButtons[child.Name].BackgroundColor3 = Color3.fromRGB(90,90,90)
			end
		end
	end)
end)

local gui = Instance.new("ScreenGui")
gui.ResetOnSpawn = false
gui.Parent = player:WaitForChild("PlayerGui")

-- MAIN CONTAINER
local mainFrame = Instance.new("Frame", gui)
mainFrame.Size = UDim2.fromOffset(750, 400)
mainFrame.Position = UDim2.fromScale(0.5, 0.5)
mainFrame.AnchorPoint = Vector2.new(0.5, 0.5)
mainFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
mainFrame.BorderSizePixel = 0
mainFrame.ClipsDescendants = true
Instance.new("UICorner", mainFrame).CornerRadius = UDim.new(0, 12)

local minimized = false
local originalSize = mainFrame.Size

-- DRAGGING
local dragging, dragInput, dragStart, startPos

mainFrame.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
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

mainFrame.InputChanged:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseMovement then
		dragInput = input
	end
end)

game:GetService("UserInputService").InputChanged:Connect(function(input)
	if input == dragInput and dragging then
		local delta = input.Position - dragStart
		mainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
	end
end)

-- HEADER
local header = Instance.new("Frame", mainFrame)
header.Size = UDim2.fromOffset(750, 50)
header.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
header.BorderSizePixel = 0
Instance.new("UICorner", header).CornerRadius = UDim.new(0, 12)

local brandLabel = Instance.new("TextLabel", header)
brandLabel.Size = UDim2.fromOffset(600, 50)
brandLabel.Position = UDim2.fromOffset(10, 0)
brandLabel.Text = "TestHub"
brandLabel.Font = Enum.Font.GothamBold
brandLabel.TextSize = 26
brandLabel.TextColor3 = Color3.fromRGB(100, 200, 255)
brandLabel.BackgroundTransparency = 1
brandLabel.TextXAlignment = Enum.TextXAlignment.Left

local minimizeBtn = Instance.new("TextButton", header)
minimizeBtn.Size = UDim2.fromOffset(40, 40)
minimizeBtn.Position = UDim2.fromOffset(655, 5)
minimizeBtn.Text = "—"
minimizeBtn.Font = Enum.Font.GothamBold
minimizeBtn.TextSize = 20
minimizeBtn.BackgroundColor3 = Color3.fromRGB(80, 80, 0)
minimizeBtn.TextColor3 = Color3.new(1,1,1)
Instance.new("UICorner", minimizeBtn).CornerRadius = UDim.new(0, 8)

local closeBtn = Instance.new("TextButton", header)
closeBtn.Size = UDim2.fromOffset(40, 40)
closeBtn.Position = UDim2.fromOffset(700, 5)
closeBtn.Text = "❌"
closeBtn.Font = Enum.Font.GothamBold
closeBtn.TextSize = 18
closeBtn.BackgroundColor3 = Color3.fromRGB(120,0,0)
closeBtn.TextColor3 = Color3.new(1,1,1)
Instance.new("UICorner", closeBtn).CornerRadius = UDim.new(0, 8)

closeBtn.MouseButton1Click:Connect(function()
	stopped = true
	enabled = false
	pedestalEnabled = false
	gui:Destroy()
end)

-- ICON SIDEBAR
local iconBar = Instance.new("Frame", mainFrame)
iconBar.Size = UDim2.fromOffset(60, 340)
iconBar.Position = UDim2.fromOffset(5, 55)
iconBar.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
iconBar.BorderSizePixel = 0
Instance.new("UICorner", iconBar).CornerRadius = UDim.new(0, 10)

local function createIcon(emoji, y, color)
	local icon = Instance.new("TextButton", iconBar)
	icon.Size = UDim2.fromOffset(50, 50)
	icon.Position = UDim2.fromOffset(5, y)
	icon.Text = emoji
	icon.Font = Enum.Font.GothamBold
	icon.TextSize = 24
	icon.BackgroundColor3 = color
	icon.TextColor3 = Color3.new(1,1,1)
	Instance.new("UICorner", icon).CornerRadius = UDim.new(0, 10)
	return icon
end

local cubeIcon = createIcon("📦", 10, Color3.fromRGB(60,60,60))
local cashIcon = createIcon("💰", 70, Color3.fromRGB(60,60,60))

-- CONTENT CONTAINER
local contentFrame = Instance.new("Frame", mainFrame)
contentFrame.Size = UDim2.fromOffset(680, 345)
contentFrame.Position = UDim2.fromOffset(70, 55)
contentFrame.BackgroundTransparency = 1
contentFrame.BorderSizePixel = 0
contentFrame.ClipsDescendants = true

-- RESIZE HANDLE
local resizeHandle = Instance.new("TextButton", mainFrame)
resizeHandle.Size = UDim2.fromOffset(20, 20)
resizeHandle.Position = UDim2.new(1, -20, 1, -20)
resizeHandle.Text = "⬀"
resizeHandle.Font = Enum.Font.GothamBold
resizeHandle.TextSize = 16
resizeHandle.TextColor3 = Color3.fromRGB(150,150,150)
resizeHandle.BackgroundTransparency = 1
resizeHandle.ZIndex = 10

local resizing = false
local resizeStart, sizeStart

resizeHandle.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		resizing = true
		resizeStart = input.Position
		sizeStart = mainFrame.Size
		
		input.Changed:Connect(function()
			if input.UserInputState == Enum.UserInputState.End then
				resizing = false
			end
		end)
	end
end)

game:GetService("UserInputService").InputChanged:Connect(function(input)
	if resizing and input.UserInputType == Enum.UserInputType.MouseMovement then
		local delta = input.Position - resizeStart
		local newWidth = math.max(600, sizeStart.X.Offset + delta.X)
		local newHeight = math.max(300, sizeStart.Y.Offset + delta.Y)
		mainFrame.Size = UDim2.fromOffset(newWidth, newHeight)
		originalSize = mainFrame.Size
		
		-- Update content sizes
		header.Size = UDim2.fromOffset(newWidth, 50)
		brandLabel.Size = UDim2.fromOffset(newWidth - 150, 50)
		iconBar.Size = UDim2.fromOffset(60, newHeight - 60)
		contentFrame.Size = UDim2.fromOffset(newWidth - 70, newHeight - 55)
		buyPanel.Size = UDim2.fromOffset(newWidth - 70, newHeight - 55)
		collectPanel.Size = UDim2.fromOffset(newWidth - 70, newHeight - 55)
		buyScroll.Size = UDim2.fromOffset(newWidth - 80, newHeight - 100)
	end
end)

minimizeBtn.MouseButton1Click:Connect(function()
	minimized = not minimized
	if minimized then
		-- Store original size before minimizing
		originalSize = mainFrame.Size
		-- Hide all content
		iconBar.Visible = false
		contentFrame.Visible = false
		resizeHandle.Visible = false
		-- Shrink to header only
		mainFrame:TweenSize(UDim2.fromOffset(mainFrame.Size.X.Offset, 50), Enum.EasingDirection.Out, Enum.EasingStyle.Quad, 0.3, true)
		minimizeBtn.Text = "□"
	else
		-- Restore to original size
		mainFrame:TweenSize(originalSize, Enum.EasingDirection.Out, Enum.EasingStyle.Quad, 0.3, true)
		-- Show all content
		iconBar.Visible = true
		contentFrame.Visible = true
		resizeHandle.Visible = true
		minimizeBtn.Text = "—"
	end
end)

-- AUTO BUY PANEL
local buyPanel = Instance.new("Frame", contentFrame)
buyPanel.Size = UDim2.fromOffset(680, 345)
buyPanel.BackgroundTransparency = 1
buyPanel.Visible = false

local buyTitle = Instance.new("TextLabel", buyPanel)
buyTitle.Size = UDim2.fromOffset(680, 35)
buyTitle.Text = "AUTO BUY UNITS"
buyTitle.Font = Enum.Font.GothamBold
buyTitle.TextSize = 20
buyTitle.TextColor3 = Color3.new(1,1,1)
buyTitle.BackgroundTransparency = 1

local buyScroll = Instance.new("ScrollingFrame", buyPanel)
buyScroll.Size = UDim2.fromOffset(670, 300)
buyScroll.Position = UDim2.fromOffset(5, 40)
buyScroll.BackgroundTransparency = 1
buyScroll.BorderSizePixel = 0
buyScroll.ScrollBarThickness = 8
buyScroll.ScrollBarImageColor3 = Color3.fromRGB(80, 80, 80)
buyScroll.CanvasSize = UDim2.fromOffset(0, 0)

local buyLayout = Instance.new("UIListLayout", buyScroll)
buyLayout.Padding = UDim.new(0, 12)
buyLayout.SortOrder = Enum.SortOrder.LayoutOrder
buyLayout.FillDirection = Enum.FillDirection.Vertical
buyLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left

local function button(text, parent, color, width)
	local b = Instance.new("TextButton", parent)
	b.Size = UDim2.fromOffset(width or 180, 38)
	b.Text = text
	b.Font = Enum.Font.GothamBold
	b.TextSize = 14
	b.TextColor3 = Color3.new(1,1,1)
	b.BackgroundColor3 = color
	Instance.new("UICorner", b).CornerRadius = UDim.new(0, 10)
	return b
end

-- Control section
local buyControlFrame = Instance.new("Frame", buyScroll)
buyControlFrame.Size = UDim2.fromOffset(650, 60)
buyControlFrame.BackgroundTransparency = 1
buyControlFrame.LayoutOrder = 1

local toggleBtn = button("START AUTO BUY", buyControlFrame, Color3.fromRGB(0,170,0), 200)
toggleBtn.Position = UDim2.fromOffset(10, 5)

local buyCountdownLabel = Instance.new("TextLabel", buyControlFrame)
buyCountdownLabel.Size = UDim2.fromOffset(200, 22)
buyCountdownLabel.Position = UDim2.fromOffset(10, 50)
buyCountdownLabel.Text = "Next buy in: --"
buyCountdownLabel.Font = Enum.Font.Gotham
buyCountdownLabel.TextSize = 12
buyCountdownLabel.TextColor3 = Color3.fromRGB(150,150,150)
buyCountdownLabel.BackgroundTransparency = 1

-- Countdown timer update for buy
task.spawn(function()
	while not stopped do
		if enabled and nextBuyTime > 0 then
			local timeLeft = nextBuyTime - os.time()
			if timeLeft >= 0 then
				local minutes = math.floor(timeLeft / 60)
				local seconds = timeLeft % 60
				buyCountdownLabel.Text = string.format("Next buy in: %dm %02ds", minutes, seconds)
			else
				buyCountdownLabel.Text = "Buying now..."
			end
		else
			buyCountdownLabel.Text = "Next buy in: --"
		end
		task.wait(1)
	end
end)

toggleBtn.MouseButton1Click:Connect(function()
	enabled = not enabled
	toggleBtn.Text = enabled and "STOP AUTO BUY" or "START AUTO BUY"
	toggleBtn.BackgroundColor3 = enabled and Color3.fromRGB(170,0,0) or Color3.fromRGB(0,170,0)
	cubeIcon.BackgroundColor3 = enabled and Color3.fromRGB(0,170,0) or Color3.fromRGB(60,60,60)
	
	if not enabled then
		nextBuyTime = 0
	end
end)

local order = 2
for _, rarity in ipairs(rarities) do
	local rarityContainer = Instance.new("Frame", buyScroll)
	rarityContainer.Size = UDim2.fromOffset(650, 50)
	rarityContainer.BackgroundTransparency = 1
	rarityContainer.LayoutOrder = order
	order += 1

	-- Get rarity color
	local rarityColor = rarityColors[rarity.name]
	local isSpecialColor = type(rarityColor) == "string"
	local buttonColor = isSpecialColor and Color3.fromRGB(60,60,60) or rarityColor
	
	local header = button(rarity.name .. " ▸", rarityContainer, buttonColor, 450)
	header.Position = UDim2.fromOffset(10, 5)
	
	-- Add special effects for rainbow/glow colors
	if rarityColor == "rainbow" then
		task.spawn(function()
			while not stopped do
				local hue = (tick() % 5) / 5
				header.BackgroundColor3 = Color3.fromHSV(hue, 1, 1)
				task.wait(0.05)
			end
		end)
	elseif rarityColor == "glow_yellow" then
		task.spawn(function()
			while not stopped do
				local brightness = 0.5 + math.sin(tick() * 3) * 0.3
				header.BackgroundColor3 = Color3.fromRGB(255 * brightness, 255 * brightness, 0)
				task.wait(0.05)
			end
		end)
	elseif rarityColor == "glow_black" then
		task.spawn(function()
			while not stopped do
				local brightness = 0.3 + math.sin(tick() * 3) * 0.2
				header.BackgroundColor3 = Color3.fromRGB(255 * brightness, 255 * brightness, 255 * brightness)
				task.wait(0.05)
			end
		end)
	end
	
	local dropdown = Instance.new("Frame", rarityContainer)
	dropdown.Size = UDim2.fromOffset(640, 0)
	dropdown.Position = UDim2.fromOffset(10, 53)
	dropdown.BackgroundColor3 = Color3.fromRGB(30,30,30)
	dropdown.BorderSizePixel = 0
	dropdown.Visible = false
	dropdown.ClipsDescendants = true
	Instance.new("UICorner", dropdown).CornerRadius = UDim.new(0, 10)

	local dropdownLayout = Instance.new("UIListLayout", dropdown)
	dropdownLayout.Padding = UDim.new(0, 3)
	dropdownLayout.SortOrder = Enum.SortOrder.LayoutOrder
	
	-- Buy All checkbox - better positioned
	local buyAllCheckbox = Instance.new("TextButton", rarityContainer)
	buyAllCheckbox.Size = UDim2.fromOffset(170, 38)
	buyAllCheckbox.Position = UDim2.fromOffset(470, 5)
	buyAllCheckbox.Text = "Buy All: OFF"
	buyAllCheckbox.Font = Enum.Font.GothamBold
	buyAllCheckbox.TextSize = 13
	buyAllCheckbox.TextColor3 = Color3.new(1,1,1)
	buyAllCheckbox.BackgroundColor3 = Color3.fromRGB(90,90,90)
	Instance.new("UICorner", buyAllCheckbox).CornerRadius = UDim.new(0, 10)
	
	local buyAllEnabled = false
	buyAllCheckbox.MouseButton1Click:Connect(function()
		buyAllEnabled = not buyAllEnabled
		buyAllCheckbox.Text = "Buy All: " .. (buyAllEnabled and "ON" or "OFF")
		buyAllCheckbox.BackgroundColor3 = buyAllEnabled and Color3.fromRGB(0,170,0) or Color3.fromRGB(90,90,90)
		
		for _, unit in ipairs(rarity.units) do
			units[unit] = buyAllEnabled
			
			if unitButtons[unit] then
				unitButtons[unit].Text = unit .. (buyAllEnabled and ": ON" or ": OFF")
				unitButtons[unit].BackgroundColor3 = buyAllEnabled and Color3.fromRGB(0,120,255) or Color3.fromRGB(90,90,90)
			end
		end
	end)

	local open = false
	header.MouseButton1Click:Connect(function()
		open = not open
		header.Text = rarity.name .. (open and " ▾" or " ▸")
		
		if open then
			dropdown.Visible = true
			local dropdownHeight = (#rarity.units * 33) + 6
			dropdown:TweenSize(
				UDim2.fromOffset(640, dropdownHeight),
				Enum.EasingDirection.Out,
				Enum.EasingStyle.Quad,
				0.25,
				true
			)
			rarityContainer:TweenSize(
				UDim2.fromOffset(650, 53 + dropdownHeight + 8),
				Enum.EasingDirection.Out,
				Enum.EasingStyle.Quad,
				0.25,
				true
			)
		else
			dropdown:TweenSize(
				UDim2.fromOffset(640, 0),
				Enum.EasingDirection.Out,
				Enum.EasingStyle.Quad,
				0.25,
				true,
				function()
					dropdown.Visible = false
				end
			)
			rarityContainer:TweenSize(
				UDim2.fromOffset(650, 50),
				Enum.EasingDirection.Out,
				Enum.EasingStyle.Quad,
				0.25,
				true
			)
		end
	end)

	for idx, unit in ipairs(rarity.units) do
		local ub = Instance.new("TextButton", dropdown)
		ub.Size = UDim2.fromOffset(630, 30)
		ub.Text = unit .. ": OFF"
		ub.Font = Enum.Font.GothamBold
		ub.TextSize = 12
		ub.TextColor3 = Color3.new(1,1,1)
		ub.BackgroundColor3 = Color3.fromRGB(90,90,90)
		ub.LayoutOrder = idx
		Instance.new("UICorner", ub).CornerRadius = UDim.new(0, 8)
		
		unitButtons[unit] = ub
		
		ub.MouseButton1Click:Connect(function()
			units[unit] = not units[unit]
			ub.Text = unit .. (units[unit] and ": ON" or ": OFF")
			ub.BackgroundColor3 = units[unit] and Color3.fromRGB(0,120,255) or Color3.fromRGB(90,90,90)
		end)
	end
end

buyScroll.CanvasSize = UDim2.fromOffset(0, buyLayout.AbsoluteContentSize.Y)
buyLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
	buyScroll.CanvasSize = UDim2.fromOffset(0, buyLayout.AbsoluteContentSize.Y)
end)

-- AUTO COLLECT PANEL
local collectPanel = Instance.new("Frame", contentFrame)
collectPanel.Size = UDim2.fromOffset(680, 345)
collectPanel.BackgroundTransparency = 1
collectPanel.Visible = false

local collectTitle = Instance.new("TextLabel", collectPanel)
collectTitle.Size = UDim2.fromOffset(680, 35)
collectTitle.Text = "AUTO COLLECT MONEY"
collectTitle.Font = Enum.Font.GothamBold
collectTitle.TextSize = 20
collectTitle.TextColor3 = Color3.new(1,1,1)
collectTitle.BackgroundTransparency = 1

local collectContent = Instance.new("Frame", collectPanel)
collectContent.Size = UDim2.fromOffset(500, 200)
collectContent.Position = UDim2.fromOffset(90, 80)
collectContent.BackgroundTransparency = 1

local toggleCollectBtn = Instance.new("TextButton", collectContent)
toggleCollectBtn.Size = UDim2.fromOffset(480, 45)
toggleCollectBtn.Position = UDim2.fromOffset(10, 10)
toggleCollectBtn.Text = "START AUTO COLLECT"
toggleCollectBtn.Font = Enum.Font.GothamBold
toggleCollectBtn.TextSize = 16
toggleCollectBtn.TextColor3 = Color3.new(1,1,1)
toggleCollectBtn.BackgroundColor3 = Color3.fromRGB(0,170,0)
Instance.new("UICorner", toggleCollectBtn).CornerRadius = UDim.new(0, 10)

toggleCollectBtn.MouseButton1Click:Connect(function()
	pedestalEnabled = not pedestalEnabled
	toggleCollectBtn.Text = pedestalEnabled and "STOP AUTO COLLECT" or "START AUTO COLLECT"
	toggleCollectBtn.BackgroundColor3 = pedestalEnabled and Color3.fromRGB(170,0,0) or Color3.fromRGB(0,170,0)
	cashIcon.BackgroundColor3 = pedestalEnabled and Color3.fromRGB(170,170,0) or Color3.fromRGB(60,60,60)
	
	if not pedestalEnabled then
		nextCollectTime = 0
	end
end)

local sliderLabel = Instance.new("TextLabel", collectContent)
sliderLabel.Size = UDim2.fromOffset(480, 25)
sliderLabel.Position = UDim2.fromOffset(10, 70)
sliderLabel.Text = "Collect Interval: 1 minute"
sliderLabel.Font = Enum.Font.GothamBold
sliderLabel.TextSize = 14
sliderLabel.TextColor3 = Color3.new(1,1,1)
sliderLabel.BackgroundTransparency = 1

local countdownLabel = Instance.new("TextLabel", collectContent)
countdownLabel.Size = UDim2.fromOffset(480, 20)
countdownLabel.Position = UDim2.fromOffset(10, 92)
countdownLabel.Text = "Next collect in: --"
countdownLabel.Font = Enum.Font.Gotham
countdownLabel.TextSize = 12
countdownLabel.TextColor3 = Color3.fromRGB(150,150,150)
countdownLabel.BackgroundTransparency = 1

-- Countdown timer update
task.spawn(function()
	while not stopped do
		if pedestalEnabled and nextCollectTime > 0 then
			local timeLeft = nextCollectTime - os.time()
			if timeLeft >= 0 then
				local minutes = math.floor(timeLeft / 60)
				local seconds = timeLeft % 60
				countdownLabel.Text = string.format("Next collect in: %dm %02ds", minutes, seconds)
			else
				countdownLabel.Text = "Collecting now..."
			end
		else
			countdownLabel.Text = "Next collect in: --"
		end
		task.wait(1)
	end
end)

local sliderBg = Instance.new("Frame", collectContent)
sliderBg.Size = UDim2.fromOffset(480, 12)
sliderBg.Position = UDim2.fromOffset(10, 125)
sliderBg.BackgroundColor3 = Color3.fromRGB(50,50,50)
Instance.new("UICorner", sliderBg).CornerRadius = UDim.new(1, 0)

local sliderFill = Instance.new("Frame", sliderBg)
sliderFill.Size = UDim2.fromScale(0, 1)
sliderFill.BackgroundColor3 = Color3.fromRGB(170,170,0)
sliderFill.BorderSizePixel = 0
Instance.new("UICorner", sliderFill).CornerRadius = UDim.new(1, 0)

local sliderKnob = Instance.new("TextButton", sliderBg)
sliderKnob.Size = UDim2.fromOffset(24, 24)
sliderKnob.Position = UDim2.fromScale(0, 0.5)
sliderKnob.AnchorPoint = Vector2.new(0.5, 0.5)
sliderKnob.Text = ""
sliderKnob.BackgroundColor3 = Color3.fromRGB(255,255,255)
Instance.new("UICorner", sliderKnob).CornerRadius = UDim.new(1, 0)

local draggingSlider = false
sliderKnob.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		draggingSlider = true
	end
end)

game:GetService("UserInputService").InputEnded:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		draggingSlider = false
	end
end)

game:GetService("UserInputService").InputChanged:Connect(function(input)
	if draggingSlider and input.UserInputType == Enum.UserInputType.MouseMovement then
		local relativeX = input.Position.X - sliderBg.AbsolutePosition.X
		local percent = math.clamp(relativeX / sliderBg.AbsoluteSize.X, 0, 1)
		sliderKnob.Position = UDim2.fromScale(percent, 0.5)
		sliderFill.Size = UDim2.fromScale(percent, 1)
		
		collectInterval = math.floor(60 + (percent * 540))
		local minutes = math.floor(collectInterval / 60)
		sliderLabel.Text = "Collect Interval: " .. minutes .. " minute" .. (minutes > 1 and "s" or "")
	end
end)

-- ICON HANDLERS
cubeIcon.MouseButton1Click:Connect(function()
	buyPanel.Visible = true
	collectPanel.Visible = false
end)

cashIcon.MouseButton1Click:Connect(function()
	collectPanel.Visible = true
	buyPanel.Visible = false
end)
