local PANEL = {}

--accessor functions
AccessorFunc(PANEL, "Text", "DrawnText", FORCE_STRING)
AccessorFunc(PANEL, "FractionHeight", "FractionHeight", FORCE_NUMBER)
AccessorFunc(PANEL, "FractionWidth", "FractionWidth", FORCE_NUMBER)
AccessorFunc(PANEL, "FractionX", "FractionX", FORCE_NUMBER)
AccessorFunc(PANEL, "FractionY", "FractionY", FORCE_NUMBER)

--panel functions
function PANEL:Init()
	self:SetText("")
	
	self.FractionWidth, self.FractionHeight = 0.5, 0.5
	self.FractionX, self.FractionY = 0.25, 0.25
	self.SetText = self.SetDrawnText
	self.Text = ""
end

function PANEL:Paint(width, height)
	local modulo = math.floor(RealTime() % 2)
	local outline = modulo * 32
	
	if self.Depressed or self:IsSelected() or self:GetToggle() then surface.SetDrawColor(255, 255, 255, 224)
	elseif self:GetDisabled() then surface.SetDrawColor(255, 255, 255, 0)
	elseif self.Hovered then surface.SetDrawColor(122, 159, 209, 192)
	else surface.SetDrawColor(255, 255, 255, 32 * modulo + 32) end
	
	surface.DrawRect(0, 0, width, height)
	
	surface.SetDrawColor(outline, outline, outline)
	surface.DrawOutlinedRect(0, 0, width, height, 2)
	
	draw.SimpleTextOutlined(self.Text, self:GetFont(), width * 0.5, height * 0.5, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 1, color_black)
end

function PANEL:ScaleToPanel(panel, width, height)
	local panel = panel or self:GetParent()
	
	local width = width or panel:GetWide()
	local height = height or panel:GetTall()
	
	self:SetPos(self.FractionX * width, self.FractionY * height)
	self:SetSize(self.FractionWidth * width, self.FractionHeight * height)
end

function PANEL:SetFractionBounds(fraction_x, fraction_y, fraction_width, fraction_height, adjust_self)
	self:SetFractionPos(fraction_x, fraction_y)
	self:SetFractionSize(fraction_width, fraction_height)
	
	if adjust_self then self:ScaleToPanel(ispanel(adjust_self) and adjust_self or nil) end
end

function PANEL:SetFractionSize(fraction_width, fraction_height, adjust_self)
	self:SetFractionHeight(fraction_height)
	self:SetFractionWidth(fraction_width)
	
	if adjust_self then self:ScaleToPanel(ispanel(adjust_self) and adjust_self or nil) end
end

function PANEL:SetFractionPos(fraction_x, fraction_y, adjust_self)
	self:SetFractionX(fraction_x)
	self:SetFractionY(fraction_y)
	
	if adjust_self then self:ScaleToPanel(ispanel(adjust_self) and adjust_self or nil) end
end

--post
derma.DefineControl("KakogeCropperAnnotation", "DButton specialized for a KakogeCropperStrip panel.", PANEL, "DButton")