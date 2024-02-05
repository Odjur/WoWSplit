
--[[------------------------------------------------------------------------------------------------
	WoWSplit
--]]------------------------------------------------------------------------------------------------

-- Loaded from WoWSplit_SavedVariable
local splits
local layouts
local settings
local state

-- Dynamic references
local activeSplits
local activeRun
local activeLayout

-- Global functions
WoWSplit = {}

function WoWSplit:Start()
	if state.running then return end
	if #activeRun.loadless.segments == #activeSplits.names then return end
	
	state.running = true
	local timestamp = GetTimePreciseSec()
	
	if state.loadless.begin then
		state.loadless.timer = timestamp - state.loadless.timer
		state.loadless.begin = timestamp - state.loadless.begin
		
		if not state.loading then
			state.loads.timer = timestamp - state.loads.timer
			state.loads.begin = timestamp - state.loads.begin
		end
	else
		state.loadless.begin = timestamp
		state.loadless.timer = timestamp
		state.loads.begin = timestamp
		state.loads.timer = timestamp
	end
end

function WoWSplit:Stop()
	if not state.running then return end
	
	state.running = false
	local timestamp = GetTimePreciseSec()
	
	state.loadless.timer = timestamp - state.loadless.timer
	state.loadless.begin = timestamp - state.loadless.begin
	
	if not state.loading then
		state.loads.timer = timestamp - state.loads.timer
		state.loads.begin = timestamp - state.loads.begin
	end
end

local huge = 2 ^ 32 - 1

function WoWSplit:Split()
	if #activeRun.loadless.segments == #activeSplits.names then return end
	if not state.loadless.begin then return end
	
	local timestamp = GetTimePreciseSec()
	local segment = #activeRun.loadless.segments + 1
	
	activeRun.loadless.segments[segment] = timestamp - state.loadless.timer
	activeRun.loads.segments[segment] = timestamp - state.loads.timer
	activeRun.loadless.totals[segment] = timestamp - state.loadless.begin
	activeRun.loads.totals[segment] = timestamp - state.loads.begin
	
	state.loadless.timer = timestamp
	state.loads.timer = timestamp
	
	if segment < #activeSplits.names then return end
	state.running = false
end

