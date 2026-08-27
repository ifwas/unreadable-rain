local profile = PROFILEMAN:GetProfile(PLAYER_1)
local frameX = 10
local frameY = 250 + capWideScale(get43size(120), 90)
local frameWidth = capWideScale(get43size(455), 455)
local score
local song
local steps
local pistola
local noteField = false
local infoOnScreen = false
local heyiwasusingthat = false
local mcbootlarder
local pOptions = GAMESTATE:GetPlayerState():GetCurrentPlayerOptions()
local usingreverse = pOptions:UsingReverse()
local prevX = capWideScale(get43size(98), 98)
local prevY = 55
local prevrevY = 60
local boolthatgetssettotrueonsongchangebutonlyifonatabthatisntthisone = false
local hackysack = false
local songChanged = false
local songChanged2 = false
local previewVisible = false
local onlyChangedSteps = false
local shouldPlayMusic = false
local beginfrombeginning = themeConfig:get_data().global.BeginFromPosZero
local prevtab = 0
local recentScores = SCOREMAN:GetNumScoresThisSession()
local inMultivarInit = Var("LoadingScreen") == "ScreenNetEvaluation"
local itsOn = false

local translated_info = {
	GoalTarget = THEME:GetString("ScreenSelectMusic", "GoalTargetString"),
	MaxCombo = THEME:GetString("ScreenSelectMusic", "MaxCombo"),
	BPM = THEME:GetString("ScreenSelectMusic", "BPM"),
	NegBPM = THEME:GetString("ScreenSelectMusic", "NegativeBPM"),
	UnForceStart = THEME:GetString("GeneralInfo", "UnforceStart"),
	ForceStart = THEME:GetString("GeneralInfo", "ForceStart"),
	Unready = THEME:GetString("GeneralInfo", "Unready"),
	Ready = THEME:GetString("GeneralInfo", "Ready"),
	TogglePreview = THEME:GetString("ScreenSelectMusic", "TogglePreview"),
	PlayerOptions = THEME:GetString("ScreenSelectMusic", "PlayerOptions"),
	OpenSort = THEME:GetString("ScreenSelectMusic", "OpenSortMenu"),
	CloseSort = THEME:GetString("ScreenSelectMusic", "CloseSortMenu"),
}

-- to reduce repetitive code for setting preview music position with booleans
local function playMusicForPreview(song)
	SOUND:StopMusic()
	SCREENMAN:GetTopScreen():PlayCurrentSongSampleMusic(true, true)
	MESSAGEMAN:Broadcast("PreviewMusicStarted") -- this is lying tbf
	restartedMusic = false

	-- use this opportunity to set all the random booleans to make it consistent
	songChanged = false
	boolthatgetssettotrueonsongchangebutonlyifonatabthatisntthisone = false
	hackysack = false
end

-- to toggle calc info display stuff
local function toggleCalcInfo(state)
	infoOnScreen = state

	if infoOnScreen then
		MESSAGEMAN:Broadcast("CalcInfoOn")
	else
		MESSAGEMAN:Broadcast("CalcInfoOff")
	end
end

local hoverAlpha = 0.8
local hoverAlpha2 = 0.6

-- to reduce repetitive code for setting preview visibility with booleans
local function setPreviewPartsState(state)
	if state == nil then return end
	mcbootlarder:visible(state)
	mcbootlarder:GetChild("NoteField"):visible(state)
	heyiwasusingthat = not state
	previewVisible = state
end

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

