EFFECT.Mat = Material( "effects/tool_tracer" )

function EFFECT:Init( data )

	self.Position = data:GetStart()
	self.WeaponEnt = data:GetEntity()
	self.Attachment = data:GetAttachment()

	self.StartPos = self:GetTracerShootPos( self.Position, self.WeaponEnt, self.Attachment )
	self.EndPos = data:GetOrigin()

	self.Alpha = 255
	self.Life = 0

	self:SetRenderBoundsWS( self.StartPos, self.EndPos )

end

function EFFECT:Think()

	self.Life = self.Life + FrameTime() * 4
	self.Alpha = 255 * ( 1 - self.Life )

	return self.Life < 1

end

function EFFECT:Render()

    local cyan = Color(0, 255, 255)
    local cyan2 = Color(0, 255, 255, 255)

	 if self.Alpha < 1 then return end

            render.SetMaterial(self.Mat)

            local startPos, endPos = self.StartPos, self.EndPos
            local life = self.Life

            local norm = (startPos - endPos) * life
            local len = norm:Length()

            local texcoord = math.Rand(0,1)

            for i=1,3 do
                render.DrawBeam(startPos - norm,endPos,8,texcoord,texcoord + len / 128,cyan)
            end

            cyan2.a = 128 * (1 - life)

            render.DrawBeam(startPos,endPos,8,texcoord,texcoord + ((startPos - endPos):Length() / 128),cyan2)
end
