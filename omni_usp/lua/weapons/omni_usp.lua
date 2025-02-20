local e = FindMetaTable("Entity")

local Remove = e.Remove
local GetClass = e.GetClass
local NextThink = e.NextThink
local Input = e.Input
local IsValid = e.IsValid

local Add = hook.Add
local Call = hook.Call
local mr = math.random

local invulnerableList = {}

SWEP.Author = "1999"
SWEP.Category = "1999's Weapons (Admin)"
SWEP.PrintName = "Omniversal USP"
SWEP.Purpose = "Kill."

SWEP.DrawCrosshair = true

SWEP.Spawnable = true
SWEP.AdminSpawnable = true
SWEP.AdminOnly = true

SWEP.UseHands = true

SWEP.ViewModelFOV = 54
SWEP.ViewModel			= "models/weapons/c_pistol.mdl"
SWEP.WorldModel			= "models/weapons/w_pistol.mdl"

SWEP.Secondary.Automatic	= true
SWEP.Secondary.Ammo		= ""

SWEP.Slot = 1
SWEP.SlotPos = 1

local ShootSound = Sound("Weapon_Pistol.Single")

SWEP.Primary.DefaultClip = 256
SWEP.Primary.ClipSize = 18
SWEP.Primary.Automatic = true
SWEP.Primary.Ammo = "pistol"

Add("EntityTakeDamage", "inv_control", function(ent)
	if invulnerableList[ent] then return true end
end)

local function OwnerKillFeed(ent,self)				
    net.Start('PlayerKilledNPC')
    net.WriteString(ent:GetClass())
    net.WriteString('omniversal_revolver')
    net.WriteEntity(self.Owner)
    net.Broadcast()	
end

local function CrazyRag(ent)
    if SERVER then
    local rd = ents.Create("prop_ragdoll")
    rd:SetPos(ent:GetPos())
    rd:SetAngles(ent:GetAngles())
    rd:SetModel(ent:GetModel())
    rd:Spawn()
    rd.OwnerINT = ent:EntIndex()
    rd.PhysgunPickup = true
    rd.CanTool = true
    rd:SetUseType(SIMPLE_USE)
	rd:EmitSound("ambient/atmosphere/cave_hit"..mr(1,6)..".wav", 100, 100, 0.75, CHAN_VOICE_BASE)
	rd:EmitSound("ambient/levels/citadel/field_loop"..mr(1,3)..".wav", mr(75,80,85), 100, 1, CHAN_VOICE_BASE)
	timer.Simple( mr(7, 9, 10), function()
	    if rd and IsValid(rd) then
		    rd:Dissolve(1)
			rd:EmitSound("ambient/energy/weld1.wav")
			rd:StopSound("ambient/levels/citadel/field_loop1.wav")
			rd:StopSound("ambient/levels/citadel/field_loop2.wav")
			rd:StopSound("ambient/levels/citadel/field_loop3.wav")
		end
	end)
    timer.Create( tostring(e), 0.05, 10 * 25, function()
             if rd:IsValid() then
                 for i = 1, rd:GetPhysicsObjectCount() - 1 do
                     local phys = rd:GetPhysicsObjectNum(i)
                     if phys:IsValid() then
                         local randomVelocity = Vector(mr(-10, 10), mr(-10, 10), mr(-1, 1)) * mr(100, 500)
                         phys:SetVelocity(randomVelocity)
                     end
                 end
             end
        end)
    end
end
-----------------------------------------------------------------------------
-- Taken from the Long Devplat Revolver
local function ClassName(ent)
	if not IsValid(ent) then return end
	local class = tostring(ent)
	class = string.TrimLeft(class, type(ent))
	class = string.TrimLeft(class, " [" .. ent:EntIndex() .. "]")
	class = string.TrimLeft(class, "[")
	class = string.TrimRight(class, "]")
	return class
end

local function AddUndoEntity(ply, self, msg, func, ...)
	undo.Create(msg)
    undo.AddEntity(self)
    undo.SetPlayer(ply)
	if func then
		undo.AddFunction(func, ...)
	end
  	undo.Finish() 
  	gamemode.Call("PlayerSpawnedSENT", ply, self)
  	ply:AddCount("sents", self) 
  	ply:AddCleanup("sents", self) 
end

local function grm(ent)
	if !SERVER then return '' end

	return ent:GetInternalVariable('model')
end

local function rnn()
	local rname = ''
	for i = 1, 15 do
		rname = rname..string.char(mr(32,164))
	end

	return rname
end

local function CreateEntityRagdoll(ent, ply, skin, self)

    if !IsValid(ent) then return end
    
	local force = self.Owner:GetAimVector()*22^14
	local vf = self.Owner:GetAimVector()*22^14
	local model = grm(ent)
	local clr = Color(ent:GetColor().r, ent:GetColor().g, ent:GetColor().b)
    if SERVER and (model and util.IsValidRagdoll(model)) then
        local ragdoll = ents.Create("prop_ragdoll")
        ragdoll:SetModel(model)
        ragdoll:SetSkin(skin or 0)
        ragdoll:SetPos(ent:GetPos())
        ragdoll:SetAngles(Angle(ent:GetAngles(),ent:GetAngles().Yaw,ent:GetAngles()))
		ragdoll:SetColor(clr)
		ragdoll:SetMaterial(ent:GetMaterial())
        ragdoll:Spawn()
		
		if IsValid(ply) then
			AddUndoEntity(ply, ragdoll, ClassName(ent))
		end
    
        for i = 0, ragdoll:GetPhysicsObjectCount()-1 do
            local bone = ragdoll:GetPhysicsObjectNum(i)
            local pos, ang = ent:GetBonePosition(ragdoll:TranslatePhysBoneToBone(i))
            if bone and pos and ang then
                bone:SetAngles(ang)
                bone:SetPos(pos)
            end

			if force then
				bone:SetVelocity(vf)
			end
        end
		ent.CorpseRag = true
    end
end

local function GoodEnemyPosition1(v)
	return v:LocalToWorld(v:OBBCenter()) or v:GetAttachment(v:LookupAttachment("eyes")).Pos
end

local function Morph(ent)
	for i = 0, ent:GetBoneCount() do
		local r = mr
		ent:ManipulateBoneScale(i, Vector( r(1,5), r(1,5), r(1,5) ))
		ent:ManipulateBonePosition(i, Vector( r(1,5), r(1,10), r(1,15) ))
		ent:ManipulateBoneAngles(i, Angle( r(1,50), r(1,50), r(1,50) ))
	end
end

local function GetNPCNextBotTable1()
	local t = {}
	for k,v in pairs(ents.GetAll()) do
		if v:IsNextBot() or v:IsNPC() then
			table.insert(t, v)
		end
	end
	return t
end

local function DoEntsExist()
	for k,v in pairs(ents.GetAll()) do
		if v:IsNPC() or v:IsNextBot() then
			return true
		end
	end
	return false
end

local function FilterEntities(ent)
	local t = {}
	for k,v in pairs(ents.GetAll()) do
		if v != ent then
			table.insert(t, v)
		end
	end
	return t
end
-----------------------------------------------------------------------------
-----------------------------------------------------------------------------
local function Attack(v, self)
    local ply = self:GetOwner()
    local hitpos = ents.FindAlongRay(ply:GetShootPos(), ply:GetEyeTrace().HitPos, Vector(-15, -15, -15), Vector(15, 15, 15))

    for k, v in pairs(hitpos) do
        if v ~= self.Owner then
            if (v:IsPlayer() and v:Alive()) then
                v:Kill()
            end

            if v:IsVehicle() then
                v:Remove()
            end

            if v:GetClass() == "bullseye_strider_focus" then
                return false
            end

            if v:IsNPC() or v:IsNextBot() and v:IsValid() then
                CreateEntityRagdoll(v, ply, skin, self)				
				HKill(v)
				
                v.AcceptInput = function() return false end
				v.BehaveStart = function() return end
				v.Initialize = function(self,...) self:Remove() return end
				v.RunBehaviour = function(self,...) self:Remove() return end
	            v.OnRemove = function(self,...) self:Remove() return end
	            v.CustomThink = function(self,...) self:Remove() return end
	            v.Think = function(self,...) self:Remove() return end
				
                NextThink(v, CurTime() + 3)
                Input(v, "Kill")
				v:Fire("Kill")
				v:SetNoDraw(false)
				v:SetHealth(0)
                Remove(v)
                OwnerKillFeed(v, self)				
            end
        end
    end
end

