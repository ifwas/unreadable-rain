--main
local mintyFreshIntervalFunction = nil
local update = false

--variable for handling song related stuff
local song
local songChanged = false
local songChanged2 = false
local onlyChangedSteps = false
local currentTagTable = {}

--specific
local hackysack = false
local profile = PROFILEMAN:GetProfile(PLAYER_1)
local ratePitchPreference

--xy, width, height tables / variables / alphas
local mainframex = SCREEN_RIGHT
local framewidth = 183
local bgStuffWidth = framewidth * 0.95
local hoverAlpha = 0.8
local hoverAlpha2 = 0.6

local explainpls = {
	explainthingY = capWideScale(103,123),
	explainRankX = (SCREEN_CENTER_X * -1) - capWideScale(105,210),
	explainTitleX = (SCREEN_CENTER_X * -1) - capWideScale(90,190),
	explainSubX = (SCREEN_CENTER_X * -1) + capWideScale(130,240)
}

local metadata = {
    ------------------------------------
    SongTitleX = framewidth * -0.98,
    SongTitleY = 125, ----123 11
    SongTitleSize = 0.32,
    -------------------------------------
    SongArtistX = framewidth * -0.98,
    SongArtistY = 140,
    SongArtistSize = 0.2,
	-------------------------------------
	SongSubX = framewidth * -0.98,
	SongSubY = 152,
	SongSubSize = 0.15,
	-------------------------------------
	cdtitleX = -16,
	cdtitleY = 380,
	-------------------------------------
	SongTitlePlayerX = (SCREEN_CENTER_X * -1) - capWideScale(20,7) ,
	SongTitlePlayerY = SCREEN_BOTTOM - 16,
	SongTitlePlayerSize = 0.17 * capWideScale(0.95,1),
	SongTitlePlayerCharLimit = capWideScale(165,300)
}

local rateStuff = {
	bgX = -91,
	bgY = 161,
	-------------------------------------
	rateStringX = framewidth * -0.94,
	rateStringY = 175
}

local radar = {
	bgX = -91,
	bgY = 331,
	-------------------------------------
	nameRadarX = framewidth * -0.94,
	nameRadarY = 328,
	-------------------------------------
	countRadarX = framewidth * -0.45,
	countRadary = 328,
	-------------------------------------
	radartxtSpacing = 17,
	radarzoom = 0.58
}

local pbStuff = {
	bgX = -91,
	bgY = 436,
	-------------------------------------
	pbWifeX = -12,
	pbWifeY = 460,
	pbWifeSize = 0.45,
	-------------------------------------
	pbRateX = -35,
	pbRateY = 468,
	pbRateSize = 0.45,
	-------------------------------------
	pbWifeVerX = -12,
	pbWifeVerY = 468,
	pbWifeVerSize = 0.45,
	-------------------------------------
	pbMaxComboX = framewidth * -0.94,
	pbMaxComboY = 468,
	pbMaxComboSize = 0.4,
	-------------------------------------
	pbClearTypeX = framewidth * -0.94,
	pbClearTypeY = 450,
	pbClearTypeSize = 0.8
}
local bird = 2.2

local bannerThingy = {
    bannerx = -4,
    bannery = 45,
    bannerwidth = 384 / bird, 
    bannerheig = 120 / bird,
	bannerPackX = (SCREEN_CENTER_X * -1) + capWideScale(0,31),
	bannerPackY = capWideScale(45,33),
	bannerPacw = capWideScale(get43size(384 / 2.5), 384 / 1.5),
	bannerPach = capWideScale(get43size(120 / 2.4), 120 / 1.48)
}

-- set the given text but truncate it if a width is reached, poco made this
function truncatetxt(self, text, maxwidth)
    for i = 1, #text do
        self:settext(text:sub(1, i).."..")
        if self:GetZoomedWidth() > maxwidth then
            break
        end
        if i == #text then
            self:settext(text)
        end
    end
end

