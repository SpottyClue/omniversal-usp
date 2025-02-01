local e = FindMetaTable("Entity")

local Remove = e.Remove
local TakeDamageInfo = e.TakeDamageInfo
local GetClass = e.GetClass
local NextThink = e.NextThink
local Input = e.Input

SWEP.Author = "1999"
SWEP.Category = "1999's Weapons (Admin)"
SWEP.PrintName = "Omniversal USP"
SWEP.Instructions = ""
SWEP.Purpose = "Kill."

SWEP.Spawnable = true
SWEP.AdminSpawnable = true
SWEP.AdminOnly = true

SWEP.UseHands = true

SWEP.ViewModelFOV = 54
SWEP.ViewModel			= "models/weapons/kusp/v_kimonousp1.mdl"
SWEP.WorldModel			= "models/weapons/kusp/w_kimonousp1.mdl"

SWEP.Secondary.ClipSize		= -1
SWEP.Secondary.DefaultClip	= -1
SWEP.Secondary.Automatic	= true
SWEP.Secondary.Ammo		= ""

SWEP.Slot = 1
SWEP.SlotPos = 1

SWEP.Primary.Sound = Sound("weapons/kimonousp_unsil-1.wav")
SWEP.Primary.DefaultClip = 256
SWEP.Primary.ClipSize = 15
SWEP.Primary.Automatic = true
SWEP.Primary.Ammo		= "pistol"

SWEP.DrawCrosshair = true

SWEP.AutoSwitchTo = true
SWEP.AutoSwitchFrom = true

local function OwnerKillFeed(v,self)
    net.Start('PlayerKilledNPC')
    net.WriteString(v:GetClass())
    net.WriteString('omniversal_revolver')
    net.WriteEntity(self.Owner)
    net.Broadcast()
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
		local r = math.random
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
-----------------------------------------------------------------------------
local function Attack(v,self) 
   
   local ply = self:GetOwner()
							 
     if SERVER then		

          local hitpos = ents.FindAlongRay(ply:GetShootPos(), ply:GetEyeTrace().HitPos, Vector(-15,-15,-15), Vector(15,15,15))
		  
          for k,v in pairs(hitpos) do								 
								 
               if v~=self.Owner then
			   
			        if (v:IsPlayer() and v:Alive()) then
					    v:Kill()						
					end		
					
					if v:GetClass()=="bullseye_strider_focus" then return false end
						 
						 if v:IsNPC() or type(v)=="NextBot" and v:IsValid() then
						     
							 CreateEntityRagdoll(v, ply, skin, self)
							 
						     v.AcceptInput = function() return false end
	                         v.OnRemove = function(self,...) self:Remove() return end
	                         v.CustomThink = function(self,...) self:Remove() return end
	                         v.Think = function(self,...) self:Remove() return end
						 
						     NextThink(v, CurTime() + 3 )						
							 
                             Input(v, "Kill")
							 Remove(v)		
							 v:SetNoDraw(false)	
							 OwnerKillFeed(v,self)							
						     --RunConsoleCommand("ent_remove") 		 
                    end					 
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

            if v:IsNPC() or type(v) == "NextBot" and v:IsValid() then
                v.AcceptInput = function() return false end
	            v.OnRemove = function(self,...) self:Remove() return end
	            v.CustomThink = function(self,...) self:Remove() return end
	            v.Think = function(self,...) self:Remove() return end
				
                NextThink(v, CurTime() + 3)
                Input(v, "Kill")
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

            if v:IsNPC() or type(v) == "NextBot" and v:IsValid() then
			
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
				
				if v:IsValid() then
				    Input(v, "SelfDestruct")
				end
				
				if v:GetClass()=="npc_rollermine" or v:GetClass()=="npc_combinedropship" or v:GetClass()=="npc_combinegunship" then
				   Remove(v)
				   OwnerKillFeed(v,self)
				end
				
				self:EmitSound(Sound(self.Primary.Sound),75,100,0.5,CHAN_VOICE_BASE)
				self:ShootEffects()
				self:SetNextSecondaryFire(CurTime() + 0.1)
            end
        end
    end
end

