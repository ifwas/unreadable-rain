
local hoverAlpha = 0.6

local t = Def.ActorFrame {}

local frameWidth = 275
local frameHeight = 20
local frameX = SCREEN_CENTER_X + capWideScale(9,40)
local frameY = capWideScale(57,60)
local frameZoom = capWideScale(0.2,0.25)
local framedzom = capWideScale(0.19,0.23)

local sortTable = {
	SortOrder_Group = THEME:GetString("SortOrder", "Group"),
	SortOrder_Title = THEME:GetString("SortOrder", "Title"),
	SortOrder_BPM = THEME:GetString("SortOrder", "BPM"),
	SortOrder_TopGrades = THEME:GetString("SortOrder", "TopGrades"),
	SortOrder_Artist = THEME:GetString("SortOrder", "Artist"),
	SortOrder_Genre = THEME:GetString("SortOrder", "Genre"),
	SortOrder_ModeMenu = THEME:GetString("SortOrder", "ModeMenu"),
	SortOrder_Length = THEME:GetString("SortOrder", "Length"),
	SortOrder_DateAdded = THEME:GetString("SortOrder", "DateAdded"),
	SortOrder_Favorites = THEME:GetString("SortOrder", "Favorites"),
	SortOrder_Overall = THEME:GetString("SortOrder", "Overall"),
	SortOrder_Stream = THEME:GetString("SortOrder", "Stream"),
	SortOrder_Jumpstream = THEME:GetString("SortOrder", "Jumpstream"),
	SortOrder_Handstream = THEME:GetString("SortOrder", "Handstream"),
	SortOrder_Stamina = THEME:GetString("SortOrder", "Stamina"),
	SortOrder_JackSpeed = THEME:GetString("SortOrder", "JackSpeed"),
	SortOrder_Chordjack = THEME:GetString("SortOrder", "Chordjack"),
	SortOrder_Technical = THEME:GetString("SortOrder", "Technical"),
	SortOrder_Author = THEME:GetString("SortOrder", "Author"),
	SortOrder_Ungrouped = THEME:GetString("SortOrder", "Ungrouped")
}

local translated_info = {
	Sort = THEME:GetString("SortOrder", "SortWord")
}

local characterThreeshold = capWideScale(27,31)

local group_rand = ""
t[#t + 1] = UIElements.TextToolTip(1, 1, "Common Large") .. {
	Name="rando",
	InitCommand = function(self)
		self:xy(frameX, frameY + 5):halign(0):zoom(frameZoom)
	end,
	BeginCommand = function(self)
		self:queuecommand("Set")
	end,
	SetCommand = function(self)
		self:finishtweening()
		self:zoom(frameZoom)
		local sort = GAMESTATE:GetSortOrder()
		local song = GAMESTATE:GetCurrentSong()
		if sort == nil then
			self:settextf("%s: ", translated_info["Sort"])
		elseif sort == "SortOrder_Group" and song ~= nil then
			group_rand = song:GetGroupName()

			if #group_rand > characterThreeshold then 
				self:zoom(frameZoom * (characterThreeshold / #group_rand))
			end
			self:settext(group_rand)
		else
			self:settextf("%s: %s", translated_info["Sort"], sortTable[sort])
			group_rand = ""
		end
	end,
	SortOrderChangedMessageCommand = function(self)
		self:queuecommand("Set")
	end,
	CurrentSongChangedMessageCommand = function(self)
		self:playcommand("Set")
	end,
	MouseDownCommand = function(self, params)
		if group_rand ~= "" and params.event == "DeviceButton_left mouse button" then
			local w = SCREENMAN:GetTopScreen():GetMusicWheel()

			if INPUTFILTER:IsShiftPressed() and self.lastlastrandom ~= nil then

				-- if the last random song wasnt filtered out, we can select it
				-- so end early after jumping to it
				if w:SelectSong(self.lastlastrandom) then
					return
				end
				-- otherwise, just pick a new random song
			end

			local t = w:GetSongsInGroup(group_rand)
			if #t == 0 then return end
			local random_song = t[math.random(#t)]
			w:SelectSong(random_song)
			self.lastlastrandom = self.lastrandom
			self.lastrandom = random_song
		end
	end,
	MouseOverCommand = function(self)
		if group_rand ~= "" then
			self:diffusealpha(hoverAlpha)
		end
	end,
	MouseOutCommand = function(self)
		if group_rand ~= "" then
			self:diffusealpha(1)
		end
	end,
	ProfileTabOffMessageCommand = function(self)
		ProfileActorFadeInOut(self, false)
	end,
	ProfileTabOnMessageCommand = function(self)
		ProfileActorFadeInOut(self, true)
	end
}

t[#t + 1] = LoadFont("Common Large").. {
	InitCommand = function(self)
		self:xy(frameX, frameY + capWideScale(18,19)):halign(0):zoom(framedzom):maxwidth((frameWidth - 40) / 0.35)
	end,
	BeginCommand = function(self)
		self:settext("")
		self:queuecommand("Set")
	end,
	SetCommand = function(self, params)
		local sort = GAMESTATE:GetSortOrder()
		local song = GAMESTATE:GetCurrentSong()
		if sort == "SortOrder_Group" and song ~= nil then
			local group = song:GetGroupName()
			local songCount = #SONGMAN:GetSongsInGroup(group)
			self:settextf("%s Songs *", songCount)
		else
			self:settext("")
		end
	end,
	SortOrderChangedMessageCommand = function(self)
		self:queuecommand("Set")
	end,
	CurrentSongChangedMessageCommand = function(self)
		self:playcommand("Set")
	end,
	ProfileTabOffMessageCommand = function(self)
		ProfileActorFadeInOut(self, false)
	end,
	ProfileTabOnMessageCommand = function(self)
		ProfileActorFadeInOut(self, true)
	end
}

t[#t + 1] = StandardDecorationFromFileOptional("BPMDisplay", "BPMDisplay")
t[#t + 1] = StandardDecorationFromFileOptional("BPMLabel", "BPMLabel")

return t
