local ip_address = KAKOGE.IPAdress

--commands
concommand.Add("kakoge", function(ply, commands, arguments, arguments_string)
	local home = vgui.Create("KakogeHome")
	
	home:SetSize(ScrW() * 0.9, ScrH() * 0.9)
	
	home:Center()
	home:MakePopup()
	
	home:SetSkin("Pecan")
end, nil, "Opens a full-screen Kakoge menu.")

concommand.Add("kakoget", function(ply, commands, arguments, arguments_string)
	local frame = vgui.Create("DFrame")
	
	frame:SetSize(500, 500)
	frame:SetTitle("Kakoge Test Window")
	
	frame:Center()
	frame:MakePopup()
	frame:SetX(62)
	
	do --contents panel
		local contents_panel = vgui.Create("EditablePanel", frame)
		
		contents_panel:Dock(FILL)
		
		if false then --language selector
			local language_selector = vgui.Create("KakogeLanguageSelector", contents_panel)
			
			language_selector:SetWide(200)
			
			contents_panel.LanguageSelector = language_selector
		end
		
		if false then --translation block
			local translation_block = vgui.Create("KakogeTranslationBlock", contents_panel)
			
			translation_block:Dock(TOP)
			translation_block:SetEditable(false)
			translation_block:SetLanguage("korean")
			
			contents_panel.TranslationBlock = translation_block
		end
		
		if false then --translation chain
			local translation_chain = vgui.Create("KakogeTranslationChain", contents_panel)
			
			translation_chain:AddBlock("japanese")
			translation_chain:Dock(TOP)
			translation_chain:SetSourceLanguage("korean")
			translation_chain:SetTargetLanguage("english")
			
			contents_panel.TranslationChain = translation_chain
		end
		
		if true then --translation chain
			local translation_network = vgui.Create("KakogeTranslationNetwork", contents_panel)
			
			translation_network:Dock(FILL)
			
			contents_panel.TranslationChain = translation_network
		end
		
		frame.ContentsPanel = contents_panel
	end
end, nil, "The test command for Kakoge.")

concommand.Add("kakoge_annotate", function(ply, commands, arguments, arguments_string)
	local id = arguments[1]
	
	if not id then return print("provide an id") end
	
	local path = "kakoge/download/" .. id
	
	if not file.Exists(path, "DATA") then return print("invalid path") end
	
	do --frame
		local frame = vgui.Create("DFrame")
		path = path .. "/"
		
		local width = 720 * 1
		
		--frame:SetMinWidth(745)
		frame:SetSizable(true)
		frame:SetSize(width + 25, ScrH())
		frame:SetTitle("Kakoge Test")
		
		frame:Center()
		frame:MakePopup()
		
		do --scroller
			local scroller = vgui.Create("DScrollPanel", frame)
			
			scroller:Dock(FILL)
			
			do --strip
				local strip = vgui.Create("KakogeCropperStrip", scroller)
				
				strip:Dock(TOP)
				strip:SetDirectory(path)
			end
		end
	end
end, nil, "Opens an menu from Kakoge for annotating scripts.")

--net
net.Receive("kakoge_ip", function()
	--this is used for the mymemory API
	--kakoge_ip_override overrides the value cached
	local read = net.ReadString()
	
	if read ~= "loopback" then
		ip_address = string.Explode(":", read, false)[1]
		KAKOGE.IPAdress = ip_address
	end
end)