-- the same shit as above but it handles subtitles
function truncateSubs(self, text, maxwidth)
    for i = 1, #text do
        self:settext(text:sub(1, i).."..\"")
        if self:GetZoomedWidth() > maxwidth then
            break
        end
        if i == #text then
            self:settext(text)
        end
    end
end


local t = Def.ActorFrame {
    Name = "wifeStrapon",
    BeginCommand = function(self)
        self:x(mainframex)
        self:queuecommand("MintyFresh")
    end,
    MintyFreshCommand = function(self)
        self:finishtweening()
		song = GAMESTATE:GetCurrentSong()
    end,
    CurrentSongChangedMessageCommand = function(self)
        -- This will disable mirror when switching songs if OneShotMirror is enabled or if permamirror is flagged on the chart (it is enabled if so in screengameplayunderlay/default)
		if playerConfig:get_data(pn_to_profile_slot(PLAYER_1)).OneShotMirror or profile:IsCurrentChartPermamirror() then
			local modslevel = topscreen == "ScreenEditOptions" and "ModsLevel_Stage" or "ModsLevel_Preferred"
			local playeroptions = GAMESTATE:GetPlayerState():GetPlayerOptions(modslevel)
			playeroptions:Mirror(false)
		end
    end,
	CurrentStepsChangedMessageCommand = function(self)
		-- this basically queues MintyFresh every 0.5 seconds but only once and also resets the 0.5 seconds
		-- if you scroll again
		-- so if you scroll really fast it doesnt pop at all until you slow down
		-- lag begone
		local topscr = SCREENMAN:GetTopScreen()

		if mintyFreshIntervalFunction ~= nil then
			topscr:clearInterval(mintyFreshIntervalFunction)
			mintyFreshIntervalFunction = nil
		end
		mintyFreshIntervalFunction = topscr:setInterval(function()
			self:queuecommand("MintyFresh")
			if mintyFreshIntervalFunction ~= nil then
				topscr:clearInterval(mintyFreshIntervalFunction)
				mintyFreshIntervalFunction = nil
			end
		end,
		0.05)
	end,
    UIElements.QuadButton(1, 1) .. {
		InitCommand = function(self)
			self:zoomto(framewidth, SCREEN_HEIGHT):valign(0):diffuse(getMainColor("frames")):halign(1)
		end
	},
    UIElements.QuadButton(1, 1) .. { --shadowgradient
		InitCommand = function(self)
			self:zoomto(framewidth, SCREEN_HEIGHT):valign(0):diffuse(getMainColor("tabs")):halign(1):fadetop(1):diffusealpha(0.2)
		end
	},
	UIElements.QuadButton(1, 1) .. {
		InitCommand = function(self)
			self:xy(rateStuff.bgX, rateStuff.bgY)
			self:zoomto(bgStuffWidth, SCREEN_HEIGHT * 0.3352):valign(0):diffuse(getMainColor("tabs")):halign(0.5)
		end
	},
	UIElements.QuadButton(1, 1) .. {
		InitCommand = function(self)
			self:xy(radar.bgX, radar.bgY)
			self:zoomto(bgStuffWidth, SCREEN_HEIGHT * 0.2):valign(0):diffuse(getMainColor("tabs")):halign(0.5)
		end
	},
	UIElements.QuadButton(1, 1) .. {
		InitCommand = function(self)
			self:xy(pbStuff.bgX, pbStuff.bgY)
			self:zoomto(bgStuffWidth, SCREEN_HEIGHT * 0.1):valign(0):diffuse(getMainColor("tabs")):halign(0.5)
		end
	},
    UIElements.TextToolTip(1, 1, "Common Large") .. {
        Name = "SongTitle",
        InitCommand = function(self)
            self:xy(metadata.SongTitleX, metadata.SongTitleY):zoom(metadata.SongTitleSize):halign(0):diffusealpha(1)
            self:settext("")
        end,
        MintyFreshCommand = function(self)
            if song and GAMESTATE:GetCurrentSong() ~= nil then
				truncatetxt(self,GAMESTATE:GetCurrentSong():GetDisplayMainTitle(), framewidth - 5)
            else
                self:settext("")
            end
        end,
		MouseOverCommand = function(self)
			self:diffusealpha(0.7)
		end,
		MouseOutCommand = function(self)
			self:diffusealpha(1)
		end,
		MouseDownCommand = function(self,params)
			local wheel = SCREENMAN:GetTopScreen():GetMusicWheel()
			if song and GAMESTATE:GetCurrentSong() ~= nil and params.event == "DeviceButton_left mouse button" and wheel:IsSettled() then
				song:OpenSongFolder()
			end
		end
    },
    LoadFont("Common Large") .. {
        Name = "SongArtist",
        InitCommand = function(self)
            self:xy(metadata.SongArtistX, metadata.SongArtistY):zoom(metadata.SongArtistSize):halign(0)
            self:diffuse(color("#a0a0a0"))
            self:settext("")
        end,
        MintyFreshCommand = function(self)
            if song and GAMESTATE:GetCurrentSong() ~= nil then
				truncatetxt(self,GAMESTATE:GetCurrentSong():GetDisplayArtist(), framewidth)
            else
                self:settext("")
            end
        end
    },
	LoadFont("Common Large") .. {
        Name = "SongSub",
        InitCommand = function(self)
            self:xy(metadata.SongSubX, metadata.SongSubY):zoom(metadata.SongSubSize):halign(0)
            self:diffuse(Brightness(getMainColor("positive"),0.6))
            self:settext("")
        end,
        MintyFreshCommand = function(self)
            if song and GAMESTATE:GetCurrentSong() ~= nil and GAMESTATE:GetCurrentSong():GetDisplaySubTitle() ~= "" then
				truncateSubs(self,"\""..GAMESTATE:GetCurrentSong():GetDisplaySubTitle().."\"", framewidth)
            else
                self:settext("")
            end
        end
    },
	LoadFont("Common Large") .. {
        Name = "explainrank",
        InitCommand = function(self)
            self:xy(explainpls.explainRankX, explainpls.explainthingY):zoom(metadata.SongArtistSize):halign(0)
            self:settext("")
        end,
        MintyFreshCommand = function(self)
            if song and GAMESTATE:GetCurrentSong() ~= nil then
				self:settext("#")
            else
                self:settext("")
            end
        end
    },
	LoadFont("Common Large") .. {
        Name = "explainTitlte",
        InitCommand = function(self)
            self:xy(explainpls.explainTitleX, explainpls.explainthingY):zoom(metadata.SongArtistSize):halign(0)
            self:settext("")
        end,
        MintyFreshCommand = function(self)
            if song and GAMESTATE:GetCurrentSong() ~= nil then
				self:settext("Title")
            else
                self:settext("")
            end
        end
    },
	LoadFont("Common Large") .. {
        Name = "explainsubtlte",
        InitCommand = function(self)
            self:xy(explainpls.explainSubX, explainpls.explainthingY):zoom(metadata.SongArtistSize):halign(1)
            self:settext("")
        end,
        MintyFreshCommand = function(self)
            if song and GAMESTATE:GetCurrentSong() ~= nil then
				self:settext("Subtitle / Tags")
            else
                self:settext("")
            end
        end
    },
	LoadFont("Common Large") .. {
        Name = "SongTitlePlayer",
        InitCommand = function(self)
            self:xy(metadata.SongTitlePlayerX, metadata.SongTitlePlayerY):zoom(metadata.SongTitlePlayerSize)
            self:settext("")
        end,
        MintyFreshCommand = function(self)
            if song and GAMESTATE:GetCurrentSong() ~= nil then
				local fucjk = metadata.SongTitlePlayerCharLimit
				truncatetxt(self,GAMESTATE:GetCurrentSong():GetDisplayArtist() .. " - ".. GAMESTATE:GetCurrentSong():GetDisplayMainTitle(), fucjk)
            else
                self:settext("")
            end
        end
    },
}