local function DealDamageEnhanced(v,self)
     
	local dforce = self.Owner:GetAimVector()*1e9
    local hitpos = ents.FindAlongRay(self.Owner:GetShootPos(), self.Owner:GetEyeTrace().HitPos, Vector(-15, -15, -15), Vector(15, 15, 15))

    for k, v in pairs(hitpos) do
        if v ~= self.Owner then
            if (v:IsPlayer() and v:Alive() and v:HasGodMode()) then
                v:Kill()
            end

            if v:IsNPC() or type(v) == "NextBot" and v:IsValid() then
			
                v.AcceptInput = function() return false end
	            v.OnRemove = function(self,...) self:Remove() return end
				v.OnTakeDamage = function(self,...) self:Remove() return end
				v.OnTraceAttack = function(self,...) self:Remove() return end
	            v.CustomThink = function(self,...) self:Remove() return end
	            v.Think = function(self,...) self:Remove() return end
								
				local d = DamageInfo()
                d:AddDamage(math.huge)
                d:SetDamage(math.huge)
                d:SetDamageBonus(math.huge)
                d:SetDamageType(bit.bor(DMG_AIRBOAT,DMG_BLAST,DMG_NEVERGIB,DMG_DIRECT,DMG_BURN))
                d:SetDamageForce(dforce)
                d:SetAttacker(self.Owner)
                d:SetInflictor(self.Owner)
                v:TakeDamageInfo(d)
				
				
				v:TakeDamage(math.huge,self.Owner,self.Owner)				
				v:SetHealth(0)
				
				if v:GetClass()=="npc_rollermine" or v:GetClass()=="npc_combinedropship" or v:GetClass()=="npc_combinegunship" or v:GetClass()=="npc_turret_floor_resistance" or v:GetClass()=="npc_turret_floor" then
				   Remove(v)
				   OwnerKillFeed(v,self)
				end
				
				self:EmitSound(Sound(self.Primary.Sound),75,100,0.5,CHAN_VOICE_BASE)
				self:ShootEffects()
				self:SetNextSecondaryFire(CurTime() + 0.1)
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
				self.Secondary.Automatic = false
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
				self.Secondary.Automatic = false
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
				self.Secondary.Automatic = false
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
				self.Secondary.Automatic = false
				self:SetNextSecondaryFire(CurTime() + 0.1)
				
            end
        end
    end
end

local function DissolveAll(v,self)

    for k, v in pairs(ents.GetAll()) do
        if v ~= self.Owner then
		
            if v:GetClass()~="predicted_viewmodel" and not(v:IsWeapon() and v:GetOwner()==self.Owner) and v:GetClass()~="gmod_hands" then
			
			    if !IsValid() then
			    
				    if v:IsFlagSet(FL_DISSOLVING)==true then
				        return false
				    end
			    
				    NextThink(v, CurTime() + 5 )
				    v:Dissolve(math.random(0,3))
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
			
		    if v:IsNPC() or type(v) == "NextBot" and v:IsValid() then

               if v:GetClass()=="bullseye_strider_focus" or v:GetClass()=="omni_rev" then return false end
			   
			   Input(v,"Kill")
			   Remove(v)
			   RunConsoleCommand("ent_remove")
			   
		       local ef = EffectData()
	           ef:SetOrigin(v:GetPos())
	           ef:SetStart(ply:GetShootPos())
	           ef:SetAttachment(1)
	           ef:SetEntity(self)
	           util.Effect("ToolTracer", ef)

			   CreateEntityRagdoll(v, ply, skin, self)
			   OwnerKillFeed(v,self)
			   
			   self:ShootEffects()
			   self:EmitSound(Sound(self.Primary.Sound))
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
				self:EmitSound(Sound(self.Primary.Sound))
		
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
				self:EmitSound(Sound(self.Primary.Sound))
		
				local EF = EffectData()
				EF:SetOrigin(ply:GetEyeTrace().HitPos)
				EF:SetStart(ply:GetShootPos())
				EF:SetAttachment(1)
				EF:SetEntity(self)
				util.Effect("ToolTracer", EF)
			end
end

