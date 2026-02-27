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
		else
			self:queuecommand("Off")
			active = false
			SCREENMAN:set_input_redirected(PLAYER_1, false)
		end
	end,
	TabChangedMessageCommand = function(self)
		self:queuecommand("Set")
	end,
	LoadFont("Common Large") .. {
		InitCommand = function(self)
			self:xy(frameX, frameY):zoom(0.3):halign(0):maxwidth(470)
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
}

return t
