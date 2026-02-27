local widthSearchBar = 270
local indexSearch = 3 --this is for future proofing if we need to shrink tabs
local searchstring = ""
local active = false
local whee
local lastsearchstring = ""
local instantSearch = themeConfig:get_data().global.InstantSearch -- this causes more issues than solutions so it's gonna be disabled here for the time being
local IgnoreTabInput = themeConfig:get_data().global.IgnoreTabInput
local canwedeleteall = false

local function searchInput(event)
	if event.type ~= "InputEventType_Release" and active == true then
		if event.button == "Back" then
			local tind = getTabIndex()
			searchstring = ""
			whee:SongSearch(searchstring)
			resetTabIndex(0)
			MESSAGEMAN:Broadcast("TabChanged", {from = tind, to = 0})
			MESSAGEMAN:Broadcast("EndingSearch")
		elseif event.button == "Start" then
			local tind = getTabIndex()
			resetTabIndex(0)
			whee:SongSearch(searchstring)
			MESSAGEMAN:Broadcast("EndingSearch")
            if searchstring ~= "" then 
                lssP = searchstring 
            end
			MESSAGEMAN:Broadcast("TabChanged", {from = tind, to = 0})
		elseif event.DeviceInput.button == "DeviceButton_space" then -- add space to the string
			searchstring = searchstring .. " "
		elseif event.DeviceInput.button == "DeviceButton_backspace" then
			searchstring = searchstring:sub(1, -2) -- remove the last element of the string
		elseif event.DeviceInput.button == "DeviceButton_delete" then
			searchstring = ""
		else
			local CtrlPressed = INPUTFILTER:IsControlPressed()
			if event.DeviceInput.button == "DeviceButton_v" and CtrlPressed then
				searchstring = searchstring .. Arch.getClipboard()
			elseif
			--if not nil and (not a number or (ctrl pressed and not online))
            --regex directo del ultimo circulo del infierno
				event.char and event.char:match('[%%%+%-%!%@%#%$%^%&%*%(%)%=%_%.%,%:%;%\'%"%>%<%?%/%~%|%w%[%]%{%}%`%\\]') and
					(not tonumber(event.char) or CtrlPressed or IgnoreTabInput > 1)
			 then
				searchstring = searchstring .. event.char
			end
		end
		if lastsearchstring ~= searchstring then
			MESSAGEMAN:Broadcast("UpdateString")
			lastsearchstring = searchstring
		end
	end
end

local function setLastSearchFromCanceledSearchLastMinute(str)
    lssP = str 
end

local function CheckLastSearchAndIfActive(str, status)
    if status == false then return false end
    if str == "" or str == nil then return false end
    return true
end

