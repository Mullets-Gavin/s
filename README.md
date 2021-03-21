<div align="center">
<h1>s</h1>

[![version](https://img.shields.io/badge/version-v0.0.1-red?style=flat-square)](https://github.com/Mullets-Gavin/s/releases)
[![docs](https://img.shields.io/badge/docs-link-blueviolet?style=flat-square)](https://github.com/Mullets-Gavin/s#documentation)
[![support](https://img.shields.io/badge/support-mullets-blue?style=flat-square)](https://www.buymeacoffee.com/mullets)

*A state management library for Roblox*
</div>

## Documentation

<details>
<summary><code>type s.none</code></summary>

Used as a replacement for nil

**Example:**
```lua
s:set({ undefined = s.none })
print(s.none) --> "none"
```
</details>

<details>
<summary><code>type s.all</code></summary>

A subscription key to watch all changes

**Example:**
```lua
s:subscribe(s.all, function)
print(s.all) --> "all"
```
</details>

<details>
<summary><code>map s.state</code></summary>

A map of the state store to read states

**Example:**
```lua
s:set({ counter = 0 })
print(s.state.counter) --> 0
```
</details>

<details>
<summary><code>function s.new(key)</code></summary>

Set state of keys and values and apply attributes if the store key is an instance and the value is a valid attribute type

**Parameters:**
* `key: any` -- the unique key for the store

**Returns:**
* `store` -- a state store

**Example:**
```lua
local playerStore = s.new(game.Players.LocalPlayer)
local gameStore = s.new(game)
```
</details>

<details>
<summary><code>method s:set(state, value?)</code></summary>

Set state of keys and values and apply attributes if the store key is an instance and the value is a valid attribute type

**Parameters:**
* `state: table | string` -- the state to set
* `value: any?` -- an optional state to set as

**Returns:**
* `table` -- the updated state table

**Example:**
```lua
s:set({ counter = 0 })
s:set("counter", s.state.counter + 1)
s:set({
	counter = s.state.counter + 1
})
```
</details>

<details>
<summary><code>method s:fire(state, value)</code></summary>

Fire all callbacks on the key provided with the updated value

**Parameters:**
* `state: string` -- the state to fire
* `value: any` -- the value to update with

**Returns:**
* `self` -- the store itself

**Example:**
```lua
s:fire("counter", 10)
```
</details>

<details>
<summary><code>method s:roact(component, keys?)</code></summary>

Initialize a roact component with the state store and injects the states from the store into the component

**Parameters:**
* `component: table` -- the roact component class
* `keys: table?` -- the optional keys (or all!) to inject state, leave nil for all

**Returns:**
* `component` -- return the roact component

**Example:**
```lua
return s:roact(Component, { "counter" }) -- track and inject counter into the component
return s:roact(Component) -- track and inject all state changes into the component
```
</details>

<details>
<summary><code>method s:define(interface)</code></summary>

Define an interface with t to filter state and maintain global changes to the store

**Parameters:**
* `interface: function` -- the t.interface or t.strictInterface function

**Returns:**
* `interface` -- returns the same t interface function

**Example:**
```lua
local interface = s:define(t.strictInterface({
	counter = t.number,
	flag = t.boolean,
}))

s:set({
	counter = 0, -- ✅
	flag = Color3.fromRGB(0, 0, 0), -- ❌
}) -- this will error since flag goes against the interface
```
</details>

<details>
<summary><code>method s:sanitize(value)</code></summary>

Sanitizes a data value to check if it's valid for an attribute and returns a boolean whether or not it is

**Parameters:**
* `value: table | any` -- the value or table of values to be sanitized

**Returns:**
* `boolean` -- true if passed, false if not

**Example:**
```lua
print("is number valid:", s:sanitize(0)) --> "is number valid: true"
print("is color3 valid:", s:sanitize(Color3.fromRGB(0, 0, 0,))) --> "is color3 valid: true"
print("is enum valid:", s:sanitize(Enum.Keycode.Q)) --> "is enum valid: false"
```
</details>

<details>
<summary><code>method s:subscribe(keys, callback)</code></summary>

Watch for changes on all keys or specified keys with a callback function. Use `s.all` to tell the subscription to watch for all changes that occur.

**Parameters:**
* `keys: table | any` -- the keys to watch, use `s.all` as your key to watch all changes
* `callback: function` -- the function to call when a change occurs, provides a `context` object

**Arguments:**
* `context = { state: any, value: any }` -- the context object passed in the callback function with `.state` and `.value`

**Returns:**
* `Subscription` -- returns a subscription object to disconnect the subscription

**Example:**
```lua
local subscription = s:subscribe(s.all, function(context)
	print(context.state .. ",", context.value) --> "hello, world!"
end)

s:set({ hello = "world!" })
subscription:unsubscribe()

s:subscribe({ "counter", "stage" }, function(context)
	if context.state == "counter" then
		print("countdown:", context.value)
	elseif context.state == "stage" then
		print("moving to new stage:", context.value)
	end
end)
```
</details>

<details>
<summary><code>method Subscription:unsubscribe()</code></summary>

Unsubscribes a subscription and disconnects the object

**Returns:**
* `nil`

**Example:**
```lua
local subscription; subscription = s:subscribe(s.all, function(context)
	subscription:unsubscribe()
end)

s:set({ counter = 0 })
```
</details>

## License

This project is licensed under the MIT license. See [LICENSE](https://github.com/Mullets-Gavin/s/blob/master/LICENSE) for details.