local enabled = PREFSMAN:GetPreference("ShowBackgrounds")
local brightness = 0.3
local bottomFrameHeight = 25.776
local t = Def.ActorFrame {}

if enabled then
	t[#t + 1] = Def.Sprite {
		OnCommand = function(self)
			if GAMESTATE:GetCurrentSong() and GAMESTATE:GetCurrentSong():GetBackgroundPath() then
				self:finishtweening()
				self:visible(true)
				self:diffusealpha(brightness)
				self:LoadBackground(GAMESTATE:GetCurrentSong():GetBackgroundPath())
				self:scaletocover(0, 0, SCREEN_WIDTH, SCREEN_BOTTOM)
			else
				self:visible(false)
			end
		end
	}

	t[#t + 1] = Def.Quad {
		OnCommand = function(self)
			self:diffuse(getMainColor("positive")):fadetop(0.4):diffusealpha(0.4)
			self:scaletocover(0, SCREEN_HEIGHT / 1.5, SCREEN_WIDTH, SCREEN_BOTTOM)
			self:addy(350)
			self:blend("BlendMode_Normal")
		end
	}
end

t[#t + 1] = UIElements.QuadButton(1, 1) .. {
	InitCommand = function(self)
		self:xy(0, SCREEN_HEIGHT):halign(0):valign(1):zoomto(SCREEN_WIDTH, bottomFrameHeight):diffuse(Brightness(getMainColor("positive"),0.07))
	end,
}

t[#t + 1] = UIElements.QuadButton(1, 1) .. {
	InitCommand = function(self)
		self:xy(0, 0):halign(0):valign(0):zoomto(SCREEN_WIDTH, bottomFrameHeight):diffuse(Brightness(getMainColor("positive"),0.07))
	end,
}

t[#t + 1] = Def.Sprite {
	Name = "Banner",
	OnCommand = function(self)
		self:x(205):y(120):valign(0)
		self:scaletoclipped(capWideScale(get43size(336), 336), capWideScale(get43size(105), 105))
		local bnpath = GAMESTATE:GetCurrentSong():GetBannerPath()
		self:visible(true)
		if not BannersEnabled() then
			self:visible(false)
		elseif not bnpath then
			bnpath = THEME:GetPathG("Common", "fallback banner")
		end
		self:LoadBackground(bnpath)
	end
}

return t
