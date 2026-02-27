local t = Def.ActorFrame {}
local topFrameHeight = 34.224
local bottomFrameHeight = 25.776

local fuckkkkkkkkkkkkkkkkkkkkkk = capWideScale(0.46,0.59479166)
--Frames
t[#t + 1] = UIElements.QuadButton(1, 1) .. {
	InitCommand = function(self)
		self:xy(SCREEN_CENTER_X + 29, topFrameHeight + 40):valign(0):zoomto(SCREEN_WIDTH * fuckkkkkkkkkkkkkkkkkkkkkk, SCREEN_HEIGHT / 5):diffuse(Brightness(getMainColor("positive"),0.1)):fadebottom(1)
	end
}

t[#t + 1] = UIElements.QuadButton(1, 1) .. {
	InitCommand = function(self)
		self:xy(SCREEN_CENTER_X + 29, topFrameHeight + 20):valign(0):zoomto(SCREEN_WIDTH * fuckkkkkkkkkkkkkkkkkkkkkk, capWideScale(get43size(120 / 1.5), 120 / 1.5)):diffuse(getMainColor("frames"))
	end
}

t[#t + 1] = UIElements.QuadButton(1, 1) .. {
	InitCommand = function(self)
		self:xy(SCREEN_CENTER_X + 29, topFrameHeight):valign(0):zoomto(SCREEN_WIDTH * fuckkkkkkkkkkkkkkkkkkkkkk, capWideScale(get43size(120 / 1.5), 120 / 1.5)):diffuse(Brightness(getMainColor("positive"),0.2))
	end
}

t[#t + 1] = UIElements.QuadButton(1, 1) .. {
	InitCommand = function(self)
		self:xy(0, 0):halign(0):valign(0):zoomto(SCREEN_WIDTH, topFrameHeight):diffuse(getMainColor("frames"))
	end
}

t[#t + 1] = UIElements.QuadButton(1, 1) .. {
	InitCommand = function(self)
		self:xy(0, SCREEN_HEIGHT):halign(0):valign(1):zoomto(SCREEN_WIDTH, bottomFrameHeight):diffuse(getMainColor("frames"))
	end
}

--[[
if themeConfig:get_data().global.TipType == 2 or themeConfig:get_data().global.TipType == 3 then
	t[#t + 1] =
		LoadFont("Common Normal") ..
		{
			InitCommand = function(self)
				self:xy(SCREEN_CENTER_X, SCREEN_BOTTOM - 7):zoom(0.35):settext(
					getRandomQuotes(themeConfig:get_data().global.TipType)
				):diffuse(getMainColor("highlight")):diffusealpha(0):zoomy(0):maxwidth((SCREEN_WIDTH - 350) / 0.35)
			end,
			BeginCommand = function(self)
				self:sleep(2)
				self:smooth(1)
				self:diffusealpha(1)
				self:zoomy(0.35)
			end
		}
end
]]

return t
