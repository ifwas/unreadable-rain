local searchstring = ""
local frameX = 10
local frameY = 40
local active = false
local whee
local lastsearchstring = ""
local instantSearch = themeConfig:get_data().global.InstantSearch
local IgnoreTabInput = themeConfig:get_data().global.IgnoreTabInput


local translated_info = {
	Active = THEME:GetString("TabSearch", "Active"),
	Complete = THEME:GetString("TabSearch", "Complete"),
	ExplainStart = THEME:GetString("TabSearch", "ExplainStart"),
	ExplainBack = THEME:GetString("TabSearch", "ExplainBack"),
	ExplainDel = THEME:GetString("TabSearch", "ExplainDelete"),
	ExplainLimit = THEME:GetString("TabSearch", "ExplainLimitation"),
	ExplainNumInput = THEME:GetString("TabSearch", "ExplainNumInput"),
	ExplainSuperSearch = THEME:GetString("TabSearch","ExplainSuperSearch"),
}

--stuff for slider debug
local quadxpos = SCREEN_CENTER_X
local quadypos = SCREEN_CENTER_Y

local filterCategoryLimits = {
        { 0, 40 },  -- Overall
        { 0, 40 },  -- Stream
        { 0, 40 },  -- Jumpstream
        { 0, 40 },  -- Handstream
        { 0, 40 },  -- Stamina
        { 0, 40 },  -- JackSpeed
        { 0, 40 },  -- Chordjacks
        { 0, 40 },  -- Technical
        { 0, 600 },  -- Length (in seconds)
        { 85, 100 }, -- Percent
}

--something something to set things nice in the c++ side of things, or at least that's what the rebirth guy says 
local function setSSFilter(ss, lb, ub)
    FILTERMAN:SetSSFilter(lb, ss, 0)
    FILTERMAN:SetSSFilter(ub, ss, 1)
end

--same thing but to get values ?
local function getSSFilter(ss)
    return FILTERMAN:GetSSFilter(ss, 0), FILTERMAN:GetSSFilter(ss, 1)
end

local function dragqueen(actor, params)
	local localX = clamp(params.MouseX, 0, SCREEN_WIDTH)
	local localY = clamp(params.MouseY, 0, SCREEN_HEIGHT)
	quadxpos = localX
	quadypos = localY
	actor:xy(localX, localY)
end
	

local grabbingQuad = nil

--this is the stuff that's on the frame (filters)
local t = Def.ActorFrame {
	BeginCommand = function(self)
		self:visible(false)
		self:queuecommand("Set")
		whee = SCREENMAN:GetTopScreen():GetMusicWheel()
	end,
	OffCommand = function(self)
		self:smooth(0.2):diffusealpha(0)
		self:sleep(0.04):queuecommand("Invis")
	end,
	InvisCommand= function(self)
		self:visible(false)
	end,
	OnCommand = function(self)
		self:smooth(0.2):diffusealpha(1)
	end,
	SetCommand = function(self)
		self:finishtweening()
		if getTabIndex() == 3 then
			MESSAGEMAN:Broadcast("BeginningSearch")
			self:visible(true)
			self:queuecommand("On")
			active = true
			whee:Move(0)
			SCREENMAN:set_input_redirected(PLAYER_1, true)
			MESSAGEMAN:Broadcast("RefreshSearchResults")
			FILTERMAN:HelpImTrappedInAChineseFortuneCodingFactory(true)
		else
			self:queuecommand("Off")
			active = false
			SCREENMAN:set_input_redirected(PLAYER_1, false)
			FILTERMAN:HelpImTrappedInAChineseFortuneCodingFactory(false)
		end
	end,
	TabChangedMessageCommand = function(self)
		self:queuecommand("Set")
	end,
	LoadFont("Common Large") .. {
		InitCommand = function(self)
			self:xy(frameX - 3, frameY + 4):zoom(0.375):halign(0):maxwidth(470)
		end,
		SetCommand = function(self)
			if active then
				self:settextf("%s:", translated_info["Active"])
				self:diffuse(getGradeColor("Grade_Tier10"))
			elseif not active and searchstring ~= "" then
				self:settext(translated_info["Complete"])
				self:diffuse(getGradeColor("Grade_Tier04"))
			else
				self:settext("")
			end
		end,
		UpdateStringMessageCommand = function(self)
			self:queuecommand("Set")
		end
	},
	LoadFont("Common Large") .. {
		InitCommand = function(self)
			self:xy(frameX - 3, frameY + 18):zoom(0.175):halign(0):maxwidth(470):diffusealpha(0.4)
		end,
		SetCommand = function(self)
			if active then
				self:settext("watcha' looking for?")
			else
				self:settext("")
			end
		end,
		UpdateStringMessageCommand = function(self)
			self:queuecommand("Set")
		end
	},

	--[[
	LoadFont("Common Large") .. {
		InitCommand = function(self)
			self:xy(frameX - 3, frameY + 40):zoom(0.175):halign(0):maxwidth(470):diffusealpha(0.4)
		end,
		SetCommand = function(self)
			if active then
				self:settext(quadxpos)
			else
				self:settext("")
			end
		end,
	},
	]]
}


local sl = Def.ActorFrame{
	Name = "slindingQuad",
	UIElements.QuadButton(1, 1) .. {
		InitCommand = function(self)
			self:xy(quadxpos, quadypos):zoomto(50,50)
		end,
		MouseDownCommand = function(self, params)
			if params.event ~= "DeviceButton_left mouse button" then return end

			if grabbedDot == nil then
				local localX = clamp(params.MouseX, 0, SCREEN_WIDTH)
				local localY = clamp(params.MouseY, 0, SCREEN_HEIGHT)
				quadxpos = localX
				quadypos = localY

				self:xy(localX, localY)
			end
		end,
		MouseHoldCommand = function(self, params)
			if params.event ~= "DeviceButton_left mouse button" then return end

			if grabbingQuad ~= nil  then 
				dragqueen(self, params)
			end
		end,
		MouseClickCommand = function(self, params)
			if params.event ~= "DeviceButton_left mouse button" then return end
			grabbingQuad = false
		end,
		MouseReleaseCommand = function(self, params)
			if params.event ~= "DeviceButton_left mouse button" then return end
			grabbingQuad = false
		end,
		
	}
}

--t[#t + 1] = sl

return t
