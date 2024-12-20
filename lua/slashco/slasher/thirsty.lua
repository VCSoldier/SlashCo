local SLASHER = {}

SLASHER.Name = "Thirsty"
SLASHER.ID = 5
SLASHER.Class = 2
SLASHER.DangerLevel = 2
SLASHER.IsSelectable = true
SLASHER.Model = "models/slashco/slashers/thirsty/thirsty.mdl"
SLASHER.GasCanMod = 0
SLASHER.KillDelay = 2
SLASHER.ProwlSpeed = 100
SLASHER.ChaseSpeed = 260
SLASHER.Perception = 1.0
SLASHER.Eyesight = 2
SLASHER.KillDistance = 150
SLASHER.ChaseRange = 900
SLASHER.ChaseRadius = 0.92
SLASHER.ChaseDuration = 8.0
SLASHER.ChaseCooldown = 3
SLASHER.JumpscareDuration = 2
SLASHER.ChaseMusic = "slashco/slasher/thirsty_chase.wav"
SLASHER.KillSound = "slashco/slasher/thirsty_kill.mp3"
SLASHER.Description = "Thirsty_desc"
SLASHER.ProTip = "Thirsty_tip"
SLASHER.SpeedRating = "★☆☆☆☆"
SLASHER.EyeRating = "★★☆☆☆"
SLASHER.DiffRating = "★★★☆☆"
SLASHER.ItemToSpawn = "MilkJug"

SLASHER.OnSpawn = function(slasher)
	slasher:SetViewOffset(Vector(0, 0, 20))
	slasher:SetCurrentViewOffset(Vector(0, 0, 20))
end

SLASHER.OnTickBehaviour = function(slasher)
	local SO = SlashCo.CurRound.OfferingData.SO
	--local SatO = SlashCo.CurRound.OfferingData.SatO

	local v1 = slasher.SlasherValue1 --Milk drank
	local v2 = slasher.SlasherValue2 --Pacification
	local v3 = slasher.SlasherValue3 --Thirst
	--local v4 = slasher.SlasherValue4 --prowl speed
	--local v5 = slasher.SlasherValue5 --chase speed

	local eyesight_final = SLASHER.Eyesight
	local perception_final = SLASHER.Perception

	if v2 > 0 then
		--Thirsty is pacified
		slasher.SlasherValue3 = 0

		slasher.SlasherValue4 = 100
		slasher.SlasherValue5 = 100
		eyesight_final = 0
		perception_final = 0

		slasher.SlasherValue2 = v2 - (0.01 + (SO * 0.04))
		slasher:SetNWBool("CanKill", false)
		slasher:SetNWBool("CanChase", false)
		slasher.SlasherValue3 = 0
		slasher:SetNWBool("DemonPacified", true)
	else
		--Thirsty is not pacified
		if v3 < 100 then
			slasher.SlasherValue3 = v3 + (FrameTime() / (2 - (SO / 2)))
		end
		--Deplete thirst

		slasher.SlasherValue5 = 285 - (v1 * 10)
		slasher.SlasherValue4 = 100 + ((v3 / (7 - v1)) + (v1 * 30)) * (0.8 + (SO * 0.5))
		eyesight_final = 2 + (v3 / (28.5 - (v1 * 4)))
		perception_final = 1.0 + (v3 / (44.5 - (v1 * 8)))
		--Thirsty's basic stats raise the thirstier he is, and are also multiplied by how much milk he has drunk.
		--His chase speed is greatest at low milk drank, and the more he drinks, it is converted to prowl speed.

		slasher:SetNWBool("CanKill", true)
		slasher:SetNWBool("CanChase", true)
		slasher:SetNWBool("DemonPacified", false)

		if slasher:GetNWBool("InSlasherChaseMode") then
			slasher:SetRunSpeed(slasher.SlasherValue5)
			slasher:SetWalkSpeed(slasher.SlasherValue5)
		else
			slasher:SetRunSpeed(slasher.SlasherValue4)
			slasher:SetWalkSpeed(slasher.SlasherValue4)
		end
	end

	slasher:SetNWInt("ThirstyThirst", math.floor(v3))

	if slasher:GetNWInt("ThirstyMilkDrank") ~= v1 then
		slasher:SetNWInt("ThirstyMilkDrank", v1)
	end

	slasher:SetNWFloat("Slasher_Eyesight", eyesight_final)
	slasher:SetNWInt("Slasher_Perception", perception_final)
end

SLASHER.OnPrimaryFire = function(slasher, target)
	SlashCo.Jumpscare(slasher, target)