local function SilentKill(v, self)

    local hitpos = ents.FindAlongRay(self.Owner:GetShootPos(), self.Owner:GetEyeTrace().HitPos, Vector(-15, -15, -15), Vector(15, 15, 15))

    for k, v in pairs(hitpos) do
        if v ~= self.Owner then
            if (v:IsPlayer() and v:Alive()) then
                v:Kill()
            end

            if v:IsNPC() or v:IsNextBot() and v:IsValid() then
                v.AcceptInput = function() return false end
	            v.OnRemove = function(self,...) self:Remove() return end
	            v.CustomThink = function(self,...) self:Remove() return end
	            v.Think = function(self,...) self:Remove() return end
				
                NextThink(v, CurTime() + 3)
                Input(v, "Kill")
				
				local rnname = rnn()
			    v:SetSaveValue('m_iName',rnname)
			    RunConsoleCommand('ent_remove_all',rnname)
				
				self.Weapon:EmitSound("common/warning.wav",75,100,CHAN_WEAPON)
				self:ShootEffects()
				self:SetNextSecondaryFire(CurTime() + 0.05)
            end
        end
    end
end

local function DealDamage(v,self)

    local dforce = self.Owner:GetAimVector()*1e9
    local hitpos = ents.FindAlongRay(self.Owner:GetShootPos(), self.Owner:GetEyeTrace().HitPos, Vector(-15, -15, -15), Vector(15, 15, 15))

    for k, v in pairs(hitpos) do
        if v ~= self.Owner then
            if (v:IsPlayer() and v:Alive() and v:HasGodMode()) then
                v:Kill()
            end

            if v:IsNPC() or v:IsNextBot() and v:IsValid() then
			
                v.AcceptInput = function() return false end
	            v.OnRemove = function(self,...) self:Remove() OwnerKillFeed(v,self) return end
	            v.CustomThink = function(self,...) self:Remove() OwnerKillFeed(v,self) return end
	            v.Think = function(self,...) self:Remove() OwnerKillFeed(v,self) return end
				
				local d = DamageInfo()
				d:SetDamage(1e9)
				d:SetDamageForce(dforce)
				d:SetAttacker(self.Owner)
                d:SetInflictor(self.Owner)
				v:TakeDamageInfo(d)
				
				v:TakeDamage(1e9,self.Owner,self.Owner)
				v:SetHealth(0)
				
				if v:GetClass()=="npc_rollermine" or v:GetClass()=="npc_combinedropship" or v:GetClass()=="npc_combinegunship" then
				   Remove(v)
				   OwnerKillFeed(v,self)
				end
				
				self:EmitSound(ShootSound)
				self:ShootEffects()
				self:SetNextSecondaryFire(CurTime() + 0.1)
            end
        end
    end
end

local function DealDamageEnhanced(v,self)
    
	local ply = self:GetOwner()
	
	local dforce = ply:GetAimVector()*1e9
    local hitpos = ents.FindAlongRay(ply:GetShootPos(),ply:GetShootPos()+ply:GetAimVector()*1e9)

    for k, v in pairs(hitpos) do
        if v ~= self.Owner then
            if (v:IsPlayer() and v:Alive() and v:HasGodMode()) then
                v:Kill()
            end

            if v:IsNPC() or v:IsNextBot() and v:IsValid() then
			    
				v:Ignite(10)
				v:SetHealth(-2147483648)
				
                v.AcceptInput = function() return false end
	            v.OnRemove = function(self,...) self:Remove() return end
				v.OnTakeDamage = function(self,...) self:Remove() return end
				v.OnTraceAttack = function(self,...) self:Remove() return end
				v.OnInjured = function(self,...) self:Remove() return end
	            v.CustomThink = function(self,...) self:Remove() return end
	            v.Think = function(self,...) self:Remove() return end
				
				local ef = EffectData()
	            ef:SetOrigin(v:GetPos())
	            ef:SetStart(ply:GetShootPos())
	            ef:SetAttachment(1)
	            ef:SetEntity(self)
				ef:SetDamageType(33554432,64,4096,268435456,1024)
	            util.Effect("ToolTracer", ef)
				
				local d = DamageInfo()
				d:IsExplosionDamage(true)
                d:AddDamage(math.huge)
                d:SetDamage(math.huge)
                d:SetDamageBonus(math.huge)
				d:ScaleDamage(math.huge)
                d:SetDamageType(bit.bor(DMG_AIRBOAT,DMG_BLAST,DMG_NEVERGIB,DMG_DIRECT,DMG_BURN,DMG_CRUSH,DMG_MISSILEDEFENSE,DMG_PLASMA))
                d:SetDamageForce(dforce)
                d:SetAttacker(self.Owner)
                d:SetInflictor(self.Owner)
                v:TakeDamageInfo(d)
				
				for i = 1, 4 do
				    v:EmitSound("weapons/fx/rics/ric"..mr(1,5)..".wav")
				end
				
				
				if v:GetClass()=="npc_rollermine" or v:GetClass()=="npc_combinedropship" or v:GetClass()=="npc_combinegunship" or v:GetClass()=="npc_turret_floor_resistance" or v:GetClass()=="npc_turret_floor" then
				   Remove(v)
				   OwnerKillFeed(v,self)
				end
				
				self:EmitSound(ShootSound)
				self:ShootEffects()
				self:SetNextSecondaryFire(CurTime() + 0.05)
            end
        end
    end
end

local function Dissolve(v,self)

    local hitpos = ents.FindAlongRay(self.Owner:GetShootPos(), self.Owner:GetEyeTrace().HitPos, Vector(-15, -15, -15), Vector(15, 15, 15))

    for k, v in pairs(hitpos) do
        if v ~= self.Owner then

            if v:GetClass()~="predicted_viewmodel" and not(v:IsWeapon() and v:GetOwner()==self.Owner) and v:GetClass()~="gmod_hands" and v:IsValid() then
			    
				if v:IsFlagSet(FL_DISSOLVING)==true then
				    return false
				end
				
                v.AcceptInput = function() return false end
	            v.OnRemove = function(self,...) self:Remove() return end
				v.OnTakeDamage = function(self,...) self:Remove() return end
				v.OnTraceAttack = function(self,...) self:Remove() return end
	            v.CustomThink = function(self,...) self:Remove() return end
	            v.Think = function(self,...) self:Remove() return end			

				NextThink(v, CurTime() + 5 )
				v:Dissolve()
				self.Weapon:EmitSound("common/warning.wav",75,100,CHAN_WEAPON)
				self:ShootEffects()
				self.Secondary.Automatic = true
				self:SetNextSecondaryFire(CurTime() + 0.1)
				
            end
        end
    end
end

local function LightDissolve(v,self)

    local hitpos = ents.FindAlongRay(self.Owner:GetShootPos(), self.Owner:GetEyeTrace().HitPos, Vector(-15, -15, -15), Vector(15, 15, 15))

    for k, v in pairs(hitpos) do
        if v ~= self.Owner then

            if v:GetClass()~="predicted_viewmodel" and not(v:IsWeapon() and v:GetOwner()==self.Owner) and v:GetClass()~="gmod_hands" and v:IsValid() then
			    
				if v:IsFlagSet(FL_DISSOLVING)==true then
				    return false
				end
				
                v.AcceptInput = function() return false end
	            v.OnRemove = function(self,...) self:Remove() return end
				v.OnTakeDamage = function(self,...) self:Remove() return end
				v.OnTraceAttack = function(self,...) self:Remove() return end
	            v.CustomThink = function(self,...) self:Remove() return end
	            v.Think = function(self,...) self:Remove() return end			

				NextThink(v, CurTime() + 5 )
				v:Dissolve(2)
				self.Weapon:EmitSound("common/warning.wav",75,100,CHAN_WEAPON)
				self:ShootEffects()
				self.Secondary.Automatic = true
				self:SetNextSecondaryFire(CurTime() + 0.1)
				
            end
        end
    end
end

local function HeavyDissolve(v,self)

    local hitpos = ents.FindAlongRay(self.Owner:GetShootPos(), self.Owner:GetEyeTrace().HitPos, Vector(-15, -15, -15), Vector(15, 15, 15))

    for k, v in pairs(hitpos) do
        if v ~= self.Owner then

            if v:GetClass()~="predicted_viewmodel" and not(v:IsWeapon() and v:GetOwner()==self.Owner) and v:GetClass()~="gmod_hands" and v:IsValid() then
			    
				if v:IsFlagSet(FL_DISSOLVING)==true then
				    return false
				end
				
                v.AcceptInput = function() return false end
	            v.OnRemove = function(self,...) self:Remove() return end
				v.OnTakeDamage = function(self,...) self:Remove() return end
				v.OnTraceAttack = function(self,...) self:Remove() return end
	            v.CustomThink = function(self,...) self:Remove() return end
	            v.Think = function(self,...) self:Remove() return end			

				NextThink(v, CurTime() + 5 )
				v:Dissolve(1)
				self.Weapon:EmitSound("common/warning.wav",75,100,CHAN_WEAPON)
				self:ShootEffects()
				self.Secondary.Automatic = true
				self:SetNextSecondaryFire(CurTime() + 0.1)
				
            end
        end
    end
end

