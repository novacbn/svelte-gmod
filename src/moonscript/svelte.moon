-- =============================================================
--- NAME: svelte
--- Provides a VGUI Panel for managed Svelte component integration
-- =============================================================

-- =============================================================
-- >> MODULE IMPORTS
-- =============================================================

-- Lua imports
import
	error, unpack, setmetatable,
	tostring, type from _G

import concat, remove from table

-- Garry's Mod imports
import JavascriptSafe from string
import JSONToTable, TableToJSON from util
import Merge from table
import CreateFromTable from vgui

-- =============================================================
-- >> UTILITY VARIABLES
-- =============================================================

SCRIPT_JS_RUNTIME = [[@include{src/javascript/runtime.js}]] -- Integration runtime for Svelte

-- Prepared integration runtime
SCRIPT_HTML_RUNTIME = "
<style>
	html, body {
		margin:	0px;
		width:	100%;
		height:	100%;
	}

	body {
		min-height: 100%;
	}
</style>
<script type='application/javascript' src='data:text/plain;charset=utf-8;base64,#{SCRIPT_JS_RUNTIME}'></script>
"

-- =============================================================
-- >> MODULE CLASSES
-- =============================================================

---
--- METHOD: Variables Variables(Panel panel, table cache)
--- Simple observed variable accessor
---
--- ```moonscript
--- ```
---
Variables = (panel, cache) ->
	metatable =
		__index: (name) => cache[name]
		__newindex: (name, value) =>
			return panel\set({[name]: value}) if value ~= cache[name]

	return setmetatable(metatable, metatable)

-- =============================================================
-- >> MODULE PANELS
-- =============================================================

