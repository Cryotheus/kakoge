local PANEL = {}

--panel functions
function PANEL:Init()
	--56512612
	
	do --divider
		local divider = vgui.Create("DHorizontalDivider", self)
		
		divider:Dock(FILL)
		
		do --left
			local panel = vgui.Create("DPanel", divider)
			
			function panel:Paint() end
			
			do --button
				local button = vgui.Create("DButton", panel)
				button.IndexingParent = self
				
				button:Dock(TOP)
				button:SetEnabled(false)
				button:SetText("Download")
				
				function button:DoClick() self.IndexingParent:StartQueue() end
				
				panel.Button = button
			end
			
			do --list view
				local list_view = vgui.Create("DListView", panel)
				list_view.IndexingParent = self
				
				list_view:AddColumn("##", 1):SetFixedWidth(36)
				list_view:AddColumn("Status", 2)
				list_view:AddColumn("File", 3)
				list_view:Dock(FILL)
				
				function list_view:OnRowSelected(index, row) self.IndexingParent:OnRowSelected(index, row) end
				
				panel.ListView = list_view
			end
			
			divider:SetLeft(panel)
		end
		
		do --right
			local panel = vgui.Create("DPanel", divider)
			
			function panel:Paint() end
			
			do --header
				local header = vgui.Create("DPanel", panel)
				
				header:Dock(TOP)
				header:SetHeight(24)
				
				function header:PerformLayout(width, height) self.TextEntry:SetWide(math.max(width * 0.25, 256)) end
				
				do --text entry
					local text_entry = vgui.Create("DTextEntry", header)
					
					text_entry:Dock(LEFT)
					text_entry:SetWide()
					text_entry:SetPlaceholderText("Product ID")
					text_entry:SetText("56512612")
					
					function text_entry:OnEnter(value)
						if string.len(value) == 0 then return end
						
						panel.DownloadStrip:Start(value)
					end
					
					header.TextEntry = text_entry
				end
				
				do --progress bar
					local bar = vgui.Create("DProgress", header)
					local bar_paint = bar.Paint
					
					bar:Dock(FILL)
					
					function bar:Paint(width, height)
						local download_strip = panel.DownloadStrip
						
						if download_strip and download_strip.GaveUp then
							surface.SetDrawColor(192, 0, 0)
							surface.DrawRect(0, 0, width, height)
							
							return
						end
						
						bar_paint(self, width, height)
					end
					
					function bar:Think()
						local download_strip = panel.DownloadStrip
						local label, label_color = self.Label, Color(0, 128, 0)
						local maximum, message, percentage, start
						
						if download_strip then
							if download_strip.GaveUp then label_color, message = color_white, "Gave Up"
							elseif download_strip.ProductID and download_strip:IsLoading() then
								maximum, start = download_strip.LoadPatience, download_strip.LoadTime
								message = "Loading"
							elseif download_strip.Counting then
								maximum, start = download_strip.DiscoveryPatience, download_strip.LastDiscovery
								message = "Current count: " .. download_strip.Count
							elseif download_strip.Grabbing then
								local count = download_strip.Count
								local downloading_count = self.LazyImageSources and #self.LazyImageSources or 0
								local grabbed_count = count - downloading_count
								percentage = grabbed_count / count
								
								if grabbed_count == count then message = "Fully loaded " .. count .. " length strip"
								else message = grabbed_count .. " / " .. count end
							end
							
							if percentage then self:SetFraction(percentage)
							elseif maximum and start then
								local maximum = math.max(maximum, RealFrameTime())
								local passed = math.Clamp(RealTime() - start, 0, maximum)
								
								self:SetFraction(passed / maximum)
							end
							
							if message and label:GetText() ~= message then
								label:SetText(message)
								
							end
							
							if label_color ~= label:GetTextColor() then label:SetTextColor(label_color) end
						end
					end
					
					do --label
						local label = vgui.Create("DLabel", bar)
						
						label:Dock(FILL)
						label:SetContentAlignment(5)
						label:SetText("")
						label:SetTextColor(Color(0, 128, 0))
						
						bar.Label = label
					end
					
					header.ProgressBar = bar
				end
				
				panel.Header = header
			end
			
			do --download strip
				local download_strip = vgui.Create("KakogeDownloadStrip", panel)
				download_strip.IndexingParent = self
				download_strip.RemoveOnGiveUp = false
				
				download_strip:Dock(FILL)
				
				function download_strip:OnImageFinish(count) self.IndexingParent:SetCount(self.Count, self) end
				
				panel.DownloadStrip = download_strip
			end
			
			divider:SetRight(panel)
		end
		
		self.Divider = divider
	end
