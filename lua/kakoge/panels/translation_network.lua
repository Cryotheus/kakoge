local PANEL = {}

--accessor functions
AccessorFunc(PANEL, "SourceLanguage", "SourceLanguage", FORCE_STRING)
AccessorFunc(PANEL, "TargetLanguage", "TargetLanguage", FORCE_STRING)

--panel functions
function PANEL:AddChain(position)
	local chain = vgui.Create("KakogeTranslationChain", self.Scroller)
	local chains = self.Chains
	
	local chain_count = #chains
	local position = table.insert(chains, position or math.max(chain_count, 1), chain)
	
	chain.Network = self
	
	function chain:OnRemove()
		self.Removing = true
		
		self.Network:RemoveChainInternal(self)
	end
	
	chain:Dock(TOP)
	chain:DockMargin(0, 4, 0, 0)
	
	self:UpdateChains()
end

function PANEL:Init()
	self.Chains = {}
	self.SourceLanguage = "korean"
	self.TargetLanguage = "english"
	
	do --header
		local header = vgui.Create("KakogeTranslationHeader", self)
		
		header:Dock(TOP)
		header.Label:Remove()
		
		function header:PerformLayoutPost(width, height) self.LanguageSizer:DockMargin(4, 0, self.ButtonSizer:GetWide() + self.ButtonMargin * 2, 0) end
		
		do --language selectors
			local sizer = vgui.Create("DSizeToContents", header)
			
			sizer:Dock(TOP)
			
			function sizer:PerformLayout(width, height)
				self:SizeToChildren(false, true)
				
				local new_width, new_height = self:GetSize()
				local new_width_half = math.Round(new_width * 0.5)
				local new_width_remaining = width - new_width_half
				local target_selector = self.TargetSelector
				
				target_selector:SetPos(new_width_half + 4, 0)
				target_selector:SetWide(new_width_remaining - 6)
				self.SourceSelector:DockMargin(4, 0, new_width_remaining + 2, 0)
			end
			
			do --source language selector
				local selector = vgui.Create("KakogeLanguageSelector", sizer)
				selector.IndexingParent = self
				
				selector:Dock(TOP)
				selector:SetValue(self.SourceLanguage)
				
				function selector:OnSelect(index, value, data) self.IndexingParent:SetSourceLanguage(data) end
				
				sizer.SourceSelector = selector
			end
			
			do --target language selector
				local selector = vgui.Create("KakogeLanguageSelector", sizer)
				selector.IndexingParent = self
				
				selector:SetValue(self.TargetLanguage)
				
				function selector:OnSelect(index, value, data) self.IndexingParent:SetTargetLanguage(data) end
				
				sizer.TargetSelector = selector
			end
			
			header.LanguageSizer = sizer
		end
		
		do --add button
			local button = header:AddButton("add", "Add Translation Chain")
			button.IndexingParent = self
			
			function button:DoClick()
				self.IndexingParent:AddChain()
			end
		end
		
		self.Header = header
	end
	
	do --scroller
		local scroller = vgui.Create("DScrollPanel", self)
		
		scroller:Dock(FILL)
		
		function scroller:Paint(width, height)
			surface.SetDrawColor(0, 0, 0, 24)
			surface.DrawRect(0, 0, width, height)
		end
		
		self.Scroller = scroller
	end
end

function PANEL:RemoveChainInternal(chain)
	if self.Removing then return end
	
	local chains = self.Chains
	
	for index, stored_chain in ipairs(chains) do
		if chain == stored_chain then
			table.remove(chains, index)
			
			self:UpdateChains()
			
			break
		end
	end
end

function PANEL:Paint(width, height) end
function PANEL:PerformLayout(width, height) end

function PANEL:SetSourceLanguage(source_language)
	local source_language = string.lower(tostring(source_language))
	self.SourceLanguage = source_language
	
	self:UpdateChains()
end

function PANEL:SetTargetLanguage(target_language)
	local target_language = string.lower(tostring(target_language))
	self.TargetLanguage = target_language
	
	self:UpdateChains()
end

function PANEL:UpdateChains()
	local chains = self.Chains
	local chain_count = #chains
	local source_language = self.SourceLanguage
	local target_language = self.TargetLanguage
	
	for index, chain in ipairs(chains) do
		chain:SetZPos(index)
		
		if source_language then chain:SetSourceLanguage(source_language) end
		if target_language then chain:SetTargetLanguage(target_language) end
	end
end

--post
derma.DefineControl("KakogeTranslationNetwork", "Contains a modifiable list of KakogeTranslationChain panels.", PANEL, "DPanel")

--autoreload
local found_panel

repeat
	found_panel = vgui.GetWorldPanel():Find("KakogeTranslationNetwork")
	
	if IsValid(found_panel) then
		local parent = found_panel:GetParent()
		local x, y, width, height = found_panel:GetBounds()
		
		found_panel:Remove()
		
		local new_panel = vgui.Create("KakogeTranslationNetwork", parent)
		parent.TranslationChain = new_panel
		
		new_panel:SetPos(x, y)
		new_panel:SetSize(width, height)
	end
until not IsValid(found_panel)