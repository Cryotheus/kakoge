local strip_queue = KAKOGE.DownloadStripQueue or {}
local render_size = 2048
local render_target = GetRenderTargetEx("kakoge/download", render_size, render_size, RT_SIZE_LITERAL, MATERIAL_RT_DEPTH_NONE, 256, 0, IMAGE_FORMAT_RGB888)

local render_target_material = CreateMaterial("kakoge/download", "UnlitGeneric", {
	["$basetexture"] = render_target:GetName()
})

--globals
KAKOGE.DownloadStripQueue = strip_queue

--[[
	https://page-edge-jz.kakao.com/sdownload/resource/

	!&kid		=	1oIO206wpS_v586Lw40XmCmezdYD7nS6QbWM1VSxYw_09mi5T-yLUeQyuempNqRv

	?&encWid		=	jY3b7S1B353MQr5NBS-pGw

	.&pid		=	56415878

	.&filename	=	5690300_1612320344337.jpeg

	!&gid		=	Qb3kSWot895rlTuEjm193A

	!&signature	=	CaLbHgHTu84LdMvpQ%2FZp7yp64fo%3D
]]

--local functions
local function get_parameters(url)
	local parameters = {}
	local key_values = string.Explode("[&%?]", url, true)
	
	table.remove(key_values, 1)
	
	for index, gib in ipairs(key_values) do
		local key, value = unpack(string.Explode("=", gib, false))
		
		parameters[key] = value
	end
	
	return parameters
end

--kakoge functions
function KAKOGE:KakogeDownload(product_id)
	assert(isstring(product_id) or isnumber(product_id), "Missing numerical or textual product ID")
	
	do --frame
		local frame = vgui.Create("DFrame")
		
		frame:SetSize(ScrW() * 0.9, ScrH() * 0.9)
		frame:SetTitle("Test Results")
		
		frame:Center()
		frame:MakePopup()
		
		do --html panel
			local website = vgui.Create("KakogeDownloadStrip", frame)
			
			website:Dock(FILL)
			website:Start(product_id)
		end
	end
end

function KAKOGE:KakogeDownloadGetParameters(url) return get_parameters(url) end

function KAKOGE:KakogeDownloadStripAdvanceQueue(id)
	local queued = strip_queue[id]
	
	if not queued then return MsgC(Color(255, 64, 64), "Released batch " .. id .. ".\n") end
	
	if #queued > 0 then
		local first_out = table.remove(queued, 1)
		
		hook.Call("KakogeDownloadStripWriteImage", self, id, "kakoge/download/" .. id, unpack(first_out))
	else
		MsgC(Color(255, 192, 64), "Completed batch " .. id .. " with " .. queued.Total .. " images in " .. (SysTime() - queued.Start) .. " seconds.\n")
		
		strip_queue[id] = nil
	end
end

function KAKOGE:KakogeDownloadStripStartQueue(id, queue)
	assert(not strip_queue[id] or table.IsEmpty(strip_queue[id]), "Queue cannot be started as the provided ID is already in use.")
	
	strip_queue[id] = queue
	
	MsgC(Color(255, 192, 64), "Starting " .. id .. "\n")
	hook.Call("KakogeDownloadStripAdvanceQueue", KAKOGE, id)
end

function KAKOGE:KakogeDownloadStripWriteImage(id, directory, file_name, source_url) --Color(255, 192, 64)
	if string.GetExtensionFromFilename(file_name) == "png" then --we want a png format, so don't convert it if we already have it
		http.Fetch(source_url, function(body, size, headers, code)
			file.CreateDir(directory)
			file.Write(directory .. "/" .. file_name, body)
			hook.Call("KakogeDownloadStripWriteImagePost", KAKOGE, id, directory, file_name, source_url)
		end, function(error_message) ErrorNoHaltWithStack("oh fiddlesticks, what now? ", error_message) end, {})
	else
		local download_capture = vgui.Create("KakogeDownloadCapture")
		
		function download_capture:OnRemove() hook.Call("KakogeDownloadStripWriteImagePost", KAKOGE, self.ProductID, self.Directory, self.FileName, self.SourceURL) end
		
		download_capture:Start(id, directory, file_name, source_url)
	end
end

function KAKOGE:KakogeDownloadStripWriteImagePost(id, directory, file_name, source_url)
	MsgC(Color(255, 192, 64), "Saved " .. file_name .. "\n")
	hook.Call("KakogeDownloadStripAdvanceQueue", self, id)
end