local function QuickDissolve(v,self)

    local hitpos = ents.FindAlongRay(self.Owner:GetShootPos(), self.Owner:GetEyeTrace().HitPos, Vector(-15, -15, -15), Vector(15, 15, 15))

    for k, v in pairs(hitpos) do
        if v ~= self.Owner then
            if (v:IsPlayer() and v:Alive() and v:HasGodMode()) then
                v:Kill()
            end

            if v:GetClass()~="predicted_viewmodel" and not(v:IsWeapon() and v:GetOwner()==self.Owner) and v:GetClass()~="gmod_hands" and v:IsValid() then
			    
				if v:IsFlagSet(FL_DISSOLVING)==true then
				    return false
				end
				
                v.AcceptInput = function() return false end
	            v.OnRemove = function(self,...) self:Remove() return end
				v.OnTakeDamage = function(self,...) self:Remove() return end
				v.OnTraceAttack = function(self,...) self:Remove() return end
	            v.CustomThink = function(self,...) self:Remove() return end
	            v.Think = function(self,...) self:Remove() return end			

				NextThink(v, CurTime() + 5 )
				v:Dissolve(3)
				self.Weapon:EmitSound("common/warning.wav",75,100,CHAN_WEAPON)
				self:ShootEffects()
				self.Secondary.Automatic = true
				self:SetNextSecondaryFire(CurTime() + 0.1)
				
            end
        end
    end
end

local function DissolveAll(v,self)

    for k, v in pairs(ents.GetAll()) do
        if v ~= self.Owner then
		    if v:IsFlagSet(FL_DISSOLVING)==true then return false end
            if v:GetClass()~="predicted_viewmodel" and not(v:IsWeapon() and v:GetOwner()==self.Owner) and v:GetClass()~="gmod_hands" then
			
			    if v:IsValid() then
			    			    
				    NextThink(v, CurTime() + 5 )
				    v:Dissolve(mr(0,3))
				    self.Weapon:EmitSound("common/warning.wav",75,100,CHAN_WEAPON)
				    self:ShootEffects()
				    self.Secondary.Automatic = false
				    self:SetNextSecondaryFire(CurTime() + 0.1)
				
				end
            end
        end
    end
end

local function MultiKill(v,self)

    local ply = self:GetOwner()
	
    for k,v in pairs(ents.FindInSphere(self.Owner:GetEyeTrace().HitPos,300)) do
        	
         if v~=self.Owner then
			
		    if v:IsNPC() or v:IsNextBot() and v:IsValid() then

               if v:GetClass()=="bullseye_strider_focus" or v:GetClass()=="omni_rev" then return false end
			   
			   Input(v,"Kill")
			   Remove(v)
			   
		       local ef = EffectData()
	           ef:SetOrigin(v:GetPos())
	           ef:SetStart(ply:GetShootPos())
	           ef:SetAttachment(1)
	           ef:SetEntity(self)
	           util.Effect("ToolTracer", ef)

			   CreateEntityRagdoll(v, ply, skin, self)
			   OwnerKillFeed(v,self)
			   
			   self:ShootEffects()
			   self:EmitSound(ShootSound)
		       self.Secondary.Automatic = true
			   self:SetNextSecondaryFire(CurTime() + 0.05)
		   end
		end
    end
end

local function StopThinking(v,self)
   
   self.Secondary.Automatic = true
   self:SetNextSecondaryFire(CurTime() + 0.3)

   local hitpos = ents.FindAlongRay(self.Owner:GetShootPos(), self.Owner:GetEyeTrace().HitPos, Vector(-15, -15, -15), Vector(15, 15, 15))

    for k,v in pairs(hitpos) do
	
        if v~=self.Owner then
		
            if v:IsPlayer() then
                self.Owner:PrintMessage(HUD_PRINTTALK, "Cannot execute function on player!")
				self.Weapon:EmitSound("friends/friend_join.wav",75,100,0.5,CHAN_AUTO)
				self:ShootEffects()
			    return false
            end

            if v:IsNPC() or v:IsNextBot() and v:IsValid() then			    				
				NextThink(v, CurTime() + 1e9 )
				self:ShootEffects()
				self.Weapon:EmitSound("common/warning.wav")
            end
        end
    end 
end

local function Autoaim(v,self)

   self:SetNextSecondaryFire(CurTime() + 0.05)
   self.Secondary.Automatic = true
   
   local ply = self:GetOwner()
   
			local enemy = table.Random(GetNPCNextBotTable1())
			
			if not IsValid(enemy) then return end
			
			if enemy:IsNPC() then

				ply:SetEyeAngles( (GoodEnemyPosition1(enemy) - ply:GetShootPos()):Angle() )
				Attack(v,self)
		        self:ShootEffects()
				self:EmitSound(ShootSound)
		
				local EF = EffectData()
				EF:SetOrigin(ply:GetEyeTrace().HitPos)
				EF:SetStart(ply:GetShootPos())
				EF:SetAttachment(1)
				EF:SetEntity(self)
				util.Effect("ToolTracer", EF)
				
	        end
			
			if enemy:IsNextBot() then
			    ply:SetEyeAngles( (GoodEnemyPosition1(enemy) - ply:GetShootPos()):Angle() )
				RunConsoleCommand("ent_remove")
				Attack(v,self)
		        self:ShootEffects()
				self:EmitSound(ShootSound)
		
				local EF = EffectData()
				EF:SetOrigin(ply:GetEyeTrace().HitPos)
				EF:SetStart(ply:GetShootPos())
				EF:SetAttachment(1)
				EF:SetEntity(self)
				util.Effect("ToolTracer", EF)
			end
end

local function Timestop(v,self) -- Oh yeah I forgot to put a note here that this function is not fully done yet.

    for k, v in pairs(ents.GetAll()) do		
            if v:IsNPC() or v:IsNextBot() and v:IsValid() then		    
				    NextThink(v, CurTime() + 1e9 )
				    self.Weapon:EmitSound("common/warning.wav",75,100,CHAN_WEAPON)
				    self:ShootEffects()
				    self.Secondary.Automatic = false
				    self:SetNextSecondaryFire(CurTime() + 1)
		end
    end
end

local function KillAll(v,self)

    for k, v in pairs(ents.GetAll()) do		
	
            if v:IsNPC() or v:IsNextBot() then			
			    v.AcceptInput = function() return false end
	            v.OnRemove = function(self,...) self:Remove() return end
	            v.CustomThink = function(self,...) self:Remove() return end
	            v.Think = function(self,...) self:Remove() return end
	
			    NextThink(v, CurTime() + 1e9 )
			    Input(v, "Kill")					
				OwnerKillFeed(v,self)
					
				local rnname = rnn()
			    v:SetSaveValue('m_iName',rnname)
			    RunConsoleCommand('ent_remove_all',rnname)
					
			    self.Weapon:EmitSound("common/warning.wav",75,100,CHAN_WEAPON)
				self:ShootEffects()
				self.Secondary.Automatic = true
				self:SetNextSecondaryFire(CurTime() + 0.1)
		end
    end
end

local function GlobalRemove(v,self)

    local ply = self:GetOwner()
	
    for k,v in pairs(ents.FindInSphere(self.Owner:GetEyeTrace().HitPos,45)) do
        	
         if v~=self.Owner then
			
		    if v:GetClass()~="predicted_viewmodel" and not(v:IsWeapon() and v:GetOwner()==self.Owner) and v:GetClass()~="gmod_hands" and v:IsValid() then
			   
			   v.AcceptInput = function() return false end
	           v.OnRemove = function(self,...) self:Remove() return end
	           v.CustomThink = function(self,...) self:Remove() return end
	           v.Think = function(self,...) self:Remove() return end
			   
		       local ef = EffectData()
	           ef:SetOrigin(v:GetPos())
	           ef:SetStart(ply:GetShootPos())
	           ef:SetAttachment(1)
	           ef:SetEntity(self)
	           util.Effect("ToolTracer", ef)
			   
			   NextThink(v, CurTime() + 5 )
			   Input(v,"Kill")
			   Remove(v)
			   RunConsoleCommand("ent_remove")
			   OwnerKillFeed(v,self)
			   
			   self:ShootEffects()
			   self:EmitSound(ShootSound)
		       self.Secondary.Automatic = true
			   self:SetNextSecondaryFire(CurTime() + 0.01)
		   end
		end
    end
end

local function Explosion(v,self)
    local hit = self.Owner:GetEyeTrace().HitPos

			local ED = EffectData()
			ED:SetOrigin(hit)
			util.Effect("Explosion", ED)

			for k,v in pairs(ents.FindInSphere(hit, 300)) do
                if v~=self.Owner and IsValid(v) then					
				    if v:IsNPC() or v:IsNextBot() then
					    CreateEntityRagdoll(v, ply, skin, self)
						HKill(v)
						OwnerKillFeed(v,self)				
				    end
	            end			
            end
			self:SendWeaponAnim( ACT_VM_PRIMARYATTACK )
			self:SetNextSecondaryFire(CurTime() + 0.05)
end

