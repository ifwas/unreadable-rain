-- all the preview stuff should be var'd and used consistently -mina
local prevZoom = 0.65
local musicratio = 1
local NotefieldPosition = capWideScale(24,0)
local wodth = capWideScale(280, 400)
local hidth = 20
local yeet
local cd
local calcinfo


local ChordDensityThing =
{
	SeekPositionX = capWideScale(200, SCREEN_WIDTH / 5),
	SeektextPosX = 295,
	SeekPosY = 380
}


local yPos = Var("yPos")
local yPosReverse = Var("yPosReverse")
if not yPos then yPos = 55 end
if not yPosReverse then yPosReverse = 60 end

local translated_info = {
	Paused = THEME:GetString("ChartPreview", "Paused"),
	NPS = THEME:GetString("ChordDensityGraph", "NPS"),
	BPM = THEME:GetString("ChordDensityGraph", "BPM"),
}

local function UpdatePreviewPos(self)
	local scrnm = SCREENMAN:GetTopScreen():GetName()
	local allowedScreens = {
		ScreenSelectMusic = true,
		ScreenNetSelectMusic = true,
	}

	if allowedScreens[scrnm] == true then
		local pos = SCREENMAN:GetTopScreen():GetSampleMusicPosition() / musicratio
		self:GetChild("Pos"):zoomto(math.min(pos,wodth), hidth)
		self:queuecommand("Highlight")

		-- calcdisplay position indicator (not the best place to put this but it works)
		local calcgraphpos = SCREENMAN:GetTopScreen():GetSampleMusicPosition() / musicratio
		local badorp = self:GetDescendant("notChordDensityGraph", "GraphPos")
		badorp:zoomto(math.min(calcgraphpos * capWideScale(300,450) / capWideScale(280,300), capWideScale(300,450)), hidth * 3):halign(0)
	end
end

local function updateCalcInfoDisplays(actor)
	if not calcinfo:GetVisible() then return end
	mx = INPUTFILTER:GetMouseX()
	px = actor:GetParent():GetX()
	sl1 = actor:GetParent():GetDescendant("notChordDensityGraph", "Seek1"):playcommand("UpdatePosition", {pos = mx, w = wodth, px=px})
	st1 = actor:GetParent():GetDescendant("notChordDensityGraph", "Seektext1"):playcommand("UpdatePosition", {pos = mx, w = wodth, px=px})
	st1:settextf("%0.2f", actor:GetParent():GetChild("Seek"):GetX() * musicratio /  getCurRateValue())
	sl1:visible(true)
	st1:visible(true)
end