end

function PANEL:OnRowSelected(index, row) print(index, row) end

function PANEL:Paint() end

function PANEL:PerformLayout(width, height)
	local divider = self.Divider
	local left_minimum = math.ceil(width * 0.2)
	local left_width = math.ceil(width * 0.3)
	
	divider:SetLeftMin(left_minimum)
	divider:SetLeftWidth(left_width)
end

function PANEL:SetCount(count, download_strip)
	local divider = self.Divider
	local divider_left = divider.m_pLeft
	local download_strip = download_strip or self.Divider.m_pRight.DownloadStrip
	local id = download_strip.ProductID
	local image_sources = download_strip.ImageSources
	local list_view = divider_left.ListView
	local queue = {ID = id, Start = SysTime()}
	local roster = {}
	
	local directory = "kakoge/download/" .. id
	local roster_name = directory .. "/roster.txt"
	
	list_view:Clear()
	
	for index = 1, count do
		local source_url = image_sources[index]
		
		local create_hooks = false
		local file_path = hook.Call("KakogeDownloadGetParameters", KAKOGE, source_url).filename
		local file_name = file_path and string.sub(file_path, 1, string.len(file_path) - string.len(string.GetExtensionFromFilename(file_path)) - 1) .. ".png" or false
		local status
		
		table.insert(roster, file_name)
		
		if file_path then
			if file.Exists(directory .. "/" .. file_name, "DATA") then status = "Downloaded"
			else
				table.insert(queue, {file_path, source_url})
				
				create_hooks = true
				status = "Ready"
			end
		else status = "Error" end
		
		local row = list_view:AddLine(index, status or "Unknown", file_path or "<missing>")
		
		if create_hooks then
			hook.Add("KakogeDownloadStripWriteImagePost", row, function(check_row, id, directory, file_name, check_source_url)
				if check_source_url ~= source_url then return end
				
				check_row:SetColumnText(2, "Downloaded")
				
				hook.Remove("KakogeDownloadStripStartQueue", check_row)
				hook.Remove("KakogeDownloadStripWriteImage", check_row)
				hook.Remove("KakogeDownloadStripWriteImagePost", check_row)
				
				if #queue == 0 then self:SetQueue() end
			end) --update to downloaded status
			
			hook.Add("KakogeDownloadStripWriteImage", row, function(self, id, directory, file_name, check_source_url)
				if post_source_url ~= source_url then return end
				
				self:SetColumnText(2, "Downloading")
			end) --update to downloading status
			
			hook.Add("KakogeDownloadStripStartQueue", row, function(self, check_id, queue)
				if check_id ~= id then return end
				
				self:SetColumnText(2, "Queued")
			end) --update to queued status
			
			function row:OnRemove()
				hook.Remove("KakogeDownloadStripStartQueue", row)
				hook.Remove("KakogeDownloadStripWriteImage", row)
				hook.Remove("KakogeDownloadStripWriteImagePost", row)
			end
		end
	end
	
	file.Write(roster_name, table.concat(roster, "\n"))
	
	local queue_count = #queue
	
	if queue_count > 0 then
		queue.Total = queue_count
		
		self:SetQueue(queue)
	end
end

function PANEL:SetQueue(queue)
	local divider = self.Divider
	local divider_left = divider.m_pLeft
	local queue_button = divider_left.Button
	
	if queue then
		self.CurrentQueue = queue
		
		queue_button:SetEnabled(true)
		
		return
	end
	
	queue_button:SetEnabled(false)
end

function PANEL:StartQueue()
	local queue = self.CurrentQueue
	
	if not queue then return end
	
	hook.Call("KakogeDownloadStripStartQueue", KAKOGE, queue.ID, queue)
end

--post
derma.DefineControl("KakogeDownloadShop", "Contains a KakogeDownloadStrip with some controls and feedback.", PANEL, "DPanel")