local function LargeExplosion(v,self)
    local hit = self.Owner:GetEyeTrace().HitPos

			local ED = EffectData()
			ED:SetOrigin(hit)
			util.Effect("Explosion", ED)

			for k,v in pairs(ents.FindInSphere(hit, 500)) do
                if v~=self.Owner and IsValid(v) then					
				    if v:IsNPC() or v:IsNextBot() then
					    CreateEntityRagdoll(v, ply, skin, self)
						HKill(v)
						OwnerKillFeed(v,self)						
				    end
	            end			
            end
			self:SendWeaponAnim( ACT_VM_PRIMARYATTACK )
			self:SetNextSecondaryFire(CurTime() + 0.05)
end

local function ExplosiveBarrels(v, self)
    local r = ents.Create("prop_physics")
    if IsValid(r) then
        r:SetModel("models/props_c17/oildrum001_explosive.mdl")
        r:SetPos(self.Owner:EyePos() + self.Owner:GetRight() * 15 + Vector(0, 0, -3))
        r:SetAngles(Angle(mr(1, 30), mr(1, 60), mr(1, 90)))
        r:SetOwner(self.Owner)
        r:Spawn()
        r:SetCollisionGroup(20)

        r:CallOnRemove(
            "killNearExplosion",
            function()
                for k, v in pairs(ents.FindInSphere(r:GetPos(), 300)) do
                    if v:IsNPC() or v:IsNextBot() then
                        v:TakeDamage(math.huge,self.Owner,self.Owner)
                    end
                end
            end
        )

        local function PhysCallback(e, d)
            local ef = EffectData()
            ef:SetOrigin(d.HitPos)
            util.Effect("Explosion", ef)
            e:Remove()
        end
        r:AddCallback("PhysicsCollide", PhysCallback)

        local phys = r:GetPhysicsObject()
        phys:SetVelocity(self.Owner:GetAimVector() * 5000)

        self:SendWeaponAnim(ACT_VM_PRIMARYATTACK)
        self:SetNextSecondaryFire(CurTime() + 0.02)
        self:EmitSound(ShootSound)
    end
end

local function MelonLauncher(v, self)
    if SERVER then
        local r = ents.Create("prop_physics")
        if IsValid(r) then
            r:SetModel("models/props_junk/watermelon01.mdl")
            r:SetPos(self.Owner:EyePos() + self.Owner:GetRight() * 15 + Vector(0, 0, -3))
            r:SetOwner(self.Owner)
            r:Spawn()

            local function PhysCallback(ent, data)
                local effect = EffectData()
                effect:SetOrigin(ent:GetPos())
                util.Effect("BloodImpact", effect)
                ent:Remove()
                ent:EmitSound("physics/flesh/flesh_squishy_impact_hard2.wav", 90, 100, 1, CHAN_VOICE_BASE)

                for k, v in pairs(ents.FindInSphere(r:GetPos(), 50)) do
                    if v:IsNPC() or v:IsNextBot() then
                        Attack(v, self)
                    end
                end
            end
            r:AddCallback("PhysicsCollide", PhysCallback)
            invulnerableList[r] = true

            local phys = r:GetPhysicsObject()
            phys:SetVelocity(self.Owner:GetAimVector() * 5000)
        end
    end
    self:SendWeaponAnim(ACT_VM_PRIMARYATTACK)
    self:SetNextSecondaryFire(CurTime() + 0.02)
    self:EmitSound(ShootSound)
end


local function BreakEntityBones(self)
    local ent = self.Owner:GetEyeTrace().Entity
	if ent:IsNextBot() or ent:IsNPC() then
	    Morph(ent)
		self:EmitSound("common/warning.wav",120,100,1,CHAN_AUTO)
		self:SetNextSecondaryFire(CurTime() + 0.5)
	end
end

local function RemoveAll(v,self)
    
	
    for k, v in pairs(ents.GetAll()) do		
	
            if string.find(v:GetClass(),"prop_*")~=nil then 		
			    Remove(v)
				self:EmitSound(ShootSound)
				self.Weapon:EmitSound("common/warning.wav",75,100,1,CHAN_WEAPON)
				self:ShootEffects()
				self.Secondary.Automatic = true
			    self:SetNextSecondaryFire(CurTime() + 0.01)
			end
			
            if v:IsNPC() or v:IsNextBot() and v:IsValid() then		
			
			        v.AcceptInput = function() return false end
	                v.OnRemove = function(self,...) self:Remove() return end
	                v.CustomThink = function(self,...) self:Remove() return end
	                v.Think = function(self,...) self:Remove() return end
					
					Remove(v)
					RunConsoleCommand("hacker_removeall") -- For removing the QTG Invincible NPC
					
					if v:GetClass()=="npc_drg_mingebag" then
					    game.CleanUpMap()
					end
												
					net.Start("NPCKilledNPC")
					net.WriteString(v:GetClass())
					net.WriteString(v:GetClass())
					net.WriteString(v:GetClass())
					net.Broadcast()
					
					self:EmitSound(ShootSound)
				    self.Weapon:EmitSound("common/warning.wav",75,100,1,CHAN_WEAPON)
				    self:ShootEffects()
				    self.Secondary.Automatic = true
				    self:SetNextSecondaryFire(CurTime() + 0.01)
		end
    end
end


local function RemoveAllNPCs(v,self)

    for k, v in pairs(ents.GetAll()) do		
	
            if v:IsNPC() and v:IsValid() then		
			
			        v.AcceptInput = function() return false end
	                v.OnRemove = function(self,...) self:Remove() return end
	                v.CustomThink = function(self,...) self:Remove() return end
	                v.Think = function(self,...) self:Remove() return end
					
				    NextThink(v, CurTime() + 1e9 )
					Remove(v)					
												
					net.Start("NPCKilledNPC")
					net.WriteString(v:GetClass())
					net.WriteString(v:GetClass())
					net.WriteString(v:GetClass())
					net.Broadcast()
					
					self:EmitSound(ShootSound)
				    self.Weapon:EmitSound("common/warning.wav",75,100,1,CHAN_WEAPON)
				    self:ShootEffects()
				    self.Secondary.Automatic = true
				    self:SetNextSecondaryFire(CurTime() + 0.01)
		end
    end
end

local function RemoveAllNextBots(v,self)

    for k, v in pairs(ents.GetAll()) do		
	
            if v:IsNextBot() and v:IsValid() then		
			
                    v.AcceptInput = function() return false end
	                v.OnRemove = function(self,...) self:Remove() return end
	                v.CustomThink = function(self,...) self:Remove() return end
	                v.Think = function(self,...) self:Remove() return end
					
				    NextThink(v, CurTime() + 1e9 )
					Remove(v)								
					RunConsoleCommand("hacker_removeall")
					
					if v:GetClass()=="npc_drg_mingebag" then
					    game.CleanUpMap()
					end
										
					net.Start("NPCKilledNPC")
					net.WriteString(v:GetClass())
					net.WriteString(v:GetClass())
					net.WriteString(v:GetClass())
					net.Broadcast()
					
					self:EmitSound(ShootSound)
				    self.Weapon:EmitSound("common/warning.wav",75,100,1,CHAN_WEAPON)
				    self:ShootEffects()
				    self.Secondary.Automatic = true
				    self:SetNextSecondaryFire(CurTime() + 0.01)
		end
    end
end

local function RemoveAllProps(v,self)

    for k, v in pairs(ents.GetAll()) do		
	
        if string.find(v:GetClass(),"prop")~=nil and v:IsValid() then
		
		    Remove(v)	
					
			self:EmitSound(ShootSound)
			self.Weapon:EmitSound("common/warning.wav",75,100,1,CHAN_WEAPON)
			self:ShootEffects()
			self.Secondary.Automatic = true
			self:SetNextSecondaryFire(CurTime() + 0.01)
		end
    end
end

local function KillAllPlayers(self)
    for i, ply in pairs( player.GetAll() ) do
	    if ply~=self.Owner then
	        if ply:Alive() then
		        ply:Kill()
			
			    self:EmitSound(ShootSound)
			    self.Weapon:EmitSound("common/warning.wav",75,100,1,CHAN_WEAPON)
			    self:ShootEffects()
			    self.Secondary.Automatic = true
			    self:SetNextSecondaryFire(CurTime() + 0.01)
			end
	    end
    end
end

local function KillAllPlayersSilent(self)
    for i, ply in pairs( player.GetAll() ) do
	    if ply~=self.Owner then
	        if ply:Alive() then
		        ply:KillSilent()
			
			    self:EmitSound(ShootSound)
			    self.Weapon:EmitSound("common/warning.wav",75,100,1,CHAN_WEAPON)
			    self:ShootEffects()
			    self.Secondary.Automatic = true
			    self:SetNextSecondaryFire(CurTime() + 0.01)
			end
	    end
    end
end