t[#t + 1] = Def.Sprite {
	Name = "banbannerrrrrrrrrrr",
	InitCommand = function(self)
		self:x(bannerThingy.bannerx):y(bannerThingy.bannery):halign(1):valign(0)
		self:scaletoclipped(bannerThingy.bannerwidth, bannerThingy.bannerheig):diffusealpha(1)
	end,
	MintyFreshCommand = function(self)
		if INPUTFILTER:IsBeingPressed("tab") then
			self:finishtweening():smooth(0.25):diffusealpha(0):sleep(0.2):queuecommand("ModifyBanner")
		else
			self:finishtweening():queuecommand("ModifyBanner")
		end
	end,
	ModifyBannerCommand = function(self)
		self:finishtweening()
		if song and GAMESTATE:GetCurrentSong() ~= nil then
			local bnpath = GAMESTATE:GetCurrentSong():GetBannerPath()
			self:visible(true)
			if not BannersEnabled() then
				self:visible(false)
			elseif not bnpath then
				bnpath = THEME:GetPathG("Common", "fallback banner")
			end
			self:LoadBackground(bnpath)
		else
			self:visible(false)
		end
		self:diffusealpha(1)
	end,
}

t[#t + 1] = Def.Sprite {
	Name = "pacbanbannerrrrrrrrrrr",
	InitCommand = function(self)
		self:x(bannerThingy.bannerPackX):y(bannerThingy.bannerPackY):halign(1):valign(0)
		self:scaletoclipped(bannerThingy.bannerPacw, bannerThingy.bannerPach):diffusealpha(1)
	end,
	MintyFreshCommand = function(self)
		if INPUTFILTER:IsBeingPressed("tab") then
			self:finishtweening():smooth(0.25):diffusealpha(0):sleep(0.2):queuecommand("ModifyBanner")
		else
			self:finishtweening():queuecommand("ModifyBanner")
		end
	end,
	ModifyBannerCommand = function(self)
		self:finishtweening()
		local bnpath = SONGMAN:GetSongGroupBannerPath(SCREENMAN:GetTopScreen():GetMusicWheel():GetSelectedSection())
			if not BannersEnabled() then
				self:visible(false)
			elseif not bnpath or bnpath == "" then
				bnpath = THEME:GetPathG("Common", "fallback banner")
			end
		self:LoadBackground(bnpath)
		self:diffusealpha(1)
	end,
	ProfileTabOffMessageCommand = function(self)
		if not BannersEnabled() then 
			self:visible(false)
			return
		end

		ProfileActorFadeInOut(self, false)
	end,
	ProfileTabOnMessageCommand = function(self)
		ProfileActorFadeInOut(self, true)
	end
}