---
--- METHOD: SveltePanel SveltePanel()
--- Base Panel for interacting with Svelte.JS
---
--- ```moonscript
--- ```
---
SveltePanel =
	Base: "Awesomium"
	Name: "SveltePanel"

	Init: () =>
		@NewObject("__runtime")
		@NewObjectCallback("__runtime", "callback")
		@NewObjectCallback("__runtime", "create")
		@NewObjectCallback("__runtime", "ready")
		@NewObjectCallback("__runtime", "release")

		@callbacks	= {}
		@queue		= {}
		@cache		= {}
		@vars		= Variables(self, @cache)

		@SetHTML(SCRIPT_HTML_RUNTIME)

	---
	--- METHOD: void OnCallback(string namespace, string func, table arguments)
	--- Called when the Javascript state calls into the Lua state
	---
	--- ```moonscript
	--- ```
	---
	OnCallback: (namespace, func, arguments) =>
		switch namespace
			when "__runtime"
				switch func
					when "callback"
						id			= remove(arguments, 1)
						callback	= @callbacks[id]
						callback(unpack(arguments)) if callback

					when "create"
						@onCreate()
						@create = true

					when "ready"
						@RunJavascript(script) for script in *@queue
						@ready = true

					when "release" then @callbacks[arguments[1]] = nil

	---
	--- METHOD: void OnRemove()
	--- Called when the SveltePanel is being destroyed
	---
	--- ```moonscript
	--- ```
	---
	OnRemove: () =>
		@onDestroy()
		return nil

	---
	--- METHOD: void Think()
	--- Called when every tick while the SveltePanel is alive
	---
	--- ```moonscript
	--- ```
	---
	Think: () =>
		@onThink() if @create
		return nil

	---
	--- METHOD: void call(string func, any ...)
	--- Internal method for calling into the Javascript state, primitive types only!
	---
	--- ```moonscript
	--- ```
	---
	call: (func, ...) =>
		arguments	= {}
		length		= 0
		for argument in *{...}
			length += 1
			switch type(argument)
				when "boolean" then arguments[length]	= argument and "true" or "false"
				when "number" then arguments[length]	= tostring(argument)
				when "string" then arguments[length]	= "'"..JavascriptSafe("#{argument}").."'"
				when "table"
					json = "'"..JavascriptSafe(TableToJSON(argument)).."'"
					arguments[length] = json

				else
					error("primitive types only!")

		script = "#{func}(#{concat(arguments, ',')});"
		if @ready
			@RunJavascript(script)

		else
			@queue[#@queue + 1] = script

		return nil

	---
	--- METHOD: void dispatch(string name, table data?, function callback?)
	--- Dispatched an event named 'name' to Svelte
	---
	--- ```moonscript
	--- ```
	---
	dispatch: (name, data={}, callback=() ->) =>
		id = @getCallbackID(callback)
		@call("runtime.dispatch", name, data)

	---
	--- METHOD: void get(string name, function callback?)
	--- Retrieves a variable named 'name' from Svelte
	---
	--- ```moonscript
	--- ```
	---
	get: (name, callback=() ->) =>
		id = @getCallbackID(callback)
		@call("runtime.get", id, name)

	---
	--- METHOD: void getCallbackID(function callback)
	--- Internal method for handling Lua callbacks
	---
	--- ```moonscript
	--- ```
	---
	getCallbackID: (callback) =>
		func	= (...) -> callback(...)
		id		= tostring(func)
		@callbacks[id] = func
		return id

	---
	--- METHOD: function observe(string name)
	--- Starts replicating a variable named 'name' to SveltePanel, call the return function to release
	---
	--- ```moonscript
	--- ```
	---
	observe: (name) =>
		id = @getCallbackID((value) ->
			@cache[name] = value
		)

		@call("runtime.observe", id, name)
		return () ->
			@call("runtime.release", id)
			@cache[name] = nil

	---
	--- METHOD: function on(string name, function callback)
	--- Listens for an event named 'name' with 'callback', call the return function to release
	---
	--- ```moonscript
	--- ```
	---
	on: (name, callback) =>
		id = @getCallbackID((json) ->
			data = JSONToTable(json)
			callback(data)
		)

		@call("runtime.on", id, name)
		return () -> @call("runtime.release", id)

	---
	--- METHOD: void set(<String, String> data, function callback?)
	--- Uses the table 'data' as a keypairs to set variables in Svelte
	---
	--- ```moonscript
	--- panel\set(x: 1, y: "hello")
	--- ```
	---
	set: (data, callback=() ->) =>
		id = @getCallbackID(callback)
		@call("runtime.set", id, data)

	---
	--- METHOD: void setMainComponent(string component)
	--- Internal method for setting the main component of Svelte
	---
	--- ```moonscript
	--- ```
	---
	setMainComponent: (component) =>
		@call("runtime.setMainComponent", component)

	---
	--- METHOD: void setSubComponents(<string, string> components)
	--- Internal method for setting the main component of Svelte
	---
	--- ```moonscript
	--- ```
	---
	setSubComponents: (components) =>
		@call("runtime.setSubComponents", components)

	---
	--- METHOD: void onCreate()
	--- Lifecycle hook for when the main component was created
	---
	--- ```moonscript
	--- ```
	---
	onCreate: () =>

	---
	--- METHOD: void onDestroy()
	--- Lifecycle hook for when the main component is about to be destroyed
	---
	--- ```moonscript
	--- ```
	---
	onDestroy: () =>

	---
	--- METHOD: void onThink()
	--- Engine hook that is called every engine tick after the component is initialized
	---
	--- ```moonscript
	--- ```
	---
	onThink: () =>

-- =============================================================
-- >> MODULE FUNCTIONS
-- =============================================================

---
--- FUNC: Panel create(string component, <String, String> components?, VGUI parent?, table Panel?)
--- Creates a new SveltePanel that manages the main component
--- NOTE: Sub components will be exposed to the main component as their key names
---
--- ```moonscript
--- components =			-- Define the sub components with their exposing IDs
---		subone: scriptone,
---		subtwo: scripttwo
---
--- panel = svelte.create(component, components) -- Creates a new SveltePanel
--- ```
---
create = (component, components={}, parent, Panel=SveltePanel) ->
	panel = CreateFromTable(Panel, parent, Panel.Name)
	panel\setSubComponents(components)
	panel\setMainComponent(component)
	return panel

---
--- FUNC: table extend(table Panel)
--- Extends the base SveltePanel with the table 'panel', useful for encapsulating Panel logic
---
--- ```moonscript
--- MyPanel = svelte.extend				-- Extend SveltePanel
--- 	onCreate: () =>
--- 		print("I was created!")		-- Print when panel is made
---
--- 	onDestroy: () =>
--- 		print("I was destroyed!")	-- Print when panel is about to be destroyed
---
--- panel = svelte.create(component, components, nil, MyPanel) -- Creates a new SveltePanel
--- ```
---
extend = (Panel) -> Merge(SveltePanel, Panel)

-- =============================================================
-- >> MODULE EXPORTS
-- =============================================================

return {
	-- Panels
	:SveltePanel

	-- Functions
	:create, :extend
}