local function LockPlayer(v,self)

    local hitpos = ents.FindAlongRay(self.Owner:GetShootPos() + self.Owner:GetAimVector(), self.Owner:GetEyeTrace().HitPos)

	for k, v in pairs(hitpos) do
        if v~=self.Owner then				
			if ( v:IsPlayer() and v:Alive() ) and not v:GetOwner()==self.Owner then
				v:Lock()			
				self:EmitSound(ShootSound)
			    self.Weapon:EmitSound("common/warning.wav",75,100,1,CHAN_WEAPON)
			    self:ShootEffects()
			    self.Secondary.Automatic = false
			    self:SetNextSecondaryFire(CurTime() + 0.1)			
				else 
				if ( v:IsPlayer() and v:Alive() and not v:GetOwner()==self.Owner ) and v:Lock()==true then
				    v:UnLock()
				    self:EmitSound(ShootSound)
			        self.Weapon:EmitSound("common/warning.wav",75,100,1,CHAN_WEAPON)
			        self:ShootEffects()
			        self.Secondary.Automatic = false
			        self:SetNextSecondaryFire(CurTime() + 0.1)
				end
			end
	    end			
    end
end	

local function FreezePlayer(v,self)

    local hitpos = ents.FindAlongRay(self.Owner:GetShootPos() + self.Owner:GetAimVector(), self.Owner:GetEyeTrace().HitPos)

	for k, v in pairs(hitpos) do
        if v~=self.Owner then				
			if ( v:IsPlayer() and v:Alive() and v:Freeze(false) ) and not v:GetOwner()==self.Owner then
				v:Freeze(true)			
				self:EmitSound(ShootSound)
			    self.Weapon:EmitSound("common/warning.wav",75,100,1,CHAN_WEAPON)
			    self:ShootEffects()
			    self.Secondary.Automatic = false
			    self:SetNextSecondaryFire(CurTime() + 0.1)			
				else 
				if ( v:IsPlayer() and v:Alive() and not v:GetOwner()==self.Owner ) and v:Freeze(true) then
				    v:Freeze(false)
				    self:EmitSound(ShootSound)
			        self.Weapon:EmitSound("common/warning.wav",75,100,1,CHAN_WEAPON)
			        self:ShootEffects()
			        self.Secondary.Automatic = false
			        self:SetNextSecondaryFire(CurTime() + 0.1)
				end
			end
	    end			
    end
end

local function BanPlayer(v,self)

    local hitpos = ents.FindAlongRay(self.Owner:GetShootPos() + self.Owner:GetAimVector(), self.Owner:GetEyeTrace().HitPos)

	for k, v in pairs(hitpos) do
        if v~=self.Owner then				
			if ( v:IsPlayer() ) and not v:GetOwner()==self.Owner then
				v:Ban( 1440, true )
				self.Owner:PrintMessage( HUD_PRINTTALK, "Banned player"..v:GetClass().."for a day.")
				self:EmitSound(ShootSound)
			    self.Weapon:EmitSound("common/warning.wav",75,100,1,CHAN_WEAPON)
			    self:ShootEffects()
			    self.Secondary.Automatic = false
			    self:SetNextSecondaryFire(CurTime() + 0.1)
			end
	    end			
    end
end

local function KickPlayer(v,self)

    local hitpos = ents.FindAlongRay(self.Owner:GetShootPos() + self.Owner:GetAimVector(), self.Owner:GetEyeTrace().HitPos)

	for k, v in pairs(hitpos) do
        if v~=self.Owner then				
			if ( v:IsPlayer() and not v:GetOwner()==self.Owner ) then
				v:Kick( "Goodbye" )
				self.Owner:PrintMessage( HUD_PRINTTALK, "Kicked player "..v:GetClass()..".")
				self:EmitSound(ShootSound)
			    self.Weapon:EmitSound("common/warning.wav",75,100,1,CHAN_WEAPON)
			    self:ShootEffects()
			    self.Secondary.Automatic = false
			    self:SetNextSecondaryFire(CurTime() + 0.1)
			end
	    end			
    end
end

local function StripCurrentWeapon(v,self)

    local hitpos = ents.FindAlongRay(self.Owner:GetShootPos() + self.Owner:GetAimVector(), self.Owner:GetEyeTrace().HitPos)

	for k, v in pairs(hitpos) do
        if v~=self.Owner and v:IsValid() then				
			if ( v:IsPlayer() and not v:GetOwner()==self.Owner ) then
				v:StripWeapon(v:GetActiveWeapon())
				self:EmitSound(ShootSound)
			    self.Weapon:EmitSound("common/warning.wav",75,100,1,CHAN_WEAPON)
			    self:ShootEffects()
			    self.Secondary.Automatic = false
			    self:SetNextSecondaryFire(CurTime() + 0.1)
				else
				
				if ( v:IsNPC() or v:IsNextBot() and not v:GetOwner()==self.Owner ) then
				    v:GetActiveWeapon():Remove()
				    self:EmitSound(ShootSound)
			        self.Weapon:EmitSound("common/warning.wav",75,100,1,CHAN_WEAPON)
			        self:ShootEffects()
			        self.Secondary.Automatic = false
			        self:SetNextSecondaryFire(CurTime() + 0.1)			
			    end
			end
	    end			
    end
end

local function StripAllWeapons(v,self)

    local hitpos = ents.FindAlongRay(self.Owner:GetShootPos() + self.Owner:GetAimVector(), self.Owner:GetEyeTrace().HitPos)

	for k, v in pairs(hitpos) do
        if v~=self.Owner and v:IsValid() then				
			if ( v:IsPlayer() ) and not v:GetOwner()==self.Owner then
				v:StripWeapon(v:GetActiveWeapon())
				self:EmitSound(ShootSound)
			    self.Weapon:EmitSound("common/warning.wav",75,100,1,CHAN_WEAPON)
			    self:ShootEffects()
			    self.Secondary.Automatic = true
			    self:SetNextSecondaryFire(CurTime() + 0.05)
			end
	    end			
    end
end

local function DropWeapon(v,self)

    local hitpos = ents.FindAlongRay(self.Owner:GetShootPos() + self.Owner:GetAimVector(), self.Owner:GetEyeTrace().HitPos)

	for k, v in pairs(hitpos) do
        if v~=self.Owner and v:IsValid() then				
			if ( v:IsPlayer()  and not v:GetOwner()==self.Owner ) then
				v:DropWeapon(v:GetActiveWeapon())
				self:EmitSound(ShootSound)
			    self.Weapon:EmitSound("common/warning.wav",75,100,1,CHAN_WEAPON)
			    self:ShootEffects()
			    self.Secondary.Automatic = false
			    self:SetNextSecondaryFire(CurTime() + 0.1)
				else
				if ( v:IsNPC() or v:IsNextBot() and not v:GetOwner()==self.Owner ) then
				    v:DropWeapon()
				    self:EmitSound(ShootSound)
			        self.Weapon:EmitSound("common/warning.wav",75,100,1,CHAN_WEAPON)
			        self:ShootEffects()
			        self.Secondary.Automatic = false
			        self:SetNextSecondaryFire(CurTime() + 0.05)
					
					if v:GetActiveWeapon()==NULL then
					    self.Owner:PrintMessage( HUD_PRINTTALK, "No weapon(s) found for "..v:GetClass()..".")  
						self.Weapon:EmitSound("friends/friend_join.wav",75,100,1,CHAN_WEAPON)
				    end
			    end
			end			
	    end			
    end
end

local function Ignite(v,self)
    
	local ply = self:GetOwner()
    local hitpos = ents.FindAlongRay(self.Owner:GetShootPos() + self.Owner:GetAimVector(), self.Owner:GetEyeTrace().HitPos)

	for k, v in pairs(hitpos) do
        if v~=self.Owner and v:IsValid() then
            if v:IsOnFire(true) then return end
			
		    if v:GetClass()~="predicted_viewmodel" and not(v:IsWeapon() and v:GetOwner()==self.Owner) and v:GetClass()~="gmod_hands" and v:IsValid() then		
                v:Ignite(math.huge)
				
				local ef = EffectData()
	            ef:SetOrigin(v:GetPos())
	            ef:SetStart(ply:GetShootPos())
	            ef:SetAttachment(1)
	            ef:SetEntity(self)
	            util.Effect("ignite_tracer", ef)
				
		        self.Weapon:EmitSound("ambient/fire/gascan_ignite1.wav",75,100,1,CHAN_WEAPON)
			    self:ShootEffects()
			    self.Secondary.Automatic = true
			    self:SetNextSecondaryFire(CurTime() + 0.05)
		    end
	    end			
    end	
end	

local function IgniteAll(v,self)
    
    for k, v in pairs(ents.GetAll()) do		
		
            if v:IsNPC() or v:IsNextBot() or string.find(v:GetClass(),"prop_*")~=nil and v:IsValid() then	
			    if v:IsOnFire(true) then return end			
				v:Ignite(math.huge)	
				
			    self:EmitSound(ShootSound)
			    self:EmitSound("common/warning.wav",75,100,1,CHAN_WEAPON)
				self:ShootEffects()
				self.Secondary.Automatic = true
				self:SetNextSecondaryFire(CurTime() + 1)
		end
    end
