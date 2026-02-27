return Def.ActorFrame {
	Def.Quad {
		InitCommand = function(self)
			self:xy(2, -2):zoomto(4, 19)
		end,
		SetGradeCommand = function(self, params)
			if params.HasGoal then
				if not params.AllGoalsComplete then
					self:diffuse(byJudgment("TapNoteScore_Miss"))
				else
					self:diffuse(byJudgment("TapNoteScore_W1"))
				end
				self:diffusealpha(1)
			else
				self:diffusealpha(0)
			end
		end
	},
	LoadFont("Common Normal") .. {
		InitCommand = function(self)
			self:xy(16, -1):zoom(0.5):maxwidth(WideScale(get43size(20), 20) / 0.5)
		end,
		SetGradeCommand = function(self, params)
			local sGrade = params.Grade or "Grade_None"
			self:valign(0.5)
			self:settext(THEME:GetString("Grade", ToEnumShortString(sGrade)) or "")
			self:diffuse(getGradeColor(sGrade))
		end
	},
	Def.Sprite {
		InitCommand = function(self)
			self:xy(455, -3):zoomto(4, 19)
			self:wag()
		end,
		SetGradeCommand = function(self, params)
			if params.PermaMirror then
				self:Load(THEME:GetPathG("", "mirror"))
				self:zoomto(13, 13)
				self:visible(true)
			else
				self:visible(false)
			end
		end
	},
	Def.Sprite {
		InitCommand = function(self)
			self:xy(455, -5):zoomto(4, 19)
			self:halign(0.5)
			self:pulse()
		end,
		SetGradeCommand = function(self, params)
			if params.Favorited then
				self:Load(THEME:GetPathG("", "favorite"))
				self:zoomto(12, 12)
				self:visible(true)
			else
				self:visible(false)
			end
		end,
		SetMessageCommand = function(self,params)
			local song = params.Song
			if song and self:IsVisible() then 
				local titleSong = song:GetDisplayMainTitle()
				
				self:x(30 + (#titleSong * 6.3))
			end
		end
	},
}
