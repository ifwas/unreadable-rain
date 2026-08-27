local assetTable = {}
local frameWidth = SCREEN_WIDTH - 20
local frameHeight = SCREEN_HEIGHT - 40

local maxPage = 1
local curPage = 1
curIndex = 1

local maxRows = 1
local maxColumns = 9
local assetWidth = 100
local assetHeight = 100
local assetXSpacing = (frameWidth + assetWidth/2) / (maxColumns + 1)
local assetYSpacing = (frameHeight) / (maxRows + 1) + 20

local fuck = "/Themes/" .. THEME:GetCurThemeName() .. "/Graphics/playlistCovers"
--curPlaylistSelected is a global variable located in scripts

local function isImage(filename)
	local extensions = {".png", ".jpg", "jpeg"} -- lazy list
	local ext = string.sub(filename, #filename-3)
	for i=1, #extensions do
		if extensions[i] == ext then return true end
	end
	return false
end

local function updateTable()
    local table = {}
    local fuckindex = 1
    assetTable = FILEMAN:GetDirListing(playlistAssetFolder)
    
    for i = 1, #assetTable do
        if isImage(assetTable[i]) then
            table[fuckindex] = assetTable[i]
            fuckindex = fuckindex + 1
        end
    end

    assetTable = table

    curPage = 1
    maxPage = math.max(1, math.ceil(#assetTable/(maxColumns * maxRows)))
    MESSAGEMAN:Broadcast("tableUpdated")
end

local function movePage(n)
    local nextPage = curPage + n
    if nextPage > maxPage then
        nextPage = maxPage
    elseif nextPage < 1 then
        nextPage = 1
    end

    if nextPage ~= curPage then
        curPage = nextPage
        MESSAGEMAN:Broadcast("playPageMoved",{page = curPage})
    end
end 

local function input(event)
    if event.type ~= "InputEventType_Release" then
        if event.button == "Back" then
            SCREENMAN:GetTopScreen():Cancel()
        end
    end

    if event.type == "InputEventType_FirstPress" then
		if event.DeviceInput.button == "DeviceButton_right mouse button" then
			MESSAGEMAN:Broadcast("MouseRightClick")
		elseif event.DeviceInput.button == "DeviceButton_mousewheel up" and event.type == "InputEventType_FirstPress" then
			movePage(-1)
		elseif event.DeviceInput.button == "DeviceButton_mousewheel down" and event.type == "InputEventType_FirstPress" then
			movePage(1)
		end
	end

    return false
end

local t = Def.ActorFrame {
    BeginCommand = function(self)
        top = SCREENMAN:GetTopScreen()
        top:AddInputCallback(input)
        updateTable()
    end,
    Def.Sprite{
        BeginCommand = function(self)
            self:LoadBackground(THEME:GetPathG("", "BackgroundTitle/ass"))
            self:scaletocover(0, 0, SCREEN_WIDTH, SCREEN_BOTTOM)
            self:diffusealpha(0.3)
        end
    },
    UIElements.QuadButton(1, 1) .. {
        BeginCommand = function(self)
            self:xy(0, 200):halign(0):valign(0):zoomto(SCREEN_WIDTH, SCREEN_HEIGHT):diffuse(getMainColor("highlight")):fadetop(1)
        end
    },
    UIElements.QuadButton(1, 1) .. {
        BeginCommand = function(self)
            self:xy(0, 0):halign(0):valign(0):zoomto(SCREEN_WIDTH, 26):diffuse(getMainColor("frames"))
        end
    },
    UIElements.QuadButton(1, 1) .. {
        BeginCommand = function(self)
            self:xy(0, SCREEN_HEIGHT):halign(0):valign(1):zoomto(SCREEN_WIDTH, 26):diffuse(getMainColor("frames"))
        end
    },
    LoadFont("Common Large") .. {
        BeginCommand = function(self)
            self:xy(8, SCREEN_BOTTOM - 14):halign(0):zoom(0.2)
            self:diffuse(color("#919191ff"))
            self:settext("You can add more Playlist Covers in: \"" .. THEME:GetCurThemeName() .. "/Graphics/playlistCovers\"")
        end
    },
    LoadFont("Common Large") .. {
        BeginCommand = function(self)
            self:xy(SCREEN_RIGHT - 10, 14):halign(1):zoom(0.32)
            self:settext(curPlaylistSelected)
        end
    },
    LoadFont("Common Large") .. {
        BeginCommand = function(self)
            self:xy(SCREEN_RIGHT - 10, SCREEN_BOTTOM - 14):halign(1):zoom(0.32)
            self:settext(curPage .. "/" .. maxPage .. " Pages")
        end,
        playPageMovedMessageCommand = function(self)
            self:finishtweening()
            self:diffusealpha(0.3)
            self:y(SCREEN_BOTTOM - 10):decelerate(0.2):y(SCREEN_BOTTOM - 14):diffusealpha(1)
            self:settext(curPage .. "/" .. maxPage .. " Pages")
        end
    },
    UIElements.TextToolTip(1, 1, "Common Large") .. {
        BeginCommand = function(self)
            self:xy(8, 15):halign(0):zoom(0.27)
            self:diffusealpha(1)
            self:settext("Playlist Cover:")
        end,
        MouseOverCommand = function(self)
            self:diffusealpha(0.4)
        end,
        MouseOutCommand = function(self)
            self:diffusealpha(1)
        end,
        MouseDownCommand = function(self, params)
            if params.event == "DeviceButton_left mouse button" then
                updateTable()
                ms.ok("Looking for new images...")
            end
        end
    }
}

local function assetBox(i)
    local t = Def.ActorFrame{
        BeginCommand = function(self)
            self:x((((i-1) % maxColumns)+1)*86)
            self:y(((math.floor((i-1)/maxColumns)+1)*assetYSpacing)-20+25)
        end,
        playPageMovedMessageCommand = function(self)
            local delay = 0.001 * i
            self:finishtweening()
            self:diffusealpha(0)
            self:queuecommand("settingIn")
            self:y(((math.floor((i-1)/maxColumns)+1)*assetYSpacing)-20+10):decelerate(0.33 + delay):y(((math.floor((i-1)/maxColumns)+1)*assetYSpacing)-20+25):diffusealpha(1)
        end,
        Def.Quad {
            Name = "BG",
            BeginCommand = function(self)
                self:xy(-4, 4)
                self:zoomto(72,72):diffuse(color("#000000")):diffusealpha(0.5)
                self:visible(false)
            end
        },
        UIElements.SpriteButton(1, 1, nil) .. {
            BeginCommand = function(self)
                self:visible(false)
            end,
            tableUpdatedMessageCommand = function(self)
                self:queuecommand("settingIn")
            end,
            settingInCommand = function(self)
                self:queuecommand("HideThing")
                local item = assetTable[i + (maxColumns * (curPage - 1))]
                if item then 
                    if isImage(item) then
                        local path = fuck .. "/" .. item
                        self:Load(path)
                        self:diffusealpha(1)
                        self:scaletoclipped(70,70)
                        self:queuecommand("ShowThing")
                    end
                end
            end,
            ShowThingCommand = function(self)
                self:GetParent():GetChild("BG"):visible(true)
                self:visible(true)
            end,
            HideThingCommand = function(self)           
                self:GetParent():GetChild("BG"):visible(false)
                self:visible(false)
            end,
            MouseOverCommand = function(self)
                self:diffusealpha(0.6)
            end,
            MouseOutCommand = function(self)
                self:diffusealpha(1)
            end,
            MouseDownCommand = function(self, params)
                local item = assetTable[i + (maxColumns * (curPage - 1))]
                if params.event == "DeviceButton_left mouse button" and isImage(item) then
                    local path = fuck .. "/" .. item
                    playListCovers:get_data().playlistCover[curPlaylistSelected] = path
                    playListCovers:set_dirty()
                    playListCovers:save()
                    SCREENMAN:GetTopScreen():Cancel()
                end
            end
        },
    }
    return t
end


for i=1, maxRows * maxColumns do
	t[#t+1] = assetBox(i)
end

return t