local musicratio = 1
local intervalbulllllshieeeet = nil
local widthPlayer = capWideScale(280, 420)
local heightPlayer = 4
local hidth = 20
local yeet
local onOff = true

local ChordDensityThing =
{
	SeekPositionX = capWideScale(165, 220),
	SeektextPosX = 295,
	SeekPosY = 380
}

local function UpdatePreviewPos(self)
	local scrnm = SCREENMAN:GetTopScreen():GetName()
	local allowedScreens = {
		ScreenSelectMusic = true,
		ScreenNetSelectMusic = true
	}
	
	if allowedScreens[scrnm] == true then
		local pos = SCREENMAN:GetTopScreen():GetSampleMusicPosition() / musicratio
        self:GetChild("Pos"):zoomto(math.min(pos,widthPlayer), heightPlayer)
        self:queuecommand("Highlight")
	end
end

local t = Def.ActorFrame {
	Name = "playerThing",
	InitCommand=function(self)
        self:x(capWideScale(165,220)):y(SCREEN_BOTTOM - 4)
        self:SetUpdateFunction(UpdatePreviewPos)
	end,
	CurrentStepsChangedMessageCommand = function(self)
		if GAMESTATE:GetCurrentSong() then
            musicratio = (GAMESTATE:GetCurrentSteps():GetFirstSecond() / getCurRateValue() + GAMESTATE:GetCurrentSteps():GetLengthSeconds()) / widthPlayer * getCurRateValue()
		end
	end,
	ChartPreviewOnMessageCommand=function(self)
		self:SetUpdateFunction(UpdatePreviewPos)
	end,
    Def.Quad {
		Name = "PosBG",
		InitCommand = function(self)
			self:zoomto(widthPlayer, 12):halign(0):diffusealpha(0):draworder(900)
		end,
		HighlightCommand = function(self)
			if isOver(self) and GAMESTATE:GetCurrentSteps() ~= nil then
				local seek = self:GetParent():GetChild("Seek")
				seek:visible(true)
				seek:x(INPUTFILTER:GetMouseX() - self:GetParent():GetX())
			else
				self:GetParent():GetChild("Seek"):visible(false)
			end
		end
	},
    Def.Quad {
		Name = "mhmyep",
		InitCommand = function(self)
			self:zoomto(widthPlayer, 4):diffuse(Saturation(getMainColor("highlight"), 0.2)):halign(0):draworder(900)
		end
	},
    Def.Quad {
		Name = "Pos",
		InitCommand = function(self)
			self:zoomto(0, heightPlayer):diffuse(getMainColor("highlight")):halign(0):draworder(900)
		end
	},
	LoadFont("Common Large")..{
		Name = "length",
		InitCommand = function(self)
			self:xy(widthPlayer,-12):zoom(0.2):halign(1)
			self:settext("")
		end,
		HighlightCommand = function(self)
			if GAMESTATE:GetCurrentSteps() ~= nil then
				local totalSongLength = GAMESTATE:GetCurrentSteps():GetLengthSeconds()
				local percentElapsed = SCREENMAN:GetTopScreen():GetSampleMusicPosition() / musicratio
				local totalSongElapsed = (percentElapsed / widthPlayer) * totalSongLength
				self:settext(SecondsToMMSS(totalSongElapsed) .. "/" .. SecondsToMMSS(totalSongLength))
			end
		end
	},
	UIElements.SpriteButton(1, 1, THEME:GetPathG("", "mhmyep/rewindPlayer")) .. {
		Name = "Rewind",
		InitCommand = function(self)
			self:xy(0,-12):zoomto(10,10):halign(0)
		end,
		MouseOverCommand = function(self)
			self:diffusealpha(0.4)
		end,
		MouseOutCommand = function(self)
			self:diffusealpha(1)
		end,
		MouseDownCommand = function(self, params)
			if params.event == "DeviceButton_left mouse button" then
				SCREENMAN:GetTopScreen():SetSampleMusicPosition(0)
			end
		end
	},
	UIElements.SpriteButton(1, 1, THEME:GetPathG("", "mhmyep/randomSong")) .. {
		Name = "Random",
		InitCommand = function(self)
			self:xy(30,-12):zoomto(15,15):halign(0)
		end,
		MouseOverCommand = function(self)
			self:diffusealpha(0.4)
		end,
		MouseOutCommand = function(self)
			self:diffusealpha(1)
		end,
		MouseDownCommand = function(self, params)
			if params.event == "DeviceButton_left mouse button" then
				local w = SCREENMAN:GetTopScreen():GetMusicWheel()

				if INPUTFILTER:IsShiftPressed() and self.lastlastrandom ~= nil then
					if w:SelectSong(self.lastlastrandom) then
						return
					end
				end

				local t = w:GetSongs()
				if #t == 0 then return end
				local random_song = t[math.random(#t)]
				w:SelectSong(random_song)
				self.lastlastrandom = self.lastrandom
				self.lastrandom = random_song
			end
		end
	},
	UIElements.SpriteButton(1, 1, nil) .. {
		Name = "PauseContinueMusic",
		InitCommand = function(self)
			self:Load(THEME:GetPathG("", "mhmyep/pause"))
			self:xy(15,-12):zoomto(10,10):halign(0)
		end,
		somethingHappenedCommand = function(self)
			if SCREENMAN:GetTopScreen():IsSampleMusicPaused() then
				self:Load(THEME:GetPathG("", "mhmyep/continue"))
			else
				self:Load(THEME:GetPathG("", "mhmyep/pause"))
			end
		end,
		MouseOverCommand = function(self)
			self:diffusealpha(0.4)
		end,
		MouseOutCommand = function(self)
			self:diffusealpha(1)
		end,
		CurrentSongChangedMessageCommand = function(self)
			self:Load(THEME:GetPathG("", "mhmyep/pause"))
		end,
		MusicPauseToggledMessageCommand = function(self)
			self:queuecommand("somethingHappened")
		end,
		PreviewMusicStartedMessageCommand = function(self)
			self:queuecommand("somethingHappened")
		end,
		MouseDownCommand = function(self, params)
			if params.event == "DeviceButton_left mouse button" then
				SCREENMAN:GetTopScreen():PauseSampleMusic()
				MESSAGEMAN:Broadcast("MusicPauseToggled")
			end
		end
	},
}

t[#t + 1] = UIElements.QuadButton(1, 1) .. {
	Name = "Seek",
	InitCommand = function(self)
		self:zoomto(2, 14):diffuse(getMainColor("highlight")):halign(0.5):draworder(1100):diffusealpha(0)
	end,
	MouseDownCommand = function(self, params)
		if params.event == "DeviceButton_left mouse button" then
			SCREENMAN:GetTopScreen():SetSampleMusicPosition((self:GetX()) * musicratio )
		end
	end
}

return t