local max_power = 16

--local functions
local function validate_target_power(power) return power >= 0 and power <= 16 and power == math.ceil(power) end

--assertions
local function assert_target_power(power) assert(validate_target_power(power), "Bad render target power (power must be < " .. (max_power + 1) .. " and a whole number)") end

--kakoge functions
function KAKOGE:KakogeRenderTarget(power, build_context, paint, depth, format, index)
	assert_target_power(power)
	
	local new_index, target_info = hook.Call("KakogeKernelGetTargetInfo", self, power, index, depth, format)
	local render_size = 2 ^ power
	local target = target_info.Target
	
	target_info.Free = false
	
	render.PushRenderTarget(target, 0, 0, render_size, render_size)
		if build_context then
			if istable(build_context) then
				cam.Start(build_context)
					paint(render_size)
				if build_context.type == "2D" then cam.End2D()
				else cam.End3D() end
			else
				cam.Start2D()
					paint(render_size)
				cam.End2D()
			end
		else paint(render_size) end
	render.PopRenderTarget()
	
	target_info.Free = true
	
	return target_info, new_index
end