--this is stuff that persists even after switching tabs
local t = Def.ActorFrame{
    InitCommand = function(self)
        self:xy(SCREEN_CENTER_X - (widthSearchBar) + 150,18)
    end,
    BeginCommand = function(self)
		self:queuecommand("Set")
		whee = SCREENMAN:GetTopScreen():GetMusicWheel()
		SCREENMAN:GetTopScreen():AddInputCallback(searchInput)
    end,
    SetCommand = function(self)
		self:finishtweening()
		if getTabIndex() == indexSearch then
			MESSAGEMAN:Broadcast("BeginningSearch")
			self:queuecommand("On")
			active = true
			whee:Move(0)
			SCREENMAN:set_input_redirected(PLAYER_1, true)
			MESSAGEMAN:Broadcast("RefreshSearchResults")
		else
			self:queuecommand("Off")
			active = false
			SCREENMAN:set_input_redirected(PLAYER_1, false)
		end
	end,
    TabChangedMessageCommand = function(self)
		self:queuecommand("Set")
	end,
    CurrentSongChangedMessageCommand = function(self)
        if getTabIndex() == indexSearch then 
            resetTabIndex(0)
            MESSAGEMAN:Broadcast("TabChanged", {from = indexSearch, to = 0})
            MESSAGEMAN:Broadcast("EndingSearch")
        end
    end,
    UIElements.QuadButton(1,1) .. {
        InitCommand = function(self)
            self:halign(0):diffusealpha(0.1):zoomto(widthSearchBar, 20)
        end,
        MouseOverCommand = function(self)
            self:diffusealpha(0.15)
        end,
        MouseOutCommand = function(self)
            local curTab = getTabIndex()

            if curTab ~= indexSearch then 
                self:diffusealpha(0.1)
            end
        end,
        MouseDownCommand = function(self, params)
            local curTab = getTabIndex()
            if params.event == "DeviceButton_left mouse button" and curTab ~= indexSearch then
                setTabIndex(indexSearch)
                MESSAGEMAN:Broadcast("TabChanged", {from = curTab, to = indexSearch})
            elseif params.event == "DeviceButton_right mouse button" and curTab == indexSearch then

                if searchstring ~= "" then
                    whee:SongSearch(searchstring)
                    setLastSearchFromCanceledSearchLastMinute(searchstring)
                end
                
                resetTabIndex(0)
                MESSAGEMAN:Broadcast("EndingSearch")
                MESSAGEMAN:Broadcast("TabChanged", {from = curTab, to = 0}) 
            end
        end,
        TabChangedMessageCommand = function(self, from, to)
            local curTab = getTabIndex()

            if curTab == indexSearch then
                self:diffusealpha(0.2)
            else
                self:diffusealpha(0.1)
            end
        end
    },
    UIElements.QuadButton(1,1) .. {
        InitCommand = function(self)
            self:diffuse(getGradeColor("Grade_Tier10"))
            self:y(10.5):halign(0):diffusealpha(0):zoomto(widthSearchBar, 1)
        end,
        TabChangedMessageCommand = function(self, from, to)
            local curTab = getTabIndex()

            if curTab == indexSearch then
                self:diffusealpha(1)
            else
                self:diffusealpha(0)
            end
        end
    },
    Def.Sprite{
        Name = "iconSearch",
        Texture = THEME:GetPathG("", "searchIcon"),
        InitCommand = function(self)
            self:x(17):halign(1):zoomto(13,13)
            self:diffusealpha(0.3)
        end
    },
    LoadFont("Common Large") .. {
        Name = "SearchString",
        InitCommand = function(self)
            self:x(20):halign(0):zoom(0.25)
        end,
		SetCommand = function(self)
            local showString = searchstring

            if #searchstring >= 40 then 
                showString = showString:sub(#searchstring - 37, #searchstring)
                showString = string.format(".%s", showString)
            end

			self:settext(showString)
		end,
		UpdateStringMessageCommand = function(self)
			self:queuecommand("Set")
		end
    },
    UIElements.SpriteButton(1, 1, THEME:GetPathG("", "cross")) .. {
        Name = "DeleteSearchMouse",
        InitCommand = function(self)
            self:x(widthSearchBar - 3):halign(1):zoomto(11,11):diffusealpha(0.15)
            self:visible(false)
        end,
        UpdateStringMessageCommand = function(self)
            if #searchstring >= 1 then
                canwedeleteall = true 
                self:visible(true)
            else
                canwedeleteall = false
                self:visible(false)
            end
        end,
        MouseOverCommand = function(self)
            if canwedeleteall == true then
                self:diffusealpha(0.25)
            end
        end,
        MouseOutCommand = function(self)
            if canwedeleteall == true then
                self:diffusealpha(0.15)
            end
        end,
        MouseDownCommand = function(self, params)
            if canwedeleteall and #searchstring >= 1 and params.event == "DeviceButton_left mouse button" then --seems very schizo to ask for the same thing twice but i don't want to lose my mind when something breaks
                searchstring = "" 
                whee:SongSearch(searchstring)
                MESSAGEMAN:Broadcast("UpdateString")
            end
        end
    },
    Def.ActorFrame{
        Name = "LastSearchedString",
        InitCommand = function(self)
            self:x(135):halign(0.5):diffusealpha(0)
        end,
        SetCommand = function(self)
            self:finishtweening()
            if CheckLastSearchAndIfActive(lssP, active) then
                self:decelerate(0.3):y(15):diffusealpha(1)
            end
        end,
        OffCommand = function(self)
            self:finishtweening()
            self:decelerate(0.2):y(0):diffusealpha(0)
        end,
        UpdateStringMessageCommand = function(self)
            self:queuecommand("Set")
        end,
        Def.Quad{
            InitCommand = function(self)
                self:diffuse(getMainColor("frames"))
                self:diffusealpha(0.76)
                self:valign(0)
                self:zoomto(widthSearchBar, 40)
            end
        },
        LoadFont("Common Large") .. {
            InitCommand = function(self)
                self:xy(-86, 6):halign(0):zoom(0.15)
                self:diffuse(getMainColor("positive"))
                self:settext("Recently Searched:")
            end
        },
        UIElements.TextToolTip(1, 1, "Common Large") .. {
            Name = "StringResultSuccessfull",
            InitCommand = function(self)
                self:halign(0.5):zoom(0.25):y(24)
                self:settext("")
            end,
            SetCommand = function(self)
                self:settext("")
                if CheckLastSearchAndIfActive(lssP, active) then
                    self:settextf("\"%s\"", lssP)
                end
            end,
            MouseOverCommand = function(self)
                if CheckLastSearchAndIfActive(lssP, active) then
                    self:diffusealpha(0.7)
                end
            end,
            MouseOutCommand = function(self)
                if CheckLastSearchAndIfActive(lssP, active) then
                    self:diffusealpha(1)
                end
            end,
            MouseDownCommand = function(self, params)
                local curTab = getTabIndex()
                if CheckLastSearchAndIfActive(lssP, active) and params.event == "DeviceButton_left mouse button" and curTab == indexSearch then --wow that's a lot of buts
                    searchstring = lssP
                    whee:SongSearch(searchstring)
                    MESSAGEMAN:Broadcast("UpdateString")
                end
            end
        }
    }
}

return t