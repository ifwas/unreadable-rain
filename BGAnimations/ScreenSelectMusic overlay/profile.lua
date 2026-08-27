local update = false
local showOnline = false
local recentactive = false
local percentactive = false
local frameX = 202
local frameY = 134
local frameWidth = capWideScale(360, SCREEN_WIDTH - 182 - 202)
local frameHeight = SCREEN_HEIGHT - 25.776 - 34 - 100

local translated_info = {
	Validated = THEME:GetString("TabProfile", "ScoreValidated"),
	Invalidated = THEME:GetString("TabProfile", "ScoreInvalidated"),
	Online = THEME:GetString("TabProfile", "Online"),
	Local = THEME:GetString("TabProfile", "Local"),
	Recent = THEME:GetString("TabProfile", "Recent"),
	Percent = THEME:GetString("TabProfile", "Percent"),
	NextPage = THEME:GetString("TabProfile", "NextPage"),
	PrevPage = THEME:GetString("TabProfile", "PreviousPage"),
	Save = THEME:GetString("TabProfile", "SaveProfile"),
	AssetSettings = THEME:GetString("TabProfile", "AssetSettingEntry"),
	Success = THEME:GetString("TabProfile", "SaveSuccess"),
	Failure = THEME:GetString("TabProfile", "SaveFail"),
	ValidateAll = THEME:GetString("TabProfile", "ValidateAllScores"),
	ForceRecalc = THEME:GetString("TabProfile", "ForceRecalcScores"),
	UploadAllScore = THEME:GetString("TabProfile", "UploadAllScore"),
	ClickLogin = THEME:GetString("GeneralInfo", "ClickToLogin"),
	ClickLogout = THEME:GetString("GeneralInfo", "ClickToLogout"),
	NotLoggedIn = THEME:GetString("GeneralInfo", "NotLoggedIn"),
	LoggedInAs = THEME:GetString("GeneralInfo", "LoggedInAs.."),
	LoginFailed = THEME:GetString("GeneralInfo", "LoginFailed"),
	LoginSuccess = THEME:GetString("GeneralInfo", "LoginSuccess"),
	LoginCanceled = THEME:GetString("GeneralInfo", "LoginCanceled"),
	Password = THEME:GetString("GeneralInfo","Password"),
	Username = THEME:GetString("GeneralInfo","Email"),
}

local function BroadcastIfActive(msg)
	if update then
		MESSAGEMAN:Broadcast(msg)
	end
end

local t = Def.ActorFrame {
	BeginCommand = function(self)
		self:queuecommand("Set"):visible(false)
	end,
	OffCommand = function(self)
		self:smooth(0.2):diffusealpha(0)
		self:sleep(0.04):queuecommand("Invis")
		MESSAGEMAN:Broadcast("ProfileTabOff")
	end,
	InvisCommand= function(self)
		self:visible(false)
	end,
	OnCommand = function(self)
		self:smooth(0.2):diffusealpha(1)
		MESSAGEMAN:Broadcast("ProfileTabOn")
	end,
	SetCommand = function(self)
		self:finishtweening()
		if getTabIndex() == 4 or SCREENMAN:GetTopScreen():GetName() == "ScreenNetRoom" and getTabIndex() == 1 then
			self:queuecommand("On")
			self:visible(true)
			update = true
		else
			self:queuecommand("Off")
			update = false
		end
	end,
	LogOutMessageCommand = function(self)
		showOnline = false
		BroadcastIfActive("UpdateRanking")
	end,
	LoginMessageCommand = function(self)
		BroadcastIfActive("UpdateRanking")
	end,
	LoginFailedMessageCommand = function(self)
		BroadcastIfActive("UpdateRanking")
	end,
	OnlineUpdateMessageCommand = function(self)
		BroadcastIfActive("UpdateRanking")
	end,
	TabChangedMessageCommand = function(self)
		self:queuecommand("Set")
	end,
	Def.Quad {
		Name = "FrameDisplay",
		InitCommand = function(self)
			self:xy(frameX, frameY):zoomto(frameWidth, frameHeight):halign(0):valign(0):diffuse(color("#0d0d0dff")):diffusealpha(1)
		end,
	},
	LoadFont("Common Large") .. {
		InitCommand = function(self)
			self:xy(100, 45):zoom(0.3)
			self:settext("Skills Mastered:"):diffuse(getMainColor("positive"))
		end,
	},
}


