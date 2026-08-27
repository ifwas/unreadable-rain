-- refactored a bit but still needs work -mina
local itemScoreIndex = 1
local collapsed = false
local rtTable
local rates
local rateIndex = 1
local scoreIndex = 1
local score
local pn = GAMESTATE:GetEnabledPlayers()[1]
local nestedTab = 1
local nestedTabs = {
	THEME:GetString("TabScore", "NestedLocal"),
	THEME:GetString("TabScore", "NestedOnline")
}
local hasReplayData

local frameX = 0
local frameY = 40
local frameWidth = 202
local frameHeight = 368
local fontScale = 0.4
local offsetX = 10
local offsetY = 20
local netScoresPerPage = 8
local netScoresCurrentPage = 1
local nestedTabButtonWidth = 153
local nestedTabButtonHeight = 20
local netPageButtonWidth = 50
local netPageButtonHeight = 50
local headeroffY = 10

local selectedrateonly

local judges = {
	"TapNoteScore_W1",
	"TapNoteScore_W2",
	"TapNoteScore_W3",
	"TapNoteScore_W4",
	"TapNoteScore_W5",
	"TapNoteScore_Miss",
	"HoldNoteScore_Held",
	"HoldNoteScore_LetGo"
}

local translated_info = {
	MaxCombo = THEME:GetString("TabScore", "MaxCombo"),
	ComboBreaks = THEME:GetString("TabScore","ComboBreaks"),
	DateAchieved = THEME:GetString("TabScore", "DateAchieved"),
	Mods = THEME:GetString("TabScore", "Mods"),
	Rate = THEME:GetString("TabScore", "Rate"), -- used in conjunction with Showing
	Showing = THEME:GetString("TabScore", "Showing"), -- to produce a scuffed thing
	ChordCohesion = THEME:GetString("TabScore", "ChordCohesion"),
	Judge = THEME:GetString("TabScore", "ScoreJudge"),
	NoScores = THEME:GetString("TabScore", "NoScores"),
	NoChart = THEME:GetString("TabScore", "NoChart"),
	Yes = THEME:GetString("OptionNames", "Yes"),
	No = THEME:GetString("OptionNames", "No"),
	ShowOffset = THEME:GetString("TabScore", "ShowOffsetPlot"),
	NoReplayData = THEME:GetString("TabScore", "NoReplayData"),
	ShowReplay = THEME:GetString("TabScore", "ShowReplay"),
	ShowEval = THEME:GetString("TabScore", "ShowEval"),
	UploadReplay = THEME:GetString("TabScore", "UploadReplay"),
	UploadAllScoreChart=THEME:GetString("TabScore", "UploadAllScoreChart"),
	UploadAllScorePack=THEME:GetString("TabScore", "UploadAllScorePack"),
	UploadAllScore=THEME:GetString("TabScore", "UploadAllScore"),
	UploadingReplay = THEME:GetString("TabScore", "UploadingReplay"),
	UploadingScore = THEME:GetString("TabScore", "UploadingScore"),
	NotLoggedIn = THEME:GetString("GeneralInfo", "NotLoggedIn"),
    ValidateScore = THEME:GetString("TabScore", "ValidateScore"),
    ScoreValidated = THEME:GetString("TabProfile", "ScoreValidated"),
    InvalidateScore = THEME:GetString("TabScore", "InvalidateScore"),
    ScoreInvalidated = THEME:GetString("TabProfile", "ScoreInvalidated")
}

local defaultRateText = ""
if themeConfig:get_data().global.RateSort then
	defaultRateText = "1.0x"
else
	defaultRateText = "All"
end

local hoverAlpha = 0.6