local function toggleNoteField()
	local nf = mcbootlarder:GetChild("NoteField")
	if song and not noteField then -- first time setup
		noteField = true
		MESSAGEMAN:Broadcast("ChartPreviewOn") -- for banner reaction... lazy -mina
		mcbootlarder:playcommand("SetupNoteField")
		mcbootlarder:xy(prevX, prevY)
		mcbootlarder:diffusealpha(1)

		pOptions = GAMESTATE:GetPlayerState():GetCurrentPlayerOptions()
		usingreverse = pOptions:UsingReverse()
		local usingscrollmod = false
		if pOptions:Split() ~= 0 or pOptions:Alternate() ~= 0 or pOptions:Cross() ~= 0 or pOptions:Centered() ~= 0 then
			usingscrollmod = true
		end

		nf:y(prevY * 2.85)
		if usingscrollmod then
			nf:y(prevY * 3.55)
		elseif usingreverse then
			nf:y(prevY * 2.85 + prevrevY)
		end

		if not songChanged then
			playMusicForPreview(song)
			tryingToStart = true
		else
			tryingToStart = false
		end
		songChanged = false
		hackysack = false
		previewVisible = true
		return true
	end

	if song then
		nf:diffusealpha(1)
		if mcbootlarder:IsVisible() then
			mcbootlarder:visible(false)
			nf:visible(false)
			MESSAGEMAN:Broadcast("ChartPreviewOff")
			previewVisible = false
			hackysack = changingSongs
			changingSongs = false
			return false
		else
			mcbootlarder:visible(true)
			nf:visible(true)
			if boolthatgetssettotrueonsongchangebutonlyifonatabthatisntthisone or songChanged or songChanged2 then
				if not restartedMusic then playMusicForPreview(song) end
				boolthatgetssettotrueonsongchangebutonlyifonatabthatisntthisone = false
				hackysack = false
				songChanged = false
				songChanged2 = false
			end
			MESSAGEMAN:Broadcast("ChartPreviewOn")
			previewVisible = true
			return true
		end
	end
	return false
end

