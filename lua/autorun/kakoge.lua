include("kakoge/loader.lua")

--commands
concommand.Add("kakoge_reload", function(ply, command, arguments, arguments_string) include("kakoge/loader.lua") end, nil, "Reload Kakoge.")