local fontScale = 0.25
local scoresperpage = 10
local scoreYspacing = 27
local distY = 15
local offsetX = -10
local offsetY = 20
local txtDist = 33
local rankingSkillset = 1
local rankingPage = 1
local numrankingpages = 20
local rankingWidth = frameWidth - capWideScale(10, 25)
local rankingX = capWideScale(25, 35)
local rankingY = capWideScale(40, 40)
local rankingTitleSpacing = (rankingWidth / (#ms.SkillSets))
local buttondiffuse = 0
local whee
local profile

if GAMESTATE:IsPlayerEnabled() then
	profile = GetPlayerOrMachineProfile(PLAYER_1)
end

local hoverAlpha = 0.6

local function byValidity(valid)
	if valid then
		return getMainColor("positive")
	end
	return byJudgment("TapNoteScore_Miss")
end

local function ButtonActive(self)
	return isOver(self) and update
end

-- The input callback for mouse clicks already exists within the tabmanager and redefining it within the local scope does nothing but create confusion - mina
local r = Def.ActorFrame {
	InitCommand = function(self)
		self:xy(frameX, frameY)
	end,
	OnCommand = function(self)
		whee = SCREENMAN:GetTopScreen():GetMusicWheel()
	end
}

local fuck = 29

local function rankingLabel(i)
	local ths  -- the top highscore object - mina
	local ck
	local thssteps
	local thssong
	local xoffset
	local onlineScore

	local t = Def.ActorFrame {
		InitCommand = function(self)
			self:xy(rankingX + offsetX - 20, 15 + (i - 1) * fuck):halign(1)
			-- self:RunCommandsOnChildren(cmd(halign,0;zoom,fontScale))
			self:visible(false)
		end,
		BeginCommand = function(self)
			--hack that's similar to that one hack on memento mori, but instead of putting the recent tab
			--as the first thing to boot up, we actually use it to put the overall scores while we start the tab
			--not sure if i'll go towards the recent scores later on.......
			rankingPage = 1
			update = true
			rankingSkillset = 1
			SCOREMAN:SortSSRsForGame(ms.SkillSets[rankingSkillset])
			MESSAGEMAN:Broadcast("UpdateRanking")
			update = false
		end,
		UpdateRankingMessageCommand = function(self)
			self:finishtweening()
			self:diffusealpha(0.2):x(rankingX + offsetX - 20)
			if update and not recentactive then
				self:sleep(0.04 + (0.005 * i)) --this makes stutters happen less often, i hope so
				if not showOnline then
					ths = SCOREMAN:GetTopSSRHighScoreForGame(i + (scoresperpage * (rankingPage - 1)), ms.SkillSets[rankingSkillset])
					if ths then
						self:visible(true)
						self:decelerate(0.3):x(rankingX + offsetX):diffusealpha(1)
						ck = ths:GetChartKey()
						thssong = SONGMAN:GetSongByChartKey(ck)
						thssteps = SONGMAN:GetStepsByChartKey(ck)
						MESSAGEMAN:Broadcast("DisplayProfileRankingLabels")
					else
						self:visible(false)
					end
				else
					onlineScore = DLMAN:GetTopSkillsetScore(i, ms.SkillSets[rankingSkillset])
					MESSAGEMAN:Broadcast("DisplayProfileRankingLabels")
					if not onlineScore then
						self:visible(false)
					else
						self:visible(true)
						self:decelerate(0.3):x(rankingX + offsetX):diffusealpha(1)
					end
				end
			else
				onlinesScore = nil
				self:visible(false)
			end
		end,
		UIElements.QuadButton(1, 1) .. {
			InitCommand = function(self)
				self:x(-20):halign(0):diffusealpha(1)
				self:diffuse(color("#1f1f1fff"))
			end,
			DisplayProfileRankingLabelsMessageCommand = function(self) -- hacky
				self:visible(true):diffuse(color("#151515ff")):diffusealpha(0.5)
				self:zoomto(frameWidth - 13, scoreYspacing)

				if ths then
					if not ths:GetEtternaValid() then
						self:diffuse(byValidity(ths:GetEtternaValid())):diffusealpha(0.3)
					end
				end 
			end,
			MouseDownCommand = function(self, params)
				if rankingSkillset > 0 and params.event == "DeviceButton_left mouse button" and update then
					if not showOnline then
						if ths then
							whee:SelectSong(thssong)
							self:GetParent():queuecommand("RedirectingWheel")
						end
					elseif onlineScore and onlineScore.chartkey then
						local song = SONGMAN:GetSongByChartKey(onlineScore.chartkey)
						if song then
							whee:SelectSong(song)
							self:GetParent():queuecommand("RedirectingWheel")
						end
					end
				elseif params.event == "DeviceButton_right mouse button" and update and not showOnline and ths then
					ths:ToggleEtternaValidation()
					BroadcastIfActive("UpdateRanking")
					if ths:GetEtternaValid() then
						ms.ok(translated_info["Validated"])
					else
						ms.ok(translated_info["Invalidated"])
					end
				end
			end,
			MouseOverCommand = function(self)
				papa = self:GetParent()
				papa:finishtweening()
				papa:smooth(0.1)
				papa:zoom(1.03)
				self:diffusealpha(1)
			end,
			MouseOutCommand = function(self)
				papa = self:GetParent()
				papa:finishtweening()
				papa:smooth(0.1)
				papa:zoom(1)
				self:diffusealpha(0.5)
			end,
		},
		LoadFont("Common Large") .. {
			Name = "text1",
			InitCommand = function(self)
				self:halign(0):zoom(fontScale)
				self:maxwidth(100)
			end,
			DisplayProfileRankingLabelsMessageCommand = function(self)
				if not showOnline then
					if ths then
						self:halign(0.5)
						self:settext(((rankingPage - 1) * scoresperpage) + i .. ".")
					end
				else
					self:halign(0.5)
					self:settext(i .. ".")
				end
			end
		},
		LoadFont("Common Large") .. {
			Name = "text2",
			InitCommand = function(self)
				self:halign(0):zoom(fontScale)
				self:x(15):maxwidth(160)
			end,
			DisplayProfileRankingLabelsMessageCommand = function(self)
				if not showOnline then
					if ths then
						local metro = ths:GetSkillsetSSR(ms.SkillSets[rankingSkillset])
						self:settextf("%5.2f", metro)
						self:diffuse(byMSD(metro))
					else
						self:settext("")
					end
				else
					if onlineScore then
						local metro = onlineScore.ssr
						self:settextf("%5.2f", metro)
						self:diffuse(byMSD(metro))
					else
						self:settext("")
					end
				end
			end
		},
		Def.Sprite{
			Name = "banbanner",
			InitCommand = function(self)
				self:halign(0):zoom(0.18)
				self:x(50)
				self:scaletoclipped(384 / 6, 120 / 5.5)
			end,
			DisplayProfileRankingLabelsMessageCommand = function(self)
				self:visible(false)
				if not showOnline and ProfileBannersEnabled() then
					if thssong and ths then
						bnpath = thssong:GetBannerPath()
						self:visible(true)
						if not BannersEnabled() then
							self:visible(false)
						elseif not bnpath then
							bnpath = THEME:GetPathG("Common", "fallback banner")
						end
						self:Load(bnpath)
					else
						self:visible(false)
					end
				else
					if onlineScore and ProfileBannersEnabled() then
						local putaMadre = onlineScore.chartkey
						fuuuuuuu = SONGMAN:GetSongByChartKey(putaMadre)
						if fuuuuuuu then
							bnpath = fuuuuuuu:GetBannerPath()
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
					else
						self:visible(false)
					end
				end
			end
		},
		LoadFont("Common Large") .. {
			Name = "text3",
			InitCommand = function(self)
				self:halign(0):zoom(0.2)
				self:xy(120, - 3):maxwidth(600)
			end,
			DisplayProfileRankingLabelsMessageCommand = function(self)
				if ProfileBannersEnabled() then 
					self:xy(120, - 3):maxwidth(600)
				else
					self:xy(55, - 3):maxwidth(850)
				end

				if not showOnline then
					if thssong and ths then
						self:settext(thssong:GetDisplayMainTitle())
					else
						self:settext("")
					end
				else
					if onlineScore then
						self:settext(onlineScore.songName)
					else
						self:settext("")
					end
				end
			end,
			RedirectingWheelCommand = function(self)
				self:finishtweening()
				self:diffuse(ColorMultiplier(getMainColor("positive"), 1.25))
				self:linear(0.45):diffuse(color("1,1,1,1"))
			end
		},
		LoadFont("Common Large") .. {
			Name = "text4",
			InitCommand = function(self)
				self:halign(0):zoom(0.13)
				self:xy(120,6):maxwidth(580):diffuse(color("#a6a6a6ff"))
			end,
			DisplayProfileRankingLabelsMessageCommand = function(self)
				if ProfileBannersEnabled() then 
					self:xy(120,6):maxwidth(580)
				else
					self:xy(55,6):maxwidth(780)
				end

				if not showOnline then
					if thssong and ths then
						self:settext(thssong:GetDisplayArtist())
					else
						self:settext("")
					end
				else
					if onlineScore then
						local putaMadre = onlineScore.chartkey
						fuuuuuuu = SONGMAN:GetSongByChartKey(putaMadre)
						if fuuuuuuu then
							self:settext(fuuuuuuu:GetDisplayArtist())
						else
							self:settext("")
						end
					else
						self:settext("")
					end
				end
			end,
			RedirectingWheelCommand = function(self)
				self:finishtweening()
			end
		},
		LoadFont("Common Large") .. {
			Name = "text5",
			InitCommand = function(self)
				self:halign(0):zoom(fontScale)
				self:x(275)
			end,
			DisplayProfileRankingLabelsMessageCommand = function(self)
				if not showOnline then
					if ths then
						self:halign(0.5)
						local ratestring = string.format("%.2f", ths:GetMusicRate()):gsub("%.?0+$", "") .. "x"
						self:settext(ratestring)
					else
						self:settext("")
					end
				else
					if onlineScore then
						local ratestring = string.format("%.2f", onlineScore.rate):gsub("%.?0+$", "") .. "x"
						self:halign(0.5)
						self:settext(ratestring)
					else
						self:settext("")
					end
				end
			end
		},
		LoadFont("Common Large") .. {
			Name = "text6",
			InitCommand = function(self)
				self:halign(0):zoom(fontScale)
				self:x(305):maxwidth(160)
			end,
			DisplayProfileRankingLabelsMessageCommand = function(self)
				if not showOnline then
					if ths then
						local wifeval = ths:GetWifeScore() * 100
						if wifeval > 99.9 then
							self:settextf("%5.4f%%", wifeval)
						else
							self:settextf("%5.2f%%", wifeval)
						end
						if not ths:GetEtternaValid() then
							self:diffuse(byJudgment("TapNoteScore_Miss"))
						else
							self:diffuse(getGradeColor(ths:GetWifeGrade()))
						end
					else
						self:settext("")
					end
				else
					if onlineScore then
						self:settextf("%5.2f%%", onlineScore.wife * 100)
						self:diffuse(getGradeColor(onlineScore.grade))
					else
						self:settext("")
					end
				end
			end
		},
		LoadFont("Common Large") .. {
			Name = "text7",
			InitCommand = function(self)
				self:halign(0):zoom(fontScale)
				self:x(365)
			end,
			DisplayProfileRankingLabelsMessageCommand = function(self)
				self:halign(0.5)
				if not showOnline then
					if thssteps then
						local diff = thssteps:GetDifficulty()
						self:diffuse(byDifficulty(diff))
						self:settext(getShortDifficulty(diff))
					else
						self:settext("")
					end
				else
					if onlineScore then
						local diff = onlineScore.difficulty
						self:diffuse(byDifficulty(diff))
						self:settext(getShortDifficulty(diff))
					else
						self:settext("")
					end
				end
			end
		},
		LoadFont("Common Large") .. {
			Name = "text8",
			InitCommand = function(self)
				self:halign(1):zoom(0.15)
				self:xy(410, - 3)
			end,
			DisplayProfileRankingLabelsMessageCommand = function(self)
				self:halign(0.5)
				if not showOnline then
					if ths then
						local timeScoreDate = ths:GetDate():sub(1,10)
						self:settext(timeScoreDate)
					else
						self:settext("")
					end
				else
					self:settext("")
				end
			end
		},
		LoadFont("Common Large") .. {
			Name = "text8",
			InitCommand = function(self)
				self:halign(1):zoom(0.17)
				self:xy(412,6)
			end,
			DisplayProfileRankingLabelsMessageCommand = function(self)
				self:halign(0.5)
				if not showOnline then
					if ths then
						local timeScoreHour = ths:GetDate():sub(12,19)
						self:settext(timeScoreHour)
					else
						self:settext("")
					end
				else
					self:settext("")
				end
			end
		}
	}
	return t
end

local buttonHeight = 23
local buttonwidth = 196
local buttonYoffset = (frameY * -1) + 70

local function rankingButton(i)
	local t = Def.ActorFrame {
		InitCommand = function(self)
			self:xy(-199, buttonYoffset + (i - 1) * (buttonHeight + 2))
		end,
		UIElements.QuadButton(1, 1) .. {
			InitCommand = function(self)
				self:x(0)
				self:zoomto(buttonwidth, buttonHeight):diffuse(color("#1f1f1fff")):diffusealpha(0.2):halign(0)
			end,
			SetCommand = function(self)
				if i == rankingSkillset and not recentactive and not percentactive then
					self:diffusealpha(1)
					self:GetParent():GetChild("RankButtonTxt"):diffuse(getMainColor("positive"))
				else
					self:diffusealpha(0.2)
					self:GetParent():GetChild("RankButtonTxt"):diffuse(color("#FFFFFF"))
				end
			end,
			MouseDownCommand = function(self, params)
				if params.event == "DeviceButton_left mouse button" and update then
					recentactive = false
					percentactive = false
					rankingSkillset = i
					rankingPage = 1
					if not percentactive then
						SCOREMAN:SortSSRsForGame(ms.SkillSets[rankingSkillset])
					else
						SCOREMAN:SortSSRsByPercentForGame()
					end
					BroadcastIfActive("UpdateRanking")
				end
			end,
			UpdateRankingMessageCommand = function(self)
				self:queuecommand("Set")
			end,
			MouseOverCommand = function(self)
				local alpha = 0.7
				self:GetParent():GetChild("RankButtonTxt"):diffusealpha(alpha)
			end,
			MouseOutCommand = function(self)
				local alpha = 1
				self:GetParent():GetChild("RankButtonTxt"):diffusealpha(alpha)
			end,
		},
		LoadFont("Common Large") .. {
			Name = "RankButtonTxt",
			InitCommand = function(self)
				self:x(4):zoom(0.27):halign(0)
			end,
			BeginCommand = function(self)
				self:settext(ms.SkillSetsTranslated[i])
			end
		},
		LoadFont("Common Large") .. {
			Name = "Meter",
			InitCommand = function(self)
				self:x(buttonwidth - 4):zoom(0.26):halign(1)
			end,
			SetCommand = function(self)
				local rating = 0
				if not showOnline then
					rating = profile:GetPlayerSkillsetRating(ms.SkillSets[i])
					self:settextf("%05.2f", rating)
				else
					rating = DLMAN:GetSkillsetRating(ms.SkillSets[i])
					self:settextf("%05.2f (#%i)", rating, DLMAN:GetSkillsetRank(ms.SkillSets[i]))
				end
				self:diffuse(byMSD(rating))
			end,
			UpdateRankingMessageCommand = function(self)
				self:queuecommand("Set")
			end,
			PlayerRatingUpdatedMessageCommand = function(self)
				self:queuecommand("Set")
			end
		}
	}
	return t
end


local function recentLabel(i)
	local ths  -- aAAAAAAAA
	local ck
	local thssteps
	local thssong
	local xoffset
	local onlineScore

	local t = Def.ActorFrame {
		InitCommand = function(self)
			self:xy(rankingX + offsetX - 20, 15 + (i - 1) * fuck)
			self:visible(false)
		end,
		UpdateRankingMessageCommand = function(self)
			self:finishtweening()
			self:diffusealpha(0.25):x(rankingX + offsetX - 20)
			if recentactive and update then
				self:sleep(0.04 + (0.005 * i)) -- no mo stut
					ths = SCOREMAN:GetRecentScoreForGame(i + (scoresperpage * (rankingPage - 1)))
					if ths then
						self:visible(true)
						self:decelerate(0.3):x(rankingX + offsetX):diffusealpha(1)
						ck = ths:GetChartKey()
						thssong = SONGMAN:GetSongByChartKey(ck)
						thssteps = SONGMAN:GetStepsByChartKey(ck)
						MESSAGEMAN:Broadcast("DisplayProfileRankingLabels")
					else
						self:visible(false)
					end
			else
				onlinesScore = nil
				self:visible(false)
			end
		end,
		UIElements.QuadButton(1, 1) .. {
			InitCommand = function(self)
				self:x(capWideScale(15,-20)):halign(0):zoom(fontScale):diffusealpha(buttondiffuse)
			end,
			DisplayProfileRankingLabelsMessageCommand = function(self) -- hacky
				self:visible(true):diffuse(color("#151515ff")):diffusealpha(0.5)
				self:zoomto(frameWidth - capWideScale(14,10), scoreYspacing * .995)

				if ths then
					if not ths:GetEtternaValid() then
						self:diffuse(byValidity(ths:GetEtternaValid())):diffusealpha(0.3)
					end
				end 
			end,
			MouseDownCommand = function(self, params)
				if recentactive and params.event == "DeviceButton_left mouse button" and update then
					if ths then
						whee:SelectSong(thssong)
					end
				elseif params.event == "DeviceButton_right mouse button" and update and recentactive then
					if ths and not showOnline then
						ths:ToggleEtternaValidation()
						BroadcastIfActive("UpdateRanking")
						if ths:GetEtternaValid() then
							ms.ok(translated_info["Validated"])
						else
							ms.ok(translated_info["Invalidated"])
						end
					end
				end
			end,
			MouseOverCommand = function(self)
				papa = self:GetParent()
				papa:finishtweening()
				papa:smooth(0.1)
				papa:zoom(1.03)
				self:diffusealpha(1)
			end,
			MouseOutCommand = function(self)
				papa = self:GetParent()
				papa:finishtweening()
				papa:smooth(0.1)
				papa:zoom(1)
				self:diffusealpha(0.5)
			end,
		},
		LoadFont("Common Large") .. {
			Name = "rectext1",
			InitCommand = function(self)
				self:halign(0):zoom(fontScale)
				self:maxwidth(100)
			end,
			DisplayProfileRankingLabelsMessageCommand = function(self)
				if ths and IsUsingWideScreen() then
					self:halign(0.5)
					self:settext(((rankingPage - 1) * scoresperpage) + i .. ".")
				end
			end
		},
		LoadFont("Common Large") .. {
			Name = "rectext2",
			InitCommand = function(self)
				self:halign(0):zoom(fontScale)
				self:x(15):maxwidth(160)
			end,
			DisplayProfileRankingLabelsMessageCommand = function(self)
				if ths then
					local meter = ths:GetSkillsetSSR(ms.SkillSets[1])
					self:settextf("%5.2f", meter)
					self:diffuse(byMSD(meter))
				else
					self:settext("")
				end
			end
		},
		Def.Sprite{
			Name = "recbanbanner",
			InitCommand = function(self)
				self:halign(0):zoom(0.18)
				self:x(50)
				self:scaletoclipped(384 / 6, 120 / 5.5)
			end,
			DisplayProfileRankingLabelsMessageCommand = function(self)
				if thssong and ths and ProfileBannersEnabled() then
					bnpath = thssong:GetBannerPath()
					self:visible(true)
					if not BannersEnabled() then
							self:visible(false)
					elseif not bnpath then
							bnpath = THEME:GetPathG("Common", "fallback banner")
					end
					self:sleep(0.01)
					self:LoadBackground(bnpath)
				else
					self:visible(false)
				end
			end
		},
		LoadFont("Common Large") .. {
			Name = "rectext3",
			InitCommand = function(self)
				self:halign(0):zoom(0.2)
				if ProfileBannersEnabled() then 
					self:xy(120, - 3):maxwidth(600)
				else
					self:xy(55, - 3):maxwidth(850)
				end
			end,
			DisplayProfileRankingLabelsMessageCommand = function(self)
				if thssong and ths then
					self:settext(thssong:GetDisplayMainTitle())
				else
					self:settext("")
				end
			end
		},
		LoadFont("Common Large") .. {
			Name = "rectext4",
			InitCommand = function(self)
				self:halign(0):zoom(0.13)
				self:diffuse(color("#a6a6a6ff"))
				if ProfileBannersEnabled() then 
					self:xy(120,6):maxwidth(580)
				else
					self:xy(55,6):maxwidth(780)
				end
			end,
			DisplayProfileRankingLabelsMessageCommand = function(self)
				if thssong and ths then
					self:settext(thssong:GetDisplayArtist())
				else
					self:settext("")
				end
			end
		},
		LoadFont("Common Large") .. {
			Name = "rectext4",
			InitCommand = function(self)
				self:halign(0):zoom(fontScale)
				self:x(275)
			end,
			DisplayProfileRankingLabelsMessageCommand = function(self)
				if ths then
					self:halign(0.5)
					local ratestring = string.format("%.2f", ths:GetMusicRate()):gsub("%.?0+$", "") .. "x"
					self:settext(ratestring)
				else
					self:settext("")
				end
			end
		},
		LoadFont("Common Large") .. {
			Name = "rectext5",
			InitCommand = function(self)
				self:halign(0):zoom(fontScale)
				self:x(305):maxwidth(160)
			end,
			DisplayProfileRankingLabelsMessageCommand = function(self)
				if ths then
					local wifeval = ths:GetWifeScore() * 100
					if wifeval > 99.9 then
						self:settextf("%5.4f%%", wifeval)
					else
						self:settextf("%5.2f%%", wifeval)
					end

					if not ths:GetEtternaValid() then
						self:diffuse(byJudgment("TapNoteScore_Miss"))
					else
						self:diffuse(getGradeColor(ths:GetWifeGrade()))
					end
				else
					self:settext("")
				end
			end
		},
		LoadFont("Common Large") .. {
			Name = "rectext6",
			InitCommand = function(self)
				self:halign(0):zoom(fontScale)
				self:x(365)
			end,
			DisplayProfileRankingLabelsMessageCommand = function(self)
				self:halign(0.5)
				if thssteps then
					local diff = thssteps:GetDifficulty()
					self:diffuse(byDifficulty(diff))
					self:settext(getShortDifficulty(diff))
				else
					self:settext("")
				end
			end
		},
		LoadFont("Common Large") .. {
			Name = "rectext67",
			InitCommand = function(self)
				self:halign(1):zoom(0.15)
				self:xy(410, - 3)
			end,
			DisplayProfileRankingLabelsMessageCommand = function(self)
				self:halign(0.5)
				if ths then
					local timeScoreDate = ths:GetDate():sub(1,10)
					self:settext(timeScoreDate)
				else
					self:settext("")
				end
			end
		},
		LoadFont("Common Large") .. {
			Name = "rectext677",
			InitCommand = function(self)
				self:halign(1):zoom(0.17)
				self:xy(412,6)
			end,
			DisplayProfileRankingLabelsMessageCommand = function(self)
				self:halign(0.5)
				if ths then
					local timeScoreHour = ths:GetDate():sub(12,19)
					self:settext(timeScoreHour)
				else
					self:settext("")
				end
			end
		}
	}
	return t
end

local function recentButton()
	local t = Def.ActorFrame {
		InitCommand = function(self)
			self:xy(rankingX, - 30):valign(1)
		end,
		UIElements.QuadButton(1, 1) .. {
			InitCommand = function(self)
				self:zoomto(rankingTitleSpacing, 26):diffuse(getMainColor("frames")):diffusealpha(0.2)
			end,
			SetCommand = function(self)
				if recentactive then
					self:diffusealpha(1)
				else
					self:diffusealpha(0.2)
				end
			end,
			MouseDownCommand = function(self, params)
				if params.event == "DeviceButton_left mouse button" and update then
					recentactive = true
					percentactive = false
					rankingPage = 1
					SCOREMAN:SortRecentScoresForGame()
					BroadcastIfActive("UpdateRanking")
				end
			end,
			UpdateRankingMessageCommand = function(self)
				self:queuecommand("Set")
			end,
			MouseOverCommand = function(self)
				local alpha = 0.7
				self:GetParent():GetChild("RecentButtonTxt"):diffusealpha(alpha)
			end,
			MouseOutCommand = function(self)
				local alpha = 1
				self:GetParent():GetChild("RecentButtonTxt"):diffusealpha(alpha)
			end,
		},
		LoadFont("Common Large") .. {
			Name = "RecentButtonTxt",
			InitCommand = function(self)
				self:addy(-1):diffuse(getMainColor("positive")):maxwidth(rankingTitleSpacing * 3):zoom(0.3)
			end,
			BeginCommand = function(self)
				self:settext(translated_info["Recent"])
			end
		}
	}
	return t
end

local function percentButton()
	local t = Def.ActorFrame {
		InitCommand = function(self)
			self:xy(-101, 140):valign(1)
		end,
		UIElements.QuadButton(1, 1) .. {
			InitCommand = function(self)
				self:zoomto(196, 26):diffuse(color("#1f1f1fff")):diffusealpha(0.2)
			end,
			SetCommand = function(self)
				if percentactive then
					self:diffusealpha(1)
				else
					self:diffusealpha(0.2)
				end
			end,
			MouseDownCommand = function(self, params)
				if params.event == "DeviceButton_left mouse button" and update then
					percentactive = not percentactive
					showOnline = false
					recentactive = false
					rankingPage = 1
					if rankingSkillset == 1 then
						rankingSkillset = 2
					end

					if not percentactive then
						SCOREMAN:SortSSRsForGame(ms.SkillSets[rankingSkillset])
					else
						SCOREMAN:SortSSRsByPercentForGame()
					end
					BroadcastIfActive("UpdateRanking")
				end
			end,
			UpdateRankingMessageCommand = function(self)
				self:queuecommand("Set")
			end,
			MouseOverCommand = function(self)
				local alpha = 0.7
				self:GetParent():GetChild("PercentButtonTxt"):diffusealpha(alpha)
			end,
			MouseOutCommand = function(self)
				local alpha = 1
				self:GetParent():GetChild("PercentButtonTxt"):diffusealpha(alpha)
			end,
		},
		LoadFont("Common Large") .. {
			Name = "PercentButtonTxt",
			InitCommand = function(self)
				self:addy(-1):diffuse(getMainColor("positive")):zoom(0.35)
			end,
			BeginCommand = function(self)
				self:settext("Percent")
			end
		}
	}
	return t
end

-- Online and Local buttons
t[#t + 1] = Def.ActorFrame {
	InitCommand = function(self)
		self:xy(250, 40)
		if DLMAN:IsLoggedIn() then
			self:visible(true)
		else
			self:visible(false)
		end
	end,
	SetCommand = function(self)
		if DLMAN:IsLoggedIn() then
			self:visible(true)
		else
			self:visible(false)
		end
	end,
	UpdateRankingMessageCommand = function(self)
		self:queuecommand("Set")
	end,
	Def.ActorFrame {
		InitCommand = function(self)
			self:xy(rankingX + frameWidth * 6 / 8 - rankingTitleSpacing, rankingY + offsetY + 2)
		end,
		UIElements.QuadButton(1, 1) .. {
			InitCommand = function(self)
				self:zoomto(rankingTitleSpacing, 26):diffusealpha(0.2):diffuse(getMainColor("frames"))
			end,
			SetCommand = function(self)
				if not showOnline then
					self:diffusealpha(1)
				else
					self:diffusealpha(0.2)
				end
			end,
			MouseDownCommand = function(self, params)
				if params.event == "DeviceButton_left mouse button" and update then
					showOnline = false
					BroadcastIfActive("UpdateRanking")
				end
			end,
			UpdateRankingMessageCommand = function(self)
				self:queuecommand("Set")
			end,
			MouseOverCommand = function(self)
				local alpha = 0.7
				self:GetParent():GetChild("LocalTxt"):diffusealpha(alpha)
			end,
			MouseOutCommand = function(self)
				local alpha = 1
				self:GetParent():GetChild("LocalTxt"):diffusealpha(alpha)
			end,
		},
		LoadFont("Common Large") ..{
			Name = "LocalTxt",
			InitCommand = function(self)
				self:maxwidth(rankingTitleSpacing*2):zoom(0.3)
			end,
			BeginCommand = function(self)
				self:settext(translated_info["Local"])
			end
		}
	},
	Def.ActorFrame {
		InitCommand = function(self)
			self:xy(rankingX + frameWidth * 7 / 8 - rankingTitleSpacing, rankingY + offsetY + 2)
		end,
		UIElements.QuadButton(1, 1) .. {
			InitCommand = function(self)
				self:zoomto(rankingTitleSpacing, 26):diffusealpha(0.2)
				if DLMAN:IsLoggedIn() then
					self:diffuse(getMainColor("frames"))
					if showOnline then
						self:diffusealpha(1)
					else
						self:diffusealpha(0.2)
					end
				else
					self:diffuse(getMainColor("disabled")):diffusealpha(0.1)
				end
			end,
			SetCommand = function(self)
				if DLMAN:IsLoggedIn() then
					self:diffuse(getMainColor("frames"))
					if showOnline then
						self:diffusealpha(1)
					else
						self:diffusealpha(0.2)
					end
				else
					self:diffuse(getMainColor("disabled")):diffusealpha(0.1)
				end
			end,
			MouseDownCommand = function(self, params)
				if params.event == "DeviceButton_left mouse button" and update and DLMAN:IsLoggedIn() then
					showOnline = true
					BroadcastIfActive("UpdateRanking")
				end
			end,
			UpdateRankingMessageCommand = function(self)
				self:queuecommand("Set")
			end,
			MouseOverCommand = function(self)
				local alpha = 0.7
				self:GetParent():GetChild("OnlineTxt"):diffusealpha(alpha)
			end,
			MouseOutCommand = function(self)
				local alpha = 1
				self:GetParent():GetChild("OnlineTxt"):diffusealpha(alpha)
			end,
		},
		LoadFont("Common Large") .. {
			Name = "OnlineTxt",
			InitCommand = function(self)
				self:maxwidth(rankingTitleSpacing*2):zoom(0.3)
			end,
			BeginCommand = function(self)
				self:settext(translated_info["Online"])
			end
		}
	},

}
-- prev/next page
r[#r + 1] = Def.ActorFrame {
	InitCommand = function(self)
		self:xy(10, frameHeight - offsetY + 5):visible(false)
	end,
	UpdateRankingMessageCommand = function(self)
		if (rankingSkillset > 0 or recentactive ) and not showOnline then
			self:visible(true)
			if not self and self.GetChildren then
				for child in self:GetChildren() do
					child:queuecommand("Display")
				end
			end
		else
			self:visible(false)
		end
	end,
	UIElements.QuadButton(1, 1) .. {
		InitCommand = function(self)
			self:xy(capWideScale(300,410), -8.5):zoomto(40, 20):halign(0):valign(0):diffuse(color("#2f2f2fff")):diffusealpha(0.2)
		end,
		MouseDownCommand = function(self, params)
			if params.event == "DeviceButton_left mouse button" then
				if rankingPage < numrankingpages then
					rankingPage = rankingPage + 1
				else
					rankingPage = 1
				end
				BroadcastIfActive("UpdateRanking")
			end
		end,
		MouseOverCommand = function(self)
			local alpha = 0.7
			self:GetParent():GetChild("NextP"):diffusealpha(alpha)
		end,
		MouseOutCommand = function(self)
			local alpha = 1
			self:GetParent():GetChild("NextP"):diffusealpha(alpha)
		end,
		
	},
	LoadFont("Common Large") .. {
		Name = "NextP",
		InitCommand = function(self)
			self:x(capWideScale(304.25,415)):halign(0):zoom(0.3):diffuse(getMainColor("positive")):settext(translated_info["NextPage"])
		end,
	},
	UIElements.QuadButton(1, 1) .. {
		InitCommand = function(self)
			self:xy(-4,-8.5):zoomto(65, 20):halign(0):valign(0):diffuse(color("#2f2f2fff")):diffusealpha(0.2)
		end,
		MouseDownCommand = function(self, params)
			if params.event == "DeviceButton_left mouse button" then
				if rankingPage > 1 then
					rankingPage = rankingPage - 1
				else
					rankingPage = numrankingpages
				end
				BroadcastIfActive("UpdateRanking")
			end
		end,
		MouseOverCommand = function(self)
			local alpha = 0.7
			self:GetParent():GetChild("PrevP"):diffusealpha(alpha)
		end,
		MouseOutCommand = function(self)
			local alpha = 1
			self:GetParent():GetChild("PrevP"):diffusealpha(alpha)
		end,
	},
	LoadFont("Common Large") .. {
		Name = "PrevP",
		InitCommand = function(self)
			self:halign(0):zoom(0.3):diffuse(getMainColor("positive")):settext(translated_info["PrevPage"])
		end,
	},
}

for i = 1, scoresperpage do
	r[#r + 1] = rankingLabel(i)
end

for i = 1, scoresperpage do
	r[#r + 1] = recentLabel(i)
end

-- Technically the "overall" skillset is used for single value display during music select/eval and isn't factored in to the profile rating
-- Only the specific skillsets are, and so overall should be used to display the specific skillset breakdowns separately - mina
for i = 1, #ms.SkillSets do
	r[#r + 1] = rankingButton(i)
end

r[#r + 1] = recentButton()
r[#r + 1] = percentButton()

local user
local pass
local profilebuttons = Def.ActorFrame {
	InitCommand = function(self)
		self:xy(-220, 50)
		self:visible(true)
	end,
	BeginCommand = function(self)
		user = playerConfig:get_data(pn_to_profile_slot(PLAYER_1)).UserName
		local passToken = playerConfig:get_data(pn_to_profile_slot(PLAYER_1)).PasswordToken
		if passToken ~= "" and answer ~= "" then
			if not DLMAN:IsLoggedIn() then
				DLMAN:LoginWithToken(user, passToken)
			end
		else
			passToken = ""
			user = ""
		end
	end,
	UIElements.TextToolTip(1, 1, "Common Large") .. {
		InitCommand = function(self)
			self:xy(frameX + frameWidth * 1/7, frameHeight + 04):halign(0.5):diffuse(getMainColor("positive")):zoom(0.3)
			self:settext(translated_info["Save"])
		end,
		MouseOverCommand = function(self)
			self:diffusealpha(hoverAlpha)
		end,
		MouseOutCommand = function(self)
			self:diffusealpha(1)
		end,
		MouseDownCommand = function(self, params)
			if params.event == "DeviceButton_left mouse button" and update and rankingSkillset == 1 and not recentactive then
				if PROFILEMAN:SaveProfile(PLAYER_1) then
					ms.ok(translated_info["Success"])
					STATSMAN:UpdatePlayerRating()
				else
					ms.ok(translated_info["Failure"])
				end
			end
		end
	},
	UIElements.TextToolTip(1, 1, "Common Large") .. {
		InitCommand = function(self)
			self:xy(frameX + frameWidth * 3/8, frameHeight + 04):halign(0.5):diffuse(getMainColor("positive")):zoom(0.3)
			self:settext(translated_info["AssetSettings"])
		end,
		MouseOverCommand = function(self)
			self:diffusealpha(hoverAlpha)
		end,
		MouseOutCommand = function(self)
			self:diffusealpha(1)
		end,
		MouseDownCommand = function(self, params)
			if params.event == "DeviceButton_left mouse button" and update and rankingSkillset == 1 and not recentactive then
				SCREENMAN:SetNewScreen("ScreenAssetSettings")
			end
		end,
	},
	--[[
	UIElements.TextToolTip(1, 1, "Common Large") .. {
		InitCommand = function(self)
			self:xy(frameX + frameWidth * 3/8, 200):halign(0.5):diffuse(getMainColor("positive")):zoom(0.3)
		end,
		SetCommand = function(self)
			profile = GetPlayerOrMachineProfile(PLAYER_1)
			local bestSkillsets = SCOREMAN:GetTopPlayedSkillsets(profile)

			topSkill1 = bestSkillsets[2]:sub(10)
			topSkill2 = bestSkillsets[3]:sub(10)
			topSkill3 = bestSkillsets[4]:sub(10)

			self:settextf("%s \n%s \n%s", topSkill1, topSkill2, topSkill3)
		end
	},
	]]
	UIElements.TextToolTip(1, 1, "Common Large") .. {
		InitCommand = function(self)
			self:xy(frameX + frameWidth * 1/7, frameHeight + 26):halign(0.5):diffuse(getMainColor("positive")):zoom(0.3)
			self:settext(translated_info["ValidateAll"])
		end,
		MouseOverCommand = function(self)
			self:diffusealpha(hoverAlpha)
		end,
		MouseOutCommand = function(self)
			self:diffusealpha(1)
		end,
		MouseDownCommand = function(self, params)
			if params.event == "DeviceButton_left mouse button" and update and rankingSkillset == 1 and not recentactive then
				profile:UnInvalidateAllScores()
				STATSMAN:UpdatePlayerRating()
			end
		end,
	},
	UIElements.TextToolTip(1, 1, "Common Large") .. {
		InitCommand = function(self)
			self:xy(frameX + frameWidth * 3/8, frameHeight + 26):diffuse(getMainColor("positive")):zoom(0.3)
			self:settext(translated_info["ForceRecalc"])
		end,
		MouseOverCommand = function(self)
			self:diffusealpha(hoverAlpha)
		end,
		MouseOutCommand = function(self)
			self:diffusealpha(1)
		end,
		MouseDownCommand = function(self, params)
			if params.event == "DeviceButton_left mouse button" and update and rankingSkillset == 1 and not recentactive  then
				ms.ok("Recalculating Scores... this might be slow and may or may not crash")
				profile:ForceRecalcScores()
				STATSMAN:UpdatePlayerRating()
			end
		end,
	},
	UIElements.TextToolTip(1, 1, "Common Large") .. {
		InitCommand = function(self)
			self:xy(frameX + frameWidth * 1/7, frameHeight + 48):diffuse(getMainColor("positive")):zoom(0.24)
			self:settext(translated_info["UploadAllScore"])
		end,
		MouseOverCommand = function(self)
			self:diffusealpha(hoverAlpha)
		end,
		MouseOutCommand = function(self)
			self:diffusealpha(1)
		end,
		MouseDownCommand = function(self, params)
			if params.event == "DeviceButton_left mouse button" and update and rankingSkillset == 1 and not recentactive  then
				if DLMAN:IsLoggedIn() then
					DLMAN:UploadAllScores()
				else
					ms.ok("You must be logged in...")
				end
			end
		end,
	},
}


local prof = Def.ActorFrame {
	ProfileTabOnMessageCommand = function(self)
		self:finishtweening()
	end,
	UIElements.SpriteButton(1, 1, nil) .. {
		InitCommand = function(self)
			self:xy(SCREEN_CENTER_X - 118, 75):diffusealpha(0)
			self:Load(getAvatarPath(PLAYER_1))
			self:zoomto(70,70)
		end,
		ProfileTabOffMessageCommand = function(self)
			self:diffusealpha(0)
		end,
		ProfileTabOnMessageCommand = function(self)
			self:sleep(0.05)
			self:smooth(0.2):diffusealpha(1)
		end,
		MouseDownCommand = function(self,params)
			if params.event == "DeviceButton_left mouse button" then
				SCREENMAN:SetNewScreen("ScreenAssetSettings")
			end
		end
	},
	Def.Sprite {
		InitCommand = function(self)
			self:xy(SCREEN_CENTER_X - 120, 76)
			self:diffuse(Brightness(getMainColor("positive"),0.2))
			self:Load(THEME:GetPathG("", "ball"))
			self:zoomto(80,75)
		end,
		ProfileTabOnMessageCommand = function(self)
			self:finishtweening()
		end
	},
	LoadFont("Common Large") .. {
		InitCommand = function(self)
			self:xy(SCREEN_CENTER_X - 80, 60):zoom(0.15):halign(0)
			self:diffuse(color("#a6a6a6ff"))
			self:settext("local profile")
		end
	},
	UIElements.TextToolTip(1, 1, "Common Large") .. {
		InitCommand = function(self)
			self:xy(SCREEN_CENTER_X - 80, 76):zoom(0.48):halign(0)
			self:settext("Default Profile")
		end,
		SetCommand = function(self)
			profile = GetPlayerOrMachineProfile(PLAYER_1)
			profileName = profile:GetDisplayName()
			playerRating = profile:GetPlayerRating()
			self:settextf("%s: %5.2f", profileName, playerRating)
		end,
		ProfileRenamedMessageCommand = function(self, params)
			self:settextf("%s: %5.2f", params.doot, playerRating)
		end,
		MouseOverCommand = function(self)
			self:diffusealpha(0.4)
		end,
		MouseOutCommand = function(self)
			self:diffusealpha(1)
		end,
		MouseDownCommand = function(self, params)
			MESSAGEMAN:Broadcast("RenameProfilePls")
		end,
	},
	UIElements.TextToolTip(1, 1, "Common Large") .. {
		InitCommand = function(self)
			self:xy(SCREEN_CENTER_X - 80, 94):zoom(0.2):halign(0)
			self:settext("Click to Login")
		end,
		MouseOverCommand = function(self)
			self:diffusealpha(0.4)
		end,
		MouseOutCommand = function(self)
			self:diffusealpha(1)
		end,
		MouseDownCommand = function(self, params)
			if params.event == "DeviceButton_left mouse button" and not SCREENMAN:get_input_redirected(PLAYER_1) then
				if DLMAN:IsLoggedIn() then
					MESSAGEMAN:Broadcast("LogOutViaProfile")
				else
					MESSAGEMAN:Broadcast("LogInViaProfile")
				end
			end
		end,
		LogOutMessageCommand = function(self)
			self:settext("Click to Login")
		end,
		setNameOnlineMessageCommand = function(self)
			self:settextf(
				"%s (%5.2f: #%i)",
				DLMAN:GetUsername(),
				DLMAN:GetSkillsetRating("Overall"),
				DLMAN:GetSkillsetRank(ms.SkillSets[1])
			)
		end,
	}
}

t[#t + 1] = prof
t[#t + 1] = profilebuttons
t[#t + 1] = r
return t
