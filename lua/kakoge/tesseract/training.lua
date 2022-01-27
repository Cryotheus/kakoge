--local tables
local words_files = {}

--convars
local kakoge_training_images_batch = CreateConVar("kakoge_training_images_batch", "1", FCVAR_ARCHIVE, "How large the batch size for training images should be. Must be above 0.", 0)
local kakoge_training_images_phrase_maximum = CreateConVar("kakoge_training_images_phrase_maximum", "6", FCVAR_ARCHIVE, "How large in unicode characters can the phrase get. This will get overstepped.", 1)
local kakoge_training_images_phrase_minimum = CreateConVar("kakoge_training_images_phrase_minimum", "1", FCVAR_ARCHIVE, "How large the phrase needs to become before it is turned into an image.", 1)
local kakoge_training_images_phrase_separator = CreateConVar("kakoge_training_images_phrase_separator", " ", FCVAR_ARCHIVE, "The string to use when seperating words to build phrases.", 1)

--local functions
local function get_power(result) return math.ceil(math.log(result, 2)) end

--console commands
concommand.Add("kakoge_training_images_generate", function(ply, command, arguments, arguments_string)
	local source_language, font, font_size, font_weight, start_index = unpack(arguments)
	
	if not source_language then return print('Invalid source language.\nArguments: source_language, font="Gothic A1", font_size=48, font_weight=500, start_index=1, stop_index=2147483647') end
	
	local directory = "kakoge/training/" .. source_language .. "/"
	local words_path = directory .. "words.txt"
	
	if not file.Exists(words_path, "DATA") then return print("Missing " .. words_path .. " file. This is a text file that has one word or phrase per line.") end
	
	local file_open = words_files[words_path] or file.Open(words_path, "r", "DATA")
	local font = font or "Gothic A1"
	local font_name = "KakogeTraining_" .. source_language
	local font_size = tonumber(font_size) or 48
	local font_weight = tonumber(font_weight) or 500
	local hook_name = "KakogeTesseractTraining_" .. source_language
	local image_index = tonumber(start_index) or 1
	local output_directory = directory .. "output/"
	local stop_index = tonumber(stop_index)
	words_files[words_path] = file_open
	
	file_open:Seek(0)
	
	file.CreateDir(output_directory)
	surface.CreateFont(font_name, {
		antialias = true,
		extended = true, --need this for lingos
		font = font,
		size = font_size,
		weight = font_weight,
	})
	
	hook.Add("PostRender", hook_name, function()
		--first we generate the text
		local minimum_length = kakoge_training_images_phrase_minimum:GetInt()
		local required_length = math.max(math.random(minimum_length, kakoge_training_images_phrase_maximum:GetInt()), 1)
		local text = string.Trim(file_open:ReadLine())
		
		while utf8.len(text) < required_length do
			local read = string.Trim(file_open:ReadLine())
			
			text = text .. kakoge_training_images_phrase_separator:GetString() .. read
			
			if file_open:EndOfFile() then
				file_open:Close()
				
				words_files[words_path] = nil
				
				hook.Remove("PostRender", hook_name)
				print("Hit the end of the file, stopping generation.")
				
				break
			end
		end
		
		if utf8.len(text) < minimum_length then return print("Discarding image #" .. image_index .. " as it does not meet the minimum length requirement.") end
		
		--then we generate the image
		surface.SetFont(font_name)
		
		local text_width, text_height = surface.GetTextSize(text)
		local image_path = output_directory .. "image_" .. image_index
		local power = get_power(math.max(text_width, text_height))
		local size = 2 ^ power
		
		cam.Start2D()
			surface.SetDrawColor(255, 255, 255)
			surface.DrawRect(0, 0, text_width, text_height)
			draw.SimpleText(text, font_name, 0, 0, Color(0, 0, 0), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
		cam.End2D()
		
		file.Write(image_path .. ".gt.txt", text .. "\n")
		file.Write(image_path .. ".png", render.Capture{
			alpha = false,
			format = "png",
			
			x = 0,
			y = 0,
			
			w = text_width,
			h = text_height
		})
		
		if stop_index and image_index >= stop_index then
			file_open:Close()
			
			words_files[words_path] = nil
			
			hook.Remove("PostRender", hook_name)
			print("Finished at stop index.")
			
			return
		end
		
		image_index = image_index + 1
	end)
end, nil, "Generate training images, given a font and text file of words. First argument is the language.")

concommand.Add("kakoge_training_images_stop", function(ply, command, arguments, arguments_string)
	for words_path, words_file in pairs(words_files) do
		words_file:Close()
		
		print("Closed " .. words_path)
	end
	
	for hook_name, hook_function in pairs(hook.GetTable().PostRender) do
		if string.StartWith(hook_name, "KakogeTesseractTraining_") then
			hook.Remove("PostRender", hook_name)
			print("Removed " .. hook_name .. " hook.")
		end
	end
	
	--because the for loop skips >:(
	table.Empty(words_files)
end, nil, "Forcibly end all image generation. This closes all word files and removed all hooks used for image generation.")