end

SLASHER.OnSecondaryFire = function(slasher)
	SlashCo.StartChaseMode(slasher)
end

SLASHER.OnMainAbilityFire = function(slasher, target)
	local SO = SlashCo.CurRound.OfferingData.SO
	local SatO = SlashCo.CurRound.OfferingData.SatO

	if not IsValid(target) or target:GetClass() ~= "sc_milkjug" then
		return
	end

	if slasher:GetPos():Distance(target:GetPos()) >= 150 or slasher:GetNWBool("ThirstyDrinking") then
		return
	end

	slasher:SetNWBool("ThirstyDrinking", true)
	slasher:SetNWBool("InSlasherChaseMode", false)
	slasher:StopSound(SlashCoSlashers[slasher:GetNWString("Slasher")].ChaseMusic)
	slasher:SetRunSpeed(slasher.SlasherValue4)
	slasher:SetWalkSpeed(slasher.SlasherValue4)
	slasher.SlasherValue2 = 99
	slasher:Freeze(true)

	target:Remove()

	local matrix = slasher:GetBoneMatrix(slasher:LookupBone("HandR"))
	local pos = matrix:GetTranslation()
	local ang = matrix:GetAngles()

	local chugjug = ents.Create("prop_physics")

	chugjug:SetMoveType(MOVETYPE_NONE)
	chugjug:SetCollisionGroup(COLLISION_GROUP_IN_VEHICLE)
	chugjug:SetModel(SlashCoItems.MilkJug.Model)
	chugjug:SetPos(pos)
	chugjug:SetAngles(ang)

	chugjug:FollowBone(slasher, slasher:LookupBone("HandR"))

	timer.Simple(1, function()
		if not IsValid(slasher) then
			return
		end

		slasher:EmitSound("slashco/slasher/thirsty_drink.mp3")
	end)

	timer.Simple(4.5, function()
		if not IsValid(chugjug) then
			return
		end

		chugjug:Remove()

		local emptyjug = ents.Create("prop_physics")
		emptyjug:SetSolid(SOLID_VPHYSICS)
		emptyjug:PhysicsInit(SOLID_VPHYSICS)
		emptyjug:SetCollisionGroup(COLLISION_GROUP_PASSABLE_DOOR) --Collide with everything but the player
		emptyjug:SetMoveType(MOVETYPE_VPHYSICS)
		emptyjug:SetModel(SlashCoItems.MilkJug.Model)
		emptyjug:SetPos(pos)
		emptyjug:SetAngles(ang)
		emptyjug:Spawn()
		emptyjug:Activate()
		local phys = emptyjug:GetPhysicsObject()
		if phys:IsValid() then
			phys:Wake()
		end
		phys:ApplyForceCenter(slasher:GetAimVector() * 450)

		timer.Simple(4.5, function()
			if not IsValid(emptyjug) then
				return
			end

			emptyjug:Remove()
		end)
	end)

	timer.Simple(8, function()
		if not IsValid(slasher) then
			return
		end

		slasher:Freeze(false)
		slasher:SetNWBool("ThirstyDrinking", false)
		slasher:SetNWBool("DemonPacified", true)

		if slasher.SlasherValue1 < (4 + SatO) then
			slasher.SlasherValue1 = slasher.SlasherValue1 + 1 + SatO
		end

		slasher.SlasherValue2 = math.random(20, 35)

		if slasher.SlasherValue1 > 2 then
			slasher:SetNWBool("ThirstyBigMlik", true)
		end
	end)
end

SLASHER.Animator = function(ply)
	local chase = ply:GetNWBool("InSlasherChaseMode")
	local pac = ply:GetNWBool("DemonPacified")

	if not ply:GetNWBool("ThirstyDrinking") then
		ply.anim_antispam = false
	end

	if ply:IsOnGround() then
		if not chase then
			if not ply:GetNWBool("ThirstyBigMlik") then
				ply.CalcIdeal = ACT_HL2MP_WALK
				ply.CalcSeqOverride = ply:LookupSequence("prowl")
			else
				if not pac then
					ply.CalcIdeal = ACT_HL2MP_RUN
					ply.CalcSeqOverride = ply:LookupSequence("chase2")
				else
					ply.CalcIdeal = ACT_HL2MP_WALK
					ply.CalcSeqOverride = ply:LookupSequence("prowl")
				end
			end
		else
			ply.CalcIdeal = ACT_HL2MP_RUN
			ply.CalcSeqOverride = ply:LookupSequence("chase")
		end
	else
		ply.CalcSeqOverride = ply:LookupSequence("float")
	end

	if ply:GetNWBool("ThirstyDrinking") then
		ply.CalcSeqOverride = ply:LookupSequence("drink")

		if ply.anim_antispam == nil or ply.anim_antispam == false then
			ply:SetCycle(0)
			ply.anim_antispam = true
		end
	end

	return ply.CalcIdeal, ply.CalcSeqOverride
