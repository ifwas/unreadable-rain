local tzoom = 0.5
local wifetzoom = 0.4
local pdh = (48 * 1.5) * tzoom
local ygap = 2
local packspaceY = pdh + ygap
local currentCountry = "Global"

local cyear = Year()
local cmonth = MonthOfYear() + 1
local cday 
local chour 
local cminute 
local csecond

local motnt = {31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31}
local leapmnt = {31, 29, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31}

local numscores = 10
local ind = 0
local offx = 5
local width = 202
local dwidth = width - offx * 2
local height = (numscores + 2) * packspaceY - packspaceY / 3 -- account dumbly for header being moved up

local adjx = 8
local c0x = 5
local c1x = 30 + c0x
local c2x = c1x + (tzoom * 7 * adjx) -- guesswork adjustment for epxected text length
local c5x = dwidth - 4 -- right aligned cols
local c4x = c5x - adjx - (tzoom * 3 * adjx) -- right aligned cols
local c3x = c4x - adjx - (tzoom * 10 * adjx) -- right aligned cols
local headeroff = packspaceY / 2
local row2yoff = 1
local moving
local cheese
local collapsed = false

local yup = 16
local yup1 = 17 + yup


local isGlobalRanking = true

-- will eat any mousewheel inputs to scroll pages while mouse is over the background frame
local function input(event)
	if isOver(cheese:GetChild("FrameDisplay")) then -- visibility checks are built into isover now -mina
		if event.DeviceInput.button == "DeviceButton_mousewheel up" and event.type == "InputEventType_FirstPress" then
			moving = true
			cheese:queuecommand("PrevPage")
			return true
		elseif event.DeviceInput.button == "DeviceButton_mousewheel down" and event.type == "InputEventType_FirstPress" then
			cheese:queuecommand("NextPage")
			return true
		elseif moving == true then
			moving = false
		end
	end
	return false
end

local hoverAlpha = 0.6

local filts = {
	THEME:GetString("NestedScores", "FilterAll"),
	THEME:GetString("NestedScores", "FilterCurrent")
}
local topornah = {
	THEME:GetString("NestedScores", "ScoresTop"),
	THEME:GetString("NestedScores", "ScoresAll")
}
local ccornah = {
	THEME:GetString("NestedScores", "ShowInvalid"),
	THEME:GetString("NestedScores", "HideInvalid")
}

local translated_info = {
	LoginToView = THEME:GetString("NestedScores", "LoginToView"),
	NoScoresFound = THEME:GetString("NestedScores", "NoScoresFound"),
	RetrievingScores = THEME:GetString("NestedScores", "RetrievingScores"),
	Watch = THEME:GetString("NestedScores", "WatchReplay"),
	NoReplay = THEME:GetString("NestedScores", "NoReplay"),
}

