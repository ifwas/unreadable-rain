local itsOn = false -- chart preview state
local stepsdisplayx = 5
local thesteps = {}

local rowwidth = 35
local rowheight = 17
local cursorwidth = 6
local cursorheight = rowheight
local offsetthing = cursorwidth

local numshown = 7
local currentindex = 1
local displayindexoffset = 0

local sd = Def.ActorFrame {
	Name = "StepsDisplay",
	InitCommand = function(self)
		self:xy(stepsdisplayx, SCREEN_BOTTOM - 50):valign(0)
	end,
	OffCommand = function(self)
		self:visible(false)
	end,
	OnCommand = function(self)
		self:visible(true)
	end,
	TabChangedMessageCommand = function(self, params)
		self:finishtweening()
		if getTabIndex() < 3 and GAMESTATE:GetCurrentSong() then
			-- dont display this if the score nested tab is already online
			-- prevents repeat 3 presses to break the display
			-- (let page 2 handle this specifically)
			if params.to == 2 then
				return
			end
			self:playcommand("On")
			self:playcommand("UpdateStepsRows")
		else
			self:playcommand("Off")
		end
	end,
	CurrentSongChangedMessageCommand = function(self, song)
		local song = song.ptr
		if song then
			thesteps = song:GetChartsMatchingFilter()
			if self.nested and getTabIndex() == 2 then
				return
			end

			-- if in online scores tab it still pops up for 1 frame
			-- so the bug fixed in the above command makes a return
			-- how sad
			if getTabIndex() < 3 then
				self:playcommand("On")
			end
			self:playcommand("UpdateStepsRows")
		else
			self:playcommand("Off")
		end
	end,
	DelayedChartUpdateMessageCommand = function(self)
		local leaderboardEnabled =
			playerConfig:get_data(pn_to_profile_slot(PLAYER_1)).leaderboardEnabled and DLMAN:IsLoggedIn()
		if leaderboardEnabled and GAMESTATE:GetCurrentSteps() then
			local chartkey = GAMESTATE:GetCurrentSteps():GetChartKey()
			if SCREENMAN:GetTopScreen():GetMusicWheel():IsSettled() then
				DLMAN:RequestChartLeaderBoardFromOnline(
					chartkey,
					function(leaderboard)
					end
				)
			end
		end
	end
}

local function stepsRows(i)
	local o = Def.ActorFrame {
		InitCommand = function(self)
			self:x(rowwidth * (i - 1) + offsetthing * (i - 1))
		end,
		UIElements.QuadButton(1, 1) .. {
			InitCommand = function(self)
				self:zoomto(rowwidth, rowheight):halign(0)
			end,
			UpdateStepsRowsCommand = function(self)
				local steps = thesteps[i + displayindexoffset]
				if steps then
					self:visible(true)
					local diff = steps:GetDifficulty()
					self:diffuse(getDifficultyColor(diff))
					self:diffusealpha(0.4)
				else
					self:visible(false)
				end
			end,
			MouseDownCommand = function(self, params)
				local steps = thesteps[i + displayindexoffset]
				if steps and params.event == "DeviceButton_left mouse button" then
					SCREENMAN:GetTopScreen():ChangeSteps(i - currentindex)
				end
			end
		},
		Def.Quad {
			InitCommand = function(self)
				self:zoomto(18, rowheight):halign(0)
			end,
			UpdateStepsRowsCommand = function(self)
				local steps = thesteps[i + displayindexoffset]
				if steps then
					self:visible(true)
					local diff = steps:GetDifficulty()
					self:diffuse(byDifficulty(diff))
				else
					self:visible(false)
				end
			end
		},
		-- Chart defined "Meter" value, not msd (useful to have this for reference)
		LoadFont("Common Large") .. {
			InitCommand = function(self)
				self:x(rowwidth / 1.3):addy(-1):zoom(0.2):settext(""):halign(0.5):maxwidth(75)
			end,
			UpdateStepsRowsCommand = function(self)
				local steps = thesteps[i + displayindexoffset]
				if steps then
					self:settext(steps:GetMeter())
				else
					self:settext("")
				end
			end
		},
		--chart difficulty name
		LoadFont("Common Large") .. {
			InitCommand = function(self)
				self:x(10):zoom(0.16):settext(""):halign(0.5):valign(0)
			end,
			UpdateStepsRowsCommand = function(self)
				local steps = thesteps[i + displayindexoffset]
				if steps then
				local diff = steps:GetDifficulty()
					self:settext(getShortDifficulty(diff))
				else
					self:settext("")
				end
			end
		},
		--chart steps type
		LoadFont("Common Large") .. {
			InitCommand = function(self)
				self:x(10):addy(-9):zoom(0.16):settext(""):halign(0.5):valign(0):maxwidth(23 / 0.18)
			end,
			UpdateStepsRowsCommand = function(self)
				local steps = thesteps[i + displayindexoffset]
				if steps then
				local st = THEME:GetString("StepsDisplay StepsType", ToEnumShortString(steps:GetStepsType()))
					self:settext(st)
				else
					self:settext("")
				end
			end
		}
	}

	return o
end

local sdr = Def.ActorFrame {
	Name = "StepsRows",
}

for i = 1, numshown do
	sdr[#sdr + 1] = stepsRows(i)
end
sd[#sd + 1] = sdr

local center = math.ceil(numshown / 2)
-- cursor goes on top
sd[#sd + 1] = Def.Quad {
	Name = "StepsCursor",
	InitCommand = function(self)
		self:x(rowwidth):zoomto(cursorwidth, cursorheight):halign(1):valign(0.5):diffusealpha(0.6)
	end,
	CurrentStepsChangedMessageCommand = function(self, steps)
		for i = 1, 20 do
			if thesteps and thesteps[i] and thesteps[i] == steps.ptr then
				currentindex = i
				break
			end
		end

		if currentindex <= center then
			displayindexoffset = 0
		elseif #thesteps - displayindexoffset > numshown then
			displayindexoffset = currentindex - center
			currentindex = center
		else
			currentindex = currentindex - displayindexoffset
		end

		if #thesteps > numshown and #thesteps - displayindexoffset < numshown then
			displayindexoffset = #thesteps - numshown
		end

		self:finishtweening()
		self:smooth(0.03):x(cursorwidth + rowwidth * (currentindex) + offsetthing * (currentindex - 1))

		if self:GetParent():GetVisible() then
			self:GetParent():GetChild("StepsRows"):playcommand("UpdateStepsRows")
		end
	end
}

return sd
