local color_palor_white = Color(222, 222, 223)
local PANEL = {}

--accessor functions
AccessorFunc(PANEL, "ButtonMargin", "ButtonMargin", FORCE_NUMBER)

--panel functions
function PANEL:AddButton(icon, tip)
	local button = vgui.Create("KakogeIconButton", self.ButtonSizer)
	
	button:Dock(LEFT)
	button:DockMargin(0, 0, self.ButtonMargin, 0)
	button:SetIcon(icon)
	button:SetTooltip(tip)
	
	return button
end

function PANEL:Init()
	self.ButtonMargin = 2
	
	do --button sizer
		local sizer = vgui.Create("DSizeToContents", self)
		
		sizer:SetTall(16)
		sizer:SetZPos(2)
		
		function sizer:PerformLayout(width, height) self:SizeToChildren(true, false) end
		
		self.ButtonSizer = sizer
	end
	
	do --label
		local label = vgui.Create("DButton", self)
		
		label:Dock(TOP)
		label:DockMargin(4, 0, 0, 0)
		label:SetAutoStretchVertical(true)
		label:SetContentAlignment(4)
		label:SetFont("Trebuchet24")
		label:SetMouseInputEnabled(false)
		label:SetPaintBackground(false)
		label:SetText("Language")
		label:SetTextColor(color_palor_white)
		
		self.Label = label
	end
end

function PANEL:Paint(width, height)
	surface.SetDrawColor(0, 0, 0, 64)
	surface.DrawRect(0, 0, width, height)
end

function PANEL:PerformLayout(width, height)
	self:SizeToChildren(false, true)
	
	local new_width, new_height = self:GetSize()
	local sizer = self.ButtonSizer
	local sizer_width, sizer_height = sizer:GetSize()
	
	sizer:SetPos(new_width - sizer_width - self.ButtonMargin, (height - sizer_height) * 0.5)
	
	self:PerformLayoutPost(new_width, new_height)
end

function PANEL:PerformLayoutPost(width, height) end
function PANEL:SetIcon(...) return self.Label:SetIcon(...) end
function PANEL:SetText(...) return self.Label:SetText(...) end

--post
derma.DefineControl("KakogeTranslationHeader", "Tool bar used by KakogeTranslationBlock and KakogeTranslationChain", PANEL, "DSizeToContents")