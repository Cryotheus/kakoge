local PANEL = {}

--panel functions
function PANEL:Init()
	self:SetMouseInputEnabled(true)
end

function PANEL:OnMousePressed(code) return self.CropperStrip:OnMousePressedImage(self, code) end
function PANEL:OnMouseReleased(code) return self.CropperStrip:OnMouseReleasedImage(self, code) end

--post
derma.DefineControl("KakogeCropperImage", "", PANEL, "DImage")