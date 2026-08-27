--uuhhhhhhhhhhhh not sure if i have to credit it but this whole code is from spwncamp, so credits to poco for all of this, i just edited some things to make it work on til death
local t = Def.ActorFrame{}
local circleRadius = 50
local maxValue = 41
local softCap = 40/30
local frameWidth = capWideScale(80,100)
local frameHeight = 300


local SkillSets = {
	"Stream", 
	"Jumpstream", 
	"Handstream", 
	"Stamina",
	"JackSpeed",
	"Chordjack",
	"Technical"
}



-- Angle in degrees
local function getPointOffset(distance, angle)
	local rad = math.rad(angle)
	return math.cos(rad)*distance, math.sin(rad)*distance
end

local sepAngle = 360/#SkillSets-1
local verts = {}
local maxVerts = {}

local function makeMSDPoints(i)
	return LoadFont("Common Normal")..{
		InitCommand  = function(self)
			local x,y = getPointOffset(circleRadius,sepAngle*(i-1)-90)
			self:xy(x,y)
			self:zoom(0.3)
		end,
		SetStepsMessageCommand = function(self, params)
			local steps = params.steps
			local MSD = steps:GetMSD(getCurRateValue(), i+1)
			self:settextf("%s",SkillSets[i])
		end
	}
end

t[#t+1] = Def.ActorMultiVertex{
	Name= "SSR_MAX_Graph",
	InitCommand = function(self)
		local x,y
		for i=1, #SkillSets do
			x,y = getPointOffset(circleRadius,sepAngle*(i-1)-90)

			maxVerts[#maxVerts+1] = {{x,y,0},color("#FFFFFF66")}
			maxVerts[#maxVerts+1] = {{0,0,0},color("#FFFFFF66")}
		end

		maxVerts[#maxVerts+1] = maxVerts[1]
		maxVerts[#maxVerts+1] = {{0,0,0},color("#FFFFFF66")}

		self:SetDrawState{First= 1, Num= -1}
		self:SetDrawState{Mode="DrawMode_QuadStrip"}
		self:playcommand("Set")
	end,
	SetCommand = function(self)
		self:diffusealpha(0.2)
		self:SetVertices(maxVerts)
		self:SetDrawState{First= 1, Num= -1}
	end
}

t[#t+1] = Def.ActorMultiVertex{
	Name= "SSR_Graph",
	InitCommand = function(self)
		self:SetDrawState{Mode="DrawMode_QuadStrip"}
		self:queuecommand("Set")
		self:diffusealpha(0.5)
	end,
	SetCommand = function(self)
		self:finishtweening()
		self:easeOut(1)
		self:SetVertices(verts)
		self:SetDrawState{First= 1, Num= -1}
	end,
	SetStepsMessageCommand = function(self, params)
		verts = {}
		local steps = params.steps
		local x,y
		local overallMSD = steps:GetMSD(getCurRateValue(), 1)
		local MSD
		for i=1, #SkillSets do
			x,y = getPointOffset(circleRadius,sepAngle*(i-1)-90)
			MSD = steps:GetMSD(getCurRateValue(), i+1)

			verts[#verts+1] = {{x*math.min(softCap,MSD/maxValue),y*math.min(softCap,MSD/maxValue),0},getMSDColor(MSD)}
			verts[#verts+1] = {{0,0,0},color("#FFFFFF")}
		end

		verts[#verts+1] = verts[1]
		verts[#verts+1] = {{0,0,0},color("#FFFFFF")}

		self:playcommand("Set")
	end
}

for i=1, #SkillSets do
	t[#t+1] = makeMSDPoints(i)
end

return t