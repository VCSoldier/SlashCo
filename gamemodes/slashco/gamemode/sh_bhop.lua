local max = CreateConVar("slashco_max_bhop_speed", 1, FCVAR_REPLICATED, "Max bhop speed, multiple of max run speed", -9999, 9999)

local function limitSpeed(ply, data)
	if not ply:IsOnGround() or not ply:KeyPressed(IN_JUMP) then
		return
	end

	local baseSpeed = ply:GetRunSpeed()
	local curSpeed = data:GetVelocity():Length()

	if curSpeed > baseSpeed * max:GetFloat() then
		data:SetVelocity((data:GetVelocity() * baseSpeed * max:GetFloat()) / curSpeed)
	end
end

if SERVER then
	hook.Add("SetupMove", "RestrictBhopping", limitSpeed)
else
	hook.Add("Move", "RestrictBhopping", limitSpeed)
end