local t = Def.ActorFrame {
	Name = "ChartPreview",
	InitCommand=function(self)
		self:visible(false)
        self:SetUpdateFunction(UpdatePreviewPos)
		calcinfo = self:GetChild("notChordDensityGraph"):visible(false):draworder(1000) -- actor for calcinfo
		cd = self:GetChild("ChordDensityGraph"):visible(false):draworder(1000)
	end,
	CurrentSongChangedMessageCommand=function(self)
		self:GetChild("pausetext"):settext("")
	end,
	CurrentStepsChangedMessageCommand = function(self)
		if GAMESTATE:GetCurrentSong() then
            musicratio = (GAMESTATE:GetCurrentSteps():GetFirstSecond() / getCurRateValue() + GAMESTATE:GetCurrentSteps():GetLengthSeconds()) / wodth * getCurRateValue()
		end
	end,
    SetupNoteFieldCommand=function(self)
		self:playcommand("NoteFieldVisible")
	end,
	ChartPreviewOnMessageCommand=function(self)
		self:GetChild("NoteField"):playcommand("LoadNoteData", {steps = GAMESTATE:GetCurrentSteps()})
	end,
	NoteFieldVisibleMessageCommand = function(self)
		self:visible(true)
		cd:queuecommand("GraphUpdate")		-- first graph will be empty if we dont force this on initial creation
	end,
	OptionsScreenClosedMessageCommand = function(self)
		local pOptions = GAMESTATE:GetPlayerState():GetCurrentPlayerOptions()
		local usingscrollmod = false
		local usingreverse = pOptions:UsingReverse()
		local nf = self:GetChild("NoteField")
		if not nf then return end
		if pOptions:Split() ~= 0 or pOptions:Alternate() ~= 0 or pOptions:Cross() ~= 0 or pOptions:Centered() ~= 0 then
			usingscrollmod = true
		end

		nf:y(yPos * 2.85)
		if usingscrollmod then
			nf:y(yPos * 3.55)
		elseif usingreverse then
			nf:y(yPos * 2.85 + yPosReverse)
		end
	end,

	Def.NoteFieldPreview {
		Name = "NoteField",
		DrawDistanceBeforeTargetsPixels = 600,
		DrawDistanceAfterTargetsPixels = 0,
		--YReverseOffsetPixels = 100,

		BeginCommand = function(self)
			self:zoom(prevZoom):draworder(90)
			self:x(wodth/2):x(NotefieldPosition)
			self:GetParent():SortByDrawOrder()
		end,
		CurrentStepsChangedMessageCommand = function(self, params)
			local steps = params.ptr
			-- only load new notedata if the preview is visible
			if self:GetParent():GetVisible() then
				self:playcommand("LoadNoteData", {steps = steps})
			end
		end,
		LoadNoteDataCommand = function(self, params)
			local steps = params.steps
			if steps ~= nil then
				self:LoadNoteData(steps)
			else
				self:LoadDummyNoteData()
			end
		end,
		CalcInfoOnMessageCommand = function(self)
			self:show_interval_bars(true)
		end,
		CalcInfoOffMessageCommand = function(self)
			self:show_interval_bars(false)
		end,
	},

	Def.Quad {
		Name = "BG",
		InitCommand = function(self)
			self:xy(wodth/2, SCREEN_HEIGHT/1.5):x(NotefieldPosition):addy(-180)
			self:diffuse(color("0.05,0.05,0.05,1"))
		end,
		ChartPreviewOnMessageCommand = function(self)
			self:visible(true)
		end,
		ChartPreviewOffMessageCommand = function(self)
			self:visible(false)
		end,
		CurrentSongChangedMessageCommand = function(self)
			if GAMESTATE:GetCurrentSong() then
				self:visible(true)
			else 
				self:visible(false)
			end
		end,
		CurrentStyleChangedMessageCommand=function(self)
			local cols = GAMESTATE:GetCurrentStyle():ColumnsPerPlayer()
			self:zoomto(52 * cols, SCREEN_HEIGHT * 1.2)
		end
	},
	LoadFont("Common Large") .. {
		Name = "pausetext",
		InitCommand = function(self)
			self:xy(wodth/2, SCREEN_HEIGHT/2):draworder(900):zoom(0.5):x(NotefieldPosition)
			self:settext(""):diffuse(color("0.8,0,0"))
			self:shadowlength(1):shadowcolor(0,0,0,1)
		end,
		NoteFieldVisibleMessageCommand = function(self)
			self:settext("")
		end,
		PreviewMusicStartedMessageCommand = function(self)
			self:playcommand("Set")
		end,
		SetCommand = function(self)
			if SCREENMAN:GetTopScreen():IsSampleMusicPaused() then
				self:settext(translated_info["Paused"])
			else
				self:settext("")
			end
		end,
		MusicPauseToggledMessageCommand = function(self)
			self:playcommand("Set")
		end,
	},
	Def.Quad {
		Name = "PosBG",
		InitCommand = function(self)
			--self:zoomto(wodth, hidth):halign(0):diffuse(color(".1,.1,.1,1")):draworder(900) -- alt bg for calc info
			self:zoomto(wodth, hidth):halign(0):diffuse(color("1,1,1,0")):draworder(900):x(ChordDensityThing.SeekPositionX):y(ChordDensityThing.SeekPosY) -- cdgraph bg
		end,
		HighlightCommand = function(self)	-- use the bg for detection but move the seek pointer -mina
			if isOver(self) and GAMESTATE:GetCurrentSteps() ~= nil then
				local seek = self:GetParent():GetChild("Seek")
				local seektext = self:GetParent():GetChild("Seektext")
				local seekbg = self:GetParent():GetChild("SeekBG")
				local cdg = self:GetParent():GetChild("ChordDensityGraph")
				local fix = self:GetParent():GetChild("SeekFixIthink")
				
				seek:visible(false)
				seektext:visible(false)
				seekbg:visible(false)
				cdg:visible(false)

				--this is so fucking bad fucj you mina
				fix:visible(false)
				seek:x(INPUTFILTER:GetMouseX() - self:GetParent():GetX())
				fix:x(INPUTFILTER:GetMouseX() - self:GetParent():GetX() - ChordDensityThing.SeekPositionX) --i don't understand how putting the chord coord makes it work again ??????????? -ifwas
				seektext:x(INPUTFILTER:GetMouseX() - self:GetParent():GetX() - 4)	-- todo: refactor this lmao -mina
				seektext:y(INPUTFILTER:GetMouseY() - self:GetParent():GetY())
				seekbg:x(INPUTFILTER:GetMouseX() - self:GetParent():GetX() - 25)
				seekbg:y(INPUTFILTER:GetMouseY() - self:GetParent():GetY() + 15)

				if cdg.npsVector ~= nil and #cdg.npsVector > 0 then
					local percent = clamp((INPUTFILTER:GetMouseX() - self:GetParent():GetX() - ChordDensityThing.SeekPositionX) / wodth, 0, 1)
					local xtime = SecondsToMMSS(fix:GetX() * musicratio / getCurRateValue())
					local hoveredindex = clamp(math.ceil(cdg.finalNPSVectorIndex * percent), math.min(1, cdg.finalNPSVectorIndex), cdg.finalNPSVectorIndex)
					local hoverednps = cdg.npsVector[hoveredindex]
					local td = GAMESTATE:GetCurrentSteps():GetTimingData()
					local bpm = td:GetBPMAtBeat(td:GetBeatFromElapsedTime(fix:GetX() * musicratio)) * getCurRateValue()
					seektext:settextf("%s\n%d %s\n%d %s", xtime, hoverednps, translated_info["NPS"], bpm, translated_info["BPM"])
				else
					seektext:settextf("%0.2f", fix:GetX() * musicratio / getCurRateValue())
				end

				updateCalcInfoDisplays(self)
			else
				self:GetParent():GetChild("Seektext"):visible(false)
				self:GetParent():GetChild("Seek"):visible(false)
				self:GetParent():GetChild("SeekBG"):visible(false)
				self:GetParent():GetDescendant("notChordDensityGraph", "Seektext1"):visible(false)
				self:GetParent():GetDescendant("notChordDensityGraph", "Seek1"):visible(false)
			end
		end
	},
	Def.Quad {
		Name = "Pos",
		InitCommand = function(self)
			self:zoomto(0, hidth):diffuse(color("0,1,0,0")):halign(0):draworder(900):x(ChordDensityThing.SeekPositionX):y(ChordDensityThing.SeekPosY)
		end
	}
}

