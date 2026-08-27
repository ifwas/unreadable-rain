local hoverAlpha = 0.6
local areWeStillInsideAPlaylist
local update = false
local clickedForSinglePlaylist = false
local t = Def.ActorFrame {
	BeginCommand = function(self)
		self:queuecommand("Set"):visible(false)
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
	SetCommand = function(self)
		self:finishtweening()
		if getTabIndex() == 7 then
			self:queuecommand("On")
			self:visible(true)
			update = true
		else
			self:queuecommand("Off")
			update = false
		end
		areWeStillInsideAPlaylist = false
		MESSAGEMAN:Broadcast("DisplayAllPlaylists")
	end,
	TabChangedMessageCommand = function(self)
		self:queuecommand("Set")
		areWeStillInsideAPlaylist = false
	end
}


local frameX = 0
local frameY = 45
local frameWidth = capWideScale(202, 202)
local frameHeight = SCREEN_HEIGHT
local fontScale = 0.25
local scoreYspacing = 13
local distY = 15
local offsetX = -10
local offsetY = 20
local rankingPage = 1
local rankingWidth = frameWidth - capWideScale(15, 50)
local rankingX = capWideScale(30, 50)
local rankingY = capWideScale(40, 40)
local rankingTitleSpacing = (rankingWidth / (#ms.SkillSets))
local whee

local singleplaylistactive = false
local allplaylistsactive = true
local PlaylistYspacing = 70
local sizePlayListsCover = PlaylistYspacing * 0.9
local row2Yoffset = 12

local pl
local playlistCovers = playListCovers:get_data().playlistCover
local keylist
local songlist = {}
local stepslist = {}
local chartlist = {}

local numofchartsdsdsd = 0
local queuedUpTime = 0
local meteraverefgagag = 0
local currentchartpage = 1
local numchartpages
local chartsperplaylist = 8

local allplaylists
local currentplaylistpage = 1
local numplaylistpages = 1
local playlistsperpage = 5

local translated_info = {
	Delete = THEME:GetString("TabPlaylists", "Delete"),
	Showing = THEME:GetString("TabPlaylists", "Showing"),
	ChartCount = THEME:GetString("TabPlaylists", "ChartCount"),
	AverageRating = THEME:GetString("TabPlaylists", "AverageRating"),
	Title = THEME:GetString("TabPlaylists", "Title"),
	ExplainAdd = THEME:GetString("TabPlaylists", "ExplainAddChart"),
	ExplainPlaylist = THEME:GetString("TabPlaylists", "ExplainNewPlaylist"),
	PlayAsCourse = THEME:GetString("TabPlaylists", "PlayAsCourse"),
	Back = THEME:GetString("TabPlaylists", "Back"),
	Next = THEME:GetString("TabPlaylists", "Next"),
	Previous = THEME:GetString("TabPlaylists", "Previous"),
	UploadOnline = THEME:GetString("TabPlaylists", "UploadOnline"),
	UploadExplain = THEME:GetString("TabPlaylists", "UploadExplain"),
	DownloadOnline = THEME:GetString("TabPlaylists", "DownloadOnline"),
	DownloadOnlineExplain = THEME:GetString("TabPlaylists", "DownloadOnlineExplain"),
	DownloadMissing = THEME:GetString("TabPlaylists", "DownloadMissing"),
	DownloadMissingExplain = THEME:GetString("TabPlaylists", "DownloadMissingExplain"),
}

local function appearActorLeftRight(actor, originalX, offsetX, offsetSeconds, secondsToTween)
	actor:finishtweening()
	actor:diffusealpha(0)
	actor:x(originalX + offsetX)
	actor:sleep(offsetSeconds)
	actor:visible(true)
	actor:decelerate(secondsToTween):x(originalX):diffusealpha(1)
end

t[#t + 1] = Def.Quad {
	InitCommand = function(self)
		self:xy(frameX, frameY):zoomto(frameWidth, frameHeight):halign(0):valign(0):diffuse(getMainColor("tabs")):diffusealpha(0)
	end
}
t[#t + 1] = Def.Quad {
	InitCommand = function(self)
		self:xy(frameX, frameY):zoomto(frameWidth, offsetY):halign(0):valign(0)
		self:diffuse(getMainColor("frames")):diffusealpha(0)
	end
}
t[#t + 1] = LoadFont("Common Normal") .. {
	InitCommand = function(self)
		self:xy(frameWidth - 4, frameY):zoom(0.3):halign(1)
	end,
	DisplaySinglePlaylistMessageCommand = function(self)
		if areWeStillInsideAPlaylist == false then 
			self:visible(false)
			self:settext(translated_info["ExplainAdd"])
			appearActorLeftRight(self, (frameWidth - 4), 20, 0, 0.35)
		else
			self:settext(translated_info["ExplainAdd"])
		end
	end,
	DisplayAllPlaylistsMessageCommand = function(self)
		self:visible(false)
		self:settext(translated_info["ExplainPlaylist"])
		appearActorLeftRight(self, (frameWidth - 4), 20, 0, 0.35)
	end
}

t[#t + 1] = LoadFont("Common Normal") .. {
	InitCommand = function(self)
		self:xy(frameWidth - 4, frameY + 9):zoom(0.3):halign(1)
	end,
	DisplaySinglePlaylistMessageCommand = function(self)
		if areWeStillInsideAPlaylist == false then 
			self:visible(false)
			self:settext("Hold Shift to Change Rates by 0.05x ")
			appearActorLeftRight(self, (frameWidth - 4), 20, 0.04, 0.35)
		else
			self:settext("Hold Shift to Change Rates by 0.05x ")
		end
	end,
	DisplayAllPlaylistsMessageCommand = function(self)
		self:visible(false)
		self:settext("")
	end
}

local function BroadcastIfActive(msg)
	if update then
		MESSAGEMAN:Broadcast(msg)
	end
end

local function ButtonActive(self)
	return isOver(self) and update
end

local r = Def.ActorFrame {
	InitCommand = function(self)
		self:xy(frameX, frameY)
	end,
	OnCommand = function(self)
		whee = SCREENMAN:GetTopScreen():GetMusicWheel()
	end,
	DisplaySinglePlaylistMessageCommand = function(self)
		if getTabIndex() ~= 7 then return end
		if update then
			queuedUpTime = 0
			numofchartsdsdsd = 0
			meteraverefgagag = 0

			pl = SONGMAN:GetActivePlaylist()
			if pl then
				singleplaylistactive = true
				allplaylistsactive = false
				keylist = pl:GetChartkeys()
				chartlist = pl:GetAllSteps()
				meteraverefgagag = pl:GetAverageRating()

				numofchartsdsdsd = #chartlist

				for j = 1, #keylist do
					songlist[j] = SONGMAN:GetSongByChartKey(keylist[j])
					stepslist[j] = SONGMAN:GetStepsByChartKey(keylist[j])
					local rateNum = chartlist[j]:GetRate()
					queuedUpTime = queuedUpTime + (stepslist[j]:GetLengthSeconds() / rateNum)
				end

				numplaylistpages = notShit.ceil(#chartlist / chartsperplaylist)
				self:visible(true)
				MESSAGEMAN:Broadcast("DisplayPP")
			else
				singleplaylistactive = false
			end
		else
			self:visible(false)
		end
	end,
	LoadFont("Common Large") .. {
		InitCommand = function(self)
			self:xy(100, 75):zoom(0.27):halign(0):maxwidth(460)
		end,
		DisplayPPMessageCommand = function(self)
			if areWeStillInsideAPlaylist then
				self:settext("queued: " .. SecondsToMMSS(queuedUpTime))
			else
				self:visible(false) 
				self:settext("queued: " .. SecondsToMMSS(queuedUpTime))
				appearActorLeftRight(self, 100, -30, 0.02, 0.25)
			end
		end,
		DisplayAllPlaylistsMessageCommand = function(self)
			if getTabIndex() == 7 then
				self:visible(false)
			end
		end
	},
	LoadFont("Common Large") .. {
		InitCommand = function(self)
			self:xy(133, 62):zoom(0.27):halign(1):maxwidth(460)
		end,
		DisplayPPMessageCommand = function(self)
			if areWeStillInsideAPlaylist then
				self:settextf("%.2f", meteraverefgagag)
				self:diffuse(byMSD(meteraverefgagag))
				self:visible(true)
			else
				self:visible(false) 
				self:settextf("%.2f", meteraverefgagag)
				self:diffuse(byMSD(meteraverefgagag))
				appearActorLeftRight(self, 133, -30, 0.01, 0.25)
			end
		end,
		DisplayAllPlaylistsMessageCommand = function(self)
			if getTabIndex() == 7 then
				self:visible(false)
			end
		end
	},
	LoadFont("Common Large") .. {
		InitCommand = function(self)
			self:xy(135, 62):zoom(0.27):halign(0):maxwidth(460)
		end,
		DisplayPPMessageCommand = function(self)
			if areWeStillInsideAPlaylist then
				self:settext("MSD")
				self:visible(true)
			else
				self:visible(false) 
				self:settext("MSD")
				appearActorLeftRight(self, 135, -30, 0.01, 0.25)
			end
		end,
		DisplayAllPlaylistsMessageCommand = function(self)
			if getTabIndex() == 7 then
				self:visible(false)
			end
		end
	},
	LoadFont("Common Large") .. {
		InitCommand = function(self)
			self:xy(100, 47):zoom(0.27):halign(0):maxwidth(460)
		end,
		DisplayPPMessageCommand = function(self)
			if areWeStillInsideAPlaylist then
				self:settext(numofchartsdsdsd .. " files")
			else
				self:visible(false)
				self:settext(numofchartsdsdsd .. " files")
				appearActorLeftRight(self, 100, -40, 0, 0.24)
			end
		end,
		DisplayAllPlaylistsMessageCommand = function(self)
			if getTabIndex() == 7 then
				self:visible(false)
			end
		end
	},
	LoadFont("Common Large") .. {
		InitCommand = function(self)
			self:xy(5, 20):zoom(0.27):halign(0):maxwidth(460)
		end,
		DisplaySinglePlaylistMessageCommand = function(self)
			pl = SONGMAN:GetActivePlaylist()
			if areWeStillInsideAPlaylist then
				self:settext(pl:GetName())
				self:visible(true)
			else
				self:visible(false)
				self:settext(pl:GetName())
				appearActorLeftRight(self, 5, -40, 0.001, 0.3)
			end
		end,
		DisplayAllPlaylistsMessageCommand = function(self)
			if getTabIndex() == 7 then
				self:visible(false)
				currentchartpage = 1
				singleplaylistactive = false
				allplaylistsactive = true
			end
		end
	},
	UIElements.SpriteButton(1, 1, nil) .. {
		Name = "PlaylistCover",
		InitCommand = function(self)
			self:xy(5, 75)
			self:halign(0)
			self:visible(false)
		end,
		DisplaySinglePlaylistMessageCommand = function(self)
			self:finishtweening()

			if not areWeStillInsideAPlaylist then
				self:diffusealpha(0)
			end 
			

			local pls = SONGMAN:GetActivePlaylist()
			local namePlaylist = pls:GetName()
			local coverImage = playlistCovers[namePlaylist]

			if coverImage == nil then
				coverImage = playlistCovers["default"]
			end

			self:Load(coverImage)
			self:linear(0.3):diffusealpha(1)
			self:scaletoclipped(90,90)
			self:visible(true)
		end,
		DisplayAllPlaylistsMessageCommand = function(self)
			if getTabIndex() == 7 then
				self:visible(false)
			end
		end,
		MouseOverCommand = function(self)
			self:diffusealpha(0.8)
		end,
		MouseOutCommand = function(self)
            self:diffusealpha(1)
        end,
		MouseDownCommand = function(self, params)
			if params.event == "DeviceButton_left mouse button" then
				local namePlaylist = pl:GetName()
				curPlaylistSelected = namePlaylist
				SCREENMAN:SetNewScreen("ScreenPlaylistAssetSettings")
			end
		end
	}
}


local function RateDisplayButton(i)
	local o = Def.ActorFrame {
		Name = "RateDisplay",
		InitCommand = function(self)
			self:xy(1, - 5):diffuse(getMainColor("positive"))
		end,
		UIElements.TextToolTip(1, 1, "Common Large") .. {
			Name = "Text",
			DisplaySinglePlaylistLevel2MessageCommand = function(self)
				local ratestring =
					string.format("%.2f", chartlist[i + ((currentchartpage - 1) * chartsperplaylist)]:GetRate()):gsub("%.?0+$", "") ..
					"x"
				self:settext(ratestring)
				self:zoom(fontScale * 0.8)
			end,
			MouseDownCommand = function(self, params)
				if params.event == "DeviceButton_left mouse button" and update and singleplaylistactive then
					
					if INPUTFILTER:IsBeingPressed("left shift") or INPUTFILTER:IsBeingPressed("right shift") then --why was this not an option wtf poco
						chartlist[i + ((currentchartpage - 1) * chartsperplaylist)]:ChangeRate(0.05)
					else
						chartlist[i + ((currentchartpage - 1) * chartsperplaylist)]:ChangeRate(0.1)
					end
					
					areWeStillInsideAPlaylist = true
					BroadcastIfActive("RateChangedPlaesUpdateThis")
					BroadcastIfActive("DisplaySinglePlaylist")
				elseif params.event == "DeviceButton_right mouse button" and update and singleplaylistactive then

					if INPUTFILTER:IsBeingPressed("left shift") or INPUTFILTER:IsBeingPressed("right shift") then
						chartlist[i + ((currentchartpage - 1) * chartsperplaylist)]:ChangeRate(-0.05)
					else
						chartlist[i + ((currentchartpage - 1) * chartsperplaylist)]:ChangeRate(-0.1)
					end
					
					areWeStillInsideAPlaylist = true
					BroadcastIfActive("RateChangedPlaesUpdateThis")
					BroadcastIfActive("DisplaySinglePlaylist")
				end
			end,
			MouseOverCommand = function(self)
				self:diffusealpha(hoverAlpha)
			end,
			MouseOutCommand = function(self)
				self:diffusealpha(1)
			end,
		}
	}
	return o
end

local function TitleDisplayButton(i)
	local o = Def.ActorFrame {
		Name = "TitleDisplay",
		InitCommand = function(self)
			self:x(12)
		end,
		UIElements.QuadButton(1, 1) .. {
			InitCommand = function(self)
				self:x(-20):zoomto(190, 26.5):halign(0):diffusealpha(1)
			end,
			DisplaySinglePlaylistLevel2MessageCommand = function(self)
				local indexrn = i + ((currentchartpage - 1) * chartsperplaylist)
				if indexrn % 2 == 1 then
					self:diffuse(color("#282828ff"))
				else
					self:diffuse(color("#161616ff"))
				end
			end,
			MouseDownCommand = function(self, params)
				-- wtf
				if params.event == "DeviceButton_left mouse button" and update and chartlist[i + ((currentchartpage - 1) * chartsperplaylist)] and
						chartlist[i + ((currentchartpage - 1) * chartsperplaylist)]:IsLoaded() and
						singleplaylistactive and not clickedForSinglePlaylist
				 then
					whee:SelectSong(songlist[i + ((currentchartpage - 1) * chartsperplaylist)])
				end
			end,
			MouseOverCommand = function(self)
				self:GetParent():GetChild("Text"):diffusealpha(0.7)
				self:GetParent():GetChild("TextPACCCC"):diffusealpha(0.7)
			end,
			MouseOutCommand = function(self)
				self:GetParent():GetChild("Text"):diffusealpha(1)
				self:GetParent():GetChild("TextPACCCC"):diffusealpha(1)
			end,
		},
		LoadFont("Common Large") .. {
			Name = "Text",
			InitCommand = function(self)
				self:y(-4)
				self:halign(0)
			end,
			DisplaySinglePlaylistLevel2MessageCommand = function(self)
				self:zoom(fontScale * 0.9)
				self:maxwidth(600)
				local chartentry = chartlist[i + ((currentchartpage - 1) * chartsperplaylist)]
				if chartentry == nil then return end
				if chartentry:IsLoaded() then
					local songentry = songlist[i + ((currentchartpage - 1) * chartsperplaylist)]
					self:diffuse(getMainColor("positive"))
					self:settext(songentry:GetDisplayMainTitle())
				else
					self:diffuse(byJudgment("TapNoteScore_Miss"))
					self:settext(chartentry:GetSongTitle())
				end
			end,
			DisplayLanguageChangedMessageCommand = function(self)
				self:playcommand("DisplaySinglePlaylistLevel2")
			end,
		},
		LoadFont("Common Large") .. {
			Name = "TextPACCCC",
			InitCommand = function(self)
				self:y(6)
				self:halign(0)
			end,
			DisplaySinglePlaylistLevel2MessageCommand = function(self)
				self:zoom(fontScale * 0.5)
				self:maxwidth(620 * 2)
				local chartentry = chartlist[i + ((currentchartpage - 1) * chartsperplaylist)]
				if chartentry == nil then return end
				if chartentry:IsLoaded() then
					local songentry = songlist[i + ((currentchartpage - 1) * chartsperplaylist)]
					self:diffuse(getMainColor("positive"))
					self:settext(songentry:GetGroupName())
				else
					self:diffuse(byJudgment("TapNoteScore_Miss"))
					self:settext(chartentry:GetGroupName())
				end
			end,
			DisplayLanguageChangedMessageCommand = function(self)
				self:playcommand("DisplaySinglePlaylistLevel2")
			end,
		},
		LoadFont("Common Large") .. {
			Name = "leeeenghyt",
			InitCommand = function(self)
				self:xy(167 , -3)
				self:halign(1)
			end,
			DisplaySinglePlaylistLevel2MessageCommand = function(self)
				self:queuecommand("updateLenght")
			end,
			RateChangedPlaesUpdateThisMessageCommand = function(self)
				self:queuecommand("updateLenght")
			end,
			updateLenghtCommand = function(self)
				self:zoom(fontScale * 0.75)
				local chart = stepslist[i + ((currentchartpage - 1) * chartsperplaylist)]
				local listaMapas = chartlist[i + ((currentchartpage - 1) * chartsperplaylist)]
				
				if chart == nil or listaMapas == nil then
					self:visible(false)
					return
				else
					self:visible(true)
				end

				local raaaaaaaaaate = listaMapas:GetRate()
				local ddddd = chart:GetLengthSeconds()
				local AAAAAAAAAAAAAAAAAAAA = ddddd / raaaaaaaaaate
				self:settext(SecondsToMMSS(AAAAAAAAAAAAAAAAAAAA))
				self:diffuse(byMusicLength(AAAAAAAAAAAAAAAAAAAA))
			end,
			DisplayLanguageChangedMessageCommand = function(self)
				self:playcommand("DisplaySinglePlaylistLevel2")
			end,
		}
	}
	return o
end

local function DeleteChartButton(i)
	local o = Def.ActorFrame {
		Name = "DeleteButton",
		InitCommand = function(self)
			self:xy(180, 8)
		end,
		UIElements.TextToolTip(1, 1, "Common Large") .. {
			Name = "Text",
			InitCommand = function(self)
				self:halign(1)
				self:zoom(fontScale * 0.8)
				self:settext(translated_info["Delete"])
				self:diffuse(byJudgment("TapNoteScore_Miss"))
			end,
			DisplaySinglePlaylistLevel2Command = function(self)
				if pl:GetName() == "Favorites" then
					self:visible(false)
				else
					self:visible(true)
				end
			end,
			MouseDownCommand = function(self, params)
				if params.event == "DeviceButton_left mouse button" and update and singleplaylistactive then
					pl:DeleteChart(i + ((currentchartpage - 1) * chartsperplaylist))
					MESSAGEMAN:Broadcast("DisplayAllPlaylists")
					MESSAGEMAN:Broadcast("DisplaySinglePlaylist")
				end
			end,
			MouseOverCommand = function(self)
				self:diffusealpha(hoverAlpha)
			end,
			MouseOutCommand = function(self)
				self:diffusealpha(1)
			end,
		}
	}
	return o
end

local function DisplayDiff(i)
	local o = Def.ActorFrame {
			Name = "DisplayDiff",
		InitCommand = function(self)
			self:xy(2, 5):zoom(1):halign(0):valign(0)
		end,
		UIElements.QuadButton(1,1) .. {
			InitCommand = function(self)
				self:x(-7):zoomto(16, scoreYspacing):halign(0):diffusealpha(0) --you like odd numbers don't you
			end,
			MouseOverCommand = function(self)
				self:GetParent():GetChild("Text"):diffusealpha(0.7)
			end,
			MouseOutCommand = function(self)
				self:GetParent():GetChild("Text"):diffusealpha(1)
			end,
		},
		LoadFont("Common Large") .. {
			Name = "Text",
			InitCommand = function(self)
				self:halign(0.5)
			end,
			DisplaySinglePlaylistLevel2MessageCommand = function(self)
				self:zoom(fontScale * 0.75)
				self:maxwidth(70)
				local chart = stepslist[i + ((currentchartpage - 1) * chartsperplaylist)]
				if chart == nil then
					self:visible(false)
					return
				else
					self:visible(true)
				end
				local diff = chart:GetDifficulty()
				self:diffuse(byDifficulty(diff))
				self:settext(getShortDifficulty(diff))
			end,
			DisplayLanguageChangedMessageCommand = function(self)
				self:playcommand("DisplaySinglePlaylistLevel2")
			end,
		}
	}
	return o
end

local function rankingLabel(i)
	local chart
	local chartloaded
	local t = Def.ActorFrame {
		InitCommand = function(self)
			self:xy(15, rankingY + offsetY + 100 + (i - 1) * 26.5)
			self:visible(false)
		end,
		DisplayAllPlaylistsMessageCommand = function(self)
			self:visible(false)
		end,
		DisplayPPMessageCommand = function(self)
			if update then
				chart = chartlist[i + ((currentchartpage - 1) * chartsperplaylist)]
				if chart then
					chartloaded = chartlist[i + ((currentchartpage - 1) * chartsperplaylist)]:IsLoaded()
					self:visible(true)
					self:GetChild("DeleteButton"):queuecommand("DisplaySinglePlaylistLevel2")
					self:GetChild("TitleDisplay"):queuecommand("DisplaySinglePlaylistLevel2")
					self:GetChild("RateDisplay"):queuecommand("DisplaySinglePlaylistLevel2")
					self:GetChild("DisplayDiff"):queuecommand("DisplaySinglePlaylistLevel2")
					self:GetChild("DeleteButton"):visible(true)
					self:GetChild("TitleDisplay"):visible(true)
					self:GetChild("RateDisplay"):visible(true)
					self:GetChild("DisplayDiff"):visible(true)
				else
					self:GetChild("DeleteButton"):visible(false)
					self:GetChild("TitleDisplay"):visible(false)
					self:GetChild("RateDisplay"):visible(false)
					self:GetChild("DisplayDiff"):visible(false)
					self:GetChild("DeleteButton"):visible(false)
				end
			else
				self:visible(true)
			end
		end,
		LoadFont("Common Large") .. {
			InitCommand = function(self)
				self:x(256):maxwidth(160)
				self:halign(0):zoom(fontScale)
			end,
			DisplaySinglePlaylistLevel2MessageCommand = function(self)
				if chartloaded then
					local rating = stepslist[i + ((currentchartpage - 1) * chartsperplaylist)]:GetMSD(chart:GetRate(), 1)
					self:settextf("%.2f", rating)
					self:diffuse(byMSD(rating))
				else
					local rating = 0
					self:settextf("%.2f", rating)
					self:diffuse(byJudgment("TapNoteScore_Miss"))
				end
			end
		},
		LoadFont("Common Large") .. {
			InitCommand = function(self)
				self:x(300)
				self:halign(0):zoom(fontScale)
			end,
			DisplaySinglePlaylistLevel2MessageCommand = function(self)
				self:halign(0.5)
				local diff = stepslist[i + ((currentchartpage - 1) * chartsperplaylist)]:GetDifficulty()
				if chartloaded then
					self:diffuse(byDifficulty(diff))
					self:settext(getShortDifficulty(diff))
				else
					local diff = chart:GetDifficulty()
					self:diffuse(byJudgment("TapNoteScore_Miss"))
					self:settext(getShortDifficulty(diff))
				end
			end
		}
	}
	
	t[#t + 1] = TitleDisplayButton(i)
	t[#t + 1] = RateDisplayButton(i)
	t[#t + 1] = DeleteChartButton(i)
	t[#t + 1] = DisplayDiff(i)
	return t
end

-- Buttons for individual playlist manipulation
local b2 = Def.ActorFrame {
	InitCommand = function(self)
		self:xy(215, rankingY)
	end,
	DisplayAllPlaylistsMessageCommand = function(self)
		self:visible(false)
	end,
	DisplaySinglePlaylistMessageCommand = function(self)
		self:visible(true)
	end
}

b2[#b2 + 1] = UIElements.TextToolTip(1, 1, "Common Large") .. {
	InitCommand = function(self)
		self:zoom(0.26):xy(capWideScale(86,-208),95):diffuse(getMainColor("positive")):halign(0)
		self:settext(translated_info["PlayAsCourse"])
	end,
	MouseDownCommand = function(self, params)
		if params.event == "DeviceButton_left mouse button" and update and singleplaylistactive then
			SCREENMAN:GetTopScreen():StartPlaylistAsCourse(pl:GetName())
		end
	end,
	MouseOverCommand = function(self)
		self:diffusealpha(hoverAlpha)
	end,
	MouseOutCommand = function(self)
		self:diffusealpha(1)
	end,
}

-- Back button
b2[#b2 + 1] = UIElements.TextToolTip(1, 1, "Common Large") .. {
	InitCommand = function(self)
		self:zoom(0.27):xy(capWideScale(5,-35), 95):diffuse(getMainColor("positive"))
		self:settext(translated_info["Back"])
	end,
	MouseDownCommand = function(self, params)
		if params.event == "DeviceButton_left mouse button" and update and singleplaylistactive then
			areWeStillInsideAPlaylist = false
			MESSAGEMAN:Broadcast("DisplayAllPlaylists")
		end
	end,
	MouseOverCommand = function(self)
		self:diffusealpha(hoverAlpha)
	end,
	MouseOutCommand = function(self)
		self:diffusealpha(1)
	end,
}

r[#r + 1] = b2

-- next/prev pages for individual playlists, i guess these could be merged with the allplaylists buttons for efficiency but meh
-- whoever was lazy enough to NOT do that deserves to die ^
r[#r + 1] = Def.ActorFrame {
	InitCommand = function(self)
		self:xy(frameX + 1, frameY + rankingY + 315)
	end,
	UIElements.TextToolTip(1, 1, "Common Large") .. {
		InitCommand = function(self)
			self:x(capWideScale(190,197)):halign(1):zoom(0.25):diffuse(getMainColor("positive"))
			self:settext(translated_info["Next"])
		end,
		DisplayAllPlaylistsMessageCommand = function(self)
			self:visible(false)
		end,
		DisplaySinglePlaylistMessageCommand = function(self)
			self:visible(true)
		end,
		MouseDownCommand = function(self, params)
			if params.event == "DeviceButton_left mouse button" and currentchartpage < numplaylistpages and singleplaylistactive then
				currentchartpage = currentchartpage + 1
				areWeStillInsideAPlaylist = true
				MESSAGEMAN:Broadcast("DisplaySinglePlaylist")
				MESSAGEMAN:Broadcast("DisplayPP")
			end
		end,
		MouseOverCommand = function(self)
			self:diffusealpha(hoverAlpha)
		end,
		MouseOutCommand = function(self)
			self:diffusealpha(1)
		end,
	},
	UIElements.TextToolTip(1, 1, "Common Large") .. {
		InitCommand = function(self)
			self:halign(0):zoom(0.25):diffuse(getMainColor("positive"))
			self:settext(translated_info["Previous"])
		end,
		DisplayAllPlaylistsMessageCommand = function(self)
			self:visible(false)
		end,
		DisplaySinglePlaylistMessageCommand = function(self)
			self:visible(true)
		end,
		MouseDownCommand = function(self, params)
			if params.event == "DeviceButton_left mouse button" and currentchartpage > 1 and singleplaylistactive then
				currentchartpage = currentchartpage - 1
				areWeStillInsideAPlaylist = true
				MESSAGEMAN:Broadcast("DisplaySinglePlaylist")
				MESSAGEMAN:Broadcast("DisplayPP")
			end
		end,
		MouseOverCommand = function(self)
			self:diffusealpha(hoverAlpha)
		end,
		MouseOutCommand = function(self)
			self:diffusealpha(1)
		end,
	},
	UIElements.TextToolTip(1, 1, "Common Large") .. {
		InitCommand = function(self)
			self:halign(1):zoom(0.25):diffuse(getMainColor("positive"))
			self:xy(capWideScale(290,190), - 30)
			self.state = "Download"
			self:queuecommand("MaintainState")
			self.visibilityFunc = function()
				return (singleplaylistactive and SONGMAN:GetActivePlaylist() ~= nil and SONGMAN:GetActivePlaylist():GetName() ~= "Favorites")
					or not singleplaylistactive
			end
		end,
		MaintainStateCommand = function(self)
			if DLMAN:IsLoggedIn() then
				self:visible(self.visibilityFunc())
			else
				self:visible(false)
			end
		end,
		LoginFailedMessageCommand = function(self)
			self:queuecommand("MaintainState")
		end,
		LoginMessageCommand = function(self)
			self:queuecommand("MaintainState")
		end,
		LogOutMessageCommand = function(self)
			self:queuecommand("MaintainState")
		end,
		OnlineUpdateMessageCommand = function(self)
			self:queuecommand("MaintainState")
		end,
		DisplayAllPlaylistsMessageCommand = function(self)
			self.state = "Download"
			self:queuecommand("MaintainState")
			self:settext(translated_info["DownloadMissing"])
			self:xy(capWideScale(250,195), -15)
		end,
		DisplaySinglePlaylistMessageCommand = function(self)
			self.state = "Upload"
			self:queuecommand("MaintainState")
			self:settext(translated_info["UploadOnline"])
			self:x(capWideScale(230,190), -15)
		end,
		MouseDownCommand = function(self, params)
			if params.event == "DeviceButton_left mouse button" and singleplaylistactive then
				self:playcommand("Invoke")
			elseif params.event == "DeviceButton_left mouse button" and not singleplaylistactive then
				self:playcommand("Invoke")
			end
		end,
		InvokeCommand = function(self)
			if self.state == "Upload" then
				local pl = SONGMAN:GetActivePlaylist()
				ms.ok("Uploading playlist '" .. pl:GetName() .. "'")
				pl:UploadOnline()
			elseif self.state == "Download" then
				ms.ok("Downloading missing playlists...")
				DLMAN:DownloadMissingPlaylists()
			end
		end,
		MouseOverCommand = function(self)
			self:diffusealpha(hoverAlpha)
			if self:IsVisible() then
				if self.state == "Download" then
					TOOLTIP:SetText(translated_info["DownloadMissingExplain"])
					TOOLTIP:Show()
				elseif self.state == "Upload" then
					TOOLTIP:SetText(translated_info["UploadExplain"])
					TOOLTIP:Show()
				end
			end
		end,
		MouseOutCommand = function(self)
			self:diffusealpha(1)
			if self:IsVisible() then
				TOOLTIP:Hide()
			end
		end,
	},
	UIElements.TextToolTip(1, 1, "Common Large") .. {
		InitCommand = function(self)
			self:halign(0):zoom(0.2):diffuse(getMainColor("positive"))
			self:xy(capWideScale(290,2), -15)
			self:settext(translated_info["DownloadOnline"])
			self:queuecommand("MaintainState")
		end,
		MaintainStateCommand = function(self)
			if DLMAN:IsLoggedIn() then
				local b = singleplaylistactive and SONGMAN:GetActivePlaylist() ~= nil and SONGMAN:GetActivePlaylist():GetName() ~= "Favorites"
				self:visible(b)
			else
				self:visible(false)
			end
		end,
		LoginFailedMessageCommand = function(self)
			self:queuecommand("MaintainState")
		end,
		LoginMessageCommand = function(self)
			self:queuecommand("MaintainState")
		end,
		LogOutMessageCommand = function(self)
			self:queuecommand("MaintainState")
		end,
		OnlineUpdateMessageCommand = function(self)
			self:queuecommand("MaintainState")
		end,
		DisplayAllPlaylistsMessageCommand = function(self)
			self:visible(false)
		end,
		DisplaySinglePlaylistMessageCommand = function(self)
			local b = DLMAN:IsLoggedIn() and SONGMAN:GetActivePlaylist() ~= nil and SONGMAN:GetActivePlaylist():GetName() ~= "Favorites"
			self:visible(b)
		end,
		MouseDownCommand = function(self, params)
			if params.event == "DeviceButton_left mouse button" and singleplaylistactive then
				self:playcommand("Invoke")
			end
		end,
		InvokeCommand = function(self)
			local pl = SONGMAN:GetActivePlaylist()
			ms.ok("Downloading playlist '" .. pl:GetName() .. "' from online")
			pl:DownloadOnline()
		end,
		MouseOverCommand = function(self)
			self:diffusealpha(hoverAlpha)
			if self:IsVisible() then
				TOOLTIP:SetText(translated_info["DownloadOnlineExplain"])
				TOOLTIP:Show()
			end
		end,
		MouseOutCommand = function(self)
			self:diffusealpha(1)
			if self:IsVisible() then
				TOOLTIP:Hide()
			end
		end,
	},
	LoadFont("Common Large") .. {
		InitCommand = function(self)
			self:x(102):halign(0.5):zoom(0.2)
		end,
		SetCommand = function(self)
			self:settextf(
				"%s %i-%i / %i",
				translated_info["Showing"],
				math.min(((currentchartpage - 1) * chartsperplaylist) + 1, #chartlist),
				math.min(currentchartpage * chartsperplaylist, #chartlist),
				#chartlist
			)
		end,
		DisplayAllPlaylistsMessageCommand = function(self)
			self:visible(false)
		end,
		DisplaySinglePlaylistMessageCommand = function(self)
			self:visible(true):queuecommand("Set")
		end
	}
}

local function PlaylistTitleDisplayButton(i)
	local o = Def.ActorFrame {
		InitCommand = function(self)
			self:xy(15, -27)
		end,
		UIElements.QuadButton(1, 1) .. {
			InitCommand = function(self)
				self:xy(-13,15):zoomto(rankingWidth - 30, sizePlayListsCover / 3 ):align(0,0)
				self:diffusealpha(0)
			end,
			MouseOverCommand = function(self)
				self:GetParent():GetChild("Text"):diffusealpha(0.7)
			end,
			MouseOutCommand = function(self)
				self:GetParent():GetChild("Text"):diffusealpha(1)
			end,
			MouseDownCommand = function(self, params)
				if params.event == "DeviceButton_left mouse button" and update and allplaylistsactive then
					SONGMAN:SetActivePlaylist(allplaylists[i + ((currentplaylistpage - 1) * playlistsperpage)]:GetName())
					pl = allplaylists[i + ((currentplaylistpage - 1) * playlistsperpage)]
					MESSAGEMAN:Broadcast("DisplaySinglePlaylist")
					clickedForSinglePlaylist = true
				end
			end,
			MouseUpMessageCommand = function(self)
				clickedForSinglePlaylist = false
			end,
		},
		LoadFont("Common Large") .. {
			Name = "Text",
			InitCommand = function(self)
				self:halign(0):maxwidth(frameWidth * 3 + 140)
				self:diffuse(getMainColor("positive"))
			end,
			AllDisplayMessageCommand = function(self)
				self:zoom(fontScale * 1.2):y(25)
				if allplaylists[i + ((currentplaylistpage - 1) * playlistsperpage)] then
					self:settext(allplaylists[i + ((currentplaylistpage - 1) * playlistsperpage)]:GetName())
				end
			end,
		}
	}
	return o
end

local function DeletePlaylistButton(i)
	local o = Def.ActorFrame {
		InitCommand = function(self)
			self:x(127)
			self:y(25)
		end,
		UIElements.TextToolTip(1, 1, "Common Large") .. {
			Name = "Text",
			InitCommand = function(self)
				self:halign(1):maxwidth(frameWidth * 3 + 140)
			end,
			AllDisplayMessageCommand = function(self)
				if allplaylists[i + ((currentplaylistpage - 1) * playlistsperpage)] then
					self:settext(translated_info["Delete"])
					self:zoom(fontScale)
					self:diffuse(byJudgment("TapNoteScore_Miss"))
				end

				if allplaylists[i + ((currentplaylistpage - 1) * playlistsperpage)] then
					if allplaylists[i + ((currentplaylistpage - 1) * playlistsperpage)]:GetName() == "Favorites" then
						self:visible(false)
					else
						self:visible(true)
					end
				end
			end,
			MouseDownCommand = function(self, params)
				if params.event == "DeviceButton_left mouse button" and update and allplaylistsactive then
					local playlistNameSelect = allplaylists[i + ((currentplaylistpage - 1) * playlistsperpage)]
					local playslisttnaameeeeeeee = playlistNameSelect:GetName()
					playListCovers:get_data().playlistCover[playslisttnaameeeeeeee] = PlaylistCoverfallbackAsset
					playListCovers:set_dirty()
					playListCovers:save()
					
					SONGMAN:DeletePlaylist(playslisttnaameeeeeeee)

					allplaylists = SONGMAN:GetPlaylists()
					numplaylistpages = notShit.ceil(#allplaylists / playlistsperpage)
					MESSAGEMAN:Broadcast("DisplayAllPlaylists")
				end
			end,
			MouseOverCommand = function(self)
				self:diffusealpha(hoverAlpha)
			end,
			MouseOutCommand = function(self)
				self:diffusealpha(1)
			end,
		}
	}
	return o
end

local function PlaylistSelectLabel(i)
	local t = Def.ActorFrame {
		Name = "Label",
		InitCommand = function(self)
			self:xy(rankingX + offsetX + 30, rankingY + offsetY + 30 + (i - 1) * PlaylistYspacing)
			self:visible(true)
		end,
		DisplaySinglePlaylistMessageCommand = function(self)
			self:visible(false)
		end,
		DisplayAllPlaylistsMessageCommand = function(self)
			if update and allplaylists[i + ((currentplaylistpage - 1) * playlistsperpage)] then
				self:visible(true)
				MESSAGEMAN:Broadcast("AllDisplay")
			else
				self:visible(false)
			end
		end,
		LoadFont("Common Large") .. {
			InitCommand = function(self)
				self:halign(0):zoom(fontScale * 0.86)
				self:xy(15, row2Yoffset)
			end,
			AllDisplayMessageCommand = function(self)
				if allplaylists[i + ((currentplaylistpage - 1) * playlistsperpage)] then
					local strFileOrFiles

					if allplaylists[i + ((currentplaylistpage - 1) * playlistsperpage)]:GetNumCharts() == 1 then
						strFileOrFiles = "file"
					else
						strFileOrFiles = "files"
					end
					
					self:settextf(
						"%d %s",
						allplaylists[i + ((currentplaylistpage - 1) * playlistsperpage)]:GetNumCharts(),
						strFileOrFiles
					)
				end
			end
		},
		LoadFont("Common Large") .. {
			InitCommand = function(self)
				self:halign(0):zoom(fontScale * 0.88)
				self:xy(45, row2Yoffset + 11.5)
			end,
			AllDisplayMessageCommand = function(self)
				self:settext("MSD")
			end
		},
		LoadFont("Common Large") .. {
			InitCommand = function(self)
				self:halign(1):zoom(fontScale * 0.88)
				self:xy(43, row2Yoffset + 12)
			end,
			AllDisplayMessageCommand = function(self)
				if allplaylists[i + ((currentplaylistpage - 1) * playlistsperpage)] then
					local rating = allplaylists[i + ((currentplaylistpage - 1) * playlistsperpage)]:GetAverageRating()
					self:settextf("%.2f", rating)
					self:diffuse(byMSD(rating))
				end
			end
		},
		UIElements.SpriteButton(1, 1, nil) .. {
			InitCommand = function(self)
				self:visible(false)
				self:y(10)
				self:halign(1)
			end,
			AllDisplayMessageCommand = function(self)
				if allplaylists[i + ((currentplaylistpage - 1) * playlistsperpage)] then
					local namePlaylist = allplaylists[i + ((currentplaylistpage - 1) * playlistsperpage)]:GetName()
					local coverImage = playlistCovers[namePlaylist]

					if coverImage == nil then
						coverImage = playlistCovers["default"]
					end

					self:Load(coverImage)
					self:diffusealpha(1)
					self:scaletoclipped(sizePlayListsCover,sizePlayListsCover)
					self:visible(true)
				end
			end,
			MouseOverCommand = function(self)
				self:diffusealpha(0.6)
			end,
			MouseOutCommand = function(self)
				self:diffusealpha(1)
			end,
			MouseDownCommand = function(self, params)
				if params.event == "DeviceButton_left mouse button" then
					if allplaylists[i + ((currentplaylistpage - 1) * playlistsperpage)] then
						local namePlaylist = allplaylists[i + ((currentplaylistpage - 1) * playlistsperpage)]:GetName()
						curPlaylistSelected = namePlaylist
						SCREENMAN:SetNewScreen("ScreenPlaylistAssetSettings")
					end
				end
			end
			
		}
	}
	t[#t + 1] = PlaylistTitleDisplayButton(i)
	t[#t + 1] = DeletePlaylistButton(i)
	return t
end

local playlists = Def.ActorFrame {
	OnCommand = function(self)
		allplaylists = SONGMAN:GetPlaylists()
		numplaylistpages = notShit.ceil(#allplaylists / playlistsperpage)
	end,
	DisplayAllPlaylistsMessageCommand = function(self)
		self:visible(true)
		allplaylists = SONGMAN:GetPlaylists()
		numplaylistpages = notShit.ceil(#allplaylists / playlistsperpage)
	end
}

-- Buttons for general playlist manipulation
local b = Def.ActorFrame {
	InitCommand = function(self)
		self:xy(100, frameHeight + 30)
	end,
	DisplaySinglePlaylistMessageCommand = function(self)
		self:visible(false)
	end,
	DisplayAllPlaylistsMessageCommand = function(self)
		self:visible(true)
	end
}

playlists[#playlists + 1] = b

for i = 1, chartsperplaylist do
	r[#r + 1] = rankingLabel(i)
end

for i = 1, playlistsperpage do
	playlists[#playlists + 1] = PlaylistSelectLabel(i)
end

-- next/prev for all playlists
r[#r + 1] = Def.ActorFrame {
	InitCommand = function(self)
		self:xy(frameX + 1, frameY + rankingY + 315)
	end,
	UIElements.TextToolTip(1, 1, "Common Large") .. {
		InitCommand = function(self)
			self:x(capWideScale(190,197)):halign(1):zoom(0.25):diffuse(getMainColor("positive"))
			self:settext(translated_info["Next"])
		end,
		DisplaySinglePlaylistMessageCommand = function(self)
			if update then
				self:visible(false)
			end
		end,
		DisplayAllPlaylistsMessageCommand = function(self)
			if update then
				self:visible(true)
			end
		end,
		MouseDownCommand = function(self, params)
			if params.event == "DeviceButton_left mouse button" and currentplaylistpage < numplaylistpages and allplaylistsactive then
				currentplaylistpage = currentplaylistpage + 1
				MESSAGEMAN:Broadcast("DisplayAllPlaylists")
			end
		end,
		MouseOverCommand = function(self)
			self:diffusealpha(hoverAlpha)
		end,
		MouseOutCommand = function(self)
			self:diffusealpha(1)
		end,
	},
	UIElements.TextToolTip(1, 1, "Common Large") .. {
		InitCommand = function(self)
			self:halign(0):zoom(0.25):diffuse(getMainColor("positive"))
			self:settext(translated_info["Previous"])
		end,
		DisplaySinglePlaylistMessageCommand = function(self)
			self:visible(false)
		end,
		DisplayAllPlaylistsMessageCommand = function(self)
			self:visible(true)
		end,
		MouseDownCommand = function(self, params)
			if params.event == "DeviceButton_left mouse button" and currentplaylistpage > 1 and allplaylistsactive then
				currentplaylistpage = currentplaylistpage - 1
				MESSAGEMAN:Broadcast("DisplayAllPlaylists")
			end
		end,
		MouseOverCommand = function(self)
			self:diffusealpha(hoverAlpha)
		end,
		MouseOutCommand = function(self)
			self:diffusealpha(1)
		end,
	},
	LoadFont("Common Large") .. {
		InitCommand = function(self)
			self:x(102):halign(0.5):zoom(0.2)
		end,
		SetCommand = function(self)
			self:settextf(
				"%s %i-%i / %i",
				translated_info["Showing"],
				math.min(((currentplaylistpage - 1) * playlistsperpage) + 1, #allplaylists),
				math.min(currentplaylistpage * playlistsperpage, #allplaylists),
				#allplaylists
			)
		end,
		DisplayAllPlaylistsMessageCommand = function(self)
			self:visible(true):queuecommand("Set")
		end,
		DisplaySinglePlaylistMessageCommand = function(self)
			self:visible(false)
		end
	}
}

t[#t + 1] = playlists
t[#t + 1] = r
return t