t[#t + 1] = UIElements.SpriteButton(1, 1, nil) .. {
	Name = "cdtitle",
	InitCommand = function(self)
		self:x(metadata.cdtitleX):y(metadata.cdtitleY):halign(1):valign(0.5):visible(false)
	end,
	MintyFreshCommand = function(self)
		self:finishtweening():queuecommand("ModifyCD")
	end,
	ModifyCDCommand = function(self)
		self:finishtweening()
		if song and GAMESTATE:GetCurrentSong() ~= nil and GAMESTATE:GetCurrentSong():HasCDTitle() then
			local cdpath = GAMESTATE:GetCurrentSong():GetCDTitlePath()
			self:visible(true)
			self:Load(cdpath):bob():effectmagnitude(0,1.5,0)
		else
			self:visible(false)
		end

		local height = self:GetHeight()
		local width = self:GetWidth()

		if height >= 60 and width >= 75 then
			if height * (75 / 60) >= width then
				self:zoom(40 / height)
			else
				self:zoom(50 / width)
			end
		elseif height >= 60 then
			self:zoom(40 / height)
		elseif width >= 75 then
			self:zoom(50 / width)
		else
			self:zoom(0.7)
		end
		if isOver(self) then
			self:playcommand("ToolTip")
		end
	end,
	ToolTipCommand = function(self)
		if isOver(self) then
			if GAMESTATE:GetCurrentSong():HasCDTitle() and self:GetVisible() then
				local auth = GAMESTATE:GetCurrentSong():GetOrTryAtLeastToGetSimfileAuthor()
				if auth and #auth > 0 and auth ~= "Author Unknown" then
					TOOLTIP:SwitchSide(true)
					TOOLTIP:SetText(auth)
					TOOLTIP:Show()
				else
					TOOLTIP:Hide()
				end
			else
				TOOLTIP:Hide()
			end
		end
	end,
	MouseOverCommand = function(self)
		self:playcommand("ToolTip")
	end,
	MouseOutCommand = function(self)
		TOOLTIP:Hide()
	end,
	MouseDownCommand = function(self, params)
		if song and GAMESTATE:GetCurrentSong():HasCDTitle() ~= nil and params.event == "DeviceButton_left mouse button" then
			local auth = GAMESTATE:GetCurrentSong():GetOrTryAtLeastToGetSimfileAuthor()
			if auth and #auth > 0 and auth ~= "Author Unknown" then
				MESSAGEMAN:Broadcast("SearchUpdateAuthorSim")
			end
		end
	end,
}

