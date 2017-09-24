-- =============================================================
--- NAME: compiler
--- Provides an API for compiling Svelte components
-- =============================================================

-- =============================================================
-- >> MODULE IMPORTS
-- =============================================================

-- Garry's Mod imports
import AddText from chat
import Add from concommand
import Read, Write from file
import Base64Encode from util
import JavascriptSafe from string
import insert from table
import Create, Register from vgui

-- =============================================================
-- >> UTILITY VARIABLES
-- =============================================================

-- Javascript injectiables
SCRIPT_JS_SERVICE	= [[@include{src/javascript/service.js}]]	-- Svelte.JS compile service
SCRIPT_JS_SVELTE	= [[@include{src/javascript/svelte.js}]]	-- Svelte.JS

-- =============================================================
-- >> MODULE PANELS
-- =============================================================

Register("SvelteService", {
	Init: () =>
		@ready		= false
		@pending	= {}
		@queue		= {}
		@queued		= false

		@NewObject("__service")
		@NewObjectCallback("__service", "dispatchCompiled")
		@NewObjectCallback("__service", "ready")

		@SetAlpha(0)
		@SetMouseInputEnabled(false)
		@SetKeyboardInputEnabled(false)

		@SetHTML([[
			<script type="application/javascript" src="data:text/plain;charset=utf-8;base64,]]..SCRIPT_JS_SVELTE..[["></script>
			<script type="application/javascript" src="data:text/plain;charset=utf-8;base64,]]..SCRIPT_JS_SERVICE..[["></script>
		]])

	OnCallback: (namespace, func, arguments) =>
		switch namespace
			when "__service"
				switch func
					when "dispatchCompiled"
						callback = @pending[arguments[1]]
						if callback
							callback(arguments[2])
							@pending[arguments[1]] = nil

					when "ready" then @ready = true

	Think: () =>
		if @ready and @queued
			@RunJavascript(script) for script in *@queue
			@queue	= {}
			@queued	= false

	compile: (source, callback) =>
		id				= tostring(callback)
		source			= JavascriptSafe(Base64Encode(source))
		@pending[id]	= callback
		@queueJavascript("service.dispatchTask('#{id}', atob('#{source}'));")

	queueJavascript: (script) =>
		insert(@queue, script)
		@queued = true

}, "Chromium")

-- =============================================================
-- >> MODULE FUNCTIONS
-- =============================================================

if SVELTE_SERVICE
	SVELTE_SERVICE\Remove()
	SVELTE_SERVICE = nil

export SVELTE_SERVICE = Create("SvelteService")

compile = (source, cb) -> SVELTE_SERVICE\compile(source, cb)

-- =============================================================
-- >> MODULE COMMANDS
-- =============================================================

Add("svelte_export", (ply, command, arguments) ->
	source = Read(arguments[1], "GAME")
	compile(source, (compiled) ->
		file = arguments[2] and arguments[2]..".txt" or "component.txt"
		Write(file, compiled)
		AddText(Color(0, 255, 0), "COMPILED SVELTE COMPONENT TO data/#{file}")
	)
)

-- =============================================================
-- >> MODULE EXPORTS
-- =============================================================

return {
	-- Functions
	:compile
}