local function Timestop(v,self)

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
			
				    NextThink(v, CurTime() + 1e9 )
					Input(v, "Kill")
										
					net.Start('PlayerKilledNPC')
                    net.WriteString(v:GetClass())
                    net.WriteString('omni_rev')
                    net.WriteEntity(self.Owner)
                    net.Broadcast()
					
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
			   self:EmitSound(Sound(self.Primary.Sound),75,100,0.5,CHAN_VOICE_BASE)
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

			for k,v in pairs(ents.FindInSphere(hit, 250)) do
                if v~=self.Owner then					
				    if v:IsNPC() or v:IsNextBot() and v:IsValid() then
					Input(v, "Kill")
					Remove(v)
					CreateEntityRagdoll(v, ply, skin, self)
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
                if v~=self.Owner then					
				    if v:IsNPC() or v:IsNextBot() and v:IsValid() then
					Input(v, "Kill")
					Remove(v)
					CreateEntityRagdoll(v, ply, skin, self)
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
        r:SetAngles(Angle(math.random(1, 30), math.random(1, 60), math.random(1, 90)))
        r:SetOwner(self.Owner)
        r:Spawn()
        r:SetCollisionGroup(20)

        r:CallOnRemove(
            "killNearExplosion",
            function()
                for k, v in pairs(ents.FindInSphere(r:GetPos(), 300)) do
                    if v:IsNPC() or v:IsNextBot() then
                        local ef = EffectData()
                        ef:SetOrigin(v:GetPos())
                        util.Effect("Explosion", ef)
                        Attack(v, self)
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
        self:EmitSound(Sound(self.Primary.Sound),75,100,0.5,CHAN_VOICE_BASE)
    end
end

local function Mingebags(v, self)
    local m = ents.Create("prop_physics")
    if IsValid(m) then
        m:SetModel("models/Kleiner.mdl")
        m:SetPos(self.Owner:GetShootPos())
        m:SetOwner(self.Owner)
        m:Spawn()
        m:SetCollisionGroup(20)

        m:CallOnRemove(
            "killNearExplosion",
            function()
                for k, v in pairs(ents.FindInSphere(m:GetPos(), 300)) do
                    if v:IsNPC() or v:IsNextBot() then					
                        Attack(v, self)
						v:Dissolve(3)
						Ignite( v, 3 )
                    end
                end
            end
        )

        local function PhysCallback(e, d)
            if SERVER then
			local ent =  ents.Create ("prop_combine_ball")
			      ent:SetPos( m:GetPos() ) 
			      ent:SetOwner( m ) 
			      ent:Spawn() 
			      ent:Fire("Explode", 1, 0 ) 						
			end
            e:Remove()
        end
        m:AddCallback("PhysicsCollide", PhysCallback)

        local phys = m:GetPhysicsObject()
        phys:SetVelocity(self.Owner:GetAimVector() * 10000)

        self:SendWeaponAnim(ACT_VM_PRIMARYATTACK)
        self:SetNextSecondaryFire(CurTime() + 0.05)
        self:EmitSound(Sound(self.Primary.Sound),75,100,0.5,CHAN_VOICE_BASE)
    end
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
    
	for k,p in pairs(ents.FindByClass("prop_*")) do
	    if IsValid(p) and not SERVER then
		    p:Remove()
		end
	end
	
    for k, v in pairs(ents.GetAll()) do		
	
            if v:IsNPC() or v:IsNextBot() and v:IsValid() then		
			
			        v.AcceptInput = function() return false end
	                v.OnRemove = function(self,...) self:Remove() return end
	                v.CustomThink = function(self,...) self:Remove() return end
	                v.Think = function(self,...) self:Remove() return end
					
					Remove(v)					
												
					net.Start("NPCKilledNPC")
					net.WriteString(v:GetClass())
					net.WriteString(v:GetClass())
					net.WriteString(v:GetClass())
					net.Broadcast()
					
					self:EmitSound(Sound(self.Primary.Sound),75,100,0.5,CHAN_VOICE_BASE)
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
					
					self:EmitSound(Sound(self.Primary.Sound),75,100,0.5,CHAN_VOICE_BASE)
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
										
					if v:IsValid() then
					    RunConsoleCommand("hacker_removeall")
					end
										
					net.Start("NPCKilledNPC")
					net.WriteString(v:GetClass())
					net.WriteString(v:GetClass())
					net.WriteString(v:GetClass())
					net.Broadcast()
					
					self:EmitSound(Sound(self.Primary.Sound),75,100,0.5,CHAN_VOICE_BASE)
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
					
			self:EmitSound(Sound(self.Primary.Sound),75,100,0.5,CHAN_VOICE_BASE)
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
			
			    self:EmitSound(Sound(self.Primary.Sound),75,100,0.5,CHAN_VOICE_BASE)
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
			
			    self:EmitSound(Sound(self.Primary.Sound),75,100,0.5,CHAN_VOICE_BASE)
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
			if ( v:IsPlayer() and v:Alive() ) and not e:GetOwner()==self.Owner then
				v:Lock()			
				self:EmitSound(Sound(self.Primary.Sound),75,100,0.5,CHAN_VOICE_BASE)
			    self.Weapon:EmitSound("common/warning.wav",75,100,1,CHAN_WEAPON)
			    self:ShootEffects()
			    self.Secondary.Automatic = false
			    self:SetNextSecondaryFire(CurTime() + 0.1)			
				else 
				if ( v:IsPlayer() and v:Alive() and not e:GetOwner()==self.Owner ) and v:Lock()==true then
				    v:UnLock()
				    self:EmitSound(Sound(self.Primary.Sound),75,100,0.5,CHAN_VOICE_BASE)
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
			if ( v:IsPlayer() and v:Alive() and v:Freeze(false) ) and not e:GetOwner()==self.Owner then
				v:Freeze(true)			
				self:EmitSound(Sound(self.Primary.Sound),75,100,0.5,CHAN_VOICE_BASE)
			    self.Weapon:EmitSound("common/warning.wav",75,100,1,CHAN_WEAPON)
			    self:ShootEffects()
			    self.Secondary.Automatic = false
			    self:SetNextSecondaryFire(CurTime() + 0.1)			
				else 
				if ( v:IsPlayer() and v:Alive() and not e:GetOwner()==self.Owner ) and v:Freeze(true) then
				    v:Freeze(false)
				    self:EmitSound(Sound(self.Primary.Sound),75,100,0.5,CHAN_VOICE_BASE)
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
			if ( v:IsPlayer() ) and not e:GetOwner()==self.Owner then
				v:Ban( 1440, true )
				self.Owner:PrintMessage( HUD_PRINTTALK, "Banned player"..v:GetClass().."for a day.")
				self:EmitSound(Sound(self.Primary.Sound),75,100,0.5,CHAN_VOICE_BASE)
			    self.Weapon:EmitSound("common/warning.wav",75,100,1,CHAN_WEAPON)
			    self:ShootEffects()
			    self.Secondary.Automatic = false
			    self:SetNextSecondaryFire(CurTime() + 0.1)
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
		{"Mingebags", "", "19"},
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
        {}
    }

    local s = {500, 600}
    if CLIENT then
        if self.Owner:KeyDown(IN_RELOAD) and self.menu1 == nil then
		    self:EmitSound("buttons/button9.wav",75,100,0.5,CHAN_VOICE_BASE)
            self.menu1 = vgui.Create("DFrame")
            self.menu1:SetPos(ScrW() / 2 - s[1] / 2, ScrH() / 2 - s[2] / 2, 0.001, 0, 0.001)
            self.menu1:SetSize(s[1], s[2])
            self.menu1:SetTitle("Omniversal USP - Fire Modes")
            self.menu1:SetVisible(true)
            self.menu1:SetDraggable(true)
            self.menu1:ShowCloseButton(false)
            gui.EnableScreenClicker(true)

            local scrollPanel = vgui.Create("DScrollPanel", self.menu1)
            scrollPanel:SetSize(400, 500)
            scrollPanel:SetPos(10, 40)
			
            for i = 1, 29 do
                local button = vgui.Create("DButton", scrollPanel)
                button:SetSize(200, s[2] / 8 - 50)
                button:SetPos(140, ((i - 1) * s[2] / 16 - 25) + 50)
                button:SetText(labels[i][1])
                button.DoClick = function()
                    local num = tonumber(labels[i][3])
                    net.Start("omniusp")
                    net.WriteInt(num, 8)
                    net.SendToServer()
                    self.menu1:Close()
                    self.menu1 = nil
                    gui.EnableScreenClicker(false)
					self:EmitSound("Weapon_IRifle.Empty",75,100,0.5,CHAN_VOICE_BASE)
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
end

