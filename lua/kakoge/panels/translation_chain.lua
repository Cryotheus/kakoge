local PANEL = {}

--accessor functions
AccessorFunc(PANEL, "SourceLanguage", "SourceLanguage", FORCE_STRING)
AccessorFunc(PANEL, "TargetLanguage", "TargetLanguage", FORCE_STRING)

--panel functions
function PANEL:AddBlock(target_language, position)
	local block = vgui.Create("KakogeTranslationBlock", self)
	local blocks = self.Blocks
	
	local block_count = #blocks
	local position = table.insert(blocks, position or math.max(block_count, 1), block)
	local previous_block = blocks[position - 1]
	local source_language = previous_block and previous_block:GetTargetLanguage()
	local target_language = target_language or self.TargetLanguage --can be nil
	
	block.Chain = self
	
	block:Dock(TOP)
	block:SetEditable(position < block_count)
	block:SetZPos(position)
	
	function block:OnLanguageSelected(target_language) self.Chain:UpdateBlocks() end
	function block:OnRemove() self.Chain:RemoveBlockInternal(self) end
	
	if source_language then block:SetSourceLanguage(source_language) end
	if target_language then block:SetTargetLanguage(target_language) end
	
	--haha over compensating function goes brrrrrrr
	self:UpdateBlocks()
	
	return block
end

function PANEL:Clear()
	local blocks = self.Blocks
	
	for index, block in ipairs(blocks) do
		block:Remove()
		
		blocks[index] = nil
	end
end

function PANEL:Init()
	local blocks = {}
	
	self.Blocks = blocks
	
	do --header
		local header = vgui.Create("KakogeTranslationHeader", self)
		
		header:Dock(TOP)
		header:DockMargin(0, 0, 0, 2)
		header:SetZPos(0)
		
		do --button
			local button = header:AddButton("add", "Add Translation Block")
			button.IndexingParent = self
			
			function button:DoClick() self.IndexingParent:AddBlock() end
		end
		
		self.Header = header
	end
	
	do --primary block
		local block = self:AddBlock()
		--more?
	end
end

function PANEL:OnRemove() self.Removing = true end

function PANEL:Paint(width, height)
	surface.SetDrawColor(0, 0, 0, 64)
	surface.DrawRect(0, 0, width, height)
end

function PANEL:RemoveBlockInternal(block)
	if self.Removing then return end
	
	local blocks = self.Blocks
	
	if #blocks <= 1 then return self:Remove() end
	
	for index, stored_block in ipairs(blocks) do
		if block == stored_block then
			table.remove(blocks, index)
			
			self:UpdateBlocks()
			
			break
		end
	end
end

function PANEL:SetSourceLanguage(source_language)
	local blocks = self.Blocks
	local first_block = blocks[#blocks]
	local header = self.Header
	local source_language = string.lower(tostring(source_language))
	local source_language_flag = KAKOGE.LanguageFlags[source_language]
	
	self.SourceLanguage = source_language
	
	first_block:SetSourceLanguage(source_language)
	header:SetIcon(source_language_flag and "flags16/" .. source_language_flag .. ".png" or nil)
	header:SetText(string.upper(source_language))
	self:UpdateBlocks()
end

function PANEL:SetTargetLanguage(target_language)
	local blocks = self.Blocks
	local first_block = blocks[#blocks]
	local target_language = string.lower(tostring(target_language))
	
	self.TargetLanguage = target_language
	
	first_block:SetTargetLanguage(target_language)
	self:UpdateBlocks()
end

function PANEL:UpdateBlocks()
	local blocks = self.Blocks
	local block_count = #blocks
	local source_language = self.SourceLanguage
	
	for index, block in ipairs(blocks) do
		local target_language = block:GetTargetLanguage()
		
		block:SetEditable(index < block_count)
		block:SetZPos(index)
		
		block:SetSourceLanguage(source_language)
		block:SetTargetLanguage(target_language) --this will update the list
		
		source_language = target_language
	end
end

--post
derma.DefineControl("KakogeTranslationChain", "Holds a list of TranslationBlock panels.", PANEL, "DSizeToContents")