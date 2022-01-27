util.AddNetworkString("kakoge_ip")

--locals
local ip_addresses = {}

local function send_ip_update(ply, ip_address)
	net.Start("kakoge_ip")
	net.WriteString(ip_address or ply:IPAddress())
	net.Send(ply)
	
	ip_addresses[ply] = ip_address
end

--hooks
hook.Add("PlayerDisconnected", "Kakoge", function(ply) ip_addresses[ply] = nil end)

hook.Add("Think", "Kakoge", function()
	for index, ply in ipairs(player.GetHumans()) do
		local ip_address = ply:IPAddress()
		
		if ip_address ~= ip_addresses[ply] then send_ip_update(ply, ip_address) end
	end
end)

--net
net.Receive("kakoge_ip", function(length, ply) send_ip_update(ply) end)