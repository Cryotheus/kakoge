local PANEL = {}

--panel functions
function PANEL:Init()
	self.PerformLayoutX = self.PerformLayout
	
	self:SetDraggable(true)
	self:SetMinimumSize(ScrW() * 0.2, ScrH() * 0.2)
	self:SetSizable(true)
	self:SetTitle("Kakoge")
	
	--shop
	do
		local download_shop = vgui.Create("KakogeDownloadShop", self)
		
		download_shop:Dock(FILL)
	end
	
	--detours are great
	function self:PerformLayout(...)
		self:PerformLayoutX(...)
		self:PerformLayoutPost(...)
	end
end

function PANEL:PerformLayoutPost(width, height)
	
end

--post
derma.DefineControl("KakogeHome", "", PANEL, "DFrame")