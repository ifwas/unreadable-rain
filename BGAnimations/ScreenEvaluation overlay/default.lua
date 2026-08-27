local t = Def.ActorFrame {}

translated_info = {
	Title = THEME:GetString("ScreenEvaluation", "Title"),
	Replay = THEME:GetString("ScreenEvaluation", "ReplayTitle")
}
local nonButtonColor = ColorMultiplier(getMainColor("positive"), 1.25)

t[#t + 1] = LoadActor("../_PlayerInfo")

local function UpdateTime(self)
	local year = Year()
	local month = MonthOfYear() + 1
	local day = DayOfMonth()
	local hour = Hour()
	local minute = Minute()
	local second = Second()
	self:GetChild("CurrentTime"):settextf("%04d-%02d-%02d %02d:%02d:%02d", year, month, day, hour, minute, second)

	local sessiontime = GAMESTATE:GetSessionTime()
	self:GetChild("SessionTime"):settextf("%s", SecondsToHHMMSS(sessiontime))
	self:diffuse(nonButtonColor)
end


--readded this bc the gradecounter breaks if the replay results text is not present
--thanks steffen
t[#t + 1] = LoadFont("Common Large") .. {
	InitCommand = function(self)
		self:xy(30, 32):halign(0):valign(1):zoom(0.35):diffuse(getMainColor("positive")):diffusealpha(0)
		self:settext("")
	end,
	OnCommand = function(self)
		local title = translated_info["Title"]
		local ss = SCREENMAN:GetTopScreen():GetStageStats()
		if not ss:GetLivePlay() then title = translated_info["Replay"] end
		local gamename = GAMESTATE:GetCurrentGame():GetName():lower()
		if gamename ~= "dance" then
			title = gamename:gsub("^%l", string.upper) .. " " .. title
		end
		self:settextf("%s:", title)

		--[[
		-- gradecounter logic
		-- only increment gradecounter on liveplay
		local liveplay = ss:GetLivePlay()
		if liveplay then
			local score = SCOREMAN:GetMostRecentScore()
			local wg = score:GetWifeGrade()
			if wg == "Grade_Tier01" or wg == "Grade_Tier02" or wg == "Grade_Tier03" or wg == "Grade_Tier04" then
				GRADECOUNTERSTORAGE:increment("AAAA")
			elseif wg == "Grade_Tier05" or wg == "Grade_Tier06" or wg == "Grade_Tier07" then
				GRADECOUNTERSTORAGE:increment("AAA")
			elseif wg == "Grade_Tier08" or wg == "Grade_Tier09" or wg == "Grade_Tier10" then
				GRADECOUNTERSTORAGE:increment("AA")
			elseif wg == "Grade_Tier11" or wg == "Grade_Tier12" or wg == "Grade_Tier13" then
				GRADECOUNTERSTORAGE:increment("A")
			end
		end
		-- gradecounter logic end]]
	end,
}

--Group folder name
local frameWidth = 280
local frameHeight = 20
local frameX = SCREEN_WIDTH - 5
local frameY = 15

t[#t + 1] = LoadFont("Common Large") .. {
	InitCommand = function(self)
		self:xy(frameX, frameY):halign(1):zoom(0.3):maxwidth((frameWidth - 40) / 0.3)
	end,
	BeginCommand = function(self)
		self:queuecommand("Set"):diffuse(getMainColor("positive")):diffusebottomedge(Saturation(getMainColor("highlight"), 0.2))
	end,
	SetCommand = function(self)
		local song = GAMESTATE:GetCurrentSong()
		if song ~= nil then
			self:settext(song:GetGroupName())
		end
	end
}

t[#t + 1] = Def.ActorFrame {
	InitCommand = function(self)
		self:SetUpdateFunction(UpdateTime)
	end,
	LoadFont("Common Normal") .. {
		Name = "CurrentTime",
		InitCommand = function(self)
			self:xy(SCREEN_WIDTH - 2,SCREEN_BOTTOM - 4):halign(1):valign(1):zoom(0.35)
		end
	},

	LoadFont("Common Normal") .. {
		Name = "SessionTime",
		InitCommand = function(self)
			self:xy(SCREEN_WIDTH - 2,SCREEN_BOTTOM - 14):halign(1):valign(1):zoom(0.35)
		end
	}
}

t[#t + 1] = LoadActor("../_cursor")

return t