local scoretable = {}
local o = Def.ActorFrame {
	Name = "ScoreDisplay",
	InitCommand = function(self)
		cheese = self
	end,
	BeginCommand = function(self)
		SCREENMAN:GetTopScreen():AddInputCallback(input)
		self:playcommand("Update")
	end,
	GetFilteredLeaderboardCommand = function(self)
		if GAMESTATE:GetCurrentSong() then
			scoretable = DLMAN:GetChartLeaderBoard(GAMESTATE:GetCurrentSteps():GetChartKey(), currentCountry)
			ind = 0
			self:playcommand("Update")
		end
	end,
	SetFromLeaderboardCommand = function(self, lb)
		scoretable = lb
		ind = 0
		self:playcommand("GetFilteredLeaderboard") -- we can move all the filter stuff to lua so we're not being dumb hurr hur -mina
		self:playcommand("Update")
	end,
	UpdateCommand = function(self)
		if not scoretable then
			ind = 0
			return
		end
		if ind == #scoretable then
			ind = ind - numscores
		elseif ind > #scoretable - (#scoretable % numscores) then
			ind = #scoretable - (#scoretable % numscores)
		end
		if ind < 0 then
			ind = 0
		end

		cday = DayOfMonth()
		chour = Hour()
		cminute = Minute()
		csecond = Second()
	end,
	NextPageCommand = function(self)
		ind = ind + numscores
		self:queuecommand("Update")
	end,
	PrevPageCommand = function(self)
		ind = ind - numscores
		self:queuecommand("Update")
	end,
	UIElements.QuadButton(1, 1) .. {-- this is a nonfunctional button to mask buttons behind the window
		Name = "FrameDisplay",
		InitCommand = function(self)
			self:zoomto(width, height - headeroff):halign(0):valign(0):diffusealpha(0)
		end
	},
	Def.Sprite {
		Name = "RequestLoop",
		Texture = THEME:GetPathG("", "wait"),
		InitCommand = function(self)
			self:xy(98, headeroff + 200):zoomto(50,50):halign(0.5):valign(0.5)
			self:diffuse(Brightness(getMainColor("positive"),0.6))
			self:diffusealpha(0.4)
			self:spin():effectclock("timerglobal")
			self:visible(false)
		end
	},
	LoadFont("Common normal") .. {
		-- informational text about online scores
		Name = "RequestStatus",
		InitCommand = function(self)
			self:xy(c1x, headeroff + 25):zoom(tzoom):halign(0)
		end,
		UpdateCommand = function(self)
			local somethinwrong = false
			local numberofscores = scoretable ~= nil and #scoretable or 0
			local online = DLMAN:IsLoggedIn()
			if not GAMESTATE:GetCurrentSong() then
				self:settext("")
			elseif not online and scoretable ~= nil and #scoretable == 0 then
				somethinwrong = true
				self:settext(translated_info["LoginToView"])
			else
				if scoretable ~= nil and #scoretable == 0 then
					somethinwrong = true
				elseif scoretable == nil then
					somethinwrong = true
					self:settext("Chart is not ranked")
				else
					self:settext("")
				end
			end

			if somethinwrong == true then 
				self:GetParent():GetChild("RequestLoop"):visible(true)
			else
				self:GetParent():GetChild("RequestLoop"):visible(false)
			end
		end,
		CurrentSongChangedMessageCommand = function(self)
			local fine = false
			local online = DLMAN:IsLoggedIn()
			if not GAMESTATE:GetCurrentSong() then
				self:settext("")
			elseif not online and scoretable ~= nil and #scoretable == 0 then
				fine = true
				self:settext(translated_info["LoginToView"])
			elseif scoretable == nil then
				fine = true
				self:settext("Chart is not ranked")
			else
				fine = true
			end

			if fine == true then 
				self:GetParent():GetChild("RequestLoop"):visible(true)
			else
				self:GetParent():GetChild("RequestLoop"):visible(false)
			end
		end
	},
	UIElements.TextToolTip(1, 1, "Common Normal") .. {
		--current rate toggle
		InitCommand = function(self)
			self:xy(c5x - 3, headeroff + 15):zoom(tzoom):halign(1):valign(1)
			self:diffuse(getMainColor("positive"))
		end,
		MouseOverCommand = function(self)
			self:diffusealpha(hoverAlpha)
		end,
		MouseOutCommand = function(self)
			self:diffusealpha(1)
		end,
		UpdateCommand = function(self)
			if DLMAN:GetCurrentRateFilter() then
				self:settext(filts[2])
			else
				self:settext("Top MSD")
			end
		end,
		MouseDownCommand = function(self, params)
			if params.event == "DeviceButton_left mouse button" then
				DLMAN:ToggleRateFilter()
				ind = 0
				self:GetParent():queuecommand("GetFilteredLeaderboard")
			end
		end
	},
	UIElements.TextToolTip(1, 1, "Common Normal") .. {
		--top score/all score toggle
		InitCommand = function(self)
			self:diffuse(getMainColor("positive"))
			self:xy(c5x - capWideScale(160,180), headeroff + 15):zoom(tzoom):halign(0):valign(1)
		end,
		MouseOverCommand = function(self)
			self:diffusealpha(hoverAlpha)
		end,
		MouseOutCommand = function(self)
			self:diffusealpha(1)
		end,
		UpdateCommand = function(self)
			if DLMAN:GetTopScoresOnlyFilter() then
				self:settext(topornah[1])
			else
				self:settext(topornah[2])
			end
		end,
		MouseDownCommand = function(self, params)
			if params.event == "DeviceButton_left mouse button" then
				DLMAN:ToggleTopScoresOnlyFilter()
				ind = 0
				self:GetParent():queuecommand("GetFilteredLeaderboard")
			end
		end
	},
	UIElements.TextToolTip(1, 1, "Common Normal") .. {
		--ccon/off filter toggle
		InitCommand = function(self)
			self:diffuse(getMainColor("positive")):diffusealpha(0.1)
			self:xy(c5x, headeroff):zoom(tzoom):halign(1):valign(1)
		end,
		MouseOverCommand = function(self)
			self:diffusealpha(hoverAlpha)
		end,
		MouseOutCommand = function(self)
			self:diffusealpha(0.1)
		end,
		UpdateCommand = function(self)
			if DLMAN:GetValidFilter() then
				self:settext(ccornah[1])
			else
				self:settext(ccornah[2])
			end
		end,
		MouseDownCommand = function(self, params)
			if params.event == "DeviceButton_left mouse button" then
				DLMAN:ToggleValidFilter()
				ind = 0
				self:GetParent():queuecommand("GetFilteredLeaderboard")
			end
		end
	}
}

