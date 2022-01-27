local PANEL = {}

--panel functions
function PANEL:Init()
	self.m_Image:SetPaintedManually(true)
	
	self:SetText("")
	self:SetSize(16, 16)
end

function PANEL:Paint(width, height)
	if self.Depressed or self:IsSelected() or self:GetToggle() then
		surface.SetDrawColor(255, 255, 255, 64)
		surface.DrawRect(0, 0, width, height)
		
		self:PaintIcon(width, height)
	elseif self:GetDisabled() then
		--dead
		self:PaintIcon(width, height)
	elseif self.Hovered then
		self:PaintIcon(width, height)
		
		surface.SetDrawColor(255, 255, 255, 32)
		surface.DrawRect(0, 0, width, height)
	else self:PaintIcon(width, height) end
end

function PANEL:PaintIcon(width, height) self.m_Image:PaintAt(0, 0, width, height) end

function PANEL:SetFlag(flag) self:SetMaterial("flags16/" .. flag .. ".png") end
function PANEL:SetIcon(icon) self:SetMaterial("icon16/" .. icon .. ".png") end

--post
derma.DefineControl("KakogeIconButton", "", PANEL, "DImageButton")