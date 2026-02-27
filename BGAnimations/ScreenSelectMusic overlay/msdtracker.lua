--Local vars
local update = false
local steps
local song
local frameX = -190
local frameY = 144
local frameWidth = SCREEN_WIDTH * 0.56
local frameHeight = 368
local fontScale = 0.4
local distY = 15
local offsetX = 10
local offsetY = 20
local pn = GAMESTATE:GetEnabledPlayers()[1]
local greatest = 0
local txtDist = 18
local steps
local meter = {}
meter[1] = 0.00

local translated_text = {
	AverageNPS = THEME:GetString("TabMSD", "AverageNPS"),
	NegBPM = THEME:GetString("TabMSD", "NegativeBPM"),
	Title = THEME:GetString("TabMSD", "Title")
}

--Actor Frame
local t = Def.ActorFrame {
	Name = "msddddd",
	BeginCommand = function(self)
		self:queuecommand("Set")
	end,
	SetCommand = function(self)
		self:finishtweening()
		self:sleep(0.05)
			song = GAMESTATE:GetCurrentSong()
			steps = GAMESTATE:GetCurrentSteps()
			greatest = 0
			if song and steps then
				for i = 1, #ms.SkillSets do
					meter[i + 1] = steps:GetMSD(getCurRateValue(), i)
					if meter[i + 1] > meter[greatest + 1] then
						greatest = i
					end
				end
			end
        update = true
	end,
    MintyFreshCommand = function(self)
		self:finishtweening()
		self:sleep(0.05)
        self:playcommand("Set")
    end,
	CurrentRateChangedMessageCommand = function(self)
		self:finishtweening()
		self:playcommand("Set")
	end,
	CurrentStepsChangedMessageCommand = function(self)
		self:finishtweening()
		self:sleep(0.05)
		self:queuecommand("Set")
	end,
}

--Skillset label function
local function littlebits(i)
	local t = Def.ActorFrame {
		LoadFont("Common Large") .. {
			InitCommand = function(self)
				self:xy(frameX + 20, frameY + 10 + txtDist * i):halign(0):valign(0):zoom(0.3):maxwidth(155 / 0.55)
			end,
			SetCommand = function(self)
				--skillset name
				if song and steps then
					self:settext(ms.SkillSetsTranslated[i] .. ":")
				else
					self:settext("")
				end
				--highlight
				if greatest == i then
					self:diffusetopedge(Saturation(getMainColor("highlight"), 0.5))
					self:diffusebottomedge(Saturation(getMainColor("positive"), 0.6))
				end
			end
		},
		LoadFont("Common Large") .. {
			InitCommand = function(self)
				self:xy(-20, frameY + 10 + txtDist * i):halign(1):valign(0):zoom(0.3):maxwidth(110 / 0.55)
			end,
			SetCommand = function(self)
				if song and steps then
					self:settextf("%05.2f", meter[i + 1])
					self:diffuse(byMSD(meter[i + 1]))
				else
					self:settext("")
				end
			end
		}
	}
	return t
end

t[#t + 1] = LoadFont("Common Large")..{
    InitCommand = function(self)
        self:xy(-12, frameY + 22):halign(1):valign(0):zoom(0.45)
    end,
    SetCommand = function(self)
        if song and steps then
            local overall = steps:GetMSD(getCurRateValue(), 1)
            self:settextf("%05.2f", overall)
            self:diffuse(byMSD(overall))
        else
            self:settext("")
        end
    end
}

--Skillset labels
for i = 2, #ms.SkillSets do
	t[#t + 1] = littlebits(i)
end

return t