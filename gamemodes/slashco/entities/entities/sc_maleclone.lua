AddCSLuaFile()

local SlashCo = SlashCo

ENT.Base = "base_nextbot"
ENT.Type = "nextbot"
ENT.ClassName = "sc_maleclone"
ENT.PingType = "SLASHER"

function ENT:Initialize()
	if CLIENT then
		self:SetIK()
	end

	self:SetModel("models/Humans/Group01/male_07.mdl")
	self:SetCollisionGroup(COLLISION_GROUP_PASSABLE_DOOR)
end

function ENT:OnTakeDamage()
	return 0
end

function ENT:RunBehaviour()
	while true do
		-- Here is the loop, it will run forever
		self:StartActivity(ACT_WALK)            -- Walk animation
		self.loco:SetDesiredSpeed(100)        -- Walk speed

		local pos = SlashCo.RandomPosLocator()
		if g_SlashCoDebug then
			debugoverlay.Cross(pos, 40, 30, Color(0, 255, 255), true)
		end
		self:MoveToPos(pos, {
			draw = g_SlashCoDebug and GetConVar("developer"):GetBool(),
			repath = 6,
			lookahead = 600
		}) -- Walk to a random place
		self:StartActivity(ACT_IDLE)

		if not self.GotStuck then
			coroutine.wait(math.Rand(0, 35))
		end
		self.GotStuck = nil

		coroutine.yield()
		-- The function is done here, but will start back at the top of the loop and make the bot walk somewhere else

		if self:GetPos()[3] < -16000 then
			self:Remove()
			SlashCo.CreateItem("sc_maleclone", SlashCo.RandomPosLocator(), Angle(0, 0, 0))
		end
	end
end

function ENT:HandleStuck()
	local justGo = SlashCo.RandomPosLocator()
	if justGo then
		self:EmitSound("physics/water/water_impact_hard" .. math.random(2) .. ".wav", 75, 90, 0.1)
		self.loco:ClearStuck()
		self:SetPos(justGo)
		return
	end
end

if CLIENT then
	function ENT:Draw()
		self:DrawModel()
	end

	return
end

function ENT:UpdateTransmitState()
	return TRANSMIT_ALWAYS
end

function ENT:Think()
	local tr = util.TraceLine({
		start = self:GetPos() + Vector(0, 0, 50),
		endpos = self:GetPos() + self:GetForward() * 10000,
		filter = self
	})

	if IsValid(tr.Entity) and tr.Entity:GetClass() == "prop_door_rotating" and self:GetPos():Distance(tr.Entity:GetPos()) < 100 and
			not tr.Entity.IsOpen and (not self.UseCooldown or CurTime() - self.UseCooldown > 2) then

		tr.Entity:Use(self)
		self.UseCooldown = CurTime()
	end
end