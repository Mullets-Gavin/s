--[=[
	s, a state management library for Roblox with easy integration of t

	Goals:
	- integrates with t
	- handles replication
	- minimal api, all surface level
	- allows for state "stores"
	- global stores for roact
]=]

local s = {}
s.stores = {}
s.attributes = true
s._attributeTypes = {
	"string",
	"boolean",
	"number",
	"UDim",
	"UDim2",
	"BrickColor",
	"Color3",
	"Vector2",
	"Vector3",
	"NumberSequence",
	"ColorSequence",
	"NumberRange",
	"Rect",
}

do
	s.none = newproxy(true)
	getmetatable(s.none).__tostring = function()
		return "none"
	end

	s.all = newproxy(true)
	getmetatable(s.all).__tostring = function()
		return "all"
	end
end

--[=[
	Copy a table

	@param master table -- table to copy
	@return clone table -- the cloned table
]=]
local function copy(master: table): table
	local clone = {}

	for key, value in pairs(master) do
		if typeof(value) == "table" then
			clone[key] = copy(value)
		else
			clone[key] = value
		end
	end

	return clone
end

--[=[
	Wrap and call a function instantly
	
	@param code () -> () -- the function to call
]=]
local function wrap(code: (any) -> (), ...): nil
	local thread = coroutine.create(code)
	local ran, response = coroutine.resume(thread, ...)

	if not ran then
		local trace = debug.traceback(thread)
		error(response .. "\n" .. trace, 2)
	end
end

--[=[
	A new store or returns a current one

	@param key any -- the unique key for the store
	@return s typeof(s.new()) -- the store class
]=]
function s.new(key: any?): typeof(s.new())
	key = key ~= nil and key or game

	if s.stores[key] then
		return s.stores[key]
	end

	s.__index = s
	s.stores[key] = setmetatable({
		state = {},
		_uid = 0,
		_key = key,
		_type = typeof(key),
		_events = {},
		_subscriptions = {},
	}, s)

	if s.stores[key]._type == "Instance" then
		local new = {}
		for scope, value in pairs(key:GetAttributes()) do
			new[scope] = value
		end
		s.stores[key].state = new
	end

	return s.stores[key]
end

--[=[
	Set the state to the store and fire any subscriptions

	@param state table | string -- the state to set
	@param value any? -- an optional state to set as
	@return update table -- the updated state table
]=]
function s:set(state: table | string, value: any?): table
	assert(state ~= nil, "'set' Argument 1 missing or nil")

	local update = copy(self.state)
	if typeof(state) == "table" then
		for key, data in pairs(state) do
			local new = data ~= s.none and data
			update[key] = new
			self:fire(key, new)
		end
	elseif typeof(state) == "string" and value ~= nil then
		local new = value ~= s.none and value
		update[state] = new
		self:fire(state, new)
	end
	self.state = update

	if self._interface then
		local success, msg = self._interface(update)
		assert(success, msg)
	end

	if self.attributes and self._type == "Instance" then
		for key, data in pairs(update) do
			if not self:sanitize(data) then
				continue
			end

			if self._key:GetAttribute(key) ~= data then
				self._key:SetAttribute(state, data)
			end
		end
	end

	return update
end

--[=[
	Sanitizes a data value and returns a boolean

	@param value table | any -- the value or table of values to be sanitized
	@return check boolean -- true if passed, false if not
]=]
function s:sanitize(value: table | any): boolean
	if typeof(value) == "table" then
		for key, data in pairs(value) do
			if not table.find(s._attributeTypes, typeof(data)) then
				return false, key
			end
		end
		return true
	else
		return table.find(s._attributeTypes, typeof(value)) ~= nil
	end
end

