--[[
	Simple helpers to create Roblox GUI instances.
]]
local function create(name: string, className: string, props: { [string]: any })
	local inst = Instance.new(className)
	inst.Name = name
	for k, v in props do
		if k == "Parent" then
			inst.Parent = v
		else
			local ok, err = pcall(function()
				inst[k] = v
			end)
			if not ok and k ~= "Parent" then
				-- skip invalid props
			end
		end
	end
	return inst
end

local function frame(name: string, parent: Instance, options: { [string]: any })
	local f = create(name, "Frame", options)
	f.BackgroundColor3 = Color3.fromRGB(40, 40, 45)
	f.BorderSizePixel = 0
	f.Parent = parent
	return f
end

local function textLabel(name: string, parent: Instance, text: string, options: { [string]: any })
	local l = create(name, "TextLabel", options)
	l.BackgroundTransparency = 1
	l.Text = text
	l.TextColor3 = Color3.fromRGB(255, 255, 255)
	l.Font = Enum.Font.GothamBold
	l.TextSize = 18
	l.Parent = parent
	return l
end

local function textButton(name: string, parent: Instance, text: string, options: { [string]: any })
	local b = create(name, "TextButton", options)
	b.BackgroundColor3 = Color3.fromRGB(60, 120, 200)
	b.BorderSizePixel = 0
	b.Text = text
	b.TextColor3 = Color3.fromRGB(255, 255, 255)
	b.Font = Enum.Font.GothamBold
	b.TextSize = 16
	b.Parent = parent
	return b
end

local function scrollingFrame(name: string, parent: Instance, options: { [string]: any })
	local s = create(name, "ScrollingFrame", options)
	s.BackgroundColor3 = Color3.fromRGB(35, 35, 40)
	s.BorderSizePixel = 0
	s.ScrollBarThickness = 6
	s.CanvasSize = UDim2.new(0, 0, 0, 0)
	s.AutomaticCanvasSize = Enum.AutomaticSize.Y
	s.Parent = parent
	return s
end

local function uICorner(parent: Instance, radius: number?)
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, radius or 8)
	c.Parent = parent
	return c
end

local function uIPadding(parent: Instance, padding: number)
	local p = Instance.new("UIPadding")
	p.PaddingLeft = UDim.new(0, padding)
	p.PaddingRight = UDim.new(0, padding)
	p.PaddingTop = UDim.new(0, padding)
	p.PaddingBottom = UDim.new(0, padding)
	p.Parent = parent
	return p
end

local function uIListLayout(parent: Instance, padding: number, sortOrder: Enum.SortOrder?)
	local l = Instance.new("UIListLayout")
	l.Padding = UDim.new(0, padding)
	l.SortOrder = sortOrder or Enum.SortOrder.LayoutOrder
	l.Parent = parent
	return l
end

return {
	create = create,
	frame = frame,
	textLabel = textLabel,
	textButton = textButton,
	scrollingFrame = scrollingFrame,
	uICorner = uICorner,
	uIPadding = uIPadding,
	uIListLayout = uIListLayout,
}