-- Music Rate Display
t[#t + 1] = UIElements.TextToolTip(1, 1, "Common Large") .. {
	InitCommand = function(self)
		self:xy(rateStuff.rateStringX, rateStuff.rateStringY):visible(true):halign(0):zoom(0.4):maxwidth(
			capWideScale(get43size(360), 360) / capWideScale(get43size(0.45), 0.45)
		)
	end,
	CurrentRateChangedMessageCommand = function(self)
		self:queuecommand("MintyFresh")
	end,
	MintyFreshCommand = function(self)
		if song then
			self:settext(getCurRateDisplayString())
		else
			self:settext("")
		end
	end,
	CodeMessageCommand = function(self, params)
		local rate = getCurRateValue()
		ChangeMusicRate(rate, params)
		self:settext(getCurRateDisplayString())
	end,
	GoalSelectedMessageCommand = function(self)
		self:queuecommand("MintyFresh")
	end,
	MouseOverCommand = function(self)
		self:diffusealpha(hoverAlpha2)
	end,
	MouseOutCommand = function(self)
		self:diffusealpha(1)
	end,
	MouseDownCommand = function(self, params)
		if not self:IsVisible() then return end
		if params.event == "DeviceButton_right mouse button" then
			ChangeMusicRate(nil, {Name="NextRate"})
		elseif params.event == "DeviceButton_left mouse button" then
			if INPUTFILTER:IsBeingPressed("left shift") then 
				ratePitchPreference = PREFSMAN:GetPreference("EnablePitchRates")

				if ratePitchPreference == true then
					PREFSMAN:SetPreference("EnablePitchRates", false)
					ms.ok("Pitch Rates: Disabled")
				else
					PREFSMAN:SetPreference("EnablePitchRates", true)
					ms.ok("Pitch Rates: Enabled")
				end

				
				return
			end
			ChangeMusicRate(nil, {Name="PrevRate"})
		end
		self:settext(getCurRateDisplayString())
	end,
}

-- "Radar values", noteinfo that isn't rate dependent -mina
local function radarPairs(i)
	local o = Def.ActorFrame {
		Name = "radarpair_"..i,
		LoadFont("Common Normal") .. {
			InitCommand = function(self)
				self:xy(radar.nameRadarX, radar.nameRadarY + radar.radartxtSpacing * i):zoom(radar.radarzoom):halign(0):maxwidth(120)
			end,
			MintyFreshCommand = function(self)
				if song then
					self:settext(ms.RelevantRadarsShort[i])
				else
					self:settext("")
				end
			end
		},
		LoadFont("Common Normal") .. {
			InitCommand = function(self)
				self:xy(radar.countRadarX, radar.countRadary + radar.radartxtSpacing * i):zoom(radar.radarzoom):halign(1):maxwidth(60)
			end,
			CurrentStepsChangedMessageCommand = function(self, steps)
				if steps.ptr then
					self:settext(steps.ptr:GetRelevantRadars()[i])
				else
					self:settext("")
				end
			end
		},
	}
	return o
