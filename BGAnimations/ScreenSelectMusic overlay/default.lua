local showVisualizer = themeConfig:get_data().global.ShowVisualizer
local nonButtonColor = ColorMultiplier(getMainColor("positive"), 1.25)
local sessTimeToolTip = ""

local function input(event)
	-- mouse click events left here to let anything in selectmusic react to them
	if event.DeviceInput.button == "DeviceButton_left mouse button" then 
		if event.type == "InputEventType_Release" then
			MESSAGEMAN:Broadcast("MouseLeftClick")
			MESSAGEMAN:Broadcast("MouseUp", {event = event})
		elseif event.type == "InputEventType_FirstPress" then
			MESSAGEMAN:Broadcast("MouseDown", {event = event})
		end
	elseif event.DeviceInput.button == "DeviceButton_right mouse button" then
		if event.type == "InputEventType_Release" then
			MESSAGEMAN:Broadcast("MouseRightClick")
			MESSAGEMAN:Broadcast("MouseUp", {event = event})
		elseif event.type == "InputEventType_FirstPress" then
			MESSAGEMAN:Broadcast("MouseDown", {event = event})
		end
	end
	return false
end

local function UpdateTime(self)
	local year = Year()
	local month = MonthOfYear() + 1
	local day = DayOfMonth()
	local hour = Hour()
	local minute = Minute()
	local second = Second()
	self:GetChild("CurrentTime"):settextf("%04d-%02d-%02d %02d:%02d:%02d", year, month, day, hour, minute, second)

	local sessiontime = GAMESTATE:GetSessionTime()
	self:GetChild("SessionTime"):settextf("%s: %s", "Session Time", SecondsToHHMMSS(sessiontime))
	self:diffuse(nonButtonColor)
end


local hoverAlpha = 0.6

local t = Def.ActorFrame {
	BeginCommand = function(self)
		local s = SCREENMAN:GetTopScreen()
		s:AddInputCallback(input)
		setenv("NewOptions","Main")
	end
}

t[#t + 1] = Def.Actor {
	CodeMessageCommand = function(self, params)
		if params.Name == "AvatarShow" and getTabIndex() == 0 and not SCREENMAN:get_input_redirected(PLAYER_1) then
			SCREENMAN:SetNewScreen("ScreenAssetSettings")
		end
	end,
	OnCommand = function(self)
		inScreenSelectMusic = true
	end,
	EndCommand = function(self)
		inScreenSelectMusic = nil
	end,
}

if showVisualizer then
	local vis = audioVisualizer:new {
		x = SCREEN_CENTER_X - (SCREEN_CENTER_X / 3),
		y = 455,
		maxHeight = 30,
		freqIntervals = audioVisualizer.multiplyIntervals(audioVisualizer.defaultIntervals, 5),
		color = getMainColor("positive"),
		onBarUpdate = function(self)
			--[
			self:fadetop(1)
			self:diffuse(getMainColor("positive"))
			--]]
			--[[
			self:diffuselowerleft()
			self:diffuseupperleft()
			self:diffuselowerright()
			self:diffuseupperright()
			--]]
		end
	}
	t[#t + 1] = vis
end

t[#t + 1] = LoadActor("../_frame")
t[#t + 1] = LoadActor("../_PlayerInfo")
t[#t + 1] = LoadActor("tabs")
t[#t + 1] = LoadActor("profile")



t[#t + 1] = LoadActor("wifetwirl")
t[#t + 1] = LoadActor("mplayer")
t[#t + 1] = LoadActor("currentsort")
t[#t + 1] = LoadActor("searchredirect")

--test button
t[#t + 1] = UIElements.TextToolTip(1, 1, "Common Large") .. {
	Name="TestEventMouseButton",
	InitCommand = function(self)
		self:xy(SCREEN_CENTER_X + 240, 30):halign(1):valign(1):zoom(0.2):diffuse(getMainColor("positive")):diffusealpha(1)
		self:settext("test")
	end,
	MouseOverCommand = function(self)
		self:diffusealpha(hoverAlpha)
	end,
	MouseOutCommand = function(self)
		self:diffusealpha(1)
	end,
	MouseDownCommand = function(self, params)
		if params.event == "DeviceButton_left mouse button" then
			local path = PROFILEMAN:GetProfileDir(1)
			local tild = path .. "Til Death_settings/playerConfig.lua"
			ms.ok(tild)
		end
	end
}

local prevplayerops = "Main"

t[#t + 1] = UIElements.SpriteButton(1, 1, THEME:GetPathG("", "playerOptionsButton")) .. {
	Name = "PlayerOptionsButton",
	BeginCommand = function(self)
		self:xy(SCREEN_CENTER_X + capWideScale(-180,220), SCREEN_BOTTOM - 12):halign(0):zoomto(17,17)
		self:diffusealpha(1)
	end,
	MouseOverCommand = function(self)
		self:diffusealpha(0.7)
	end,
	MouseOutCommand = function(self)
		self:diffusealpha(1)
	end,
	MouseDownCommand = function(self, params)
		local songp = GAMESTATE:GetCurrentSong()
		if params.event == "DeviceButton_left mouse button" and songp then
			SCREENMAN:GetTopScreen():OpenOptions()
		end
	end,
	OptionsScreenClosedMessageCommand = function(self)
		local nextplayerops = getenv("NewOptions") or "Main" --wtf

		if nextplayerops == prevplayerops then
			setenv("NewOptions", "Main")
			prevplayerops = "Main"
			return
		end

		prevplayerops = nextplayerops
		setenv("NewOptions", nextplayerops)
		SCREENMAN:GetTopScreen():OpenOptions() --softlock potential ?
	end
}

local tooltipOver = false

t[#t + 1] = LoadActor("../_volumecontrol")


t[#t + 1] = Def.ActorFrame {
	InitCommand = function(self)
		self:SetUpdateFunction(UpdateTime)
	end,
	LoadFont("Common Normal") .. {
		Name = "CurrentTime",
		InitCommand = function(self)
			self:xy(SCREEN_WIDTH - 3, 15):halign(1):valign(1):zoom(0.45)
		end
	},

	LoadFont("Common Normal") .. {
		Name = "SessionTime",
		InitCommand = function(self)
			self:xy(SCREEN_WIDTH - 3, 28):halign(1):valign(1):zoom(0.45)
		end
	}
}




t[#t + 1] = LoadActor("../_cursor")
t[#t + 1] = LoadActor("../_halppls")

collectgarbage()
updateDiscordStatusForMenus()
updateNowPlaying()

return t
