local PANEL = {}
local render_size = 2048

--local render_target = GetRenderTargetEx("kakoge/download", render_size, render_size, RT_SIZE_LITERAL, MATERIAL_RT_DEPTH_NONE, 256, 0, IMAGE_FORMAT_RGB888)
--local render_target_material = CreateMaterial("kakoge/download", "UnlitGeneric", {["$basetexture"] = render_target:GetName()})

--panel functions
function PANEL:ConsoleMessage(message) MsgC(Color(255, 160, 255), "[Kakoge] ", color_white, tostring(message), "\n") end

function PANEL:Init()
	self:SetParent(vgui.GetWorldPanel())
	self:SetPos(0, 0)
	self:SetSize(render_size, render_size)
	
	self:AddFunction("kakoge", "load", function(...) return self:SizeReceived(...) end)
end

function PANEL:OnFinishLoadingDocument() self.FinishedLoading = true end
function PANEL:OnSuccess() end
function PANEL:Paint(width, height) end

function PANEL:SizeReceived(width, height)
	self.CaptureTime = RealTime() + 0.2
	self.Width, self.Height = width, height
end

function PANEL:Start(id, directory, file_name, url)
	self.Directory = directory
	self.Expires = RealTime() + 10
	self.FileName = file_name
	self.ProductID = id
	self.SourceURL = url
	
	self:SetHTML([[<body style='margin:0;'><img src=']] .. url .. [[' loading='eager' onload='kakoge.load(this.width, this.height);'>]])
end

function PANEL:Think()
	local real_time = RealTime()
	
	if self.Expires and real_time > self.Expires then self:Remove()
	elseif self.FinishedLoading and self.CaptureTime and real_time > self.CaptureTime then
		local directory = self.Directory
		local file_name = self.FileName
		local id = self.ProductID
		local material = self:GetHTMLMaterial()
		local source_url = self.SourceURL
		
		if material then
			self:UpdateHTMLTexture()
			
			hook.Call("KakogeRenderTarget", KAKOGE, math.ceil(math.log(math.max(self.Width, self.Height), 2)), true, function(size)
				render.Clear(0, 0, 0, 255, true, true)
				surface.SetDrawColor(255, 255, 255)
				surface.SetMaterial(material)
				surface.DrawTexturedRect(0, 0, size, size)
				
				file_name = string.sub(file_name, 1, string.len(file_name) - string.len(string.GetExtensionFromFilename(file_name)) - 1) .. ".png"
				
				file.CreateDir(directory)
				file.Write(directory .. "/" .. file_name, render.Capture{
					format = "png",
					x = 0,
					y = 0,
					w = self.Width,
					h = self.Height
				})
				
				self.FileName = file_name
			end, MATERIAL_RT_DEPTH_NONE, IMAGE_FORMAT_RGB888)
		end
		
		if self:OnSuccess() then return end
		
		self:Remove()
	end
end

--post
derma.DefineControl("KakogeDownloadCapture", "Given an image source, writes a png to the data folder. May have issues with dimensions above 2048.", PANEL, "DHTML")