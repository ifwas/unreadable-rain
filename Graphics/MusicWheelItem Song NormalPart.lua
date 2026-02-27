local lastclick = GetTimeSinceStart()
local tagTable = {}
local requiredtimegap = 0.1

local function tagCheck(step)
    tagTable = {}

end

return Def.ActorFrame {
    UIElements.QuadButton(1, 1) .. {
		InitCommand = function(self)
			self:halign(0)
			self:xy(0,0)
			self:diffusealpha(0)
			self:zoomto(854, 30)
		end,
        SetCommand = function(self, params)
            self.index = params.DrawIndex
        end,
		MouseDownCommand = function(self, params)
            if params.event == "DeviceButton_left mouse button" and getTabIndex() ~= 4 then
                local now = GetTimeSinceStart()
                if now - lastclick < requiredtimegap then return end --fuckass math
                lastclick = now

                local numwheelitems = 15
                local middle = math.ceil(15 / 2)
                local top = SCREENMAN:GetTopScreen()
                local we = top:GetMusicWheel()
                if we then
                    local dist = self.index - middle
                    if dist == 0 and we:IsSettled() then
                        -- clicked current item
                        top:SelectCurrent()
                    else
                        local itemtype = we:MoveAndCheckType(self.index - middle)
                        we:Move(0)
                        if itemtype == "WheelItemDataType_Section" then
                            -- clicked a group
                            top:SelectCurrent()
                        end
                    end
                end
            elseif params.event == "DeviceButton_right mouse button" then
                SCREENMAN:GetTopScreen():PauseSampleMusic()
                MESSAGEMAN:Broadcast("MusicPauseToggled")
            end
		end,
	},
}