end

local r = Def.ActorFrame {
	Name = "RadarValues",
}

-- Create the radar values
for i = 1, 5 do
	r[#r + 1] = radarPairs(i)
end

t[#t + 1] = r
t[#t + 1] = LoadActor("msdtracker")


t[#t + 1] = Def.ActorFrame{
	Name = "ratestufffffffffffffffff", -- mostly pb scores, song length and stuff will be put in something like mplayer.lua
	MintyFreshCommand = function()
		score = GetDisplayScore()
	end,
	CurrentRateChangedMessageCommand = function(self)
		self:queuecommand("MintyFresh") --steps stuff
		self:queuecommand("MortyFarts") --songs stuff
	end,
	LoadFont("Common Large") .. {
		InitCommand = function(self)
			self:xy(pbStuff.pbWifeX, pbStuff.pbWifeY):zoom(pbStuff.pbWifeSize):halign(1):maxwidth(180):valign(1)
		end,
		MintyFreshCommand = function(self)
			if song and score then
				local perc = score:GetWifeScore() * 100
				if perc > 99.65 then
					self:settextf("%05.4f%%", notShit.floor(perc, 4))
				else
					self:settextf("%05.2f%%", notShit.floor(perc, 2))
				end
				self:diffuse(getGradeColor(score:GetWifeGrade()))
			else
				self:settext("")
			end
		end
	},
	LoadFont("Common Normal") .. {
		InitCommand = function(self)
			self:xy(pbStuff.pbRateX, pbStuff.pbRateY):zoom(pbStuff.pbRateSize):halign(1)
		end,
		MintyFreshCommand = function(self)
			if song and score then
				local rate = notShit.round(score:GetMusicRate(), 3)
				local notCurRate = notShit.round(getCurRateValue(), 3) ~= rate
				local rate = string.format("%.2f", rate)
				if rate:sub(#rate, #rate) == "0" then
					rate = rate:sub(0, #rate - 1)
				end
				rate = rate .. "x"
				if notCurRate then
					self:settext("(" .. rate .. ")")
				else
					self:settext(rate)
				end
			else
				self:settext("")
			end
		end
	},
	LoadFont("Common Normal") .. {
		InitCommand = function(self)
			self:xy(pbStuff.pbWifeVerX, pbStuff.pbWifeVerY):zoom(pbStuff.pbWifeVerSize):halign(1):maxwidth(140)
		end,
		MintyFreshCommand = function(self)
			if song and score then
				local wv = score:GetWifeVers()
				local ws = " W" .. wv
				self:settext(ws):diffuse(byGrade(score:GetWifeGrade()))
			else
				self:settext("")
			end
		end
	},
	LoadFont("Common Normal") .. {
		InitCommand = function(self)
			self:xy(pbStuff.pbMaxComboX, pbStuff.pbMaxComboY):zoom(pbStuff.pbMaxComboSize):halign(0)
		end,
		MintyFreshCommand = function(self)
			if song and score then
				self:settextf("Combo: %d", score:GetMaxCombo())
			else
				self:settext("")
			end
		end
	},
	LoadFont("Common Normal") .. {
		Name = "ClearType",
		InitCommand = function(self)
			self:xy(pbStuff.pbClearTypeX, pbStuff.pbClearTypeY):zoom(pbStuff.pbClearTypeSize):halign(0)
		end,
		MintyFreshCommand = function(self)
			if song and score then
				self:visible(true)
				self:settext(getClearTypeFromScore(PLAYER_1, score, 0))
				self:diffuse(getClearTypeFromScore(PLAYER_1, score, 2))
			else
				self:visible(false)
			end
		end
	},
}


return t