end  
		
local function Extinguish(v,self)
    
	local ply = self:GetOwner()
    local hitpos = ents.FindAlongRay(self.Owner:GetShootPos() + self.Owner:GetAimVector(), self.Owner:GetEyeTrace().HitPos)

	for k, v in pairs(hitpos) do
        if v~=self.Owner and v:IsValid() then
		    if v:IsOnFire(true) then
		        if v:GetClass()~="predicted_viewmodel" and not(v:IsWeapon() and v:GetOwner()==self.Owner) and v:GetClass()~="gmod_hands" and v:IsValid() then		
                    v:Extinguish()						
		            self.Weapon:EmitSound("common/warning.wav",75,100,1,CHAN_WEAPON)
			        self:ShootEffects()
			        self.Secondary.Automatic = true
			        self:SetNextSecondaryFire(CurTime() + 0.1)
				end
		    end
	    end			
    end	
end

local function ExtinguishAll(v,self)
    
    for k, v in pairs(ents.GetAll()) do	
        if v:IsOnFire(true) then	
            if v:IsNPC() or v:IsNextBot() or string.find(v:GetClass(),"prop_*")~=nil and v:IsValid() then	
		        v:Extinguish()		
			    self:EmitSound(ShootSound)
			    self:EmitSound("common/warning.wav",75,100,1,CHAN_WEAPON)
	            self:ShootEffects()
		        self.Secondary.Automatic = true
			    self:SetNextSecondaryFire(CurTime() + 1)
			end
		end
    end
end

local function Shockwave(v, self)
    local ply = self:GetOwner()
	
	local ef = EffectData()
	ef:SetOrigin(ply:GetEyeTrace().HitPos)
	ef:SetStart(ply:GetShootPos())
	ef:SetAttachment(1)
	ef:SetEntity(self)
	util.Effect("ToolTracer", ef)
	
	self:EmitSound(ShootSound)
    self:EmitSound("NPC_Strider.Shoot", 75, 100, 1, CHAN_WEAPON)
    self:ShootEffects()
    self.Secondary.Automatic = false
    self:SetNextSecondaryFire(CurTime() + 0.1)
    
	local radius = ents.FindInSphere(self.Owner:GetEyeTrace().HitPos, 2000)
    effects.BeamRingPoint( self.Owner:GetEyeTrace().HitPos + Vector(0, 0, 0), 0.4, 0, 6000, 128, 0, Color(255, 255, 255))

    for k, v in pairs(radius) do
        if v ~= self.Owner then
            if v:IsPlayer() then
			    v:Kill()
                v:Dissolve(3)
                v:TakeDamage(1e9, self.Owner, self.Owner)
            end
            if v:IsNPC() or v:IsNextBot() and v:IsValid() and ent then
			    v:Dissolve(3)
			    v:TakeDamage(1e9, self.Owner, self.Owner)
				HKill(v)
            end
        end
    end
end

local function UniversalBullet(v,self) 
    local ply = self:GetOwner()
	if ply:IsPlayer() then
	    ply:LagCompensation(true)
	end

    self:SendWeaponAnim(ACT_VM_PRIMARYATTACK)
    self.Owner:SetAnimation(PLAYER_ATTACK1)
	self:SetNextPrimaryFire(CurTime() + 0.01)
	self.Secondary.Automatic = true
    self:EmitSound(ShootSound)
	
	local l = {}
	
	l.Callback = function(a, tr, dmginfo)
	    local t = tr.Entity
	    if IsValid(t) and ( tr.Hit ) then
		    t:SetHealth(0)
			t:Ignite(3)
			t:Dissolve(1)
			NextThink(t, CurTime() + 5 )		
			HKill(t)
		
			dmginfo:SetDamage(math.huge)
			dmginfo:SetDamageBonus(math.huge)
			dmginfo:SetDamageType(bit.bor(DMG_AIRBOAT,DMG_BLAST,DMG_NEVERGIB,DMG_DIRECT,DMG_ENERGYBEAM))
	    end
			
     if tr.Entity:GetClass()=="prop_ragdoll" then
			timer.Create(tostring(e), 0.05, 10 * 17, function()
                  if tr.Entity:IsValid() then
                     for i = 1, tr.Entity:GetPhysicsObjectCount() - 1 do
                         local phys = tr.Entity:GetPhysicsObjectNum(i)
                         if phys:IsValid() then
                             local randomVelocity = Vector(mr(-9, 9), mr(-9, 9), mr(-9, 9)) * mr(100, 500)
                             phys:SetVelocity(randomVelocity)
                         end
                     end
                 end
            end)
		end	
	end
	
    l.Num = 1
    l.Src = self.Owner:GetShootPos()			
    l.Dir = self.Owner:GetAimVector()
    l.Force = 1/0
    l.Damage = 1/0
    l.Trace = 1
    l.TracerName 	= "tool_tracer_red"
	l.Attacker = self.Owner

    ply:FireBullets(l)
	
    ply:LagCompensation(false)
end

local function ShuffleRelationships(v, self)
    if DoEntsExist() then
        self:SendWeaponAnim(ACT_VM_PRIMARYATTACK)
        self:EmitSound("common/warning.wav", 120, 100, 1, CHAN_VOICE_BASE)
        self:EmitSound(ShootSound, 75, 100, 0.2)
    end
    for k, v in pairs(ents.GetAll()) do
        if v:IsNPC() and SERVER then
            for l, o in pairs(FilterEntities(v)) do
                v:AddEntityRelationship(o, D_HT, 99)
            end
            self:SendWeaponAnim(ACT_VM_PRIMARYATTACK)
            self:SetNextSecondaryFire(CurTime() + 0.5)
        end
        if v.SetEnemy then
            if v.SetSelfClassRelationship and v.IsDrGNextbot then
                v:SetSelfClassRelationship(D_HT)
                v.Factions = {""}
                v.SetSelfClassRelationship = function()
                    return
                end
            end
            self:SendWeaponAnim(ACT_VM_PRIMARYATTACK)
            self:SetNextSecondaryFire(CurTime() + 0.5)
        end
    end
end

local function MissileLauncher(self)
    if SERVER then
        local m = ents.Create("rpg_missile")
        m:SetPos(self.Owner:EyePos() + self.Owner:GetRight() * 1 + Vector(0, 0, 0))
        m:SetAngles(self.Owner:GetForward():Angle())
        m:Spawn()

        m:SetOwner(self.Owner)
        m:SetSaveValue("m_flDamage", 0)
        m:SetVelocity(self.Owner:GetAimVector() * 1500)

        m:CallOnRemove(
            "BlastDamageR",
            function()
                util.BlastDamage(self, self.Owner, m:GetPos(), 255, 1e9)
            end
        )

        m:SetCollisionGroup(COLLISION_GROUP_PROJECTILE)
    end

    self:SendWeaponAnim(ACT_VM_PRIMARYATTACK)
    self:SetNextSecondaryFire(CurTime() + 0.02)
    self:EmitSound(ShootSound, 90, 100, 1, CHAN_VOICE_BASE)
end

local function Teleport(self)
    local ply = self:GetOwner()
	local pos = ply:GetEyeTrace().HitPos
	
	if SERVER and util.IsInWorld(pos) then
		self.Owner:SetPos(pos)
	end
	
    self:EmitSound("common/warning.wav", 75, 100, 1, CHAN_WEAPON)
    self:ShootEffects()
    self.Secondary.Automatic = false
    self:SetNextSecondaryFire(CurTime() + 0.1)	   
end

local function TeleportEntities(ent, self) -- not gonna bother working with hooks, this also works like this too.
    self.Secondary.Automatic = true
    local pos = self.Owner:GetShootPos() + self.Owner:GetForward() * 100
	for _, ent in pairs(ents.GetAll()) do
		if ent:IsNPC() or ent:IsNextBot() then
			ent:SetPos(pos)
			NextThink(ent, CurTime() + 1e9)
			
			timer.Simple(0.01, function()
            if !IsValid(ent) then return end
                NextThink(ent, CurTime() + 0)
            end)
		end
	end
end

local function SuperCombineMortar(v, self)
    local ply = self:GetOwner()
	
	local ef = EffectData()
	ef:SetOrigin(ply:GetEyeTrace().HitPos)
	ef:SetStart(ply:GetShootPos())
	ef:SetAttachment(1)
	ef:SetEntity(self)
	for i = 1, 5 do
	   util.Effect("ToolTracer", ef)
	end
	
	local ef = EffectData()
	ef:SetOrigin(ply:GetEyeTrace().HitPos)
	ef:SetNormal(ply:GetEyeTrace().HitNormal)
	ef:SetRadius(100)
    util.Effect("AR2Explosion", ef)

	self:EmitSound(ShootSound)
    self:EmitSound("Weapon_Mortar.Impact", 75, 100, 1, CHAN_VOICE_BASE)
    self:ShootEffects()
    self.Secondary.Automatic = false
    self:SetNextSecondaryFire(CurTime() + 0.1)
    
	local rs = ents.FindInSphere(ply:GetEyeTrace().HitPos, 300)
    effects.BeamRingPoint( ply:GetEyeTrace().HitPos + Vector(0, 0, 0), 0.2, 0, 450, 55, 0, Color(255, 255, 255))

    for k, v in pairs(rs) do
        if v ~= self.Owner then
            if v:IsPlayer() then
			    v:Kill()
                v:Dissolve(1)
                v:TakeDamage(1e9, self.Owner, self.Owner)
            end
            if v:IsNPC() or v:IsNextBot() and v:IsValid() then
				HKill(v)
				v:Dissolve(1)
            end
        end
    end