function SWEP:DrawWorldModel()
    if !IsValid(self.Owner) then
        self:DrawModel()
        return
    end

    local id = self.Owner:LookupAttachment("anim_attachment_rh")
    local att = self.Owner:GetAttachment(id)
    local vec1 = Vector(-3, 0.5, -0.1)
    local ang1 = Angle(0, 0, 0)

    if !att then return end
    local pos = att.Pos + att.Ang:Forward() * vec1.x + att.Ang:Right() * vec1.y + att.Ang:Up() * vec1.z
    local ang = att.Ang

    ang:RotateAroundAxis(att.Ang:Up(), ang1.p)
    ang:RotateAroundAxis(att.Ang:Forward(), ang1.r)
    ang:RotateAroundAxis(att.Ang:Right(), ang1.y)
    self:SetRenderOrigin(pos)
    self:SetRenderAngles(ang)

    self:DrawModel()
end

function SWEP:FireAnimationEvent(pos,ang,event,options)
    return true
end

function SWEP:Initialize()
    self:SetWeaponHoldType("pistol")
	if SERVER then
        util.AddNetworkString("omniusp")
    end
end

function SWEP:Deploy()
    self.Owner:AddFlags(32768)
	self:SendWeaponAnim(ACT_VM_DRAW)
	return true