local mintyFreshIntervalFunction = nil
local update = false
local t = Def.ActorFrame {
	Name = "wifetwirler",
	BeginCommand = function(self)
		self:queuecommand("MintyFresh")
	end,
	OffCommand = function(self)
		self:bouncebegin(0.2):xy(-500, 0):diffusealpha(0)
		self:sleep(0.04):queuecommand("Invis")
	end,
	InvisCommand= function(self)
		self:visible(false)
	end,
	OnCommand = function(self)
		self:bouncebegin(0.2):xy(0, 0):diffusealpha(1)
	end,
	CurrentSongChangedMessageCommand = function()
		-- This will disable mirror when switching songs if OneShotMirror is enabled or if permamirror is flagged on the chart (it is enabled if so in screengameplayunderlay/default)
		if playerConfig:get_data(pn_to_profile_slot(PLAYER_1)).OneShotMirror or profile:IsCurrentChartPermamirror() then
			local modslevel = topscreen == "ScreenEditOptions" and "ModsLevel_Stage" or "ModsLevel_Preferred"
			local playeroptions = GAMESTATE:GetPlayerState():GetPlayerOptions(modslevel)
			playeroptions:Mirror(false)
		end
		-- if not on General and we started the noteField and we changed tabs then changed songs
		-- this means the music should be set again as long as the preview is still "on" but off screen
		if getTabIndex() ~= 0 and noteField and heyiwasusingthat then
			boolthatgetssettotrueonsongchangebutonlyifonatabthatisntthisone = true
		end

		-- if the preview was turned on ever but is currently not on screen as the song changes
		-- this goes hand in hand with the above boolean
		if noteField and not previewVisible then
			songChanged = true
		end

		-- check to see if the song actually really changed
		-- >:(
		if noteField and GAMESTATE:GetCurrentSong() ~= song then
			-- always true if switching songs and preview has ever been opened
			songChanged2 = true
			restartedMusic = false
		else
			songChanged2 = false
		end

		-- an awkwardly named bool describing the fact that we just changed songs
		-- used in notefield creation function to see if we should restart music
		-- it is immediately turned off when toggling notefield
		changingSongs = true
		tryingToStart = false

		-- if switching songs, we want the notedata to disappear temporarily
		if noteField and songChanged2 and previewVisible then
			mcbootlarder:GetChild("NoteField"):finishtweening()
			mcbootlarder:GetChild("NoteField"):diffusealpha(0)
		end
	end,
	DelayedChartUpdateMessageCommand = function(self)
		-- wait for the music wheel to settle before playing the music
		-- to keep things very slightly more easy to deal with
		-- and reduce a tiny bit of lag
		local s = GAMESTATE:GetCurrentSong()
		local unexpectedlyChangedSong = s ~= song

		shouldPlayMusic = false
		-- should play the music because the notefield is visible
		shouldPlayMusic = shouldPlayMusic or (noteField and mcbootlarder:GetChild("NoteField") and mcbootlarder:GetChild("NoteField"):IsVisible())
		-- should play the music if we switched songs while on a different tab
		shouldPlayMusic = shouldPlayMusic or boolthatgetssettotrueonsongchangebutonlyifonatabthatisntthisone
		-- should play the music if we switched to a song from a pack tab
		-- also applies for if we just toggled the notefield or changed screen tabs
		shouldPlayMusic = shouldPlayMusic or hackysack
		-- should play the music if we already should and we either jumped song or we didnt change the song
		shouldPlayMusic = shouldPlayMusic and (not onlyChangedSteps or unexpectedlyChangedSong) and not tryingToStart

		-- at this point the music will or will not play ....
		SCREENMAN:GetTopScreen():PlayCurrentSongSampleMusic(true, true)
		boolthatgetssettotrueonsongchangebutonlyifonatabthatisntthisone = false
		hackysack = false
		tryingToStart = false
		songChanged = false
		onlyChangedSteps = true
	end,
	PlayingSampleMusicMessageCommand = function(self)
		-- delay setting the music for preview up until after the sample music starts (smoothness)
		if shouldPlayMusic then
			shouldPlayMusic = false
			local s = GAMESTATE:GetCurrentSong()
			if s then
				if mcbootlarder and mcbootlarder:GetChild("NoteField") then mcbootlarder:GetChild("NoteField"):diffusealpha(1) end
				playMusicForPreview(s)
			end
		end
	end,
	MintyFreshCommand = function(self)
		self:finishtweening()
		local bong = GAMESTATE:GetCurrentSong()
		-- if not on a song and preview is on, hide it (dont turn it off)
		if not bong and noteField and mcbootlarder:IsVisible() then
			MESSAGEMAN:Broadcast("ChartPreviewOff")
		end

		-- if the song changed
		if song ~= bong then
			if not lockbools then
				onlyChangedSteps = false
			end
			if not song and previewVisible and not lockbools then
				hackysack = true -- used in cases when moving from null song (pack hover) to a song (this fixes searching and preview not working)
			end
			song = bong
			self:queuecommand("MortyFarts")
		else
			if not lockbools and not songChanged2 then
				onlyChangedSteps = true
			end
		end

		-- on general tab
		if getTabIndex() == 0 then
			-- if preview was on and should be made visible again
			if heyiwasusingthat and bong and noteField then
				setPreviewPartsState(true)
				MESSAGEMAN:Broadcast("ChartPreviewOn")
			elseif bong and noteField and previewVisible then
				-- make sure that it is visible even if it isnt, when it should be
				-- (haha lets call this 1000000 times nothing could go wrong)
				setPreviewPartsState(true)
			end

			self:visible(true)
			self:queuecommand("On")
			update = true
		else
			-- changing tabs off of general with preview on, hide the preview
			if bong and noteField and mcbootlarder:IsVisible() then
				setPreviewPartsState(false)
				MESSAGEMAN:Broadcast("ChartPreviewOff")
			end

			self:queuecommand("Off")
			update = false
		end
		lockbools = false
	end,
	TabChangedMessageCommand = function(self)
		local newtab = getTabIndex()
		if newtab ~= prevtab then
			self:queuecommand("MintyFresh")
			prevtab = newtab
			if getTabIndex() == 0 and noteField then
				mcbootlarder:GetChild("NoteField"):diffusealpha(1)
				lockbools = true
			elseif getTabIndex() ~= 0 and noteField then
				hackysack = mcbootlarder:IsVisible()
				onlyChangedSteps = false
				boolthatgetssettotrueonsongchangebutonlyifonatabthatisntthisone = false
				lockbools = true
			end
		end
	end,
	MilkyTartsCommand = function(self) -- when entering pack screenselectmusic explicitly turns visibilty on notefield off -mina
		if noteField and mcbootlarder:IsVisible() then
			toggleCalcInfo(false)
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
}

t[#t + 1] = Def.Actor {
	MintyFreshCommand = function(self)
		if song then
			ptags = tags:get_data().playerTags
			steps = GAMESTATE:GetCurrentSteps()
			chartKey = steps:GetChartKey()
			ctags = {}
			for k, v in pairs(ptags) do
				if ptags[k][chartKey] then
					ctags[#ctags + 1] = k
				end
			end
		end
	end
}

local enabledC = "#099948"
local disabledC = "#ff6666"
local force = false
local ready = false
local function toggleButton(textEnabled, textDisabled, msg, x, extrawidth, y, enabledF)
	local ison = false
	return Def.ActorFrame {
		InitCommand = function(self)
			self:xy(10 - 115 + capWideScale(get43size(384), 384) + x, 66 + capWideScale(get43size(120), 120) + y)
			self.updatebutton = function()
				if self.ison ~= nil then
					ison = self.ison
				end

				-- wtf
				self:GetChild("Top"):diffuse((ison and color(enabledC) or (isOver(self:GetChild("Top")) and getMainColor("highlight") or color(disabledC))))
				self:GetChild("Words"):settext(ison and textEnabled or textDisabled)
			end
		end,

		Def.Quad {
			Name = "BG",
			InitCommand = function(self)
				self:zoomto(50 + extrawidth + 1.5, 24 + 1.5)
				self:diffuse(color("#333333"))
			end,
		},
		UIElements.QuadButton(1, 1) .. {
			Name = "Top",
			InitCommand = function(self)
				self:zoomto(50 + extrawidth, 24)
				self:diffuse(color(disabledC))
			end,
			MouseOverCommand = function(self)
				self:diffuse(ison and color(enabledC) or getMainColor("highlight"))
			end,
			MouseOutCommand = function(self)
				self:diffuse(color(ison and enabledC or disabledC))
			end,
			MouseDownCommand = function(self, params)
				if params.event == "DeviceButton_left mouse button" then
					if enabledF then
						ison = enabledF()
					else
						ison = (not ison)
					end
					
					-- wtf 2
					self:diffuse(ison and color(enabledC) or getMainColor("highlight"))
					NSMAN:SendChatMsg(msg, 1, NSMAN:GetCurrentRoomName())
				end
			end,
		},
		LoadFont("Common Large") .. {
			Name = "Words",
			InitCommand = function(self)
				self:zoom(0.3)
				self:diffuse(color("#FFFFFF"))
				self:maxwidth((50 + extrawidth) / 0.3)
				self:settext(textDisabled)
			end,
		},
	}
end
local forceStart = toggleButton(translated_info["UnForceStart"], translated_info["ForceStart"], "/force", -35, 30, 11) .. {
	Name = "ForceStart",
}
local readyButton = nil
do
	-- do-end block to minimize the scope of 'f'
	local areWeReadiedUp = function()
		local top = SCREENMAN:GetTopScreen()
		if top:GetName() == "ScreenNetSelectMusic" then
			local qty = top:GetUserQty()
			local loggedInUser = NSMAN:GetLoggedInUsername()
			for i = 1, qty do
				local user = top:GetUser(i)
				if user == loggedInUser then
					return top:GetUserReady(i)
				end
			end
			-- ???? this should never happen
			-- retroactive - had this happen once and i still dont know why
			error "Could not find ourselves in the userlist"
		end
	end
	readyButton = toggleButton(translated_info["Unready"], translated_info["Ready"], "/ready", 50, 0, 11, areWeReadiedUp) .. {
		Name = "Ready",
		UsersUpdateMessageCommand = function(self)
			self.ison = areWeReadiedUp()
			self.updatebutton()
		end
	}
end

local sn = Var ("LoadingScreen")
if sn and sn:find("Net") ~= nil then
	t[#t + 1] = forceStart
	t[#t + 1] = readyButton
end

-- t[#t+1] = LoadFont("Common Large") .. {
-- InitCommand=function(self)
-- 	self:xy((capWideScale(get43size(384),384))+68,SCREEN_BOTTOM-135):halign(1):zoom(0.4,maxwidth,125)
-- end,
-- BeginCommand=function(self)
-- 	self:queuecommand("Set")
-- end,
-- SetCommand=function(self)
-- if song then
-- self:settext(song:GetOrTryAtLeastToGetSimfileAuthor())
-- else
-- self:settext("")
-- end
-- end,
-- CurrentStepsChangedMessageCommand=function(self)
-- 	self:queuecommand("Set")
-- end,
-- RefreshChartInfoMessageCommand=function(self)
-- 	self:queuecommand("Set")
-- end,
-- }

-- active filters display
-- t[#t+1] = Def.Quad{InitCommand=cmd(xy,16,capWideScale(SCREEN_TOP+172,SCREEN_TOP+194);zoomto,SCREEN_WIDTH*1.35*0.4 + 8,24;halign,0;valign,0.5;diffuse,color("#000000");diffusealpha,0),
-- EndingSearchMessageCommand=function(self)
-- self:diffusealpha(1)
-- end
-- }
-- t[#t+1] = LoadFont("Common Large") .. {
-- InitCommand=function(self)
-- 	self:xy(20,capWideScale(SCREEN_TOP+170,SCREEN_TOP+194)):halign(0):zoom(0.4):settext("Active Filters: "..GetPersistentSearch()):maxwidth(SCREEN_WIDTH*1.35)
-- end,
-- EndingSearchMessageCommand=function(self, msg)
-- self:settext("Active Filters: "..msg.ActiveFilter)
-- end
-- }

-- tags?
t[#t + 1] = LoadFont("Common Normal") .. {
	InitCommand = function(self)
		self:xy(frameX + 300, frameY - 60):halign(0):zoom(0.6):maxwidth(capWideScale(54, 450) / 0.6)
	end,
	MintyFreshCommand = function(self)
		if song and ctags[1] then
			self:settext(ctags[1])
		else
			self:settext("")
		end
	end,
	ChartPreviewOnMessageCommand = function(self)
		self:visible(false)
	end,
	ChartPreviewOffMessageCommand = function(self)
		self:visible(true)
	end
}

t[#t + 1] = LoadFont("Common Normal") .. {
	InitCommand = function(self)
		self:xy(frameX + 300, frameY - 30):halign(0):zoom(0.6):maxwidth(capWideScale(54, 450) / 0.6)
	end,
	MintyFreshCommand = function(self)
		if song and ctags[2] then
			self:settext(ctags[2])
		else
			self:settext("")
		end
	end
}

t[#t + 1] = LoadFont("Common Normal") .. {
	InitCommand = function(self)
		self:xy(frameX + 300, frameY):halign(0):zoom(0.6):maxwidth(capWideScale(54, 450) / 0.6)
	end,
	MintyFreshCommand = function(self)
		if song and ctags[3] then
			self:settext(ctags[3])
		else
			self:settext("")
		end
	end
}

--Chart Preview Button
local yesiwantnotefield = false
local lastratepresses = {0,0}
local function ihatestickinginputcallbackseverywhere(event)
	if event.type ~= "InputEventType_Release" and getTabIndex() == 0 then
		if event.DeviceInput.button == "DeviceButton_space" then
			toggleNoteField()
		end
		if event.GameButton == "EffectUp" then
			lastratepresses[1] = 0
		end
		if event.GameButton == "EffectDown" then
			lastratepresses[2] = 0
		end
	end
	if event.type == "InputEventType_FirstPress" then
		local CtrlPressed = INPUTFILTER:IsControlPressed()
		if CtrlPressed and event.DeviceInput.button == "DeviceButton_l" then
			MESSAGEMAN:Broadcast("LoginHotkeyPressed")
		end
		if event.GameButton == "EffectUp" then
			lastratepresses[1] = GetTimeSinceStart()
		end
		if event.GameButton == "EffectDown" then
			lastratepresses[2] = GetTimeSinceStart()
		end
		-- this sucks so bad
		if math.abs(lastratepresses[1] - lastratepresses[2]) < 0.05 and lastratepresses[1] ~= 0 and lastratepresses[2] ~= 0 then
			MESSAGEMAN:Broadcast("Code", {Name="ResetRate"})
			ChangeMusicRate(nil, {Name="ResetRate"})
		end
	end
	return false
end

local yOffestThing = 0
local numScoresLimit = 10

if sn and sn:find("Net") ~= nil then
	numScoresLimit = 9
	yOffestThing = 30
end

local prevplayerops = "Main"

local lastsortmode = nil
t[#t + 1] = Def.ActorFrame {
	Name = "LittleButtonsOnTheLeft",

	UIElements.TextToolTip(1, 1, "Common Normal") .. {
		Name = "PreviewViewer",
		BeginCommand = function(self)
			mcbootlarder = self:GetParent():GetParent():GetChild("ChartPreview")
			SCREENMAN:GetTopScreen():AddInputCallback(MPinput)
			SCREENMAN:GetTopScreen():AddInputCallback(ihatestickinginputcallbackseverywhere)
			self:xy(20, 235):zoom(0.5):halign(0)
			self:diffuse(getMainColor("positive")):visible(false)
		end,
		MouseDownCommand = function(self, params)
			if params.event == "DeviceButton_left mouse button" and (song or noteField) then
				toggleNoteField()
			end
		end,
		ChartPreviewOnMessageCommand = function(self)
			local ready = self:GetParent():GetParent():GetChild("Ready")
			local force = self:GetParent():GetParent():GetChild("ForceStart")
			if ready ~= nil then
				ready:visible(false)
			end
			if force ~= nil then
				force:visible(false)
			end
		end,
		ChartPreviewOffMessageCommand = function(self)
			if SCREENMAN:GetTopScreen():GetName():find("Net") ~= nil then
				local ready = self:GetParent():GetParent():GetChild("Ready")
				local force = self:GetParent():GetParent():GetChild("ForceStart")
				if ready ~= nil then
					ready:visible(true)
				end
				if force ~= nil then
					force:visible(true)
				end
			end
		end,
		MouseOverCommand = function(self)
			self:diffusealpha(hoverAlpha2)
		end,
		MouseOutCommand = function(self)
			self:diffusealpha(1)
		end,
		MintyFreshCommand = function(self)
			if song then
				self:settext(translated_info["TogglePreview"])
			else
				self:settext("")
			end
		end,
	},
	LoadFont("Common Large") .. {
		BeginCommand = function(self)
			self:diffusealpha(1)
			self:xy(101, 50):halign(0.5):zoom(0.3)
			self:settext("Session Plays")
			pistola = SCREENMAN:GetTopScreen():GetMusicWheel()
			SCOREMAN:SortRecentScoresForGame()

			if sn and sn:find("Net") ~= nil then
				self:settext("")
			end
		end
	},
	Def.Quad {
		BeginCommand = function(self)
			self:xy(101, 59 + yOffestThing):zoomto(200, 1)
			self:faderight(0.5):fadeleft(0.5)
		end
	},
	Def.Quad {
		BeginCommand = function(self)
			self:xy(101, SCREEN_BOTTOM - 70):zoomto(200, 1)
			self:faderight(0.5):fadeleft(0.5)
		end
	},
	LoadFont("Common Large") .. {
		BeginCommand = function(self)
			self:xy(101, 203):halign(0.5):zoom(0.3)
			self:settext("")
			self:diffuse(color("#444444dd"))

			if recentScores == 0 then 
				self:settext("try setting some scores")
			end
		end
	},

	LoadFont("Common Large") .. {
		BeginCommand = function(self)
			self:xy(101, 223):halign(0.5):zoom(0.4)
			self:settext("")
			self:diffuse(color("#444444dd"))

			if recentScores == 0 then 
				self:settext("( ` ω´)")
				self:spin():effectmagnitude(0,200,0)
			end
		end
	},
}

local AAAAAAAAAAAAAAA = 30
local putamadre = 35
local putamadre2 = putamadre + 10
local putamadre3 = putamadre2 + 11
local putamadre4 = putamadre3 + 12



local function recentShit(i)
	local el
	local llavecartografo
	local cancion
	local lospasos

	local t = Def.ActorFrame {
		InitCommand = function(self)
			self:xy(0, 50 + (4 * (i - 1)) + (yOffestThing + AAAAAAAAAAAAAAA * i))
			if not BannersEnabled() then
				self:x(20)
			end
		end,
		ProfileTabOffMessageCommand = function(self)
			SCOREMAN:SortRecentScoresForGame()
			el = SCOREMAN:GetRecentScoreForGame(i)
			llavecartografo = el:GetChartKey()
			cancion = SONGMAN:GetSongByChartKey(llavecartografo)
			lospasos = SONGMAN:GetStepsByChartKey(llavecartografo)
			MESSAGEMAN:Broadcast("hola")
		end,
		OnCommand = function(self)
			el = SCOREMAN:GetRecentScoreForGame(i)
			llavecartografo = el:GetChartKey()
			cancion = SONGMAN:GetSongByChartKey(llavecartografo)
			lospasos = SONGMAN:GetStepsByChartKey(llavecartografo)
			MESSAGEMAN:Broadcast("hola")
		end,
		Def.Quad {
			InitCommand = function(self)
				self:x(-4)
				self:zoomto(150, 30)
				self:halign(0)
				self:diffuse(getMainColor("highlight"))
				self:diffusealpha(0.3)
				self:faderight(1)
			end
		},
		LoadFont("Common Large") .. {
			Name = "SongTitle",
			InitCommand = function(self)
				self:xy(putamadre4,-2):halign(0):zoom(0.2):valign(0.5)
				self:settext("")
			end,
			holaMessageCommand = function(self)
				if cancion and el then --a little check wouldn't hurt
					local title = cancion:GetDisplayMainTitle()
					truncatetxt(self, title, 130)
				end
			end
		},
		LoadFont("Common Large") .. {
			Name = "SongArtist",
			InitCommand = function(self)
				self:xy(putamadre4,8):halign(0):zoom(0.12):valign(0.5)
				self:diffuse(getMainColor("positive"))
				self:settext("")
			end,
			holaMessageCommand = function(self)
				if cancion and el then 
					self:settext(cancion:GetDisplayArtist())
				end
			end
		},
		LoadFont("Common Large") .. {
			Name = "ssr" .. i,
			InitCommand = function(self)
				self:xy(putamadre2, 8):halign(1):zoom(0.2):valign(0.5)
				self:diffuse(getMainColor("positive"))
				self:settext("")
			end,
			holaMessageCommand = function(self)
				if el then 
					local ssr = el:GetSkillsetSSR(ms.SkillSets[1])
					self:settextf("%5.2f", ssr)
					self:diffuse(byMSD(ssr))
				else
					self:settext("")
				end
			end
		},
		LoadFont("Common Large") .. {
			Name = "Wife" .. i,
			InitCommand = function(self)
				self:xy(putamadre2, -4):halign(1):zoom(0.21):valign(0.5)
				self:diffuse(getMainColor("positive"))
				self:settext("")
			end,
			holaMessageCommand = function(self)
				if el then 
					self:settextf("%5.2f%%", el:GetWifeScore() * 100)
					if not el:GetEtternaValid() then
						self:diffuse(byJudgment("TapNoteScore_Miss"))
					else
						self:diffuse(getGradeColor(el:GetWifeGrade()))
					end
				else
					self:settext("")
				end
			end
		},
		LoadFont("Common Large") .. {
			Name = "Diff" .. i,
			InitCommand = function(self)
				self:xy(putamadre3, -4):halign(0.5):zoom(0.21):valign(0.5)
				self:settext("")
			end,
			holaMessageCommand = function(self)
				if lospasos then 
					local diff = lospasos:GetDifficulty()
					self:settext(getShortDifficulty(diff))
					self:diffuse(byDifficulty(diff))
				else
					self:settext("")
				end
			end
		},
		LoadFont("Common Large") .. {
			Name = "Rate" .. i,
			InitCommand = function(self)
				self:xy(putamadre3, 8):halign(0.5):zoom(0.15):valign(0.5)
				self:settext("")
			end,
			holaMessageCommand = function(self)
				if el then 
					local ratestring = string.format("%.2f", el:GetMusicRate()):gsub("%.?0+$", "") .. "x"
					self:settext(ratestring)
				else
					self:settext("")
				end
			end
		},
		UIElements.QuadButton(1, 1).. {
			InitCommand = function(self)
				self:x(0)
				self:zoomto(202, 30)
				self:halign(0)
				self:diffuse(getMainColor("tabs"))
				self:diffusealpha(0)
			end,
			MouseDownCommand = function(self, params)
				if params.event == "DeviceButton_left mouse button" then
					if el then
						pistola:SelectSong(cancion)
					end
				end
			end,
			MouseOverCommand = function(self)
				self:finishtweening()
				self:GetParent():GetChild("GroupNameHover"):finishtweening()
				self:GetParent():GetChild("GroupNameHover"):decelerate(0.2):x(5):diffusealpha(1)
				self:diffusealpha(0.8)
			end,
			MouseOutCommand = function(self)
				self:finishtweening()
				self:GetParent():GetChild("GroupNameHover"):finishtweening()
				self:GetParent():GetChild("GroupNameHover"):decelerate(0.3):x(0):diffusealpha(0)
				self:diffusealpha(0)
			end
		},
		LoadFont("Common Large") .. {
			Name = "GroupNameHover",
			InitCommand = function(self)
				self:x(0):zoom(0.2):halign(0):diffuse(Saturation(getMainColor("highlight"), 0.6))
				self:diffusealpha(0)
				self:settext("")
			end,
			holaMessageCommand = function(self)
				if el and cancion then
					self:settext(cancion:GetGroupName())
				end
			end
		}
	}
	return t
end

local weirdworkaround 

if recentScores ~= 0 then
	weirdworkaround = recentScores

	if recentScores >= numScoresLimit then 
		weirdworkaround = numScoresLimit
	end

	for i = 1, weirdworkaround do 
		t[#t + 1] = recentShit(i)
	end
end

t[#t + 1] = LoadActorWithParams("../_chartpreview.lua", {yPos = prevY, yPosReverse = prevrevY})

--zorder shenanigans lmao
t[#t + 1] =LoadFont("Common Normal") .. {
	InitCommand = function(self)
		self:xy(capWideScale(get43size(384), 196), SCREEN_BOTTOM - 32.5):halign(1):zoom(0.50)
	end,
	MortyFartsCommand = function(self)
		if song then
			self:settext(translated_info["BPM"])
		else
			self:settext("")
		end
	end
}

-- **song stuff that scales with rate**
t[#t + 1] = Def.BPMDisplay{
	File = THEME:GetPathF("BPMDisplay", "bpm"),
		Name = "BPMDisplay",
		InitCommand = function(self)
			self:xy(capWideScale(get43size(384), 170), SCREEN_BOTTOM - 32.5):halign(1):zoom(0.50):maxwidth(50)
		end,
		CurrentRateChangedMessageCommand = function(self)
			self:queuecommand("MintyFresh") --steps stuff
	    end,
		MintyFreshCommand = function(self)
			if song then
				self:visible(true)
				self:SetFromSteps(steps)
			else
				self:visible(false)
			end
		end
}

return t
