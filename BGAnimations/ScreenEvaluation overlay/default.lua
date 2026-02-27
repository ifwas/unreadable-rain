local t = Def.ActorFrame {}

local basePath = PROFILEMAN:GetProfileDir(1)
local saveFile = basePath .. "lastfmstr.txt"
local str

--Group folder name
local frameWidth = 280
local frameHeight = 20
local frameX = SCREEN_WIDTH - 5
local frameY = 20



t[#t + 1] = LoadActor("../_PlayerInfo")

translated_info = {
	Title = THEME:GetString("ScreenEvaluation", "Title"),
	Replay = THEME:GetString("ScreenEvaluation", "ReplayTitle")
}

--cdtitle
t[#t + 1] = UIElements.SpriteButton(1, 1, nil) .. {
	Texture= GAMESTATE:GetCurrentSong():GetCDTitlePath(),
	InitCommand=function(self)
		self:xy(frameX - frameWidth + 20, 150):wag():effectmagnitude(0,0,5)

		local height = self:GetHeight()
		local width = self:GetWidth()

		if height >= 60 and width >= 75 then
			if height * (75 / 60) >= width then
				self:zoom(40 / height)
			else
				self:zoom(56.25 / width)
			end
		elseif height >= 60 then
			self:zoom(40 / height)
		elseif width >= 75 then
			self:zoom(56.25 / width)
		else
			self:zoom(0.75)
		end
	end,
	ToolTipCommand = function(self)
		if isOver(self) then
			local auth = GAMESTATE:GetCurrentSong():GetOrTryAtLeastToGetSimfileAuthor()
			TOOLTIP:SetText(auth)
			TOOLTIP:SwitchSide(false)
			TOOLTIP:Show()
		end
	end,
	MouseOverCommand = function(self)
		self:playcommand("ToolTip")
	end,
	MouseOutCommand = function(self)
		TOOLTIP:Hide()
	end,
}


--what the settext says
t[#t + 1] = LoadFont("Common Large") .. {
	InitCommand = function(self)
		self:xy(5, frameY):halign(0):valign(1):zoom(0.35):diffuse(getMainColor("positive"))
		self:settext("")
	end,
	OnCommand = function(self)
		local title = translated_info["Title"]
		local ss = SCREENMAN:GetTopScreen():GetStageStats()
		if not ss:GetLivePlay() then 
			title = translated_info["Replay"]
		else
			local songName = GAMESTATE:GetCurrentSong():GetDisplayMainTitle()
			local songArtist = GAMESTATE:GetCurrentSong():GetDisplayArtist()

			str = string.format("%s\n%s", songArtist, songName)
			File.Write(saveFile, str)
		end 
		local gamename = GAMESTATE:GetCurrentGame():GetName():lower()
		if gamename ~= "dance" then
			title = gamename:gsub("^%l", string.upper) .. " " .. title
		end
		self:settextf("%s:", title)
	end,
}



t[#t + 1] = LoadFont("Common Large") .. {
	InitCommand = function(self)
		self:xy(frameX, frameY):halign(1):zoom(0.35):maxwidth((frameWidth - 40) / 0.35):valign(1)
	end,
	BeginCommand = function(self)
		self:queuecommand("Set"):diffuse(getMainColor("positive"))
	end,
	SetCommand = function(self)
		local song = GAMESTATE:GetCurrentSong()
		if song ~= nil then
			self:settext(song:GetGroupName())
		end
	end
}

t[#t + 1] = LoadActor("../_cursor")

return t
