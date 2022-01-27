local default_target_depth = MATERIAL_RT_DEPTH_SHARED
local default_target_format = IMAGE_FORMAT_RGBA8888
local max_power = 16
local targets = KAKOGE.RenderTargets or {}

--globals
KAKOGE.RenderTargets = targets

--local functions
local function validate_target_power(power) return power >= 0 and power <= 16 and power == math.ceil(power) end

--assertions
local function assert_target_power(power) assert(validate_target_power(power), "Bad render target power (power must be < " .. (max_power + 1) .. " and a whole number)") end

--kakoge functions
function KAKOGE:KakogeKernelCreateTarget(power, depth, format)
	assert_target_power(power)
	
	depth = depth or default_target_depth
	format = format or default_target_format
	
	local power_targets = targets[power]
	local size = 2 ^ power
	
	if not power_targets then
		power_targets = {}
		targets[power] = power_targets
	end
	
	local index = #power_targets + 1
	local material_additive_name = "kakoge_kernel/" .. power .. "/material_additive_" .. index
	local material_name = "kakoge_kernel/" .. power .. "/material_" .. index
	local target_name = "kakoge_kernel/" .. power .. "/target_" .. index
	
	local target = GetRenderTargetEx(target_name,
		size, size, RT_SIZE_LITERAL,
		depth,
		0, --256 for no mips
		0,
		format
	)
	
	local target_info = {
		--more!
		Depth = depth,
		Format = format,
		Free = true,
		Target = target,
		TargetName = target_name,
		
		Material = CreateMaterial(material_name, "UnlitGeneric", {
			["$basetexture"] = target_name,
			["$translucent"] = "1",
			["$vertexalpha"] = "1",
			["$vertexcolor"] = "1"
		}), MaterialName = material_name,
		
		MaterialAdditive = CreateMaterial(material_additive_name, "UnlitGeneric", {
			["$additive"] = "1",
			["$basetexture"] = target_name,
			["$translucent"] = "1",
			["$vertexalpha"] = "1",
			["$vertexcolor"] = "1"
		}), MaterialAdditiveName = material_additive_name
	}
	
	power_targets[index] = target_info
	
	return index, target_info
end

function KAKOGE:KakogeKernelGetTarget(...)
	local index, target_info = hook.Call("KakogeKernelGetTargetInfo", self, ...)
	
	return index, target_info.Texture
end

function KAKOGE:KakogeKernelGetTargetInfo(power, index, depth, format)
	assert_target_power(power)
	
	local power_targets = targets[power]
	
	if power_targets then
		if index then return index, power_targets[index] end
		
		local depth = depth or default_target_depth
		local format = format or default_target_format
		
		--find a free cached target
		for index, target_info in ipairs(power_targets) do
			local free = target_info.Free
			local check_depth = depth == target_info.Depth
			local check_format = format == target_info.Format
			
			if free and check_depth and check_format then
			--if target_info.Free and depth == target_info.Depth and format == target_info.Format then
				--TODO: more advanced matching?
				return index, target_info
			else print("didnt match", free, check_depth, check_format) print(depth, target_info.Depth, format, target_info.Format) end
		end
	elseif index then error("Panic! Attempt to fetch an existing render target by index without a matching power table to fetch from. This should never happen!") end
	
	return hook.Call("KakogeKernelCreateTarget", self, power, depth, format)
end

function KAKOGE:KakogeKernelGetTargetMaterial(...)
	local index, target_info = hook.Call("KakogeKernelGetTargetInfo", self, ...)
	
	return index, target_info.Material
end

function KAKOGE:KakogeKernelGetTargetMaterialAdditive(...)
	local index, target_info = hook.Call("KakogeKernelGetTargetInfo", self, ...)
	
	return index, target_info.MaterialAdditive
end

--commands
concommand.Add("kakoge_kernel_release", function(ply, command, arguments, arguments_string)
	local response = true
	
	for power, targets in pairs(KAKOGE.RenderTargets) do
		for index, target_info in ipairs(targets) do
			if not target_info.Free then
				print("target 2^" .. power .. " #" .. index .. " released")
				
				response = false
				target_info.Free = true
			end
		end
	end
	
	if response then print("all targets are already free") end
end, nil, "Forcibly release all of Kakoge's render targets, setting the Free field to true. This will cause targets in use to get drawn over (which is bad).")