t[#t + 1] = LoadActor("_chorddensitygraph.lua")
t[#t + 1] = LoadActor("_calcdisplay.lua")

--if you delete this the text on the hovered time will be so incorrect that it'll add 9 minutes or some shit
t[#t + 1] = UIElements.QuadButton(1, 1) .. {
	Name = "SeekFixIthink",
	InitCommand = function(self)
		self:zoomto(2, hidth):diffuse(color("1,.2,.5,0")):halign(0.5):draworder(1100)
	end
}



-- more draw order shenanigans
t[#t + 1] = LoadFont("Common Normal") .. {
	Name = "Seektext",
	InitCommand = function(self)
		self:x(ChordDensityThing.SeektextPosX):y(8):valign(0):halign(1):draworder(1100):zoom(0.45)
	end
}

t[#t + 1] = UIElements.QuadButton(1, 1) .. {
	Name = "Seek",
	InitCommand = function(self)
		self:zoomto(2, hidth):diffuse(color("1,.2,.5,0")):halign(0.5):draworder(1100):x(ChordDensityThing.SeekPositionX):y(ChordDensityThing.SeekPosY)
	end
}

t[#t + 1] = UIElements.QuadButton(1, 1) .. {
	Name = "SeekBG",
	InitCommand = function(self)
		self:zoomto(50 , 40):diffuse(color("0,0,0,0")):halign(0.5):draworder(1000)
	end,
}

return t