local moped
-- Only works if ... it should work
-- You know, if we can see the place where the scores should be.
local function updateLeaderBoardForCurrentChart()
	local top = SCREENMAN:GetTopScreen()
	if top:GetName() == "ScreenSelectMusic" or top:GetName() == "ScreenNetSelectMusic" then
		if top:GetMusicWheel():IsSettled() and ((getTabIndex() == 2 and nestedTab == 2) or collapsed) then
			local steps = GAMESTATE:GetCurrentSteps()
			if steps then
				local leaderboardAttempt = DLMAN:GetChartLeaderBoard(steps:GetChartKey())
				if leaderboardAttempt ~= nil and #leaderboardAttempt > 0 then
					moped:playcommand("SetFromLeaderboard", leaderboardAttempt)
				elseif leaderboardAttempt ~= nil and #leaderboardAttempt == 0 then
					DLMAN:RequestChartLeaderBoardFromOnline(
						steps:GetChartKey(),
						function(leaderboard)
							moped:queuecommand("SetFromLeaderboard", leaderboard)
						end
					)
				else
					moped:queuecommand("SetFromLeaderboard", nil)
				end
			else
				moped:playcommand("SetFromLeaderboard", {})
			end
		end
	end
end

local ret = Def.ActorFrame {
	Name = "Scoretab",
	BeginCommand = function(self)
		moped = self:GetChild("ScoreDisplay")
		self:queuecommand("Set"):visible(false)
		self:GetChild("LocalScores"):xy(frameX, frameY):visible(false)
		moped:xy(frameX, frameY):visible(false)

		if FILTERMAN:oopsimlazylol() then -- set saved position and auto collapse
			nestedTab = 2
			self:GetChild("LocalScores"):visible(false)
			moped:xy(FILTERMAN:grabposx("Doot"), FILTERMAN:grabposy("Doot")):visible(true)
			self:playcommand("Collapse")
		end
	end,
	OffCommand = function(self)
		self:bouncebegin(0.2):xy(-500, 0):diffusealpha(0)
		self:sleep(0.04):queuecommand("Invis")
	end,
	InvisCommand= function(self)
		self:visible(false)
		self:GetChild("LocalScores"):visible(false)
	end,
	OnCommand = function(self)
		self:bouncebegin(0.2):xy(0, 0):diffusealpha(1)
		if getTabIndex() == 2 and nestedTab == 1 then
			self:GetChild("LocalScores"):visible(true)
		else
			self:GetChild("LocalScores"):visible(false)
		end
	end,
	SetCommand = function(self)
		self:finishtweening(1)
		if getTabIndex() == 2 then -- switching to this tab
			local sd = self:GetParent():GetChild("StepsDisplay")
			if nestedTab == 2 then
				sd.nested = true
				sd:visible(false)
			else
				sd.nested = false
				sd:visible(true)
			end
			if collapsed then -- expand if collaped
				self:queuecommand("Expand")
			else
				self:queuecommand("On")
				self:visible(true)
			end
		elseif collapsed and getTabIndex() == 0 then -- display on general tab if collapsed
			self:queuecommand("On")
			self:visible(true) -- not sure about whether this works or is needed
		elseif collapsed and getTabIndex() ~= 0 then -- but not others
			self:queuecommand("Off")
		elseif not collapsed then -- if not collapsed, never display outside of this tab
			self:queuecommand("Off")
		end
	end,
	TabChangedMessageCommand = function(self, params)
		self:queuecommand("Set")
		-- if tab was already visible, swap nested tabs
		if params ~= nil and params.from == 2 and params.to == 2 and self:GetVisible() and not collapsed then
			if nestedTab == 1 then nestedTab = 2 else nestedTab = 1 end
			local sd = self:GetParent():GetChild("StepsDisplay")
			self:GetChild("Button_1"):playcommand("NestedTabChanged")
			self:GetChild("Button_2"):playcommand("NestedTabChanged")
			if nestedTab == 1 then
				self:GetChild("ScoreDisplay"):visible(false)
				self:GetChild("LocalScores"):visible(true)
				sd:visible(true)
			else
				updateLeaderBoardForCurrentChart()
				self:GetChild("ScoreDisplay"):visible(true)
				self:GetChild("LocalScores"):visible(false)
				sd:visible(false)
			end
		end
		updateLeaderBoardForCurrentChart()
	end,
	ChangeStepsMessageCommand = function(self)
		if getTabIndex() ~= 2 then return end
		self:queuecommand("Set")
		updateLeaderBoardForCurrentChart()
	end,
	CollapseCommand = function(self)
		collapsed = true
		local tind = getTabIndex()
		resetTabIndex()
		MESSAGEMAN:Broadcast("TabChanged", {from = tind, to = 0})
	end,
	ExpandCommand = function(self)
		collapsed = false
		local tind = getTabIndex()
		if getTabIndex() ~= 2 then
			setTabIndex(2)
		end
		local after = getTabIndex()
		self:GetChild("ScoreDisplay"):xy(frameX, frameY)
		MESSAGEMAN:Broadcast("TabChanged", {from = tind, to = after})
	end,
	DelayedChartUpdateMessageCommand = function(self)
		local leaderboardEnabled =
			playerConfig:get_data(pn_to_profile_slot(PLAYER_1)).leaderboardEnabled and DLMAN:IsLoggedIn()
		if GAMESTATE:GetCurrentSteps() then
			local chartkey = GAMESTATE:GetCurrentSteps():GetChartKey()
			if leaderboardEnabled then
			DLMAN:RequestChartLeaderBoardFromOnline(
				chartkey,
				function(leaderboard)
					moped:playcommand("SetFromLeaderboard", leaderboard)
				end
			)	-- this is also intentionally super bad so we actually do something about it -mina
			elseif (SCREENMAN:GetTopScreen():GetName() == "ScreenSelectMusic" or SCREENMAN:GetTopScreen():GetName() == "ScreenNetSelectMusic") and ((getTabIndex() == 2 and nestedTab == 2) or collapsed) then
				DLMAN:RequestChartLeaderBoardFromOnline(
				chartkey,
				function(leaderboard)
					moped:playcommand("SetFromLeaderboard", leaderboard)
				end
			)
			end
		end
	end,
	NestedTabChangedMessageCommand = function(self)
		self:queuecommand("Set")
		updateLeaderBoardForCurrentChart()
	end,
	CodeMessageCommand = function(self, params) -- this is intentionally bad to remind me to fix other things that are bad -mina
		if ((getTabIndex() == 2 and nestedTab == 2) and not collapsed) and DLMAN:GetCurrentRateFilter() then
			local rate = getCurRateValue()
			if params.Name == "PrevScore" and rate < MAX_MUSIC_RATE - 0.05 then
				GAMESTATE:GetSongOptionsObject("ModsLevel_Preferred"):MusicRate(rate + 0.1)
				GAMESTATE:GetSongOptionsObject("ModsLevel_Song"):MusicRate(rate + 0.1)
				GAMESTATE:GetSongOptionsObject("ModsLevel_Current"):MusicRate(rate + 0.1)
				MESSAGEMAN:Broadcast("CurrentRateChanged")
			elseif params.Name == "NextScore" and rate > MIN_MUSIC_RATE + 0.05 then
				GAMESTATE:GetSongOptionsObject("ModsLevel_Preferred"):MusicRate(rate - 0.1)
				GAMESTATE:GetSongOptionsObject("ModsLevel_Song"):MusicRate(rate - 0.1)
				GAMESTATE:GetSongOptionsObject("ModsLevel_Current"):MusicRate(rate - 0.1)
				MESSAGEMAN:Broadcast("CurrentRateChanged")
			end
			if params.Name == "PrevRate" and rate < MAX_MUSIC_RATE then
				GAMESTATE:GetSongOptionsObject("ModsLevel_Preferred"):MusicRate(rate + 0.05)
				GAMESTATE:GetSongOptionsObject("ModsLevel_Song"):MusicRate(rate + 0.05)
				GAMESTATE:GetSongOptionsObject("ModsLevel_Current"):MusicRate(rate + 0.05)
				MESSAGEMAN:Broadcast("CurrentRateChanged")
			elseif params.Name == "NextRate" and rate > MIN_MUSIC_RATE then
				GAMESTATE:GetSongOptionsObject("ModsLevel_Preferred"):MusicRate(rate - 0.05)
				GAMESTATE:GetSongOptionsObject("ModsLevel_Song"):MusicRate(rate - 0.05)
				GAMESTATE:GetSongOptionsObject("ModsLevel_Current"):MusicRate(rate - 0.05)
				MESSAGEMAN:Broadcast("CurrentRateChanged")
			end
		end
	end,
	CurrentRateChangedMessageCommand = function(self)
		if ((getTabIndex() == 2 and nestedTab == 2) or collapsed) and DLMAN:GetCurrentRateFilter() then
			moped:queuecommand("GetFilteredLeaderboard")
		end
	end
}