function WoWSplit:Reset()
	state.running = false
	state.loadless.begin = nil
	state.loads.begin = nil
	
	local segment = #activeRun.loadless.segments
	if segment == 0 then return end
	
	-- Update sum of best segments
	local sumOfBest = activeSplits.sumOfBest
	
	for a = 1, segment do
		if activeRun.loadless.segments[a] < sumOfBest.loadless.segments[a] and activeRun.loadless.segments[a] > 0 then
			sumOfBest.loadless.segments[a] = activeRun.loadless.segments[a]
		end
		
		if activeRun.loads.segments[a] < sumOfBest.loads.segments[a] and activeRun.loads.segments[a] > 0 then
			sumOfBest.loads.segments[a] = activeRun.loads.segments[a]
		end
	end
	
	-- Update sum of best totals
	sumOfBest.loadless.totals[1] = sumOfBest.loadless.segments[1]
	sumOfBest.loads.totals[1] = sumOfBest.loads.segments[1]
	
	for a = 2, #activeSplits.names do
		sumOfBest.loadless.totals[a] = sumOfBest.loadless.totals[a - 1] + sumOfBest.loadless.segments[a]
		sumOfBest.loads.totals[a] = sumOfBest.loads.totals[a - 1] + sumOfBest.loads.segments[a]
	end
	
	-- Update personal best
	local personalBest = activeSplits.personalBest
	
	if activeRun.loadless.totals[segment] <
			personalBest.loadless.totals[#personalBest.loadless.totals] and
			(segment == #personalBest.loadless.totals or
			personalBest.loadless.totals[segment + 1] == huge) and
			activeRun.loadless.totals[segment] > 0 then
		for a = 1, segment do
			personalBest.loadless.segments[a] = activeRun.loadless.segments[a]
			personalBest.loads.segments[a] = activeRun.loads.segments[a]
			personalBest.loadless.totals[a] = activeRun.loadless.totals[a]
			personalBest.loads.totals[a] = activeRun.loads.totals[a]
		end
	end
	
	activeSplits.runs[#activeSplits.runs + 1] = {
		loadless = {segments = {}, totals = {}},
		loads = {segments = {}, totals = {}}
	}
	
	activeRun = activeSplits.runs[#activeSplits.runs]
end

function WoWSplit:Skip()
	if #activeRun.loadless.segments >= #activeSplits.names - 1 then return end
	
	local segment = #activeRun.loadless.segments + 1
	activeRun.loadless.segments[segment] = 0
	activeRun.loads.segments[segment] = 0
	activeRun.loadless.totals[segment] = activeRun.loadless.totals[segment - 1] or 0
	activeRun.loads.totals[segment] = activeRun.loads.totals[segment - 1] or 0
end

function WoWSplit:Undo()
	if #activeRun.loadless.segments == 0 then return end
	
	state.loadless.timer = state.loadless.timer - activeRun.loadless.segments[#activeRun.loadless.segments]
	activeRun.loadless.segments[#activeRun.loadless.segments] = nil
	
	state.loads.timer = state.loads.timer - activeRun.loads.segments[#activeRun.loads.segments]
	activeRun.loads.segments[#activeRun.loads.segments] = nil
	
	if not state.loadless.begin then return end
	state.running = true
end

--[[------------------------------------------------------------------------------------------------
	Splits
--]]------------------------------------------------------------------------------------------------

local function CreateSplits()
	local splits = {}
	
	splits.category = "Category Name"
	splits.subCategory = "Any%"
	splits.names = {}
	
	for a = 1, 10 do
		splits.names[a] = "Split " .. a
	end
	
	splits.runs = {{
		loadless = {segments = {}, totals = {}},
		loads = {segments = {}, totals = {}}
	}}
	
	splits.personalBest = {
		loadless = {segments = {}, totals = {}},
		loads = {segments = {}, totals = {}}
	}
	
	splits.sumOfBest = {
		loadless = {segments = {}, totals = {}},
		loads = {segments = {}, totals = {}}
	}
	
	for a = 1, #splits.names do
		splits.personalBest.loadless.segments[a] = huge
		splits.personalBest.loads.segments[a] = huge
		splits.personalBest.loadless.totals[a] = huge
		splits.personalBest.loads.totals[a] = huge
		
		splits.sumOfBest.loadless.segments[a] = huge
		splits.sumOfBest.loads.segments[a] = huge
		splits.sumOfBest.loadless.totals[a] = huge
		splits.sumOfBest.loads.totals[a] = huge
	end
	
	return splits
end

--[[------------------------------------------------------------------------------------------------
	Layout
--]]------------------------------------------------------------------------------------------------

local function CreateLayout()
	local layout = {}
	
	layout.clickable = true
	layout.anchor = "RIGHT"
	layout.x = 0
	layout.y = 0
	layout.vertical = true
	layout.spacing = 0
	
	for a, b in pairs({"title", "splits", "timer", "data", "controls", "settings"}) do
		layout[b] = {}
		layout[b].enabled = true
		
		layout[b].width = 300
		layout[b].height = 24
		layout[b].padding = 4
		layout[b].primaryColor = "#1A1A1AFF"
		
		layout[b].borderSize = 1
		layout[b].borderColor = "#060606FF"
		
		layout[b].font = "Interface\\Addons\\WoWSplit\\Assets\\Fonts\\Nunito\\Nunito-Regular.ttf"
		layout[b].fontSize = 14
		layout[b].fontColor = "#E6E6E6FF"
	end
	
	layout.settings.enabled = false
	
	layout.controls.width = 20
	layout.settings.width = 300
	layout.title.height = 40
	layout.timer.height = 40
	layout.controls.height = 20
	layout.settings.height = 500
	layout.settings.lineHeight = 20
	
	layout.title.inline = false
	layout.splits.inline = true
	layout.data.inline = true
	
	layout.splits.precision = 0
	layout.timer.precision = 2
	layout.data.precision = 0
	
	layout.splits.segments = 10
	layout.data.segments = 10
	layout.splits.spacing = 0
	layout.data.spacing = 0
	layout.controls.spacing = 0
	layout.settings.spacing = 0
	layout.splits.secondaryColor = "#262626FF"
	layout.data.secondaryColor = "#262626FF"
	layout.controls.secondaryColor = "#262626FF"
	
	layout.timer.font = "Interface\\Addons\\WoWSplit\\Assets\\Fonts\\CourierPrime\\CourierPrime-Regular.ttf"
	layout.controls.font = nil
	layout.timer.fontSize = 32
	layout.controls.fontSize = nil
	layout.controls.fontColor = nil
	
	return layout
end

--[[------------------------------------------------------------------------------------------------
	Utility functions
--]]------------------------------------------------------------------------------------------------

-- Convert color formats
local function HexToRGBA(hex)
	hex = hex:gsub("#", "")
	
	if hex:len() == 6 then
		return	tonumber("0x" .. hex:sub(1, 2)) / 255, tonumber("0x" .. hex:sub(3, 4)) / 255,
				tonumber("0x" .. hex:sub(5, 6)) / 255
	else
		return	tonumber("0x" .. hex:sub(1, 2)) / 255, tonumber("0x" .. hex:sub(3, 4)) / 255,
				tonumber("0x" .. hex:sub(5, 6)) / 255, tonumber("0x" .. hex:sub(7, 8)) / 255
	end
end

-- Cache string formats up to the supported number of decimal places using string voodoo
local formats = {}

formats[0] = {
	"%d:%02d:%02.0f",
	"%d:%02.0f",
	"%.0f"
}

for a = 1, 3 do
	formats[a] = {
		"%d:%02d:%0" .. (a + 3) .. "." .. a .. "f",
		"%d:%0" .. (a + 3) .. "." .. a .. "f",
		"%." .. a .. "f"
	}
end

-- Format time as 'H:MM:SS.MMM'
local function SecToTime(sec, precision)
	local scale = 10 ^ precision
	sec = math.floor(math.abs(sec) * scale) / scale
	
	if sec >= 3600 then
		return string.format(formats[precision][1], sec / 3600, (sec % 3600) / 60, sec % 60)
	elseif sec >= 60 then
		return string.format(formats[precision][2], (sec % 3600) / 60, sec % 60)
	else
		return string.format(formats[precision][3], sec % 60)
	end
end

--[[------------------------------------------------------------------------------------------------
	Frame template
--]]------------------------------------------------------------------------------------------------

local function TemplateFrame(frame, parent, layout, class, isContainer)
	layout = activeLayout[layout]
	frame = frame or CreateFrame(class or "Frame", nil, parent, "BackdropTemplate")
	frame:SetShown(layout.enabled)
	
	if not isContainer then
		frame:SetBackdrop({
			bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
			edgeFile = "Interface\\ChatFrame\\ChatFrameBackground",
			tile = false,
			tileSize = 0,
			edgeSize = layout.borderSize,
			insets = {layout.padding, layout.padding, layout.padding, layout.padding}
		})
		
		frame:SetBackdropColor(HexToRGBA(layout.primaryColor))
		frame:SetBackdropBorderColor(HexToRGBA(layout.borderColor))
	end
	
	frame:SetSize(layout.width, layout.height)
	
	if class == "EditBox" then
		frame:SetFont(layout.font, layout.fontSize, "")
		frame:SetTextColor(HexToRGBA(layout.fontColor))
		frame:SetTextInsets(4, 4, 0, 0)
		frame:SetAutoFocus(false)
		frame:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
		frame:SetScript("OnEnterPressed", function(self) self:ClearFocus() end)
	end
	
	frame.super = frame.super or frame.SetPoint
	function frame.SetPoint(...)
		frame:ClearAllPoints()
		frame.super(...)
	end
	
	function frame:TemplateFontString(fontString)
		if fontString then return fontString end
		fontString = fontString or frame:CreateFontString()
		
		fontString:SetFont(layout.font, layout.fontSize, "")
		fontString:SetTextColor(HexToRGBA(layout.fontColor))
		
		fontString.super = fontString.super or fontString.SetPoint
		function fontString.SetPoint(self, position, ...)
			local point = {position, ...}
			
			-- Adjust fonts down a pixel
			if type(point[#point]) == "number" then
				point[#point] = point[#point] - 1
			else
				point[#point + 1] = 0
				point[#point + 1] = -1
			end
			
			-- Apply padding
			if string.find(position, "TOP") then
				point[#point] = point[#point] - layout.padding
			elseif string.find(position, "BOTTOM") then
				point[#point] = point[#point] + layout.padding
			elseif string.find(position, "LEFT") then
				point[#point - 1] = point[#point - 1] + layout.padding
			elseif string.find(position, "RIGHT") then
				point[#point - 1] = point[#point - 1] - layout.padding
			end
			
			self:ClearAllPoints()
			fontString.super(self, unpack(point))
		end
		
		function fontString:TemplateText(text)
			fontString:SetText(SecToTime(text, layout.precision))
		end
		
		return fontString
	end
	
	return frame
end

--[[------------------------------------------------------------------------------------------------
	Create or update frames
--]]------------------------------------------------------------------------------------------------

local WS = CreateFrame("Frame", nil, UIParent)

local function LoadFrames()
	WS:ClearAllPoints()
	WS:SetPoint(activeLayout.anchor, activeLayout.x, activeLayout.y)
	
	if activeLayout.clickable then
		WS:SetPassThroughButtons()
	else
		WS:SetPassThroughButtons("LeftButton", "MiddleButton", "Button4", "Button5")
	end
	
	-- Title
	WS.title = TemplateFrame(WS.title, WS, "title")
	
	WS.title.category = TemplateFrame(WS.title.category, WS.title, "title", "EditBox")
	WS.title.category:SetPoint("TOP", 0, activeLayout.title.padding * -1)
	WS.title.category:SetSize(activeLayout.title.width - activeLayout.title.padding * 2,
			(activeLayout.title.height - activeLayout.title.padding * 3) * 0.5)
	WS.title.category:SetBackdropBorderColor(0, 0, 0, 0)
	WS.title.category:SetText(activeSplits.category)
	WS.title.category:SetJustifyH("CENTER")
	WS.title.category:SetScript("OnEditFocusLost", function(self)
		activeSplits.category = self:GetText()
		LoadFrames()
	end)
	
	WS.title.subCategory = TemplateFrame(WS.title.subCategory, WS.title, "title", "EditBox")
	WS.title.subCategory:SetPoint("BOTTOM", 0, activeLayout.title.padding)
	WS.title.subCategory:SetSize(activeLayout.title.width - activeLayout.title.padding * 2,
			(activeLayout.title.height - activeLayout.title.padding * 3) * 0.5)
	WS.title.subCategory:SetBackdropBorderColor(0, 0, 0, 0)
	WS.title.subCategory:SetText(activeSplits.subCategory)
	WS.title.subCategory:SetJustifyH("CENTER")
	WS.title.subCategory:SetScript("OnEditFocusLost", function(self)
		activeSplits.subCategory = self:GetText()
		LoadFrames()
	end)
	
	-- Splits
	WS.splits = TemplateFrame(WS.splits, WS, "splits", nil, true)
	
	if activeLayout.vertical then
		WS.splits:SetSize(activeLayout.splits.width,
				activeLayout.splits.height * activeLayout.splits.segments +
				activeLayout.splits.spacing * (activeLayout.splits.segments - 1))
	else
		WS.splits:SetSize(activeLayout.splits.width * activeLayout.splits.segments +
				activeLayout.splits.spacing * (activeLayout.splits.segments - 1),
				activeLayout.splits.height)
	end
	
	-- Calculate limited splits display
	local offset
	
	if #activeRun.loadless.segments < activeLayout.splits.segments * 0.5 + 0.1 then
		offset = 0
	elseif #activeRun.loadless.segments > #activeSplits.names - activeLayout.splits.segments then
		offset = #activeSplits.names - activeLayout.splits.segments
	else
		offset = #activeRun.loadless.segments - math.floor(activeLayout.splits.segments * 0.5 + 0.1)
	end
	
	for a = 1, activeLayout.splits.segments do
		local split = "split" .. a
		
		-- Splits background
		WS.splits[split] = TemplateFrame(WS.splits[split], WS.splits, "splits")
		WS.splits[split]:Show()
		
		if a % 2 == 0 then
			WS.splits[split]:SetBackdropColor(HexToRGBA(activeLayout.splits.secondaryColor))
		end
		
		if activeLayout.vertical then
			WS.splits[split]:SetPoint("TOP", 0, -1 * (a - 1) * (activeLayout.splits.height + activeLayout.splits.spacing))
		else
			WS.splits[split]:SetPoint("LEFT", (a - 1) * (activeLayout.splits.width + activeLayout.splits.spacing), 0)
		end
		
		a = a + offset
		
		-- Splits name
		WS.splits[split].name = TemplateFrame(WS.splits[split].name, WS.splits[split], "splits", "EditBox")
		WS.splits[split].name:SetSize(activeLayout.splits.width - activeLayout.splits.padding * 2, activeLayout.splits.height)
		WS.splits[split].name:SetBackdropColor(0, 0, 0, 0)
		WS.splits[split].name:SetBackdropBorderColor(0, 0, 0, 0)
		WS.splits[split].name:SetText(activeSplits.names[a])
		WS.splits[split].name:SetScript("OnEditFocusLost", function(self)
			activeSplits.names[a] = self:GetText()
			LoadFrames()
		end)
		
		-- Splits delta
		WS.splits[split].delta = WS.splits[split]:TemplateFontString(WS.splits[split].delta)
		
		-- Set previous split deltas
		if a <= #activeRun.loadless.segments then
			if state.loadless.begin then
				local method = settings.method
				local split = a
				
				-- Timing calculations
				local segment = activeRun[method].segments[split]
				local bestSegment = activeSplits.sumOfBest[method].segments[split]
				local deltaSegment = segment - activeSplits.personalBest[method].segments[split]
				local total = activeRun[method].totals[split]
				local deltaTotal = total - activeSplits.personalBest[method].totals[split]
				
				-- Manage previous split
				local frame = WS.splits["split" .. split].delta
				
				if bestSegment == huge then
					frame:SetText("-")
					frame:SetTextColor(HexToRGBA(activeLayout.splits.fontColor))
				elseif deltaTotal >= 0 then
					frame:SetText("+" .. SecToTime(deltaTotal, activeLayout.splits.precision))
					
					if deltaSegment < 0 then
						frame:SetTextColor(0.95, 0.35, 0.35, 1) -- Light red
					else
						frame:SetTextColor(0.95, 0, 0, 1) -- Dark red
					end
				else
					frame:SetText("-" .. SecToTime(deltaTotal, activeLayout.splits.precision))
					
					if deltaSegment < 0 then
						frame:SetTextColor(0, 0.95, 0, 1) -- Dark green
					else
						frame:SetTextColor(0.35, 0.95, 0.35, 1) -- Light green
					end
				end
			end
		else
			WS.splits[split].delta:SetText("")
		end
		
		-- Splits timer
		WS.splits[split].timer = WS.splits[split]:TemplateFontString(WS.splits[split].timer)
		
		if a <= #activeRun.loadless.segments then
			WS.splits[split].timer:TemplateText(activeRun[settings.method].totals[a])
		else
			if activeSplits.personalBest[settings.method].totals[a] == huge then
				WS.splits[split].timer:SetText("-")
			else
				WS.splits[split].timer:TemplateText(activeSplits.personalBest[settings.method].totals[a])
			end
		end
		
		-- Splits orientation
		if activeLayout.splits.inline then
			WS.splits[split].name:SetPoint("LEFT")
			WS.splits[split].delta:SetPoint("RIGHT", -50, 0) -- TODO; better spacing
			WS.splits[split].timer:SetPoint("RIGHT")
		else
			WS.splits[split].name:SetPoint("TOP")
			WS.splits[split].delta:SetPoint("BOTTOMLEFT")
			WS.splits[split].timer:SetPoint("BOTTOMRIGHT")
		end
	end
	
	for a = activeLayout.splits.segments + 1, 99 do
		local split = "split" .. a
		
		if WS.splits[split] then
			WS.splits[split]:Hide()
		else
			break
		end
	end
	
	-- Timer
	WS.timer = TemplateFrame(WS.timer, WS, "timer")
	
	WS.timer.stopwatch = WS.timer:TemplateFontString(WS.timer.stopwatch)
	WS.timer.stopwatch:SetPoint("RIGHT")
	
	-- Set current split delta and timer
	if state.loadless.begin then
		if not state.running then
			local method = settings.method
			local split = #activeRun[method].segments + 1
			
			-- Timing calculations
			if #activeRun[method].segments < #activeSplits.names then
				local segment = state[method].timer
				local bestSegment = activeSplits.sumOfBest[method].segments[split]
				local deltaSegment = segment - activeSplits.personalBest[method].segments[split]
				local total = segment + (activeRun[method].totals[split - 1] or 0)
				local deltaTotal = total - activeSplits.personalBest[method].totals[split]
				
				-- Manage current split and stopwatch
				WS.timer.stopwatch:TemplateText(total)
				
				if #activeRun.loadless.segments < activeLayout.splits.segments * 0.5 + 0.1 then
					split = split
				elseif #activeRun.loadless.segments > #activeSplits.names - activeLayout.splits.segments then
					split = activeLayout.splits.segments - (#activeSplits.names - #activeRun.loadless.segments) + 1
				else
					split = math.ceil(activeLayout.splits.segments * 0.5 + 0.1)
				end
				
				local frame = WS.splits["split" .. split].delta
				
				if bestSegment == huge then
					frame:SetText("")
					WS.timer.stopwatch:SetTextColor(HexToRGBA(activeLayout.timer.fontColor))
				elseif deltaTotal >= 0 then
					frame:SetText("+" .. SecToTime(deltaTotal, activeLayout.splits.precision))
					
					if deltaSegment < 0 then
						frame:SetTextColor(0.95, 0.35, 0.35, 1) -- Light red
						WS.timer.stopwatch:SetTextColor(0.95, 0.35, 0.35, 1)
					else
						frame:SetTextColor(0.95, 0, 0, 1) -- Dark red
						WS.timer.stopwatch:SetTextColor(0.95, 0, 0, 1)
					end
				else
					if segment >= bestSegment then
						frame:SetText("-" .. SecToTime(deltaTotal, activeLayout.splits.precision))
					end
					
					if deltaSegment < 0 then
						frame:SetTextColor(0, 0.95, 0, 1) -- Dark green
						WS.timer.stopwatch:SetTextColor(0, 0.95, 0, 1)
					else
						frame:SetTextColor(0.35, 0.95, 0.35, 1) -- Light green
						WS.timer.stopwatch:SetTextColor(0.35, 0.95, 0.35, 1)
					end
				end
			end
		end
	else
		WS.timer.stopwatch:TemplateText(0)
		WS.timer.stopwatch:SetTextColor(HexToRGBA(activeLayout.timer.fontColor))
	end
	
	-- Data
	WS.data = TemplateFrame(WS.data, WS, "data")
	activeLayout.data.enabled = false
	-- TODO
	
	-- Controls
	WS.controls = TemplateFrame(WS.controls, WS, "controls", nil, true)
	
	WS.controls.start = TemplateFrame(WS.start, WS.controls, "controls", "Button")
	WS.controls.stop = TemplateFrame(WS.stop, WS.controls, "controls", "Button")
	WS.controls.split = TemplateFrame(WS.split, WS.controls, "controls", "Button")
	WS.controls.reset = TemplateFrame(WS.reset, WS.controls, "controls", "Button")
	WS.controls.skip = TemplateFrame(WS.skip, WS.controls, "controls", "Button")
	WS.controls.undo = TemplateFrame(WS.undo, WS.controls, "controls", "Button")
	
	-- Position buttons based on timer size
	local limit = math.max(1, math.floor(activeLayout.timer.height / activeLayout.controls.height))
	
	for a, b in ipairs({"start", "split", "stop", "reset", "skip", "undo"}) do
		WS.controls[b]:SetPoint("TOPLEFT",
				math.floor((a - 1) / limit) * activeLayout.controls.width,
				-1 * ((a - 1) % limit) * activeLayout.controls.height)
	end
	
	WS.controls.start:SetNormalTexture("Interface\\Addons\\WoWSplit\\Assets\\Icons\\start.ttf")
	WS.controls.stop:SetNormalTexture("Interface\\Addons\\WoWSplit\\Assets\\Icons\\stop.ttf")
	WS.controls.split:SetNormalTexture("Interface\\Addons\\WoWSplit\\Assets\\Icons\\split.ttf")
	WS.controls.reset:SetNormalTexture("Interface\\Addons\\WoWSplit\\Assets\\Icons\\reset.ttf")
	WS.controls.skip:SetNormalTexture("Interface\\Addons\\WoWSplit\\Assets\\Icons\\skip.ttf")
	WS.controls.undo:SetNormalTexture("Interface\\Addons\\WoWSplit\\Assets\\Icons\\undo.ttf")
	
	-- TODO; highlight backdrop on click
	
	WS.controls.start:SetScript("OnClick", WoWSplit.Start)
	WS.controls.stop:SetScript("OnClick", WoWSplit.Stop)
	WS.controls.split:SetScript("OnClick", WoWSplit.Split)
	WS.controls.reset:SetScript("OnClick", WoWSplit.Reset)
	WS.controls.skip:SetScript("OnClick", WoWSplit.Skip)
	WS.controls.undo:SetScript("OnClick", WoWSplit.Undo)
	
	-- Vertical and horizontal orientation
	local enabledFrames = {}
	
	for a, b in ipairs({"title", "splits", "timer", "data", "controls"}) do
		if activeLayout[b].enabled then
			enabledFrames[#enabledFrames + 1] = b
		end
	end
	
	if #enabledFrames == 0 then return end
	WS[enabledFrames[1]]:SetPoint("TOPLEFT")
	
	if activeLayout.vertical then
		local largest, sum = WS[enabledFrames[1]]:GetSize()
		
		for a = 2, #enabledFrames do
			local frame = WS[enabledFrames[a]]
			frame:SetPoint("TOP", WS[enabledFrames[a - 1]], "BOTTOM", 0, activeLayout.spacing)
			
			sum = sum + frame:GetHeight()
			largest = math.max(largest, frame:GetWidth())
		end
		
		WS:SetSize(largest, sum - activeLayout.spacing)
	else
		local sum, largest = WS[enabledFrames[1]]:GetSize()
		
		for a = 2, #enabledFrames do
			local frame = WS[enabledFrames[a]]
			frame:SetPoint("LEFT", WS[enabledFrames[a - 1]], "RIGHT", activeLayout.spacing, 0)
			
			sum = sum + frame:GetWidth()
			largest = math.max(largest, frame:GetHeight())
		end
		
		WS:SetSize(sum - activeLayout.spacing, largest)
	end
	
	if activeLayout.timer.enabled and activeLayout.controls.enabled then
		WS.controls:SetPoint("TOPLEFT", WS.timer)
	else
		WS.controls:Hide()
	end
	
	-- Settings
	WS.settings = TemplateFrame(WS.settings, WS, "settings", "ScrollFrame", true)
	
	if string.find(activeLayout.anchor, "TOP") then
		WS.settings:SetPoint("TOP", WS, "BOTTOM")
	elseif string.find(activeLayout.anchor, "BOTTOM") then
		WS.settings:SetPoint("BOTTOM", WS, "TOP")
	elseif string.find(activeLayout.anchor, "LEFT") then
		WS.settings:SetPoint("TOPLEFT", WS, "TOPRIGHT")
	else
		WS.settings:SetPoint("TOPRIGHT", WS, "TOPLEFT")
	end
	
	WS:SetScript("OnMouseDown", function(self, button)
		if button ~= "RightButton" then return end
		activeLayout.settings.enabled = not activeLayout.settings.enabled
		LoadFrames()
	end)
	
	WS.settings.scroll = TemplateFrame(WS.settings.scroll, WS.settings, "settings")
	local scroll = WS.settings.scroll
	scroll:SetPoint("TOP")
	WS.settings:SetScrollChild(scroll)
	
	-- Menu title
	scroll.label = scroll:TemplateFontString(scroll.label)
	scroll.label:SetPoint("TOP")
	scroll.label:SetText("Settings")
	
	-- Splits file
	local position = activeLayout.settings.padding * -1 - activeLayout.settings.lineHeight * 1.5 -
		activeLayout.settings.spacing
	
	scroll.file = scroll.file or {}
	
	scroll.file.key = scroll:TemplateFontString(scroll.file.key)
	scroll.file.key:SetPoint("TOPLEFT", activeLayout.settings.padding, position)
	scroll.file.key:SetText("> splitsFile <")
	
	scroll.file.value = TemplateFrame(scroll.file.value, scroll, "settings", "EditBox")
	scroll.file.value:SetPoint("TOPRIGHT", activeLayout.settings.padding * -1, position)
	scroll.file.value:SetSize((activeLayout.settings.width - activeLayout.settings.padding * 2) * 0.5,
			activeLayout.settings.lineHeight)
	scroll.file.value:SetText(settings.splitsIndex)
	
	scroll.file.value:SetScript("OnEditFocusLost", function(self)
		settings.splitsIndex = self:GetText()
		
		if not splits[settings.splitsIndex] then
			splits[settings.splitsIndex] = CreateSplits()
		end
		
		activeSplits = splits[settings.splitsIndex]
		LoadFrames()
	end)
	
	position = position - activeLayout.settings.lineHeight - activeLayout.settings.spacing
	
	scroll.quantity = scroll.quantity or {}
	
	scroll.quantity.key = scroll:TemplateFontString(scroll.quantity.key)
	scroll.quantity.key:SetPoint("TOPLEFT", activeLayout.settings.padding, position)
	scroll.quantity.key:SetText("> #_splits <")
	
	scroll.quantity.value = TemplateFrame(scroll.quantity.value, scroll, "settings", "EditBox")
	scroll.quantity.value:SetPoint("TOPRIGHT", activeLayout.settings.padding * -1, position)
	scroll.quantity.value:SetSize((activeLayout.settings.width - activeLayout.settings.padding * 2) * 0.5,
			activeLayout.settings.lineHeight)
	scroll.quantity.value:SetText(#activeSplits.names)
	
	scroll.quantity.value:SetScript("OnEditFocusLost", function(self)
		local quantity = self:GetText()
		
		-- Delete entries
		for a = quantity + 1, #activeSplits.names do
			activeSplits.names[a] = nil
			
			activeSplits.personalBest.loadless.segments[a] = nil
			activeSplits.personalBest.loadless.totals[a] = nil
			activeSplits.personalBest.loads.segments[a] = nil
			activeSplits.personalBest.loads.totals[a] = nil
			
			activeSplits.sumOfBest.loadless.segments[a] = nil
			activeSplits.sumOfBest.loadless.totals[a] = nil
			activeSplits.sumOfBest.loads.segments[a] = nil
			activeSplits.sumOfBest.loads.totals[a] = nil
		end
		
		-- Add entries
		for a = #activeSplits.names, quantity do
			activeSplits.names[a] = "Split " .. a
			
			activeSplits.personalBest.loadless.segments[a] = huge
			activeSplits.personalBest.loadless.totals[a] = huge
			activeSplits.personalBest.loads.segments[a] = huge
			activeSplits.personalBest.loads.totals[a] = huge
			
			activeSplits.sumOfBest.loadless.segments[a] = huge
			activeSplits.sumOfBest.loadless.totals[a] = huge
			activeSplits.sumOfBest.loads.segments[a] = huge
			activeSplits.sumOfBest.loads.totals[a] = huge
		end
		
		LoadFrames()
	end)
	
	position = position - activeLayout.settings.lineHeight * 1.5 - activeLayout.settings.spacing
	
	-- TODO; mulitple layout configs
	
	-- Display each setting
	for a, b in pairs(activeLayout) do
		if type(b) ~= "table" then
			-- Option
			scroll[a] = scroll[a] or {}
			
			scroll[a].key = scroll:TemplateFontString(scroll[a].key)
			scroll[a].key:SetPoint("TOPLEFT", activeLayout.settings.padding, position)
			scroll[a].key:SetText(a)
			
			scroll[a].value = TemplateFrame(scroll[a].value, scroll, "settings", "EditBox")
			scroll[a].value:SetPoint("TOPRIGHT", activeLayout.settings.padding * -1, position)
			scroll[a].value:SetSize((activeLayout.settings.width - activeLayout.settings.padding * 2) * 0.5,
					activeLayout.settings.lineHeight)
			scroll[a].value:SetText(tostring(b))
			
			scroll[a].value:SetScript("OnEditFocusLost", function(self)
				local text = self:GetText()
				text = tonumber(text) or text
				
				if text == "true" then
					text = true
				elseif text == "false" then
					text = false
				end
				
				activeLayout[a] = text
				LoadFrames()
			end)
			
			position = position - activeLayout.settings.lineHeight - activeLayout.settings.spacing
		end
	end
	
	position = position - activeLayout.settings.lineHeight * 0.5 - activeLayout.settings.spacing
	
	for a, b in pairs(activeLayout) do
		if type(b) == "table" then
			-- Category
			scroll[a] = scroll[a] or {}
			
			scroll[a].label = scroll:TemplateFontString(scroll[a].label)
			scroll[a].label:SetPoint("TOPLEFT", activeLayout.settings.padding, position)
			scroll[a].label:SetText(a:upper())
				
			position = position - activeLayout.settings.lineHeight - activeLayout.settings.spacing
			
			for c, d in pairs(b) do
				-- Option
				scroll[a][c] = scroll[a][c] or {}
				
				scroll[a][c].key = scroll:TemplateFontString(scroll[a][c].key)
				scroll[a][c].key:SetPoint("TOPLEFT", activeLayout.settings.padding * 4, position)
				scroll[a][c].key:SetText(c)
				
				scroll[a][c].value = TemplateFrame(scroll[a][c].value, scroll, "settings", "EditBox")
				scroll[a][c].value:SetPoint("TOPRIGHT", activeLayout.settings.padding * -1, position)
				scroll[a][c].value:SetSize((activeLayout.settings.width - activeLayout.settings.padding * 5) * 0.5,
						activeLayout.settings.lineHeight)
				scroll[a][c].value:SetText(tostring(d))
				
				scroll[a][c].value:SetScript("OnEditFocusLost", function(self)
					local text = self:GetText()
					text = tonumber(text) or text
					
					if text == "true" then
						text = true
					elseif text == "false" then
						text = false
					end
					
					activeLayout[a][c] = text
					LoadFrames()
				end)
				
				position = position - activeLayout.settings.lineHeight - activeLayout.settings.spacing
			end
			
			position = position - activeLayout.settings.lineHeight * 0.5 - activeLayout.settings.spacing
		end
	end
	
	scroll:SetSize(activeLayout.settings.width, position * -1)
	position = position * -1 - activeLayout.settings.height
	
	WS.settings:SetScript("OnMouseWheel", function(self, delta)
		self:SetVerticalScroll(math.max(0, math.min(position, self:GetVerticalScroll() - delta * 64)))
	end)
end

for a, b in pairs(WoWSplit) do
	hooksecurefunc(WoWSplit, a, LoadFrames)
end

--[[------------------------------------------------------------------------------------------------
	Initialize and update timer
--]]------------------------------------------------------------------------------------------------

WS:SetScript("OnEvent", function(self)
	self:UnregisterEvent("ADDON_LOADED")
	
	--WoWSplit_SavedVariable = nil
	
	if WoWSplit_SavedVariable then
		-- Load any saved data from disk
		splits = WoWSplit_SavedVariable.splits
		layouts = WoWSplit_SavedVariable.layouts
		settings = WoWSplit_SavedVariable.settings
		state = WoWSplit_SavedVariable.state
	else
		-- Do one-time setup
		WoWSplit_SavedVariable = {}
		
		splits = {CreateSplits()}
		layouts = {CreateLayout()}
		
		settings = {}
		settings.splitsIndex = 1
		settings.layoutIndex = 1
		settings.open = true
		settings.menu = 1
		settings.method = "loadless"
		
		state = {}
		state.running = false
		state.loading = false
		state.loadless = {}
		state.loadless.begin = nil
		state.loadless.timer = nil
		state.loads = {}
		state.loads.begin = nil
		state.loads.timer = nil
	end
	
	activeSplits = splits[settings.splitsIndex]
	activeRun = activeSplits.runs[#activeSplits.runs]
	activeLayout = layouts[settings.layoutIndex]
	
	-- Initialize the UI
	LoadFrames()
	
	-- Detect loading
	self:SetScript("OnEvent", function(_, event)
		if event == "LOADING_SCREEN_DISABLED" then
			if not state.loading then return end
			WoWSplit:Start()
			state.loading = false
		else
			-- Loading screen or logout
			if state.running then
				state.loading = true
				WoWSplit:Stop()
			end
			
			-- Save data to disk
			if event == "PLAYER_LOGOUT" then
				WoWSplit_SavedVariable.splits = splits
				WoWSplit_SavedVariable.layouts = layouts
				WoWSplit_SavedVariable.settings = settings
				WoWSplit_SavedVariable.state = state
			end
		end
	end)
	
	self:RegisterEvent("LOADING_SCREEN_ENABLED")
	self:RegisterEvent("LOADING_SCREEN_DISABLED")
	self:RegisterEvent("PLAYER_LOGOUT")
	
	local method
	local timestamp
	local split
	local segment
	local bestSegment
	local deltaSegment
	local total
	local deltaTotal
	local frame
	
	-- Update timers
	self:SetScript("OnUpdate", function()
		if not state.running then return end
		
		timestamp = GetTimePreciseSec()
		method = settings.method
		split = #activeRun[method].segments + 1
		
		-- Timing calculations
		segment = timestamp - state[method].timer
		bestSegment = activeSplits.sumOfBest[method].segments[split]
		deltaSegment = segment - activeSplits.personalBest[method].segments[split]
		total = timestamp - state[method].begin
		deltaTotal = total - activeSplits.personalBest[method].totals[split]
		
		-- Manage current split and stopwatch
		self.timer.stopwatch:TemplateText(total)
		
		if #activeRun.loadless.segments < activeLayout.splits.segments * 0.5 + 0.1 then
			split = split
		elseif #activeRun.loadless.segments > #activeSplits.names - activeLayout.splits.segments then
			split = activeLayout.splits.segments - (#activeSplits.names - #activeRun.loadless.segments) + 1
		else
			split = math.ceil(activeLayout.splits.segments * 0.5 + 0.1)
		end
		
		frame = self.splits["split" .. split].delta
		
		if bestSegment == huge then
			frame:SetText("")
			self.timer.stopwatch:SetTextColor(HexToRGBA(activeLayout.timer.fontColor))
		elseif deltaTotal >= 0 then
			frame:SetText("+" .. SecToTime(deltaTotal, activeLayout.splits.precision))
			
			if deltaSegment < 0 then
				frame:SetTextColor(0.95, 0.35, 0.35, 1) -- Light red
				self.timer.stopwatch:SetTextColor(0.95, 0.35, 0.35, 1)
			else
				frame:SetTextColor(0.95, 0, 0, 1) -- Dark red
				self.timer.stopwatch:SetTextColor(0.95, 0, 0, 1)
			end
		else
			if segment >= bestSegment then
				frame:SetText("-" .. SecToTime(deltaTotal, activeLayout.splits.precision))
			end
			
			if deltaSegment < 0 then
				frame:SetTextColor(0, 0.95, 0, 1) -- Dark green
				self.timer.stopwatch:SetTextColor(0, 0.95, 0, 1)
			else
				frame:SetTextColor(0.35, 0.95, 0.35, 1) -- Light green
				self.timer.stopwatch:SetTextColor(0.35, 0.95, 0.35, 1)
			end
		end
	end)
	
	self:SetShown(settings.open)
end)

WS:RegisterEvent("ADDON_LOADED")

--[[------------------------------------------------------------------------------------------------
	Chat Commands
--]]------------------------------------------------------------------------------------------------

-- Toggle the addon's visibility
local function WoWSplit_Slash()
	WS:SetShown(not WS:IsVisible())
end

SlashCmdList["WoWSplit"] = WoWSplit_Slash

SLASH_WoWSplit1 = "/wowsplit"
SLASH_WoWSplit2 = "/ws"