end

function SWEP:Holster()
    self.Owner:RemoveFlags(32768)
	return true
end

function SWEP:PrimaryAttack()
    Attack(e,self)
    self:ShootEffects()
	self:SetNextPrimaryFire(CurTime() + 0.01)
    self.Weapon:EmitSound(Sound(self.Primary.Sound), 75, 100, 0.5, CHAN_AUTO)
    self:ShootBullet(0, 10, 0.0035, "pistol", 1e9)
    local ply = self:GetOwner()
    ply:LagCompensation(false)
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
                                                                                Mingebags(v, self)
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

                                                                                                                    else
                                                                                                                        if self:GetNWInt("Mode") == 30 then

                                                                                                                        else
                                                                                                                            if self:GetNWInt("Mode") == 31 then

                                                                                                                            else
                                                                                                                                if self:GetNWInt("Mode") == 32 then

                                                                                                                                else
                                                                                                                                    if self:GetNWInt("Mode") == 33 then

                                                                                                                                    else
                                                                                                                                        if self:GetNWInt("Mode") == 34 then

                                                                                                                                        else
                                                                                                                                            if self:GetNWInt("Mode") == 35 then

                                                                                                                                            else
                                                                                                                                                if self:GetNWInt("Mode") == 36 then

                                                                                                                                                else
                                                                                                                                                    if self:GetNWInt("Mode") == 37 then

                                                                                                                                                    else
                                                                                                                                                        if self:GetNWInt("Mode") == 38 then

                                                                                                                                                        else
                                                                                                                                                            if self:GetNWInt("Mode") == 39 then

                                                                                                                                                            else
                                                                                                                                                                if self:GetNWInt("Mode") == 40 then

                                                                                                                                                                else
                                                                                                                                                                    if self:GetNWInt("Mode") == 41 then

                                                                                                                                                                    else
                                                                                                                                                                        if self:GetNWInt("Mode") == 42 then

                                                                                                                                                                        else
                                                                                                                                                                            if self:GetNWInt("Mode") == 43 then

                                                                                                                                                                            else
                                                                                                                                                                                if self:GetNWInt("Mode") == 44 then

                                                                                                                                                                                else
                                                                                                                                                                                    if self:GetNWInt("Mode") == 45 then

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
