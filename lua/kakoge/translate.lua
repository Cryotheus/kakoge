local flags = bit.bor(FCVAR_ARCHIVE, FCVAR_PRINTABLEONLY, FCVAR_SERVER_CANNOT_QUERY)

--convars
local kakoge_ip_override = CreateConVar("kakoge_ip_override", "", flags, "IP Address to use instead of auto-detected address. Necessary for IP services in single-player.")
local kakoge_translate_azure_client_id = CreateConVar("kakoge_translate_azure_client_id", "", flags, "Client trace ID for Microsoft Azure translation API. Leave empty if you don't need it.")
local kakoge_translate_azure_domain = CreateConVar("kakoge_translate_azure_domain", "https://api.cognitive.microsofttranslator.com/", flags, "Domain for Microsoft Azure translation API. Don't mess with this.")
local kakoge_translate_azure_key = CreateConVar("kakoge_translate_azure_key", "", flags, "API key for Microsoft Azure translation API. Leave empty for global resources.")
local kakoge_translate_azure_region = CreateConVar("kakoge_translate_azure_region", "", flags, "API key for Microsoft Azure translation API.")
local kakoge_translate_deepl_domain = CreateConVar("kakoge_translate_deepl_domain", "https://api-free.deepl.com/v2/translate", flags, "Domain for DeepL translation API.")
local kakoge_translate_deepl_key = CreateConVar("kakoge_translate_deepl_key", "", flags, "API key for DeepL translator.")
local kakoge_translate_itranslate_key = CreateConVar("kakoge_translate_itranslate_key", "", flags, "API key for iTranslate translation API.")
local kakoge_translate_yandex_key = CreateConVar("kakoge_translate_yandex_key", "", flags, "API key for Yandex's translation API.")

--local tables
local language_flags = {
	english = "us",
	japanese = "jp",
	korean = "kr"
}

local languages_available = KAKOGE.LanguagesAvailable or {}
local languages_services = KAKOGE.LanguagesServices or {}

local translator_convars = { --console variables passed to the translator functions
	azure = {
		kakoge_translate_azure_client_id,
		kakoge_translate_azure_domain,
		kakoge_translate_azure_key,
		kakoge_translate_azure_region
	},
	
	deepl = {
		kakoge_translate_deepl_domain,
		kakoge_translate_deepl_key
	},
	
	itranslate = kakoge_translate_itranslate_key,
	yandex = kakoge_translate_yandex_key
}

local translator_language_aliases = { --what the API needs as the language, also used to check if the language is supported
	azure = {
		english = "en",
		japanese = "ja",
		korean = "ko"
	},
	
	deepl = {
		english = "EN",
		japanese = "JA",
		korean = false
	},
	
	--[[google = {
		english = "en",
		korean = "ko"
	},]]
	
	itranslate = {
		english = "en",
		japanese = "ja",
		korean = "ko"
	},
	
	mymemory = {
		english = "en",
		japanese = "ja",
		korean = "ko"
	},
	
	yandex = {
		english = "en",
		japanese = "ja",
		korean = "ko"
	}
}

