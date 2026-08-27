return Def.ActorFrame {
	Def.Quad {
		Name = "Horizontal",
		InitCommand = function(self)
			self:xy(-5.25,0):zoomto(854, 29):halign(0)
		end,
		SetCommand = function(self)
			self:diffuse(color("#ffffff1e"))
		end,
		BeginCommand = function(self)
			self:queuecommand("Set")
		end,
		OffCommand = function(self)
			self:visible(false)
		end
	}
}
