include('shared.lua')
include('slashco/gamemode/items/items_init.lua')

function SWEP:Initialize()

    self.heldEntity = ClientsideModel("models/props_junk/metalgascan.mdl", RENDER_GROUP_VIEW_MODEL_OPAQUE)
    if (IsValid(self.heldEntity)) then
        self.heldEntity:SetPos(self:GetPos())
        self.heldEntity:SetAngles(self:GetAngles())
        self.heldEntity:SetParent(self)
        self.heldEntity:SetNoDraw(true)
        self.heldEntity:ResetSequence( 0 )
    end

    self.heldEntityWorld = ClientsideModel("models/props_junk/metalgascan.mdl", RENDER_GROUP_VIEW_MODEL_OPAQUE)
    if (IsValid(self.heldEntityWorld)) then
        self.heldEntityWorld:SetPos(self:GetPos())
        self.heldEntityWorld:SetAngles(self:GetAngles())
        self.heldEntityWorld:SetParent(self)
        self.heldEntityWorld:SetNoDraw(true)
        self.heldEntityWorld:ResetSequence( 0 )
    end

    self.heldEntityHolstered = ClientsideModel("models/props_junk/metalgascan.mdl", RENDER_GROUP_VIEW_MODEL_OPAQUE)
    if (IsValid(self.heldEntityHolstered)) then
        self.heldEntityHolstered:SetPos(self:GetPos())
        self.heldEntityHolstered:SetAngles(self:GetAngles())
        self.heldEntityHolstered:SetParent(self)
        self.heldEntityHolstered:SetNoDraw(true)
        self.heldEntityHolstered:ResetSequence( 0 )
    end
end

function SWEP:RenderModel(v, model, owner, flipVM, xPos)
    if IsValid(model) then
        local bone = owner:LookupBone(v.bone)
        if not bone then return end
        local m = owner:GetBoneMatrix(bone)
        local pos, ang = Vector(0,0,0), Angle(0,0,0)
        if m then
            pos, ang = m:GetTranslation(), m:GetAngles()
        end

        if flipVM and self.ViewModelFlip then
            ang.r = -ang.r -- Fixes mirrored models
        end

        model:SetModel(v.model)
        model:SetPos(pos + ang:Forward() * (xPos or v.pos.x) + ang:Right() * v.pos.y + ang:Up() * v.pos.z)
        ang:RotateAroundAxis(ang:Up(), v.angle.y)
        ang:RotateAroundAxis(ang:Right(), v.angle.p)
        ang:RotateAroundAxis(ang:Forward(), v.angle.r)

        model:SetAngles(ang)
        local matrix = Matrix()
        matrix:Scale(v.size)
        model:EnableMatrix("RenderMultiply", matrix)

        if (v.material == "") then
            model:SetMaterial("")
        elseif (model:GetMaterial() ~= v.material) then
            model:SetMaterial(v.material)
        end

        if (v.skin and v.skin ~= model:GetSkin()) then
            model:SetSkin(v.skin)
        end

        if (v.bodygroup) then
            for k, v1 in pairs(v.bodygroup) do
                if (model:GetBodygroup(k) ~= v1) then
                    model:SetBodygroup(k, v1)
                end
            end
        end

        if (v.surpresslightning) then
            render.SuppressEngineLighting(true)
        end

        render.SetColorModulation(v.color.r / 255, v.color.g / 255, v.color.b / 255)
        render.SetBlend(v.color.a / 255)
        model:DrawModel()
        render.SetBlend(1)
        render.SetColorModulation(1, 1, 1)

        if (v.surpresslightning) then
            render.SuppressEngineLighting(false)
        end
    else
        self:Initialize()
    end
end

function SWEP:ViewModelDrawn()
    if not IsValid(self.Owner) then
        return
    end

    local vm = self.Owner:GetViewModel()
    if not IsValid(vm) then
        return
    end

    local item = self.Owner:GetNWString("item2", "none")
    if item == "none" then
        item = self.Owner:GetNWString("item", "none")
    end

    local v
    if SlashCoItems[item] and SlashCoItems[item].ViewModel then
        v = SlashCoItems[item].ViewModel
    end
    --PrintTable(v or {"none"})

    if not v then
        self.xPos = Lerp(0.06,self.xPos or 55,55)

        if (self.xPos-55) <= 1 then
            self.lastEquip = nil
        end
    elseif not self.lastEquip or self.lastEquip ~= v then
        self.xPos = Lerp(0.06,self.xPos or v.pos.x,55)

        if (self.xPos-55) <= 1 then
            self.lastEquip = v
        end
    else
        self.xPos = Lerp(0.06,self.xPos or 55,v.pos.x)
    end

    --PrintTable(self.lastEquip)

    if not v and not self.lastEquip then return end
    v = self.lastEquip or v

    v.bone = "ValveBiped.Bip01_Spine4"
    self:RenderModel(v, self.heldEntity, vm, true, self.xPos)
    self.Owner:ItemFunction2("OnRenderHand", item, self.heldEntity)
end

function SWEP:DrawWorldModel()

    if not IsValid(self.Owner) then
        return
    end

    local item = self.Owner:GetNWString("item2", "none")
    local itemH
    if item == "none" then
        item = self.Owner:GetNWString("item", "none")
    else
        itemH = self.Owner:GetNWString("item", "none")
    end

    local v
    if SlashCoItems[item] and SlashCoItems[item].WorldModel then
        v = SlashCoItems[item].WorldModel
    end
    if not v then
        self.heldEntityWorld:SetNoDraw(true)
        self:SetHoldType("normal")
        return
    end

    self:SetHoldType(v.holdtype)

    self:RenderModel(v, self.heldEntityWorld, self.Owner)
    self.Owner:ItemFunction2("OnRenderWorld", item, self.heldEntityWorld)

    if itemH and SlashCoItems[itemH] and SlashCoItems[itemH].WorldModelHolstered then
        self:RenderModel(SlashCoItems[itemH].WorldModelHolstered, self.heldEntityHolstered, self.Owner)
        self.Owner:ItemFunction2("OnRenderHolstered", item, self.heldEntityHolstered)
    else
        self.heldEntityHolstered:SetNoDraw(true)
    end
end