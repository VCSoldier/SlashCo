local SlashCo = SlashCo
local SlashCoItems = SlashCoItems

SlashCo.UseItem = function(ply)
	if CLIENT then
		return
	end

	if game.GetMap() == "sc_lobby" then
		return
	end

	if ply:Team() ~= TEAM_SURVIVOR then
		return
	end

	if ply:IsFrozen() then
		return
	end

	local item = ply:GetItem("item2")
	if item == "none" then
		item = ply:GetItem("item")
	end

	if SlashCoItems[item] and SlashCoItems[item].OnUse then
		local doNotRemove = SlashCoItems[item].OnUse(ply)
		if not doNotRemove then
			SlashCo.ChangeSurvivorItem(ply, "none")
		end
	end
end

SlashCo.DropAllItems = function(ply, noEffect)
	if not noEffect then
		ply:ClearEffect()
	end

	SlashCo.DropItem(ply)
	SlashCo.DropItem(ply)
end

SlashCo.DropItem = function(ply)
	if CLIENT then
		return
	end

	if game.GetMap() == "sc_lobby" then
		return
	end

	if ply:Team() ~= TEAM_SURVIVOR then
		return
	end

	if ply:IsFrozen() then
		return
	end

	local item = ply:GetItem("item2")
	if item == "none" then
		item = ply:GetItem("item")
	end

	if not SlashCoItems[item] then
		SlashCo.SendValue(ply, "preItem")
		return
	end

	local dontDrop = ply:ItemFunction2("PreDrop", item)
	if dontDrop then
		return
	end

	local slot = "item"
	local time = 0.18
	if SlashCoItems[item].IsSecondary then
		local dontDrop1 = ply:ItemFunction("PreDropSecondary", item)
		if dontDrop1 then
			return
		end

		ply:ViewPunch(Angle(-6, 0, 0))
		ply:SetItem("item2", "none")
		time = 0.25
		slot = "item2"
	else
		ply:ViewPunch(Angle(-2, 0, 0))
		ply:SetItem("item", "none")
	end

	timer.Create(string.format("SlashCoItemSwitch_%s_%s", slot, ply:UserID()), time, 1, function()
		if not IsValid(ply) then
			return
		end

		local height, dontDrop1, dontPush = ply:ItemFunction2("OnDrop", item)
		if dontDrop1 then
			return
		end

		ply:ItemFunction2("OnSwitchFrom", item)

		local droppeditem = SlashCo.CreateItem(SlashCoItems[item].EntClass,
				ply:LocalToWorld(Vector(0, 0, height or 60)),
				ply:LocalToWorldAngles(Angle(0, 0, 0)))
		local phys = droppeditem:GetPhysicsObject()

		if not dontPush and IsValid(phys) then
			phys:SetVelocity(ply:GetAimVector() * 250)
			local randomvec = Vector(0, 0, 0)
			randomvec:Random(-1000, 1000)
			phys:SetAngleVelocity(randomvec)
		end

		ply:ItemFunction2("ItemDropped", item, droppeditem, phys)

		if not SlashCoItems[item].IsSecondary then
			SlashCo.CurRound.Items[droppeditem:EntIndex()] = true
		end
	end)

	ply.LastDroppedItemTime = CurTime()
end

SlashCo.RemoveItem = function(ply, isSec)
	local slot = isSec and "item2" or "item"
	local item = ply:GetItem(slot)
	timer.Create(string.format("SlashCoItemSwitch_%s_%s", slot, ply:UserID()), isSec and 0.25 or 0.18, 1, function()
		if IsValid(ply) then
			ply:ItemFunction2("OnSwitchFrom", item)
		end
	end)
	ply:SetItem(slot, "none")
end

SlashCo.ChangeSurvivorItem = function(ply, id)
	if SlashCoItems[id] then
		if SlashCoItems[id].OnPickUp then
			SlashCoItems[id].OnPickUp(ply)
		end

		if SlashCoItems[id].IsSecondary then
			local item = ply:GetItem("item2")
			ply:ItemFunction2("OnSwitchFrom", item)
			ply:SetItem("item2", id)
		else
			local item = ply:GetItem("item")
			ply:ItemFunction2("OnSwitchFrom", item)
			ply:SetItem("item", id)
		end

		if SlashCoItems[id].EquipSound then
			ply:EmitSound(SlashCoItems[id].EquipSound())
		else
			ply:EmitSound("slashco/survivor/item_equip" .. math.random(1, 2) .. ".mp3")
		end
	elseif id == "none" then
		ply:SetItem("item", "none")
	end
end

SlashCo.ItemPickUp = function(ply, itemindex, item)
	if SlashCoItems[item].IsSecondary and ply:GetItem("item2") ~= "none"
			or not SlashCoItems[item].IsSecondary and ply:GetItem("item") ~= "none" then
		return
	end

	if ply.LastDroppedItemTime and CurTime() - ply.LastDroppedItemTime < 1 then
		return
	end

	local slot = SlashCoItems[item].IsSecondary and "item2" or "item"
	if timer.Exists(string.format("SlashCoItemSwitch_%s_%s", slot, ply:UserID())) then
		return
	end

	local dontPickupHook = hook.Run("SlashCoItemPickUp", ply, item, itemindex)
	if dontPickupHook then
		return
	end

	local dontPickup = ply:ItemFunction2("PrePickUp", item, itemindex)
	if dontPickup then
		return
	end

	if slot == "item" then
		local dontPickup1 = ply:SecondaryItemFunction("PrePickUpPrimary", item, itemindex)
		if dontPickup1 then
			return
		end
	else
		local dontPickup2 = ply:ItemFunction("PrePickUpSecondary", item, itemindex)
		if dontPickup2 then
			return
		end
	end

	local itemEnt = Entity(itemindex)

	if IsValid(itemEnt.SpawnedAt) then
		itemEnt.SpawnedAt:TriggerOutput("OnPickedUp", ply)
		itemEnt.SpawnedAt.SpawnedEntity = nil
	end

	SlashCo.ChangeSurvivorItem(ply, item)
	itemEnt:Remove()

	return true
end