local translator_functions = { --per service functions for translating text
	azure = function(source_language, target_language, source_key, target_key, text, on_success, on_fail, client_id_convar, domain_convar, api_key_convar, region_convar)
		local api_key = api_key_convar:GetString()
		
		if api_key == "" then return false, "Missing API key! Set it using the kakoge_translate_azure_key convar."
		elseif string.len(api_key) ~= 32 then return false, "Malformed API key!" end
		
		local domain = domain_convar:GetString()
		
		if domain == "" then return false, "Missing API domain! Set it using the kakoge_translate_azure_domain convar." end
		
		local body = util.TableToJSON{{Text = text}}
		local client_id = client_id_convar:GetString()
		local headers = {["Ocp-Apim-Subscription-Key"] = api_key}
		local region = region_convar:GetString()
		
		if client_id ~= "" then headers["X-ClientTraceId"] = client_id end
		if region ~= "" then headers["Ocp-Apim-Subscription-Region"] = region end
		
		local post_data = {
			body = body,
			failed = function(reason) on_fail(source_language, target_language, "azure", text, 0, reason) end,
			headers = headers,
			method = "POST",
			type = "application/json; charset=UTF-8",
			url = domain .. "translate?api-version=3.0&from=" .. source_key .. "&to=" .. target_key,
			
			success = function(code, body, headers)
				if code == 200 then return on_success(source_language, target_language, "azure", text, body) end
				
				on_fail(source_language, target_language, "azure", text, code, "code was not 200", body, headers)
			end
		}
		
		return HTTP(post_data)
	end,
	
	--doesn't support korean, still implemented it
	deepl = function(source_language, target_language, source_key, target_key, text, on_success, on_fail, domain_convar, api_key_convar)
		local api_key = api_key_convar:GetString()
		
		if api_key == "" then return false, "Missing API key! Set it using the kakoge_translate_deepl_key convar."
		elseif string.len(api_key) < 36 then return false, "Malformed API key!" end
		
		local domain = domain_convar:GetString()
		
		if domain == "" then return false, "Missing API domain! Set it using the kakoge_translate_deepl_domain convar." end
		
		local parameters = {
			auth_key = api_key,
			source_lang = source_key,
			target_lang = target_key,
			text = text
		}
		
		local post_data = {
			failed = function(reason) on_fail(source_language, target_language, "deepl", text, 0, reason) end,
			headers = {},
			method = "POST",
			parameters = parameters,
			type = "text/plain; charset=utf-8",
			url = domain,
			
			success = function(code, body, headers)
				if code == 200 then
					local response = util.JSONToTable(body)
					local translations = {}
					
					for index, translation_data in ipairs(response.translations) do
						--maybe we should make a lanuge autodetect
						if source_key == translation_data.detected_source_language then table.insert(translations, translation_data.text) end
					end
					
					if next(translations) then return on_success(source_language, target_language, "deepl", text, unpack(translations)) end
					
					return on_fail(source_language, target_language, "deepl", text, code, "no translations provided in response", body, headers)
				end
				
				on_fail(source_language, target_language, "deepl", text, code, "code was not 200", body, headers)
			end
		}
		
		return HTTP(post_data)
	end,
	
	google = function(source_language, target_language, source_key, target_key, text, on_success, on_fail)
		--more?
		on_fail(source_language, target_language, "google", text, nil, "Google Translate is not yet supported by Kakoge")
	end,
	
	--don't forget to read this https://developer.itranslate.com/API_Integration_Agreement.pdf
	itranslate = function(source_language, target_language, source_key, target_key, text, on_success, on_fail, api_key_convar)
		local api_key = api_key_convar:GetString()
		
		if api_key == "" then return false, "Missing API key! Set it using the kakoge_translate_itranslate_key convar."
		elseif string.len(api_key) ~= 36 then return false, "Malformed API key!" end
		
		local body = util.TableToJSON{
			source = {
				dialect = source_key,
				text = text
			},
			
			target = {dialect = target_key}
		}
		
		local headers = {
			Authorization = "Bearer " .. api_key,
			--["Content-length"] = tostring(string.len(body)),
			--["Content-Type"] = "application/json",
		}
		
		local post_data = {
			body = body,
			failed = function(reason) on_fail(source_language, target_language, "itranslate", text, 0, reason) end,
			headers = headers,
			method = "POST",
			type = "application/json",
			url = "https://dev-api.itranslate.com/translation/v2/",
			
			success = function(code, body, headers)
				if code == 200 then return on_success(source_language, target_language, "itranslate", text, util.JSONToTable(body).target.text) end
				
				on_fail(source_language, target_language, "itranslate", text, code, "code was not 200", body, headers)
			end
		}
		
		return HTTP(post_data)
	end,
	
	mymemory = function(source_language, target_language, source_key, target_key, text, on_success, on_fail)
		local parameters = {
			de = "wisedthecoder@gmail.com",
			ip = kakoge_ip_override:GetString() or ip_address,
			langpair = source_key .. "|" .. target_key,
			of = "json",
			q = text
		}
		
		local post_data = {
			failed = function(reason) on_fail(source_language, target_language, "mymemory", text, 0, reason) end,
			headers = {},
			method = "POST",
			parameters = parameters,
			type = "text/plain; charset=utf-8",
			url = "https://api.mymemory.translated.net/get",
			
			success = function(code, body, headers)
				if code == 200 then
					local response = util.JSONToTable(body)
					local soft_text = string.lower(text) --TODO: add more loss for a softer compare alogirthm
					local translations = {}
					
					for index, translation_data in ipairs(response.matches) do
						--more?
						if string.lower(translation_data.segment) == soft_text then table.insert(translations, translation_data.translation) end
					end
					
					if next(translations) then return on_success(source_language, target_language, "mymemory", text, unpack(translations)) end
					
					return on_success(source_language, target_language, "mymemory", text, response.responseData.translatedText)
				end
				
				on_fail(source_language, target_language, "mymemory", text, code, "code was not 200", body, headers)
			end
		}
		
		return HTTP(post_data)
	end,
	
	--we must credit this somewhere if yandex is used: http://translate.yandex.com/
	yandex = function(source_language, target_language, source_key, target_key, text, on_success, on_fail, api_key_convar)
		local api_key = api_key_convar:GetString()
		local api_key_length = string.len(api_key)
		
		if api_key == 0 then return false, "Missing API key! Set it using the kakoge_translate_yandex_key convar."
		elseif api_key_length < 64 or api_key_length > 128 then return false, "Malformed API key!" end
		
		local parameters = {
			lang = source_key .. "-" .. target_key,
			key = api_key,
			text = text
		}
		
		local post_data = {
			failed = function(reason) on_fail(source_language, target_language, "yandex", text, 0, reason) end,
			headers = {},
			method = "POST",
			parameters = parameters,
			type = "text/plain; charset=utf-8",
			url = "https://translate.yandex.net/api/v1.5/tr.json/translate",
			
			success = function(code, body, headers)
				--yandex always uses a table of results
				if code == 200 then return on_success(source_language, target_language, "yandex", text, unpack(util.JSONToTable(body).text)) end
				
				on_fail(source_language, target_language, "yandex", text, code, "code was not 200", body, headers)
			end
		}
		
		return HTTP(post_data)
	end
}

