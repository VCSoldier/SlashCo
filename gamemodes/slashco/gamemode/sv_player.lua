--local SlashCo = SlashCo

function GM:PlayerSwitchWeapon()
	return false
end

function GM:PlayerInitialSpawn(ply)
	if game.GetMap() == "sc_lobby" then
		ply:SetTeam(TEAM_SPECTATOR)
		ply:Spawn()
	end
end

function GM:PlayerSpawn(ply, transition)
	if not IsValid(ply) then
		return
	end

	ply:StopAllGlobalSounds()
	ply:CrosshairDisable()

	if self.TeamBased then
		local tm = ply:Team()

		if tm == TEAM_SPECTATOR or tm == TEAM_UNASSIGNED then
			self:PlayerSpawnAsSpectator(ply)
			return
		end

		if tm == TEAM_SURVIVOR then
			player_manager.SetPlayerClass(ply, "player_survivor")
		elseif tm == TEAM_SLASHER then
			player_manager.SetPlayerClass(ply, "player_slasher_base")
		elseif tm == TEAM_LOBBY then
			player_manager.SetPlayerClass(ply, "player_lobby")
		end
	end

	-- Stop observer mode
	ply:UnSpectate()
	ply:SetupHands()

	player_manager.OnPlayerSpawn(ply, transition)
	player_manager.RunClass(ply, "Spawn")

	-- If we are in transition, do not touch player's weapons
	if not transition then
		-- Call item loadout function
		hook.Call("PlayerLoadout", GAMEMODE, ply)
	end

	-- Set player model
	hook.Call("PlayerSetModel", GAMEMODE, ply)
end

function GM:PlayerDeathThink(ply)
	if ply:Team() == TEAM_SPECTATOR then
		local pos = ply:EyePos()
		local eyeang = ply:EyeAngles()

		ply:Spawn()
		ply:SetPos(pos)
		ply:SetEyeAngles(eyeang)

		return true
	end

	ply:Spawn()
	return true
end

function GM:CanPlayerSuicide(player)
	if player:Team() == TEAM_SPECTATOR or player:Team() == TEAM_SLASHER then
		return false
	end

	return true
end

--Proximity voice chat

hook.Add("PlayerCanHearPlayersVoice", "Maximum Range", function(listener, talker)
	if talker:Team() == TEAM_SPECTATOR or talker:Team() == TEAM_SLASHER then
		return false
	end
	if listener:GetPos():DistToSqr(talker:GetPos()) > 1000000 then
		return false
	end
end)

hook.Add("GetFallDamage", "RealisticDamage", function(_, speed)
	return speed / 16
end)

hook.Add("PlayerCanSeePlayersChat", "TeamChat", function(_, _, listener, speaker)
	if listener:Team() == TEAM_SPECTATOR then
		return true
	end
	if speaker:Team() == TEAM_SLASHER then
		return false
	end
	if listener:Team() == TEAM_SLASHER then
		return false
	end
	if speaker:Team() == TEAM_SPECTATOR and listener:Team() ~= TEAM_SPECTATOR then
		return false
	end

	if listener:GetPos():DistToSqr(speaker:GetPos()) > 1000000 then
		return false
	else
		if speaker:Team() == TEAM_SURVIVOR then
			return true
		end
	end
end)

hook.Add("ShowTeam", "DoNotAllowTeamSwitch", function()
	return false
end)

hook.Add("PlayerUse", "STOP", function(ply, _)
	if ply:Team() == TEAM_SPECTATOR then
		return false
	else
		return
	end
end)

local PLAYER = FindMetaTable("Player")

function PLAYER:SetImpervious(state)
	if state then
		if self.IsImpervious then
			return
		end

		self:SetCustomCollisionCheck(true)
		self.IsImpervious = true

		local userid = self:UserID()
		hook.Add("ShouldCollide", "SlashCoImpervious_" .. userid, function(ent1, ent2)
			if not IsValid(self) then
				hook.Remove("ShouldCollide", "SlashCoImpervious_" .. userid)
				return
			end

			local object
			if ent1 == self then
				object = ent2
			end
			if ent2 == self then
				object = ent1
			end

			if not IsValid(object) then
				return
			end
			if object:IsPlayer() or object:GetClass() == "prop_door_rotating" then
				--i would put a check for if doors were locked here but the locked state of doors could change
				--see the warning in https://wiki.facepunch.com/gmod/GM:ShouldCollide to see why this matters
				return false
			end
		end)
	else
		if not self.IsImpervious then
			return
		end

		self:SetCustomCollisionCheck(false)
		self.IsImpervious = nil
		hook.Remove("ShouldCollide", "SlashCoImpervious_" .. self:UserID())
	end
end

hook.Add("PlayerDeath", "slashCoRemoveImpervious", function(victim)
	victim:SetImpervious(false)
end)
