local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local Player = Players.LocalPlayer

-- grab t
local t = require(ReplicatedStorage.t)

-- initialize s
local s = require(ReplicatedStorage.s)(Player) -- grab player state

-- define the states interface
local interface = t.strictInterface({
	counter = t.optional(t.number),
	flag = t.boolean,
})
s:define(interface)

-- set initial states
s:set({ counter = 0, flag = false })
print("initial states:", s.state)

-- subscription, watch changes
local subscription; subscription = s:subscribe(s.all, function(context)
	if context.state == "flag" and context.value then
		subscription:unsubscribe()
	else
		print(context.state .. ":", context.value)
	end
end)

-- increment the state
while wait(1) do
	s:set({ counter = s.state.counter + 1 })

	if s.state.counter >= 10 then
		s:set({ flag = true })
		break
	end
end

--[[
	s.state = Map<state: string, value: any>
	s.new(key: any)
	s:set(props: Map<state: string, value: any>)
	s:fire(state: string, value: any)
	s:roact(component: table, keys: table)
	s:define(interface: () -> ())
	s:sanitize(value: any): boolean
	s:subscribe(keys: string | table, callback: () -> ()):unsubscribe()
]]