--[[
	Fire all callbacks on the key provided

	@param state string -- the state to fire
	@param value any -- the value to update with
	@return s typeof(s.new()) -- self class
]]
function s:fire(state: string, value: any): typeof(s.new())
	for _, subscriptions in ipairs(self._subscriptions) do
		if not table.find(subscriptions.keys, s.all) and not table.find(subscriptions.keys, state) then
			continue
		end

		wrap(subscriptions.callback, {
			state = state,
			value = value,
		})
	end

	return self
end

--[=[
	Watch for changes on all keys or specified keys

	@param keys table | any -- the keys to watch
	@param callback () -> () -- the function to call
	@return methods table -- the unsubscribe method to disconnect
]=]
function s:subscribe(keys: table | any, callback: () -> ()): table
	assert(keys ~= nil, "'subscribe' Argument 1 missing or nil")
	assert(typeof(callback) == "function", "'subscribe' Argument 2 must be a function")

	local subscription = {
		keys = typeof(keys) == "table" and keys or { keys },
		callback = callback,
	}
	table.insert(self._subscriptions, subscription)

	local events = {}
	if self.attributes and self._type == "Instance" then
		for index, key in ipairs(keys) do
			events[index] = self._key:GetAttributeChangedSignal(key):Connect(function()
				local attributeValue = self._key:GetAttribute(key)
				local stateValue = self.state[key]

				if attributeValue ~= stateValue then
					self:set({ [key] = attributeValue })
				end
			end)
		end
	end

	return {
		unsubscribe = function(): nil
			if not subscription then
				return
			end

			local find = table.find(self._subscriptions, subscription)
			if find then
				table.remove(self._subscriptions, find)
			end

			for _, event in pairs(events) do
				event:Disconnect()
			end

			events = nil
			subscription = nil
		end,
	}
end

--[=[
	Initialize a roact component with the state store

	@param component table -- the roact component class
	@param keys table? -- the optional keys (or all!) to inject state
	@return component table -- return the roact component
]=]
function s:roact(component: table, keys: table?): table
	assert(typeof(component) == "table", "'roact' Argument 1 must be a Roact Component")
	assert(typeof(keys) == "table", "'roact' Argument 2 expected a table, got '" .. typeof(keys) .. "'")

	local initialMethods = {
		init = component.init,
		willUnmount = component.willUnmount,
	}

	component.init = function(this, ...)
		local initialState = {}

		if initialMethods.init then
			initialMethods.init(this, ...)
		end

		if typeof(keys) == "table" then
			for _, key in ipairs(keys) do
				initialState[key] = self.state[key]
			end

			self._componentSubscription = self:subscribe(keys, function(context)
				this:setState({ [context.state] = context.value })
			end)
		else
			initialState = self.state

			self._componentSubscription = self:subscribe(s.all, function(context)
				this:setState({ [context.state] = context.value })
			end)
		end

		this:setState(initialState)
	end

	component.willUnmount = function(this, ...)
		if initialMethods.willUnmount then
			initialMethods.willUnmount(this, ...)
		end

		if self._componentSubscription then
			self._componentSubscription:unsubscribe()
			self._componentSubscription = nil
		end
	end

	return component
end

--[=[
	Define an interface with t to filter state

	@param interface () -> () -- the t.interface or t.strictInterface function
	@return interface () -> () -- returns the same t interface function
]=]
function s:define(interface: () -> ()): () -> ()
	assert(typeof(interface) == "function", "'s:interface' only takes an interface from t")

	self._interface = interface

	return interface
end

--[=[
	A replacement for s.new()

	@param key any -- the key can be anything except nil
	@return s typeof(s.new()) -- the state store
]=]
function s:__call(key: any): typeof(s.new())
	if s.stores[key] then
		s.stores[key]._key = key
		s.stores[key]._type = typeof(key)
		return s.stores[key]
	end

	return s.new(key)
end

--[=[
	When debugging, use print(s) to check the store key

	@return key string -- the key name or path
]=]
function s:__tostring()
	return "s: " .. typeof(self._key) == "Instance" and self._key:GetFullName() or tostring(self._key)
end

return s.new(game)