--globals
KAKOGE.LanguageFlags = language_flags
KAKOGE.LanguagesAvailable = languages_available
KAKOGE.LanguagesServices = languages_services
KAKOGE.TranslatorConvars = translator_convars
KAKOGE.TranslatorFunctions = translator_functions
KAKOGE.TranslatorLanguageAliases = translator_language_aliases

--local function
local function default_on_fail(...)
	print("on fail!")
	print(...)
end

--post function setup
do --build langauge tables
	table.Empty(languages_available)
	table.Empty(languages_services)

	for service, language_aliases in pairs(translator_language_aliases) do
		for language_name, language_alias in pairs(language_aliases) do
			local language_services = languages_services[language_name]
			
			if not languages_available[language_name] then languages_available[language_name] = table.insert(languages_available, language_name) end
			
			if language_alias then
				if language_services then table.insert(language_services, service)
				else languages_services[language_name] = {service} end
			end
		end
	end
	
	table.sort(languages_available)
	
	--correct the indices used to make this a duplex table
	for index, language_name in ipairs(languages_available) do languages_available[language_name] = index end
	
	--sort languages_services and make it a duplex table
	for language_name, services in pairs(languages_services) do
		table.sort(services)
		
		for index, service in ipairs(services) do services[service] = index end
	end
end

--kakoge functions
function KAKOGE:KakogeTranslate(source_language, target_language, service, text, on_success, on_fail)
	local source_key = hook.Call("KakogeTranslateGetAvailability", self, source_language, service)
	local target_key = hook.Call("KakogeTranslateGetAvailability", self, target_language, service)
	
	if source_key and target_key then
		local translator_convar = translator_convars[service]
		local translator_function = translator_functions[service]
		
		assert(translator_function, "No translation function available for service [" .. service .. "]")
		--on_success(source_language, target_language, service, source_text, translated_text, ambiguous_translations...)
		--on_fail(source_language, target_language, service, text, code, message, info...)
		
		if istable(translator_convar) then return translator_function(source_language, target_language, source_key, target_key, text, on_success, on_fail or default_on_fail, unpack(translator_convar)) end
		
		return translator_function(source_language, target_language, source_key, target_key, text, on_success, on_fail or default_on_fail, translator_convar) 
	end
end

function KAKOGE:KakogeTranslateGetAvailability(language_key, service)
	--nil = service is not integrated
	--false = language is not supported by service
	--string = the language's name as known by the service's API
	local service_aliases = translator_language_aliases[service]
	
	if service_aliases then return service_aliases[language_key] or false end
	
	return nil
end

--console commands
concommand.Add("kakoge_translate", function(ply, command, arguments, arguments_string)
	local input_text = arguments_string or "Test"
	local source_language, target_language, service, input_text = unpack(arguments)
	
	assert(source_language and target_language and service and input_text, "Parameters: source_language, target_language, service, input_text")
	
	local translating, error_message = hook.Call("KakogeTranslate", KAKOGE, source_language, target_language, service, input_text, function(source_language, target_language, service, source_text, translated_text, ...)
		local ambiguous_translations = {...}
		
		print("source text: " .. source_text)
		
		if next(ambiguous_translations) then
			print("translated text (@" .. service .. ") with multiple matches: " .. translated_text)
			
			for index, translation in ipairs(ambiguous_translations) do print("ambiguous translation: " .. translation) end
			
			return
		end
		
		print("translated text (@" .. service .. "): " .. translated_text)
	end, function(...) print("we reached the hook's fail function\n", ...) end)
	
	if not translating then print("more!", error_message) end
end, nil, "Test command for Kakoge's translation.")

--hooks
hook.Add("InitPostEntity", "Kakoge", function()
	net.Start("kakoge_ip")
	net.SendToServer()
end)