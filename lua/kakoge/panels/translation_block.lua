local PANEL = {}

--accessor functions
AccessorFunc(PANEL, "Editable", "Editable", FORCE_BOOL)
AccessorFunc(PANEL, "SourceLanguage", "SourceLanguage", FORCE_STRING)
AccessorFunc(PANEL, "TargetLanguage", "TargetLanguage", FORCE_STRING)

--panel functions
function PANEL:AddService(index, service)
	local sizer = vgui.Create("DSizeToContents", self)
	
	sizer:Dock(TOP)
	sizer:DockMargin(0, 0, 0, 2)
	sizer:SetZPos(index)
	
	function sizer:PerformLayout(width, height) self:SizeToChildren(false, true) end
	
	do --check box
		local check_box = vgui.Create("DCheckBox", sizer)
		check_box.IndexingParent = self
		
		check_box:SetPos(2, 0)
		
		if self.EnabledServices[service] then check_box:SetValue(true) end
		
		function check_box:OnChange(value) self.IndexingParent.EnabledServices[service] = value or nil end
		
		sizer.CheckBox = check_box
	end
	
	do --label
		local label = vgui.Create("DLabel", sizer)
		
		label:Dock(TOP)
		label:DockMargin(19, 0, 0, 0)
		label:SetAutoStretchVertical(true)
		label:SetText(service)
		
		sizer.Label = label
	end
	
	table.insert(self.ServicePanels, sizer)
end

function PANEL:Init()
	self.EnabledServices = {}
	self.ServicePanels = {}
	
	do
		local header = vgui.Create("KakogeTranslationHeader", self)
		
		header:Dock(TOP)
		header:SetZPos(32767)
		
		function header:PerformLayoutPost(width, height) self.LanguageSelector:DockMargin(4, 0, self.ButtonSizer:GetWide() + self.ButtonMargin * 2, 0) end
		
		if false then --edit button
			local button = header:AddButton("pencil", "Edit Block Services")
			button.IndexingParent = self
			
			function button:DoClick()
				local parent = self.IndexingParent
				
				parent:SetEditable(not parent:GetEditable())
			end
		end
		
		do --delete button
			local button = header:AddButton("delete", "Delete Block")
			button.IndexingParent = self
			
			function button:DoClick() Derma_Query("Delete this block?", "Block Deletion Confirmation", "Yes", function() self.IndexingParent:Remove() end, "No", function() end) end
		end
		
		do --language selector
			local selector = vgui.Create("KakogeLanguageSelector", header)
			selector.IndexingParent = self
			
			selector:Dock(TOP)
			selector:SetFont("Trebuchet24")
			selector:SetVisible(false)
			
			function selector:OnSelect(index, value, data)
				local parent = self.IndexingParent
				
				parent:OnLanguageSelected(parent:SetTargetLanguage(data))
			end
			
			header.LanguageSelector = selector
		end
		
		self.Header = header
	end
end

function PANEL:OnLanguageSelected(target_language) end

function PANEL:SetEditable(state)
	local header = self.Header
	local header_label = header.Label
	local header_selector = header.LanguageSelector
	local state = tobool(state)
	
	header_label:SetVisible(not state)
	header_selector:SetVisible(state)
	
	self.Editable = state
end

function PANEL:SetTargetLanguage(target_language)
	local header = self.Header
	local header_selector = header.LanguageSelector
	local panels = self.ServicePanels
	local source_language = self.SourceLanguage
	local target_language = string.lower(tostring(target_language))
	local target_language_flag = KAKOGE.LanguageFlags[target_language]
	
	self.TargetLanguage = target_language
	
	header:SetIcon(target_language_flag and "flags16/" .. target_language_flag .. ".png" or nil)
	header:SetText(string.upper(target_language))
	header_selector:SetValue(target_language)
	
	for index, panel in ipairs(panels) do
		panel:Remove()
		
		panels[index] = nil
	end
	
	for index, service in ipairs(KAKOGE.LanguagesServices[target_language] or {}) do
		if not source_language or hook.Call("KakogeTranslateGetAvailability", KAKOGE, source_language, service) then
			self:AddService(index, service)
		end
	end
	
	return target_language
end

function PANEL:SetSourceLanguage(source_language) self.SourceLanguage = string.lower(tostring(source_language)) end

--post
derma.DefineControl("KakogeTranslationBlock", "Configurable list of services.", PANEL, "DSizeToContents")