end

SLASHER.Footstep = function()
	return true
end

local milkTable = {
	default = Material("slashco/ui/icons/slasher/s_5"),
	["d/"] = Material("slashco/ui/icons/slasher/kill_disabled")
}

local gray = Color(128, 128, 128)
SLASHER.InitHud = function(_, hud)
	hud:SetAvatar(Material("slashco/ui/icons/slasher/s_5"))
	hud:SetTitle("Thirsty")

	hud:AddControl("R", "drink milk", milkTable)
	hud:ChaseAndKill()

	hud:AddMeter("milkies", 4 + GetGlobalInt("SatO"), "", nil, true)
	hud:TieMeterInt("milkies", "ThirstyMilkDrank", true)

	hud:AddMeter("thirst")
	hud:TieMeterInt("thirst", "ThirstyThirst")
	hud:SetMeterColors("thirst", gray, color_white)

	hud:SetCrosshairEnabled(true)
	hud:TieCrosshairEntity("sc_milkjug", 150, "R", {InvertOutput = false, "ThirstyDrinking"}, {
		SpinOn = 50,
		TightenOn = 4,
		ProngsOn = 4,
		AlphaOn = 255,
		SpinOff = 0,
		TightenOff = 0,
		ProngsOff = 3,
		AlphaOff = 0
	})
end

SLASHER.PreDrawHalos = function()
	SlashCo.DrawHalo(ents.FindByClass("sc_milkjug"), "gray", 2, false)

	local plyWithItem = {}
	for _, v in ipairs(team.GetPlayers(TEAM_SURVIVOR)) do
		if v:HasItem("MilkJug") then
			table.insert(plyWithItem, v)
		end
	end

	SlashCo.DrawHalo(plyWithItem, "gray", 2, false)
end

SLASHER.ThirstyRage = function(ply)
	local pos = ply:GetPos()

	for _, slasher in ipairs(team.GetPlayers(TEAM_SLASHER)) do
		if SlashCoSlashers[slasher:GetNWString("Slasher")].SlasherID ~= 5 then
			return
		end

		if slasher:GetPos():Distance(pos) > 1600 then
			return
		end

		slasher.SlasherValue1 = 6
		slasher:SetNWBool("ThirstyBigMlik", true)

		for _, ply1 in ipairs(player.GetAll()) do
			ply1:SetNWBool("ThirstyFuck", true)
		end

		timer.Simple(3, function()
			for _, ply1 in ipairs(player.GetAll()) do
				ply1:SetNWBool("ThirstyFuck", false)
			end
		end)
	end
end

if CLIENT then
	hook.Add("HUDPaint", SLASHER.Name .. "_Jumpscare", function()
		if LocalPlayer():GetNWBool("SurvivorJumpscare_Thirsty") == true then
			if LocalPlayer().thrs_f == nil then
				LocalPlayer().thrs_f = 0
			end
			LocalPlayer().thrs_f = LocalPlayer().thrs_f + (FrameTime() * 20)
			if LocalPlayer().thrs_f > 29 then
				LocalPlayer().thrs_f = 25
			end

			local Overlay = Material("slashco/ui/overlays/jumpscare_5")
			Overlay:SetInt("$frame", math.floor(LocalPlayer().thrs_f))

			surface.SetDrawColor(255, 255, 255, 255)
			surface.SetMaterial(Overlay)
			surface.DrawTexturedRect(0, 0, ScrW(), ScrH())
		else
			LocalPlayer().thrs_f = nil
		end

		if LocalPlayer():GetNWBool("ThirstyFuck") == true then
			local Overlay = Material("slashco/ui/overlays/thirsty_fuck")

			surface.SetDrawColor(255, 255, 255, 60)
			surface.SetMaterial(Overlay)
			surface.DrawTexturedRect(0, 0, ScrW(), ScrH())

			if g_thirstySound == nil then
				surface.PlaySound("slashco/slasher/thirsty_rage1.mp3")
				surface.PlaySound("slashco/slasher/thirsty_rage2.mp3")
				g_thirstySound = true
			end
		end
	end)
end

SlashCo.RegisterSlasher(SLASHER, "Thirsty")