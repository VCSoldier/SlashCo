ENT.Type = "point"

function ENT:Initialize()
	--override me!
end

function ENT:ExtraKeyValue()
	--override me!
end

function ENT:ExtraAcceptInput()
	--override me!
end

function ENT:KeyValue(key, value)
	if string.sub(key, 1, 2) == "On" then
		self:StoreOutput(key, value)
		return
	end
	local key1 = string.lower(key)
	if key1 == "disabled" then
		self.Disabled = tonumber(value) == 1
		return
	end
	if key1 == "active" then
		self.Disabled = tonumber(value) == 0
		return
	end
	if key1 == "weight" then
		self.Weight = tonumber(value)
		return
	end
	if key1 == "delete" then
		self.DeleteOnSpawn = tonumber(value) == 1
		return
	end

	self:ExtraKeyValue(key, value)
end

function ENT:AcceptInput(name, activator)
	if string.sub(name, 1, 2) == "On" then
		self:TriggerOutput(name, activator)
		return true
	end
	local name1 = string.lower(name)
	if name1 == "enable" then
		self.Disabled = false
		return true
	end
	if name1 == "disable" then
		self.Disabled = true
		return true
	end
	if name1 == "toggle" then
		self.Disabled = not self.Disabled
		return true
	end

	self:ExtraAcceptInput(name, activator)
end

function ENT:OnSpawn()
	--override me!
end

function ENT:SpawnEnt()
	local ent = self:OnSpawn()
	self.SpawnedEntity = ent or self.SpawnedEntity
	self:TriggerOutput("OnSpawn", self.SpawnedEntity)
	if self.DeleteOnSpawn then
		self:Remove()
	elseif IsValid(self.SpawnedEntity) then
		self.SpawnedEntity.SpawnedAt = self
	end
end