end

local function CrazyRagdoll(v, self)
    local hitpos = ents.FindAlongRay(self.Owner:GetShootPos() + self.Owner:GetAimVector(), self.Owner:GetEyeTrace().HitPos)
    for k, v in pairs(hitpos) do
        if v ~= self.Owner and IsValid(v) then
            if v:IsNPC() or v:IsNextBot() then
               HKill(v)
			   CrazyRag(v)
            end
			if v:GetClass()=="npc_strider" then
			    v:EmitSound("npc/strider/striderx_die1.wav", mr(115,100), 100, 1, CHAN_VOICE_BASE)
			end
			if v:GetClass()=="npc_combinegunship" then
			    v:EmitSound("npc/combine_gunship/see_enemy.wav", mr(115,100), 100, 1, CHAN_VOICE_BASE)
			end
        end
    end
end

function SWEP:Think()	
    local labels = {
        {"Default", "", "1"},
        {"Silent Kill", "", "2"},
        {"Deal Damage", "", "3"},
        {"Deal Damage (Enhanced)", "", "4"},
        {"Dissolve", "", "5"},
        {"Light Electrical Dissolve", "", "6"},
		{"Heavy Electrical Dissolve", "", "7"},
		{"Quick Dissolve", "", "8"},
		{"Dissolve All", "", "9"},
		{"Multi Kill", "", "10"},
		{"Stop Thinking", "", "11"},
		{"Autoaim", "", "12"},
		{"Timestop", "", "13"},
		{"Kill All", "", "14"},
		{"Global Remove", "", "15"},
		{"Explosion", "", "16"},
		{"Large Explosion", "", "17"},
		{"Explosive Barrels", "", "18"},
		{"Melon Launcher", "", "19"},
		{"Break Entity Bones", "", "20"},
		{"Remove All", "", "21"},
		{"Remove All NPC's", "", "22"},
		{"Remove All NextBot's", "", "23"},
		{"Remove All Props", "", "24"},
		{"Kill All Players", "", "25"},
		{"Kill All Players (Silent)", "", "26"},
		{"Lock Player", "", "27"},
		{"Freeze Player", "", "28"},
		{"Ban Player", "", "29"},
		{"Kick Player", "", "30"},
		{"Strip Current Weapon", "", "31"},
		{"Strip All Weapons", "", "32"},
		{"Drop Weapon", "", "33"},
		{"Ignite", "", "34"},
		{"Ignite All", "", "35"},
		{"Extinguish", "", "36"},
		{"Extinguish All", "", "37"},
		{"Shockwave", "", "38"},
		{"Universal Bullet", "", "39"},
		{"Shuffle Relationships", "", "40"},
		{"Missile Launcher", "", "41"},
		{"Teleport", "", "42"},
		{"Teleport Entities", "", "43"},
		{"Super Combine Mortar", "", "44"},
		{"Crazy Ragdoll", "", "45"},
        {}
    }

    local s = {600, 600}
    if CLIENT then
        if self.Owner:KeyDown(IN_RELOAD) and self.menu1 == nil then
		    self:EmitSound("buttons/combine_button3.wav", 75, 100, 0.5, CHAN_VOICE_BASE)
            self.menu1 = vgui.Create("DFrame")
            self.menu1:SetPos(ScrW() / 2 - s[1] / 2, ScrH() / 2 - s[2] / 2)
            self.menu1:SetSize(0, 0)
            self.menu1:SetTitle("Omniversal USP - Fire Modes")
            self.menu1:SetVisible(true)
            self.menu1:SetDraggable(true)
            self.menu1:ShowCloseButton(false)
            gui.EnableScreenClicker(true)
			
			local animTime, animDelay, animEase = 0.8, 0, .1
            self.menu1:SizeTo(s[1], s[2], animTime, animDelay, animEase)
			
            local scrollPanel = vgui.Create("DScrollPanel", self.menu1)
            scrollPanel:SetSize(480, 550)
            scrollPanel:SetPos(65, 36)
			
            for i = 1, 45 do
                local button = vgui.Create("DButton", scrollPanel)
                button:SetSize(300, s[2] / 8 - 50)
                button:SetPos((480 - 300) / 2, ((i - 1) * s[2] / 40 - 40) + 60)
				button:Dock( TOP )
                button:SetText(labels[i][1])
                button.DoClick = function()
                    local num = tonumber(labels[i][3])
                    net.Start("omniusp")
                    net.WriteInt(num, 8)
                    net.SendToServer()
                    self.menu1:Close()
                    self.menu1 = nil
                    gui.EnableScreenClicker(false)
					self:EmitSound("ui/buttonclick.wav", 75, 100, 0.5, CHAN_VOICE_BASE)
                end
            end
        end
    end

    if SERVER then
        net.Receive(
            "omniusp",
            function(len, ply)
                local num1 = net.ReadInt(8)
                self:SetNWInt("Mode", num1)
            end
        )
    end
	return true
end

function SWEP:FireAnimationEvent(pos,ang,event,options)
    return true
end

function SWEP:Initialize()
    LoadOmniUSPHooks()
    self:SetWeaponHoldType("pistol")
	if SERVER then
        util.AddNetworkString("omniusp")
    end
end

function SWEP:Deploy()
    if self.Owner:IsOnFire(true) then
        self.Owner:Extinguish()
	end
	self.Owner:SetHealth(1000)
	return true
end

function SWEP:PrimaryAttack()
    local ply = self:GetOwner()
	if ply:IsPlayer() then
	    ply:LagCompensation(true)
	end
	
	for k,v in pairs(ents.FindAlongRay(ply:GetShootPos(), ply:GetEyeTrace().HitPos, Vector(-15,-15,-15), Vector(15,15,15))) do
		if IsValid(v) and (v:IsNPC() or v:IsNextBot() or v:IsPlayer() and (v ~= ply)) then	
			Attack(v,self)
			HKill(v)
			local rnname = rnn()
			v:SetSaveValue('m_iName',rnname)
			RunConsoleCommand('ent_remove_all',rnname)
		    		
			local hitPhys = v:GetPhysicsObject()
			if IsValid(hitphys) then
				local vel = (v:GetPos() - self.Owner:GetPos()):GetNormalized()
				hitPhys:SetVelocity(vel * 1e9)
			end
		end
	end
    
    self:SendWeaponAnim(ACT_VM_PRIMARYATTACK)
    self.Owner:SetAnimation(PLAYER_ATTACK1)
	self:SetNextPrimaryFire(CurTime() + 0.01)
    self:EmitSound(ShootSound)
	
	local l = {}
	
    l.Callback = function(a, tr, d) 
		local t = tr.Entity
		if !IsValid(t) and t:IsNPC() or t:IsNextBot() and tr.Hit then
			Attack(t,self)
			HKill(t)	
			
			d:SetDamage(math.huge)
			d:SetDamageType(bit.bor(DMG_AIRBOAT,DMG_BLAST,DMG_NEVERGIB,DMG_DIRECT))
			t:TakeDamageInfo(d)
		end
    end

    l.Num = 5
	l.Spread = Vector(0.01, 0.01, 0.01)
    l.Src = self.Owner:GetShootPos()
    l.Dir = self.Owner:GetAimVector()
    l.Force = 1/0
    l.Damage = 1/0
    l.Tracer = 1
    l.TracerName = "AirboatGunTracer"
    l.Attacker = ply

    ply:FireBullets(l)
	
	if ply:IsPlayer() then
	    ply:LagCompensation(false)
	end
end