local function makeScoreDisplay(i)
	local hs

	local o = Def.ActorFrame {
		Name = "Scoredisplay_"..i,
		InitCommand = function(self)
			self:xy(5,packspaceY * i + headeroff)
			self:diffusealpha(0)
			if i > numscores or hs == nil then
				self:visible(false)
			else
				self:visible(true)
				self:playcommand("showScoreItem")
			end
		end,
		CurrentSongChangedMessageCommand = function(self)
			self:diffusealpha(0)
			self:visible(false)
		end,
		UpdateCommand = function(self)
			self:finishtweening()
			self:diffusealpha(0)
			if scoretable ~= nil then
				hs = scoretable[(i + ind)]
			else
				hs = nil
			end
			if hs and i <= numscores then
				self:visible(true)
				self:playcommand("Display")
				self:playcommand("showScoreItem")
			else
				self:visible(false)
			end
		end,
		showScoreItemCommand = function(self)
			self:y(packspaceY * i + headeroff + 10):decelerate(0.2 + 0.03 * i):diffusealpha(1):y(packspaceY * i + headeroff)
		end,
		NestedTabChangedMessageCommand = function(self)
			if i > numscores or hs == nil then
				self:visible(false)
			else
				self:visible(true)
				self:playcommand("Display")
				self:playcommand("showScoreItem")
			end
		end,
		UIElements.QuadButton(1, 1) .. {-- this is a non functional button to mask buttons behind the box
			InitCommand = function(self)
				self:zoomto(dwidth, pdh):halign(0)
			end,
			DisplayCommand = function(self)
				self:diffuse(color("#181818cc"))
				self:diffusealpha(1)
			end,
		},
		LoadFont("Common normal") .. {
			--ssr
			InitCommand = function(self)
				self:x(yup):zoom(0.45):halign(0.5):valign(1)
			end,
			DisplayCommand = function(self)
				local ssr = hs:GetSkillsetSSR("Overall")
				self:settextf("%.2f", ssr):diffuse(byMSD(ssr))
			end
		},
		LoadFont("Common normal") .. {
			--rate
			InitCommand = function(self)
				self:xy(yup, 2):zoom(tzoom - 0.1):halign(0.5):valign(0)
			end,
			DisplayCommand = function(self)
				local ratestring = string.format("%.2f", hs:GetMusicRate()):gsub("%.?0$", "") .. "x"
				self:settext(ratestring)
			end
		},
		UIElements.TextToolTip(1, 1, "Common Normal") .. {
			Name = "Burt" .. i,
			InitCommand = function(self)
				self:x(yup1):zoom(tzoom + 0.04):maxwidth((dwidth) / tzoom):halign(0):valign(1)
			end,
			DisplayCommand = function(self)
				self:zoom(tzoom + 0.04)
				local nameeee = hs:GetDisplayName()
				if #nameeee > 13 then
					self:zoom(tzoom * (13 / #nameeee) + 0.04)
				end
				self:settext(nameeee)
				if not hs:GetEtternaValid() then
					self:diffuse(color("#F0EEA6"))
				else
					self:diffuse(getMainColor("positive"))
				end
			end,
			MouseOverCommand = function(self)
				self:diffusealpha(hoverAlpha)
			end,
			MouseOutCommand = function(self)
				self:diffusealpha(1)
			end,
			MouseDownCommand = function(self, params)
				if params.event == "DeviceButton_left mouse button" then
					DLMAN:ShowUserPage(hs:GetDisplayName())
				end
			end
		},
		UIElements.TextToolTip(1, 1, "Common Normal") .. {
			Name = "Ernie" .. i,
			InitCommand = function(self)
				self:xy(yup1, 4):zoom(wifetzoom - 0.05):halign(0):valign(0):maxwidth(width / wifetzoom / 1.4)
			end,
			DisplayCommand = function(self)
				local marv = scoretable[i + ind]:GetTapNoteScore("TapNoteScore_W1")
				local perfects = scoretable[i + ind]:GetTapNoteScore("TapNoteScore_W2")
				local greats = scoretable[i + ind]:GetTapNoteScore("TapNoteScore_W3")
				local goods = scoretable[i + ind]:GetTapNoteScore("TapNoteScore_W4")
				local boo = scoretable[i + ind]:GetTapNoteScore("TapNoteScore_W5")
				local miss = scoretable[i + ind]:GetTapNoteScore("TapNoteScore_W5")
				local combo = scoretable[i + ind]:GetMaxCombo()

				self:settextf("%d / %d / %d / %d / %d / %d (%dx)", marv, perfects, greats, goods, boo, miss, combo)

				if not hs:GetEtternaValid() then
					self:diffuse(color("#F0EEA6"))
				else
					self:diffuse(color("#FFFFFF"))
				end
			end,
			MouseOverCommand = function(self)
				self:diffusealpha(hoverAlpha)
			end,
			MouseOutCommand = function(self)
				self:diffusealpha(1)
			end,
			MouseDownCommand = function(self, params)
				if params.event == "DeviceButton_left mouse button" then
					DLMAN:ShowScorePage(hs:GetDisplayName(), hs:GetScoreid())
				end
			end
		},

		--[[ --wife version display ... not 100% reliable
		LoadFont("Common normal") .. {
			Name = "WifeVers" .. i,
			InitCommand = function(self)
				if not collapsed then
					self:x(capWideScale(c3x + 52, c3x)):zoom(tzoom - 0.25):halign(1):valign(0.5):maxwidth(width / 2 / tzoom):diffuse(getMainColor("negative")):addy(-pdh/4)
				end
			end,
			DisplayCommand = function(self)
				if hs:GetWifeVers() ~= 3 then
					self:settextf("W2/XML", hs:GetWifeVers())
				else
					self:settext("")
				end
			end,
			CollapseCommand = function(self)
				self:visible(false)
			end,
			ExpandCommand = function(self)
				self:visible(true)
			end
		},
		]]
		UIElements.SpriteButton(1, 1) .. {
			Name = "Replay" .. i,
			Texture = THEME:GetPathG("", "showReplay"),
			InitCommand = function(self)
				if not collapsed then
					self:x(c3x + 25):zoom(tzoom * 1):halign(1):valign(1):addy(
						row2yoff
					)
				end
			end,
			BeginCommand = function(self)
				if SCREENMAN:GetTopScreen():GetName() == "ScreenNetSelectMusic" then
					self:visible(false)
				end
			end,
			DisplayCommand = function(self)
				if GAMESTATE:GetCurrentSteps() then
					if hs:HasReplayData() then
						self:diffusealpha(1)
					else
						self:diffusealpha(0)
					end
				end
			end,
			MouseOverCommand = function(self)
				self:diffusealpha(hoverAlpha)
			end,
			MouseOutCommand = function(self)
				self:diffusealpha(1)
			end,
			MouseDownCommand = function(self, params)
				if params.event == "DeviceButton_left mouse button" and hs then
					DLMAN:RequestOnlineScoreReplayData(
						hs,
						function()
							if hs:GetReplay():HasReplayData() then
								SCREENMAN:GetTopScreen():PlayReplay(hs)
							else
								ms.ok(translated_info["NoReplay"])
							end
						end
					)
				end
			end
		},
		UIElements.QuadButton(1, 1) .. {
			InitCommand = function(self)
				self:x(c5x):zoomto(50,10):halign(1):valign(1)
				if collapsed then
					self:x(c5x):zoomto(40, 10):halign(1):valign(0.5)
				end
				self:diffusealpha(0)
			end,
			MouseOverCommand = function(self)
				if self:IsVisible() then
					self:GetParent():GetChild("NormalText"):visible(false)
					self:GetParent():GetChild("Replay" .. i):x(c3x + 10)
					self:GetParent():GetChild("LongerText"):visible(true)
				end
			end,
			MouseOutCommand = function(self)
				if self:IsVisible() then
					self:GetParent():GetChild("NormalText"):visible(true)
					self:GetParent():GetChild("Replay" .. i):x(c3x + 25)
					self:GetParent():GetChild("LongerText"):visible(false)
				end
			end,
			MouseDownCommand = function(self, params)
				if params.event == "DeviceButton_left mouse button" and hs and not collapsed then
					if SCREENMAN:GetTopScreen():GetName() == "ScreenNetSelectMusic" then return end
					if hs:HasReplayData() then
						DLMAN:RequestOnlineScoreReplayData(
							hs,
							function()
								setScoreForPlot(hs)
								SCREENMAN:AddNewScreenToTop("ScreenScoreTabOffsetPlot")
							end
						)
					end
				end
			end
		},
		LoadFont("Common normal") .. {
			--percent
			Name="NormalText",
			InitCommand = function(self)
				self:x(c5x):zoom(tzoom):halign(1):valign(1)
				if collapsed then
					self:x(c5x):zoom(tzoom + 0.15):halign(1):valign(0.5):maxwidth(30 / tzoom)
				end
			end,
			DisplayCommand = function(self)
				self:settextf("%05.2f%%", notShit.floor(hs:GetWifeScore() * 100, 2)):diffuse(byGrade(hs:GetWifeGrade()))
			end
		},
		LoadFont("Common normal") .. {
			--percent
			Name="LongerText",
			InitCommand = function(self)
				self:x(c5x):zoom(tzoom):halign(1):valign(1)
				if collapsed then
					self:x(c5x):zoom(tzoom + 0.15):halign(1):valign(0.5):maxwidth(30 / tzoom)
				end
				self:visible(false)
			end,
			DisplayCommand = function(self)
				local perc = hs:GetWifeScore() * 100
				self:settextf("%05.4f%%", notShit.floor(perc, 4))
				self:diffuse(byGrade(hs:GetWifeGrade()))
			end
		},
		UIElements.TextToolTip(1, 1, "Common Normal") .. {
			--date
			InitCommand = function(self)
				self:xy(c5x, 4):zoom(tzoom - 0.05):halign(1):valign(0):maxwidth(width / 4 / tzoom)
			end,
			DisplayCommand = function(self)
				local mhmyep = ""
				local syear = hs:GetDate():sub(1, 4)
				local smonth = hs:GetDate():sub(6, 7)
				local sday = hs:GetDate():sub(9, 10)
				local shour = hs:GetDate():sub(12, 13)
				local sminutes = hs:GetDate():sub(15, 16)
				local sseconds = hs:GetDate():sub(18, 19)


				local passedyear = cyear - syear
				local passedmonth = cmonth - smonth
				local passeday = cday - sday
				local passedhour = chour - shour
				local passedmin = cminute - sminutes
				local passedsec = csecond - sseconds

				if passedyear ~= 0 then
					mhmyep = passedyear .. "y"
				elseif passedmonth >= 1 then
					mhmyep = passedmonth .. "mo"
				elseif passeday ~= 0 then
					mhmyep = passeday .. "d"
				elseif passedhour ~= 0 then
					mhmyep = passedhour .. "h"
				elseif passedmin ~= 0 then
					mhmyep = passedmin .. "min"
				elseif passedsec ~= 0 then
					mhmyep = passedsec .. "sec"
				end

				self:settext(mhmyep)
			end,
			MouseOverCommand = function(self)
				local e = hs:GetDate()
				TOOLTIP:SwitchSide(false)
				TOOLTIP:SetText(e)
				TOOLTIP:Show()
			end,
			MouseOutCommand = function(self)
				TOOLTIP:Hide()
			end
		}
	}
	return o
end

for i = 1, numscores do
	o[#o + 1] = makeScoreDisplay(i)
end

--[[
--Commented for now
-- Todo: make the combobox scrollable
-- To handle a large amount of choices
local countryDropdown
countryDropdown =
	Widg.ComboBox {
	onSelectionChanged = function(newChoice)
		currentCountry = newChoice
		cheese:queuecommand("ChartLeaderboardUpdate")
	end,
	choice = "Global",
	choices = DLMAN:GetCountryCodes(),
	commands = {
		CollapseCommand = function(self)
			self:xy(c5x - 20, headeroff - 20):halign(0)
		end,
		ExpandCommand = function(self)
			self:xy(c5x - 89, headeroff)
		end,
		ChartLeaderboardUpdateMessageCommand = function(self)
			self:visible(DLMAN:IsLoggedIn())
		end
	},
	selectionColor = color("#111111"),
	itemColor = color("#111111"),
	hoverColor = getMainColor("highlight"),
	height = tzoom * 29,
	width = 50,
	x = c5x - 89, -- needs to be thought out for design purposes
	y = headeroff,
	visible = DLMAN:IsLoggedIn(),
	numitems = 4
}
o[#o + 1] = countryDropdown
]]
return o
