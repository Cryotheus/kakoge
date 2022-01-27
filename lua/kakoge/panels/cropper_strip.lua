local PANEL = {}

--accessor functions
AccessorFunc(PANEL, "Font", "Font", FORCE_STRING)
AccessorFunc(PANEL, "MinimumCropSize", "MinimumCropSize", FORCE_NUMBER)

--local functions
local function get_power(result) return  math.ceil(math.log(result, 2)) end

--post function setup
if not KAKOGE.CropperFontMade then
	surface.CreateFont("KakogeCropper", {
		antialias = false,
		name = "Consolas",
		size = 16,
		weight = 500
	})
	
	KAKOGE.CropperFontMade = true
end

--panel functions
function PANEL:Annotate(x, y, width, height, fractional, z_position)
	local annotation = vgui.Create("KakogeCropperAnnotation", self.AnnotationPanel)
	local z_position = z_position or self.ImageCount + 1
	
	table.insert(self.Annotations, annotation)
	
	if fractional then annotation:SetFractionBounds(x, y, width, height, true)
	else
		local parent_width, parent_height = self:GetSize()
		
		annotation:SetFractionBounds(x / parent_width, y / parent_height, width / parent_width, height / parent_height, true)
	end
	
	annotation:SetFont("CloseCaption_BoldItalic")
	annotation:SetText("THUNDER!")
	annotation:SetTextColor(color_black)
	annotation:SetZPos(z_position)
	
	return annotation
end

function PANEL:AnnotateCrop(x_fraction, y_fraction, width_fraction, height_fraction, file_name)
	local annotation = self:Annotate(x_fraction, y_fraction, width_fraction, height_fraction, true)
	
	print(x_fraction, y_fraction, width_fraction, height_fraction, file_name)
	
	annotation:SetFont("DermaDefaultBold")
	annotation:SetText(file_name)
	
	return annotation
end

function PANEL:CalculateCrop(start_x, start_y, end_x, end_y)
	local maximum_x, maximum_y, minimum_x, minimum_y = self:CalculateMaxes(start_x, start_y, end_x, end_y)
	
	return maximum_x, maximum_y, minimum_x, minimum_y, math.min(maximum_x - minimum_x, self:GetWide(), 2 ^ get_power(ScrW())), math.min(maximum_y - minimum_y, self:GetTall(), 2 ^ get_power(ScrH()))
end

function PANEL:CalculateMaxes(start_x, start_y, end_x, end_y)
	local maximum_x, maximum_y = end_x, end_y
	local minimum_x, minimum_y = start_x, start_y
	
	if start_x > end_x then
		maximum_x = start_x
		minimum_x = end_x
	end
	
	if start_y > end_y then
		maximum_y = start_y
		minimum_y = end_y
	end
	
	return maximum_x, maximum_y, minimum_x, minimum_y
end

function PANEL:ClearAnnotations()
	self.AnnotationPanel:Clear()
	table.Empty(self.Annotations)
end

function PANEL:ClearImages()
	local images = self.Images
	
	self:ClearAnnotations()
	
	for index, image in ipairs(images) do
		image:Remove()
		
		images[index] = nil
	end
end

