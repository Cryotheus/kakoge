local color_palor_blue = Color(122, 159, 209)
local color_palor_white = Color(222, 222, 223)
local PANEL = {}

--accessor functions
AccessorFunc(PANEL, "Value", "Value", FORCE_STRING)

--panel functions
function PANEL:Init()
	local first = true
	local flags = KAKOGE.LanguageFlags
	
	for index, language_name in ipairs(KAKOGE.LanguagesAvailable) do
		self:AddChoice(string.upper(language_name), language_name, index == 1, "flags16/" .. flags[language_name] .. ".png")
	end
end

function PANEL:Paint(width, height)
	self:PaintBackground(width, height)
	
	if self.Depressed or self:IsSelected() or self:GetToggle() then self:SetTextColor(color_white)
	elseif self:GetDisabled() then self:SetTextColor(color_black)
	elseif self.Hovered then self:SetTextColor(color_palor_blue)
	else self:SetTextColor(color_palor_white) end
end

function PANEL:PaintBackground(width, height) end

function PANEL:SetValue(value)
	local value = string.lower(tostring(value))
	local flag = KAKOGE.LanguageFlags[value]
	self.Value = value
	
	self:SetIcon(flag and "flags16/" .. flag .. ".png" or nil)
	self:SetText(string.upper(value))
end

--post
derma.DefineControl("KakogeLanguageSelector", "DComboBox with all of Kakoge's available languages.", PANEL, "DComboBox")