local SlashCoItems = SlashCoItems

SlashCoItems.DeathWard = {}
SlashCoItems.DeathWard.Model = "models/slashco/items/deathward.mdl"
SlashCoItems.DeathWard.Name = "Death Ward"
SlashCoItems.DeathWard.Icon = "slashco/ui/icons/items/item_2"
SlashCoItems.DeathWard.Price = 50
SlashCoItems.DeathWard.Description = "A ceramic, skull-shaped charm. Will save you from certain death,\nbut only once. Your team can only have a limited amount of them.\nThis item will take up your Item Slot, even if spent."
SlashCoItems.DeathWard.CamPos = Vector(40,0,15)
SlashCoItems.DeathWard.MaxAllowed = function()
    return 2
end
SlashCoItems.DeathWard.OnDie = function(ply)
    ply:EmitSound( "slashco/survivor/deathward.mp3")
    ply:EmitSound( "slashco/survivor/deathward_break"..math.random(1,2)..".mp3")

    SlashCo.RespawnPlayer(ply)

    SlashCo.ChangeSurvivorItem(pid, "DeathWardUsed")

    return true
end