local curPage = 1
local maxPage = 1
local cheese

local function movePage(n)
    local nextPage = curPage + n
    if nextPage > maxPage then
        nextPage = maxPage
    elseif nextPage < 1 then
        nextPage = 1
    end

    if nextPage ~= curPage then
        curPage = nextPage
        MESSAGEMAN:Broadcast("scorePageChanged",{page = curPage})
    end
end 


-- eats only inputs that would scroll to a new score
local function input(event)
	if isOver(cheese:GetChild("FrameDisplay")) then
		if event.DeviceInput.button == "DeviceButton_mousewheel up" and event.type == "InputEventType_FirstPress" then
			moving = true
			if nestedTab == 1 and rtTable and rtTable[rates[rateIndex]] ~= nil then
				cheese:queuecommand("PrevScore")
				movePage(-1)
				return true
			end
		elseif event.DeviceInput.button == "DeviceButton_mousewheel down" and event.type == "InputEventType_FirstPress" then
			if nestedTab == 1 and rtTable ~= nil and rtTable[rates[rateIndex]] ~= nil then
				cheese:queuecommand("NextScore")
				movePage(1)
				return true
			end
		elseif moving == true then
			moving = false
		end
	end
	return false
end

local t = Def.ActorFrame {
	Name = "LocalScores",
	InitCommand = function(self)
		rtTable = nil
		cheese = self
	end,
	BeginCommand = function(self)
		SCREENMAN:GetTopScreen():AddInputCallback(input)
	end,
	OnCommand = function(self)
		if nestedTab == 1 and self:IsVisible() then
			if GAMESTATE:GetCurrentSong() ~= nil then
				rtTable = getRateTable()
				if rtTable ~= nil then
					rates, rateIndex = getUsedRates(rtTable)
					itemScoreIndex = 1
					scoreIndex = 1
					self:queuecommand("Display")
				else
					self:queuecommand("Init")
				end
			else
				self:queuecommand("Init")
			end
		end
	end,
	NestedTabChangedMessageCommand = function(self)
		self:visible(nestedTab == 1)
		self:queuecommand("Set")
	end,
	CurrentStepsChangedMessageCommand = function(self)
		scoreIndex = 1
		curPage = 1
		if getTabIndex() == 2 then
			self:playcommand("On")
			if rtTable == nil or #rtTable == 0 or rates == nil or #rates == 0 or rates[rateIndex] == nil or rtTable[rates[rateIndex]] == nil then
				return
			end
			self:playcommand("Display")
		end
	end,
	CodeMessageCommand = function(self, params)
		if nestedTab == 1 and rtTable ~= nil and rtTable[rates[rateIndex]] ~= nil then
			if params.Name == "NextRate" then
				self:queuecommand("PrevRate")
			elseif params.Name == "PrevRate" then
				self:queuecommand("NextRate")
			elseif params.Name == "NextScore" then
				self:queuecommand("NextScore")
				movePage(-1)
			elseif params.Name == "PrevScore" then
				self:queuecommand("PrevScore")
				movePage(1)
			end
		end
	end,
	NextRateCommand = function(self)
		rateIndex = ((rateIndex) % (#rates)) + 1
		scoreIndex = 1
		self:queuecommand("Display")
	end,
	PrevRateCommand = function(self)
		rateIndex = ((rateIndex - 2) % (#rates)) + 1
		scoreIndex = 1
		self:queuecommand("Display")
	end,
	NextScoreCommand = function(self)
		scoreIndex = ((scoreIndex) % (#rtTable[rates[rateIndex]])) + 1
		self:queuecommand("Display")
	end,
	PrevScoreCommand = function(self)
		scoreIndex = ((scoreIndex - 2) % (#rtTable[rates[rateIndex]])) + 1
		self:queuecommand("Display")
	end,
	DisplayCommand = function(self)
		score = rtTable[rates[rateIndex]][scoreIndex]
		if getTabIndex() == 2 then
			hasReplayData = score:HasReplayData()
		else
			hasReplayData = false
		end
		setScoreForPlot(score)
	end,
	LoadFont("Common Large") .. {
		Name = "Oopsnoscore",
		InitCommand = function(self)
			self:xy(100,150):zoom(0.25):settextf("No Local Scores Registered... \n\n...You should maybe set one (^_^´)"):diffusealpha(1):wag():effectmagnitude(3,0,1):diffuse(getMainColor("positive"))
		end,
		DisplayCommand = function(self)
			self:diffusealpha(0)
		end
	},
	Def.Quad {
		Name = "FrameDisplay",
		InitCommand = function(self)
			self:zoomto(frameWidth, frameHeight):halign(0):valign(0):diffuse(getMainColor("tabs"))
			self:diffusealpha(0)
		end,
		CollapseCommand = function(self)
			self:visible(false)
		end,
		ExpandCommand = function(self)
			self:visible(true)
		end
	}
}



local l = Def.ActorFrame {
	InitCommand = function(self)
		self:xy(offsetX, offsetY)
	end
}



local function makeText(index)
	return UIElements.TextToolTip(1, 1, "Common Normal") .. {
		InitCommand = function(self)
			local foff = 0
			local loggg = 0

			if index > 5 then 
				foff = 15
				loggg = 5
			end 
			self:xy(frameX + ((index - loggg) * 40) - 35, offsetY + foff + 13):zoom(fontScale):halign(0):settext("")
		end,
		DisplayCommand = function(self)
			local count = 0
			if rtTable[rates[index]] ~= nil then
				count = #rtTable[rates[index]]
			end
			if index <= #rates then
				self:settextf("%s (%d)", rates[index], count)
				if index == rateIndex then 
					--hyper mega hack to make the itemScore display update initial rate scores, and also handles CodeMessageCommand at the same time... pretty neat huh? -ifwas
					rateIndex = index
					itemScoreIndex = index
					self:diffuse(color("#FFFFFF"))
				else
					self:diffuse(getMainColor("positive"))
				end
			else
				self:settext("")
			end
		end,
		MouseOverCommand = function(self)
			if index ~= rateIndex then
				self:diffusealpha(hoverAlpha)
			end
		end,
		MouseOutCommand = function(self)
			if index ~= rateIndex then
				self:diffusealpha(1)
			end
		end,
		MouseDownCommand = function(self, params)
			if nestedTab == 1 and params.event == "DeviceButton_left mouse button" then
				rateIndex = index
				scoreIndex = 1
				itemScoreIndex = index
				curPage = 1
				self:GetParent():queuecommand("Display")
			end
		end
	}
end

for i = 1, 9 do
	t[#t + 1] = makeText(i)
end


local function showItem(i)
	local precio
	local puntuacion
	local intRate
	local totalScoresRate = 0
	local t = Def.ActorFrame {
		Name = "yup",
		InitCommand = function(self)
			self:xy(18, 10 + 45 * i)
		end,
		scorePageChangedMessageCommand = function(self)
			self:queuecommand("Display")
		end,
		CurrentStepsChangedMessageCommand = function(self)
			self:visible(false)
		end,
		DisplayCommand = function(self)
			self:finishtweening()
			self:visible(false)
			precio = nil
			totalScoresRate = 0
			if rtTable[rates[itemScoreIndex]] ~= nil and getTabIndex() == 2 then --this has a panic attack when we're not in score tab for some reason
				totalScoresRate = #rtTable[rates[itemScoreIndex]]
				maxPage = math.max(1, math.ceil(totalScoresRate/7))
				intRate = rates[rateIndex]
				if i <= totalScoresRate then
					puntuacion = rtTable[rates[rateIndex]][i + (7 * (curPage - 1))]
					if puntuacion then
						precio = puntuacion:HasReplayData()
						self:visible(true)
						self:queuecommand("naranja")
					end
				end
			else
				self:visible(false)
			end
		end,
		naranjaCommand = function(self)
			self:finishtweening()
			self:diffusealpha(0)
			self:y(20 + 45 * i):decelerate(0.2 + 0.05 * i):diffusealpha(1):y(10 + 45 * i)
		end,
		Def.Quad{
			Name = "bg",
			InitCommand = function(self)
				self:x(172):zoomto(196, 40):halign(1)
			end,
			naranjaCommand = function(self)
				self:diffuse(color("#212121cc"))
			end
		},
		LoadFont("Common Large") .. {
			Name = "indexText" .. i,
			InitCommand = function(self)
				self:xy(-20,-10):halign(0):zoom(0.2):maxwidth(80):diffuse(getMainColor("highlight")):diffusealpha(0.75)
			end,
			naranjaCommand = function(self)
				local indexNom = i + ((curPage - 1) * 7)
				self:settext(indexNom .. ".")
			end
		},
		LoadFont("Common Large") .. {
			Name = "Rate",
			InitCommand = function(self)
				self:x(170):halign(1):zoom(0.2)
			end,
			naranjaCommand = function(self)
				self:settext(intRate)
			end
		},
		UIElements.TextToolTip(1, 1, "Common Large") .. {
			Name = "spread",
			InitCommand = function(self)
				self:xy(14,1):zoom(0.165):halign(0):maxwidth(780)
			end,
			naranjaCommand = function(self)
				local maravilloso = puntuacion:GetTapNoteScore("TapNoteScore_W1")
				local perfecto = puntuacion:GetTapNoteScore("TapNoteScore_W2")
				local genial = puntuacion:GetTapNoteScore("TapNoteScore_W3")
				local tabien = puntuacion:GetTapNoteScore("TapNoteScore_W4")
				local pffff = puntuacion:GetTapNoteScore("TapNoteScore_W5")
				local fallaste = puntuacion:GetTapNoteScore("TapNoteScore_Miss")
				local combo = puntuacion:GetMaxCombo()
				self:settextf("%d / %d / %d / %d / %d / %d (%dx)", maravilloso, perfecto, genial, tabien, pffff, fallaste, combo)
			end,
			MouseOverCommand = function(self)
				if precio then
					self:diffusealpha(0.5)
				end
			end,
			MouseOutCommand = function(self)
				self:diffusealpha(1)
			end,
			MouseDownCommand = function(self, params)
				if params.event == "DeviceButton_left mouse button" and nestedTab == 1 then
					if getTabIndex() == 2 and getScoreForPlot() and precio and isOver(self) then
						SCREENMAN:AddNewScreenToTop("ScreenScoreTabOffsetPlot")
					end
				end
			end
		},
		LoadFont("Common Large") .. {
			Name = "Date",
			InitCommand = function(self)
				self:xy(170,12):halign(1):zoom(0.17)
			end,
			naranjaCommand = function(self)
				self:settext(getScoreDate(puntuacion))
			end
		},
		LoadFont("Common Large") .. {
			Name = "ssr",
			InitCommand = function(self)
				self:xy(170,-11):halign(1):zoom(0.27)
			end,
			naranjaCommand = function(self)
				local overall = puntuacion:GetSkillsetSSR("Overall")
				self:settextf("%.2f",overall):diffuse(byMSD(overall))
			end
		},
		LoadFont("Common Large") .. {
			Name = "grade",
			InitCommand = function(self)
				self:xy(-5,5):halign(0.5):zoom(0.4):maxwidth(80)
			end,
			naranjaCommand = function(self)
				self:settext(THEME:GetString("Grade", ToEnumShortString(puntuacion:GetWifeGrade())))
				self:diffuse(getGradeColor(puntuacion:GetWifeGrade()))
			end
		},
		LoadFont("Common Large") .. {
			Name = "waifu",
			InitCommand = function(self)
				self:xy(14,-11):halign(0):zoom(0.23)
			end,
			naranjaCommand = function(self)
				if puntuacion:GetWifeScore() ~= 0 then
					local wv = puntuacion:GetWifeVers()
					local wv = puntuacion:GetWifeVers()
					local ws = "Wife" .. wv .. " J"
					local judge = 4
					if PREFSMAN:GetPreference("SortBySSRNormPercent") == false then
						judge = table.find(ms.JudgeScalers, notShit.round(puntuacion:GetJudgeScale(), 2))
					end
					if not judge then judge = 4 end
					if judge < 4 then judge = 4 end
					local js = judge ~= 9 and judge or "ustice"
					local perc = puntuacion:GetWifeScore() * 100
					if perc > 99.65 then
						self:settextf("%05.4f%% (%s)", notShit.floor(perc, 4), ws .. js)
					else
						self:settextf("%05.2f%% (%s)", notShit.floor(perc, 2), ws .. js)
					end
					self:diffuse(byGrade(puntuacion:GetWifeGrade()))
				else
					self:settext("NA")
				end
			end
		},
		UIElements.SpriteButton(1, 1, THEME:GetPathG("", "showEval")) .. {
			Name = "EvalViewer",
			InitCommand = function(self)
				self:xy(15,12):halign(0):zoom(0.42):visible(false)
			end,
			naranjaCommand = function(self)
				if precio ~= nil then 
					self:visible(true)
				end
			end,
			MouseOverCommand = function(self)
				if precio then
					self:diffusealpha(0.5)
					TOOLTIP:SwitchSide(false)
					TOOLTIP:SetText("Show Evaluation")
					TOOLTIP:Show()
				end
			end,
			MouseOutCommand = function(self)
				self:diffusealpha(1)
				TOOLTIP:Hide()
			end,
			MouseDownCommand = function(self, params)
				if params.event == "DeviceButton_left mouse button" and nestedTab == 1 then
					if getTabIndex() == 2 and getScoreForPlot() and precio and isOver(self) then
						SCREENMAN:GetTopScreen():ShowEvalScreenForScore(puntuacion)
					end
				end
			end
		},
		UIElements.SpriteButton(1, 1, THEME:GetPathG("", "showReplay")) .. {
			Name = "ReplayViewer",
			InitCommand = function(self)
				self:xy(27,12):halign(0):zoom(0.42):visible(false)
			end,
			naranjaCommand = function(self)
				if precio ~= nil then 
					self:visible(true)
				end
			end,
			MouseOverCommand = function(self)
				if precio then
					self:diffusealpha(0.5)
					TOOLTIP:SwitchSide(false)
					TOOLTIP:SetText("Show Replay")
					TOOLTIP:Show()
				end
			end,
			MouseOutCommand = function(self)
				self:diffusealpha(1)
				TOOLTIP:Hide()
			end,
			MouseDownCommand = function(self, params)
				if params.event == "DeviceButton_left mouse button" and nestedTab == 1 then
					if getTabIndex() == 2 and getScoreForPlot() and precio and isOver(self) then
						SCREENMAN:GetTopScreen():PlayReplay(puntuacion)
					end
				end
			end
		},
		UIElements.SpriteButton(1, 1, THEME:GetPathG("", "invalidate")) .. {
			Name = "Validity",
			InitCommand = function(self)
				self:xy(38,12):halign(0):zoom(0.42):visible(false)
			end,
			naranjaCommand = function(self)
				if puntuacion ~= nil then 
					if puntuacion:GetEtternaValid()then
						IsInvalidOrNah = translated_info["InvalidateScore"]
					else
						IsInvalidOrNah = translated_info["ValidateScore"]
					end
					self:visible(true)
				end
			end,
			MouseOverCommand = function(self)
				if self:IsVisible() then
					self:diffusealpha(0.5)
					TOOLTIP:SwitchSide(false)
					TOOLTIP:SetText(IsInvalidOrNah)
					TOOLTIP:Show()
				end
			end,
			MouseOutCommand = function(self)
				self:diffusealpha(1)
				TOOLTIP:Hide()
			end,
			MouseDownCommand = function(self, params)
				if params.event == "DeviceButton_left mouse button" and nestedTab == 1 then
					if getTabIndex() == 2 and isOver(self) then
						puntuacion:ToggleEtternaValidation()
						MESSAGEMAN:Broadcast("UpdateRanking")
						if puntuacion:GetEtternaValid() then
							ms.ok(translated_info["ScoreInvalidated"])
							self:diffuse(color("#ff6d6dff"))
							IsInvalidOrNah = translated_info["ValidateScore"]
						else
							ms.ok(translated_info["ScoreValidated"])
							self:diffuse(color("#FFFFFF"))
							IsInvalidOrNah = translated_info["InvalidateScore"]
						end

						TOOLTIP:SetText(IsInvalidOrNah)
					end
				end
			end
		}
	}

	return t
end

for i = 1, 7 do 
	l[#l + 1] = showItem(i)
end

t[#t + 1] = l

ret[#ret + 1] = t

local function nestedTabButton(i)
	return Def.ActorFrame {
		Name = "Button_"..i,
		InitCommand = function(self)
			self:xy(frameX + offsetX/2 + (i - 1) * (nestedTabButtonWidth - capWideScale(100, 80)), frameY + offsetY - 10)
		end,
		CollapseCommand = function(self)
			self:visible(false)
		end,
		ExpandCommand = function(self)
			self:visible(true)
		end,
		UIElements.TextToolTip(1, 1, "Common Normal") .. {
			InitCommand = function(self)
				self:diffuse(getMainColor("positive")):maxwidth(nestedTabButtonWidth - 80):maxheight(40):zoom(0.65)
				self:settext(nestedTabs[i])
				self:halign(0):valign(1)
				self.hoverDiffusefunction = function(self)
					local inTabNotHovered = 1
					local offTabNotHovered = 0.6
					local offTabHovered = 0.8
					local inTabHovered = 0.6
					if isOver(self) then
						if nestedTab == i then
							self:diffusealpha(inTabHovered)
						else
							self:diffusealpha(offTabHovered)
						end
					else
						if nestedTab == i then
							self:diffusealpha(inTabNotHovered)
						else
							self:diffusealpha(offTabNotHovered)
						end
					end
				end
				self:hoverDiffusefunction()
			end,
			MouseOverCommand = function(self)
				self:hoverDiffusefunction()
			end,
			MouseOutCommand = function(self)
				self:hoverDiffusefunction()
			end,
			NestedTabChangedMessageCommand = function(self)
				self:hoverDiffusefunction()
			end,
			MouseDownCommand = function(self, params)
				if params.event == "DeviceButton_left mouse button" then
					nestedTab = i
					MESSAGEMAN:Broadcast("NestedTabChanged")
					if nestedTab == 1 then
						self:GetParent():GetParent():GetChild("ScoreDisplay"):visible(false)
						self:GetParent():GetParent():GetParent():GetChild("StepsDisplay"):visible(true)
					else
						self:GetParent():GetParent():GetChild("ScoreDisplay"):visible(true)
						self:GetParent():GetParent():GetParent():GetChild("StepsDisplay"):visible(false)
					end
				end
			end
		}
	}
end

-- online score display
ret[#ret + 1] = LoadActor("../superscoreboard")

for i = 1, #nestedTabs do
	ret[#ret + 1] = nestedTabButton(i)
end

return ret
