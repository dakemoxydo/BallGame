--!strict
--!nocheck
-- Dependency injection keeps package paths owned by the consuming project.
return function(React, Ripple, UserInputService)
	-- onRest(value) fires when the spring settles; reduced motion settles immediately.
	local function useSpringBinding(initial, options, reducedMotion, onRest)
		local binding, update = React.useBinding(initial)
		local rest = React.useRef(onRest)
		rest.current = onRest
		local motion = React.useRef(nil)
		local goal = React.useRef(initial)
		local frequency = options.Frequency
		local damping = options.DampingRatio
		React.useEffect(function()
			local spring = Ripple.createSpring(initial, {
				frequency = frequency,
				dampingRatio = damping,
				start = true,
			})
			motion.current = spring
			local disconnect = spring:onChange(update)
			local completed = spring:onComplete(function(value)
				if rest.current then
					rest.current(value)
				end
			end)
			spring:setGoal(goal.current)
			return function()
				disconnect()
				completed()
				spring:destroy()
				if motion.current == spring then
					motion.current = nil
				end
			end
		end, { frequency, damping })
		local function setGoal(value)
			goal.current = value
			if reducedMotion then
				update(value)
			end
			if motion.current then
				if reducedMotion then
					motion.current:setPosition(value)
				end
				motion.current:setGoal(value)
			end
			if reducedMotion and rest.current then
				task.defer(rest.current, value)
			end
		end
		React.useEffect(function()
			if reducedMotion then
				setGoal(goal.current)
			end
		end, { reducedMotion })
		return binding, setGoal
	end

	-- Returns one progress binding: -1 pressed, 0 rest, 1 hover/focus.
	-- Components derive lift, tint or scale from it; nothing else writes those properties.
	local function useButtonMotion(props, theme)
		local progress, setGoal = useSpringBinding(0, theme.Motion, props.ReducedMotion == true)
		local state = React.useRef({ hover = false, focus = false, pressed = nil })
		local blocked = props.Disabled == true or props.Loading == true or props.Visible == false
		-- Connections use the newest props after a React render.
		local latest = React.useRef(nil)
		latest.current = { blocked = blocked, target = setGoal }
		local function update()
			local s = state.current
			local goal = 0
			if not latest.current.blocked then
				if s.pressed then
					goal = -1
				elseif s.hover or s.focus then
					goal = 1
				end
			end
			latest.current.target(goal)
		end
		local function cancel()
			state.current.pressed = nil
			update()
		end
		React.useEffect(function()
			if blocked then
				state.current.hover = false
				state.current.focus = false
				state.current.pressed = nil
			end
			update()
		end, { blocked, props.ReducedMotion == true })
		React.useEffect(function()
			local ended = UserInputService.InputEnded:Connect(function(input)
				local pressed = state.current.pressed
				if not pressed then
					return
				end
				-- A finger that slides off the button releases outside of it, so the touch has to clear the press too.
				local kind = pressed.UserInputType
				if
					pressed == input
					or (kind == Enum.UserInputType.MouseButton1 and input.UserInputType == kind)
					or (kind == Enum.UserInputType.Touch and input.UserInputType == kind)
				then
					cancel()
				end
			end)
			local lost = UserInputService.WindowFocusReleased:Connect(function()
				state.current.hover = false
				state.current.focus = false
				cancel()
			end)
			return function()
				ended:Disconnect()
				lost:Disconnect()
			end
		end, {})
		local events = {
			[React.Event.MouseEnter] = function()
				state.current.hover = true
				update()
			end,
			[React.Event.MouseLeave] = function()
				state.current.hover = false
				local pressed = state.current.pressed
				if pressed and pressed.UserInputType == Enum.UserInputType.MouseButton1 then
					state.current.pressed = nil
				end
				update()
			end,
			[React.Event.SelectionGained] = function()
				state.current.focus = true
				update()
			end,
			[React.Event.SelectionLost] = function()
				state.current.focus = false
				cancel()
			end,
			[React.Event.InputBegan] = function(_, input)
				if latest.current.blocked then
					return
				end
				if
					input.UserInputType == Enum.UserInputType.MouseButton1
					or input.UserInputType == Enum.UserInputType.Touch
					or input.KeyCode == Enum.KeyCode.ButtonA
				then
					state.current.pressed = input
					update()
				end
			end,
			[React.Event.InputEnded] = function(_, input)
				if state.current.pressed == input then
					cancel()
				end
			end,
		}
		return progress, events
	end

	local function useWindowNavigation()
		local activeWindow, setActiveWindow = React.useState(nil)
		local function toggle(windowId)
			assert(type(windowId) == "string", "Window id must be a string")
			setActiveWindow(function(current)
				if current == windowId then
					return nil
				end
				return windowId
			end)
		end
		local function close(windowId)
			setActiveWindow(function(current)
				if current == windowId then
					return nil
				end
				return current
			end)
		end
		return activeWindow, toggle, close
	end
	return {
		useSpringBinding = useSpringBinding,
		useButtonMotion = useButtonMotion,
		useWindowNavigation = useWindowNavigation,
	}
end