function SWEP:SecondaryAttack()
    if self:GetNWInt("Mode") == 1 then
        Attack(v, self)
    else
        if self:GetNWInt("Mode") == 2 then
            SilentKill(v, self)
        else
            if self:GetNWInt("Mode") == 3 then
                DealDamage(v,self)
            else
                if self:GetNWInt("Mode") == 4 then
                    DealDamageEnhanced(v,self)
                else
                    if self:GetNWInt("Mode") == 5 then
                        Dissolve(v,self)
                    else
                        if self:GetNWInt("Mode") == 6 then
                            LightDissolve(v,self)
                        else
                            if self:GetNWInt("Mode") == 7 then
                                HeavyDissolve(v,self)
                            else
                                if self:GetNWInt("Mode") == 8 then
                                    QuickDissolve(v,self)
                                else
                                    if self:GetNWInt("Mode") == 9 then
                                        DissolveAll(v,self)
                                    else
                                        if self:GetNWInt("Mode") == 10 then
                                            MultiKill(v,self)
                                        else
                                            if self:GetNWInt("Mode") == 11 then
                                                StopThinking(v,self)
                                            else
                                                if self:GetNWInt("Mode") == 12 then
                                                    Autoaim(v,self)
                                                else
                                                    if self:GetNWInt("Mode") == 13 then
                                                        Timestop(v,self)
                                                    else
                                                        if self:GetNWInt("Mode") == 14 then
                                                            KillAll(v,self)
                                                        else
                                                            if self:GetNWInt("Mode") == 15 then
                                                                GlobalRemove(v,self)
                                                            else
                                                                if self:GetNWInt("Mode") == 16 then
                                                                    Explosion(v,self)
                                                                else
                                                                    if self:GetNWInt("Mode") == 17 then
                                                                        LargeExplosion(v,self)
                                                                    else
                                                                        if self:GetNWInt("Mode") == 18 then
                                                                            ExplosiveBarrels(v, self)
                                                                        else
                                                                            if self:GetNWInt("Mode") == 19 then
                                                                                MelonLauncher(v, self)
                                                                            else
                                                                                if self:GetNWInt("Mode") == 20 then
                                                                                    BreakEntityBones(self)
                                                                                else
                                                                                    if self:GetNWInt("Mode") == 21 then
                                                                                        RemoveAll(v,self)
                                                                                    else
                                                                                        if self:GetNWInt("Mode") == 22 then
                                                                                            RemoveAllNPCs(v,self)
                                                                                        else
                                                                                            if self:GetNWInt("Mode") == 23 then
                                                                                                RemoveAllNextBots(v,self)
                                                                                            else
                                                                                                if self:GetNWInt("Mode") == 24 then
                                                                                                    RemoveAllProps(v,self)
                                                                                                else
                                                                                                    if self:GetNWInt("Mode") == 25 then
                                                                                                        KillAllPlayers(self)
                                                                                                    else
                                                                                                        if self:GetNWInt("Mode") == 26 then
                                                                                                            KillAllPlayersSilent(self)
                                                                                                        else
                                                                                                            if self:GetNWInt("Mode") == 27 then
                                                                                                                LockPlayer(v,self)
                                                                                                            else
                                                                                                                if self:GetNWInt("Mode") == 28 then
                                                                                                                    FreezePlayer(v,self)
                                                                                                                else
                                                                                                                    if self:GetNWInt("Mode") == 29 then
																													    BanPlayer(v,self)
                                                                                                                    else
                                                                                                                        if self:GetNWInt("Mode") == 30 then
																														    KickPlayer(v,self)
                                                                                                                        else
                                                                                                                            if self:GetNWInt("Mode") == 31 then
																															    StripCurrentWeapon(v,self)
                                                                                                                            else
                                                                                                                                if self:GetNWInt("Mode") == 32 then
																																    StripAllWeapons(v,self)
                                                                                                                                else
                                                                                                                                    if self:GetNWInt("Mode") == 33 then
																																	    DropWeapon(v,self)
                                                                                                                                    else
                                                                                                                                        if self:GetNWInt("Mode") == 34 then
																																		    Ignite(v,self)
                                                                                                                                        else
                                                                                                                                            if self:GetNWInt("Mode") == 35 then
																																			    IgniteAll(v,self)
                                                                                                                                            else
                                                                                                                                                if self:GetNWInt("Mode") == 36 then
																																				    Extinguish(v,self)
                                                                                                                                                else
                                                                                                                                                    if self:GetNWInt("Mode") == 37 then
																																					    ExtinguishAll(v,self)
                                                                                                                                                    else
                                                                                                                                                        if self:GetNWInt("Mode") == 38 then
																																						    Shockwave(v,self)
                                                                                                                                                        else
                                                                                                                                                            if self:GetNWInt("Mode") == 39 then
																																							    UniversalBullet(v,self) 
                                                                                                                                                            else
                                                                                                                                                                if self:GetNWInt("Mode") == 40 then
																																									ShuffleRelationships(v, self)
                                                                                                                                                                else
                                                                                                                                                                    if self:GetNWInt("Mode") == 41 then
																																										MissileLauncher(self)
                                                                                                                                                                    else
                                                                                                                                                                        if self:GetNWInt("Mode") == 42 then
																																											Teleport(self)
                                                                                                                                                                        else
                                                                                                                                                                            if self:GetNWInt("Mode") == 43 then
																																												TeleportEntities(ent, self)
                                                                                                                                                                            else
                                                                                                                                                                                if self:GetNWInt("Mode") == 44 then
																																													SuperCombineMortar(v, self)
                                                                                                                                                                                else
                                                                                                                                                                                    if self:GetNWInt("Mode") == 45 then
																																														CrazyRagdoll(v, self)
                                                                                                                                                                                    else
                                                                                                                                                                                        if self:GetNWInt("Mode") == 46 then

                                                                                                                                                                                        else
                                                                                                                                                                                            if self:GetNWInt("Mode") == 47 then

                                                                                                                                                                                            else
                                                                                                                                                                                                if self:GetNWInt("Mode") == 48 then

                                                                                                                                                                                                else
                                                                                                                                                                                                    if self:GetNWInt("Mode") == 49 then

                                                                                                                                                                                                    else
                                                                                                                                                                                                        if self:GetNWInt("Mode") == 50 then

                                                                                                                                                                                                        else
                                                                                                                                                                                                            if self:GetNWInt("Mode") == 51 then

                                                                                                                                                                                                            else
                                                                                                                                                                                                                if self:GetNWInt("Mode") == 52 then

                                                                                                                                                                                                                else
                                                                                                                                                                                                                    if self:GetNWInt("Mode") == 53 then

                                                                                                                                                                                                                    else
                                                                                                                                                                                                                        if self:GetNWInt("Mode") == 54 then

                                                                                                                                                                                                                        else
                                                                                                                                                                                                                            if self:GetNWInt("Mode") == 55 then

                                                                                                                                                                                                                            else
                                                                                                                                                                                                                                if self:GetNWInt("Mode") == 56 then

                                                                                                                                                                                                                                else
                                                                                                                                                                                                                                    if self:GetNWInt("Mode") == 57 then

                                                                                                                                                                                                                                    else
                                                                                                                                                                                                                                        if self:GetNWInt("Mode") == 58 then

                                                                                                                                                                                                                                        else
                                                                                                                                                                                                                                            if self:GetNWInt("Mode") == 59 then

                                                                                                                                                                                                                                            else
                                                                                                                                                                                                                                                if self:GetNWInt("Mode") == 60 then

                                                                                                                                                                                                                                                else
                                                                                                                                                                                                                                                    if self:GetNWInt("Mode") == 61 then

                                                                                                                                                                                                                                                    else
                                                                                                                                                                                                                                                        if self:GetNWInt("Mode") == 62 then

                                                                                                                                                                                                                                                        else
                                                                                                                                                                                                                                                            if self:GetNWInt("Mode") == 63 then

                                                                                                                                                                                                                                                            else
                                                                                                                                                                                                                                                                if self:GetNWInt("Mode") == 64 then
                                                                                                                                                                                                                                                                end
                                                                                                                                                                                                                                                            end
                                                                                                                                                                                                                                                        end
                                                                                                                                                                                                                                                    end
                                                                                                                                                                                                                                                end
                                                                                                                                                                                                                                            end
                                                                                                                                                                                                                                        end
                                                                                                                                                                                                                                    end
                                                                                                                                                                                                                                end
                                                                                                                                                                                                                            end
                                                                                                                                                                                                                        end
                                                                                                                                                                                                                    end
                                                                                                                                                                                                                end
                                                                                                                                                                                                            end
                                                                                                                                                                                                        end
                                                                                                                                                                                                    end
                                                                                                                                                                                                end
                                                                                                                                                                                            end
                                                                                                                                                                                        end
                                                                                                                                                                                    end
                                                                                                                                                                                end
                                                                                                                                                                            end
                                                                                                                                                                        end
                                                                                                                                                                    end
                                                                                                                                                                end
                                                                                                                                                            end
                                                                                                                                                        end
                                                                                                                                                    end
                                                                                                                                                end
                                                                                                                                            end
                                                                                                                                        end
                                                                                                                                    end
                                                                                                                                end
                                                                                                                            end
                                                                                                                        end
                                                                                                                    end
                                                                                                                end
                                                                                                            end
                                                                                                        end
                                                                                                    end
                                                                                                end
                                                                                            end
                                                                                        end
                                                                                    end
                                                                                end
                                                                            end
                                                                        end
                                                                    end
                                                                end
                                                            end
                                                        end
                                                    end
                                                end
                                            end
                                        end
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end
    end
end