function PANEL:Crop(start_image, end_image, start_x, start_y, end_x, end_y, annotate)
	local maximum_x, maximum_y, minimum_x, minimum_y, drag_width, drag_height = self:CalculateCrop(start_x, start_y, end_x, end_y)
	
	--assertions
	if drag_width == 0 or drag_height == 0 then return self:RejectCrop(start_x, start_y, end_x, end_y, "zero sized crop", 2)
	elseif drag_width < self.MinimumCropSize or drag_height < self.MinimumCropSize then return self:RejectCrop(start_x, start_y, end_x, end_y, "undersized crop", 2) end
	
	local crop_images = {}
	local directory = self.Directory .. "crops/"
	local image_heights = {}
	local end_index, start_index = end_image:GetZPos(), start_image:GetZPos()
	local images = self.Images
	local maximum_width = self.MaximumWidth
	
	--flip start index should always be lower than end_index
	if start_index > end_index then end_index, start_index = start_index, end_index end
	
	--first pass to calculate end of the render target's size
	local width, height = self:GetSize()
	local scale = maximum_width / width
	local scale_width, scale_height = math.Round(drag_width * scale), math.Round(drag_height * scale)
	
	--because capture's size cannot exceede the frame buffer >:(
	if scale_width > 2 ^ get_power(ScrW()) or scale_height > 2 ^ get_power(ScrH()) then return self:RejectCrop(start_x, start_y, end_x, end_y, "oversized crop", 3) end
	
	local file_name = string.format("%u_%u_%u_%u.png", minimum_x, minimum_y, scale_width, scale_height)
	local power = get_power(math.max(scale_height, maximum_width))
	local scale_x, scale_y = math.Round(minimum_x * scale), math.Round(minimum_y * scale)
	local y_offset = math.Round(images[start_index]:GetY() * scale) - scale_y
	
	local target_info = hook.Call("KakogeRenderTarget", KAKOGE, power, true, function()
		render.Clear(0, 0, 255, 255)
		render.Clear(0, 0, 255, 255, true, true)
		
		surface.SetDrawColor(0, 255, 0)
		surface.DrawRect(0, 0, 100, 100)
		
		--we make the capture's x and y the image's 0, 0 so we can fit more
		for index = start_index, end_index do
			local image = images[index]
			local image_height = maximum_width / image.ActualWidth * image.ActualHeight
			
			--DImage:PaintAt has scaling loss
			surface.SetDrawColor(255, 255, 255)
			surface.SetMaterial(image:GetMaterial())
			surface.DrawTexturedRect(-scale_x, y_offset, maximum_width, image_height)
			
			y_offset = y_offset + image_height
		end
		
		--unfortunately this seems to return an empty or malformed string when beyond the frame buffer >:(
		--the frame buffer's ratio is sometimes be 2:1, but in normal play is 1:1
		file.CreateDir(directory)
		file.Write(directory .. file_name, render.Capture{
			alpha = false,
			format = "png",
			x = 0,
			y = 0,
			w = scale_width,
			h = scale_height
		})
	end, MATERIAL_RT_DEPTH_NONE, IMAGE_FORMAT_RGB888)
	
	local debug_expires = RealTime() + 10
	
	hook.Add("HUDPaint", "Kakoge", function()
		if RealTime() > debug_expires then hook.Remove("HUDPaint", "Kakoge") end
		
		surface.SetDrawColor(255, 255, 255)
		surface.SetMaterial(target_info.Material)
		surface.DrawTexturedRect(0, 0, 2 ^ power, 2 ^ power)
	end)
	
	if annotate then annotate = self:AnnotateCrop(minimum_x / width, minimum_y / height, drag_width / width, drag_height / height, string.StripExtension(file_name)) end
	
	self:OnCrop(scale_x, scale_y, scale_width, scale_height, annotate)
	
	return true
end

function PANEL:GetCropFromFile(file_name_stripped)
	local bounds = string.Split(file_name_stripped, "_")

	if #bounds ~= 4 then return end
	for index, value in ipairs(bounds) do bounds[index] = tonumber(value) end

	return unpack(bounds)
end

function PANEL:Init()
	self.Annotations = {}
	self.CropRejections = {}
	self.Font = "KakogeCropper"
	self.Images = {}
	self.Pressing = {}
	self.MinimumCropSize = 16
	
	do --annotation panel
		local panel = vgui.Create("DPanel", self)
		panel.IndexingParent = self
		
		panel:SetPaintBackground(false)
		panel:SetMouseInputEnabled(false)
		panel:SetZPos(29999)
		
		function panel:PerformLayout(width, height) self.IndexingParent:PerformLayoutAnnotations(self, width, height) end
		
		self.AnnotationPanel = panel
	end
	
	do --overlay panel
		local panel = vgui.Create("DPanel", self)
		panel.IndexingParent = self
		
		panel:SetMouseInputEnabled(false)
		panel:SetZPos(30000)
		
		function panel:Paint(width, height) self.IndexingParent:PaintOverlay(self, width, height) end
		function panel:PerformLayout(width, height) self.IndexingParent:PerformLayoutOverlay(self, width, height) end
		
		self.OverlayPanel = panel
	end
end

function PANEL:OnCrop(scale_x, scale_y, scale_width, scale_height) end

function PANEL:OnMousePressedImage(image, code)
	local pressing = self.Pressing
	local x, y = self:ScreenToLocal(gui.MouseX(), gui.MouseY())
	
	pressing[code] = {
		Image = image,
		
		X = x,
		Y = y
	}
end

function PANEL:OnMouseReleasedImage(image, code)
	local pressing = self.Pressing
	local press_data = pressing[code]
	local x, y = self:ScreenToLocal(gui.MouseX(), gui.MouseY())
	
	if press_data then
		self:OnMouseClickedImage(code, press_data.Image, image, press_data.X, press_data.Y, x, y)
		
		pressing[code] = nil
	end
end

function PANEL:OnMouseClickedImage(code, start_image, end_image, start_x, start_y, end_x, end_y)
	--crop wtih left click, but cancel with right click
	--probably will add a new mode in the furute
	if code == MOUSE_LEFT and not self.Pressing[MOUSE_RIGHT] then self:Crop(start_image, end_image, start_x, start_y, end_x, end_y, true) end
end

function PANEL:OnRemove()
	local directory = self.Directory
	local files = file.Find(directory .. "crops/*.png", "DATA")
	
	print(directory .. "crops/*.png")
	
	if files then
		local roster = {}
		
		PrintTable(files, 1)
		
		for index, file_name in ipairs(files) do
			local x, y, width, height = self:GetCropFromFile(string.StripExtension(file_name))
			
			if x and y and width and height then table.insert(roster, file_name) end
		end
		
		PrintTable(roster, 1)
		
		if next(roster) then file.Write(directory .. "crops/roster.txt", table.concat(roster, "\n")) end
	end
end

function PANEL:PaintCrop(start_x, start_y, width, height)
	--right click means cancel, so turn white if they are cancelling
	local disco = self.Pressing[MOUSE_RIGHT] and color_white or HSVToColor(math.floor(RealTime() * 2) * 30, 0.7, 1)
	local font = self.Font
	local screen_end_x, screen_end_y = gui.MouseX(), gui.MouseY()
	
	local end_x, end_y = self:ScreenToLocal(screen_end_x, screen_end_y)
	local screen_start_x, screen_start_y = self:LocalToScreen(start_x, start_y)
	
	local maximum_x, maximum_y, minimum_x, minimum_y, drag_width, drag_height = self:CalculateCrop(start_x, start_y, end_x, end_y)
	local screen_minimum_x, screen_minimum_y = math.min(screen_end_x, screen_start_x), math.min(screen_end_y, screen_start_y)
	
	surface.SetDrawColor(0, 0, 0, 64)
	surface.DrawRect(minimum_x, minimum_y, drag_width, drag_height)
	
	surface.SetDrawColor(0, 0, 0, 255)
	surface.DrawOutlinedRect(minimum_x, minimum_y, drag_width, drag_height, 3)
	
	surface.SetDrawColor(disco)
	surface.DrawOutlinedRect(minimum_x + 1, minimum_y + 1, drag_width - 2, drag_height - 2, 1)
	
	--scissor rect bad!
	render.SetScissorRect(screen_minimum_x + 3, screen_minimum_y + 3, screen_minimum_x + drag_width - 3, screen_minimum_y + drag_height - 3, true)
		draw.SimpleTextOutlined(drag_width .. " width", font, minimum_x + drag_width - 4, minimum_y + 2, disco, TEXT_ALIGN_RIGHT, TEXT_ALIGN_TOP, 1, color_black)
		draw.SimpleTextOutlined(drag_height .. " height", font, minimum_x + drag_width - 4, minimum_y + 16, disco, TEXT_ALIGN_RIGHT, TEXT_ALIGN_TOP, 1, color_black)
	render.SetScissorRect(0, 0, 0, 0, false)
end

function PANEL:PaintOverlay(overlay_panel, width, height)
	local cropping = self.Pressing[MOUSE_LEFT]
	
	self:PaintRejects(width, height)
	
	if cropping then self:PaintCrop(cropping.X, cropping.Y, width, height) end
end

function PANEL:PaintRejects(width, height)
	local font = self.Font
	local real_time = RealTime()
	local rejection_index = 1
	local rejections = self.CropRejections
	
	while rejection_index <= #rejections do
		local reject_data = rejections[rejection_index]
		local expires = reject_data.Expires
		
		if real_time > expires then table.remove(rejections, rejection_index)
		else
			local difference = expires - real_time
			local fraction = math.Clamp(difference, 0, 1)
			local fraction_510 = fraction * 510
			local message = reject_data.Message
			local saturation = math.ceil(difference * 2) % 2 * 64
			local x, y, width, height = reject_data.X, reject_data.Y, reject_data.Width, reject_data.Height
			
			surface.SetDrawColor(255, saturation, saturation, fraction * 192)
			surface.DrawRect(x, y, width, height)
			
			--a little bit hacky, but an alpha above 255 is treated as 255, so we can make this fade 0.5 seconds before the expiration by making it double 255
			surface.SetDrawColor(0, 0, 0, fraction_510)
			surface.DrawOutlinedRect(x, y, width, height, 3)
			
			surface.SetDrawColor(255, saturation, saturation, fraction_510)
			surface.DrawOutlinedRect(x + 1, y + 1, width - 2, height - 2, 1)
			
			if message then
				local clipping = DisableClipping(true)
				local message_saturation = saturation + 32
				
				draw.SimpleTextOutlined(message, font, x + width * 0.5, y + height * 0.5, Color(255, message_saturation, message_saturation, fraction_510), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 1, Color(0, 0, 0, fraction_510))
				DisableClipping(clipping)
			end
			
			rejection_index = rejection_index + 1
		end
	end
end

function PANEL:PerformLayout(width, height)
	local annotation_panel = self.AnnotationPanel
	local overlay = self.OverlayPanel
	
	--1 instead of 0, because I'm scared of dividing by 0...
	--never again, that sh*t is like a plague
	annotation_panel:SetTall(1)
	overlay:SetTall(1)
	
	for index, image in ipairs(self.Images) do
		local image_width = image:GetWide()
		
		image:SetCursor("crosshair")
		image:SetTall(width / image.ActualWidth * image.ActualHeight)
	end
	
	self:SizeToChildren(false, true)
	
	--now, resize!
	annotation_panel:SetSize(self:GetSize())
	overlay:SetSize(self:GetSize())
end

function PANEL:PerformLayoutAnnotations(annotation_parent, width, height)
	local annotation_parent = self.AnnotationPanel
	
	for index, annotation in ipairs(self.Annotations) do annotation:ScaleToPanel(annotation_parent, width, height) end
end

function PANEL:PerformLayoutOverlay(overlay, width, height) end

function PANEL:RejectCrop(start_x, start_y, end_x, end_y, message, duration)
	local maximum_x, maximum_y, minimum_x, minimum_y, drag_width, drag_height = self:CalculateCrop(start_x, start_y, end_x, end_y)
	
	table.insert(self.CropRejections, {
		Expires = RealTime() + duration,
		
		Width = drag_width,
		Height = drag_height,
		
		Message = message,
		
		X = minimum_x,
		Y = minimum_y,
	})
	
	return false, message
end

function PANEL:SetAnnotationsEditable(state) self.AnnotationPanel:SetMouseInputEnabled(state) end

function PANEL:SetDirectory(directory)
	if not string.EndsWith(directory, "/") then directory = directory .. "/" end
	
	local files, folders = file.Find(directory .. "*", "DATA")
	local images = self.Images
	self.Directory = directory
	
	self:ClearImages()
	
	assert(files, "KakogeCropperStrip had an invalid directory set")
	
	for index, file_name in ipairs(files) do files[file_name] = index end
	for index, folder_name in ipairs(folders) do folders[folder_name] = index end
	
	--trustee generated roster
	if files["roster.txt"] then
		local total_height = 0
		local maximum_width = 0
		local image_count = 0
		local image_names = string.Split(file.Read(directory .. "roster.txt", "DATA"), "\n")
		
		for index, image_name in ipairs(image_names) do
			local image = vgui.Create("KakogeCropperImage", self)
			image_count = image_count + 1
			image.CropperStrip = self
			
			table.insert(images, image)
			
			image:Dock(TOP)
			image:SetMaterial("data/" .. directory .. image_name)
			image:SetZPos(index)
			
			maximum_width = math.max(maximum_width, image.ActualWidth)
			total_height = total_height + image.ActualHeight
		end
		
		self.TotalHeight = total_height
		self.MaximumWidth = maximum_width
		self.ImageCount = image_count
		
		self:InvalidateLayout(true)
		
		local parent_width, parent_height = maximum_width, total_height
		
		--we store our crops in a folder alongside its OCR data
		--easy way to store meta without having duplication: use the file's name!
		if folders.crops then
			local crop_files, crop_folders = file.Find(directory .. "crops/*", "DATA")
			
			for index, file_name in ipairs(crop_files) do crop_files[file_name] = index end
			
			for index, file_name in ipairs(crop_files) do
				local file_name_stripped = string.StripExtension(file_name)
				local x, y, width, height = self:GetCropFromFile(file_name_stripped)
				
				if x and y and width and height then
					local extension = string.GetExtensionFromFilename(file_name)
					
					if extension == "png" then self:AnnotateCrop(x / parent_width, y / parent_height, width / parent_width, height / parent_height, file_name_stripped)
					elseif extension == "txt" then
						--more!
						self:DescribeAnnotation(file_name_stripped)
					else print("bonus file: " .. file_name) end
				else print("malformed file in crops folder: " .. file_name_stripped, x, y, width, height) end
			end
		end
	end
end

function PANEL:SetFont(font) self.Font =  font and tostring(font) or "KakogeCropper" end

--post
derma.DefineControl("KakogeCropperStrip", "", PANEL, "DSizeToContents")