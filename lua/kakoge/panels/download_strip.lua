local PANEL = {}

local count_javascript = [[kakoge.count(document.getElementsByClassName('comic-viewer-content-img').length);]]

local grab_javascript = [[var foundElements = document.getElementsByClassName('comic-viewer-content-img');
var lazyCount = 0;
var index = 0;
for (const element of foundElements) {
	index++;
	const staticIndex = index;
	
	if (element.complete) {kakoge.push(staticIndex, element.src, false);}
	else
	{
		lazyCount++;
		kakoge.wait(staticIndex, element.src);
		element.onload = function() {kakoge.push(staticIndex, this.src, true);}
	}
}
kakoge.done(index, lazyCount);]]

--panel functions
function PANEL:ConsoleMessage(message) MsgC(Color(255, 160, 255), "[Kakoge] ", color_white, tostring(message), "\n") end

function PANEL:GrabImageSources()
	self.Grabbing = true
	
	file.CreateDir(self.Directory)
	
	self:Call(grab_javascript)
end

function PANEL:ImageCount(count)
	local last_count = self.Count or 0
	
	if last_count ~= count then
		self.Count = count
		self.LastDiscovery = RealTime()
		
		self:OnImageCountUpdated(count)
	end
end

function PANEL:ImageFinish()
	self.Grabbing = false
	
	--MsgC(Color(64, 255, 64), "[Kakoge] ", color_white, "Finished fetching all image sources! A total of " .. self.PushTotal .. " sources have been collected.\n")
	
	self:OnImageFinish()
end

function PANEL:ImagePush(index, source_url, lazy)
	if not self.Grabbing then return end
	
	local image_sources = self.ImageSources
	local previous_index = image_sources[source_url]
	
	--MsgC(Color(240, 192, 64), "[Kakoge] ", color_white, "#" .. index .. (lazy and " pushed as a lazy load\n" or  " pushed as an eager load\n"))
	
	image_sources[index] = source_url
	image_sources[source_url] = index
	
	self:OnImagePush(index, source_url, lazy)
	
	if previous_index then return end
	
	if lazy then
		local lazy_sources = self.LazyImageSources
		lazy_sources[index] = nil
		
		if table.IsEmpty(lazy_sources) then self:ImageFinish() end
	end
	
	self.LastGrab = RealTime()
end

function PANEL:ImagePushDone(count, lazy_count)
	if not self.Grabbing then return end
	
	--MsgC(Color(255, 255, 64), "[Kakoge] ", color_white, "Done queuing source pushes. A total of " .. count .. " sources are accounted for, and " .. lazy_count .. (lazy_count == 1 and " is still loading.\n" or " are still loading.\n"))
	
	self.PushTotal = count
	self.LazyCount = lazy_count
	
	self:OnImagePushDone(count, lazy_count)
	
	if lazy_count == 0 then self:ImageFinish() end
end

function PANEL:ImageWait(index, source_url)
	if not self.Grabbing then return end
	
	--MsgC(Color(240, 192, 64), "[Kakoge] ", color_white, "#" .. index .. " is lazy and awaiting load event\n")
	
	self.LazyImageSources[index] = source_url
	
	self:OnImageWait(index, source_url)
end

function PANEL:Init()
	self:SetScrollbars(false)
	
	self.DiscoveryPatience = 2
	self.ImageSources = {}
	self.LazyImageSources = {}
	self.LoadPatience = 5
	self.RemoveOnGiveUp = true
	
	self:AddFunction("kakoge", "count", function(...) return self:ImageCount(...) end)
	self:AddFunction("kakoge", "done", function(...) return self:ImagePushDone(...) end)
	self:AddFunction("kakoge", "push", function(...) return self:ImagePush(...) end)
	self:AddFunction("kakoge", "wait", function(...) return self:ImageWait(...) end)
end

function PANEL:OnDocumentReady(...) end
function PANEL:OnFinishLoadingDocument(...) self:StartCounting() end

--these "On" methods are safe to override, just don't make script errors inside them
function PANEL:OnImageCountFinished(count) end
function PANEL:OnImageCountUpdated(count) end
function PANEL:OnImageFinish() end
function PANEL:OnImagePush(index, source_url, lazy) end
function PANEL:OnImagePushDone(count, lazy_count) end
function PANEL:OnImageWait(index, source_url) end

function PANEL:Paint(width, height)
	if self.ProductID then
		if self:IsLoading() then draw.SimpleText("Loading", "DermaLarge", width * 0.5, height * 0.5, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER) end
		
		return
	end
	
	draw.SimpleText("Awaiting ID entry", "DermaLarge", width * 0.5, height * 0.5, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
end

function PANEL:GiveUp()
	self.GaveUp = true
	
	if self.RemoveOnGiveUp then self:Remove() end
end

function PANEL:Start(id)
	self.Counting = false
	self.Directory = "kakoge/download/" .. id
	self.GaveUp = false
	self.LastDiscovery = nil
	self.LoadTime = RealTime()
	self.ProductID = id
	
	self:OpenURL("https://page.kakao.com/viewer?productId=" .. id)
	
	table.Empty(self.ImageSources)
	table.Empty(self.LazyImageSources)
end

function PANEL:StartCounting()
	self.Count = 0
	self.Counting = true
	self.LastDiscovery = RealTime()
	
	--MsgC(Color(240, 192, 64), "[Kakoge] ", color_white, "Begin counting...\n")
end

function PANEL:StopCounting()
	local count = self.Count
	
	self.Counting = false
	self.LastDiscovery = nil
	
	if count == 0 then
		MsgC(Color(240, 64, 64), "[Kakoge] ", color_white, "Did not count any image sources, maybe we were not patient enough.\n")
		
		self:GiveUp()
	else
		--MsgC(Color(240, 192, 64), "[Kakoge] ", color_white, "Done counting, counted a total of " .. count .. "\n")
		
		self:OnImageCountFinished(count)
		self:GrabImageSources()
	end
end

function PANEL:Think()
	if self.GaveUp then return end
	
	local real_time = RealTime()
	
	if self:IsLoading() then
		if self.LoadTime and real_time - self.LoadTime > self.LoadPatience then
			MsgC(Color(240, 64, 64), "[Kakoge] ", color_white, "Giving up, took too long to load.")
			
			self:GiveUp()
		end
		
		return
	end
	
	if self.Counting then
		if real_time - self.LastDiscovery > self.DiscoveryPatience then self:StopCounting()
		else self:RunJavascript(count_javascript) end
	end
	
	if self.JS then
		for index, scripture in pairs(self.JS) do self:RunJavascript(scripture) end
		
		self.JS = nil
	end
end

--post
derma.DefineControl("KakogeDownloadStrip", "", PANEL, "DHTML")