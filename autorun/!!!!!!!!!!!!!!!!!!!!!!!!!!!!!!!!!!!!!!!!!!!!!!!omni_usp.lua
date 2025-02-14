if SERVER then
    AddCSLuaFile("weapons/omni_usp.lua")
end

local ent = FindMetaTable("Entity")
local ply = FindMetaTable("Player")

local Add = hook.Add
local Call = hook.Call

local IsValid = ent.IsValid
local Input = ent.Input
local Remove = ent.Remove
local NextThink = ent.NextThink

if SERVER then Msg("[Omniversal USP] - Initializing file...\n") end

function LoadOmniUSPHooks()
    if SERVER then
        Add(
            "PlayerShouldTakeDamage",
            "BlockDamage_0001",
            function(ply, attacker)
                if IsValid(ply:GetActiveWeapon()) and ply:GetActiveWeapon():GetClass() == "omni_usp" then
                    return false
                end
                return true
            end
        )
        Add(
            "EntityTakeDamage",
            "BlockDamage2_0002",
            function(target, dmginfo)
                if target:IsPlayer() then
                    local activeWeapon = target:GetActiveWeapon()
                    if IsValid(activeWeapon) and activeWeapon:GetClass() == "omni_usp" then
                        return false
                    end
                end
            end
        )
        Add(
            "GetFallDamage",
            "BlockFallDamage_0002",
            function(ply, speed)
                if IsValid(ply:GetActiveWeapon()) and ply:GetActiveWeapon():GetClass() == "omni_usp" then
                    return false
                end
            end
        )
        Add(
            "CanPlayerSuicide",
            "BlockSuicide_0003",
            function(TwentyFive)
                if IsValid(ply:GetActiveWeapon()) and ply:GetActiveWeapon():GetClass() == "omni_usp" then
                    print("CPS Working.")
                    return false
                end
            end
        )
        Add(
            "PlayerDeathThink",
            "BlockDeath_0004",
            function(TwentyFive)
                if IsValid(ply:GetActiveWeapon()) and ply:GetActiveWeapon():GetClass() == "omni_usp" then
                    print("PDT Working.")
                end
            end
        )
        Add(
            "PlayerSwitchWeapon",
            "BlockWeaponSwitch_0005",
            function(ply, oldWep, newWep)
                if not IsValid(ply) or not IsValid(oldWep) or not IsValid(newWep) then
                    return
                end
                if ply:GetActiveWeapon():GetClass() == "omni_usp" then
                    if ply:GetNWBool("IsSpawnMenuOpen", false) then
                        return true
                    end
                end
            end
        )
        util.AddNetworkString("SetSpawnMenuOpen")
        net.Receive(
            "SetSpawnMenuOpen",
            function(len, ply)
                local isOpen = net.ReadBool()
                ply:SetNWBool("IsSpawnMenuOpen", isOpen)
            end
        )
    else
        Add(
            "Think",
            "DetectSpawnMenu",
            function()
                local isOpen = g_SpawnMenu and g_SpawnMenu:IsVisible()
                net.Start("SetSpawnMenuOpen")
                net.WriteBool(isOpen)
                net.SendToServer()
            end
        )
    end
end


function HKill(ent)
	if IsValid(ent) and ent:IsNPC() or ent:IsNextBot() and SERVER then
		ent.AcceptInput = function() return false end
	    ent.OnRemove = function(self,...) self:Remove() return end
	    ent.CustomThink = function(self,...) self:Remove() return end
	    ent.Think = function(self,...) self:Remove() return end
		
		ent:SetNoDraw(true)
	    ent:Fire("Kill")
		ent:Fire("SelfDestruct")
		ent:SetHealth(-2147483648)
		ent:AddFlags(134217728)
		Input(ent, "Kill")
		Remove(ent)
		NextThink(ent, CurTime() + 1e9 )
	end
	ent = nil
end

if SERVER then Msg("[Omniversal USP] - Hook overrides run successfully.\n") end